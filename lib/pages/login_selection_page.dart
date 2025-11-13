import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:g/utils/app_text.dart';
import '../services/google_sign_in_service.dart';
import '../controllers/app_controller.dart';
import 'login_page.dart';
import 'registration_page.dart';
import 'set_pin_page.dart';

class LoginSelectionPage extends StatelessWidget {
  const LoginSelectionPage({super.key});

  Future<void> _handleGoogleSignIn() async {
    try {
      // Show loading
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64B5F6)),
          ),
        ),
        barrierDismissible: false,
      );

      final googleSignInService = GoogleSignInService();
      final userCredential = await googleSignInService.signInWithGoogle();

      // Close loading dialog
      Get.back();

      if (userCredential != null && userCredential.user != null) {
        // Update app controller with user info and load data from Firestore
        final controller = Get.find<AppController>();
        final user = userCredential.user!;

        // Load user data from Firestore
        await controller.loadUserData(user.uid);

        // Don't overwrite the name if user has already set it up
        // Only use Google name for new users (will be replaced during setup)

        // Check if user has completed setup (has PIN set)
        final hasPin = controller.pin.value.isNotEmpty;

        if (hasPin) {
          // Existing user - redirect to PIN login for security
          Get.offAll(
            () => const LoginPage(),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 400),
          );

          // Show welcome back message
          Get.snackbar(
            'Welcome Back',
            'Please enter your PIN to continue',
            backgroundColor: const Color(0xFF64B5F6),
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(20),
            borderRadius: 16,
            duration: const Duration(seconds: 2),
          );
        } else {
          // New user, redirect to PIN setup
          Get.offAll(
            () => const SetPinPage(),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 400),
          );

          // Show welcome message
          Get.snackbar(
            'Welcome',
            'Let\'s set up your account',
            backgroundColor: const Color(0xFF64B5F6),
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(20),
            borderRadius: 16,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Show error message
      Get.snackbar(
        'Error',
        'Failed to sign in with Google: ${e.toString()}',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20),
        borderRadius: 16,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _handlePhoneSignIn() {
    Get.to(
      () => const RegistrationPage(),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 400),
    );
  }

  void _handlePinLogin() {
    Get.to(
      () => const LoginPage(),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 400),
    );
  }

  void _handleSetupAccount() {
    Get.to(
      () => const SetPinPage(),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E5EC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Title with neumorphic text effect
              Text(
                'Welcome Back',
                style: AppText.poppins(
                  color: const Color(0xFF2C3E50),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  shadows: [
                    Shadow(
                      color: Colors.white.withOpacity(0.8),
                      offset: const Offset(-2, -2),
                      blurRadius: 4,
                    ),
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0),

              const SizedBox(height: 12),

              Text(
                'Choose how you want to sign in',
                style: AppText.poppins(
                  color: const Color(0xFF64B5F6),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 100.ms)
                  .slideY(begin: -0.3, end: 0, delay: 100.ms),

              const SizedBox(height: 40),

              // Sign-in with Google only
              _buildNeumorphicOption(
                icon: Icons.g_mobiledata_rounded,
                title: 'Continue with Google',
                subtitle: 'Sign in with your Google account',
                onTap: _handleGoogleSignIn,
                delay: 200,
              ),

              const SizedBox(height: 40),

              // Terms
              Text(
                'By continuing, you agree to our\nTerms of Service and Privacy Policy',
                textAlign: TextAlign.center,
                style: AppText.poppins(
                  color: const Color(0xFF64B5F6).withOpacity(0.7),
                  fontSize: 12,
                  height: 1.5,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 600.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required int delay,
  }) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon container with inner shadow
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E5EC),
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFE0E5EC),
                        const Color(0xFFE0E5EC).withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF64B5F6),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.poppins(
                          color: const Color(0xFF2C3E50),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppText.poppins(
                          color: const Color(0xFF64B5F6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64B5F6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64B5F6).withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: delay.ms)
        .slideX(begin: 0.3, end: 0, delay: delay.ms);
  }
}
