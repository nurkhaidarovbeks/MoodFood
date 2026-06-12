import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class IngredientsProvider extends ChangeNotifier {
  static const _key = 'home_ingredients';

  List<String> _ingredients = [];
  bool _loaded = false;

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
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _ingredients = prefs.getStringList(_key) ?? [];
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final lower = _ingredients.map((e) => e.toLowerCase()).toSet();
    if (lower.contains(trimmed.toLowerCase())) return;
    _ingredients = [..._ingredients, trimmed];
    await _save();
    notifyListeners();
  }

  Future<void> remove(String name) async {
    _ingredients = _ingredients
        .where((e) => e.toLowerCase() != name.toLowerCase())
        .toList();
    await _save();
    notifyListeners();
  }

  Future<void> toggle(String name) async {
    final lower = _ingredients.map((e) => e.toLowerCase()).toSet();
    if (lower.contains(name.toLowerCase())) {
      await remove(name);
    } else {
      await add(name);
    }
  }

  bool has(String name) =>
      _ingredients.any((e) => e.toLowerCase() == name.toLowerCase());

  Future<void> clear() async {
    _ingredients = [];
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _ingredients);
  }
}
