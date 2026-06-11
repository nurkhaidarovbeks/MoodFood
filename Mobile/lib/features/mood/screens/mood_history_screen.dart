import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/mood_entry_model.dart';
import '../../../core/providers/mood_provider.dart';
import '../../../core/theme/app_theme.dart';

class MoodHistoryScreen extends StatelessWidget {
  const MoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<MoodProvider>().entries;
    final weekEntries = context.watch<MoodProvider>().weekEntries;

    return Scaffold(
      appBar: AppBar(title: const Text('Mood History')),
      body: entries.isEmpty
          ? _EmptyState()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _WeekSummary(entries: weekEntries),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _MoodEntryCard(entry: entries[i]),
                      childCount: entries.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _WeekSummary extends StatelessWidget {
  final List<MoodEntry> entries;

  const _WeekSummary({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final avgEnergy = entries.isEmpty
        ? 0.0
        : entries.map((e) => e.energyLevel).reduce((a, b) => a + b) /
            entries.length;

    final moodCount = <String, int>{};
    for (final e in entries) {
      moodCount[e.mood] = (moodCount[e.mood] ?? 0) + 1;
    }
    final topMood = moodCount.entries.isEmpty
        ? null
        : moodCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreenMed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This week',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                label: '${entries.length} check-ins',
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(width: 10),
              _StatChip(
                label: 'Avg energy ${avgEnergy.toStringAsFixed(1)}/5',
                icon: Icons.bolt,
              ),
              if (topMood != null) ...[
                const SizedBox(width: 10),
                _StatChip(
                  label:
                      '${MoodEntry.moodEmojis[topMood] ?? ''} ${MoodEntry.moodLabels[topMood] ?? topMood}',
                  icon: null,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _StatChip({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodEntryCard extends StatelessWidget {
  final MoodEntry entry;

  const _MoodEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d • HH:mm').format(entry.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                entry.moodEmoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.moodLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.divider),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoTag(
                icon: Icons.bolt,
                label: 'Energy: ${entry.energyLevel}/5',
                color: AppTheme.accentAmber,
              ),
              const SizedBox(width: 8),
              _InfoTag(
                icon: Icons.psychology_outlined,
                label:
                    'Stress: ${MoodEntry.stressLabels[entry.stressLevel] ?? entry.stressLevel}',
                color: _stressColor(entry.stressLevel),
              ),
              const SizedBox(width: 8),
              _InfoTag(
                icon: Icons.bedtime_outlined,
                label:
                    'Sleep: ${entry.sleepQuality == 'poor' ? 'Poor' : entry.sleepQuality == 'normal' ? 'Normal' : 'Good'}',
                color: AppTheme.primaryGreenLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _stressColor(String level) {
    switch (level) {
      case 'low':
        return AppTheme.primaryGreenLight;
      case 'high':
        return AppTheme.errorColor;
      default:
        return AppTheme.accentAmber;
    }
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📊', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          const Text(
            'No mood history yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete your first mood check-in\nto start tracking your patterns.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textMedium, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, '/mood-check'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Check in now'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(160, 48),
            ),
          ),
        ],
      ),
    );
  }
}
