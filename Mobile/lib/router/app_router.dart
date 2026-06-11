import 'package:flutter/material.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/onboarding/screens/profile_setup_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/mood/screens/mood_check_screen.dart';
import '../features/mood/screens/mood_history_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case '/splash':
        return _fade(const SplashScreen());
      case '/welcome':
        return _slide(const WelcomeScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/otp':
        final email = settings.arguments as String? ?? '';
        return MaterialPageRoute(builder: (_) => OtpScreen(email: email));
      case '/profile-setup':
        return MaterialPageRoute(builder: (_) => const ProfileSetupScreen());
      case '/home':
        return _fade(const HomeScreen());
      case '/mood-check':
        return MaterialPageRoute(
          builder: (_) => const MoodCheckScreen(),
          fullscreenDialog: true,
        );
      case '/mood-history':
        return MaterialPageRoute(builder: (_) => const MoodHistoryScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }

  static PageRoute<dynamic> _fade(Widget page) {
    return PageRouteBuilder<dynamic>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  static PageRoute<dynamic> _slide(Widget page) {
    return PageRouteBuilder<dynamic>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: FadeTransition(opacity: animation, child: child),
      ),
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}
