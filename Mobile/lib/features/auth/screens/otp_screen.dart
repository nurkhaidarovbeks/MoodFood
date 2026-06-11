import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/mood_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/auth_text_field.dart';

enum _OtpStep { enterEmail, enterCode }

class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({super.key, this.email = ''});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  _OtpStep _step = _OtpStep.enterEmail;
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSending = false;
  bool _isVerifying = false;
  int _resendCooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.email.isNotEmpty) {
      _emailCtrl.text = widget.email;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _resendCooldown = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown <= 0) {
        t.cancel();
        if (mounted) setState(() {});
      } else {
        if (mounted) setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _sendOtp() async {
    if (_emailCtrl.text.isEmpty || !_emailCtrl.text.contains('@')) {
      _showError('Enter a valid email address');
      return;
    }
    setState(() => _isSending = true);
    try {
      await context.read<AuthProvider>().sendOtp(_emailCtrl.text.trim());
      if (!mounted) return;
      setState(() {
        _step = _OtpStep.enterCode;
        _isSending = false;
      });
      _startCooldown();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSending = false);
      _showError('Failed to send code. Is the backend running?');
    }
  }

  Future<void> _verifyOtp() async {
    if (_codeCtrl.text.length != 6) {
      _showError('Enter the 6-digit code');
      return;
    }
    setState(() => _isVerifying = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyOtp(
      email: _emailCtrl.text.trim(),
      code: _codeCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isVerifying = false);
    if (ok) {
      await context.read<MoodProvider>().loadEntries();
      if (!mounted) return;
      final user = auth.user;
      if (user != null && !user.isProfileComplete) {
        Navigator.pushReplacementNamed(context, '/profile-setup');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      _showError(auth.error ?? 'Invalid code');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in with OTP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (_step == _OtpStep.enterCode) {
              setState(() {
                _step = _OtpStep.enterEmail;
                _codeCtrl.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: _step == _OtpStep.enterEmail
                ? _buildEmailStep()
                : _buildCodeStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Enter your email 📧',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "We'll send a 6-digit code to your email. No password needed.",
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textMedium,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        AuthTextField(
          label: 'Email',
          hint: 'you@example.com',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined, size: 20),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _sendOtp(),
          autofocus: true,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isSending ? null : _sendOtp,
          child: _isSending
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Send Code'),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Check your email 📬',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit code to ${_emailCtrl.text}.\nIt expires in 5 minutes.',
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textMedium,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        TextFormField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: 16,
            color: AppTheme.primaryGreen,
          ),
          decoration: const InputDecoration(
            hintText: '000000',
            hintStyle: TextStyle(
              fontSize: 32,
              letterSpacing: 16,
              color: AppTheme.textLight,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 18),
          ),
          onChanged: (v) {
            if (v.length == 6) _verifyOtp();
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isVerifying ? null : _verifyOtp,
          child: _isVerifying
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Verify Code'),
        ),
        const SizedBox(height: 20),
        Center(
          child: _resendCooldown > 0
              ? Text(
                  'Resend code in $_resendCooldown s',
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 14,
                  ),
                )
              : TextButton(
                  onPressed: _sendOtp,
                  child: const Text("Didn't get the code? Resend"),
                ),
        ),
      ],
    );
  }
}
