import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/biometric_auth_service.dart';
import '../utils/app_text.dart';
import '../controllers/app_controller.dart';
import 'login_selection_page.dart';

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

  @override
  void initState() {
    super.initState();
    // Delay biometric check to ensure Flutter engine is ready
    Future.delayed(const Duration(milliseconds: 300), () {
      _checkBiometricStatus();
    });
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
      print('Error checking biometric status: $e');
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
        // Enabling biometric - require authentication first
        final authenticated = await _biometricService.authenticate(
          localizedReason: 'Authenticate to enable biometric login',
        );

        if (authenticated) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_biometricPrefKey, true);
          if (mounted) {
            setState(() {
              _isBiometricEnabled = true;
            });
          }

          Get.snackbar(
            'Success',
            'Biometric authentication enabled!',
            backgroundColor: const Color(0xFF4CAF50),
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(20),
            borderRadius: 16,
          );
        } else {
          Get.snackbar(
            'Failed',
            'Biometric authentication was not successful',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(20),
            borderRadius: 16,
          );
        }
      } else {
        // Disabling biometric
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_biometricPrefKey, false);
        if (mounted) {
          setState(() {
            _isBiometricEnabled = false;
          });
        }

        Get.snackbar(
          'Success',
          'Biometric authentication disabled',
          backgroundColor: const Color(0xFF64B5F6),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(20),
          borderRadius: 16,
        );
      }
    } catch (e) {
      print('Error toggling biometric: $e');
      Get.snackbar(
        'Error',
        'Failed to update biometric settings',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20),
        borderRadius: 16,
      );
    }
  }

  Future<void> _logout() async {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFFE0E5EC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Logout',
          style: AppText.poppins(
            color: const Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppText.poppins(
            color: const Color(0xFF2C3E50),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: AppText.poppins(
                color: const Color(0xFF64B5F6),
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
                color: Colors.red,
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
    return Scaffold(
      backgroundColor: const Color(0xFFE0E5EC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E5EC),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  offset: const Offset(-4, -4),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(4, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF2C3E50),
            ),
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Settings',
          style: AppText.poppins(
            color: const Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64B5F6)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Security Section
                  Text(
                    'Security',
                    style: AppText.poppins(
                      color: const Color(0xFF2C3E50),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Biometric Toggle
                  Container(
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
                            color: _isBiometricEnabled
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF64B5F6),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isBiometricEnabled
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFF64B5F6))
                                    .withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.fingerprint,
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
                                'Biometric Login',
                                style: AppText.poppins(
                                  color: const Color(0xFF2C3E50),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isBiometricAvailable
                                    ? 'Use fingerprint or face to login'
                                    : 'Not available on this device',
                                style: AppText.poppins(
                                  color: const Color(0xFF64B5F6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isBiometricEnabled,
                          onChanged:
                              _isBiometricAvailable ? _toggleBiometric : null,
                          activeColor: const Color(0xFF4CAF50),
                          inactiveThumbColor:
                              const Color(0xFF2C3E50).withOpacity(0.3),
                        ),
                      ],
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
                  ),
                  const SizedBox(height: 16),

                  // Logout Button
                  GestureDetector(
                    onTap: _logout,
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
                              color: Colors.red.shade400,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.shade400.withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Logout',
                              style: AppText.poppins(
                                color: const Color(0xFF2C3E50),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: const Color(0xFF2C3E50).withOpacity(0.3),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App Info
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Version 1.0.0',
                          style: AppText.poppins(
                            color: const Color(0xFF2C3E50).withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '© 2025 G App',
                          style: AppText.poppins(
                            color: const Color(0xFF2C3E50).withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
