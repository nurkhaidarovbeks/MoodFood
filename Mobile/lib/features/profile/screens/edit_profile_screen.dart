import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _avatarKey = 'avatar_path';
  static const _nameKey = 'display_name_override';

  late TextEditingController _nameCtrl;
  String? _avatarPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? user?.email ?? '');
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_avatarKey);
    if (path != null && File(path).existsSync()) {
      setState(() => _avatarPath = path);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarKey, picked.path);
    setState(() => _avatarPath = picked.path);
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Change Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 16),
              _SheetOption(
                icon: Icons.camera_alt_outlined,
                label: 'Take Photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              _SheetOption(
                icon: Icons.photo_library_outlined,
                label: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_avatarPath != null) ...[
                const SizedBox(height: 8),
                _SheetOption(
                  icon: Icons.delete_outline,
                  label: 'Remove Photo',
                  color: const Color(0xFFD32F2F),
                  onTap: () async {
                    Navigator.pop(context);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove(_avatarKey);
                    setState(() => _avatarPath = null);
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    // Save display name override locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    // Notify auth provider to reflect updated name
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      auth.setUser(auth.user!.copyWith(name: name));
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated!'),
        backgroundColor: Color(0xFF7CB342),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final initials = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Avatar
                    GestureDetector(
                      onTap: _showImageSourceSheet,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                            backgroundImage: _avatarPath != null
                                ? FileImage(File(_avatarPath!))
                                : null,
                            child: _avatarPath == null
                                ? Text(
                                    initials,
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Tap to change photo',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Name field
                    _Field(
                      label: 'Display Name',
                      controller: _nameCtrl,
                      icon: Icons.person_outline,
                      hint: 'Your name',
                    ),

                    const SizedBox(height: 16),

                    // Email (read-only)
                    _Field(
                      label: 'Email',
                      controller: TextEditingController(
                        text: context.read<AuthProvider>().user?.email ?? '',
                      ),
                      icon: Icons.email_outlined,
                      hint: 'Email',
                      readOnly: true,
                    ),

                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Edit health profile
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/profile-setup',
                          arguments: true,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.restaurant_outlined, size: 18),
                        label: const Text(
                          'Edit Health & Diet Preferences',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool readOnly;

  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    required this.hint,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textDark,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: AppTheme.textSecondary),
              hintText: hint,
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              filled: readOnly,
              fillColor: readOnly
                  ? const Color(0xFFF5F5F5)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textDark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
