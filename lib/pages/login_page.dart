import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:g/utils/app_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/app_controller.dart';
import '../controllers/theme_controller.dart';
import '../services/biometric_auth_service.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final RxString _pin = ''.obs;
  final int _pinLength = 4;
  final BiometricAuthService _biometricService = BiometricAuthService();
  final RxBool _isBiometricAvailable = false.obs;
  final ThemeController _themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    // Delay biometric check to ensure Flutter engine is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkBiometric();
    });
  }

  Future<void> _checkBiometric() async {
    try {
      final available = await _biometricService.isBiometricAvailable();
      if (available) {
        final prefs = await SharedPreferences.getInstance();
        final isEnabled = prefs.getBool('biometric_enabled') ?? false;
        _isBiometricAvailable.value = isEnabled;
      } else {
        _isBiometricAvailable.value = false;
      }
    } catch (e) {
      print('Error checking biometric: $e');
      _isBiometricAvailable.value = false;
    }
  }

  Future<void> _authenticateWithBiometric() async {
    try {
      final authenticated = await _biometricService.authenticate(
        localizedReason: 'Authenticate to access your account',
        useErrorDialogs: true,
        stickyAuth: true,
      );

      if (authenticated) {
        final controller = Get.find<AppController>();
        Get.offAll(
          () => DashboardPage(
            userName: controller.userName.value.isNotEmpty
                ? controller.userName.value
                : 'User',
          ),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 300),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Authentication Failed',
        'Please try again or use PIN',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20),
        borderRadius: 16,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _onNumberPressed(String number) {
    if (_pin.value.length < _pinLength) {
      _pin.value += number;

      if (_pin.value.length == _pinLength) {
        final controller = Get.find<AppController>();

        // Validate PIN
        if (_pin.value == controller.pin.value) {
          // Correct PIN - navigate to dashboard
          Future.delayed(const Duration(milliseconds: 300), () {
            Get.offAll(
              () => DashboardPage(
                userName: controller.userName.value.isNotEmpty
                    ? controller.userName.value
                    : 'User',
              ),
              transition: Transition.fadeIn,
              duration: const Duration(milliseconds: 300),
            );
          });
        } else {
          // Incorrect PIN - show error and reset
          Future.delayed(const Duration(milliseconds: 300), () {
            Get.snackbar(
              'Incorrect PIN',
              'Please try again',
              backgroundColor: Colors.red.shade400,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              margin: const EdgeInsets.all(20),
              borderRadius: 16,
              duration: const Duration(seconds: 2),
            );
            _pin.value = ''; // Reset PIN input
          });
        }
      }
    }
  }

  void _onDeletePressed() {
    if (_pin.value.isNotEmpty) {
      _pin.value = _pin.value.substring(0, _pin.value.length - 1);
    }
  }

  Widget _buildNumberButton(
    String number,
    Color cardColor,
    Color textColor,
    bool isDark,
    double buttonSize,
    bool isSmallScreen,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNumberPressed(number),
        borderRadius: BorderRadius.circular(buttonSize / 2),
        splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: cardColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
              width: 1,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              number,
              style: AppText.poppins(
                color: textColor,
                fontSize: isSmallScreen ? 24 : 28,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    VoidCallback onTap,
    Color cardColor,
    Color iconColor,
    bool isDark,
    double buttonSize,
    bool isSmallScreen,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(buttonSize / 2),
        splashColor: iconColor.withOpacity(0.15),
        highlightColor: iconColor.withOpacity(0.08),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: cardColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
              width: 1,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
          ),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: isSmallScreen ? 26 : 30,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final theme = Theme.of(context);
      final isDark = _themeController.themeMode.value == ThemeMode.dark;
      final size = MediaQuery.of(context).size;
      final isSmallScreen = size.height < 700;

      final backgroundColor =
          isDark ? const Color(0xFF0F1419) : const Color(0xFFF8F9FA);
      final cardColor = isDark ? const Color(0xFF1C2128) : Colors.white;
      final textPrimary =
          isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1F2937);
      final textMuted =
          isDark ? const Color(0xFF8B949E) : const Color(0xFF6B7280);
      final accentColor = theme.colorScheme.primary;

      // Responsive sizing
      final iconSize = isSmallScreen ? 80.0 : 100.0;
      final titleSize = isSmallScreen ? 24.0 : 32.0;
      final buttonSize = isSmallScreen ? 64.0 : 75.0;
      final verticalPadding = isSmallScreen ? 16.0 : 32.0;

      return Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxWidth: 600,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.06,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Back Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Get.back(),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.black.withOpacity(0.05),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: textPrimary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: verticalPadding),

                          // Animated Logo/Icon
                          Container(
                            width: iconSize,
                            height: iconSize,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accentColor,
                                  accentColor.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.4),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.shield_rounded,
                              color: Colors.white,
                              size: iconSize * 0.5,
                            ),
                          )
                              .animate()
                              .scale(
                                duration: 800.ms,
                                curve: Curves.elasticOut,
                              )
                              .shimmer(duration: 1500.ms, delay: 600.ms),

                          SizedBox(height: verticalPadding * 0.75),

                          // Title
                          Text(
                            'Welcome Back',
                            style: AppText.poppins(
                              color: textPrimary,
                              fontSize: titleSize,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 500.ms, delay: 200.ms)
                              .slideY(begin: 0.3, end: 0),

                          const SizedBox(height: 8),

                          Text(
                            'Enter your PIN to continue',
                            style: AppText.poppins(
                              color: textMuted,
                              fontSize: isSmallScreen ? 14 : 15,
                              fontWeight: FontWeight.w400,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 500.ms, delay: 300.ms)
                              .slideY(begin: 0.3, end: 0),

                          SizedBox(height: verticalPadding * 1.2),

                          // PIN Display
                          Obx(() => Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children:
                                        List.generate(_pinLength, (index) {
                                      final isFilled =
                                          index < _pin.value.length;
                                      return AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        curve: Curves.easeOutCubic,
                                        width: isSmallScreen ? 18 : 20,
                                        height: isSmallScreen ? 18 : 20,
                                        margin: EdgeInsets.symmetric(
                                          horizontal: isSmallScreen ? 10 : 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isFilled
                                              ? accentColor
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isFilled
                                                ? accentColor
                                                : textMuted.withOpacity(0.3),
                                            width: 2.5,
                                          ),
                                          boxShadow: isFilled
                                              ? [
                                                  BoxShadow(
                                                    color: accentColor
                                                        .withOpacity(0.3),
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                              : [],
                                        ),
                                      )
                                          .animate(
                                            key: ValueKey('$index-$isFilled'),
                                          )
                                          .scale(
                                            duration: 200.ms,
                                            begin: const Offset(0.8, 0.8),
                                            end: const Offset(1, 1),
                                          );
                                    }),
                                  ))
                              .animate()
                              .fadeIn(duration: 500.ms, delay: 400.ms)
                              .slideY(begin: 0.2, end: 0),

                          const Spacer(),

                          // Number Keypad
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: isSmallScreen ? 320 : 380,
                            ),
                            child: Column(
                              children: [
                                _buildKeypadRow(
                                  ['1', '2', '3'],
                                  cardColor,
                                  textPrimary,
                                  isDark,
                                  buttonSize,
                                  isSmallScreen,
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                _buildKeypadRow(
                                  ['4', '5', '6'],
                                  cardColor,
                                  textPrimary,
                                  isDark,
                                  buttonSize,
                                  isSmallScreen,
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                _buildKeypadRow(
                                  ['7', '8', '9'],
                                  cardColor,
                                  textPrimary,
                                  isDark,
                                  buttonSize,
                                  isSmallScreen,
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Obx(() => _isBiometricAvailable.value
                                        ? _buildActionButton(
                                            Icons.fingerprint_rounded,
                                            _authenticateWithBiometric,
                                            cardColor,
                                            accentColor,
                                            isDark,
                                            buttonSize,
                                            isSmallScreen,
                                          )
                                        : SizedBox(
                                            width: buttonSize,
                                            height: buttonSize,
                                          )),
                                    _buildNumberButton(
                                      '0',
                                      cardColor,
                                      textPrimary,
                                      isDark,
                                      buttonSize,
                                      isSmallScreen,
                                    ),
                                    _buildActionButton(
                                      Icons.backspace_outlined,
                                      _onDeletePressed,
                                      cardColor,
                                      textMuted,
                                      isDark,
                                      buttonSize,
                                      isSmallScreen,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 500.ms, delay: 500.ms)
                              .slideY(begin: 0.3, end: 0),

                          SizedBox(height: verticalPadding * 0.75),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildKeypadRow(
    List<String> numbers,
    Color cardColor,
    Color textColor,
    bool isDark,
    double buttonSize,
    bool isSmallScreen,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers
          .map((num) => _buildNumberButton(
                num,
                cardColor,
                textColor,
                isDark,
                buttonSize,
                isSmallScreen,
              ))
          .toList(),
    );
  }
}
