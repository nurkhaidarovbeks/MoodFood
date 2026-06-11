import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const ApiException(this.message, {this.code, this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static ApiClient? _instance;
  late final Dio dio;

  ApiClient._() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.get();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  ApiException handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] as String? ?? 'Something went wrong';
        final code = data['error'] as String?;
        return ApiException(
          _friendlyMessage(code, message),
          code: code,
          statusCode: e.response!.statusCode,
        );
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ApiException('Connection timeout. Check your internet.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const ApiException(
        'Cannot reach server. Make sure the backend is running.',
      );
    }
    return ApiException(e.message ?? 'Unknown error');
  }

  String _friendlyMessage(String? code, String fallback) {
    switch (code) {
      case 'EMAIL_EXISTS':
        return 'This email is already registered. Try signing in.';
      case 'INVALID_CREDENTIALS':
        return 'Wrong email or password. Please try again.';
      case 'ACCOUNT_INACTIVE':
        return 'Your account is inactive. Contact support.';
      case 'EMAIL_NOT_VERIFIED':
        return 'Please verify your email first.';
      case 'INVALID_OTP':
        return 'Invalid or expired code. Request a new one.';
      case 'OTP_MAX_ATTEMPTS':
        return 'Too many attempts. Please request a new code.';
      case 'OTP_RATE_LIMITED':
        return 'Please wait a moment before requesting another code.';
      case 'UNAUTHORIZED':
        return 'Session expired. Please sign in again.';
      default:
        return fallback;
    }
  }
}
