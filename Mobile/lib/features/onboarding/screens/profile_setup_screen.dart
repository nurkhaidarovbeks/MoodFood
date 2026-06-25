import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isEditing;
  const ProfileSetupScreen({super.key, this.isEditing = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 3;

  // Step 1 — Goals (multi-select)
  final Set<String> _selectedGoals = {};

  // Step 2 — Diet preference (single select)
  String? _selectedDiet;

  // Step 3 — Allergies (multi-select)
  final Set<String> _selectedAllergies = {};

  static const _goals = [
    ('more_energy', '⚡', 'More Energy'),
    ('better_focus', '🎯', 'Better Focus'),
    ('better_sleep', '😴', 'Better Sleep'),
    ('reduce_stress', '🧘', 'Reduce Stress'),
    ('improve_mood', '😊', 'Improve Mood'),
    ('general_health', '💪', 'General Health'),
  ];

  static const _diets = [
    'No Preference',
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Keto',
    'Paleo',
  ];

  static const _allergies = [
    'Dairy',
    'Eggs',
    'Peanuts',
    'Tree Nuts',
    'Soy',
    'Wheat',
    'Fish',
    'Shellfish',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
  }

  void _loadExisting() {
    final profile = context.read<ProfileProvider>().profile;
    if (profile == null) return;
    setState(() {
      if (profile.goal != null && profile.goal!.isNotEmpty) {
        _selectedGoals.addAll(profile.goal!.split(','));
      }
      if (profile.dietaryRestrictions.isNotEmpty) {
        final diet = profile.dietaryRestrictions.first;
        _selectedDiet = diet[0].toUpperCase() + diet.substring(1);
      }
      for (final a in profile.allergies) {
        final label = a.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
        _selectedAllergies.add(label);
      }
    });
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  // Maps Flutter UI labels → backend DIETARY_RESTRICTION_KEYS
  static const _allergyToKey = {
    'Dairy':      'lactose_free',
    'Eggs':       'egg_allergy',
    'Peanuts':    'nut_allergy',
    'Tree Nuts':  'nut_allergy',
    'Soy':        'soy_allergy',
    'Wheat':      'gluten_free',
  };

  static const _dietToKey = {
    'Vegetarian':  'vegetarian',
    'Vegan':       'vegan',
    'Pescatarian': 'pescatarian',
  };

  Future<void> _submit() async {
    // Diet → known backend key or customRestrictions
    final List<String> diet = [];
    final List<String> custom = [];

    if (_selectedDiet != null && _selectedDiet != 'No Preference') {
      final key = _dietToKey[_selectedDiet!];
      if (key != null) {
        diet.add(key);
      } else {
        custom.add(_selectedDiet!.toLowerCase()); // e.g. 'keto', 'paleo'
      }
    }

    // Allergies → known keys or customRestrictions
    final List<String> allergies = [];
    for (final label in _selectedAllergies) {
      final key = _allergyToKey[label];
      if (key != null) {
        if (!allergies.contains(key)) allergies.add(key);
      } else {
        custom.add(label.toLowerCase()); // e.g. 'fish', 'shellfish'
      }
    }

    final profile = ProfileModel(
      goal: _selectedGoals.join(','),
      dietaryRestrictions: diet,
      allergies: allergies,
      customRestrictions: custom,
    );

    final profileProvider = context.read<ProfileProvider>();
    final ok = await profileProvider.saveProfile(profile);
    if (!mounted) return;
    if (ok) {
      if (widget.isEditing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated!'),
            backgroundColor: Color(0xFF7CB342),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profileProvider.error ?? 'Failed to save profile'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProfileProvider>().isLoading;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isEditing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
                          const Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: List.generate(_totalPages, (i) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i < _totalPages - 1 ? 6 : 0),
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= _currentPage
                                ? AppTheme.primary
                                : const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Step ${_currentPage + 1} of $_totalPages',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _Step1Goals(
                    goals: _goals,
                    selected: _selectedGoals,
                    onToggle: (k) => setState(() {
                      if (_selectedGoals.contains(k)) {
                        _selectedGoals.remove(k);
                      } else {
                        _selectedGoals.add(k);
                      }
                    }),
                  ),
                  _Step2Diet(
                    diets: _diets,
                    selected: _selectedDiet,
                    onSelect: (d) => setState(() => _selectedDiet = d),
                  ),
                  _Step3Allergies(
                    allergies: _allergies,
                    selected: _selectedAllergies,
                    onToggle: (a) => setState(() {
                      if (_selectedAllergies.contains(a)) {
                        _selectedAllergies.remove(a);
                      } else {
                        _selectedAllergies.add(a);
                      }
                    }),
                  ),
                ],
              ),
            ),

            // Continue button
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentPage == 0 && _selectedGoals.isEmpty
                        ? AppTheme.primary.withValues(alpha: 0.5)
                        : AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading && _currentPage == _totalPages - 1
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _totalPages - 1
                                  ? (widget.isEditing ? 'Save Changes' : 'Complete Setup')
                                  : 'Continue',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right, size: 20),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 1: Goals ────────────────────────────────────────────────────────────

class _Step1Goals extends StatelessWidget {
  final List<(String, String, String)> goals;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _Step1Goals({
    required this.goals,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.track_changes,
                  size: 16,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'What are your goals?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Select all that apply',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            itemCount: goals.length,
            itemBuilder: (_, i) {
              final (key, emoji, label) = goals[i];
              final isSelected = selected.contains(key);
              return GestureDetector(
                onTap: () => onToggle(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : const Color(0xFFEEEEEE),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 24)),
                      const Spacer(),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Step 2: Diet Preference ─────────────────────────────────────────────────

class _Step2Diet extends StatelessWidget {
  final List<String> diets;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _Step2Diet({
    required this.diets,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant,
                  size: 14,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Diet Preferences',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'How do you prefer to eat?',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          ...diets.map((diet) {
            final isSelected = selected == diet;
            return GestureDetector(
              onTap: () => onSelect(diet),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withValues(alpha: 0.06)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : const Color(0xFFEEEEEE),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  diet,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppTheme.primary : AppTheme.textDark,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Step 3: Allergies ────────────────────────────────────────────────────────

class _Step3Allergies extends StatelessWidget {
  final List<String> allergies;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _Step3Allergies({
    required this.allergies,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Any Allergies?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "We'll make sure to avoid these",
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allergies.map((a) {
              final isSelected = selected.contains(a);
              return GestureDetector(
                onTap: () => onToggle(a),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 10 : 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFF3E0)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF8F00)
                          : const Color(0xFFDDDDDD),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        a,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFFE65100)
                              : AppTheme.textDark,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.close,
                          size: 14,
                          color: Color(0xFFE65100),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Info card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFE0B2)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.favorite_outline,
                  size: 16,
                  color: Color(0xFFFF8F00),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Almost there!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE65100),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "We'll use this information to personalize your meal recommendations and keep you safe.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8D6E63),
                          height: 1.4,
                        ),
                      ),
                    ],
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
