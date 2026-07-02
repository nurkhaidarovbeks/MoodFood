import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

/// Dedicated water tracking screen.
///
/// Shares the same SharedPreferences key (`water_glasses`, stored as
/// `YYYY-MM-DD:count`) as the Home water card, so both stay in sync.
class WaterTrackerScreen extends StatefulWidget {
  const WaterTrackerScreen({super.key});

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen> {
  static const _waterKey = 'water_glasses';
  static const _goal = 8;
  static const _mlPerGlass = 250;
  static const _blue = Color(0xFF2196F3);
  static const _blueDark = Color(0xFF1565C0);

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
    final pct = (_glasses / _goal).clamp(0.0, 1.0);
    final reached = _glasses >= _goal;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            // Header
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back,
                        size: 20, color: AppTheme.textDark),
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Water Tracker',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Progress ring
            Center(
              child: SizedBox(
                width: 210,
                height: 210,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 210,
                      height: 210,
                      child: CustomPaint(
                        painter: _RingPainter(progress: pct),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.water_drop_rounded,
                            color: _blue, size: 34),
                        const SizedBox(height: 6),
                        Text(
                          '$_glasses',
                          style: const TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                            height: 1,
                          ),
                        ),
                        Text(
                          'of $_goal glasses',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_glasses * _mlPerGlass} / ${_goal * _mlPerGlass} ml',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _blueDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Motivational line
            Center(
              child: Text(
                reached
                    ? '🎉 Goal reached! Great hydration today.'
                    : 'Keep going — ${_goal - _glasses} more to hit your goal.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: reached ? AppTheme.primaryDark : AppTheme.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Glass row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's glasses",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(_goal, (i) {
                      final filled = i < _glasses;
                      return GestureDetector(
                        onTap: () => _set(i + 1),
                        child: Icon(
                          filled
                              ? Icons.local_drink
                              : Icons.local_drink_outlined,
                          size: 34,
                          color: filled ? _blue : const Color(0xFFBBDEFB),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Add / remove controls
            Row(
              children: [
                _CircleBtn(
                  icon: Icons.remove,
                  onTap: _glasses > 0 ? () => _set(_glasses - 1) : null,
                  filled: false,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _set(_glasses + 1),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_blue, _blueDark],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _blue.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Add a glass',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                _CircleBtn(
                  icon: Icons.add,
                  onTap: () => _set(_glasses + 1),
                  filled: false,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Goal info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: _blueDark),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Daily goal: $_goal glasses (${_goal * _mlPerGlass} ml ≈ 2 L). '
                      'Staying hydrated boosts energy, focus and mood.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: _blueDark,
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

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  const _CircleBtn({required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? const Color(0xFF90CAF9) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? const Color(0xFF1565C0) : const Color(0xFFBDBDBD),
          size: 22,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const stroke = 16.0;

    final bg = Paint()
      ..color = const Color(0xFFE3F2FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF64B5F6), Color(0xFF1565C0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
