import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api_client.dart';
import '../models/mood_entry_model.dart';
import '../services/recommendation_service.dart';

class VisionService {
  final _api = ApiClient.instance;

  /// Converts XFile to base64 with mime type.
  Future<(String, String)> _toBase64(XFile file) async {
    final bytes = await File(file.path).readAsBytes();
    final b64 = base64Encode(bytes);
    final mime = file.mimeType ??
        (file.path.endsWith('.png') ? 'image/png' : 'image/jpeg');
    return (b64, mime);
  }

  /// Photo → list of extracted ingredients.
  Future<List<String>> extractIngredients(XFile photo) async {
    try {
      final (b64, mime) = await _toBase64(photo);
      final res = await _api.dio.post(
        '/vision/ingredients',
        data: {'imageBase64': b64, 'mimeType': mime},
      );
      final items = res.data['ingredients'] as List<dynamic>? ?? [];
      return items
          .where((i) => (i['confidence'] as num? ?? 0) >= 0.4)
          .map((i) => i['name'] as String)
          .toList();
    } on DioException {
      return [];
    }
  }

  /// Photo → 3 dish recommendations (one-shot).
  Future<RecommendationResult?> recommendFromPhoto({
    required XFile photo,
    MoodEntry? moodEntry,
    int? maxCookingTime,
  }) async {
    try {
      final (b64, mime) = await _toBase64(photo);
      final res = await _api.dio.post(
        '/vision/recommendations',
        data: {
          'imageBase64': b64,
          'mimeType': mime,
          if (moodEntry != null) 'mood': moodEntry.mood,
          if (moodEntry != null) 'energyLevel': moodEntry.energyLevel,
          if (moodEntry != null) 'stressLevel': moodEntry.stressLevel,
          if (moodEntry != null) 'sleepQuality': moodEntry.sleepQuality,
          if (moodEntry?.hungerLevel != null) 'hungerLevel': moodEntry!.hungerLevel,
          if (maxCookingTime != null) 'maxCookingTime': maxCookingTime,
        },
      );
      final data = res.data as Map;
      final options = (data['options'] as List<dynamic>)
          .map((o) => RecommendationOption.fromJson(
              Map<String, dynamic>.from(o as Map)))
          .toList();
      return RecommendationResult(
        options: options,
        aiPowered: data['aiPowered'] as bool? ?? true,
      );
    } on DioException {
      return null;
    }
  }
}
