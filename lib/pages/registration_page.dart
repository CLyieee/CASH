import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:g/utils/app_text.dart';
import 'package:g/utils/responsive_helper.dart';
import '../controllers/app_controller.dart';
import 'phone_verification_page.dart';

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    final phoneController = TextEditingController();

    final isSmallScreen = ResponsiveHelper.isSmallScreen(context);
    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);
    final verticalPadding = ResponsiveHelper.verticalPadding(context);

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
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - verticalPadding * 2,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: isSmallScreen ? 10 : 20),

                      // Title
                      Text(
                        'Phone\nRegistration',
                        style: AppText.poppins(
                          color: const Color(0xFF2C3E50),
                          fontSize: isSmallScreen ? 32 : 40,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
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
                      )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: -0.3, end: 0),

                      SizedBox(height: isSmallScreen ? 8 : 12),

                      Text(
                        'Enter your phone number to receive a verification code',
                        style: AppText.poppins(
                          color: const Color(0xFF64B5F6),
                          fontSize: isSmallScreen ? 13 : 15,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                      const Spacer(),

                      // Phone Icon
                      Center(
                        child: Container(
                          width: isSmallScreen ? 80 : 100,
                          height: isSmallScreen ? 80 : 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E5EC),
                            shape: BoxShape.circle,
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
                          child: Center(
                            child: Container(
                              width: isSmallScreen ? 56 : 70,
                              height: isSmallScreen ? 56 : 70,
                              decoration: BoxDecoration(
                                color: const Color(0xFF64B5F6),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF64B5F6)
                                        .withOpacity(0.5),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.phone_android_rounded,
                                color: Colors.white,
                                size: isSmallScreen ? 28 : 35,
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .scale(duration: 600.ms, curve: Curves.easeOutBack),
                      ),

                      const Spacer(),

                      // Phone Input
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 18 : 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E5EC),
                          borderRadius: BorderRadius.circular(24),
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
                            Text(
                              '+63',
                              style: AppText.poppins(
                                color: const Color(0xFF2C3E50),
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 12 : 16),
                            Container(
                              width: 2,
                              height: 30,
                              color: const Color(0xFF64B5F6).withOpacity(0.3),
                            ),
                            SizedBox(width: isSmallScreen ? 12 : 16),
                            Expanded(
                              child: TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                style: AppText.poppins(
                                  color: const Color(0xFF2C3E50),
                                  fontSize: isSmallScreen ? 18 : 20,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: '912 345 6789',
                                  hintStyle: AppText.poppins(
                                    color: const Color(0xFF64B5F6)
                                        .withOpacity(0.4),
                                    fontSize: isSmallScreen ? 18 : 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 200.ms)
                          .slideY(begin: 0.3, end: 0, delay: 200.ms),

                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Continue Button
                      Container(
                        width: double.infinity,
                        height: isSmallScreen ? 60 : 68,
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
                            onTap: () {
                              if (phoneController.text.length >= 10) {
                                controller.setPhoneNumber(
                                    '+63${phoneController.text}');
                                Get.to(
                                  () => PhoneVerificationPage(
                                    phoneNumber: '+63${phoneController.text}',
                                  ),
                                  transition: Transition.rightToLeftWithFade,
                                  duration: const Duration(milliseconds: 400),
                                );
                              } else {
                                Get.snackbar(
                                  'Invalid Phone Number',
                                  'Please enter a valid 10-digit phone number',
                                  backgroundColor: const Color(0xFFE0E5EC),
                                  colorText: const Color(0xFF2C3E50),
                                  snackPosition: SnackPosition.TOP,
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 16 : 24,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Continue',
                                      style: AppText.poppins(
                                        fontSize: isSmallScreen ? 18 : 20,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF2C3E50),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: isSmallScreen ? 12 : 16),
                                  Container(
                                    padding:
                                        EdgeInsets.all(isSmallScreen ? 10 : 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF64B5F6),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF64B5F6)
                                              .withOpacity(0.5),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 300.ms)
                          .slideY(begin: 0.3, end: 0, delay: 300.ms),

                      SizedBox(height: isSmallScreen ? 16 : 32),
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
}
