import '../api/api_client.dart';
import '../constants/api_constants.dart';

/// A single pantry entry returned by the backend.
/// `id` is the `userIngredient` id — needed to delete a single item.
class PantryItem {
  final String id;
  final String name; // lowercase, as stored on the backend
  final String? category;

  const PantryItem({required this.id, required this.name, this.category});

  factory PantryItem.fromJson(Map<String, dynamic> j) => PantryItem(
        id: j['id'] as String,
        name: j['name'] as String,
        category: j['category'] as String?,
      );
}

/// Talks to `/pantry` — the user's fridge/cupboard stored in the DB.
class PantryService {
  final _api = ApiClient.instance;

  /// GET /pantry → list of items.
  /// Returns null on error (guest/offline) so callers can tell "backend
  /// unavailable" apart from a genuinely empty pantry (and avoid wiping the
  /// local cache).
  Future<List<PantryItem>?> getPantry() async {
    try {
      final res = await _api.dio.get(ApiConstants.pantry);
      final list = res.data as List<dynamic>? ?? [];
      return list
          .map((e) => PantryItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// POST /pantry { ingredients: [...] } — names are lowercased server-side.
  /// Returns true on success.
  Future<bool> addIngredients(List<String> names) async {
    if (names.isEmpty) return true;
    try {
      await _api.dio.post(
        ApiConstants.pantry,
        data: {'ingredients': names.map((n) => n.toLowerCase().trim()).toList()},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// DELETE /pantry/:id (the userIngredient id). Returns true on success.
  Future<bool> removeIngredient(String pantryItemId) async {
    try {
      await _api.dio.delete('${ApiConstants.pantry}/$pantryItemId');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// DELETE /pantry/clear. Returns true on success.
  Future<bool> clearPantry() async {
    try {
      await _api.dio.delete(ApiConstants.pantryClear);
      return true;
    } catch (_) {
      return false;
    }
  }
}
