import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../models/mood_entry_model.dart';

class RecommendationOption {
  final String category;
  final int fitScore;
  final String explanation;
  final RecommendationRecipe recipe;
  final double? matchScore;
  final List<String> missingIngredients;

  const RecommendationOption({
    required this.category,
    required this.fitScore,
    required this.explanation,
    required this.recipe,
    this.matchScore,
    this.missingIngredients = const [],
  });

  factory RecommendationOption.fromJson(Map<String, dynamic> j) =>
      RecommendationOption(
        category: j['category'] as String? ?? '',
        fitScore: (j['fitScore'] as num?)?.toInt() ?? 0,
        explanation: j['explanation'] as String? ?? '',
        recipe: RecommendationRecipe.fromJson(
            Map<String, dynamic>.from(j['recipe'] as Map)),
        matchScore: (j['matchScore'] as num?)?.toDouble(),
        missingIngredients: (j['missingIngredients'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class RecommendationRecipe {
  final String id;
  final String title;
  final int? cookingTimeMin;
  final String? difficulty;
  final int? estimatedCost;
  final int? calories;
  final int? proteinG;
  final List<String> moodTags;

  const RecommendationRecipe({
    required this.id,
    required this.title,
    this.cookingTimeMin,
    this.difficulty,
    this.estimatedCost,
    this.calories,
    this.proteinG,
    this.moodTags = const [],
  });

  factory RecommendationRecipe.fromJson(Map<String, dynamic> j) =>
      RecommendationRecipe(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        cookingTimeMin: (j['cookingTimeMin'] as num?)?.toInt(),
        difficulty: j['difficulty'] as String?,
        estimatedCost: (j['estimatedCost'] as num?)?.toInt(),
        calories: (j['calories'] as num?)?.toInt(),
        proteinG: (j['proteinG'] as num?)?.toInt(),
        moodTags: (j['moodTags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class RecommendationResult {
  final List<RecommendationOption> options;
  final bool aiPowered;

  const RecommendationResult({
    required this.options,
    required this.aiPowered,
  });
}

class RecommendationService {
  final _api = ApiClient.instance;

  Future<RecommendationResult?> recommend({
    required MoodEntry entry,
    bool useMyIngredients = false,
    int? maxCookingTime,
  }) async {
    try {
      final res = await _api.dio.post(
        ApiConstants.aiRecommendations,
        data: {
          'mood': entry.mood,
          'energyLevel': entry.energyLevel,
          'stressLevel': entry.stressLevel,
          'sleepQuality': entry.sleepQuality,
          if (entry.hungerLevel != null) 'hungerLevel': entry.hungerLevel,
          'useMyIngredients': useMyIngredients,
          if (maxCookingTime != null) 'maxCookingTime': maxCookingTime!,
        },
      );
      final data = res.data as Map;
      final options = (data['options'] as List<dynamic>)
          .map((o) => RecommendationOption.fromJson(
              Map<String, dynamic>.from(o as Map)))
          .toList();
      return RecommendationResult(
        options: options,
        aiPowered: data['aiPowered'] as bool? ?? false,
      );
    } on DioException {
      return null;
    }
  }
}
