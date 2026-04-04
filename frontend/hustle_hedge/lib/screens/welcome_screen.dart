import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../user_registration/screens/registration_chat_screen.dart';
import 'sign_in_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _animController.forward();
    });
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
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              // Logo
              FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'H',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Headline
              SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            fontFamily: AppTheme.fontFamily,
                            color: AppTheme.textPrimary,
                          ),
                          children: [
                            TextSpan(text: 'Welcome to\n'),
                            TextSpan(
                              text: 'HustleHedge.',
                              style: TextStyle(color: AppTheme.secondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "Insurance built for gig workers.\nProtect your hustle, your way.",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                          height: 1.6,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3),
              // Buttons
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegistrationChatScreen(),
                        ),
                      ),
                      child: const Text("I'm new here — Sign Up"),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignInScreen(),
                        ),
                      ),
                      child: const Text('Sign In'),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'By continuing, you agree to our Terms & Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textHint,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 16),
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