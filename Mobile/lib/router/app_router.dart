import 'package:flutter/material.dart';
import '../core/models/mood_entry_model.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/onboarding/screens/profile_setup_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/premium/screens/premium_screen.dart';
import '../features/mood/screens/mood_check_screen.dart';
import '../features/mood/screens/mood_history_screen.dart';
import '../features/ingredients/screens/ingredients_screen.dart';
import '../features/recipes/screens/recipes_screen.dart';
import '../features/recommendations/screens/recommendations_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/premium/screens/payment_success_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case '/splash':
        return _fade(const SplashScreen());
      case '/onboarding':
        return _fade(const OnboardingScreen());
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
        final isEditing = settings.arguments as bool? ?? false;
        return MaterialPageRoute(
          builder: (_) => ProfileSetupScreen(isEditing: isEditing),
        );
      case '/home':
        return _fade(const HomeScreen());
      case '/mood-check':
        return MaterialPageRoute(
          builder: (_) => const MoodCheckScreen(),
          fullscreenDialog: true,
        );
      case '/mood-history':
        return MaterialPageRoute(builder: (_) => const MoodHistoryScreen());
      case '/ingredients':
        return MaterialPageRoute(builder: (_) => const IngredientsScreen());
      case '/recipes':
        return MaterialPageRoute(builder: (_) => const RecipesScreen());
      case '/recommendations':
        final entry = settings.arguments as MoodEntry?;
        return MaterialPageRoute(
          builder: (_) => RecommendationsScreen(moodEntry: entry),
          fullscreenDialog: true,
        );
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/premium':
        return MaterialPageRoute(builder: (_) => const PremiumScreen());
      case '/notifications':
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case '/payment-success':
        return _slide(const PaymentSuccessScreen());
      case '/edit-profile':
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
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
