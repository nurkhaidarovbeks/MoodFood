import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class AuthHeader extends StatelessWidget {
  final String subtitle;
  const AuthHeader({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text('🥗', style: TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MoodFood',
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.33,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.43,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AuthTabToggle extends StatelessWidget {
  final String activeTab;
  const AuthTabToggle({super.key, required this.activeTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.tabInactive,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _TabItem(
            label: 'Login',
            active: activeTab == 'login',
            onTap: () {
              if (activeTab != 'login') {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
          _TabItem(
            label: 'Sign Up',
            active: activeTab == 'register',
            onTap: () {
              if (activeTab != 'register') {
                Navigator.pushReplacementNamed(context, '/register');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabItem({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: active
              ? BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : null,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppTheme.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  final String text;
  const AuthFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final error = context.select<AuthProvider, String?>((a) => a.error);
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          error,
          style: TextStyle(color: Colors.red.shade700, fontSize: 13),
        ),
      ),
    );
  }
}

class AuthSubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const AuthSubmitButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final loading = context.select<AuthProvider, bool>((a) => a.isLoading);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.black.withValues(alpha: 0.08))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ),
        Expanded(child: Divider(color: Colors.black.withValues(alpha: 0.08))),
      ],
    );
  }
}

class AuthSocialButtons extends StatelessWidget {
  const AuthSocialButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _GoogleSignInBtn()),
        SizedBox(width: 12),
        Expanded(child: _SocialBtn(label: 'Apple', icon: Icons.apple)),
      ],
    );
  }
}

class _GoogleSignInBtn extends StatefulWidget {
  const _GoogleSignInBtn();

  @override
  State<_GoogleSignInBtn> createState() => _GoogleSignInBtnState();
}

class _GoogleSignInBtnState extends State<_GoogleSignInBtn> {
  bool _loading = false;

  static final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '189389207039-8bht9m53kvpqi00hqjfm5k1ov2vujt3h.apps.googleusercontent.com',
  );

  Future<void> _handleSignIn() async {
    setState(() => _loading = true);
    try {
      final account = await _googleSignIn.signIn();
      if (account == null || !mounted) {
        setState(() => _loading = false);
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Sign In failed: no token received')),
          );
        }
        setState(() => _loading = false);
        return;
      }
      if (!mounted) return;
      await context.read<AuthProvider>().googleSignIn(idToken);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign In error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _handleSignIn,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 0.8),
        ),
        child: _loading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.g_mobiledata, size: 22, color: AppTheme.textDark),
                  SizedBox(width: 8),
                  Text(
                    'Google',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SocialBtn({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label sign-in coming soon')),
      ),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: AppTheme.textDark),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
