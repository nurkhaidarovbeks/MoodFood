import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/theme/app_theme.dart';

class PayPalWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String orderId;

  const PayPalWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.orderId,
  });

  @override
  State<PayPalWebViewScreen> createState() => _PayPalWebViewScreenState();
}

class _PayPalWebViewScreenState extends State<PayPalWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _handling = false;

  static const _successPattern = '/payment/paypal/success';
  static const _cancelPattern = '/payment/paypal/cancel';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (req) {
            final url = req.url;
            if (_handling) return NavigationDecision.prevent;

            if (url.contains(_successPattern)) {
              _handling = true;
              _onPayPalSuccess();
              return NavigationDecision.prevent;
            }
            if (url.contains(_cancelPattern)) {
              _handling = true;
              _onPayPalCancel();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            // Ignore resource errors (ads, trackers, etc.)
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  Future<void> _onPayPalSuccess() async {
    if (!mounted) return;

    setState(() => _loading = true);

    // Give backend 2s to capture the payment
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Sync subscription status from backend
    await context.read<SubscriptionProvider>().syncFromBackend();

    // If backend confirmed active subscription, show success screen
    final isPremium = context.read<SubscriptionProvider>().isPremium;

    if (!mounted) return;

    if (isPremium) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/payment-success',
        (route) => route.settings.name == '/home',
      );
    } else {
      // Backend didn't confirm yet — fallback: upgrade locally and show success
      await context.read<SubscriptionProvider>().upgradeToPremium();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/payment-success',
          (route) => route.settings.name == '/home',
        );
      }
    }
  }

  void _onPayPalCancel() {
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment cancelled'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.divider),
            ),
            child: const Icon(
              Icons.close,
              size: 18,
              color: AppTheme.textDark,
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF003087),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  'P',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'PayPal Checkout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _loading
              ? const LinearProgressIndicator(
                  color: Color(0xFF0070BA),
                  backgroundColor: Color(0xFFE3F2FD),
                  minHeight: 2,
                )
              : const SizedBox(height: 2),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
