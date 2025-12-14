import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:g/utils/app_text.dart';
import '../services/google_sign_in_service.dart';
import '../controllers/app_controller.dart';
import 'login_page.dart';
import 'registration_page.dart';
import 'set_pin_page.dart';
import 'terms_conditions_page.dart';

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
      // Force account picker to show - allows users to choose from multiple Google accounts
      final userCredential =
          await googleSignInService.signInWithGoogle(forceAccountPicker: true);

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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompact = screenWidth < 360;
    final isSmall = screenWidth < 400;
    final isShortScreen = screenHeight < 700;

    final horizontalPadding = isCompact ? 16.0 : (isSmall ? 20.0 : 24.0);
    final topSpacing = isShortScreen ? 30.0 : 60.0;
    final iconSize = isCompact ? 80.0 : (isSmall ? 90.0 : 100.0);
    final titleSize = isCompact ? 28.0 : (isSmall ? 32.0 : 36.0);
    final subtitleSize = isCompact ? 13.0 : (isSmall ? 14.0 : 15.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: topSpacing),

                      // App icon
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(isCompact ? 20 : 24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF64B5F6).withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/icon/app_icon.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                          .animate()
                          .scale(duration: 600.ms, curve: Curves.easeOutBack),

                      SizedBox(height: isShortScreen ? 20 : 32),

                      // Title with gradient effect
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF64B5F6),
                            Color(0xFF42A5F5),
                            Color(0xFF1E88E5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          'Welcome Back',
                          style: AppText.poppins(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: -0.2, end: 0),

                      SizedBox(height: isCompact ? 8 : 12),

                      Text(
                        'Sign in to continue managing your finances',
                        textAlign: TextAlign.center,
                        style: AppText.poppins(
                          color: const Color(0xFF6B7280),
                          fontSize: subtitleSize,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 100.ms)
                          .slideY(begin: -0.2, end: 0, delay: 100.ms),

                      SizedBox(height: isShortScreen ? 40 : 60),

                      // Sign-in with Google
                      _buildModernOption(
                        context: context,
                        icon: Icons.g_mobiledata_rounded,
                        title: 'Continue with Google',
                        subtitle: 'Choose from your accounts',
                        onTap: _handleGoogleSignIn,
                        delay: 200,
                        color: const Color(0xFF64B5F6),
                      ),

                      const Spacer(),
                      SizedBox(height: isShortScreen ? 40 : 80),

                      // Terms
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF64B5F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                color: Color(0xFF64B5F6),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your data is secure and encrypted',
                                style: AppText.poppins(
                                  color: const Color(0xFF6B7280),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 600.ms, delay: 400.ms),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'By continuing, you agree to our ',
                            textAlign: TextAlign.center,
                            style: AppText.poppins(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Get.to(
                                () => const TermsConditionsPage(),
                                transition: Transition.rightToLeftWithFade,
                                duration: const Duration(milliseconds: 400),
                              );
                            },
                            child: Text(
                              'Terms & Conditions',
                              textAlign: TextAlign.center,
                              style: AppText.poppins(
                                color: const Color(0xFF64B5F6),
                                fontSize: 12,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 600.ms, delay: 500.ms),

                      SizedBox(height: isShortScreen ? 20 : 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required int delay,
    required Color color,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final isSmall = screenWidth < 400;

    final iconContainerSize = isCompact ? 44.0 : (isSmall ? 50.0 : 56.0);
    final iconSize = isCompact ? 24.0 : (isSmall ? 28.0 : 32.0);
    final titleSize = isCompact ? 15.0 : (isSmall ? 16.0 : 18.0);
    final subtitleSize = isCompact ? 12.0 : (isSmall ? 13.0 : 14.0);
    final cardPadding = isCompact ? 16.0 : (isSmall ? 20.0 : 24.0);
    final borderRadius = isCompact ? 18.0 : (isSmall ? 20.0 : 24.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
                SizedBox(width: isCompact ? 14 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.poppins(
                          color: Colors.white,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: isCompact ? 2 : 4),
                      Text(
                        subtitle,
                        style: AppText.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: subtitleSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(isCompact ? 6 : 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: isCompact ? 16 : 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: delay.ms).scale(
        begin: const Offset(0.9, 0.9),
        end: const Offset(1, 1),
        delay: delay.ms,
        curve: Curves.easeOutBack);
  }

  Widget _buildSecondaryOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required int delay,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                // Icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF64B5F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF64B5F6).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF64B5F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.poppins(
                          color: const Color(0xFF1F2937),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppText.poppins(
                          color: const Color(0xFF6B7280),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: delay.ms)
        .slideX(begin: 0.1, end: 0, delay: delay.ms, curve: Curves.easeOutQuad);
  }
}
