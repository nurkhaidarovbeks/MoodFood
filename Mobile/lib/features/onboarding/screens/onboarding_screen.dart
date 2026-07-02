import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _controller = PageController();
  int _page = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  static const _pages = [
    _PageData(
      imageUrl:
          'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&auto=format&fit=crop&q=80',
      icon: Icons.psychology_outlined,
      title: 'Food Affects\nYour Mood',
      subtitle:
          'Discover how the right nutrients can boost your energy, focus, and emotional well-being.',
    ),
    _PageData(
      imageUrl:
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&auto=format&fit=crop&q=80',
      icon: Icons.auto_awesome_outlined,
      title: 'AI-Powered\nRecommendations',
      subtitle:
          'Get personalized meal suggestions based on your mood, energy levels, and goals.',
    ),
    _PageData(
      imageUrl:
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&auto=format&fit=crop&q=80',
      icon: Icons.trending_up_rounded,
      title: 'Track Your\nProgress',
      subtitle:
          'Monitor your habits, mood patterns, and see how your nutrition impacts your daily life.',
    ),
    _PageData(
      imageUrl:
          'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800&auto=format&fit=crop&q=80',
      icon: Icons.favorite_outline_rounded,
      title: 'Build Healthy\nHabits',
      subtitle:
          'Create sustainable routines that support your mental and physical wellness.',
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _controller.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  void _next() {
    if (!_isLast) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
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

  void _onPageChanged(int i) {
    setState(() => _page = i);
    _fadeController.reset();
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Full-screen paged photos
          PageView.builder(
            controller: _controller,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (_, i) => _PhotoPage(data: _pages[i]),
          ),

          // Skip button — top right
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: AnimatedOpacity(
              opacity: _isLast ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: _isLast ? null : _finish,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom content
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _BottomContent(
                data: _pages[_page],
                page: _page,
                total: _pages.length,
                isLast: _isLast,
                onNext: _next,
                onDotTap: (i) => _controller.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Full-screen photo page ───────────────────────────────────────────────────

class _PhotoPage extends StatelessWidget {
  final _PageData data;
  const _PhotoPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          data.imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(color: const Color(0xFF1A1A1A));
          },
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFF1A1A1A)),
        ),
        // Gradient overlay: transparent top → dark bottom
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.45, 1.0],
              colors: [
                Colors.transparent,
                Color(0x66000000),
                Color(0xDD000000),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Bottom content overlay ───────────────────────────────────────────────────

class _BottomContent extends StatelessWidget {
  final _PageData data;
  final int page;
  final int total;
  final bool isLast;
  final VoidCallback onNext;
  final void Function(int) onDotTap;

  const _BottomContent({
    required this.data,
    required this.page,
    required this.total,
    required this.isLast,
    required this.onNext,
    required this.onDotTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(28, 0, 28, bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(
              data.icon,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 12),

          // Subtitle
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 28),

          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final active = i == page;
              return GestureDetector(
                onTap: () => onDotTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 24 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 24),

          // Next / Get Started button
          GestureDetector(
            onTap: onNext,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLast ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF1A1A1A),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _PageData {
  final String imageUrl;
  final IconData icon;
  final String title;
  final String subtitle;

  const _PageData({
    required this.imageUrl,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
