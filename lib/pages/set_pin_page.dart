import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:g/utils/app_text.dart';
import 'package:g/utils/responsive_helper.dart';
import '../controllers/app_controller.dart';
import 'setup_page.dart';

class SetPinPage extends StatefulWidget {
  const SetPinPage({super.key});

  @override
  State<SetPinPage> createState() => _SetPinPageState();
}

class _SetPinPageState extends State<SetPinPage> {
  final AppController controller = Get.find<AppController>();
  String _pin = '';
  String _firstPin = '';
  bool _isConfirmingPin = false;
  final int _pinLength = 4;

  void _onNumberPressed(String number) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += number;
      });

      if (_pin.length == _pinLength) {
        if (!_isConfirmingPin) {
          // First PIN entered, move to confirmation
          Future.delayed(const Duration(milliseconds: 300), () {
            setState(() {
              _firstPin = _pin;
              _pin = '';
              _isConfirmingPin = true;
            });
          });
        } else {
          // Confirming PIN
          if (_pin == _firstPin) {
            // PINs match, save and proceed
            controller.setPin(_pin);

            Future.delayed(const Duration(milliseconds: 300), () {
              Get.off(
                () => const SetupPage(),
                transition: Transition.fadeIn,
                duration: const Duration(milliseconds: 400),
              );
            });
          } else {
            // PINs don't match, show error and reset
            Future.delayed(const Duration(milliseconds: 300), () {
              _showPinMismatchError();
              setState(() {
                _pin = '';
                _firstPin = '';
                _isConfirmingPin = false;
              });
            });
          }
        }
      }
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _showPinMismatchError() {
    Get.snackbar(
      'PIN Mismatch',
      'PINs do not match. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  Widget _buildNumberButton(
      String number, bool isSmallScreen, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final buttonSize = isSmallScreen ? 60.0 : 70.0;
    final cardSurface = isDark ? const Color(0xFF1A2332) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final textPrimary = theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: () => _onNumberPressed(number),
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cardSurface,
          border: Border.all(color: cardBorder),
        ),
        child: Center(
          child: Text(
            number,
            style: AppText.poppins(
              color: textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(bool isSmallScreen, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final buttonSize = isSmallScreen ? 60.0 : 70.0;
    final cardSurface = isDark ? const Color(0xFF1A2332) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final accentBlue =
        isDark ? const Color(0xFF5BA3E8) : const Color(0xFF64B5F6);

    return GestureDetector(
      onTap: _onDeletePressed,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cardSurface,
          border: Border.all(color: cardBorder),
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            color: accentBlue,
            size: 28,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textPrimary = theme.colorScheme.onSurface;
    final accentBlue =
        isDark ? const Color(0xFF5BA3E8) : const Color(0xFF64B5F6);

    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false, // Remove back button
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 26,
                  height: 26,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Create PIN',
                style: AppText.poppins(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = ResponsiveHelper.isSmallScreen(context);
              final horizontalPadding =
                  ResponsiveHelper.horizontalPadding(context);

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isSmallScreen ? 8.0 : 10.0,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 20,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        SizedBox(height: isSmallScreen ? 2 : 5),
                        Text(
                          _isConfirmingPin ? 'Confirm PIN' : 'Create PIN',
                          style: AppText.poppins(
                            color: textPrimary,
                            fontSize: isSmallScreen ? 24 : 28,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: -0.3, end: 0),
                        const Spacer(),
                        Container(
                          width: isSmallScreen ? 70 : 80,
                          height: isSmallScreen ? 70 : 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      const Color(0xFF5BA3E8),
                                      const Color(0xFF4A8FD4)
                                    ]
                                  : [
                                      const Color(0xFF64B5F6),
                                      const Color(0xFF42A5F5)
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accentBlue.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.pin_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        )
                            .animate()
                            .scale(duration: 600.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 24),
                        Text(
                          _isConfirmingPin
                              ? 'Re-enter your PIN to confirm'
                              : 'Set up your 4-digit PIN',
                          style: AppText.poppins(
                            color: accentBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_pinLength, (index) {
                            final dotSize = isSmallScreen ? 44.0 : 50.0;
                            final cardSurface =
                                isDark ? const Color(0xFF1A2332) : Colors.white;
                            final cardBorder = isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.06);

                            return Container(
                              width: dotSize,
                              height: dotSize,
                              margin: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 6 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: cardSurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: index < _pin.length
                                      ? accentBlue
                                      : cardBorder,
                                  width: index < _pin.length ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: index < _pin.length
                                        ? accentBlue
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const Spacer(),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton('1', isSmallScreen, context),
                                _buildNumberButton('2', isSmallScreen, context),
                                _buildNumberButton('3', isSmallScreen, context),
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton('4', isSmallScreen, context),
                                _buildNumberButton('5', isSmallScreen, context),
                                _buildNumberButton('6', isSmallScreen, context),
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton('7', isSmallScreen, context),
                                _buildNumberButton('8', isSmallScreen, context),
                                _buildNumberButton('9', isSmallScreen, context),
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                SizedBox(
                                  width: isSmallScreen ? 60 : 70,
                                  height: isSmallScreen ? 60 : 70,
                                ),
                                _buildNumberButton('0', isSmallScreen, context),
                                _buildDeleteButton(isSmallScreen, context),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 20),
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
}
