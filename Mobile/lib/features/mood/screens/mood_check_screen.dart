import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/mood_entry_model.dart';
import '../../../core/providers/mood_provider.dart';
import '../../../core/theme/app_theme.dart';

class MoodCheckScreen extends StatefulWidget {
  const MoodCheckScreen({super.key});

  @override
  State<MoodCheckScreen> createState() => _MoodCheckScreenState();
}

class _MoodCheckScreenState extends State<MoodCheckScreen> {
  String? _selectedMood;
  int _energyLevel = 3;
  String? _stressLevel;
  String? _sleepQuality;

  static const _moods = [
    ('happy', '😊', 'Happy'),
    ('energetic', '⚡', 'Energetic'),
    ('calm', '😌', 'Calm'),
    ('focused', '🎯', 'Focused'),
    ('cozy', '🛋️', 'Cozy'),
    ('tired', '😴', 'Tired'),
    ('stressed', '😰', 'Stressed'),
  ];

  static const _stressOptions = [
    ('low', '🟢', 'Low'),
    ('medium', '🟡', 'Medium'),
    ('high', '🔴', 'High'),
  ];

  static const _sleepOptions = [
    ('poor', '😔', 'Poor'),
    ('normal', '😐', 'Normal'),
    ('good', '😊', 'Good'),
  ];

  bool get _canSave =>
      _selectedMood != null &&
      _stressLevel != null &&
      _sleepQuality != null;

  Future<void> _save() async {
    if (!_canSave) return;

    final entry = MoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      mood: _selectedMood!,
      energyLevel: _energyLevel,
      stressLevel: _stressLevel!,
      sleepQuality: _sleepQuality!,
    );

    await context.read<MoodProvider>().saveMoodEntry(entry);
    if (!mounted) return;

    Navigator.pop(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How are you feeling?'),
        leading: IconButton(
          icon: const Icon(Icons.close, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(
                title: 'Your mood right now',
                subtitle: 'Pick the one that fits best',
              ),
              const SizedBox(height: 14),
              _MoodGrid(
                moods: _moods,
                selected: _selectedMood,
                onSelect: (m) => setState(() => _selectedMood = m),
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'Energy level',
                subtitle: 'How much energy do you have? ($_energyLevel/5)',
              ),
              const SizedBox(height: 14),
              _EnergySelector(
                value: _energyLevel,
                onChanged: (v) => setState(() => _energyLevel = v),
              ),
              const SizedBox(height: 28),
              const _SectionHeader(
                title: 'Stress level',
                subtitle: 'How stressed are you?',
              ),
              const SizedBox(height: 14),
              _OptionRow(
                options: _stressOptions,
                selected: _stressLevel,
                onSelect: (v) => setState(() => _stressLevel = v),
              ),
              const SizedBox(height: 28),
              const _SectionHeader(
                title: 'Sleep quality',
                subtitle: 'How did you sleep last night?',
              ),
              const SizedBox(height: 14),
              _OptionRow(
                options: _sleepOptions,
                selected: _sleepQuality,
                onSelect: (v) => setState(() => _sleepQuality = v),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _canSave ? _save : null,
                icon: const Icon(Icons.restaurant_menu, size: 20),
                label: const Text('Save & Get Recommendations'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                ),
              ),
              if (!_canSave)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Center(
                    child: Text(
                      'Select mood, stress, and sleep to continue',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppTheme.textMedium),
        ),
      ],
    );
  }
}

class _MoodGrid extends StatelessWidget {
  final List<(String, String, String)> moods;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _MoodGrid({
    required this.moods,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: moods.length,
      itemBuilder: (_, i) {
        final (key, emoji, label) = moods[i];
        final isSelected = selected == key;
        return GestureDetector(
          onTap: () => onSelect(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.primaryGreen : AppTheme.divider,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : AppTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EnergySelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _EnergySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const emojis = ['😫', '😕', '😐', '🙂', '🤩'];
    const labels = ['Very Low', 'Low', 'Medium', 'High', 'Very High'];

    return Column(
      children: [
        Row(
          children: List.generate(5, (i) {
            final level = i + 1;
            final isSelected = level == value;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentAmber.withValues(alpha: 0.2)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentAmber
                          : AppTheme.divider,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        emojis[i],
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$level',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppTheme.accentAmber
                              : AppTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              labels[0],
              style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
            ),
            Text(
              labels[4],
              style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
            ),
          ],
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  final List<(String, String, String)> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _OptionRow({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.asMap().entries.map((entry) {
        final i = entry.key;
        final (key, emoji, label) = entry.value;
        final isSelected = selected == key;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isSelected ? AppTheme.primaryGreen : AppTheme.divider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
