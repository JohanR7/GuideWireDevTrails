import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../models/registration_data.dart';

class RegistrationCompleteScreen extends StatefulWidget {
  final RegistrationData data;

  const RegistrationCompleteScreen({super.key, required this.data});

  @override
  State<RegistrationCompleteScreen> createState() =>
      _RegistrationCompleteScreenState();
}

class _RegistrationCompleteScreenState extends State<RegistrationCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryMuted,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.secondary,
                      size: 52,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(
                      "You're all set,\n${widget.data.fullName?.split(' ').first ?? 'there'}!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        height: 1.3,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Your profile is ready. We'll now find the best coverage plan for your hustle.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                        height: 1.6,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to home / plan selection
                      },
                      child: const Text('View My Plans'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Do this later',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}