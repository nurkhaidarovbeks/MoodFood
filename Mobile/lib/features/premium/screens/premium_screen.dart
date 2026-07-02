import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../payment/screens/paypal_webview_screen.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _showPaymentSheet = false;
  String _selectedPlan = 'monthly'; // 'monthly' | 'annual'

  // Prices mirror the backend subscription_plans seed (USD).
  static const _monthlyPrice = r'$9.99';
  static const _annualPrice = r'$79.99';

  static const _features = [
    (Icons.auto_awesome, 'Advanced AI Insights',
        'Get deep food-mood analysis and personalized insights powered by AI'),
    (Icons.menu_book_outlined, 'Unlimited Recipes',
        'Access our full library of 1000+ mood-optimized recipes'),
    (Icons.bar_chart_outlined, 'Advanced Analytics',
        'Track your mood and nutrition trends with detailed charts'),
    (Icons.support_agent, 'Priority Support',
        'Get instant help from our nutrition and wellness experts'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFFFE0B2)),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Hero section
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8F00),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8F00)
                                    .withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.workspace_premium,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Go Premium',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Unlock the full power of MoodFood\nand transform your wellbeing',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8D6E63),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Feature list
                  ...(_features.map((f) => _FeatureTile(
                        icon: f.$1,
                        title: f.$2,
                        subtitle: f.$3,
                      ))),

                  const SizedBox(height: 28),

                  // Plan cards
                  _PlanCard(
                    title: 'Free',
                    price: r'$0',
                    period: 'forever',
                    features: const [
                      '5 recipes per day',
                      'Basic mood tracking',
                      'Standard AI chat',
                      'Basic analytics',
                    ],
                    isRecommended: false,
                    buttonLabel: 'Current Plan',
                    buttonEnabled: false,
                    onPressed: () {},
                  ),

                  const SizedBox(height: 14),

                  // Monthly / Annual selector
                  _PlanToggle(
                    selected: _selectedPlan,
                    onSelect: (p) => setState(() => _selectedPlan = p),
                  ),

                  const SizedBox(height: 14),

                  _PlanCard(
                    title: 'Premium',
                    price: _selectedPlan == 'annual'
                        ? _annualPrice
                        : _monthlyPrice,
                    period: _selectedPlan == 'annual' ? '/year' : '/month',
                    subLabel: _selectedPlan == 'annual'
                        ? 'Just \$6.67/mo · billed annually'
                        : null,
                    features: const [
                      'Unlimited recipes',
                      'Advanced mood tracking',
                      'Priority AI chat',
                      'Advanced analytics',
                    ],
                    isRecommended: true,
                    buttonLabel: 'Upgrade Now',
                    buttonEnabled: true,
                    onPressed: () => setState(() => _showPaymentSheet = true),
                  ),

                  const SizedBox(height: 20),

                  // Footer
                  const Center(
                    child: Text(
                      'Cancel anytime • Secure payment\nNo hidden fees',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFBCAAA4),
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Payment sheet overlay
            if (_showPaymentSheet) ...[
              GestureDetector(
                onTap: () => setState(() => _showPaymentSheet = false),
                child: Container(color: Colors.black.withValues(alpha: 0.4)),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _PaymentSheet(
                  planType: _selectedPlan,
                  priceLabel: _selectedPlan == 'annual'
                      ? '$_annualPrice / year'
                      : '$_monthlyPrice / month',
                  onClose: () =>
                      setState(() => _showPaymentSheet = false),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: const Color(0xFFFF8F00)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3E2723),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8D6E63),
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

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String? subLabel;
  final List<String> features;
  final bool isRecommended;
  final String buttonLabel;
  final bool buttonEnabled;
  final VoidCallback onPressed;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    this.subLabel,
    required this.features,
    required this.isRecommended,
    required this.buttonLabel,
    required this.buttonEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isRecommended
            ? Border.all(color: const Color(0xFFFF8F00), width: 2)
            : Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: isRecommended
                ? const Color(0xFFFF8F00).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: isRecommended
                  ? const Color(0xFFFF8F00).withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isRecommended
                              ? const Color(0xFFE65100)
                              : const Color(0xFF3E2723),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            price,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: isRecommended
                                  ? const Color(0xFFE65100)
                                  : const Color(0xFF3E2723),
                            ),
                          ),
                          Text(
                            period,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8D6E63),
                            ),
                          ),
                        ],
                      ),
                      if (subLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subLabel!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8F00),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Recommended',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Features
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: isRecommended
                          ? const Color(0xFFFF8F00)
                          : AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      f,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),

          // Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: buttonEnabled ? onPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRecommended
                      ? const Color(0xFFFF8F00)
                      : const Color(0xFFEEEEEE),
                  disabledBackgroundColor: const Color(0xFFEEEEEE),
                  foregroundColor: isRecommended
                      ? Colors.white
                      : AppTheme.textSecondary,
                  disabledForegroundColor: AppTheme.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanToggle extends StatelessWidget {
  final String selected; // 'monthly' | 'annual'
  final void Function(String) onSelect;

  const _PlanToggle({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _segment('monthly', 'Monthly', null),
          _segment('annual', 'Annual', 'Save 30%'),
        ],
      ),
    );
  }

  Widget _segment(String value, String label, String? badge) {
    final active = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? const Color(0xFFE65100)
                      : const Color(0xFF8D6E63),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8F00),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentSheet extends StatefulWidget {
  final VoidCallback onClose;
  final String planType; // 'monthly' | 'annual'
  final String priceLabel;
  const _PaymentSheet({
    required this.onClose,
    required this.planType,
    required this.priceLabel,
  });

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  int _selectedMethod = 0;
  bool _processing = false;
  String? _error;

  final _subService = SubscriptionService();

  static const _methods = [
    ('paypal', '🅿️', 'PayPal'),
    ('forte', '🏦', 'Forte Bank'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const Text(
            'Choose Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3E2723),
            ),
          ),

          const SizedBox(height: 20),

          ..._methods.asMap().entries.map((e) {
            final idx = e.key;
            final (_, emoji, name) = e.value;
            final isSelected = _selectedMethod == idx;
            return GestureDetector(
              onTap: () => setState(() => _selectedMethod = idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF8F00).withValues(alpha: 0.06)
                      : const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF8F00)
                        : const Color(0xFFEEEEEE),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFFE65100)
                            : const Color(0xFF3E2723),
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFFFF8F00),
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFD32F2F),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _processing ? null : () => _pay(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8F00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _processing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Pay ${widget.priceLabel}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: widget.onClose,
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8D6E63),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pay(BuildContext context) async {
    final method = _methods[_selectedMethod].$1;

    // Forte Bank is not yet available
    if (method == 'forte') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Forte Bank coming soon. Please use PayPal.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() { _processing = true; _error = null; });

    try {
      final result = await _subService.subscribe(
        planType: widget.planType,
        gateway: 'paypal',
      );

      final paymentUrl = result['paymentUrl'] as String?;
      final orderId = result['orderId'] as String?;

      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw ApiException('No payment URL received from server');
      }

      if (!mounted) return;
      setState(() => _processing = false);
      widget.onClose();

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PayPalWebViewScreen(
            paymentUrl: paymentUrl,
            orderId: orderId ?? '',
          ),
          fullscreenDialog: true,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _processing = false; _error = e.message; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _processing = false; _error = 'Something went wrong. Please try again.'; });
    }
  }
}
