import 'package:flutter/material.dart';
import '../models/registration_question.dart';
import '../models/registration_questions.dart';
import '../models/registration_data.dart';

class RegistrationController extends ChangeNotifier {
  final Map<String, String> _answers = {};
  final RegistrationData registrationData = RegistrationData();

  int _currentIndex = 0;
  bool _isTyping = false; // Simulates bot "typing"
  bool _isComplete = false;

  // Active questions based on current answers
  List<RegistrationQuestion> get _activeQuestions =>
      RegistrationQuestions.getActiveQuestions(_answers);

  RegistrationQuestion? get currentQuestion {
    final active = _activeQuestions;
    if (_currentIndex >= active.length) return null;
    return active[_currentIndex];
  }

  int get currentIndex => _currentIndex;
  bool get isTyping => _isTyping;
  bool get isComplete => _isComplete;
  Map<String, String> get answers => Map.unmodifiable(_answers);

  int get totalQuestions => _activeQuestions.length;
  double get progress =>
      totalQuestions == 0 ? 0 : _currentIndex / totalQuestions;

  // Returns all questions up to and including current (for chat display)
  List<RegistrationQuestion> get displayedQuestions {
    final active = _activeQuestions;
    final end = (_currentIndex + 1).clamp(0, active.length);
    return active.sublist(0, end);
  }

  /// Called when user submits an answer
  Future<void> submitAnswer(String questionId, String value) async {
    _answers[questionId] = value;
    registrationData.setAnswer(questionId, value);

    // Show typing indicator before moving to next
    _isTyping = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));

    _isTyping = false;

    final nextActive = RegistrationQuestions.getActiveQuestions(_answers);
    if (_currentIndex + 1 >= nextActive.length) {
      _isComplete = true;
    } else {
      _currentIndex++;
    }

    notifyListeners();
  }

  /// Go back one question
  void goBack() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  bool get canGoBack => _currentIndex > 0;

  String? getAnswer(String questionId) => _answers[questionId];
}