import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/recipe_model.dart';
import '../../../core/providers/ingredients_provider.dart';
import '../../../core/providers/recipe_provider.dart';
import '../../../core/theme/app_theme.dart';

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
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: const Icon(
                      Icons.tune,
                      size: 20,
                      color: AppTheme.textDark,
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

class _RecipeGridCard extends StatelessWidget {
  final Recipe recipe;
  final List<String> pantry;

  const _RecipeGridCard({required this.recipe, required this.pantry});

  static const _emojis = {
    'Scrambled Eggs': '🍳',
    'Chicken': '🍗',
    'Banana': '🍌',
    'Pasta': '🍝',
    'Yogurt': '🥣',
    'Tuna': '🐟',
    'Avocado': '🥑',
    'Quinoa': '🥗',
    'Salmon': '🐟',
    'Berry': '🫐',
    'Stir Fry': '🥘',
    'Lentil': '🍲',
  };

  String get _emoji {
    for (final entry in _emojis.entries) {
      if (recipe.title.contains(entry.key)) return entry.value;
    }
    return '🍽️';
  }

  String get _difficulty {
    switch (recipe.difficulty?.toLowerCase()) {
      case 'easy':
        return 'Easy';
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      default:
        return 'Easy';
    }
  }

  Color get _difficultyColor {
    switch (recipe.difficulty?.toLowerCase()) {
      case 'medium':
        return const Color(0xFFF57C00);
      case 'hard':
        return const Color(0xFFD32F2F);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // Food image area
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Center(
                child: Text(
                  _emoji,
                  style: const TextStyle(fontSize: 52),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
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
                        '${recipe.cookingTimeMin ?? '?'} min',
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
                        '${recipe.calories?.toInt() ?? '?'}',
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecipeDetailSheet(recipe: recipe, pantry: pantry),
    );
  }
}

class _RecipeDetailSheet extends StatefulWidget {
  final Recipe recipe;
  final List<String> pantry;

  const _RecipeDetailSheet({required this.recipe, required this.pantry});

  @override
  State<_RecipeDetailSheet> createState() => _RecipeDetailSheetState();
}

class _RecipeDetailSheetState extends State<_RecipeDetailSheet> {
  bool _showIngredients = true;
  bool _showInstructions = false;

  @override
  Widget build(BuildContext context) {
    final pantryLower =
        widget.pantry.map((e) => e.toLowerCase()).toSet();

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
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
                padding: EdgeInsets.zero,
                children: [
                  // Food image area
                  Container(
                    height: 180,
                    color: AppTheme.background,
                    child: Stack(
                      children: [
                        const Center(
                          child: Text('🥑',
                              style: TextStyle(fontSize: 80)),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Row(
                            children: [
                              _IconButton(Icons.favorite_border),
                              const SizedBox(width: 8),
                              _IconButton(Icons.share_outlined),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.recipe.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _MetaItem(
                              Icons.access_time_outlined,
                              '${widget.recipe.cookingTimeMin ?? 15} min',
                            ),
                            const SizedBox(width: 16),
                            _MetaItem(
                              Icons.local_fire_department_outlined,
                              '${widget.recipe.calories?.toInt() ?? 320} cal',
                            ),
                            const SizedBox(width: 16),
                            const _MetaItem(
                              Icons.people_outlined,
                              '2 servings',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'A nutritious and delicious meal packed with healthy fats and energy-boosting ingredients.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Health Benefits
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFDE7),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text('✨',
                                      style: TextStyle(fontSize: 14)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Health Benefits',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...const [
                                'Rich in healthy fats for sustained energy',
                                'High in fiber for better digestion',
                                'Contains B vitamins for mood support',
                              ].map(
                                (b) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.add,
                                          size: 14,
                                          color: AppTheme.primary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          b,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color:
                                                AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Ingredients collapsible
                        _CollapsibleSection(
                          title: 'Ingredients',
                          isOpen: _showIngredients,
                          onToggle: () => setState(
                              () => _showIngredients = !_showIngredients),
                          child: widget.recipe.ingredients.isEmpty
                              ? const Text(
                                  'No ingredient data',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary),
                                )
                              : Column(
                                  children: widget.recipe.ingredients
                                      .map((ing) {
                                    final have = pantryLower.contains(
                                        ing.name.toLowerCase());
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              ing.name,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      AppTheme.textDark),
                                            ),
                                          ),
                                          Text(
                                            '${ing.amount ?? ''} ${ing.unit ?? ''}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme
                                                    .textSecondary),
                                          ),
                                          if (have)
                                            const Icon(
                                              Icons.check_circle,
                                              size: 14,
                                              color: AppTheme.primary,
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: 10),

                        // Instructions collapsible
                        _CollapsibleSection(
                          title: 'Instructions',
                          isOpen: _showInstructions,
                          onToggle: () => setState(() =>
                              _showInstructions = !_showInstructions),
                          child: widget.recipe.steps == null ||
                                  widget.recipe.steps!.isEmpty
                              ? const Text(
                                  'No instructions available',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary),
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: widget.recipe.steps!
                                      .split('\n')
                                      .where((s) => s.trim().isNotEmpty)
                                      .toList()
                                      .asMap()
                                      .entries
                                      .map(
                                        (e) => Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 10),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 22,
                                                height: 22,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          6),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${e.key + 1}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  e.value.replaceFirst(
                                                      RegExp(r'^\d+\.\s*'),
                                                      ''),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        AppTheme.textDark,
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                        ),
                        const SizedBox(height: 20),

                        // Start Cooking button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Start Cooking',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  const _IconButton(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: AppTheme.textDark),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaItem(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CollapsibleSection extends StatelessWidget {
  final String title;
  final bool isOpen;
  final VoidCallback onToggle;
  final Widget child;

  const _CollapsibleSection({
    required this.title,
    required this.isOpen,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFEEEEEE)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const Spacer(),
                Icon(
                  isOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (isOpen)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: child,
          ),
      ],
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
