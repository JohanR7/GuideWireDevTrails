import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../services/api_client.dart';
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
    
    // Submit registration data to backend automatically
    Future.delayed(const Duration(milliseconds: 1000), _submitRegistration);
  }

  Future<void> _submitRegistration() async {
    try {
      final registrationData = {
        'full_name': widget.data.fullName ?? '',
        'residential_address': widget.data.residentialAddress,
        'delivery_partner_id': widget.data.deliveryPartnerId,
        'platform': widget.data.platform,
        'date_of_birth': widget.data.dateOfBirth,
        'aadhar_number': widget.data.aadharNumber,
        'vehicle_type': widget.data.vehicleType,
        'driving_license': widget.data.drivingLicense,
      };
      
      final result = await ApiClient.submitRegistration(registrationData);
      
      if (result['success'] == true && mounted) {
        // Data submitted successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile registered successfully!')),
        );
      }
    } catch (e) {
      print('Error submitting registration: $e');
      // Continue anyway - user can still view plans
    }
  }

  Future<void> _navigateToPlans() async {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/plans');
    }
  }

  Future<void> _skipForNow() async {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/plans');
    }
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
                      onPressed: _navigateToPlans,
                      child: const Text('View My Plans'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _skipForNow,
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