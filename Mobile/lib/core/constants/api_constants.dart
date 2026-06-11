class ApiConstants {
  // iOS Simulator / desktop: localhost
  // Android emulator: 10.0.2.2
  static const String baseUrl = 'http://localhost:3000/api/v1';

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String googleAuth = '/auth/google';
  static const String otpSend = '/auth/otp/send';
  static const String otpVerify = '/auth/otp/verify';
  static const String profile = '/profile';
  static const String recipes = '/recipes';
  static const String recommendations = '/recipes/recommendations';

  static const List<String> moodTags = [
    'happy',
    'energetic',
    'calm',
    'focused',
    'cozy',
  ];
}
