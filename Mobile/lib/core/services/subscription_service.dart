import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../constants/api_constants.dart';

class SubscriptionService {
  final _api = ApiClient.instance;

  Future<List<Map<String, dynamic>>> getPlans() async {
    try {
      final res = await _api.dio.get(ApiConstants.subscriptionPlans);
      final List<dynamic> plans = res.data['plans'] as List<dynamic>? ?? [];
      return plans.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Returns { orderId, paymentUrl, plan }
  Future<Map<String, dynamic>> subscribe({
    required String planType,
    required String gateway,
  }) async {
    try {
      final res = await _api.dio.post(
        ApiConstants.subscriptionSubscribe,
        data: {'planType': planType, 'gateway': gateway},
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Returns null if no subscription, otherwise { status, expiresAt, plan }
  Future<Map<String, dynamic>?> getMySubscription() async {
    try {
      final res = await _api.dio.get(ApiConstants.subscriptionMe);
      if (res.data == null) return null;
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _api.handleError(e);
    }
  }

  Future<void> cancel() async {
    try {
      await _api.dio.delete(ApiConstants.subscriptionCancel);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }
}
