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
  double _energyLevel = 5;
  double _sleepQuality = 5;
  double _stressLevel = 5;
  double _hungerLevel = 5;

  // 6 moods matching Figma design
  static const _moods = [
    ('happy', '😊', 'Happy'),
    ('energetic', '⚡', 'Energetic'),
    ('calm', '😌', 'Calm'),
    ('tired', '😴', 'Tired'),
    ('stressed', '😰', 'Stressed'),
    ('sad', '😢', 'Sad'),
  ];

  String _sleepCategory(double v) {
    if (v <= 3) return 'poor';
    if (v <= 7) return 'normal';
    return 'good';
  }

  String _stressCategory(double v) {
    if (v <= 3) return 'low';
    if (v <= 7) return 'medium';
    return 'high';
  }

  String _hungerCategory(double v) {
    if (v <= 3) return 'low';
    if (v <= 7) return 'medium';
    return 'high';
  }

  int _energyInt(double v) => ((v / 2).ceil()).clamp(1, 5);

  Future<void> _submit() async {
    if (_selectedMood == null) return;

    final entry = MoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      mood: _selectedMood!,
      energyLevel: _energyInt(_energyLevel),
      stressLevel: _stressCategory(_stressLevel),
      sleepQuality: _sleepCategory(_sleepQuality),
      hungerLevel: _hungerCategory(_hungerLevel),
    );

    await context.read<MoodProvider>().saveMoodEntry(entry);
    if (!mounted) return;

    // Navigate to recommendations screen
    Navigator.pushReplacementNamed(
      context,
      '/recommendations',
      arguments: entry,
    );
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
        title: const Text(
          'Daily Mood Check',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How are you feeling?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Let's check in on your mood and energy",
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 28),

              // Mood grid
              const Text(
                'Select your mood',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              _MoodGrid(
                moods: _moods,
                selected: _selectedMood,
                onSelect: (m) => setState(() => _selectedMood = m),
              ),
              const SizedBox(height: 28),

              // Energy level slider
              _SliderSection(
                title: 'Energy Level',
                value: _energyLevel,
                minLabel: 'Low',
                maxLabel: 'High',
                onChanged: (v) => setState(() => _energyLevel = v),
              ),
              const SizedBox(height: 20),

              // Sleep quality slider
              _SliderSection(
                title: 'Sleep Quality',
                value: _sleepQuality,
                minLabel: 'Poor',
                maxLabel: 'Excellent',
                onChanged: (v) => setState(() => _sleepQuality = v),
              ),
              const SizedBox(height: 20),

              // Stress level slider
              _SliderSection(
                title: 'Stress Level',
                value: _stressLevel,
                minLabel: 'Relaxed',
                maxLabel: 'Very Stressed',
                onChanged: (v) => setState(() => _stressLevel = v),
              ),
              const SizedBox(height: 20),

              // Hunger level slider
              _SliderSection(
                title: 'Hunger Level',
                value: _hungerLevel,
                minLabel: 'Not Hungry',
                maxLabel: 'Very Hungry',
                onChanged: (v) => setState(() => _hungerLevel = v),
              ),
              const SizedBox(height: 36),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedMood != null ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    disabledBackgroundColor:
                        AppTheme.primary.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get AI Recommendations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                ),
              ),
              if (_selectedMood == null)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Center(
                    child: Text(
                      'Select a mood to continue',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
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
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: moods.length,
      itemBuilder: (_, i) {
        final (key, emoji, label) = moods[i];
        final isSelected = selected == key;
        return GestureDetector(
          onTap: () => onSelect(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isSelected ? AppTheme.primary : const Color(0xFFEEEEEE),
                width: isSelected ? 2 : 1,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
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

class _SliderSection extends StatelessWidget {
  final String title;
  final double value;
  final String minLabel;
  final String maxLabel;
  final ValueChanged<double> onChanged;

  const _SliderSection({
    required this.title,
    required this.value,
    required this.minLabel,
    required this.maxLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              '${value.round()}/10',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: const Color(0xFFE0E0E0),
            thumbColor: AppTheme.primary,
            overlayColor: AppTheme.primary.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              minLabel,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              maxLabel,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
