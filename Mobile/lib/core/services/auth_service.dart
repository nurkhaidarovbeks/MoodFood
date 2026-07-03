import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';
import '../storage/token_storage.dart';

class AuthResult {
  final UserModel user;
  final String token;
  const AuthResult({required this.user, required this.token});
}

class AuthService {
  final _client = ApiClient.instance;
  Dio get _dio => _client.dio;

  Future<AuthResult> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        },
      );
      return _parseAuthResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      return _parseAuthResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  Future<void> sendOtp(String email) async {
    try {
      await _dio.post(ApiConstants.otpSend, data: {'email': email});
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  Future<AuthResult> verifyOtp({
    required String email,
    required String code,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.otpVerify,
        data: {'email': email, 'code': code},
      );
      return _parseAuthResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  Future<AuthResult> googleSignIn(String idToken) async {
    try {
      final res = await _dio.post(
        ApiConstants.googleAuth,
        data: {'idToken': idToken},
      );
      return _parseAuthResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  /// POST /auth/forgot-password — emails a reset token. Always succeeds
  /// (generic message) so accounts can't be enumerated.
  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  /// POST /auth/reset-password — sets a new password using the token from email.
  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      await _dio.post(
        '/auth/reset-password',
        data: {'token': token, 'password': password},
      );
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  Future<void> logout() => TokenStorage.clear();

  Future<AuthResult> _parseAuthResponse(Map<String, dynamic> data) async {
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;
    await TokenStorage.save(token);
    return AuthResult(user: user, token: token);
  }
}
