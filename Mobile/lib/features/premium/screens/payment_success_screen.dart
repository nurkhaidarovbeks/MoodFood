import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/subscription_provider.dart';

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({super.key});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;

  late Animation<double> _circleScale;
  late Animation<double> _checkScale;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _circleScale = CurvedAnimation(
      parent: _scaleCtrl,
      curve: Curves.elasticOut,
    );
    _checkScale = CurvedAnimation(
      parent: _scaleCtrl,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    );
    _contentFade = CurvedAnimation(
      parent: _fadeCtrl,
      curve: Curves.easeOut,
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    // Staggered animation sequence
    _scaleCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeCtrl.forward();
        _slideCtrl.forward();
        HapticFeedback.lightImpact();
        // Mark user as premium
        context.read<SubscriptionProvider>().upgradeToPremium();
      }
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FBF0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Animated check circle
              ScaleTransition(
                scale: _circleScale,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow ring
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                      ),
                    ),
                    // Inner green circle
                    Container(
                      width: 104,
                      height: 104,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4CAF50),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x334CAF50),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                    // Check icon
                    ScaleTransition(
                      scale: _checkScale,
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Animated content
              FadeTransition(
                opacity: _contentFade,
                child: SlideTransition(
                  position: _contentSlide,
                  child: Column(
                    children: [
                      const Text(
                        'Payment\nSuccessful!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Welcome to MoodFood Premium!\nYour subscription is now active.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black.withValues(alpha: 0.5),
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Plan details card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _PlanRow(
                              icon: Icons.workspace_premium,
                              iconColor: const Color(0xFFFF8F00),
                              label: 'MoodFood Premium',
                              value: r'$9.99/month',
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                            ),
                            _PlanRow(
                              icon: Icons.calendar_today_outlined,
                              iconColor: const Color(0xFF7CB342),
                              label: 'Next billing date',
                              value: _nextBillingDate(),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                            ),
                            _PlanRow(
                              icon: Icons.check_circle_outline,
                              iconColor: const Color(0xFF7CB342),
                              label: 'Status',
                              value: 'Active',
                              valueColor: const Color(0xFF4CAF50),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // What's unlocked
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "You've unlocked:",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...[
                              ('🤖', 'Advanced AI Insights'),
                              ('📚', 'Unlimited Recipes'),
                              ('📊', 'Advanced Analytics'),
                              ('⚡', 'Priority Support'),
                            ].map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Text(item.$1,
                                        style: const TextStyle(fontSize: 14)),
                                    const SizedBox(width: 8),
                                    Text(
                                      item.$2,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.w500,
                                      ),
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
                ),
              ),

              const Spacer(flex: 3),

              // CTA button
              FadeTransition(
                opacity: _contentFade,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (_) => false,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Start Exploring Premium',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (_) => false,
                      ),
                      child: Text(
                        'Back to Home',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  static String _nextBillingDate() {
    final next = DateTime.now().add(const Duration(days: 30));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[next.month - 1]} ${next.day}, ${next.year}';
  }
}

class _PlanRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  const _PlanRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF717182),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}
