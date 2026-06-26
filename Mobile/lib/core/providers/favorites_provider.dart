import 'package:flutter/foundation.dart';
import '../services/favorites_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final _service = FavoritesService();

  List<FavoriteItem> _items = [];
  bool _loading = false;

  List<FavoriteItem> get items => _items;
  bool get loading => _loading;

  /// Map recipeId → favoriteId for O(1) lookup
  final Map<String, String> _favoriteIds = {};

  bool isFavorite(String recipeId) => _favoriteIds.containsKey(recipeId);
  String? favoriteId(String recipeId) => _favoriteIds[recipeId];

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await _service.getFavorites();
    _favoriteIds
      ..clear()
      ..addEntries(_items.map((i) => MapEntry(i.recipe.id, i.favoriteId)));
    _loading = false;
    notifyListeners();
  }

  Future<void> toggle(String recipeId) async {
    if (isFavorite(recipeId)) {
      final favId = _favoriteIds[recipeId]!;
      // Optimistic update
      _favoriteIds.remove(recipeId);
      _items.removeWhere((i) => i.favoriteId == favId);
      notifyListeners();
      await _service.removeFavorite(favId);
    } else {
      // Optimistic update with a temp id
      const tempId = '__temp__';
      _favoriteIds[recipeId] = tempId;
      notifyListeners();
      final newId = await _service.addFavorite(recipeId);
      if (newId != null) {
        _favoriteIds[recipeId] = newId;
      } else {
        _favoriteIds.remove(recipeId);
      }
      // Reload to get full recipe data for the favorites list
      await load();
    }
  }
}
