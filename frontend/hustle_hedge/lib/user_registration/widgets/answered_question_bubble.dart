import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../models/registration_question.dart';

class AnsweredQuestionBubble extends StatelessWidget {
  final RegistrationQuestion question;
  final String answer;

  const AnsweredQuestionBubble({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bot message
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.only(bottom: 6, right: 48),
            decoration: BoxDecoration(
              color: AppTheme.secondaryMuted,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Text(
              question.message.replaceAll('\n', ' '),
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
        ),
        // User answer
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.only(bottom: 20, left: 48),
            decoration: BoxDecoration(
              color: AppTheme.secondary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}