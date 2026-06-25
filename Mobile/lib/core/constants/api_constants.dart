class ApiConstants {
  static const String baseUrl = 'https://moodfood-backend.onrender.com/api/v1';

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String googleAuth = '/auth/google';
  static const String otpSend = '/auth/otp/send';
  static const String otpVerify = '/auth/otp/verify';
  static const String profile = '/profile';
  static const String recipes = '/recipes';
  static const String recommendations = '/recipes/recommendations';
  static const String pantry = '/pantry';
  static const String pantryClear = '/pantry/clear';

  // Subscriptions & Payments
  static const String subscriptionPlans = '/subscriptions/plans';
  static const String subscriptionSubscribe = '/subscriptions/subscribe';
  static const String subscriptionMe = '/subscriptions/me';
  static const String subscriptionCancel = '/subscriptions/me';

  // Mood checks
  static const String moodChecks = '/mood-checks';
  static const String moodChecksLatest = '/mood-checks/latest';

  // AI Recommendations
  static const String aiRecommendations = '/recommendations';

  static const List<String> moodTags = [
    'happy',
    'energetic',
    'calm',
    'focused',
    'cozy',
  ];
}
