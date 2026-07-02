import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../constants/api_constants.dart';

/// A sent reminder — mirrors an item from GET /notifications/history.
class NotificationItem {
  final String type; // 'water' | 'meal'
  final String title;
  final String body;
  final DateTime sentAt;

  const NotificationItem({
    required this.type,
    required this.title,
    required this.body,
    required this.sentAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        type: j['type'] as String? ?? 'water',
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        sentAt: DateTime.tryParse(j['sentAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Reminder preferences — mirrors GET /notifications/preferences.
class NotificationPreferences {
  final bool waterRemindersOn;
  final int waterIntervalMin;
  final bool mealRemindersOn;
  final String wakeTime;
  final String sleepTime;

  const NotificationPreferences({
    required this.waterRemindersOn,
    required this.waterIntervalMin,
    required this.mealRemindersOn,
    required this.wakeTime,
    required this.sleepTime,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> j) =>
      NotificationPreferences(
        waterRemindersOn: j['waterRemindersOn'] as bool? ?? true,
        waterIntervalMin: (j['waterIntervalMin'] as num?)?.toInt() ?? 120,
        mealRemindersOn: j['mealRemindersOn'] as bool? ?? true,
        wakeTime: j['wakeTime'] as String? ?? '08:00',
        sleepTime: j['sleepTime'] as String? ?? '23:00',
      );

  static const defaults = NotificationPreferences(
    waterRemindersOn: true,
    waterIntervalMin: 120,
    mealRemindersOn: true,
    wakeTime: '08:00',
    sleepTime: '23:00',
  );
}

class NotificationService {
  final _api = ApiClient.instance;

  Future<List<NotificationItem>> history({int limit = 20}) async {
    try {
      final res = await _api.dio.get(
        ApiConstants.notificationHistory,
        queryParameters: {'limit': limit},
      );
      final data = res.data;
      final items = data is Map ? (data['items'] as List<dynamic>? ?? []) : [];
      return items
          .map((e) =>
              NotificationItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<NotificationPreferences?> getPreferences() async {
    try {
      final res = await _api.dio.get(ApiConstants.notificationPreferences);
      return NotificationPreferences.fromJson(
          Map<String, dynamic>.from(res.data as Map));
    } catch (_) {
      return null;
    }
  }

  /// Update reminder toggles. Returns the refreshed prefs, or null on error.
  Future<NotificationPreferences?> updatePreferences({
    bool? waterRemindersOn,
    bool? mealRemindersOn,
    int? waterIntervalMin,
  }) async {
    try {
      final res = await _api.dio.put(
        ApiConstants.notificationPreferences,
        data: {
          if (waterRemindersOn != null) 'waterRemindersOn': waterRemindersOn,
          if (mealRemindersOn != null) 'mealRemindersOn': mealRemindersOn,
          if (waterIntervalMin != null) 'waterIntervalMin': waterIntervalMin,
        },
      );
      return NotificationPreferences.fromJson(
          Map<String, dynamic>.from(res.data as Map));
    } on DioException {
      return null;
    }
  }
}
