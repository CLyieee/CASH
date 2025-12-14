import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:g/utils/app_text.dart';
import 'package:g/utils/responsive_helper.dart';
import 'login_selection_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = ResponsiveHelper.isSmallScreen(context);
              final horizontalPadding =
                  ResponsiveHelper.horizontalPadding(context);
              final verticalPadding = ResponsiveHelper.verticalPadding(context);

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
                      children: [
                        const Spacer(flex: 2),

                        // App Logo
                        Container(
                          width: isSmallScreen ? 120 : 160,
                          height: isSmallScreen ? 120 : 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF64B5F6).withOpacity(0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.asset(
                              'assets/icon/app_icon.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                            .animate()
                            .scale(
                              duration: 800.ms,
                              curve: Curves.elasticOut,
                            )
                            .fade(duration: 600.ms),

                        const SizedBox(height: 50),

                        // App Name with Gradient
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFF64B5F6),
                              Color(0xFF42A5F5),
                              Color(0xFF2196F3),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'GCASH CATALOG',
                            style: AppText.poppins(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 28 : 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 300.ms)
                            .slideY(
                                begin: 0.3,
                                end: 0,
                                duration: 800.ms,
                                delay: 300.ms),

                        const SizedBox(height: 16),

                        // Tagline
                        Text(
                          'Track, Scan & Manage',
                          textAlign: TextAlign.center,
                          style: AppText.poppins(
                            color: const Color(0xFF4B5563),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 500.ms)
                            .slideY(
                                begin: 0.3,
                                end: 0,
                                duration: 800.ms,
                                delay: 500.ms),

                        const SizedBox(height: 12),

                        // Description
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Your all-in-one solution for instant transaction logging and intelligent reporting',
                            textAlign: TextAlign.center,
                            style: AppText.poppins(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 14,
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 700.ms)
                            .slideY(
                                begin: 0.3,
                                end: 0,
                                duration: 800.ms,
                                delay: 700.ms),

                        const Spacer(flex: 3),

                        // Features Pills
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildFeaturePill(
                                '📸 OCR Scan', const Color(0xFF10B981)),
                            _buildFeaturePill(
                                '🤖 AI Powered', const Color(0xFF8B5CF6)),
                            _buildFeaturePill(
                                '📊 Analytics', const Color(0xFFF59E0B)),
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 900.ms)
                            .slideY(
                                begin: 0.3,
                                end: 0,
                                duration: 800.ms,
                                delay: 900.ms),

                        const SizedBox(height: 40),

                        // Get Started Button
                        Container(
                          width: double.infinity,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF64B5F6),
                                Color(0xFF42A5F5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF64B5F6).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Get.to(
                                () => const LoginSelectionPage(),
                                transition: Transition.fadeIn,
                                duration: const Duration(milliseconds: 400),
                              ),
                              borderRadius: BorderRadius.circular(20),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Get Started',
                                      style: AppText.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 1100.ms)
                            .slideY(
                                begin: 0.3,
                                end: 0,
                                duration: 800.ms,
                                delay: 1100.ms)
                            .shimmer(
                              duration: 2000.ms,
                              delay: 1500.ms,
                              color: Colors.white.withOpacity(0.3),
                            ),

                        const SizedBox(height: 20),

                        // Version Info
                        Text(
                          'Version 1.0.0',
                          style: AppText.poppins(
                            color: const Color(0xFFD1D5DB),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ).animate().fadeIn(duration: 800.ms, delay: 1300.ms),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: AppText.poppins(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
