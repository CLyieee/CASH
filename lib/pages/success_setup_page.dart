import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:g/utils/responsive_helper.dart';
import 'login_selection_page.dart';

class SuccessSetupPage extends StatelessWidget {
  const SuccessSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0066FF),
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
                    children: [
                      const Spacer(),

                      // Success Title with animation
                      TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Text(
                                'Successfully Created',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: ResponsiveHelper.fontSize(context,
                                      mobile: 24),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      Flexible(
                        child: Text(
                          'Your account has been created successfully.\nYou can now login to your account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize:
                                ResponsiveHelper.fontSize(context, mobile: 14),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => Get.offAll(
                            () => const LoginSelectionPage(),
                            transition: Transition.fadeIn,
                            duration: const Duration(milliseconds: 300),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0066FF),
                          ),
                          child: Text(
                            'Go to Login',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.fontSize(context,
                                  mobile: 16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
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
