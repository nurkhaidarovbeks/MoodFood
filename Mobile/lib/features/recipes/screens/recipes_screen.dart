import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/recipe_model.dart';
import '../../../core/providers/ingredients_provider.dart';
import '../../../core/providers/recipe_provider.dart';
import '../../../core/theme/app_theme.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipeProvider>().fetchRecipes();
      context.read<IngredientsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Recipes'),
        backgroundColor: AppTheme.surface,
        actions: [_FilterToggle()],
      ),
      body: Consumer2<RecipeProvider, IngredientsProvider>(
        builder: (_, recipes, ingredients, _) {
          if (recipes.loading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary,
              ),
            );
          }

          if (recipes.error != null) {
            return _ErrorState(
              message: recipes.error!,
              onRetry: () => context.read<RecipeProvider>().fetchRecipes(),
            );
          }

          final filtered = recipes.filtered(ingredients.ingredients);

          if (recipes.recipes.isEmpty) {
            return _EmptyState(
              message: 'No recipes found.\nMake sure the backend is running.',
              onRetry: () => context.read<RecipeProvider>().fetchRecipes(),
            );
          }

          if (filtered.isEmpty && recipes.filter == RecipeFilter.canMake) {
            return const _EmptyState(
              message:
                  'None of your recipes match your current fridge.\nAdd more ingredients or switch to All.',
              onRetry: null,
            );
          }

          return Column(
            children: [
              _StatsBar(
                total: recipes.recipes.length,
                canMake: recipes.recipes
                    .where((r) => r.canMakeWith(ingredients.ingredients))
                    .length,
                pantryCount: ingredients.ingredients.length,
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _RecipeCard(
                    recipe: filtered[i],
                    pantry: ingredients.ingredients,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeProvider>(
      builder: (_, prov, _) {
        final isCanMake = prov.filter == RecipeFilter.canMake;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => prov.setFilter(
              isCanMake ? RecipeFilter.all : RecipeFilter.canMake,
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCanMake
                    ? AppTheme.primary
                    : AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.kitchen_outlined,
                    size: 14,
                    color: isCanMake ? Colors.white : AppTheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Can make',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isCanMake ? Colors.white : AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatsBar extends StatelessWidget {
  final int total;
  final int canMake;
  final int pantryCount;

  const _StatsBar({
    required this.total,
    required this.canMake,
    required this.pantryCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _Stat(label: 'Total', value: '$total'),
          const SizedBox(width: 20),
          _Stat(
            label: 'Can make',
            value: '$canMake',
            valueColor: AppTheme.primary,
          ),
          const SizedBox(width: 20),
          _Stat(label: 'In fridge', value: '$pantryCount items'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Stat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppTheme.textDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMedium),
        ),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final List<String> pantry;

  const _RecipeCard({required this.recipe, required this.pantry});

  @override
  Widget build(BuildContext context) {
    final matchCount = recipe.matchCount(pantry);
    final totalCount = recipe.ingredients.length;
    final canMake = recipe.canMakeWith(pantry);

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: canMake && pantry.isNotEmpty
                ? AppTheme.primary.withValues(alpha: 0.4)
                : AppTheme.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                if (canMake && pantry.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '✓ Can make',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              children: [
                if (recipe.cookingTimeMin != null)
                  _MetaChip(
                    icon: Icons.timer_outlined,
                    label: '${recipe.cookingTimeMin} min',
                  ),
                if (recipe.difficultyLabel.isNotEmpty)
                  _MetaChip(
                    icon: Icons.bar_chart,
                    label: recipe.difficultyLabel,
                  ),
                if (recipe.calories != null)
                  _MetaChip(
                    icon: Icons.local_fire_department_outlined,
                    label: '${recipe.calories!.toInt()} cal',
                  ),
              ],
            ),
            if (totalCount > 0 && pantry.isNotEmpty) ...[
              const SizedBox(height: 10),
              _IngredientMatchBar(
                matchCount: matchCount,
                totalCount: totalCount,
              ),
            ],
            if (recipe.moodTags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: recipe.moodTags
                    .take(3)
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecipeDetailSheet(recipe: recipe, pantry: pantry),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.textMedium),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
        ),
      ],
    );
  }
}

class _IngredientMatchBar extends StatelessWidget {
  final int matchCount;
  final int totalCount;

  const _IngredientMatchBar({
    required this.matchCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = totalCount > 0 ? matchCount / totalCount : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$matchCount / $totalCount ingredients available',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: AppTheme.divider,
            color: ratio == 1.0 ? AppTheme.primary : AppTheme.accentAmber,
          ),
        ),
      ],
    );
  }
}

class _RecipeDetailSheet extends StatelessWidget {
  final Recipe recipe;
  final List<String> pantry;

  const _RecipeDetailSheet({required this.recipe, required this.pantry});

  @override
  Widget build(BuildContext context) {
    final pantryLower = pantry.map((e) => e.toLowerCase()).toSet();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    children: [
                      if (recipe.cookingTimeMin != null)
                        _DetailStat(
                          icon: Icons.timer_outlined,
                          label: '${recipe.cookingTimeMin} min',
                        ),
                      if (recipe.difficultyLabel.isNotEmpty)
                        _DetailStat(
                          icon: Icons.bar_chart,
                          label: recipe.difficultyLabel,
                        ),
                      if (recipe.calories != null)
                        _DetailStat(
                          icon: Icons.local_fire_department_outlined,
                          label: '${recipe.calories!.toInt()} cal',
                        ),
                      if (recipe.proteinG != null)
                        _DetailStat(
                          icon: Icons.fitness_center_outlined,
                          label: '${recipe.proteinG!.toInt()}g protein',
                        ),
                    ],
                  ),
                  if (recipe.ingredients.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Ingredients',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...recipe.ingredients.map((ing) {
                      final have = pantryLower.contains(ing.name.toLowerCase());
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              have
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 18,
                              color: have
                                  ? AppTheme.primary
                                  : AppTheme.textMedium,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                [
                                  if (ing.amount != null) ing.amount!,
                                  if (ing.unit != null) ing.unit!,
                                  ing.name,
                                ].join(' '),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: have
                                      ? AppTheme.textDark
                                      : AppTheme.textMedium,
                                  fontWeight: have
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  if (recipe.steps != null && recipe.steps!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recipe.steps!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMedium,
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.textMedium),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textMedium),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _EmptyState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textMedium,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(140, 44),
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: AppTheme.textMedium,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textMedium,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(140, 44),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
