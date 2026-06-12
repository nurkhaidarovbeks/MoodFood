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
