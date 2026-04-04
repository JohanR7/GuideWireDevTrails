import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/providers.dart';
import 'services/monitoring_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/plans/plans_screen.dart';
import 'screens/policy/policy_screen.dart';
import 'screens/claims/claims_screen.dart';
import 'screens/claims/claim_result_screen.dart';
import 'user_registration/screens/registration_chat_screen.dart';
import 'models/models.dart';

void main() {
  final monitoringService = MonitoringService();
  monitoringService.initialize();
  
  runApp(MyApp(monitoringService: monitoringService));
}

class MyApp extends StatelessWidget {
  final MonitoringService monitoringService;

  const MyApp({required this.monitoringService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PolicyProvider()),
        ChangeNotifierProvider(create: (_) => ClaimsProvider()),
        ChangeNotifierProvider(create: (_) => MonitoringProvider()),
      ],
      child: MaterialApp(
        title: 'HustleHedge',
        theme: ThemeData(
          primaryColor: const Color(0xFF1A7A7A),
          fontFamily: 'Poppins',
          useMaterial3: true,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A7A7A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthGate(),
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/sign-in': (context) => const SignInScreen(),
          '/registration': (context) => const RegistrationChatScreen(),
          '/home': (context) => const HomeScreen(),
          '/plans': (context) => const PlansScreen(),
          '/policy': (context) => const PolicyScreen(),
          '/claims': (context) => const ClaimsScreen(),
          '/claim-result': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            if (args != null) {
              final claim = args['claim'] as Claim;
              final approved = args['approved'] as bool;
              return ClaimResultScreen(claim: claim, approved: approved);
            }
            return const HomeScreen(); // Fallback
          },
        },
      ),
    );
  }

  @override
  void dispose() {
    monitoringService.dispose();
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), _checkAuth);
  }

  Future<void> _checkAuth() async {
    final authProvider = context.read<AuthProvider>();
    final token = await authProvider.getStoredToken();

    if (mounted) {
      if (token != null) {
        // Token exists, check if user has a policy
        final policyProvider = context.read<PolicyProvider>();
        await policyProvider.fetchActivePolicy();
        
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            policyProvider.hasActivePolicy ? '/home' : '/plans',
          );
        }
      } else {
        // No token, go to welcome/signin flow
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}