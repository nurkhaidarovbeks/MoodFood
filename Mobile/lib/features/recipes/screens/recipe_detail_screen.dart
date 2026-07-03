import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/recipe_model.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/recipe_photo.dart';

/// Full-screen recipe detail — photo hero, info cards, mood/energy,
/// nutrition facts, ingredients, instructions, and a Start Cooking CTA.
class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  final List<String> pantry;
  final String? photoUrl;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.pantry = const [],
    this.photoUrl,
  });

  String get _photo => photoUrl ?? RecipePhoto.forTitle(recipe.title, seed: recipe.id);

  String get _difficulty {
    switch (recipe.difficulty?.toLowerCase()) {
      case 'hard':
        return 'Hard';
      case 'medium':
        return 'Medium';
      default:
        return 'Easy';
    }
  }

  String get _moodBenefit {
    final tags = recipe.moodTags.map((e) => e.toLowerCase()).toSet();
    if (tags.contains('energetic')) return 'Sustained Energy & Mental Clarity';
    if (tags.contains('focused')) return 'Focus & Concentration';
    if (tags.contains('calm')) return 'Calm & Stress Relief';
    if (tags.contains('happy')) return 'Mood Boost & Positivity';
    if (tags.contains('cozy')) return 'Comfort & Warmth';
    return 'Balanced Nutrition & Wellbeing';
  }

  String get _energyImpact {
    final cal = recipe.calories ?? 0;
    final tags = recipe.moodTags.map((e) => e.toLowerCase()).toSet();
    if (tags.contains('energetic') || cal >= 450) return 'High energy boost';
    if (cal >= 300) return 'Balanced, steady energy';
    return 'Light & refreshing';
  }

  List<String> get _steps => (recipe.steps ?? '')
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              // Photo hero
              SizedBox(
                height: 300,
                width: double.infinity,
                child: Image.network(
                  _photo,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: const Color(0xFFEDEDED),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFEDEDED),
                    child: const Center(
                      child: Icon(Icons.restaurant,
                          size: 56, color: Colors.white),
                    ),
                  ),
                ),
              ),

              // Overlapping content
              Transform.translate(
                offset: const Offset(0, -28),
                child: Column(
                  children: [
                    _headCard(context),
                    const SizedBox(height: 16),
                    _nutritionCard(),
                    const SizedBox(height: 16),
                    _ingredientsCard(),
                    const SizedBox(height: 16),
                    _instructionsCard(),
                  ],
                ),
              ),
            ],
          ),

          // Header buttons over photo
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _CircleBtn(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
                const Spacer(),
                Consumer<FavoritesProvider>(
                  builder: (context, fav, _) {
                    final saved = fav.isFavorite(recipe.id);
                    return _CircleBtn(
                      icon: saved ? Icons.favorite : Icons.favorite_border,
                      iconColor: saved ? const Color(0xFFE53935) : null,
                      onTap: () => fav.toggle(recipe.id),
                    );
                  },
                ),
                const SizedBox(width: 10),
                _CircleBtn(
                  icon: Icons.share_outlined,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sharing coming soon'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Fixed Start Cooking button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.background.withValues(alpha: 0),
                    AppTheme.background,
                  ],
                ),
              ),
              child: _StartCookingButton(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Let's get cooking! 🍳"),
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Head card: title + info + mood + energy ───────────────────────────────
  Widget _headCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recipe.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  icon: Icons.access_time,
                  label: 'Time',
                  value: '${recipe.cookingTimeMin ?? 15} min',
                  colors: const [Color(0xFF64B5F6), Color(0xFF2196F3)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: Icons.trending_up,
                  label: 'Difficulty',
                  value: _difficulty,
                  colors: const [Color(0xFFFFB74D), Color(0xFFFF9800)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: Icons.people_outline,
                  label: 'Servings',
                  value: '2',
                  colors: const [Color(0xFFB39DDB), Color(0xFF9575CD)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _BenefitTile(
            icon: Icons.bolt,
            iconColor: const Color(0xFF7E57C2),
            bg: const Color(0xFFEDE7F6),
            title: 'Mood Benefit',
            subtitle: _moodBenefit,
          ),
          const SizedBox(height: 12),
          _BenefitTile(
            icon: Icons.local_fire_department,
            iconColor: const Color(0xFFFF7043),
            bg: const Color(0xFFFFF3E0),
            title: 'Energy Impact',
            subtitle: _energyImpact,
          ),
        ],
      ),
    );
  }

  // ─── Nutrition facts ────────────────────────────────────────────────────────
  Widget _nutritionCard() {
    final cal = recipe.calories?.round();
    final p = recipe.proteinG?.round();
    final c = recipe.carbsG?.round();
    final f = recipe.fatG?.round();
    if (cal == null && p == null && c == null && f == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nutrition Facts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MacroCard(
                  value: '${cal ?? '—'}',
                  label: 'Calories',
                  colors: const [Color(0xFFFFB74D), Color(0xFFF57C00)],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MacroCard(
                  value: p == null ? '—' : '$p',
                  unit: 'g',
                  label: 'Protein',
                  colors: const [Color(0xFF9575CD), Color(0xFF7E57C2)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MacroCard(
                  value: c == null ? '—' : '$c',
                  unit: 'g',
                  label: 'Carbs',
                  colors: const [Color(0xFF64B5F6), Color(0xFF42A5F5)],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MacroCard(
                  value: f == null ? '—' : '$f',
                  unit: 'g',
                  label: 'Fat',
                  colors: const [Color(0xFFE57373), Color(0xFFEF5350)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Ingredients ────────────────────────────────────────────────────────────
  Widget _ingredientsCard() {
    if (recipe.ingredients.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingredients',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),
          ...recipe.ingredients.map((ing) {
            final parts = [
              if (ing.amount != null && ing.amount!.isNotEmpty) ing.amount,
              if (ing.unit != null && ing.unit!.isNotEmpty) ing.unit,
              ing.name,
            ].whereType<String>().join(' ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF9575CD),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      parts,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textDark,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Instructions ───────────────────────────────────────────────────────────
  Widget _instructionsCard() {
    final steps = _steps;
    if (steps.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instructions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        e.value,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static BoxDecoration _cardDeco({double radius = 20}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
}

// ─── Small building blocks ──────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: iconColor ?? AppTheme.textDark),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<Color> colors;
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final String title;
  final String subtitle;
  const _BenefitTile({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String value;
  final String? unit;
  final String label;
  final List<Color> colors;
  const _MacroCard({
    required this.value,
    this.unit,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Text(
                  unit!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartCookingButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartCookingButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF9A825), Color(0xFFF5B301)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF9A825).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '🍳  Start Cooking',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
