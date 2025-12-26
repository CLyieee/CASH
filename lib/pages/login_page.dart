import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:g/utils/app_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/app_controller.dart';
import '../services/biometric_auth_service.dart';
import '../services/google_sign_in_service.dart';
import 'dashboard_page.dart';
import 'login_selection_page.dart';
import 'forgot_pin_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final RxString _pin = ''.obs;
  final int _pinLength = 4;
  final BiometricAuthService _biometricService = BiometricAuthService();
  final GoogleSignInService _googleSignInService = GoogleSignInService();
  final RxBool _isBiometricAvailable = false.obs;
  final Rx<String?> _userEmail = Rx<String?>(null);
  final Rx<String?> _userName = Rx<String?>(null);

  @override
  void initState() {
    super.initState();
    _loadGoogleAccountInfo();
    // Delay biometric check to ensure Flutter engine is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkBiometric();
    });
  }

  void _loadGoogleAccountInfo() {
    final controller = Get.find<AppController>();
    // Get email from Firebase/Google Sign-In service
    _userEmail.value = _googleSignInService.userEmail;
    _userName.value = controller.userName.value;
  }

  Future<void> _changeGoogleAccount() async {
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

      // Sign in with Google and show account picker
      final userCredential =
          await _googleSignInService.signInWithGoogle(forceAccountPicker: true);

      // Close loading dialog
      Get.back();

      if (userCredential != null && userCredential.user != null) {
        final controller = Get.find<AppController>();
        final user = userCredential.user!;

        // Load user data from Firestore
        await controller.loadUserData(user.uid);

        // Check if user has completed setup (has PIN set)
        final hasPin = controller.pin.value.isNotEmpty;

        if (hasPin) {
          // Update the displayed account info
          _loadGoogleAccountInfo();

          Get.snackbar(
            'Account Changed',
            'Now enter your PIN to continue',
            backgroundColor: const Color(0xFF64B5F6),
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(20),
            borderRadius: 16,
            duration: const Duration(seconds: 2),
          );
        } else {
          // No PIN - this account needs setup
          Get.snackbar(
            'Account Not Set Up',
            'This account needs to complete setup first',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(20),
            borderRadius: 16,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        'Error',
        'Failed to change account: ${e.toString()}',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20),
        borderRadius: 16,
        duration: const Duration(seconds: 3),
      );
    }
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
    double buttonSize,
    bool isSmallScreen,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNumberPressed(number),
        borderRadius: BorderRadius.circular(buttonSize / 2),
        splashColor: Colors.white.withOpacity(0.2),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: cardColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                offset: const Offset(0, 4),
                blurRadius: 12,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                offset: const Offset(0, -2),
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
    double buttonSize,
    bool isSmallScreen,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(buttonSize / 2),
        splashColor: Colors.white.withOpacity(0.2),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: cardColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                offset: const Offset(0, 4),
                blurRadius: 12,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                offset: const Offset(0, -2),
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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final isNarrowScreen = size.width < 380;

    final backgroundColor = Colors.transparent;
    final cardColor = Colors.white.withOpacity(0.15);
    final textPrimary = Colors.white;
    final textMuted = Colors.white.withOpacity(0.7);
    final accentColor = const Color(0xFF64B5F6);

    // Responsive sizing
    final iconSize = isNarrowScreen
        ? 70.0
        : isSmallScreen
            ? 80.0
            : 100.0;
    final titleSize = isNarrowScreen
        ? 22.0
        : isSmallScreen
            ? 24.0
            : 32.0;
    final buttonSize = isNarrowScreen
        ? 56.0
        : isSmallScreen
            ? 64.0
            : 75.0;
    final verticalPadding = isNarrowScreen
        ? 12.0
        : isSmallScreen
            ? 16.0
            : 32.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/space_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate adaptive spacing based on screen height
              final availableHeight = constraints.maxHeight;
              final adaptiveSpacing =
                  availableHeight < 650 ? 8.0 : verticalPadding * 0.75;
              final adaptiveVerticalPadding =
                  availableHeight < 650 ? 8.0 : (isNarrowScreen ? 12.0 : 16.0);

              final displayIconSize =
                  availableHeight < 650 ? iconSize * 0.8 : iconSize;
              final displayTitleSize = availableHeight < 650
                  ? (titleSize > 20 ? titleSize - 2 : titleSize)
                  : titleSize;

              final keypadMaxWidth = isNarrowScreen
                  ? 280.0
                  : isSmallScreen
                      ? 320.0
                      : 380.0;
              final keypadGap = isNarrowScreen
                  ? 10.0
                  : isSmallScreen
                      ? 12.0
                      : 16.0;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isNarrowScreen ? 16 : size.width * 0.06,
                      vertical: adaptiveVerticalPadding,
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
                              onTap: () {
                                Get.offAll(
                                  () => const LoginSelectionPage(),
                                  transition: Transition.fadeIn,
                                  duration: const Duration(milliseconds: 300),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.08),
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

                        SizedBox(
                            height:
                                availableHeight < 650 ? 8 : verticalPadding),

                        // Google Account Selector
                        Obx(() => _userEmail.value != null
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.08),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      offset: const Offset(0, 2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.g_mobiledata_rounded,
                                        color: accentColor,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _userName.value ?? 'User',
                                            style: AppText.poppins(
                                              color: textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _userEmail.value ?? '',
                                            style: AppText.poppins(
                                              color: textMuted,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _changeGoogleAccount,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accentColor.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color:
                                                  accentColor.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Change',
                                                style: AppText.poppins(
                                                  color: accentColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.swap_horiz_rounded,
                                                color: accentColor,
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                .animate()
                                .fadeIn(duration: 500.ms, delay: 100.ms)
                                .slideY(begin: -0.2, end: 0)
                            : const SizedBox.shrink()),

                        SizedBox(height: adaptiveSpacing),

                        // Animated Logo/Icon
                        Container(
                          width: displayIconSize,
                          height: displayIconSize,
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
                            size: displayIconSize * 0.5,
                          ),
                        )
                            .animate()
                            .scale(
                              duration: 800.ms,
                              curve: Curves.elasticOut,
                            )
                            .shimmer(duration: 1500.ms, delay: 600.ms),

                        SizedBox(height: adaptiveSpacing),

                        Text(
                          'Welcome Back',
                          style: AppText.poppins(
                            color: textPrimary,
                            fontSize: displayTitleSize,
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
                            fontSize: isNarrowScreen
                                ? 13
                                : isSmallScreen
                                    ? 14
                                    : 15,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 300.ms)
                            .slideY(begin: 0.3, end: 0),

                        SizedBox(
                            height: availableHeight < 650
                                ? 10
                                : verticalPadding * 0.9),

                        // PIN Display
                        Obx(
                          () => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_pinLength, (index) {
                              final isFilled = index < _pin.value.length;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                width: isNarrowScreen
                                    ? 16
                                    : isSmallScreen
                                        ? 18
                                        : 20,
                                height: isNarrowScreen
                                    ? 16
                                    : isSmallScreen
                                        ? 18
                                        : 20,
                                margin: EdgeInsets.symmetric(
                                  horizontal: isNarrowScreen
                                      ? 8
                                      : isSmallScreen
                                          ? 10
                                          : 14,
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
                                            color: accentColor.withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : [],
                                ),
                              )
                                  .animate(key: ValueKey('$index-$isFilled'))
                                  .scale(
                                    duration: 200.ms,
                                    begin: const Offset(0.8, 0.8),
                                    end: const Offset(1, 1),
                                  );
                            }),
                          )
                              .animate()
                              .fadeIn(duration: 500.ms, delay: 400.ms)
                              .slideY(begin: 0.2, end: 0),
                        ),

                        SizedBox(
                            height: availableHeight < 650
                                ? 6
                                : verticalPadding * 0.4),

                        TextButton(
                          onPressed: () {
                            Get.to(
                              () => const ForgotPinPage(),
                              transition: Transition.fadeIn,
                              duration: const Duration(milliseconds: 300),
                            );
                          },
                          child: Text(
                            'Forgot PIN?',
                            style: AppText.poppins(
                              color: accentColor,
                              fontSize: isSmallScreen ? 13 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 450.ms)
                            .slideY(begin: 0.2, end: 0),

                        // Keypad takes remaining space and scales down if needed
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.bottomCenter,
                              child: SizedBox(
                                width: keypadMaxWidth,
                                child: Column(
                                  children: [
                                    _buildKeypadRow(
                                      ['1', '2', '3'],
                                      cardColor,
                                      textPrimary,
                                      buttonSize,
                                      isSmallScreen,
                                    ),
                                    SizedBox(height: keypadGap),
                                    _buildKeypadRow(
                                      ['4', '5', '6'],
                                      cardColor,
                                      textPrimary,
                                      buttonSize,
                                      isSmallScreen,
                                    ),
                                    SizedBox(height: keypadGap),
                                    _buildKeypadRow(
                                      ['7', '8', '9'],
                                      cardColor,
                                      textPrimary,
                                      buttonSize,
                                      isSmallScreen,
                                    ),
                                    SizedBox(height: keypadGap),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Obx(
                                          () => _isBiometricAvailable.value
                                              ? _buildActionButton(
                                                  Icons.fingerprint_rounded,
                                                  _authenticateWithBiometric,
                                                  cardColor,
                                                  accentColor,
                                                  buttonSize,
                                                  isSmallScreen,
                                                )
                                              : SizedBox(
                                                  width: buttonSize,
                                                  height: buttonSize,
                                                ),
                                        ),
                                        _buildNumberButton(
                                          '0',
                                          cardColor,
                                          textPrimary,
                                          buttonSize,
                                          isSmallScreen,
                                        ),
                                        _buildActionButton(
                                          Icons.backspace_outlined,
                                          _onDeletePressed,
                                          cardColor,
                                          textMuted,
                                          buttonSize,
                                          isSmallScreen,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 500.ms, delay: 500.ms)
                                .slideY(begin: 0.3, end: 0),
                          ),
                        ),
                        SizedBox(
                            height:
                                availableHeight < 650 ? 4 : adaptiveSpacing),
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

  Widget _buildKeypadRow(
    List<String> numbers,
    Color cardColor,
    Color textColor,
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
                buttonSize,
                isSmallScreen,
              ))
          .toList(),
    );
  }
}
