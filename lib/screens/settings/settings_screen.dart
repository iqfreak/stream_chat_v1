import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/app_state.dart';
import '../../services/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav_scaffold.dart';
import '../../widgets/user_avatar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotificationsEnabled = true;
  bool _mentionsEnabled = true;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && mounted) {
      // Persist to the data service so every widget sees the update
      context.read<MockDataService>().updateUserAvatar(pickedFile.path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr('image_updated', context.read<AppState>().locale),
          ),
        ),
      );
    }
  }

  String _tr(String key, String lang) {
    const dict = {
      'en': {
        'settings_title': 'Settings & Profile',
        'edit_profile': 'Edit Profile',
        'appearance': 'Appearance',
        'dark_mode': 'Dark Mode',
        'enabled': 'Enabled',
        'disabled': 'Disabled',
        'language': 'Language',
        'notifications': 'Notifications',
        'push_notif': 'Push Notifications',
        'all_msgs': 'All messages',
        'mentions': 'Mentions',
        'notify_mentions': 'Notify me on @mention',
        'account': 'Account',
        'security': 'Account & Security',
        'security_sub': 'Password, 2FA',
        'privacy': 'Privacy',
        'privacy_sub': 'Manage your data',
        'help': 'Help & Support',
        'about': 'About',
        'sign_out': 'Sign Out',
        'image_updated': 'Profile picture updated!',
      },
      'ar': {
        'settings_title': 'الإعدادات والملف الشخصي',
        'edit_profile': 'تعديل الحساب',
        'appearance': 'المظهر',
        'dark_mode': 'الوضع الداكن',
        'enabled': 'مفعل',
        'disabled': 'معطل',
        'language': 'اللغة',
        'notifications': 'الإشعارات',
        'push_notif': 'إشعارات التطبيق',
        'all_msgs': 'كل الرسائل',
        'mentions': 'الإشارات (Mentions)',
        'notify_mentions': 'نبهني عند الإشارة لي',
        'account': 'الحساب',
        'security': 'الحساب والأمان',
        'security_sub': 'كلمة المرور، التحقق بخطوتين',
        'privacy': 'الخصوصية',
        'privacy_sub': 'إدارة بياناتك',
        'help': 'المساعدة والدعم',
        'about': 'عن التطبيق',
        'sign_out': 'تسجيل الخروج',
        'image_updated': 'تم تحديث صورة الملف الشخصي!',
      },
    };
    return dict[lang]?[key] ?? dict['en']![key]!;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final data = context.watch<MockDataService>();
    final user = data.currentUser;
    final isDark = appState.isDark;
    final lang = appState.locale;
    // Determine whether the avatar is a local file or a network URL
    final isLocalAvatar =
        user.avatarUrl.isNotEmpty && user.avatarUrl.startsWith('/');

    return Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: BottomNavScaffold(
        selectedIndex: 3,
        child: Scaffold(
          appBar: AppBar(title: Text(_tr('settings_title', lang))),
          body: ListView(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                color: isDark ? AppColors.darkCard : const Color(0xFFF5F6FA),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          isLocalAvatar
                              ? CircleAvatar(
                                  radius: 44,
                                  backgroundImage:
                                      FileImage(File(user.avatarUrl)),
                                )
                              : UserAvatar(
                                  name: user.name,
                                  avatarUrl: user.avatarUrl,
                                  size: 88,
                                  showOnline: true,
                                ),
                          Positioned(
                            bottom: 0,
                            right: lang == 'ar' ? null : 0,
                            left: lang == 'ar' ? 0 : null,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text(_tr('edit_profile', lang)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        context.push('/edit-profile');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              _SectionHeader(label: _tr('appearance', lang)),
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                iconColor: const Color(0xFF7B61FF),
                label: _tr('dark_mode', lang),
                subtitle:
                    isDark ? _tr('enabled', lang) : _tr('disabled', lang),
                trailing: Switch(
                  value: isDark,
                  onChanged: (_) => appState.toggleTheme(),
                  activeThumbColor: AppColors.primary,
                ),
              ),
              _SettingsTile(
                icon: Icons.language,
                iconColor: const Color(0xFF00C3FF),
                label: _tr('language', lang),
                subtitle: lang == 'ar' ? 'العربية' : 'English',
                onTap: () => _showLanguagePicker(context, appState),
              ),

              const SizedBox(height: 8),

              _SectionHeader(label: _tr('notifications', lang)),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                iconColor: const Color(0xFFFF9500),
                label: _tr('push_notif', lang),
                subtitle: _tr('all_msgs', lang),
                trailing: Switch(
                  value: _pushNotificationsEnabled,
                  onChanged: (v) =>
                      setState(() => _pushNotificationsEnabled = v),
                  activeThumbColor: AppColors.primary,
                ),
              ),
              _SettingsTile(
                icon: Icons.alternate_email,
                iconColor: AppColors.primary,
                label: _tr('mentions', lang),
                subtitle: _tr('notify_mentions', lang),
                trailing: Switch(
                  value: _mentionsEnabled,
                  onChanged: (v) => setState(() => _mentionsEnabled = v),
                  activeThumbColor: AppColors.primary,
                ),
              ),

              const SizedBox(height: 8),

              _SectionHeader(label: _tr('account', lang)),
              _SettingsTile(
                icon: Icons.security,
                iconColor: const Color(0xFF34C759),
                label: _tr('security', lang),
                subtitle: _tr('security_sub', lang),
                onTap: () => context.push('/security'),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: const Color(0xFF72767E),
                label: _tr('privacy', lang),
                subtitle: _tr('privacy_sub', lang),
                onTap: () => context.push('/privacy'),
              ),
              _SettingsTile(
                icon: Icons.help_outline,
                iconColor: const Color(0xFF00C3FF),
                label: _tr('help', lang),
                onTap: () => context.push('/help'),
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                iconColor: const Color(0xFF72767E),
                label: _tr('about', lang),
                subtitle: 'Version 1.0.0',
                onTap: () => context.push('/about'),
              ),

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: Text(_tr('sign_out', lang)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _confirmSignOut(context, lang),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('English'),
            trailing: appState.locale == 'en'
                ? const Icon(Icons.check, color: AppColors.primary)
                : null,
            onTap: () {
              appState.setLocale('en');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('العربية'),
            trailing: appState.locale == 'ar'
                ? const Icon(Icons.check, color: AppColors.primary)
                : null,
            onTap: () {
              appState.setLocale('ar');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('sign_out', lang)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppState>().signOut();
              context.read<MockDataService>().logout();
              context.go('/login');
            },
            child: Text(_tr('sign_out', lang)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark
              ? AppColors.textDarkSecondary
              : AppColors.textLightSecondary,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title:
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 12))
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, size: 20)
              : null),
      onTap: onTap,
    );
  }
}
