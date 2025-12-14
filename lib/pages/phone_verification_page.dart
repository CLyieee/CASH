import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:g/utils/app_text.dart';
import 'package:g/utils/responsive_helper.dart';
import 'verification_success_page.dart';

class PhoneVerificationPage extends StatefulWidget {
  final String phoneNumber;

  const PhoneVerificationPage({super.key, required this.phoneNumber});

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    bool allFilled =
        _controllers.every((controller) => controller.text.isNotEmpty);
    if (allFilled) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Get.off(
            () => const VerificationSuccessPage(),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 400),
          );
        }
      });
    }
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
      ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      Text(
                        'Verification',
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
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: -0.3, end: 0),

                      const SizedBox(height: 12),

                      Flexible(
                        child: Text(
                          'Enter the 6-digit code sent to\n${widget.phoneNumber}',
                          style: AppText.poppins(
                            color: const Color(0xFF64B5F6),
                            fontSize:
                                ResponsiveHelper.fontSize(context, mobile: 15),
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                      ),

                      const Spacer(),

                      // OTP Input
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          final boxSize =
                              ResponsiveHelper.isSmallScreen(context)
                                  ? 45.0
                                  : 50.0;
                          return Container(
                            width: boxSize,
                            height: boxSize * 1.2,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E5EC),
                              borderRadius: BorderRadius.circular(16),
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
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: AppText.poppins(
                                color: const Color(0xFF2C3E50),
                                fontSize: ResponsiveHelper.fontSize(context,
                                    mobile: 24),
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onChanged: (value) => _onChanged(value, index),
                            ),
                          )
                              .animate(delay: (index * 50).ms)
                              .fadeIn(duration: 400.ms)
                              .scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1, 1));
                        }),
                      ),

                      const SizedBox(height: 40),

                      // Resend Code
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Get.snackbar(
                              'Code Sent',
                              'A new verification code has been sent',
                              backgroundColor: const Color(0xFFE0E5EC),
                              colorText: const Color(0xFF2C3E50),
                              snackPosition: SnackPosition.TOP,
                            );
                          },
                          child: Text(
                            'Resend Code',
                            style: AppText.poppins(
                              color: const Color(0xFF64B5F6),
                              fontSize: ResponsiveHelper.fontSize(context,
                                  mobile: 16),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Verify Button
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
                            onTap: () {
                              bool allFilled = _controllers.every(
                                (controller) => controller.text.isNotEmpty,
                              );
                              if (allFilled) {
                                Get.off(
                                  () => const VerificationSuccessPage(),
                                  transition: Transition.fadeIn,
                                  duration: const Duration(milliseconds: 400),
                                );
                              } else {
                                Get.snackbar(
                                  'Incomplete Code',
                                  'Please enter all 6 digits',
                                  backgroundColor: const Color(0xFFE0E5EC),
                                  colorText: const Color(0xFF2C3E50),
                                  snackPosition: SnackPosition.TOP,
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Verify',
                                    style: AppText.poppins(
                                      fontSize: ResponsiveHelper.fontSize(
                                          context,
                                          mobile: 20),
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
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
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
