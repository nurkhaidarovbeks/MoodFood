import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/recipe_model.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/providers/ingredients_provider.dart';
import '../../../core/providers/recipe_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/recipe_photo.dart';
import '../../../core/widgets/recipe_image.dart';
import 'recipe_detail_screen.dart';

// Chip filter definition
enum _RecipeChip { all, quick, budget, energy, protein }

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  _RecipeChip _activeChip = _RecipeChip.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipeProvider>().fetchRecipes();
      context.read<IngredientsProvider>().load();
    });
  }

  List<Recipe> _filter(List<Recipe> all) {
    var list = all;

    if (_searchQuery.isNotEmpty) {
      list = list
          .where((r) =>
              r.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    switch (_activeChip) {
      case _RecipeChip.quick:
        list = list
            .where((r) => r.cookingTimeMin != null && r.cookingTimeMin! <= 15)
            .toList();
      case _RecipeChip.budget:
        list = list
            .where((r) => r.estimatedCost != null && r.estimatedCost! <= 400)
            .toList();
      case _RecipeChip.energy:
        list = list
            .where((r) =>
                r.moodTags.contains('energetic') ||
                r.moodTags.contains('happy'))
            .toList();
      case _RecipeChip.protein:
        list = list
            .where((r) => r.proteinG != null && r.proteinG! >= 20)
            .toList();
      case _RecipeChip.all:
        break;
    }

    return list;
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Filter Recipes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterOption(
                      label: 'All Recipes',
                      active: _activeChip == _RecipeChip.all,
                      onTap: () {
                        setSheetState(() {});
                        setState(() => _activeChip = _RecipeChip.all);
                      },
                    ),
                    _FilterOption(
                      label: 'Quick Meals (≤15 min)',
                      active: _activeChip == _RecipeChip.quick,
                      onTap: () {
                        setSheetState(() {});
                        setState(() => _activeChip = _RecipeChip.quick);
                      },
                    ),
                    _FilterOption(
                      label: 'Budget-Friendly',
                      active: _activeChip == _RecipeChip.budget,
                      onTap: () {
                        setSheetState(() {});
                        setState(() => _activeChip = _RecipeChip.budget);
                      },
                    ),
                    _FilterOption(
                      label: 'Energy Boost',
                      active: _activeChip == _RecipeChip.energy,
                      onTap: () {
                        setSheetState(() {});
                        setState(() => _activeChip = _RecipeChip.energy);
                      },
                    ),
                    _FilterOption(
                      label: 'High Protein (≥20g)',
                      active: _activeChip == _RecipeChip.protein,
                      onTap: () {
                        setSheetState(() {});
                        setState(() => _activeChip = _RecipeChip.protein);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply Filter',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recipes',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/ingredients'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: const Icon(
                        Icons.kitchen_outlined,
                        size: 20,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.search,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                              decoration: const InputDecoration(
                                hintText: 'Search recipes...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                filled: false,
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showFilterSheet(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _activeChip == _RecipeChip.all
                            ? Colors.white
                            : AppTheme.primary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _activeChip == _RecipeChip.all
                              ? AppTheme.divider
                              : AppTheme.primary,
                        ),
                      ),
                      child: Icon(
                        Icons.tune,
                        size: 20,
                        color: _activeChip == _RecipeChip.all
                            ? AppTheme.textDark
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Chip filters
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _ChipFilter(
                    icon: Icons.favorite_outline,
                    label: 'All Recipes',
                    active: _activeChip == _RecipeChip.all,
                    onTap: () =>
                        setState(() => _activeChip = _RecipeChip.all),
                  ),
                  _ChipFilter(
                    icon: Icons.access_time_outlined,
                    label: 'Quick Meals',
                    active: _activeChip == _RecipeChip.quick,
                    onTap: () =>
                        setState(() => _activeChip = _RecipeChip.quick),
                  ),
                  _ChipFilter(
                    icon: Icons.attach_money,
                    label: 'Budget',
                    active: _activeChip == _RecipeChip.budget,
                    onTap: () =>
                        setState(() => _activeChip = _RecipeChip.budget),
                  ),
                  _ChipFilter(
                    icon: Icons.bolt,
                    label: 'Energy Boost',
                    active: _activeChip == _RecipeChip.energy,
                    onTap: () =>
                        setState(() => _activeChip = _RecipeChip.energy),
                  ),
                  _ChipFilter(
                    icon: Icons.trending_up,
                    label: 'High Protein',
                    active: _activeChip == _RecipeChip.protein,
                    onTap: () =>
                        setState(() => _activeChip = _RecipeChip.protein),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Recipe list
            Expanded(
              child: Consumer2<RecipeProvider, IngredientsProvider>(
                builder: (_, recipesProv, ingredients, _) {
                  if (recipesProv.loading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                      ),
                    );
                  }

                  if (recipesProv.error != null) {
                    return _ErrorState(
                      message: recipesProv.error!,
                      onRetry: () =>
                          context.read<RecipeProvider>().fetchRecipes(),
                    );
                  }

                  final filtered = _filter(recipesProv.recipes);

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                          child: Text(
                            '${filtered.length} recipe${filtered.length == 1 ? '' : 's'} found',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      if (filtered.isEmpty)
                        const SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🍽️',
                                    style: TextStyle(fontSize: 48)),
                                SizedBox(height: 12),
                                Text(
                                  'No recipes found',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _RecipeGridCard(
                                recipe: filtered[i],
                                pantry: ingredients.ingredients,
                              ),
                              childCount: filtered.length,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.78,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipFilter extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ChipFilter({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppTheme.primary : AppTheme.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeGridCard extends StatefulWidget {
  final Recipe recipe;
  final List<String> pantry;

  const _RecipeGridCard({required this.recipe, required this.pantry});

  @override
  State<_RecipeGridCard> createState() => _RecipeGridCardState();
}

class _RecipeGridCardState extends State<_RecipeGridCard> {
  String get _photoUrl =>
      RecipePhoto.forTitle(widget.recipe.title, seed: widget.recipe.id);

  String get _difficulty {
    switch (widget.recipe.difficulty?.toLowerCase()) {
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      default:
        return 'Easy';
    }
  }

  Color get _difficultyColor {
    switch (widget.recipe.difficulty?.toLowerCase()) {
      case 'medium':
        return const Color(0xFFF57C00);
      case 'hard':
        return const Color(0xFFD32F2F);
      default:
        return AppTheme.primary;
    }
  }

  void _toggleSave() {
    final fav = context.read<FavoritesProvider>();
    final wasFav = fav.isFavorite(widget.recipe.id);
    fav.toggle(widget.recipe.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasFav ? 'Recipe removed' : '❤️ Recipe saved!'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          backgroundColor: wasFav ? AppTheme.textSecondary : AppTheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaved = context.watch<FavoritesProvider>().isFavorite(widget.recipe.id);
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food photo
            Stack(
              children: [
                RecipeImage(
                  title: widget.recipe.title,
                  seed: widget.recipe.id,
                  height: 110,
                  width: double.infinity,
                  radius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                // Save button overlay
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: _toggleSave,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSaved ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isSaved
                            ? const Color(0xFFE53935)
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipe.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_outlined,
                        size: 11,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${widget.recipe.cookingTimeMin ?? '?'} min',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.local_fire_department_outlined,
                        size: 11,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${widget.recipe.calories?.toInt() ?? '?'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _difficultyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _difficulty,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _difficultyColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(
          recipe: widget.recipe,
          pantry: widget.pantry,
          photoUrl: _photoUrl,
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
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
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

class _FilterOption extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : AppTheme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppTheme.primary : AppTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : AppTheme.textDark,
          ),
        ),
      ),
    );
  }
}
