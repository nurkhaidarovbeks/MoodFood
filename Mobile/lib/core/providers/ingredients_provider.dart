import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/pantry_service.dart';

class IngredientCategory {
  final String emoji;
  final String label;
  final List<String> items;

  const IngredientCategory({
    required this.emoji,
    required this.label,
    required this.items,
  });
}

/// Backs the "What's in Your Fridge?" screen.
///
/// Offline-first: keeps a local SharedPreferences cache for instant display
/// and guest mode, but syncs every change to the backend `/pantry` so the
/// data lives in the DB and powers ingredient-based recommendations.
class IngredientsProvider extends ChangeNotifier {
  static const _key = 'home_ingredients';

  final _pantry = PantryService();

  List<String> _ingredients = [];
  bool _loaded = false;

  /// Lowercase ingredient name → backend pantry item id (for single delete).
  final Map<String, String> _idByName = {};

  List<String> get ingredients => List.unmodifiable(_ingredients);
  bool get isEmpty => _ingredients.isEmpty;

  static const List<IngredientCategory> categories = [
    IngredientCategory(
      emoji: '🥚',
      label: 'Dairy & Eggs',
      items: ['Eggs', 'Milk', 'Butter', 'Cheese', 'Yogurt', 'Sour cream'],
    ),
    IngredientCategory(
      emoji: '🍗',
      label: 'Meat & Fish',
      items: ['Chicken', 'Beef', 'Pork', 'Salmon', 'Tuna', 'Shrimp'],
    ),
    IngredientCategory(
      emoji: '🍚',
      label: 'Grains',
      items: ['Rice', 'Pasta', 'Bread', 'Oats', 'Flour', 'Noodles'],
    ),
    IngredientCategory(
      emoji: '🥦',
      label: 'Vegetables',
      items: [
        'Tomato',
        'Onion',
        'Garlic',
        'Potato',
        'Carrot',
        'Cucumber',
        'Spinach',
        'Broccoli',
        'Bell pepper',
        'Lettuce',
      ],
    ),
    IngredientCategory(
      emoji: '🍎',
      label: 'Fruits',
      items: ['Apple', 'Banana', 'Orange', 'Lemon', 'Berries', 'Mango'],
    ),
    IngredientCategory(
      emoji: '🫙',
      label: 'Pantry',
      items: [
        'Olive oil',
        'Salt',
        'Pepper',
        'Soy sauce',
        'Honey',
        'Sugar',
        'Tomato paste',
        'Coconut milk',
      ],
    ),
  ];

  Future<void> load() async {
    // Show the local cache instantly (and it's the source of truth in guest
    // mode), then reconcile with the backend pantry.
    if (!_loaded) {
      final prefs = await SharedPreferences.getInstance();
      _ingredients = prefs.getStringList(_key) ?? [];
      _loaded = true;
      notifyListeners();
    }
    await _pullBackend();
  }

  /// Fetch the pantry from the DB and reconcile it with the local cache.
  /// No-op (keeps local data) when the backend is unreachable or in guest mode.
  Future<void> _pullBackend() async {
    final items = await _pantry.getPantry();
    if (items == null) return; // offline / guest — keep local cache

    _idByName
      ..clear()
      ..addEntries(items.map((i) => MapEntry(i.name.toLowerCase(), i.id)));

    // Preserve nicer display casing from the local list when names match.
    final displayByLower = {
      for (final n in _ingredients) n.toLowerCase(): n,
    };
    _ingredients = items
        .map((i) => displayByLower[i.name.toLowerCase()] ?? _titleCase(i.name))
        .toList();

    await _saveCache();
    notifyListeners();
  }

  Future<void> add(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || has(trimmed)) return;

    // Optimistic local update
    _ingredients = [..._ingredients, trimmed];
    await _saveCache();
    notifyListeners();

    // Sync to backend, then refresh ids so a later delete can target this item.
    final ok = await _pantry.addIngredients([trimmed]);
    if (ok) await _pullBackend();
  }

  Future<void> remove(String name) async {
    final lower = name.toLowerCase();

    // Optimistic local update
    _ingredients =
        _ingredients.where((e) => e.toLowerCase() != lower).toList();
    await _saveCache();
    notifyListeners();

    // Resolve the backend id (refresh once if we don't have it yet), then delete.
    var id = _idByName[lower];
    if (id == null) {
      await _pullBackendIds();
      id = _idByName[lower];
    }
    if (id != null) {
      final ok = await _pantry.removeIngredient(id);
      if (ok) _idByName.remove(lower);
    }
  }

  Future<void> toggle(String name) async {
    if (has(name)) {
      await remove(name);
    } else {
      await add(name);
    }
  }

  bool has(String name) =>
      _ingredients.any((e) => e.toLowerCase() == name.toLowerCase());

  Future<void> clear() async {
    _ingredients = [];
    _idByName.clear();
    await _saveCache();
    notifyListeners();
    await _pantry.clearPantry();
  }

  /// Refresh only the id map (used to resolve a delete target).
  Future<void> _pullBackendIds() async {
    final items = await _pantry.getPantry();
    if (items == null) return;
    _idByName
      ..clear()
      ..addEntries(items.map((i) => MapEntry(i.name.toLowerCase(), i.id)));
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _ingredients);
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
