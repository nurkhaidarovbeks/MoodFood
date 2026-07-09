import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../models/mood_entry_model.dart';

class MoodCheckService {
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>?> create(MoodEntry entry) async {
    try {
      final res = await _api.dio.post(
        ApiConstants.moodChecks,
        data: {
          'mood': entry.mood,
          'energyLevel': entry.energyLevel,
          'stressLevel': entry.stressLevel,
          'sleepQuality': entry.sleepQuality,
          if (entry.hungerLevel != null) 'hungerLevel': entry.hungerLevel,
        },
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLatest() async {
    try {
      final res = await _api.dio.get(ApiConstants.moodChecksLatest);
      if (res.data == null) return null;
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException {
      return null;
    }
  }

  /// GET /mood-checks — history as MoodEntry list (newest first).
  /// Returns null on error so the provider can keep its local cache.
  Future<List<MoodEntry>?> history({int limit = 60}) async {
    try {
      final res = await _api.dio.get(
        ApiConstants.moodChecks,
        queryParameters: {'limit': limit},
      );
      final data = res.data;
      final list =
          data is Map ? (data['moodChecks'] as List<dynamic>? ?? []) : [];
      return list.map((e) {
        final j = Map<String, dynamic>.from(e as Map);
        return MoodEntry(
          id: j['id'] as String? ?? '',
          timestamp: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
              DateTime.now(),
          mood: j['mood'] as String? ?? 'happy',
          energyLevel: (j['energyLevel'] as num?)?.toInt() ?? 3,
          stressLevel: j['stressLevel'] as String? ?? 'medium',
          sleepQuality: j['sleepQuality'] as String? ?? 'normal',
          hungerLevel: j['hungerLevel'] as String?,
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }
}
