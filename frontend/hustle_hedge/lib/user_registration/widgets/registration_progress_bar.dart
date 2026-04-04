import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class RegistrationProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int current;
  final int total;

  const RegistrationProgressBar({
    super.key,
    required this.progress,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step $current of $total',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: AppTheme.divider,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
          ),
        ),
      ],
    );
  }
}