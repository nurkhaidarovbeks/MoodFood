import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _PageData(
      emoji: '🥗',
      bgColor: Color(0xFFE8F5E9),
      iconColor: Color(0xFF7CB342),
      title: 'Eat Smart,\nFeel Better',
      subtitle:
          'Discover meals that match how you feel and help you build energy, focus, and balance.',
    ),
    _PageData(
      emoji: '🤖',
      bgColor: Color(0xFFE3F2FD),
      iconColor: Color(0xFF1976D2),
      title: 'AI-Powered\nRecommendations',
      subtitle:
          'Get personalized meal suggestions based on your mood, energy, and daily goals.',
    ),
    _PageData(
      emoji: '📊',
      bgColor: Color(0xFFFFF8E1),
      iconColor: Color(0xFFF9A825),
      title: 'Track Your\nProgress',
      subtitle:
          'Monitor habits, mood patterns, and see how nutrition impacts your daily life.',
    ),
    _PageData(
      emoji: '🌱',
      bgColor: Color(0xFFF3E5F5),
      iconColor: Color(0xFF9C27B0),
      title: 'Build Healthy\nHabits',
      subtitle:
          'Create sustainable routines that support your mental and physical wellness every day.',
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  void _next() {
    if (!_isLast) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Page content
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _OnboardingPage(
              data: _pages[i],
              topPadding: top,
            ),
          ),

          // Skip button
          if (!_isLast)
            Positioned(
              top: top + 12,
              right: 20,
              child: GestureDetector(
                onTap: _finish,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            left: 24,
            right: 24,
            bottom: bottom + 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dot indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    final active = i == _page;
                    return GestureDetector(
                      onTap: () => _controller.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.primary
                              : AppTheme.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                // Next / Get Started
                GestureDetector(
                  onTap: _next,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLast ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
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

class _PageData {
  final String emoji;
  final Color bgColor;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _PageData({
    required this.emoji,
    required this.bgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _PageData data;
  final double topPadding;

  const _OnboardingPage({required this.data, required this.topPadding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(28, topPadding + 60, 28, 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration container
          Expanded(
            flex: 5,
            child: Center(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: data.bgColor,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: data.iconColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: data.iconColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          data.emoji,
                          style: const TextStyle(fontSize: 56),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Feature chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _featureChips(data.iconColor),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data.subtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _featureChips(Color color) {
    final Map<String, List<String>> chips = {
      '🥗': ['😊 Mood', '⚡ Energy'],
      '🤖': ['🤖 AI', '✨ Smart'],
      '📊': ['📈 Track', '🏆 Goals'],
      '🌱': ['🌿 Habits', '💪 Health'],
    };
    final list = chips[data.emoji] ?? [];
    return list
        .map(
          (c) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              c,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        )
        .toList();
  }
}
