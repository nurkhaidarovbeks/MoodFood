import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      title: 'Eat Smart,\nFeel Better',
      subtitle:
          'Track your mood, discover meals that match how you feel, and build healthy habits that last.',
      colors: [Color(0xFF1B4332), Color(0xFF052E16)],
    ),
    _PageData(
      emoji: '🤖',
      title: 'AI-Powered\nRecommendations',
      subtitle:
          'Get personalized meal suggestions based on your mood, energy levels, and goals.',
      colors: [Color(0xFF1E3A5F), Color(0xFF0A1628)],
    ),
    _PageData(
      emoji: '📊',
      title: 'Track Your\nProgress',
      subtitle:
          'Monitor your habits, mood patterns, and see how your nutrition impacts your daily life.',
      colors: [Color(0xFF164E63), Color(0xFF0C2A34)],
    ),
    _PageData(
      emoji: '🌱',
      title: 'Build Healthy\nHabits',
      subtitle:
          'Create sustainable routines that support your mental and physical wellness.',
      colors: [Color(0xFF14532D), Color(0xFF052E16)],
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
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
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _PageView(
              data: _pages[i],
              bottomPadding: bottom + 140,
              topPadding: top,
            ),
          ),

          // Skip button (hidden on last page)
          if (!isLast)
            Positioned(
              right: 24,
              top: top + 16,
              child: GestureDetector(
                onTap: _finish,
                child: Container(
                  width: 65,
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(
                    'Skip',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.90),
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.50,
                    ),
                  ),
                ),
              ),
            ),

          // Bottom controls: dots + button
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
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.40),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                // Next / Get Started button
                GestureDetector(
                  onTap: _next,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 6,
                          offset: Offset(0, 4),
                          spreadRadius: -4,
                        ),
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 15,
                          offset: Offset(0, 10),
                          spreadRadius: -3,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLast ? 'Get Started' : 'Next',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF101828),
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            height: 1.50,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          size: 20,
                          color: Color(0xFF101828),
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
  final String title;
  final String subtitle;
  final List<Color> colors;

  const _PageData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.colors,
  });
}

class _PageView extends StatelessWidget {
  final _PageData data;
  final double bottomPadding;
  final double topPadding;

  const _PageView({
    required this.data,
    required this.bottomPadding,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: data.colors,
        ),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.10),
              Colors.black.withValues(alpha: 0.40),
              Colors.black.withValues(alpha: 0.60),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder for skip button height
            const SizedBox(height: 40),

            // Push content to bottom third of screen
            const Spacer(),

            // Icon circle
            Container(
              width: 80,
              height: 80,
              decoration: ShapeDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.30),
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              child: Center(
                child: Text(
                  data.emoji,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            SizedBox(
              width: double.infinity,
              child: Text(
                data.title,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  height: 1.11,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Subtitle
            Text(
              data.subtitle,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.90),
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.63,
              ),
            ),

            // Bottom spacing for controls overlay
            SizedBox(height: bottomPadding),
          ],
        ),
      ),
    );
  }
}
