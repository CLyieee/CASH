import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/app_controller.dart';
import '../controllers/theme_controller.dart';
import '../services/biometric_auth_service.dart';
import '../services/app_update_service.dart';
import '../services/auto_receipt_scanner_service.dart';
import '../services/backup_service.dart';
import '../utils/app_text.dart';
import 'login_selection_page.dart';
import 'fee_settings_page.dart';
import 'reports_page.dart';
import 'profile_edit_page.dart';
import 'calendar_view_page.dart';
import 'terms_conditions_page.dart';
import 'forgot_pin_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const String _biometricPrefKey = 'biometric_enabled';
  final BiometricAuthService _biometricService = BiometricAuthService();
  final AutoReceiptScannerService _autoScanService =
      AutoReceiptScannerService();
  final BackupService _backupService = BackupService();
  final AppController controller = Get.find<AppController>();
  final ThemeController themeController = Get.find<ThemeController>();
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _isAutoScanEnabled = false;
  bool _isAutoBackupEnabled = false;
  bool _isLoading = true;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), _checkBiometricStatus);
    _loadAutoScanStatus();
    _loadAutoBackupStatus();
  }

  Future<void> _loadAutoScanStatus() async {
    final isEnabled = await _autoScanService.isAutoScanEnabled();
    if (mounted) {
      setState(() {
        _isAutoScanEnabled = isEnabled;
      });
    }
  }

  Future<void> _loadAutoBackupStatus() async {
    final isEnabled = await _backupService.isAutoBackupEnabled();
    if (mounted) {
      setState(() {
        _isAutoBackupEnabled = isEnabled;
      });
    }
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

  Future<void> _toggleAutoScan(bool value) async {
    if (value) {
      // Request permission
      final hasPermission = await _autoScanService.requestStoragePermission();
      if (!hasPermission) {
        _showSnackbar('Permission Required',
            'Please grant storage access to auto-scan receipts');
        return;
      }

      // Enable auto-scan
      await _autoScanService.setAutoScanEnabled(true);
      setState(() => _isAutoScanEnabled = true);

      // Run initial scan
      _runAutoScan();

      _showSnackbar(
          'Success', 'Auto-scan enabled! Scanning Pictures folder...');
    } else {
      await _autoScanService.setAutoScanEnabled(false);
      setState(() => _isAutoScanEnabled = false);
      _showSnackbar('Disabled', 'Auto-scan disabled');
    }
  }

  Future<void> _runAutoScan() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);

    try {
      final result = await _autoScanService.scanPicturesFolder();

      if (result.success) {
        _showSnackbar(
          'Scan Complete',
          result.message,
          duration: const Duration(seconds: 4),
        );
      } else {
        _showSnackbar('Scan Failed', result.message);
      }
    } catch (e) {
      _showSnackbar('Error', 'Failed to scan: $e');
    } finally {
      setState(() => _isScanning = false);
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
    final palette = _SettingsPalette(theme);
    Get.dialog(
      Dialog(
        backgroundColor: palette.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: palette.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Logout',
                style: AppText.poppins(
                  color: palette.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to logout?',
                style: AppText.poppins(
                  color: palette.onSurfaceVariant,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: palette.onSurface,
                        side: BorderSide(color: palette.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Get.back(),
                      child: Text(
                        'Cancel',
                        style: AppText.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.error,
                        foregroundColor: palette.onError,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
                  valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
                ),
              )
            : CustomScrollView(
                slivers: [
                  // M3 Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Material(
                            color: palette.surfaceContainer,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Get.back(),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: palette.onSurface,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Settings',
                            style: AppText.poppins(
                              color: palette.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Profile Section
                        _buildProfileSection(palette),
                        const SizedBox(height: 28),

                        // Preferences Section
                        _buildSectionHeader('Preferences', palette),
                        const SizedBox(height: 12),
                        _buildPreferencesSection(palette),
                        const SizedBox(height: 28),

                        // Tools Section
                        _buildSectionHeader('Tools', palette),
                        const SizedBox(height: 12),
                        _buildToolsSection(palette),
                        const SizedBox(height: 28),

                        // Data Management Section
                        _buildSectionHeader('Data Management', palette),
                        const SizedBox(height: 12),
                        _buildDataManagementSection(palette),
                        const SizedBox(height: 28),

                        // About Section
                        _buildSectionHeader('About', palette),
                        const SizedBox(height: 12),
                        _buildAboutSection(palette),
                        const SizedBox(height: 28),

                        // Logout
                        _buildLogoutTile(palette),
                        const SizedBox(height: 32),

                        // Footer
                        _buildFooter(palette),
                      ]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, _SettingsPalette palette) {
    return Text(
      title,
      style: AppText.poppins(
        color: palette.onSurfaceVariant,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildProfileSection(_SettingsPalette palette) {
    return Obx(() {
      final name = controller.userName.value.isEmpty
          ? 'Hi there'
          : controller.userName.value;
      final phone = controller.phoneNumber.value.isEmpty
          ? 'Add your mobile number'
          : controller.phoneNumber.value;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              palette.primary.withOpacity(0.15),
              palette.primary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: palette.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppText.poppins(
                      color: palette.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: AppText.poppins(
                      color: palette.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Get.to(() => const ProfileEditPage()),
              style: IconButton.styleFrom(
                backgroundColor: palette.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                Icons.edit_rounded,
                color: palette.primary,
                size: 20,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPreferencesSection(_SettingsPalette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Theme Toggle
          Obx(() {
            final isDark = themeController.themeMode.value == ThemeMode.dark;
            return _buildSettingsTile(
              icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              iconColor: const Color(0xFFFFA726),
              iconBgColor: const Color(0xFFFFA726).withOpacity(0.15),
              title: 'Appearance',
              subtitle: isDark ? 'Dark mode' : 'Light mode',
              palette: palette,
              trailing: Switch.adaptive(
                value: isDark,
                onChanged: (value) => themeController.toggleTheme(),
                activeColor: palette.primary,
              ),
            );
          }),
          Divider(height: 1, color: palette.outlineVariant, indent: 60),
          // Biometric
          _buildSettingsTile(
            icon: Icons.fingerprint_rounded,
            iconColor: const Color(0xFF26A69A),
            iconBgColor: const Color(0xFF26A69A).withOpacity(0.15),
            title: 'Biometric login',
            subtitle: _isBiometricAvailable
                ? 'Fingerprint or Face ID'
                : 'Not available',
            palette: palette,
            trailing: Switch.adaptive(
              value: _isBiometricEnabled,
              onChanged: _isBiometricAvailable ? _toggleBiometric : null,
              activeColor: palette.primary,
            ),
          ),
          Divider(height: 1, color: palette.outlineVariant, indent: 60),
          // Reset PIN
          _buildSettingsTile(
            icon: Icons.lock_reset_rounded,
            iconColor: const Color(0xFFFF7043),
            iconBgColor: const Color(0xFFFF7043).withOpacity(0.15),
            title: 'Reset PIN',
            subtitle: 'Change your security PIN',
            palette: palette,
            onTap: () => Get.to(
              () => const ForgotPinPage(),
              transition: Transition.fadeIn,
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsSection(_SettingsPalette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.calendar_month_rounded,
            iconColor: const Color(0xFF42A5F5),
            iconBgColor: const Color(0xFF42A5F5).withOpacity(0.15),
            title: 'Calendar view',
            subtitle: 'View transactions by date',
            palette: palette,
            onTap: () => Get.to(() => const CalendarViewPage()),
          ),
          Divider(height: 1, color: palette.outlineVariant, indent: 60),
          _buildSettingsTile(
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xFFAB47BC),
            iconBgColor: const Color(0xFFAB47BC).withOpacity(0.15),
            title: 'Fee settings',
            subtitle: 'Manage transaction fees',
            palette: palette,
            onTap: () => Get.to(() => const FeeSettingsPage()),
          ),
          Divider(height: 1, color: palette.outlineVariant, indent: 60),
          _buildSettingsTile(
            icon: Icons.download_rounded,
            iconColor: const Color(0xFF66BB6A),
            iconBgColor: const Color(0xFF66BB6A).withOpacity(0.15),
            title: 'Export reports',
            subtitle: 'Generate CSV reports',
            palette: palette,
            onTap: () => Get.to(() => const ReportsPage()),
          ),
          Divider(height: 1, color: palette.outlineVariant, indent: 60),
          _buildSettingsTile(
            icon: Icons.system_update_rounded,
            iconColor: const Color(0xFF29B6F6),
            iconBgColor: const Color(0xFF29B6F6).withOpacity(0.15),
            title: 'Check for updates',
            subtitle: 'Download latest version',
            palette: palette,
            onTap: () => _showUpdateDialog(palette),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementSection(_SettingsPalette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.cloud_upload_rounded,
            iconColor: const Color(0xFF4CAF50),
            iconBgColor: const Color(0xFF4CAF50).withOpacity(0.15),
            title: 'Backup data',
            subtitle: 'Save your data to cloud',
            palette: palette,
            onTap: () => _createBackup(palette),
          ),
          Divider(height: 1, color: palette.outlineVariant, indent: 60),
          _buildSettingsTile(
            icon: Icons.cloud_download_rounded,
            iconColor: const Color(0xFF2196F3),
            iconBgColor: const Color(0xFF2196F3).withOpacity(0.15),
            title: 'Restore data',
            subtitle: 'Restore from previous backup',
            palette: palette,
            onTap: () => _showRestoreDialog(palette),
          ),
          Divider(height: 1, color: palette.outlineVariant, indent: 60),
          _buildSettingsTile(
            icon: Icons.delete_forever_rounded,
            iconColor: const Color(0xFFE53935),
            iconBgColor: const Color(0xFFE53935).withOpacity(0.15),
            title: 'Delete all data',
            subtitle: 'Permanently delete all your data',
            palette: palette,
            onTap: () => _showDeleteAllDialog(palette),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(_SettingsPalette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF78909C),
            iconBgColor: const Color(0xFF78909C).withOpacity(0.15),
            title: 'Terms & Conditions',
            subtitle: 'Read our terms of service',
            palette: palette,
            onTap: () => Get.to(() => const TermsConditionsPage()),
          ),
          Divider(height: 1, color: palette.outlineVariant, indent: 60),
          FutureBuilder<String>(
            future: AppUpdateService.getCurrentVersion(),
            builder: (context, snapshot) {
              final version = snapshot.data ?? '1.0.0';
              return _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                iconColor: const Color(0xFF78909C),
                iconBgColor: const Color(0xFF78909C).withOpacity(0.15),
                title: 'App version',
                subtitle: 'Version $version',
                palette: palette,
                showChevron: false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required _SettingsPalette palette,
    Widget? trailing,
    VoidCallback? onTap,
    bool showChevron = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.poppins(
                        color: palette.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppText.poppins(
                        color: palette.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
              if (trailing == null && showChevron && onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.outline,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutTile(_SettingsPalette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _logout,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: palette.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: palette.error,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Logout',
                    style: AppText.poppins(
                      color: palette.error,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.error.withOpacity(0.5),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppUpdateCard(_SettingsPalette palette) {
    return _SettingsCard(
      title: 'App Update',
      subtitle: 'Download the latest version',
      palette: palette,
      child: FutureBuilder<String>(
        future: AppUpdateService.getCurrentVersion(),
        builder: (context, snapshot) {
          final currentVersion = snapshot.data ?? 'Loading...';
          return Column(
            children: [
              _SupportTile(
                icon: Icons.system_update_rounded,
                title: 'Check for updates',
                subtitle: 'Current version: $currentVersion',
                palette: palette,
                onTap: () => _showUpdateDialog(palette),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showUpdateDialog(_SettingsPalette palette) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UpdateDialog(palette: palette),
    );
  }

  Widget _buildFooter(_SettingsPalette palette) {
    return Center(
      child: Column(
        children: [
          FutureBuilder<String>(
            future: AppUpdateService.getCurrentVersion(),
            builder: (context, snapshot) {
              final version = snapshot.data ?? '1.0.0';
              return Text(
                'Version $version',
                style: AppText.poppins(
                  color: palette.textMuted,
                  fontSize: 12,
                ),
              );
            },
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

  void _showSnackbar(String title, String message, {Duration? duration}) {
    final theme = Theme.of(context);
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: theme.colorScheme.surface,
      colorText: theme.colorScheme.onSurface,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  // Toggle auto backup
  Future<void> _toggleAutoBackup(bool value) async {
    try {
      await _backupService.setAutoBackup(value);
      setState(() => _isAutoBackupEnabled = value);
      _showSnackbar(
        'Success',
        value ? 'Auto backup enabled' : 'Auto backup disabled',
      );

      // If enabled, perform initial backup
      if (value && controller.currentUserId.value.isNotEmpty) {
        _createBackup(_SettingsPalette(Theme.of(context)), showDialog: false);
      }
    } catch (e) {
      _showSnackbar('Error', 'Failed to update auto backup setting');
    }
  }

  // Create backup
  Future<void> _createBackup(_SettingsPalette palette,
      {bool showDialog = true}) async {
    if (controller.currentUserId.value.isEmpty) {
      _showSnackbar('Error', 'User not logged in');
      return;
    }

    try {
      if (showDialog) {
        Get.dialog(
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: palette.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: palette.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Creating backup...',
                    style: AppText.poppins(
                      color: palette.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          barrierDismissible: false,
        );
      }

      final result =
          await _backupService.createBackup(controller.currentUserId.value);

      if (showDialog) {
        Get.back(); // Close loading dialog
      }

      _showSnackbar('Success', result);
    } catch (e) {
      if (showDialog) {
        Get.back(); // Close loading dialog
      }
      _showSnackbar('Error', 'Failed to create backup: ${e.toString()}');
    }
  }

  // Show restore dialog with list of backups
  Future<void> _showRestoreDialog(_SettingsPalette palette) async {
    if (controller.currentUserId.value.isEmpty) {
      _showSnackbar('Error', 'User not logged in');
      return;
    }

    try {
      Get.dialog(
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: palette.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: palette.primary),
                const SizedBox(height: 16),
                Text(
                  'Loading backups...',
                  style: AppText.poppins(
                    color: palette.onSurface,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final backups =
          await _backupService.listBackups(controller.currentUserId.value);
      Get.back(); // Close loading dialog

      if (backups.isEmpty) {
        _showSnackbar('Info', 'No backups available');
        return;
      }

      // Show list of backups
      Get.dialog(
        Dialog(
          backgroundColor: palette.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Backup',
                  style: AppText.poppins(
                    color: palette.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: backups.length,
                    separatorBuilder: (context, index) => Divider(
                      color: palette.outlineVariant,
                    ),
                    itemBuilder: (context, index) {
                      final backup = backups[index];
                      final date = backup['created'] as DateTime?;
                      final transactionCount =
                          backup['transactionCount'] as int? ?? 0;

                      return ListTile(
                        leading: Icon(
                          Icons.cloud_done_rounded,
                          color: palette.primary,
                        ),
                        title: Text(
                          date?.toString().substring(0, 19) ?? 'Unknown',
                          style: AppText.poppins(
                            color: palette.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '$transactionCount transactions',
                          style: AppText.poppins(
                            color: palette.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          Get.back();
                          _restoreBackup(palette, backup['id']);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: palette.onSurface,
                      side: BorderSide(color: palette.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Get.back(),
                    child: Text('Cancel', style: AppText.poppins(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      Get.back(); // Close loading dialog if open
      _showSnackbar('Error', 'Failed to load backups: ${e.toString()}');
    }
  }

  // Restore backup
  Future<void> _restoreBackup(
      _SettingsPalette palette, String backupName) async {
    Get.dialog(
      Dialog(
        backgroundColor: palette.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.cloud_download_rounded,
                  color: palette.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Restore Backup',
                style: AppText.poppins(
                  color: palette.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will replace all your current data with the backup data. This action cannot be undone.',
                style: AppText.poppins(
                  color: palette.onSurfaceVariant,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: palette.onSurface,
                        side: BorderSide(color: palette.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Get.back(),
                      child:
                          Text('Cancel', style: AppText.poppins(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: palette.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        Get.back();

                        // Show loading
                        Get.dialog(
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: palette.surfaceContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                      color: palette.primary),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Restoring backup...',
                                    style: AppText.poppins(
                                      color: palette.onSurface,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          barrierDismissible: false,
                        );

                        try {
                          final result = await _backupService.restoreBackup(
                            controller.currentUserId.value,
                            backupName,
                          );
                          Get.back(); // Close loading
                          _showSnackbar('Success', result);

                          // Reload app controller data
                          await controller
                              .loadUserData(controller.currentUserId.value);
                        } catch (e) {
                          Get.back(); // Close loading
                          _showSnackbar(
                              'Error', 'Failed to restore: ${e.toString()}');
                        }
                      },
                      child:
                          Text('Restore', style: AppText.poppins(fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show delete all data confirmation
  Future<void> _showDeleteAllDialog(_SettingsPalette palette) async {
    Get.dialog(
      Dialog(
        backgroundColor: palette.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.delete_forever_rounded,
                  color: palette.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete All Transactions',
                style: AppText.poppins(
                  color: palette.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will permanently delete all your transactions. Your profile, settings, and backups will be preserved. This action cannot be undone!',
                style: AppText.poppins(
                  color: palette.onSurfaceVariant,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: palette.onSurface,
                        side: BorderSide(color: palette.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Get.back(),
                      child:
                          Text('Cancel', style: AppText.poppins(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: palette.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        Get.back();

                        // Show loading
                        Get.dialog(
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: palette.surfaceContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                      color: palette.error),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Deleting all data...',
                                    style: AppText.poppins(
                                      color: palette.onSurface,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          barrierDismissible: false,
                        );

                        try {
                          await _backupService
                              .deleteAllData(controller.currentUserId.value);
                          Get.back(); // Close loading

                          // Don't logout - just show success message
                          _showSnackbar('Success',
                              'All transactions deleted successfully');

                          // Reload the current page to refresh data
                          setState(() {});
                        } catch (e) {
                          Get.back(); // Close loading
                          _showSnackbar('Error',
                              'Failed to delete data: ${e.toString()}');
                        }
                      },
                      child:
                          Text('Delete', style: AppText.poppins(fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
        color: palette.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.poppins(
              color: palette.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppText.poppins(
              color: palette.onSurfaceVariant,
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: palette.onPrimaryContainer, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.poppins(
                      color: palette.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppText.poppins(
                      color: palette.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: palette.outline,
              size: 20,
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
          color: palette.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              action.label,
              style: AppText.poppins(
                color: palette.onSurface,
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
                color: palette.onSurfaceVariant,
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
        // M3 Surface colors
        background = theme.brightness == Brightness.dark
            ? const Color(0xFF0D1117)
            : const Color(0xFFFCFCFF),
        surfaceContainer = theme.brightness == Brightness.dark
            ? const Color(0xFF1C2128)
            : const Color(0xFFF3F3F6),
        containerHigh = theme.brightness == Brightness.dark
            ? const Color(0xFF262C36)
            : const Color(0xFFEAEAED),
        // M3 Text colors
        textPrimary = theme.colorScheme.onSurface,
        textMuted = theme.brightness == Brightness.dark
            ? const Color(0xFF9CA3AF)
            : const Color(0xFF6B7280),
        onSurface = theme.colorScheme.onSurface,
        onSurfaceVariant = theme.brightness == Brightness.dark
            ? const Color(0xFF9CA3AF)
            : const Color(0xFF6B7280),
        // M3 Primary tonal palette
        primary = theme.brightness == Brightness.dark
            ? const Color(0xFF93C5FD)
            : const Color(0xFF2563EB),
        primaryContainer = theme.brightness == Brightness.dark
            ? const Color(0xFF1E3A5F)
            : const Color(0xFFDBEAFE),
        onPrimaryContainer = theme.brightness == Brightness.dark
            ? const Color(0xFFDBEAFE)
            : const Color(0xFF1E3A5F),
        // M3 Outline colors
        outline = theme.brightness == Brightness.dark
            ? const Color(0xFF4B5563)
            : const Color(0xFFD1D5DB),
        outlineVariant = theme.brightness == Brightness.dark
            ? const Color(0xFF374151)
            : const Color(0xFFE5E7EB),
        // M3 Error colors
        error = theme.brightness == Brightness.dark
            ? const Color(0xFFFCA5A5)
            : const Color(0xFFDC2626),
        onError = theme.brightness == Brightness.dark
            ? const Color(0xFF7F1D1D)
            : Colors.white,
        // Legacy colors (simplified)
        cardSurface = theme.brightness == Brightness.dark
            ? const Color(0xFF1C2128)
            : Colors.white,
        cardBorder = theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        navIconBackground = theme.brightness == Brightness.dark
            ? const Color(0xFF262C36)
            : const Color(0xFFEAEAED),
        navIconColor = theme.colorScheme.onSurface,
        quickActionBackground = theme.brightness == Brightness.dark
            ? const Color(0xFF1C2128)
            : Colors.white,
        quickActionBorder = theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        quickActionDescription = theme.brightness == Brightness.dark
            ? const Color(0xFF9CA3AF)
            : const Color(0xFF6B7280),
        supportIconBackground = theme.brightness == Brightness.dark
            ? const Color(0xFF1E3A5F)
            : const Color(0xFFDBEAFE),
        dividerColor = theme.brightness == Brightness.dark
            ? const Color(0xFF374151)
            : const Color(0xFFE5E7EB),
        chevronColor = theme.brightness == Brightness.dark
            ? const Color(0xFF6B7280)
            : const Color(0xFF9CA3AF),
        dangerColor = theme.brightness == Brightness.dark
            ? const Color(0xFFFCA5A5).withOpacity(0.12)
            : const Color(0xFFDC2626).withOpacity(0.12),
        dangerText = theme.brightness == Brightness.dark
            ? const Color(0xFFFCA5A5)
            : const Color(0xFFDC2626);

  final bool isDark;
  final Color background;
  final Color surfaceContainer;
  final Color containerHigh;
  final Color textPrimary;
  final Color textMuted;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color primary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color outline;
  final Color outlineVariant;
  final Color error;
  final Color onError;
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

class _UpdateDialog extends StatefulWidget {
  final _SettingsPalette palette;

  const _UpdateDialog({required this.palette});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _status = 'Ready to download';

  Future<void> _downloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _status = 'Downloading update...';
      _downloadProgress = 0.0;
    });

    try {
      final filePath = await AppUpdateService.downloadAPK(
        onProgress: (received, total) {
          setState(() {
            _downloadProgress = total > 0 ? received / total : 0.0;
            _status =
                'Downloading: ${(_downloadProgress * 100).toStringAsFixed(1)}%';
          });
        },
      );

      if (filePath == null) {
        setState(() {
          _status = 'Download failed. Please try again.';
          _isDownloading = false;
        });
        return;
      }

      setState(() {
        _status = 'Installing update...';
      });

      final installed = await AppUpdateService.installAPK(filePath);

      if (installed) {
        setState(() {
          _status = 'Update installed! Please restart the app.';
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _status = 'Installation failed. Please install manually.';
          _isDownloading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      backgroundColor: widget.palette.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.palette.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.system_update_rounded,
                    color: widget.palette.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'App Update',
                    style: AppText.poppins(
                      color: widget.palette.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _status,
              style: AppText.poppins(
                color: widget.palette.onSurface,
                fontSize: 14,
              ),
            ),
            if (_isDownloading) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _downloadProgress,
                  backgroundColor: widget.palette.outline.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.palette.primary,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                style: AppText.poppins(
                  color: widget.palette.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Download the latest version from MediaFire and install it automatically.',
              style: AppText.poppins(
                color: widget.palette.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: widget.palette.onSurface,
                      side: BorderSide(color: widget.palette.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isDownloading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: AppText.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.palette.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isDownloading ? null : _downloadAndInstall,
                    child: Text(
                      _isDownloading ? 'Downloading...' : 'Download',
                      style: AppText.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
