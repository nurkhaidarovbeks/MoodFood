import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _notifService = NotificationService();
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await _notifService.getPreferences();
    if (prefs != null && mounted) {
      setState(() {
        _notificationsEnabled =
            prefs.waterRemindersOn || prefs.mealRemindersOn;
      });
    }
  }

  // The single "Notifications" toggle controls both water and meal reminders.
  Future<void> _setNotifications(bool on) async {
    setState(() => _notificationsEnabled = on);
    await _notifService.updatePreferences(
      waterRemindersOn: on,
      mealRemindersOn: on,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 18,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 8),

                  // Account
                  _SectionHeader(label: 'Account'),
                  _SettingsCard(children: [
                    _SettingsTile(
                      icon: Icons.person_outline,
                      label: 'Profile Info',
                      onTap: () =>
                          Navigator.pushNamed(context, '/edit-profile'),
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.lock_outline,
                      label: 'Privacy & Security',
                      onTap: () => _showSecurityInfo(context),
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.language_outlined,
                      label: 'Language',
                      trailing: const Text(
                        'English',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      onTap: () => _showLanguagePicker(context),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Preferences
                  _SectionHeader(label: 'Preferences'),
                  _SettingsCard(children: [
                    _ToggleTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      value: _notificationsEnabled,
                      onChanged: _setNotifications,
                    ),
                    _Divider(),
                    _ToggleTile(
                      icon: Icons.dark_mode_outlined,
                      label: 'Dark Mode',
                      value: _darkModeEnabled,
                      onChanged: (v) =>
                          setState(() => _darkModeEnabled = v),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Health
                  _SectionHeader(label: 'Health'),
                  _SettingsCard(children: [
                    _SettingsTile(
                      icon: Icons.restaurant_outlined,
                      label: 'Dietary Preferences',
                      onTap: () =>
                          Navigator.pushNamed(context, '/profile-setup'),
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.warning_amber_outlined,
                      label: 'Allergies',
                      onTap: () =>
                          Navigator.pushNamed(context, '/profile-setup'),
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.track_changes_outlined,
                      label: 'Health Goals',
                      onTap: () =>
                          Navigator.pushNamed(context, '/profile-setup'),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Support
                  _SectionHeader(label: 'Support'),
                  _SettingsCard(children: [
                    _SettingsTile(
                      icon: Icons.mail_outline,
                      label: 'Contact Us',
                      onTap: () => _showContactUs(context),
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.help_outline,
                      label: 'Help & Support',
                      onTap: () => _showHelpSupport(context),
                    ),
                    if (context.watch<SubscriptionProvider>().isPremium) ...[
                      _Divider(),
                      _SettingsTile(
                        icon: Icons.cancel_outlined,
                        label: 'Cancel Subscription',
                        onTap: () => _confirmCancelSubscription(context),
                      ),
                    ],
                  ]),

                  const SizedBox(height: 16),

                  // Info
                  _SectionHeader(label: 'Info'),
                  _SettingsCard(children: [
                    _SettingsTile(
                      icon: Icons.info_outline,
                      label: 'About',
                      onTap: () => _showAbout(context),
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      onTap: () => _showPrivacyPolicy(context),
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.description_outlined,
                      label: 'Terms of Service',
                      onTap: () => _showTermsOfService(context),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Log Out
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _confirmLogout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEBEE),
                        foregroundColor: const Color(0xFFD32F2F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Log Out',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Version footer
                  const Center(
                    child: Text(
                      'MoodFood v1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              final navigator = Navigator.of(context);
              navigator.pop();
              await authProvider.logout();
              if (!mounted) return;
              navigator.pushNamedAndRemoveUntil('/welcome', (_) => false);
            },
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD32F2F)),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showSecurityInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: const Text(
          'Your data is encrypted and stored securely. '
          'To change your password, log out and use "Forgot Password" on the sign-in screen.\n\n'
          'We never share your personal data with third parties.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Language'),
        content: const Text(
          'MoodFood is currently available in English.\n\nMore languages coming soon!',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'MoodFood ("we") collects only the information needed to provide personalized nutrition recommendations.\n\n'
            '• Account data: email and name for authentication.\n'
            '• Health data: mood logs and dietary preferences, stored securely.\n'
            '• We do not sell your data to third parties.\n'
            '• You may delete your account and all data at any time.\n\n'
            'For questions, contact support@moodfood.app',
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using MoodFood you agree to the following:\n\n'
            '• MoodFood provides wellness suggestions, not medical advice.\n'
            '• Always consult a healthcare professional for medical decisions.\n'
            '• You are responsible for maintaining your account credentials.\n'
            '• We reserve the right to update these terms with notice.\n\n'
            'Last updated: June 2025',
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('About MoodFood'),
        content: const Text(
          'MoodFood helps you track your mood and discover personalized food recommendations for better mental and physical wellbeing.\n\nVersion 1.0.0',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showContactUs(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Contact Us'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('We\'d love to hear from you!'),
            SizedBox(height: 12),
            Row(children: [
              Icon(Icons.email_outlined, size: 18, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('support@moodfood.app'),
            ]),
            SizedBox(height: 8),
            Row(children: [
              Icon(Icons.phone_outlined, size: 18, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('+7 700 000 0000'),
            ]),
            SizedBox(height: 8),
            Row(children: [
              Icon(Icons.access_time, size: 18, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Mon–Fri, 9:00–18:00'),
            ]),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FaqItem(
                q: 'How do recommendations work?',
                a: 'We match meals to your mood, energy, and the ingredients you have at home.',
              ),
              _FaqItem(
                q: 'How do I track water?',
                a: 'Open the Water tab and tap + for each glass. Your goal and reminders are set there.',
              ),
              _FaqItem(
                q: 'How do I reset my password?',
                a: 'On the login screen tap "Forgot password?" and follow the emailed instructions.',
              ),
              _FaqItem(
                q: 'How do I cancel Premium?',
                a: 'Settings → Support → Cancel Subscription.',
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _confirmCancelSubscription(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Your Premium benefits stay active until the end of the current billing period. Cancel anyway?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: const Text('Keep Premium'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dctx);
              await context.read<SubscriptionProvider>().cancelPremium();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Subscription cancelled'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Cancel Subscription',
                style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            a,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppTheme.textDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.textDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
            activeTrackColor: AppTheme.primary.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 62,
      endIndent: 16,
      color: Color(0xFFF0F0F0),
    );
  }
}
