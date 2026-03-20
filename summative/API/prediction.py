import os
import pickle
import numpy as np
import pandas as pd
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, r2_score
import io

# App initialization

app = FastAPI(
    title="Student Performance Prediction API",
    description="Predicts student Performance Index based on study habits and personal factors.",
    version="1.0.0"
)


# CORS Middleware 
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8080",
        "https://your-flutter-app.web.app",
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Content-Type", "Authorization", "Accept"],
)

# Load model artifacts

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def load_artifacts():
    with open(os.path.join(BASE_DIR, "best_model.pkl"), "rb") as f:
        model = pickle.load(f)
    with open(os.path.join(BASE_DIR, "scaler.pkl"), "rb") as f:
        scaler = pickle.load(f)
    with open(os.path.join(BASE_DIR, "feature_names.pkl"), "rb") as f:
        feature_names = pickle.load(f)
    return model, scaler, feature_names

model, scaler, feature_names = load_artifacts()

# Pydantic model with data types and range constraints

class StudentInput(BaseModel):
    hours_studied: float = Field(
        ...,
        ge=1.0, le=9.0,
        description="Number of hours studied per day (1 to 9)"
    )
    previous_scores: float = Field(
        ...,
        ge=40.0, le=99.0,
        description="Previous academic scores (40 to 99)"
    )
    extracurricular_activities: int = Field(
        ...,
        ge=0, le=1,
        description="Extracurricular activities participation: 1 = Yes, 0 = No"
    )
    sleep_hours: float = Field(
        ...,
        ge=4.0, le=9.0,
        description="Average sleep hours per night (4 to 9)"
    )
    sample_question_papers_practiced: float = Field(
        ...,
        ge=0.0, le=9.0,
        description="Number of sample question papers practiced (0 to 9)"
    )

class PredictionResponse(BaseModel):
    predicted_performance_index: float
    message: str

class RetrainResponse(BaseModel):
    message: str
    model_type: str
    test_mse: float
    r2_score: float

# Endpoints

@app.get("/")
def root():
    return {
        "message": "Student Performance Prediction API is running!",
        "docs": "/docs",
        "endpoints": {
            "POST /predict": "Predict student performance index",
            "POST /retrain": "Retrain model with new CSV data",
            "GET  /health":  "Check API health"
        }
    }


@app.get("/health")
def health():
    return {
        "status": "ok",
        "model_loaded": model is not None,
        "features": feature_names
    }


@app.post("/predict", response_model=PredictionResponse)
def predict(student: StudentInput):
    """
    Accepts student data and returns a predicted Performance Index.
    All inputs are validated with data types and range constraints.
    """
    try:
        features = np.array([[
            student.hours_studied,
            student.previous_scores,
            student.extracurricular_activities,
            student.sleep_hours,
            student.sample_question_papers_practiced
        ]])

        features_scaled = scaler.transform(features)
        prediction = model.predict(features_scaled)[0]
        prediction = round(float(prediction), 2)

        # Clamp prediction to valid range
        prediction = max(0.0, min(100.0, prediction))

        return PredictionResponse(
            predicted_performance_index=prediction,
            message="Prediction generated successfully"
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/retrain", response_model=RetrainResponse)
async def retrain(file: UploadFile = File(...)):
    """
    Accepts a new CSV file and retrains the Linear Regression model.
    The CSV must have the same columns as the original dataset.
    Expected columns: Hours Studied, Previous Scores, Extracurricular Activities,
                      Sleep Hours, Sample Question Papers Practiced, Performance Index
    """
    global model, scaler, feature_names

    try:
        # Read uploaded CSV
        contents = await file.read()
        df = pd.read_csv(io.StringIO(contents.decode("utf-8")))

        required_cols = [
            "Hours Studied",
            "Previous Scores",
            "Extracurricular Activities",
            "Sleep Hours",
            "Sample Question Papers Practiced",
            "Performance Index"
        ]

        # Validate columns
        missing = [c for c in required_cols if c not in df.columns]
        if missing:
            raise HTTPException(
                status_code=400,
                detail=f"Missing columns in uploaded CSV: {missing}"
            )

        # Encode categorical
        from sklearn.preprocessing import LabelEncoder
        if df["Extracurricular Activities"].dtype == object:
            le = LabelEncoder()
            df["Extracurricular Activities"] = le.fit_transform(
                df["Extracurricular Activities"]
            )

        # Prepare features and target
        X = df.drop("Performance Index", axis=1)[required_cols[:-1]]
        y = df["Performance Index"]

        # Standardize
        new_scaler = StandardScaler()
        X_scaled = new_scaler.fit_transform(X)

        # Split
        X_train, X_test, y_train, y_test = train_test_split(
            X_scaled, y, test_size=0.2, random_state=42
        )

        # Retrain
        new_model = LinearRegression()
        new_model.fit(X_train, y_train)

        # Evaluate
        y_pred = new_model.predict(X_test)
        mse = round(float(mean_squared_error(y_test, y_pred)), 4)
        r2  = round(float(r2_score(y_test, y_pred)), 4)

        # Save updated model and scaler
        with open(os.path.join(BASE_DIR, "best_model.pkl"), "wb") as f:
            pickle.dump(new_model, f)
        with open(os.path.join(BASE_DIR, "scaler.pkl"), "wb") as f:
            pickle.dump(new_scaler, f)
        with open(os.path.join(BASE_DIR, "feature_names.pkl"), "wb") as f:
            pickle.dump(list(X.columns), f)

        # Update in-memory model
        model        = new_model
        scaler       = new_scaler
        feature_names = list(X.columns)

        return RetrainResponse(
            message="Model retrained successfully with new data",
            model_type="LinearRegression",
            test_mse=mse,
            r2_score=r2
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
