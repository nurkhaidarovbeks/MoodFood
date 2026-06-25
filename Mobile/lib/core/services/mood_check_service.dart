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
}
