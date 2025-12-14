import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:g/utils/app_text.dart';
import 'package:g/utils/responsive_helper.dart';
import 'set_pin_page.dart';

class VerificationSuccessPage extends StatelessWidget {
  const VerificationSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E5EC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.all(
                      ResponsiveHelper.horizontalPadding(context)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // Success Icon
                      Container(
                        width:
                            ResponsiveHelper.isSmallScreen(context) ? 120 : 140,
                        height:
                            ResponsiveHelper.isSmallScreen(context) ? 120 : 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E5EC),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              offset: const Offset(-8, -8),
                              blurRadius: 16,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(8, 8),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFF64B5F6),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF64B5F6).withOpacity(0.5),
                                  blurRadius: 24,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .scale(duration: 600.ms, curve: Curves.elasticOut),

                      const SizedBox(height: 48),

                      Text(
                        'Verified!',
                        style: AppText.poppins(
                          color: const Color(0xFF2C3E50),
                          fontSize:
                              ResponsiveHelper.fontSize(context, mobile: 40),
                          fontWeight: FontWeight.bold,
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
                          .fadeIn(duration: 400.ms, delay: 300.ms)
                          .slideY(begin: 0.3, end: 0, delay: 300.ms),

                      const SizedBox(height: 16),

                      Flexible(
                          child: Text(
                        'Your phone number has been\nsuccessfully verified',
                        textAlign: TextAlign.center,
                        style: AppText.poppins(
                          color: const Color(0xFF64B5F6),
                          fontSize:
                              ResponsiveHelper.fontSize(context, mobile: 16),
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      )).animate().fadeIn(duration: 400.ms, delay: 400.ms),

                      const Spacer(),

                      // Continue Button
                      Container(
                        width: double.infinity,
                        height: 68,
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
                            onTap: () => Get.off(
                              () => const SetPinPage(),
                              transition: Transition.fadeIn,
                              duration: const Duration(milliseconds: 400),
                            ),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Continue',
                                    style: AppText.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
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
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 500.ms)
                          .slideY(begin: 0.3, end: 0, delay: 500.ms),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
