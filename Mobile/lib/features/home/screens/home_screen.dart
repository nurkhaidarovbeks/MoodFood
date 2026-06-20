import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/mood_entry_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/mood_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/theme/app_theme.dart';
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
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _HomeTab(onSwitchTab: (i) => setState(() => _tabIndex = i)),
          const RecipesScreen(),
          const _AIChatTab(),
          const _TrackerTab(),
          const _ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: const Color(0xFFAAAAAA),
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy),
            label: 'AI Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Tracker',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final void Function(int tab) onSwitchTab;
  const _HomeTab({required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final todayEntry = context.watch<MoodProvider>().todayEntry;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    final firstName = (user?.displayName ?? 'Alex').split(' ').first;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting,',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          firstName,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const Text(
                          'How are you feeling today?',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/notifications'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        size: 20,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Daily Mood Check card
                _DailyMoodCard(todayEntry: todayEntry),
                const SizedBox(height: 16),

                // Water + Calories stats
                _StatsRow(todayEntry: todayEntry),
                const SizedBox(height: 20),

                // Today's Meals
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today's Meals",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onSwitchTab(1),
                      child: const Text(
                        'See all >',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TodayMealsList(),
                const SizedBox(height: 20),

                // AI Insight
                _AiInsightCard(todayEntry: todayEntry),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyMoodCard extends StatelessWidget {
  final MoodEntry? todayEntry;
  const _DailyMoodCard({required this.todayEntry});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final entry =
            await Navigator.pushNamed(context, '/mood-check');
        if (entry != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mood saved!'),
              backgroundColor: AppTheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Mood Check',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    todayEntry != null
                        ? 'Feeling ${todayEntry!.moodLabel} today'
                        : 'Track how you feel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatefulWidget {
  final MoodEntry? todayEntry;
  const _StatsRow({required this.todayEntry});

  @override
  State<_StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<_StatsRow> {
  static const _waterKey = 'water_glasses';
  static const _goal = 8;
  int _glasses = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final saved = prefs.getString(_waterKey);
    if (saved != null && saved.startsWith(today)) {
      final count = int.tryParse(saved.split(':').last) ?? 0;
      if (mounted) setState(() => _glasses = count);
    }
  }

  Future<void> _set(int v) async {
    final clamped = v.clamp(0, 12);
    setState(() => _glasses = clamped);
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_waterKey, '$today:$clamped');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _WaterCard(
            glasses: _glasses,
            goal: _goal,
            onAdd: () => _set(_glasses + 1),
            onRemove: () => _set(_glasses - 1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CaloriesCard(entry: widget.todayEntry),
        ),
      ],
    );
  }
}

class _WaterCard extends StatelessWidget {
  final int glasses;
  final int goal;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _WaterCard({
    required this.glasses,
    required this.goal,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_outlined,
                  size: 16, color: Color(0xFF2196F3)),
              const SizedBox(width: 6),
              const Text(
                'Water',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2196F3),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$glasses/$goal',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const Text(
            'glasses today',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _WaterBtn(
                icon: Icons.remove,
                onTap: onRemove,
                enabled: glasses > 0,
              ),
              const SizedBox(width: 8),
              _WaterBtn(icon: Icons.add, onTap: onAdd, enabled: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _WaterBtn({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF2196F3).withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? const Color(0xFF2196F3) : Colors.grey,
        ),
      ),
    );
  }
}

class _CaloriesCard extends StatelessWidget {
  final MoodEntry? entry;
  const _CaloriesCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final calories = entry != null ? '${(entry!.energyLevel * 200).round()}' : '0';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBE9E7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department_outlined,
                  size: 16, color: Color(0xFFFF7043)),
              SizedBox(width: 6),
              Text(
                'Calories',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFF7043),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            calories,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const Text(
            'of 2,000 goal',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/mood-check'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7043).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '+ Log meal',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF7043),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayMealsList extends StatelessWidget {
  static const _meals = [
    (
      '🥑',
      'Avocado Toast Bowl',
      'Breakfast',
      'High Energy',
      const Color(0xFFE8F5E9),
      const Color(0xFF388E3C),
      320,
      15
    ),
    (
      '🥗',
      'Quinoa Buddha Bowl',
      'Lunch',
      'Balanced',
      const Color(0xFFE3F2FD),
      const Color(0xFF1976D2),
      450,
      25
    ),
    (
      '🐟',
      'Salmon with Greens',
      'Dinner',
      'Focus Boost',
      const Color(0xFFF3E5F5),
      const Color(0xFF7B1FA2),
      380,
      30
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _meals.map((m) {
        final (emoji, name, type, tag, tagBg, tagColor, cal, mins) = m;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
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
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: tagColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$cal cal · $mins min',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                type,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  final MoodEntry? todayEntry;
  const _AiInsightCard({required this.todayEntry});

  @override
  Widget build(BuildContext context) {
    final text = todayEntry != null
        ? _insightForMood(todayEntry!.mood)
        : 'Your energy levels are highest in the morning. '
            'Try having protein-rich meals to maintain focus throughout the day!';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
        ),
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
              Icons.trending_up,
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
                  'AI Insight',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
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

  static String _insightForMood(String mood) {
    switch (mood) {
      case 'tired':
        return 'You\'re feeling tired. Iron-rich foods like spinach and lentils can help restore your energy naturally.';
      case 'stressed':
        return 'Stress detected! Magnesium-rich foods like dark chocolate, almonds and avocados can help calm your nervous system.';
      case 'sad':
        return 'Omega-3 fatty acids in salmon, walnuts and flaxseed are proven to support your mood and emotional well-being.';
      case 'energetic':
        return 'Great energy today! Stay balanced with complex carbs and lean protein to keep your energy steady all day.';
      case 'happy':
        return 'You\'re in a great mood! Maintain it with antioxidant-rich berries and leafy greens for lasting well-being.';
      case 'calm':
        return 'Calm energy is wonderful. Green tea and whole grains can help sustain this relaxed, focused state.';
      default:
        return 'Your energy levels are highest in the morning. Try having protein-rich meals to maintain focus throughout the day!';
    }
  }
}

// ─── AI Chat Tab ─────────────────────────────────────────────────────────────

class _AIChatTab extends StatefulWidget {
  const _AIChatTab();

  @override
  State<_AIChatTab> createState() => _AIChatTabState();
}

class _AIChatTabState extends State<_AIChatTab> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();
  final List<_ChatMsg> _messages = [
    const _ChatMsg(
      text:
          "Hi! I'm your MoodFood AI assistant. How can I help you with your nutrition today?",
      isUser: false,
      time: '10:30 AM',
    ),
  ];

  static const _quickSuggestions = [
    "What should I eat if I'm stressed?",
    'Quick dinner for low energy?',
    'Healthy study snacks?',
    'Best foods for better sleep',
  ];

  static const _aiResponses = {
    'stress': "When you're feeling stressed, try foods rich in magnesium and vitamin B like dark chocolate, almonds, avocados, and leafy greens. Green tea can also help calm your mind!",
    'energy':
        'For a quick energy boost, I recommend bananas with nut butter, Greek yogurt with berries, or a smoothie with spinach and fruit. These provide sustained energy without the crash!',
    'snack':
        'Great study snacks include trail mix, apple slices with almond butter, hummus with veggies, or dark chocolate with almonds. These help maintain focus and energy!',
    'sleep':
        'Foods that promote better sleep include almonds, chamomile tea, kiwi, fatty fish like salmon, and tart cherry juice. Avoid caffeine 6 hours before bed!',
    'protein':
        'Excellent protein sources include eggs, Greek yogurt, chicken breast, lentils, tofu, and quinoa. Aim for 20-30g per meal for optimal muscle maintenance.',
    'mood':
        'To boost your mood naturally, try foods rich in omega-3 (salmon, walnuts), magnesium (dark chocolate, spinach), and probiotics (yogurt, kefir). These support brain chemistry!',
    'weight':
        'For healthy weight management, focus on fiber-rich foods like vegetables, legumes, and whole grains. They keep you full longer and support steady blood sugar levels.',
    'default':
        'That\'s a great question! I suggest focusing on whole, unprocessed foods that align with your mood and energy needs. Would you like specific recipe recommendations?',
  };

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add(_ChatMsg(text: text.trim(), isUser: true, time: timeStr));
      _msgCtrl.clear();
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMsg(
          text: _getResponse(text.toLowerCase()),
          isUser: false,
          time: timeStr,
        ));
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 80,
      );
      if (picked == null || !mounted) return;
      final now = DateTime.now();
      final timeStr =
          '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour < 12 ? 'AM' : 'PM'}';
      setState(() {
        _messages.add(_ChatMsg(
          text: '📷 [Photo shared]',
          isUser: true,
          time: timeStr,
          imagePath: picked.path,
        ));
      });
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      final replyTime =
          '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour < 12 ? 'AM' : 'PM'}';
      setState(() {
        _messages.add(_ChatMsg(
          text:
              '📸 I can see your food photo! Based on what I can tell, this looks like a nutritious meal. For accurate calorie and macro tracking, try describing the specific ingredients. I can give you detailed nutritional insights and mood-boosting recommendations!',
          isUser: false,
          time: replyTime,
        ));
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      // Permission denied or cancelled
    }
  }

  String _getResponse(String input) {
    if (input.contains('stress') || input.contains('anxious')) {
      return _aiResponses['stress']!;
    } else if (input.contains('energy') ||
        input.contains('tired') ||
        input.contains('low')) {
      return _aiResponses['energy']!;
    } else if (input.contains('snack') || input.contains('study')) {
      return _aiResponses['snack']!;
    } else if (input.contains('sleep') || input.contains('bed')) {
      return _aiResponses['sleep']!;
    } else if (input.contains('protein') || input.contains('muscle')) {
      return _aiResponses['protein']!;
    } else if (input.contains('mood') || input.contains('happy') ||
        input.contains('sad')) {
      return _aiResponses['mood']!;
    } else if (input.contains('weight') || input.contains('diet')) {
      return _aiResponses['weight']!;
    } else if (input.contains('photo') || input.contains('analyze') ||
        input.contains('gallery')) {
      return '📸 Photo analysis is coming soon! For now, I can help you by name — just describe what you ate and I\'ll give you nutritional insights and mood recommendations.';
    }
    return _aiResponses['default']!;
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Assistant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Online',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _ChatBubble(msg: _messages[i]),
              ),
            ),
            // Quick suggestions (show only when no user messages)
            if (_messages.length == 1) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick suggestions:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 3.0,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _quickSuggestions.map((s) {
                        return GestureDetector(
                          onTap: () => _sendMessage(s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: Text(
                              s,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textDark,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
            // Share a photo section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Share a photo',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 16),
                          label: const Text('Camera'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_outlined, size: 16),
                          label: const Text('Gallery'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Input field
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                  16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 22,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppTheme.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppTheme.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: AppTheme.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: AppTheme.background,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _sendMessage(_msgCtrl.text),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMsg {
  final String text;
  final bool isUser;
  final String time;
  final String? imagePath;
  const _ChatMsg({
    required this.text,
    required this.isUser,
    required this.time,
    this.imagePath,
  });
}

class _ChatBubble extends StatelessWidget {
  final _ChatMsg msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!msg.isUser)
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                const Text(
                  'MoodFood AI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          if (!msg.isUser) const SizedBox(height: 6),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: msg.isUser ? AppTheme.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                bottomRight: Radius.circular(msg.isUser ? 4 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (msg.imagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(msg.imagePath!),
                      width: 180,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (msg.imagePath != null && msg.text != '📷 [Photo shared]')
                  const SizedBox(height: 6),
                if (msg.text != '📷 [Photo shared]' || msg.imagePath == null)
                  Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 13,
                      color: msg.isUser ? Colors.white : AppTheme.textDark,
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            msg.time,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tracker Tab ─────────────────────────────────────────────────────────────

class _TrackerTab extends StatelessWidget {
  const _TrackerTab();

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<MoodProvider>().entries;
    final weekEntries = context.watch<MoodProvider>().weekEntries;

    final avgEnergy = weekEntries.isEmpty
        ? 7.0
        : weekEntries
                .map((e) => e.energyLevel * 2.0)
                .reduce((a, b) => a + b) /
            weekEntries.length;

    final streak = entries.isNotEmpty ? math.min(entries.length, 7) : 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Progress',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const Text(
                      'Track your daily habits and trends',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stats grid
                  _TrackerStatsGrid(avgEnergy: avgEnergy),
                  const SizedBox(height: 20),

                  // Mood & Energy Trends chart
                  _MoodTrendCard(entries: weekEntries),
                  const SizedBox(height: 16),

                  // Great Progress card
                  if (weekEntries.length >= 3)
                    _ProgressCard(streak: streak),
                  if (weekEntries.length >= 3) const SizedBox(height: 16),

                  // Achievements
                  _AchievementsSection(streak: streak),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackerStatsGrid extends StatefulWidget {
  final double avgEnergy;
  const _TrackerStatsGrid({required this.avgEnergy});

  @override
  State<_TrackerStatsGrid> createState() => _TrackerStatsGridState();
}

class _TrackerStatsGridState extends State<_TrackerStatsGrid> {
  static const _waterKey = 'water_glasses';
  int _glasses = 0;

  @override
  void initState() {
    super.initState();
    _loadWater();
  }

  Future<void> _loadWater() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final saved = prefs.getString(_waterKey);
    if (saved != null && saved.startsWith(today)) {
      final count = int.tryParse(saved.split(':').last) ?? 0;
      if (mounted) setState(() => _glasses = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _TrackerStatCard(
          icon: Icons.water_drop_outlined,
          iconColor: const Color(0xFF2196F3),
          bgColor: Colors.white,
          title: 'Water',
          value: '$_glasses/8',
          subtitle: 'glasses',
        ),
        _TrackerStatCard(
          icon: Icons.restaurant_outlined,
          iconColor: AppTheme.primary,
          bgColor: Colors.white,
          title: 'Meals',
          value: '2/3',
          subtitle: 'today',
          showBar: true,
          barValue: 2 / 3,
          barColor: AppTheme.primary,
        ),
        _TrackerStatCard(
          icon: Icons.bedtime_outlined,
          iconColor: const Color(0xFF9C27B0),
          bgColor: Colors.white,
          title: 'Sleep',
          value: '7.5',
          subtitle: 'hours',
        ),
        _TrackerStatCard(
          icon: Icons.bolt_outlined,
          iconColor: const Color(0xFFFF7043),
          bgColor: Colors.white,
          title: 'Energy',
          value: '${widget.avgEnergy.toStringAsFixed(0)}/10',
          subtitle: 'avg',
          showBar: true,
          barValue: widget.avgEnergy / 10,
          barColor: const Color(0xFFFF7043),
        ),
      ],
    );
  }
}

class _TrackerStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String value;
  final String subtitle;
  final bool showBar;
  final double barValue;
  final Color barColor;

  const _TrackerStatCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.value,
    required this.subtitle,
    this.showBar = false,
    this.barValue = 0,
    this.barColor = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
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
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          if (showBar) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: barValue.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: AppTheme.divider,
                color: barColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoodTrendCard extends StatelessWidget {
  final List<MoodEntry> entries;
  const _MoodTrendCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mood & Energy Trends',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: const Text(
                  '7 days',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: _MiniLineChart(entries: entries),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Mood',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 16),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF7043),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Energy',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniLineChart extends StatelessWidget {
  final List<MoodEntry> entries;
  const _MiniLineChart({required this.entries});

  static double _moodToValue(String mood) {
    switch (mood) {
      case 'energetic':
        return 9;
      case 'happy':
        return 8;
      case 'calm':
        return 7;
      case 'focused':
        return 7;
      case 'cozy':
        return 6;
      case 'stressed':
        return 4;
      case 'tired':
        return 3;
      case 'sad':
        return 2;
      default:
        return 6;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate last 7 days data
    final now = DateTime.now();
    final List<double> moodData = [];
    final List<double> energyData = [];
    final List<String> labels = [];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      labels.add(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1]);

      final dayEntry = entries.where((e) {
        return e.timestamp.year == day.year &&
            e.timestamp.month == day.month &&
            e.timestamp.day == day.day;
      }).toList();

      if (dayEntry.isNotEmpty) {
        moodData.add(_moodToValue(dayEntry.last.mood));
        energyData.add(dayEntry.last.energyLevel * 2.0);
      } else {
        // Default values for days without entries
        final demo = [6.0, 7.0, 5.0, 8.0, 6.5, 7.5, 8.0];
        moodData.add(demo[6 - i]);
        energyData.add(demo[6 - i] - 0.5);
      }
    }

    return CustomPaint(
      painter: _LineChartPainter(
        moodData: moodData,
        energyData: energyData,
        labels: labels,
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> moodData;
  final List<double> energyData;
  final List<String> labels;

  _LineChartPainter({
    required this.moodData,
    required this.energyData,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const minY = 0.0;
    const maxY = 10.0;
    const bottomPad = 24.0;
    const topPad = 8.0;
    final chartH = size.height - bottomPad - topPad;
    final stepX = size.width / (moodData.length - 1);

    Offset toOffset(int i, double v) {
      final x = i * stepX;
      final y = topPad + chartH * (1 - (v - minY) / (maxY - minY));
      return Offset(x, y);
    }

    void drawLine(List<double> data, Color color) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      for (int i = 0; i < data.length; i++) {
        final o = toOffset(i, data[i]);
        if (i == 0) {
          path.moveTo(o.dx, o.dy);
        } else {
          final prev = toOffset(i - 1, data[i - 1]);
          final cp1 = Offset((prev.dx + o.dx) / 2, prev.dy);
          final cp2 = Offset((prev.dx + o.dx) / 2, o.dy);
          path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, o.dx, o.dy);
        }
      }
      canvas.drawPath(path, paint);

      final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
      for (int i = 0; i < data.length; i++) {
        final o = toOffset(i, data[i]);
        canvas.drawCircle(o, 3.5, dotPaint);
        canvas.drawCircle(o, 3.5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    }

    // Y-axis grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..strokeWidth = 1;
    for (final v in [0.0, 3.0, 6.0, 10.0]) {
      final y = topPad + chartH * (1 - (v - minY) / (maxY - minY));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    drawLine(energyData, const Color(0xFFFF7043));
    drawLine(moodData, AppTheme.primary);

    // Labels
    final tp = TextPainter(textDirection: ui.TextDirection.ltr);
    for (int i = 0; i < labels.length; i++) {
      tp.text = TextSpan(
        text: labels[i],
        style: const TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)),
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(i * stepX - tp.width / 2, size.height - tp.height),
      );
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.moodData != moodData || old.energyData != energyData;
}

class _ProgressCard extends StatelessWidget {
  final int streak;
  const _ProgressCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.trending_up,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Great Progress!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your mood and energy levels have improved by 25% this week. Keep up the healthy eating habits!',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
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

class _AchievementsSection extends StatelessWidget {
  final int streak;
  const _AchievementsSection({required this.streak});

  @override
  Widget build(BuildContext context) {
    final achievements = [
      ('🔥', '7 Day Streak', 'Logged meals daily', streak >= 7),
      ('💧', 'Hydration Hero', 'Met water goal 5 days', true),
      ('🥗', 'Healthy Eater', '50 nutritious meals', false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievements',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        ...achievements.map((a) {
          final (emoji, title, subtitle, unlocked) = a;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
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
                Text(
                  emoji,
                  style: TextStyle(
                    fontSize: 26,
                    color: unlocked ? null : const Color(0xFFCCCCCC),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: unlocked
                              ? AppTheme.textDark
                              : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Earned',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Profile Tab ─────────────────────────────────────────────────────────────

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  static const _avatarKey = 'avatar_path';
  static const _savedKey = 'saved_recipes';
  String? _avatarPath;
  int _savedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_avatarKey);
    if (path != null && File(path).existsSync()) {
      if (mounted) setState(() => _avatarPath = path);
    }
    final saved = prefs.getStringList(_savedKey) ?? [];
    if (mounted) setState(() => _savedCount = saved.length);
  }

  Future<void> _loadAvatar() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final entries = context.watch<MoodProvider>().entries;
    final streak = math.min(entries.length, 7);
    final isPremium = context.watch<SubscriptionProvider>().isPremium;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // User card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.pushNamed(context, '/edit-profile');
                                  _loadAvatar();
                                },
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: _avatarPath != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: Image.file(
                                                File(_avatarPath!),
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                user?.displayName.isNotEmpty == true
                                                    ? user!.displayName[0].toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.primary,
                                                ),
                                              ),
                                            ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                        child: const Icon(Icons.edit, color: Colors.white, size: 9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.displayName ?? 'Alex Johnson',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user?.email ?? 'alex@example.com',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: isPremium
                                          ? null
                                          : () => Navigator.pushNamed(context, '/premium'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isPremium
                                              ? const Color(0xFFE8F5E9)
                                              : const Color(0xFFFFF3E0),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          isPremium ? '⭐ Premium' : '🏆 Free Plan',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isPremium
                                                ? const Color(0xFF2E7D32)
                                                : const Color(0xFFE65100),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/settings'),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppTheme.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: AppTheme.divider),
                                  ),
                                  child: const Icon(
                                    Icons.settings_outlined,
                                    size: 18,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Stats row
                          Row(
                            children: [
                              Expanded(
                                child: _ProfileStat(
                                  emoji: '🔥',
                                  value: '$streak',
                                  label: 'Day Streak',
                                ),
                              ),
                              Expanded(
                                child: _ProfileStat(
                                  emoji: '♥',
                                  value: '$_savedCount',
                                  label: 'Recipes Saved',
                                ),
                              ),
                              Expanded(
                                child: _ProfileStat(
                                  emoji: '🎯',
                                  value: '15',
                                  label: 'Goals Hit',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Upgrade banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/premium'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8F00), Color(0xFFFF6F00)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Text('🏆',
                                style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Upgrade to Premium',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Unlock AI insights & unlimited recipes',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Your Goals section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _GoalsSection(),
                  ),
                  const SizedBox(height: 16),

                  // Saved Recipes
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SavedRecipesSection(),
                  ),
                  const SizedBox(height: 16),

                  // Achievements
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ProfileAchievements(),
                  ),
                  const SizedBox(height: 16),

                  // Links
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _ProfileLink(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          onTap: () =>
                              Navigator.pushNamed(context, '/settings'),
                        ),
                        const SizedBox(height: 8),
                        _ProfileLink(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          onTap: () =>
                              Navigator.pushNamed(context, '/notifications'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _ProfileStat(
      {required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _GoalsSection extends StatelessWidget {
  static const _goals = [
    ('More Energy', '⚡', 0.7),
    ('Better Focus', '🎯', 0.5),
    ('Reduce Stress', '🧘', 0.4),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Text(
            'Your Goals',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ..._goals.map((g) {
            final (name, emoji, progress) = g;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppTheme.divider,
                      color: AppTheme.primary,
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
}

class _SavedRecipesSection extends StatelessWidget {
  static const _recipes = [
    ('🥑', 'Avocado Toast Bowl'),
    ('🥗', 'Quinoa Buddha Bowl'),
    ('🍓', 'Berry Smoothie'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saved Recipes',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const Text(
                'View all',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._recipes.map((r) {
            final (emoji, name) = r;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.favorite,
                    size: 18,
                    color: Color(0xFFE53935),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ProfileAchievements extends StatelessWidget {
  static const _badges = [
    ('🔥', '7 Day\nStreak'),
    ('💧', 'Water\nHero'),
    ('🥗', 'Healthy\nEater'),
    ('🎯', 'Goal\nCrusher'),
    ('🌅', 'Early\nBird'),
    ('🏆', 'Champion'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Text(
            'Achievements',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: _badges.map((b) {
              final (emoji, label) = b;
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ProfileLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProfileLink(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
