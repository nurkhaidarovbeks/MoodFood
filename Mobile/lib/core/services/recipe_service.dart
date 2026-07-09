import '../api/api_client.dart';
import '../models/recipe_model.dart';

class RecipeService {
  final ApiClient _api;

  RecipeService(this._api);

  /// Fetches the FULL catalogue (backend caps each page at 100, so we paginate
  /// until a short page comes back). This is why the list shows all ~168
  /// recipes instead of only the first 20.
  Future<List<Recipe>> getRecipes({String? mood}) async {
    const pageSize = 100;
    final all = <Recipe>[];
    var offset = 0;

    while (true) {
      final response = await _api.dio.get(
        '/recipes',
        queryParameters: {
          'mood': ?mood,
          'limit': pageSize,
          'offset': offset,
        },
      );
      final data = response.data;
      final list = data is List
          ? data
          : (data is Map ? (data['recipes'] as List? ?? []) : const []);
      final page = list
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
      all.addAll(page);
      if (page.length < pageSize) break; // last page
      offset += pageSize;
      if (offset > 2000) break; // safety guard
    }
    return all;
  }

  Future<List<Recipe>> getRecommendations({
    String? mood,
    int limit = 20,
    bool useMyIngredients = false,
  }) async {
    final response = await _api.dio.get(
      '/recipes/recommendations',
      queryParameters: {
        'mood': ?mood,
        'limit': limit,
        if (useMyIngredients) 'useMyIngredients': 'true',
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
