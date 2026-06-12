import '../api/api_client.dart';
import '../models/recipe_model.dart';

class RecipeService {
  final ApiClient _api;

  RecipeService(this._api);

  Future<List<Recipe>> getRecipes({String? mood, int limit = 20}) async {
    final response = await _api.dio.get(
      '/recipes',
      queryParameters: {
        if (mood != null) 'mood': mood,
        'limit': limit,
      },
    );
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map && data['recipes'] != null) {
      return (data['recipes'] as List)
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<Recipe>> getRecommendations({String? mood, int limit = 20}) async {
    final response = await _api.dio.get(
      '/recipes/recommendations',
      queryParameters: {
        if (mood != null) 'mood': mood,
        'limit': limit,
      },
    );
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map && data['recipes'] != null) {
      return (data['recipes'] as List)
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
