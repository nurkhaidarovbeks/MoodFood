class RecipeIngredient {
  final String id;
  final String name;
  final String? category;
  final String? amount;
  final String? unit;

  const RecipeIngredient({
    required this.id,
    required this.name,
    this.category,
    this.amount,
    this.unit,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String?,
      amount: json['amount'] as String?,
      unit: json['unit'] as String?,
    );
  }
}

class Recipe {
  final String id;
  final String title;
  final int? cookingTimeMin;
  final String? difficulty;
  final double? estimatedCost;
  final double? calories;
  final double? proteinG;
  final String? steps;
  final List<String> moodTags;
  final List<RecipeIngredient> ingredients;

  const Recipe({
    required this.id,
    required this.title,
    this.cookingTimeMin,
    this.difficulty,
    this.estimatedCost,
    this.calories,
    this.proteinG,
    this.steps,
    required this.moodTags,
    required this.ingredients,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      cookingTimeMin: json['cookingTimeMin'] as int?,
      difficulty: json['difficulty'] as String?,
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
      calories: (json['calories'] as num?)?.toDouble(),
      proteinG: (json['proteinG'] as num?)?.toDouble(),
      steps: json['steps'] as String?,
      moodTags: (json['moodTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get difficultyLabel {
    switch (difficulty) {
      case 'easy':
        return 'Easy';
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      default:
        return '';
    }
  }

  int matchCount(List<String> pantry) {
    if (ingredients.isEmpty) return 0;
    final pantryLower = pantry.map((e) => e.toLowerCase()).toSet();
    return ingredients
        .where((i) => pantryLower.contains(i.name.toLowerCase()))
        .length;
  }

  bool canMakeWith(List<String> pantry) {
    if (ingredients.isEmpty) return true;
    return matchCount(pantry) == ingredients.length;
  }
}
