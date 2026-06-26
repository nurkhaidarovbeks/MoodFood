import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/theme/app_theme.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)
              ],
            ),
            child: const Icon(Icons.arrow_back,
                size: 20, color: AppTheme.textDark),
          ),
        ),
        title: const Text(
          'Saved Recipes',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark),
        ),
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, prov, _) {
          if (prov.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }
          if (prov.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🍽️', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  const Text(
                    'No saved recipes yet',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap ♥ on any recipe to save it here',
                    style:
                        TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, '/home',
                        arguments: {'tab': 1}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Browse Recipes'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () => prov.load(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: prov.items.length,
              itemBuilder: (_, i) =>
                  _FavoriteCard(item: prov.items[i]),
            ),
          );
        },
      ),
    );
  }
}

// ─── Favourite Card ────────────────────────────────────────────────────────────

class _FavoriteCard extends StatelessWidget {
  final FavoriteItem item;
  const _FavoriteCard({required this.item});

  static const _photos = {
    'egg': 'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=400&q=70&fit=crop',
    'chicken': 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=400&q=70&fit=crop',
    'banana': 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400&q=70&fit=crop',
    'pasta': 'https://images.unsplash.com/photo-1555949258-eb67b1ef0ceb?w=400&q=70&fit=crop',
    'salmon': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400&q=70&fit=crop',
    'fish': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400&q=70&fit=crop',
    'avocado': 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=400&q=70&fit=crop',
    'quinoa': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&q=70&fit=crop',
    'berry': 'https://images.unsplash.com/photo-1498557850523-fd3d118b962e?w=400&q=70&fit=crop',
    'salad': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&q=70&fit=crop',
    'rice': 'https://images.unsplash.com/photo-1536304993881-ff6e9eefa2a6?w=400&q=70&fit=crop',
    'oat': 'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?w=400&q=70&fit=crop',
    'soup': 'https://images.unsplash.com/photo-1547592180-85f173990554?w=400&q=70&fit=crop',
    'smoothie': 'https://images.unsplash.com/photo-1638176066959-7cf4f8cef945?w=400&q=70&fit=crop',
    'beef': 'https://images.unsplash.com/photo-1432139509613-5c4255815697?w=400&q=70&fit=crop',
    'toast': 'https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=400&q=70&fit=crop',
    'stir': 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400&q=70&fit=crop',
    'wrap': 'https://images.unsplash.com/photo-1552332386-f8dd00dc2f85?w=400&q=70&fit=crop',
  };

  static const _fallback =
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=70&fit=crop';

  String get _photoUrl {
    final title = item.recipe.title.toLowerCase();
    for (final e in _photos.entries) {
      if (title.contains(e.key)) return e.value;
    }
    return _fallback;
  }

  @override
  Widget build(BuildContext context) {
    final recipe = item.recipe;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Photo
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(18)),
            child: Image.network(
              _photoUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100,
                height: 100,
                color: AppTheme.background,
                child:
                    const Center(child: Text('🍽️', style: TextStyle(fontSize: 32))),
              ),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    children: [
                      if (recipe.cookingTimeMin != null)
                        _Chip(
                            icon: Icons.timer_outlined,
                            label: '${recipe.cookingTimeMin} min'),
                      if (recipe.calories != null)
                        _Chip(
                            icon: Icons.local_fire_department_outlined,
                            label: '${recipe.calories!.toInt()} kcal'),
                      if (recipe.difficulty != null &&
                          recipe.difficulty!.isNotEmpty)
                        _Chip(
                            icon: Icons.signal_cellular_alt,
                            label: recipe.difficultyLabel),
                    ],
                  ),
                  if (recipe.proteinG != null ||
                      recipe.fatG != null ||
                      recipe.carbsG != null) ...[
                    const SizedBox(height: 6),
                    _MacroRow(recipe: recipe),
                  ],
                ],
              ),
            ),
          ),
          // Remove button
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () =>
                  context.read<FavoritesProvider>().toggle(recipe.id),
              child: const Icon(Icons.favorite,
                  color: Color(0xFFE53935), size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textSecondary),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _MacroRow extends StatelessWidget {
  final dynamic recipe;
  const _MacroRow({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (recipe.proteinG != null)
          _MacroBadge('P ${recipe.proteinG!.toInt()}g',
              const Color(0xFF1565C0)),
        if (recipe.fatG != null)
          _MacroBadge('F ${recipe.fatG!.toInt()}g',
              const Color(0xFFE65100)),
        if (recipe.carbsG != null)
          _MacroBadge('C ${recipe.carbsG!.toInt()}g',
              const Color(0xFF2E7D32)),
      ],
    );
  }
}

class _MacroBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MacroBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 5),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
