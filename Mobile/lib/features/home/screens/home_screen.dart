import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/mood_entry_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/mood_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../ingredients/screens/ingredients_screen.dart';
import '../../recipes/screens/recipes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          _HomeTab(),
          IngredientsScreen(),
          RecipesScreen(),
          _HistoryTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen),
            label: 'Fridge',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Recipes',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── Home tab ─────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final todayEntry = context.watch<MoodProvider>().todayEntry;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppTheme.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting,',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMedium,
                          ),
                        ),
                        Text(
                          user?.displayName ?? 'User',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text('🥗', style: TextStyle(fontSize: 34)),
                ],
              ),
            ),
            toolbarHeight: 72,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Today's check-in
                todayEntry != null
                    ? _TodayMoodCard(entry: todayEntry)
                    : _CheckInPrompt(),
                const SizedBox(height: 20),
                // Quick actions
                const Text(
                  'Quick actions',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                _QuickActionsGrid(),
                const SizedBox(height: 20),
                // Tips section
                _TipCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckInPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final entry =
            await Navigator.pushNamed(context, '/mood-check');
        if (entry != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mood saved! Check recommendations below.'),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryGreen, Color(0xFF388E3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🙂', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How are you feeling?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Check in to get personalized\nmeal recommendations',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Check In',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayMoodCard extends StatelessWidget {
  final MoodEntry entry;

  const _TodayMoodCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Today's check-in",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMedium,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/mood-check'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Update'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                entry.moodEmoji,
                style: const TextStyle(fontSize: 36),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.moodLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    'Energy: ${entry.energyLevel}/5  •  '
                    'Stress: ${MoodEntry.stressLabels[entry.stressLevel] ?? ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.restaurant_menu, size: 16),
            label: const Text('View Recommendations'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              textStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        '🎯',
        'Mood Check',
        'How are you now?',
        () => Navigator.pushNamed(context, '/mood-check')
      ),
      (
        '📊',
        'History',
        'View past entries',
        () => Navigator.pushNamed(context, '/mood-history')
      ),
      (
        '👤',
        'Profile',
        'Your preferences',
        () => Navigator.pushNamed(context, '/profile')
      ),
      (
        '🧊',
        'My Fridge',
        'What\'s available',
        () => Navigator.pushNamed(context, '/ingredients'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.4,
      ),
      itemCount: actions.length,
      itemBuilder: (_, i) {
        final (emoji, title, subtitle, onTap) = actions[i];
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMedium,
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

class _TipCard extends StatelessWidget {
  static const _tips = [
    ('💧', 'Stay hydrated!', 'Drink 6-8 glasses of water daily to boost energy and focus.'),
    ('🌱', 'Eat more greens!', 'Vegetables improve mood and provide long-lasting energy.'),
    ('⏰', 'Don\'t skip breakfast', 'A healthy breakfast sets your energy for the day.'),
    ('😴', 'Sleep well, eat well', 'Good sleep helps you make healthier food choices.'),
  ];

  @override
  Widget build(BuildContext context) {
    final tip = _tips[DateTime.now().day % _tips.length];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.accentAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentAmber.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tip.$1, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.$2,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.$3,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMedium,
                    height: 1.4,
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

// ─── History tab (wrapper) ────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<MoodProvider>().entries;

    if (entries.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('History')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📊', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              const Text(
                'No history yet',
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
                style: TextStyle(
                    fontSize: 14, color: AppTheme.textMedium, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/mood-check'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(160, 48)),
                child: const Text('Check in now'),
              ),
            ],
          ),
        ),
      );
    }

    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => const _FullHistoryPage(),
      ),
    );
  }
}

class _FullHistoryPage extends StatelessWidget {
  const _FullHistoryPage();

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<MoodProvider>().entries;
    final weekEntries = context.watch<MoodProvider>().weekEntries;

    return Scaffold(
      appBar: AppBar(title: const Text('Mood History')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _WeekSummary(entries: weekEntries),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _HistoryEntryCard(entry: entries[i]),
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

    final avgEnergy = entries.map((e) => e.energyLevel).reduce((a, b) => a + b) /
        entries.length;

    final moodCount = <String, int>{};
    for (final e in entries) {
      moodCount[e.mood] = (moodCount[e.mood] ?? 0) + 1;
    }
    final topMood = moodCount.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This week',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${entries.length} check-in${entries.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Avg energy: ${avgEnergy.toStringAsFixed(1)}/5',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Top mood: ${MoodEntry.moodEmojis[topMood] ?? ''} ${MoodEntry.moodLabels[topMood] ?? topMood}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  final MoodEntry entry;

  const _HistoryEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d • HH:mm').format(entry.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Text(entry.moodEmoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.moodLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Energy ${entry.energyLevel}/5  •  '
                  '${MoodEntry.stressLabels[entry.stressLevel] ?? ''} stress',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMedium,
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

// ─── Profile tab (wrapper) ────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => const _ProfilePage(),
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/profile-setup'),
            child: const Text('Edit'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (user?.displayName.isNotEmpty == true
                          ? user!.displayName[0].toUpperCase()
                          : '?'),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  user?.displayName ?? 'User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              Center(
                child: Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMedium,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _ProfileInfoSection(),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/welcome');
                  }
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About you',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: const Column(
            children: [
              _ProfileRow(
                icon: Icons.person_outline,
                label: 'Name',
                value: 'Set in your account',
              ),
              Divider(height: 16, color: AppTheme.divider),
              _ProfileRow(
                icon: Icons.restaurant_outlined,
                label: 'Dietary setup',
                value: 'Tap Edit to configure',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textMedium),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLight,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
