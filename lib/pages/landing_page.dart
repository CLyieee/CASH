import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:g/utils/responsive_helper.dart';
import 'login_selection_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/space_background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = MediaQuery.sizeOf(context);
                final horizontalPadding =
                    ResponsiveHelper.horizontalPadding(context);
                final verticalPadding =
                    ResponsiveHelper.verticalPadding(context);
                final isSmallScreen = ResponsiveHelper.isSmallScreen(context);

                // Keep button width responsive but capped.
                final buttonMaxWidth =
                    (constraints.maxWidth * 0.86).clamp(260.0, 360.0);
                final buttonHeight = isSmallScreen ? 48.0 : 56.0;

                // Responsive vertical spacing so the layout fits on short screens.
                final bottomGap =
                    (constraints.maxHeight * 0.10).clamp(16.0, 80.0);

                // Biased downward placement (like a hero CTA).
                final topSpacerMin =
                    (constraints.maxHeight * 0.80).clamp(220.0, 680.0);

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - verticalPadding * 2,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: topSpacerMin),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: buttonMaxWidth),
                          child: SizedBox(
                            width: double.infinity,
                            height: buttonHeight,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Get.to(
                                  () => const LoginSelectionPage(),
                                  transition: Transition.fadeIn,
                                  duration: const Duration(milliseconds: 350),
                                ),
                                borderRadius: BorderRadius.circular(999),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        colorScheme.surfaceContainerHighest,
                                        colorScheme.primaryContainer,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.shadowColor.withOpacity(
                                            isSmallScreen ? 0.20 : 0.25),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Get Started',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 650.ms, delay: 250.ms)
                            .slideY(
                              begin: 0.10,
                              end: 0,
                              duration: 650.ms,
                              delay: 250.ms,
                            ),
                        SizedBox(height: bottomGap),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
