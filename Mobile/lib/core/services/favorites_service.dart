import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../models/recipe_model.dart';

class FavoriteItem {
  final String favoriteId;
  final Recipe recipe;
  final DateTime createdAt;

  const FavoriteItem({
    required this.favoriteId,
    required this.recipe,
    required this.createdAt,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> j) => FavoriteItem(
        favoriteId: j['id'] as String,
        recipe: Recipe.fromJson(Map<String, dynamic>.from(j['recipe'] as Map)),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class FavoritesService {
  final _api = ApiClient.instance;

  Future<List<FavoriteItem>> getFavorites({int limit = 50, int offset = 0}) async {
    try {
      final res = await _api.dio.get(
        ApiConstants.favorites,
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final list = res.data as List<dynamic>;
      return list
          .map((e) => FavoriteItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException {
      return [];
    }
  }

  /// Returns favoriteId on success, null on error.
  Future<String?> addFavorite(String recipeId) async {
    try {
      final res = await _api.dio.post(
        ApiConstants.favorites,
        data: {'recipeId': recipeId},
      );
      return res.data['id'] as String?;
    } on DioException {
      return null;
    }
  }

  /// Returns true on success.
  Future<bool> removeFavorite(String favoriteId) async {
    try {
      await _api.dio.delete('${ApiConstants.favorites}/$favoriteId');
      return true;
    } on DioException {
      return false;
    }
  }

  /// Returns (isFavorite, favoriteId).
  Future<(bool, String?)> checkFavorite(String recipeId) async {
    try {
      final res = await _api.dio.get('${ApiConstants.favorites}/check/$recipeId');
      final data = res.data as Map;
      final isFav = data['isFavorite'] as bool? ?? false;
      final favId = data['favoriteId'] as String?;
      return (isFav, favId);
    } on DioException {
      return (false, null);
    }
  }
}
