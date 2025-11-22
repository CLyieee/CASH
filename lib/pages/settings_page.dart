import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/app_controller.dart';
import '../controllers/theme_controller.dart';
import '../services/biometric_auth_service.dart';
import '../utils/app_text.dart';
import 'login_selection_page.dart';
import 'fee_settings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const String _biometricPrefKey = 'biometric_enabled';
  final BiometricAuthService _biometricService = BiometricAuthService();
  final AppController controller = Get.find<AppController>();
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _isLoading = true;

  final List<_QuickAction> _quickActions = const [
    _QuickAction(
      icon: Icons.person_outline,
      label: 'Profile details',
      description: 'Name, number, PIN',
      color: Color(0xFF6AC1FF),
    ),
    _QuickAction(
      icon: Icons.shield_outlined,
      label: 'Security tips',
      description: 'Best practices',
      color: Color(0xFFFFA26B),
    ),
    _QuickAction(
      icon: Icons.receipt_long_outlined,
      label: 'Transfer fees',
      description: 'Review fee tiers',
      color: Color(0xFF8B7CFF),
    ),
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), _checkBiometricStatus);
  }

  Future<void> _checkBiometricStatus() async {
    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool(_biometricPrefKey) ?? false;

      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable;
          _isBiometricEnabled = isEnabled;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking biometric status: $e');
      if (mounted) {
        setState(() {
          _isBiometricAvailable = false;
          _isBiometricEnabled = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    try {
      if (value) {
        final authenticated = await _biometricService.authenticate(
          localizedReason: 'Authenticate to enable biometric login',
        );

        if (authenticated) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_biometricPrefKey, true);
          if (mounted) {
            setState(() => _isBiometricEnabled = true);
          }
          _showSnackbar('Success', 'Biometric authentication enabled!');
        } else {
          _showSnackbar(
            'Failed',
            'Biometric authentication was not successful',
          );
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_biometricPrefKey, false);
        if (mounted) {
          setState(() => _isBiometricEnabled = false);
        }
        _showSnackbar('Success', 'Biometric authentication disabled');
      }
    } catch (e) {
      debugPrint('Error toggling biometric: $e');
      _showSnackbar('Error', 'Failed to update biometric settings');
    }
  }

  Future<void> _logout() async {
    final theme = Theme.of(context);
    Get.dialog(
      AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Logout',
          style: AppText.poppins(
            color: theme.colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppText.poppins(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: AppText.poppins(
                color: theme.colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final shouldKeepBiometric =
                  prefs.getBool(_biometricPrefKey) ?? false;
              await prefs.clear();
              if (shouldKeepBiometric) {
                await prefs.setBool(_biometricPrefKey, true);
              }
              Get.offAll(() => const LoginSelectionPage());
            },
            child: Text(
              'Logout',
              style: AppText.poppins(
                color: theme.colorScheme.error,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _SettingsPalette(theme);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        floating: true,
                        pinned: false,
                        snap: false,
                        title: Text(
                          'Settings',
                          style: AppText.poppins(
                            color: palette.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        leading: IconButton(
                          onPressed: () => Get.back(),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: palette.navIconBackground,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: palette.navIconColor,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildProfileCard(palette),
                            const SizedBox(height: 20),
                            _buildQuickActions(palette),
                            const SizedBox(height: 24),
                            _buildSecurityCard(palette),
                            const SizedBox(height: 24),
                            _buildSupportCard(palette),
                            const SizedBox(height: 24),
                            _buildDangerZone(palette),
                            const SizedBox(height: 32),
                            _buildFooter(palette),
                          ]),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildProfileCard(_SettingsPalette palette) {
    return Obx(() {
      final name = controller.userName.value.isEmpty
          ? 'Hi there'
          : controller.userName.value;
      final phone = controller.phoneNumber.value.isEmpty
          ? 'Add your mobile number'
          : controller.phoneNumber.value;

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: AppText.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    phone,
                    style: AppText.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Flexible(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.18),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _showComingSoon('Profile editing'),
                child: Text(
                  'Edit',
                  style: AppText.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQuickActions(_SettingsPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick actions',
          style: AppText.poppins(
            color: palette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _quickActions
              .map(
                (action) => _QuickActionCard(
                  action: action,
                  palette: palette,
                  onTap: () => _showComingSoon(action.label),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

                  // Preferences Section
                  Text(
                    'Preferences',
                    style: AppText.poppins(
                      color: const Color(0xFF2C3E50),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Fee Settings Button
                  GestureDetector(
                    onTap: () => Get.to(() => const FeeSettingsPage()),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E5EC),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.8),
                            offset: const Offset(-6, -6),
                            blurRadius: 12,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(6, 6),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF64B5F6),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF64B5F6).withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.attach_money,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fee Settings',
                                  style: AppText.poppins(
                                    color: const Color(0xFF2C3E50),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Configure transaction fee ranges',
                                  style: AppText.poppins(
                                    color: const Color(0xFF64B5F6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF2C3E50),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Account Section
                  Text(
                    'Account',
                    style: AppText.poppins(
                      color: const Color(0xFF2C3E50),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,

                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isBiometricAvailable
                          ? 'Use your fingerprint or face to sign in faster'
                          : 'Biometric hardware not detected on this device',
                      style: AppText.poppins(
                        color: palette.textMuted,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isBiometricEnabled,
                onChanged: _isBiometricAvailable ? _toggleBiometric : null,
                activeColor: const Color(0xFF4ADE80),
              ),
            ],
          ),
          Divider(color: palette.dividerColor, height: 32),
          // Theme toggle
          Obx(() {
            final isDark = themeController.themeMode.value == ThemeMode.dark;
            return Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.textMuted.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: palette.textPrimary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme',
                        style: AppText.poppins(
                          color: palette.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDark
                            ? 'Dark mode is easier on the eyes'
                            : 'Light mode for better visibility',
                        style: AppText.poppins(
                          color: palette.textMuted,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: isDark,
                  onChanged: (value) => themeController.toggleTheme(),
                  activeColor: const Color(0xFF5BA3E8),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSupportCard(_SettingsPalette palette) {
    return _SettingsCard(
      title: 'Need help?',
      subtitle: 'We are online 24/7 for urgent transfers',
      palette: palette,
      child: Column(
        children: [
          _SupportTile(
            icon: Icons.chat_bubble_outline,
            title: 'Chat with support',
            subtitle: 'Get responses in under 5 minutes',
            palette: palette,
            onTap: () => _showComingSoon('Support chat'),
          ),
          Divider(color: palette.dividerColor),
          _SupportTile(
            icon: Icons.mail_outline,
            title: 'Email updates',
            subtitle: 'Receive monthly product news',
            palette: palette,
            onTap: () => _showComingSoon('Email updates'),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(_SettingsPalette palette) {
    return _SettingsCard(
      title: 'Danger zone',
      subtitle: 'Sign out securely from this device',
      palette: palette,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.dangerColor,
          foregroundColor: palette.dangerText,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded),
        label: Text(
          'Logout',
          style: AppText.poppins(
            color: palette.dangerText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(_SettingsPalette palette) {
    return Center(
      child: Column(
        children: [
          Text(
            'Version 1.0.0',
            style: AppText.poppins(
              color: palette.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '(c) 2025 G App',
            style: AppText.poppins(
              color: palette.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    final theme = Theme.of(context);
    Get.snackbar(
      'Coming soon',
      '$feature is being prepared for the next release.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: theme.colorScheme.surface,
      colorText: theme.colorScheme.onSurface,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
    );
  }

  void _showSnackbar(String title, String message) {
    final theme = Theme.of(context);
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: theme.colorScheme.surface,
      colorText: theme.colorScheme.onSurface,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.palette,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final _SettingsPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.poppins(
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppText.poppins(
              color: palette.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.palette,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final _SettingsPalette palette;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.supportIconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: palette.textPrimary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.poppins(
                      color: palette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppText.poppins(
                      color: palette.textMuted,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: palette.chevronColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.action,
    required this.onTap,
    required this.palette,
  });

  final _QuickAction action;
  final VoidCallback onTap;
  final _SettingsPalette palette;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 150,
          maxWidth: 160,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.quickActionBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.quickActionBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              action.label,
              style: AppText.poppins(
                color: palette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              action.description,
              style: AppText.poppins(
                color: palette.quickActionDescription,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
}

class _SettingsPalette {
  _SettingsPalette(ThemeData theme)
      : isDark = theme.brightness == Brightness.dark,
        background = theme.scaffoldBackgroundColor,
        textPrimary = theme.colorScheme.onSurface,
        textMuted = theme.brightness == Brightness.dark
            ? const Color(0xFF7A88A8)
            : const Color(0xFF5A6B84),
        cardSurface = theme.brightness == Brightness.dark
            ? const Color(0xFF111A2E)
            : Colors.white,
        cardBorder = theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05),
        navIconBackground = theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.08),
        navIconColor = theme.colorScheme.onSurface,
        quickActionBackground = theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.05)
            : Colors.white,
        quickActionBorder = theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05),
        quickActionDescription = theme.brightness == Brightness.dark
            ? Colors.white70
            : Colors.black54,
        supportIconBackground = theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.08)
            : theme.colorScheme.primary.withOpacity(0.08),
        dividerColor = theme.brightness == Brightness.dark
            ? Colors.white12
            : Colors.black12,
        chevronColor = theme.brightness == Brightness.dark
            ? Colors.white38
            : Colors.black45,
        dangerColor = theme.brightness == Brightness.dark
            ? const Color(0xFFFF5F6D)
            : Colors.redAccent,
        dangerText = Colors.white;

  final bool isDark;
  final Color background;
  final Color textPrimary;
  final Color textMuted;
  final Color cardSurface;
  final Color cardBorder;
  final Color navIconBackground;
  final Color navIconColor;
  final Color quickActionBackground;
  final Color quickActionBorder;
  final Color quickActionDescription;
  final Color supportIconBackground;
  final Color dividerColor;
  final Color chevronColor;
  final Color dangerColor;
  final Color dangerText;
}
