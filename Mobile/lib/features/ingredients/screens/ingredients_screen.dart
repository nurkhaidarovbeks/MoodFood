import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/ingredients_provider.dart';
import '../../../core/providers/recipe_provider.dart';
import '../../../core/theme/app_theme.dart';

const _availableIngredients = [
  ('🥑', 'Avocado'),
  ('🍌', 'Banana'),
  ('🥚', 'Eggs'),
  ('🐔', 'Chicken'),
  ('🍅', 'Tomatoes'),
  ('🧅', 'Onions'),
  ('🧄', 'Garlic'),
  ('🫛', 'Spinach'),
  ('🥦', 'Broccoli'),
  ('🥕', 'Carrots'),
  ('🍚', 'Rice'),
  ('🍝', 'Pasta'),
  ('🥜', 'Peanuts'),
  ('🐟', 'Salmon'),
  ('🫐', 'Blueberries'),
  ('🥛', 'Milk'),
  ('🧀', 'Cheese'),
  ('🍞', 'Bread'),
  ('🌾', 'Oats'),
  ('🫘', 'Lentils'),
  ('🥩', 'Beef'),
  ('🍋', 'Lemon'),
  ('🫐', 'Berries'),
  ('🥗', 'Quinoa'),
];

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  String _searchQuery = '';
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IngredientsProvider>().load();
    });
  }

  List<(String, String)> get _filtered {
    if (_searchQuery.isEmpty) return _availableIngredients;
    return _availableIngredients
        .where((e) =>
            e.$2.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer2<IngredientsProvider, RecipeProvider>(
          builder: (_, ingProv, recProv, _) {
            final selected = ingProv.ingredients;

            final List<dynamic> matchedRecipes;
            if (_showSuggestions) {
              matchedRecipes = recProv.recipes
                  .where((r) => r.matchCount(selected) > 0)
                  .toList()
                ..sort((a, b) =>
                    b.matchCount(selected).compareTo(a.matchCount(selected)));
            } else {
              matchedRecipes = [];
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 18,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "What's in Your Fridge?",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    'Select your available ingredients',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),

                // Selected ingredient chips
                if (selected.isNotEmpty)
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: selected.length,
                      itemBuilder: (_, i) {
                        final item = selected[i];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => ingProv.toggle(item),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                if (selected.isNotEmpty) const SizedBox(height: 10),

                // Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        const Icon(Icons.search,
                            size: 18, color: AppTheme.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (v) =>
                                setState(() => _searchQuery = v),
                            decoration: const InputDecoration(
                              hintText: 'Search ingredients...',
                              hintStyle: TextStyle(
                                  fontSize: 13, color: AppTheme.textSecondary),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              filled: false,
                            ),
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.textDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Ingredients grid
                Expanded(
                  child: _showSuggestions
                      ? _SuggestionsList(
                          recipes: matchedRecipes.cast(),
                          selected: selected,
                          onBack: () =>
                              setState(() => _showSuggestions = false),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final (emoji, name) = _filtered[i];
                            final isSelected = selected.contains(name);
                            return GestureDetector(
                              onTap: () => ingProv.toggle(name),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary.withValues(alpha: 0.08)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.divider,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(emoji,
                                        style: const TextStyle(fontSize: 28)),
                                    const SizedBox(height: 4),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected
                                            ? AppTheme.primary
                                            : AppTheme.textDark,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      bottomSheet: _BottomBar(
        onGenerateRecipes: () {
          context.read<RecipeProvider>().fetchRecipes();
          setState(() => _showSuggestions = true);
        },
        onClear: () => context.read<IngredientsProvider>().clear(),
      ),
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  final List<dynamic> recipes;
  final List<String> selected;
  final VoidCallback onBack;

  const _SuggestionsList({
    required this.recipes,
    required this.selected,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'No recipes found with these\ningredients',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 15, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onBack,
              child: const Text('Add more ingredients'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      itemCount: recipes.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: const Icon(Icons.arrow_back,
                      size: 18, color: AppTheme.textDark),
                ),
                const SizedBox(width: 8),
                Text(
                  '${recipes.length} recipe${recipes.length == 1 ? '' : 's'} found',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          );
        }
        final recipe = recipes[i - 1] as dynamic;
        final match = recipe.matchCount(selected) as int;
        final total = recipe.ingredients.length as int;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('🍽️', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$match/$total ingredients available',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: match == total
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  match == total ? 'Ready' : '$match/$total',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: match == total
                        ? AppTheme.primary
                        : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onGenerateRecipes;
  final VoidCallback onClear;

  const _BottomBar({
    required this.onGenerateRecipes,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.divider),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onClear,
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: onGenerateRecipes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Generate Recipes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
