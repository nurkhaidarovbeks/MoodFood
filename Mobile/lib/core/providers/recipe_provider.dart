import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/recipe_model.dart';
import '../services/recipe_service.dart';

enum RecipeFilter { all, canMake }

class RecipeProvider extends ChangeNotifier {
  final RecipeService _service;

  RecipeProvider() : _service = RecipeService(ApiClient.instance);

  List<Recipe> _recipes = [];
  RecipeFilter _filter = RecipeFilter.all;
  bool _loading = false;
  String? _error;

  List<Recipe> get recipes => _recipes;
  RecipeFilter get filter => _filter;
  bool get loading => _loading;
  String? get error => _error;

  List<Recipe> filtered(List<String> pantry) {
    if (_filter == RecipeFilter.canMake) {
      return _recipes.where((r) => r.canMakeWith(pantry)).toList();
    }
    return _recipes;
  }

  void setFilter(RecipeFilter f) {
    _filter = f;
    notifyListeners();
  }

  Future<void> fetchRecipes({String? mood}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _recipes = await _service.getRecipes(mood: mood);
    } on DioException catch (e) {
      _error = ApiClient.instance.handleError(e).message;
    } catch (e) {
      _error = 'Failed to load recipes';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void loadMockData() {
    _recipes = [
      const Recipe(
        id: 'm1',
        title: 'Scrambled Eggs & Toast',
        cookingTimeMin: 10,
        difficulty: 'easy',
        estimatedCost: 350.0,
        calories: 420.0,
        proteinG: 22.0,
        steps: '1. Crack 3 eggs into a bowl and whisk with a pinch of salt.\n'
            '2. Heat butter in a pan over medium-low heat.\n'
            '3. Add eggs and stir gently until just set.\n'
            '4. Toast bread and serve together.',
        moodTags: ['tired', 'low_energy'],
        ingredients: [
          RecipeIngredient(id: 'i1', name: 'Eggs', category: 'dairy', amount: '3', unit: 'pcs'),
          RecipeIngredient(id: 'i2', name: 'Butter', category: 'dairy', amount: '1', unit: 'tbsp'),
          RecipeIngredient(id: 'i3', name: 'Bread', category: 'grains', amount: '2', unit: 'slices'),
          RecipeIngredient(id: 'i4', name: 'Salt', category: 'pantry', amount: '1', unit: 'pinch'),
        ],
      ),
      const Recipe(
        id: 'm2',
        title: 'Chicken Rice Bowl',
        cookingTimeMin: 25,
        difficulty: 'medium',
        estimatedCost: 700.0,
        calories: 580.0,
        proteinG: 38.0,
        steps: '1. Cook rice according to package instructions.\n'
            '2. Season chicken breast with salt, pepper, and soy sauce.\n'
            '3. Cook chicken in a hot pan for 6–7 minutes per side.\n'
            '4. Slice chicken and serve over rice with your favourite sauce.',
        moodTags: ['happy', 'stressed'],
        ingredients: [
          RecipeIngredient(id: 'i5', name: 'Chicken', category: 'meat', amount: '200', unit: 'g'),
          RecipeIngredient(id: 'i6', name: 'Rice', category: 'grains', amount: '100', unit: 'g'),
          RecipeIngredient(id: 'i7', name: 'Soy sauce', category: 'pantry', amount: '2', unit: 'tbsp'),
          RecipeIngredient(id: 'i8', name: 'Pepper', category: 'pantry', amount: '1', unit: 'pinch'),
        ],
      ),
      const Recipe(
        id: 'm3',
        title: 'Banana Oat Smoothie',
        cookingTimeMin: 5,
        difficulty: 'easy',
        estimatedCost: 280.0,
        calories: 310.0,
        proteinG: 9.0,
        steps: '1. Peel banana and break into chunks.\n'
            '2. Add banana, oats, milk and honey to a blender.\n'
            '3. Blend until smooth.\n'
            '4. Pour into a glass and enjoy immediately.',
        moodTags: ['tired', 'low_energy', 'stressed'],
        ingredients: [
          RecipeIngredient(id: 'i9', name: 'Banana', category: 'fruits', amount: '1', unit: 'pc'),
          RecipeIngredient(id: 'i10', name: 'Oats', category: 'grains', amount: '50', unit: 'g'),
          RecipeIngredient(id: 'i11', name: 'Milk', category: 'dairy', amount: '200', unit: 'ml'),
          RecipeIngredient(id: 'i12', name: 'Honey', category: 'pantry', amount: '1', unit: 'tsp'),
        ],
      ),
      const Recipe(
        id: 'm4',
        title: 'Pasta with Tomato Sauce',
        cookingTimeMin: 20,
        difficulty: 'easy',
        estimatedCost: 450.0,
        calories: 520.0,
        proteinG: 16.0,
        steps: '1. Boil salted water and cook pasta per package directions.\n'
            '2. Sauté garlic in olive oil for 1 minute.\n'
            '3. Add tomato paste and 150 ml water, simmer 8 minutes.\n'
            '4. Drain pasta and toss with sauce.',
        moodTags: ['happy', 'hungry'],
        ingredients: [
          RecipeIngredient(id: 'i13', name: 'Pasta', category: 'grains', amount: '100', unit: 'g'),
          RecipeIngredient(id: 'i14', name: 'Tomato paste', category: 'pantry', amount: '2', unit: 'tbsp'),
          RecipeIngredient(id: 'i15', name: 'Garlic', category: 'vegetables', amount: '2', unit: 'cloves'),
          RecipeIngredient(id: 'i16', name: 'Olive oil', category: 'pantry', amount: '1', unit: 'tbsp'),
        ],
      ),
      const Recipe(
        id: 'm5',
        title: 'Greek Yogurt Bowl',
        cookingTimeMin: 5,
        difficulty: 'easy',
        estimatedCost: 400.0,
        calories: 280.0,
        proteinG: 18.0,
        steps: '1. Spoon yogurt into a bowl.\n'
            '2. Top with fresh berries and a drizzle of honey.\n'
            '3. Optionally add a sprinkle of oats for crunch.',
        moodTags: ['happy', 'stressed'],
        ingredients: [
          RecipeIngredient(id: 'i17', name: 'Yogurt', category: 'dairy', amount: '200', unit: 'g'),
          RecipeIngredient(id: 'i18', name: 'Berries', category: 'fruits', amount: '50', unit: 'g'),
          RecipeIngredient(id: 'i19', name: 'Honey', category: 'pantry', amount: '1', unit: 'tsp'),
        ],
      ),
      const Recipe(
        id: 'm6',
        title: 'Tuna & Cucumber Salad',
        cookingTimeMin: 8,
        difficulty: 'easy',
        estimatedCost: 500.0,
        calories: 340.0,
        proteinG: 30.0,
        steps: '1. Drain canned tuna.\n'
            '2. Dice cucumber and slice lettuce.\n'
            '3. Mix tuna and vegetables with olive oil, salt and pepper.\n'
            '4. Serve immediately.',
        moodTags: ['tired', 'hungry'],
        ingredients: [
          RecipeIngredient(id: 'i20', name: 'Tuna', category: 'meat', amount: '150', unit: 'g'),
          RecipeIngredient(id: 'i21', name: 'Cucumber', category: 'vegetables', amount: '1', unit: 'pc'),
          RecipeIngredient(id: 'i22', name: 'Lettuce', category: 'vegetables', amount: '50', unit: 'g'),
          RecipeIngredient(id: 'i23', name: 'Olive oil', category: 'pantry', amount: '1', unit: 'tbsp'),
        ],
      ),
    ];
    _loading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> fetchRecommendations({String? mood}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _recipes = await _service.getRecommendations(mood: mood);
    } on DioException catch (e) {
      _error = ApiClient.instance.handleError(e).message;
    } catch (e) {
      _error = 'Failed to load recommendations';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
