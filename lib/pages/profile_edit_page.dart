import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/app_controller.dart';
import '../utils/app_text.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final AppController controller = Get.find<AppController>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _pinController;
  bool _isLoading = false;
  bool _showPin = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: controller.userName.value);
    _phoneController =
        TextEditingController(text: controller.phoneNumber.value);
    _pinController = TextEditingController(text: controller.pin.value);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    // Validation
    if (name.isEmpty) {
      _showSnackbar('Error', 'Name cannot be empty', isError: true);
      return;
    }

    if (phone.isNotEmpty && !_isValidPhoneNumber(phone)) {
      _showSnackbar('Error', 'Invalid phone number format', isError: true);
      return;
    }

    if (pin.isNotEmpty && pin.length != 4) {
      _showSnackbar('Error', 'PIN must be exactly 4 digits', isError: true);
      return;
    }

    if (pin.isNotEmpty && !RegExp(r'^\d+$').hasMatch(pin)) {
      _showSnackbar('Error', 'PIN must contain only numbers', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      controller.setUserName(name);
      if (phone.isNotEmpty) {
        controller.setPhoneNumber(phone);
      }
      if (pin.isNotEmpty) {
        controller.setPin(pin);
      }

      await controller.saveUserData();

      if (mounted) {
        _showSnackbar('Success', 'Profile updated successfully!',
            isError: false);
        await Future.delayed(const Duration(milliseconds: 800));
        Get.back();
      }
    } catch (e) {
      _showSnackbar('Error', 'Failed to update profile: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isValidPhoneNumber(String phone) {
    // Check for Philippine phone number format
    final cleaned = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    return RegExp(r'^\+?63\d{10}$').hasMatch(cleaned) ||
        RegExp(r'^09\d{9}$').hasMatch(cleaned);
  }

  void _showSnackbar(String title, String message, {required bool isError}) {
    Get.snackbar(
      title,
      message,
      backgroundColor:
          isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA);
    final cardSurface = isDark ? const Color(0xFF1C2128) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final textPrimary =
        isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1F2937);
    final textSecondary =
        isDark ? const Color(0xFF8B949E) : const Color(0xFF6B7280);
    final accentBlue = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardSurface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: 20),
        ),
        title: Text(
          'Edit Profile',
          style: AppText.poppins(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: cardBorder),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Icon
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentBlue, accentBlue.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentBlue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Name Field
            _buildInputField(
              label: 'Full Name',
              controller: _nameController,
              icon: Icons.person_outline,
              hint: 'Enter your full name',
              cardSurface: cardSurface,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              accentColor: accentBlue,
            ),

            const SizedBox(height: 20),

            // Phone Field
            _buildInputField(
              label: 'Phone Number',
              controller: _phoneController,
              icon: Icons.phone_outlined,
              hint: '+63 912 345 6789 or 09123456789',
              keyboardType: TextInputType.phone,
              cardSurface: cardSurface,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              accentColor: accentBlue,
            ),

            const SizedBox(height: 20),

            // PIN Field
            _buildInputField(
              label: 'Security PIN (4 digits)',
              controller: _pinController,
              icon: Icons.lock_outline,
              hint: 'Enter 4-digit PIN',
              keyboardType: TextInputType.number,
              isPassword: !_showPin,
              cardSurface: cardSurface,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              accentColor: accentBlue,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _showPin = !_showPin),
                icon: Icon(
                  _showPin ? Icons.visibility_off : Icons.visibility,
                  color: textSecondary,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // PIN Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: accentBlue, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your PIN is used for secure transactions and app access',
                      style: AppText.poppins(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: AppText.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: TextButton(
                onPressed: _isLoading ? null : () => Get.back(),
                style: TextButton.styleFrom(
                  foregroundColor: textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: cardBorder),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: AppText.poppins(
                    color: textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required Color cardSurface,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
    TextInputType? keyboardType,
    bool isPassword = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.poppins(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword,
            style: AppText.poppins(
              color: textPrimary,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppText.poppins(
                color: textSecondary.withOpacity(0.6),
                fontSize: 14,
              ),
              prefixIcon: Icon(icon, color: accentColor, size: 22),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
