import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _mobileController = TextEditingController(text: '9876543210');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-login on load
    Future.delayed(const Duration(milliseconds: 500), _quickLogin);
  }

  Future<void> _quickLogin() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Mock authentication - skip OTP entirely
      final authProvider = context.read<AuthProvider>();
      authProvider.setMockUser(_mobileController.text.trim());
      
      // Navigate to plans (new users) or home (existing users)
      // Delay to avoid setState during build
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        // Default to plans for new users - they can navigate from there
        Navigator.pushReplacementNamed(context, '/plans');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF1A7A7A)),
                  const SizedBox(height: 24),
                  Text(
                    'Logging you in...',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined, size: 64, color: Color(0xFF1A7A7A)),
                  const SizedBox(height: 24),
                  const Text(
                    'HustleHedge',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Insurance for Gig Workers',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _quickLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A7A7A),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
      ),
    );
  }
}
