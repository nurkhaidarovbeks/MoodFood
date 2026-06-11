import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 4;

  // Step 1 — basic info
  final _ageCtrl = TextEditingController();
  String? _lifestyle;

  // Step 2 — budget
  String? _budgetLevel;

  // Step 3 — dietary restrictions
  final Set<String> _restrictions = {};

  // Step 4 — allergies + custom
  final Set<String> _allergies = {};
  final _customCtrl = TextEditingController();
  final List<String> _customList = [];

  @override
  void dispose() {
    _pageController.dispose();
    _ageCtrl.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submit() async {
    final profile = ProfileModel(
      age: int.tryParse(_ageCtrl.text.trim()),
      lifestyle: _lifestyle,
      budgetLevel: _budgetLevel,
      dietaryRestrictions: _restrictions.toList(),
      allergies: _allergies.toList(),
      customRestrictions: _customList,
    );

    final profileProvider = context.read<ProfileProvider>();
    final ok = await profileProvider.saveProfile(profile);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/home');
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

  bool get _canProceed {
    switch (_currentPage) {
      case 0:
        return true;
      case 1:
        return _budgetLevel != null;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProfileProvider>().isLoading;
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Step ${_currentPage + 1} of $_totalPages'),
        automaticallyImplyLeading: _currentPage > 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: _back,
              )
            : null,
        actions: [
          if (_currentPage < _totalPages - 1)
            TextButton(
              onPressed: _next,
              child: const Text('Skip'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
              backgroundColor: AppTheme.divider,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryGreen),
              borderRadius: BorderRadius.circular(4),
              minHeight: 4,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (p) => setState(() => _currentPage = p),
              children: [
                _Step1BasicInfo(
                  userName: user?.displayName,
                  ageCtrl: _ageCtrl,
                  selectedLifestyle: _lifestyle,
                  onLifestyleChanged: (v) =>
                      setState(() => _lifestyle = v),
                ),
                _Step2Budget(
                  selected: _budgetLevel,
                  onChanged: (v) => setState(() => _budgetLevel = v),
                ),
                _Step3Restrictions(
                  selected: _restrictions,
                  onToggle: (k) => setState(() {
                    if (_restrictions.contains(k)) {
                      _restrictions.remove(k);
                    } else {
                      _restrictions.add(k);
                    }
                  }),
                ),
                _Step4Allergies(
                  selected: _allergies,
                  onToggle: (k) => setState(() {
                    if (_allergies.contains(k)) {
                      _allergies.remove(k);
                    } else {
                      _allergies.add(k);
                    }
                  }),
                  customCtrl: _customCtrl,
                  customList: _customList,
                  onAddCustom: () {
                    final v = _customCtrl.text.trim();
                    if (v.isNotEmpty && !_customList.contains(v.toLowerCase())) {
                      setState(() {
                        _customList.add(v.toLowerCase());
                        _customCtrl.clear();
                      });
                    }
                  },
                  onRemoveCustom: (v) =>
                      setState(() => _customList.remove(v)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: ElevatedButton(
              onPressed: (_canProceed && !isLoading) ? _next : null,
              child: isLoading && _currentPage == _totalPages - 1
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _currentPage == _totalPages - 1
                          ? 'Finish Setup'
                          : 'Continue',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 1: Basic info ───────────────────────────────────────────────────────

class _Step1BasicInfo extends StatelessWidget {
  final String? userName;
  final TextEditingController ageCtrl;
  final String? selectedLifestyle;
  final ValueChanged<String?> onLifestyleChanged;

  const _Step1BasicInfo({
    this.userName,
    required this.ageCtrl,
    required this.selectedLifestyle,
    required this.onLifestyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userName != null ? 'Hi, $userName! 👋' : 'Tell us about you 👋',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This helps us give you relevant meal recommendations.',
            style: TextStyle(fontSize: 14, color: AppTheme.textMedium, height: 1.5),
          ),
          const SizedBox(height: 28),
          const Text(
            'Your age (optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: ageCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: const InputDecoration(
              hintText: 'e.g. 22',
              prefixIcon: Icon(Icons.cake_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your lifestyle',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ...ProfileModel.lifestyleLabels.entries.map(
            (e) => _OptionTile(
              label: e.value,
              icon: _lifestyleIcon(e.key),
              selected: selectedLifestyle == e.key,
              onTap: () => onLifestyleChanged(e.key),
            ),
          ),
        ],
      ),
    );
  }

  String _lifestyleIcon(String key) {
    switch (key) {
      case 'student':
        return '🎓';
      case 'professional':
        return '💼';
      default:
        return '🙂';
    }
  }
}

// ─── Step 2: Budget ───────────────────────────────────────────────────────────

class _Step2Budget extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _Step2Budget({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final budgets = {
      'low': ('🪙', 'Low Budget', 'Affordable meals for students'),
      'medium': ('💰', 'Medium Budget', 'Balanced cost & quality'),
      'high': ('💎', 'High Budget', 'Premium ingredients, no limits'),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s your budget? 💸',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'ll suggest meals that fit your spending habits.',
            style: TextStyle(fontSize: 14, color: AppTheme.textMedium, height: 1.5),
          ),
          const SizedBox(height: 28),
          ...budgets.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OptionCard(
                emoji: e.value.$1,
                title: e.value.$2,
                subtitle: e.value.$3,
                selected: selected == e.key,
                onTap: () => onChanged(e.key),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 3: Dietary restrictions ────────────────────────────────────────────

class _Step3Restrictions extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _Step3Restrictions({
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final items = {
      'vegan': ('🌱', 'Vegan'),
      'vegetarian': ('🥗', 'Vegetarian'),
      'pescatarian': ('🐟', 'Pescatarian'),
      'gluten_free': ('🌾', 'Gluten-free'),
      'lactose_free': ('🥛', 'Lactose-free'),
      'halal': ('☪️', 'Halal'),
      'kosher': ('✡️', 'Kosher'),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dietary restrictions 🥦',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select all that apply. We\'ll filter recipes accordingly.',
            style: TextStyle(fontSize: 14, color: AppTheme.textMedium, height: 1.5),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.entries
                .map(
                  (e) => _SelectableChip(
                    emoji: e.value.$1,
                    label: e.value.$2,
                    selected: selected.contains(e.key),
                    onTap: () => onToggle(e.key),
                  ),
                )
                .toList(),
          ),
          if (selected.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'No restrictions? Great — you\'ll see all recipes!',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Step 4: Allergies + custom ───────────────────────────────────────────────

class _Step4Allergies extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final TextEditingController customCtrl;
  final List<String> customList;
  final VoidCallback onAddCustom;
  final ValueChanged<String> onRemoveCustom;

  const _Step4Allergies({
    required this.selected,
    required this.onToggle,
    required this.customCtrl,
    required this.customList,
    required this.onAddCustom,
    required this.onRemoveCustom,
  });

  @override
  Widget build(BuildContext context) {
    final allergies = {
      'nut_allergy': ('🥜', 'Nut allergy'),
      'egg_allergy': ('🥚', 'Egg allergy'),
      'soy_allergy': ('🫘', 'Soy allergy'),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Allergies & avoidances 🚫',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We take this seriously — these will always be filtered out.',
            style: TextStyle(fontSize: 14, color: AppTheme.textMedium, height: 1.5),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: allergies.entries
                .map(
                  (e) => _SelectableChip(
                    emoji: e.value.$1,
                    label: e.value.$2,
                    selected: selected.contains(e.key),
                    onTap: () => onToggle(e.key),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Anything else to avoid?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: customCtrl,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => onAddCustom(),
                  decoration: const InputDecoration(
                    hintText: 'e.g. mushrooms, coriander',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: onAddCustom,
                icon: const Icon(Icons.add, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          if (customList.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: customList
                  .map(
                    (v) => Chip(
                      label: Text(v),
                      deleteIcon:
                          const Icon(Icons.close, size: 16),
                      onDeleted: () => onRemoveCustom(v),
                      backgroundColor:
                          const Color(0xFFFFEBEE),
                      side: const BorderSide(
                          color: Color(0xFFFFCDD2)),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryGreen.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primaryGreen : AppTheme.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: selected ? AppTheme.primaryGreen : AppTheme.textDark,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryGreen,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryGreen.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primaryGreen : AppTheme.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppTheme.primaryGreen
                          : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryGreen,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppTheme.primaryGreen : AppTheme.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
