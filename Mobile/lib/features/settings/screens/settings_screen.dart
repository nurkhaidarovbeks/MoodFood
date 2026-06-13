import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifMood = true;
  bool _notifRecipes = true;
  bool _notifTips = false;
  String _dietaryPref = 'No restrictions';
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const _SectionHeader('Notifications'),
          _ToggleTile(
            icon: Icons.mood_outlined,
            title: 'Mood reminders',
            subtitle: 'Daily check-in reminders',
            value: _notifMood,
            onChanged: (v) => setState(() => _notifMood = v),
          ),
          _ToggleTile(
            icon: Icons.restaurant_menu_outlined,
            title: 'Recipe suggestions',
            subtitle: 'New recipe recommendations',
            value: _notifRecipes,
            onChanged: (v) => setState(() => _notifRecipes = v),
          ),
          _ToggleTile(
            icon: Icons.lightbulb_outline,
            title: 'Health tips',
            subtitle: 'Weekly wellness tips',
            value: _notifTips,
            onChanged: (v) => setState(() => _notifTips = v),
          ),
          const SizedBox(height: 8),
          const _SectionHeader('Preferences'),
          _OptionTile(
            icon: Icons.restaurant_outlined,
            title: 'Dietary preference',
            value: _dietaryPref,
            options: const [
              'No restrictions',
              'Vegetarian',
              'Vegan',
              'Gluten-free',
              'Lactose-free',
              'Halal',
            ],
            onChanged: (v) => setState(() => _dietaryPref = v),
          ),
          _OptionTile(
            icon: Icons.language_outlined,
            title: 'Language',
            value: _language,
            options: const ['English', 'Русский', 'Қазақша'],
            onChanged: (v) => setState(() => _language = v),
          ),
          const SizedBox(height: 8),
          const _SectionHeader('Account'),
          _NavTile(
            icon: Icons.workspace_premium_outlined,
            title: 'MoodFood Premium',
            subtitle: 'Unlock all features',
            iconColor: const Color(0xFFFFB300),
            onTap: () => Navigator.pushNamed(context, '/premium'),
          ),
          _NavTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _NavTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {},
          ),
          _NavTile(
            icon: Icons.info_outline,
            title: 'About MoodFood',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          const _SectionHeader('Danger zone'),
          _NavTile(
            icon: Icons.logout,
            title: 'Sign Out',
            iconColor: AppTheme.errorColor,
            titleColor: AppTheme.errorColor,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sign out?'),
                  content:
                      const Text('You will need to log in again to access your account.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/welcome');
                }
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textLight,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.primary,
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMedium),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppTheme.textLight, size: 20),
          ],
        ),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          builder: (_) => ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: options
                .map(
                  (opt) => ListTile(
                    title: Text(opt),
                    trailing: opt == value
                        ? const Icon(Icons.check, color: AppTheme.primary)
                        : null,
                    onTap: () {
                      onChanged(opt);
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? titleColor;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppTheme.primary, size: 22),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: titleColor ?? AppTheme.textDark,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight, size: 20),
        onTap: onTap,
      ),
    );
  }
}
