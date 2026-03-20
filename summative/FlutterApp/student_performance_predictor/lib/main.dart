import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Performance Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A56DB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE02424)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE02424), width: 2),
          ),
        ),
      ),
      home: const PredictionPage(),
    );
  }
}

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  //API URL
  static const String _apiUrl =
      'https://student-performance-api-2sd5.onrender.com/predict';

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _hoursController = TextEditingController();
  final _scoresController = TextEditingController();
  final _extraController = TextEditingController();
  final _sleepController = TextEditingController();
  final _samplesController = TextEditingController();

  // State
  bool _isLoading = false;
  String _resultText = '';
  bool _hasError = false;
  bool _hasPrediction = false;

  @override
  void dispose() {
    _hoursController.dispose();
    _scoresController.dispose();
    _extraController.dispose();
    _sleepController.dispose();
    _samplesController.dispose();
    super.dispose();
  }

  // Validate and call API
  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _resultText = '';
      _hasError = false;
      _hasPrediction = false;
    });

    try {
      final body = jsonEncode({
        'hours_studied': double.parse(_hoursController.text.trim()),
        'previous_scores': double.parse(_scoresController.text.trim()),
        'extracurricular_activities': int.parse(_extraController.text.trim()),
        'sleep_hours': double.parse(_sleepController.text.trim()),
        'sample_question_papers_practiced':
            double.parse(_samplesController.text.trim()),
      });

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prediction = data['predicted_performance_index'];
        setState(() {
          _resultText = prediction.toStringAsFixed(2);
          _hasPrediction = true;
          _hasError = false;
        });
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        setState(() {
          _resultText =
              'Validation error: one or more values are out of range.';
          _hasError = true;
        });
      } else {
        setState(() {
          _resultText =
              'Server error (${response.statusCode}). Please try again.';
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _resultText =
            'Connection error. Please check your internet connection.';
        _hasError = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Input field builder
  Widget _buildField({
    required String label,
    required String hint,
    required String range,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.number,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111928),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              range,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Student Performance Predictor',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF5FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter Student Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Fill in all fields to predict the student\'s Performance Index.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Field 1: Hours Studied
                _buildField(
                  label: 'Hours Studied',
                  hint: 'e.g. 7',
                  range: '(1 – 9)',
                  controller: _hoursController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'This field is required';
                    final val = double.tryParse(v.trim());
                    if (val == null) return 'Enter a valid number';
                    if (val < 1 || val > 9)
                      return 'Value must be between 1 and 9';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Field 2: Previous Scores
                _buildField(
                  label: 'Previous Scores',
                  hint: 'e.g. 75',
                  range: '(40 – 99)',
                  controller: _scoresController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'This field is required';
                    final val = double.tryParse(v.trim());
                    if (val == null) return 'Enter a valid number';
                    if (val < 40 || val > 99)
                      return 'Value must be between 40 and 99';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Field 3: Extracurricular Activities
                _buildField(
                  label: 'Extracurricular Activities',
                  hint: '1 = Yes, 0 = No',
                  range: '(0 or 1)',
                  controller: _extraController,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'This field is required';
                    final val = int.tryParse(v.trim());
                    if (val == null) return 'Enter 0 or 1';
                    if (val != 0 && val != 1)
                      return 'Value must be 0 (No) or 1 (Yes)';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Field 4: Sleep Hours
                _buildField(
                  label: 'Sleep Hours',
                  hint: 'e.g. 7',
                  range: '(4 – 9)',
                  controller: _sleepController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'This field is required';
                    final val = double.tryParse(v.trim());
                    if (val == null) return 'Enter a valid number';
                    if (val < 4 || val > 9)
                      return 'Value must be between 4 and 9';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Field 5: Sample Papers Practiced
                _buildField(
                  label: 'Sample Papers Practiced',
                  hint: 'e.g. 5',
                  range: '(0 – 9)',
                  controller: _samplesController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'This field is required';
                    final val = double.tryParse(v.trim());
                    if (val == null) return 'Enter a valid number';
                    if (val < 0 || val > 9)
                      return 'Value must be between 0 and 9';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Predict Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _predict,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56DB),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF93C5FD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Predict',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Result Display Area
                if (_hasPrediction || _hasError)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _hasError
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _hasError
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFF86EFAC),
                      ),
                    ),
                    child: _hasError
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Color(0xFFDC2626),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _resultText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFB91C1C),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              const Text(
                                'Predicted Performance Index',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF15803D),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _resultText,
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF166534),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'out of 100',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4ADE80),
                                ),
                              ),
                            ],
                          ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
