# Student Performance Prediction – Summative Assignment

This repository presents our implementation of a **Multivariate Linear Regression** model as part of the **Summative Assignment** for the Machine Learning module.

The project focuses on predicting student academic performance using study habits and personal factors, applying **Linear Regression, Decision Tree, and Random Forest** models built with the **scikit-learn** library.

---

## Context and Objective

Student academic performance is influenced by multiple factors that interact in complex ways. Identifying which factors matter most can help educators intervene early and provide targeted support.

The objective of this project is to:

- Build and compare three regression models (Linear Regression, Decision Tree, Random Forest)
- Identify which features most influence student performance
- Save the best-performing model for future use in a prediction API
- Optimize the linear regression model using gradient descent

---

## Dataset Description

**Dataset used:**

```
Student_Performance.csv
```

- **Source:** [Kaggle – Student Performance Multiple Linear Regression](https://www.kaggle.com/datasets/nikhil7280/student-performance-multiple-linear-regression)
- **Rows:** 10,000
- **Columns:** 6
- **Target variable:** `Performance Index` (0–100)

The dataset contains student records including study hours, previous academic scores, sleep patterns, extracurricular participation, and sample paper practice. It has no missing values and includes one categorical column that was converted to numeric for modeling.

---

## Implementation Overview

All steps were implemented using the scikit-learn library and standard Python data science tools:

- Loading and inspecting the dataset
- Visualizing feature distributions and correlations
- Feature engineering (encoding categorical columns and determining feature weights)
- Standardizing all features using StandardScaler
- Splitting data into training (80%) and test (20%) sets
- Training three models: Linear Regression, Decision Tree, and Random Forest
- Plotting the loss curve for train and test data using gradient descent (SGDRegressor)
- Plotting a scatter plot before and after fitting the linear regression line
- Comparing models by MSE and R2 score
- Saving the best-performing model to disk

The full implementation is available in the notebook below.

**Notebook:**

```
linear_regression_model/summative/linear_regression/multivariate.ipynb
```

---

## Project Structure

```
linear_regression_model/
│
├── summative/
│   ├── linear_regression/
│   │   ├── multivariate.ipynb
│   │   ├── Student_Performance.csv
│   │   ├── best_model.pkl
│   │   ├── scaler.pkl
│   │   ├── feature_names.pkl
│   │   └── x_test.csv
│   ├── API/                        # Coming in Part 2
│   └── FlutterApp/                 # Coming in Part 3
```

---

## Technical Requirements

To run this project locally, ensure the following dependencies are installed:

- Python 3.x
- NumPy
- Pandas
- Matplotlib
- Seaborn
- Scikit-learn

Install them using:

```
pip install numpy pandas matplotlib seaborn scikit-learn
```

---

## How to Run

**1.** Clone the repository:

```
git clone https://github.com/Adossi-design/linear_regression_model.git
```

**2.** Open the project directory.

**3.** Navigate to `linear_regression_model/summative/linear_regression/`.

**4.** Launch Jupyter Notebook:

```
jupyter notebook
```

**5.** Open `multivariate.ipynb` and execute all cells in order.

---

## Results

| Model | Train MSE | Test MSE | R2 Score |
|---|---|---|---|
| Linear Regression | 4.1697 | 4.0826 | 0.9890 |
| Random Forest | 0.9377 | 5.1712 | 0.9860 |
| Decision Tree | 0.2564 | 8.8959 | 0.9760 |

- **Linear Regression** achieved the lowest test MSE (4.08) and the highest R2 score (0.989), making it the best-performing model
- This is expected because the dataset has a very strong linear relationship between Previous Scores and Performance Index (r = 0.92)
- The loss curve confirms the model converges correctly using gradient descent
- The before/after scatter plot clearly shows the linear regression line fitting well through the data
