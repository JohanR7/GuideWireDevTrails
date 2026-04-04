import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  bool _otpSent = false;
  bool _isLoading = false;

  void _sendOtp() async {
    if (_emailController.text.trim().isEmpty ||
        !_emailController.text.contains('@')) {
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200)); // Simulate API
    if (mounted) {
      setState(() {
        _isLoading = false;
        _otpSent = true;
      });
      Future.delayed(
          const Duration(milliseconds: 100),
          () => _otpFocusNodes.first.requestFocus());
    }
  }

  void _verifyOtp() {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) return;
    // TODO: Verify OTP with backend
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _otpSent ? _OtpView(
            key: const ValueKey('otp'),
            email: _emailController.text,
            controllers: _otpControllers,
            focusNodes: _otpFocusNodes,
            onVerify: _verifyOtp,
            onResend: () {
              // resend logic
            },
          ) : _EmailView(
            key: const ValueKey('email'),
            controller: _emailController,
            isLoading: _isLoading,
            onSend: _sendOtp,
          ),
        ),
      ),
    );
  }
}

// --- Email Input View ---

class _EmailView extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  const _EmailView({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Sign in to\nHustleHedge.',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            height: 1.25,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Enter your email and we'll send you a one-time code.",
          style: TextStyle(
            fontSize: 15,
            color: AppTheme.textSecondary,
            height: 1.5,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        const SizedBox(height: 36),
        TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => onSend(),
          style: const TextStyle(
            fontSize: 15,
            fontFamily: AppTheme.fontFamily,
          ),
          decoration: const InputDecoration(
            hintText: 'your@email.com',
            prefixIcon: Icon(Icons.mail_outline_rounded,
                color: AppTheme.secondary, size: 20),
          ),
        ),
        const SizedBox(height: 20),
        isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.secondary),
                  strokeWidth: 2.5,
                ),
              )
            : ElevatedButton(
                onPressed: onSend,
                child: const Text('Send OTP'),
              ),
      ],
    );
  }
}

// --- OTP Input View ---

class _OtpView extends StatelessWidget {
  final String email;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  const _OtpView({
    super.key,
    required this.email,
    required this.controllers,
    required this.focusNodes,
    required this.onVerify,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Check your\nemail.',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            height: 1.25,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "We sent a 6-digit code to $email",
          style: const TextStyle(
            fontSize: 15,
            color: AppTheme.textSecondary,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        const SizedBox(height: 36),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 46,
              height: 56,
              child: TextField(
                controller: controllers[i],
                focusNode: focusNodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTheme.fontFamily,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.secondary, width: 2),
                  ),
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && i < 5) {
                    focusNodes[i + 1].requestFocus();
                  }
                  if (val.isEmpty && i > 0) {
                    focusNodes[i - 1].requestFocus();
                  }
                  // Auto-submit when all filled
                  if (i == 5 && val.isNotEmpty) {
                    onVerify();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onVerify,
          child: const Text('Verify & Sign In'),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: onResend,
            child: const Text(
              "Didn't receive it? Resend",
              style: TextStyle(
                color: AppTheme.secondary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
        ),
      ],
    );
  }
}