import 'package:flutter/material.dart';
import '../../../core/models/mood_entry_model.dart';
import '../../../core/theme/app_theme.dart';

class RecommendationsScreen extends StatelessWidget {
  final MoodEntry? moodEntry;

  const RecommendationsScreen({super.key, this.moodEntry});

  @override
  Widget build(BuildContext context) {
    final mood = moodEntry?.mood ?? 'happy';
    final energy = moodEntry?.energyLevel ?? 3;
    final categories = _buildCategories(mood, energy);

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
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back,
              size: 20,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your\nRecommendations',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Based on your current mood and energy',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ...categories.map((cat) => _CategoryCard(category: cat)),
                  const SizedBox(height: 16),
                  _WhyCard(mood: mood, energy: energy),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (_) => false,
                          arguments: {'tab': 1},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book_outlined, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Explore More Recipes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.popUntil(
                        context,
                        ModalRoute.withName('/home'),
                      ),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_RecommendationCategory> _buildCategories(String mood, int energy) {
    switch (mood) {
      case 'tired':
      case 'sad':
        return [
          _RecommendationCategory(
            icon: Icons.bolt,
            iconColor: const Color(0xFFFFA000),
            bgColor: const Color(0xFFFFF8E1),
            title: 'Boost Your Energy',
            items: [
              _FoodItem(name: 'Banana & Almond Butter', reason: 'Quick energy boost'),
              _FoodItem(name: 'Greek Yogurt with Berries', reason: 'Sustained energy'),
              _FoodItem(name: 'Oatmeal with Nuts', reason: 'Long-lasting fuel'),
            ],
          ),
          _RecommendationCategory(
            icon: Icons.favorite_outline,
            iconColor: const Color(0xFF4CAF50),
            bgColor: const Color(0xFFE8F5E9),
            title: 'Mood Boosters',
            items: [
              _FoodItem(name: 'Dark Chocolate', reason: 'Serotonin boost'),
              _FoodItem(name: 'Salmon', reason: 'Omega-3 for mood'),
              _FoodItem(name: 'Walnuts', reason: 'Brain support'),
            ],
          ),
          _RecommendationCategory(
            icon: Icons.water_drop_outlined,
            iconColor: const Color(0xFF2196F3),
            bgColor: const Color(0xFFE3F2FD),
            title: 'Hydration Reminder',
            items: [
              _FoodItem(name: 'Coconut Water', reason: 'Electrolytes'),
              _FoodItem(name: 'Cucumber Slices', reason: 'Hydrating snack'),
              _FoodItem(name: 'Herbal Tea', reason: 'Gentle hydration'),
            ],
          ),
        ];

      case 'stressed':
        return [
          _RecommendationCategory(
            icon: Icons.spa_outlined,
            iconColor: const Color(0xFF9C27B0),
            bgColor: const Color(0xFFF3E5F5),
            title: 'Reduce Stress',
            items: [
              _FoodItem(name: 'Dark Chocolate', reason: 'Mood enhancer'),
              _FoodItem(name: 'Green Tea', reason: 'Calming effect'),
              _FoodItem(name: 'Avocado Toast', reason: 'Healthy fats'),
            ],
          ),
          _RecommendationCategory(
            icon: Icons.bolt,
            iconColor: const Color(0xFFFFA000),
            bgColor: const Color(0xFFFFF8E1),
            title: 'Boost Your Energy',
            items: [
              _FoodItem(name: 'Banana & Almond Butter', reason: 'Quick energy boost'),
              _FoodItem(name: 'Greek Yogurt with Berries', reason: 'Sustained energy'),
              _FoodItem(name: 'Oatmeal with Nuts', reason: 'Long-lasting fuel'),
            ],
          ),
          _RecommendationCategory(
            icon: Icons.water_drop_outlined,
            iconColor: const Color(0xFF2196F3),
            bgColor: const Color(0xFFE3F2FD),
            title: 'Hydration Reminder',
            items: [
              _FoodItem(name: 'Coconut Water', reason: 'Electrolytes'),
              _FoodItem(name: 'Cucumber Slices', reason: 'Hydrating snack'),
              _FoodItem(name: 'Herbal Tea', reason: 'Gentle hydration'),
            ],
          ),
        ];

      case 'energetic':
        return [
          _RecommendationCategory(
            icon: Icons.fitness_center_outlined,
            iconColor: const Color(0xFF4CAF50),
            bgColor: const Color(0xFFE8F5E9),
            title: 'Sustain Your Energy',
            items: [
              _FoodItem(name: 'Chicken Quinoa Bowl', reason: 'Protein + complex carbs'),
              _FoodItem(name: 'Mixed Nuts', reason: 'Healthy fats'),
              _FoodItem(name: 'Fruit Salad', reason: 'Natural sugars'),
            ],
          ),
          _RecommendationCategory(
            icon: Icons.local_fire_department_outlined,
            iconColor: const Color(0xFFFF5722),
            bgColor: const Color(0xFFFBE9E7),
            title: 'Performance Meals',
            items: [
              _FoodItem(name: 'Salmon with Greens', reason: 'Omega-3 for recovery'),
              _FoodItem(name: 'Brown Rice Bowl', reason: 'Complex carbohydrates'),
              _FoodItem(name: 'Protein Smoothie', reason: 'Muscle support'),
            ],
          ),
          _RecommendationCategory(
            icon: Icons.water_drop_outlined,
            iconColor: const Color(0xFF2196F3),
            bgColor: const Color(0xFFE3F2FD),
            title: 'Hydration Reminder',
            items: [
              _FoodItem(name: 'Coconut Water', reason: 'Electrolytes'),
              _FoodItem(name: 'Sports Drink', reason: 'Mineral replenishment'),
              _FoodItem(name: 'Watermelon', reason: 'Natural hydration'),
            ],
          ),
        ];

      default: // happy, calm, focused, cozy
        return [
          _RecommendationCategory(
            icon: Icons.bolt,
            iconColor: const Color(0xFFFFA000),
            bgColor: const Color(0xFFFFF8E1),
            title: 'Boost Your Energy',
            items: [
              _FoodItem(name: 'Banana & Almond Butter', reason: 'Quick energy boost'),
              _FoodItem(name: 'Greek Yogurt with Berries', reason: 'Sustained energy'),
              _FoodItem(name: 'Oatmeal with Nuts', reason: 'Long-lasting fuel'),
            ],
          ),
          _RecommendationCategory(
            icon: Icons.spa_outlined,
            iconColor: const Color(0xFF9C27B0),
            bgColor: const Color(0xFFF3E5F5),
            title: 'Reduce Stress',
            items: [
              _FoodItem(name: 'Dark Chocolate', reason: 'Mood enhancer'),
              _FoodItem(name: 'Green Tea', reason: 'Calming effect'),
              _FoodItem(name: 'Avocado Toast', reason: 'Healthy fats'),
            ],
          ),
          _RecommendationCategory(
            icon: Icons.water_drop_outlined,
            iconColor: const Color(0xFF2196F3),
            bgColor: const Color(0xFFE3F2FD),
            title: 'Hydration Reminder',
            items: [
              _FoodItem(name: 'Coconut Water', reason: 'Electrolytes'),
              _FoodItem(name: 'Cucumber Slices', reason: 'Hydrating snack'),
              _FoodItem(name: 'Herbal Tea', reason: 'Gentle hydration'),
            ],
          ),
        ];
    }
  }
}

class _RecommendationCategory {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final List<_FoodItem> items;

  const _RecommendationCategory({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.items,
  });
}

class _FoodItem {
  final String name;
  final String reason;
  const _FoodItem({required this.name, required this.reason});
}

class _CategoryCard extends StatelessWidget {
  final _RecommendationCategory category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: category.bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(
                  category.icon,
                  size: 20,
                  color: category.iconColor,
                ),
                const SizedBox(width: 8),
                Text(
                  category.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: category.iconColor,
                  ),
                ),
              ],
            ),
          ),
          ...category.items.map(
            (item) => Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.reason,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _WhyCard extends StatelessWidget {
  final String mood;
  final int energy;
  const _WhyCard({required this.mood, required this.energy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.bolt,
              size: 18,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Why these recommendations?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _explanation(mood, energy),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _explanation(String mood, int energy) {
    switch (mood) {
      case 'tired':
        return 'Our AI analyzed your mood, energy level, and sleep quality. These foods contain nutrients that can help restore your energy and improve focus naturally.';
      case 'stressed':
        return 'Our AI detected elevated stress. These foods contain magnesium, vitamin B, and antioxidants that can help calm your nervous system naturally.';
      case 'sad':
        return 'Our AI found foods rich in omega-3, serotonin precursors, and mood-supporting vitamins to help lift your spirits naturally.';
      case 'energetic':
        return 'Great energy today! Our AI selected foods to sustain your performance and keep your metabolism optimal throughout the day.';
      default:
        return 'Our AI analyzed your mood, energy level, and sleep quality. These foods contain nutrients that can help boost your energy and reduce stress naturally.';
    }
  }
}
