import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/app_controller.dart';
import '../services/otp_service.dart';
import '../services/google_sign_in_service.dart';
import '../utils/app_text.dart';
import 'login_page.dart';

/// Material 3 Palette for Forgot PIN Page
class _ForgotPinPalette {
  _ForgotPinPalette(ThemeData theme)
      : isDark = theme.brightness == Brightness.dark,
        background = theme.brightness == Brightness.dark
            ? const Color(0xFF0D1117)
            : const Color(0xFFFCFCFF),
        surfaceContainer = theme.brightness == Brightness.dark
            ? const Color(0xFF1C2128)
            : const Color(0xFFF3F3F6),
        cardSurface = theme.brightness == Brightness.dark
            ? const Color(0xFF1C2128)
            : Colors.white,
        cardBorder = theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        textPrimary = theme.colorScheme.onSurface,
        textSecondary = theme.brightness == Brightness.dark
            ? const Color(0xFF9CA3AF)
            : const Color(0xFF6B7280),
        primary = theme.brightness == Brightness.dark
            ? const Color(0xFF93C5FD)
            : const Color(0xFF2563EB),
        primaryContainer = theme.brightness == Brightness.dark
            ? const Color(0xFF1E3A5F)
            : const Color(0xFFDBEAFE),
        onPrimaryContainer = theme.brightness == Brightness.dark
            ? const Color(0xFFDBEAFE)
            : const Color(0xFF1E3A5F),
        surfaceContainerHighest = theme.brightness == Brightness.dark
            ? const Color(0xFF262C36)
            : const Color(0xFFEAEAED);

  final bool isDark;
  final Color background;
  final Color surfaceContainer;
  final Color cardSurface;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color surfaceContainerHighest;
}

class ForgotPinPage extends StatefulWidget {
  const ForgotPinPage({super.key});

  @override
  State<ForgotPinPage> createState() => _ForgotPinPageState();
}

class _ForgotPinPageState extends State<ForgotPinPage> {
  final AppController _controller = Get.find<AppController>();
  final OtpService _otpService = OtpService();
  final GoogleSignInService _googleSignInService = GoogleSignInService();

  int _currentStep = 1; // 1: Request OTP, 2: Verify OTP, 3: Set New PIN
  String _otp = '';
  String _newPin = '';
  String _confirmPin = '';
  bool _isLoading = false;
  String? _userEmail;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  void _loadUserEmail() {
    _userEmail = _googleSignInService.userEmail;
    _userId = _googleSignInService.currentUser?.uid;
    setState(() {});
  }

  Future<void> _requestOTP() async {
    if (_userEmail == null || _userId == null) {
      Get.snackbar(
        'Error',
        'Please sign in with Google first',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20),
        borderRadius: 16,
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _otpService.sendOTPToEmail(_userId!, _userEmail!);

    setState(() => _isLoading = false);

    if (success) {
      Get.snackbar(
        'OTP Sent',
        'Check your email for the verification code',
        backgroundColor: const Color(0xFF64B5F6),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20),
        borderRadius: 16,
        duration: const Duration(seconds: 5),
      );

      setState(() => _currentStep = 2);
    } else {
      Get.snackbar(
        'Error',
        'Failed to send OTP. Please try again.',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20),
        borderRadius: 16,
      );
    }
  }

  Future<void> _verifyOTP() async {
    if (_otp.length != 6) {
      Get.snackbar(
        'Invalid OTP',
        'Please enter the complete 6-digit code',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20),
        borderRadius: 16,
      );
      return;
    }

    setState(() => _isLoading = true);

    final isValid = await _otpService.verifyOTP(_userId!, _otp);

    setState(() => _isLoading = false);

    if (isValid) {
      Get.snackbar(
        'Verified',
        'OTP verified successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20),
        borderRadius: 16,
      );
      setState(() => _currentStep = 3);
    } else {
      Get.snackbar(
        'Invalid OTP',
        'The code you entered is incorrect or expired',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20),
        borderRadius: 16,
      );
      setState(() => _otp = '');
    }
  }

  Future<void> _setNewPin() async {
    if (_newPin.length != 4) {
      Get.snackbar(
        'Invalid PIN',
        'PIN must be exactly 4 digits',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20),
        borderRadius: 16,
      );
      return;
    }

    if (_newPin != _confirmPin) {
      Get.snackbar(
        'PIN Mismatch',
        'PINs do not match. Please try again.',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20),
        borderRadius: 16,
      );
      setState(() {
        _newPin = '';
        _confirmPin = '';
      });
      return;
    }

    setState(() => _isLoading = true);

    // Update PIN in controller (will sync to Firestore)
    _controller.setPin(_newPin);

    // Give Firestore a moment to update
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _isLoading = false);

    Get.snackbar(
      'Success',
      'Your PIN has been reset successfully',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(20),
      borderRadius: 16,
    );

    // Navigate back to login after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      Get.off(() => const LoginPage());
    });
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_currentStep == 2) {
        if (_otp.length < 6) {
          _otp += number;
          if (_otp.length == 6) {
            Future.delayed(const Duration(milliseconds: 300), _verifyOTP);
          }
        }
      } else if (_currentStep == 3) {
        if (_newPin.length < 4) {
          _newPin += number;
        } else if (_confirmPin.length < 4) {
          _confirmPin += number;
          if (_confirmPin.length == 4) {
            Future.delayed(const Duration(milliseconds: 300), _setNewPin);
          }
        }
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      if (_currentStep == 2) {
        if (_otp.isNotEmpty) {
          _otp = _otp.substring(0, _otp.length - 1);
        }
      } else if (_currentStep == 3) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else if (_newPin.isNotEmpty) {
          _newPin = _newPin.substring(0, _newPin.length - 1);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ForgotPinPalette(theme);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: palette.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Reset PIN',
          style: AppText.poppins(
            color: palette.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Step Indicator
              _buildStepIndicator(),

              const SizedBox(height: 40),

              // Content based on current step
              if (_currentStep == 1) _buildRequestOTPStep(),
              if (_currentStep == 2) _buildVerifyOTPStep(),
              if (_currentStep == 3) _buildSetNewPINStep(),

              const SizedBox(height: 40),

              // Number pad for steps 2 and 3
              if (_currentStep >= 2) _buildNumberPad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final theme = Theme.of(context);
    final palette = _ForgotPinPalette(theme);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle(1, 'Request', _currentStep >= 1),
        Container(
          width: 40,
          height: 2,
          color: _currentStep >= 2
              ? palette.primary
              : palette.surfaceContainerHighest,
        ),
        _buildStepCircle(2, 'Verify', _currentStep >= 2),
        Container(
          width: 40,
          height: 2,
          color: _currentStep >= 3
              ? palette.primary
              : palette.surfaceContainerHighest,
        ),
        _buildStepCircle(3, 'Reset', _currentStep >= 3),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label, bool isActive) {
    final theme = Theme.of(context);
    final palette = _ForgotPinPalette(theme);

    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? palette.primary : palette.surfaceContainerHighest,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: AppText.poppins(
                color: isActive ? Colors.white : palette.textSecondary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppText.poppins(
            color: isActive ? palette.textPrimary : palette.textSecondary,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    ).animate().fadeIn(delay: (step * 100).ms).scale();
  }

  Widget _buildRequestOTPStep() {
    final theme = Theme.of(context);
    final palette = _ForgotPinPalette(theme);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: palette.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.email_rounded,
            size: 64,
            color: palette.primary,
          ),
        ).animate().scale(duration: 400.ms),
        const SizedBox(height: 30),
        Text(
          'Forgot Your PIN?',
          style: AppText.poppins(
            color: palette.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 12),
        Text(
          'We\'ll send a verification code to your email',
          style: AppText.poppins(
            color: palette.textSecondary,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 20),
        if (_userEmail != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: palette.cardSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.primary),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.email_outlined, color: palette.primary),
                const SizedBox(width: 8),
                Text(
                  _userEmail!,
                  style: AppText.poppins(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 40),
        _isLoading
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
              )
            : _buildNeumorphicButton(
                'Send OTP',
                Icons.send_rounded,
                _requestOTP,
              ).animate().fadeIn(delay: 400.ms).scale(),
      ],
    );
  }

  Widget _buildVerifyOTPStep() {
    final theme = Theme.of(context);
    final palette = _ForgotPinPalette(theme);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: palette.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.lock_clock_rounded,
            size: 64,
            color: palette.primary,
          ),
        ).animate().scale(duration: 400.ms),
        const SizedBox(height: 30),
        Text(
          'Enter Verification Code',
          style: AppText.poppins(
            color: palette.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 12),
        Text(
          'We sent a 6-digit code to $_userEmail',
          style: AppText.poppins(
            color: palette.textSecondary,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 30),
        // OTP Display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final isFilled = index < _otp.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 45,
              height: 55,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color:
                    isFilled ? palette.primaryContainer : palette.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFilled ? palette.primary : palette.cardBorder,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  isFilled ? _otp[index] : '',
                  style: AppText.poppins(
                    color: palette.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 20),
        TextButton(
          onPressed: _requestOTP,
          child: Text(
            'Resend Code',
            style: AppText.poppins(
              color: palette.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetNewPINStep() {
    final theme = Theme.of(context);
    final palette = _ForgotPinPalette(theme);
    final isSettingNew = _newPin.length < 4;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: palette.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.lock_reset_rounded,
            size: 64,
            color: palette.primary,
          ),
        ).animate().scale(duration: 400.ms),
        const SizedBox(height: 30),
        Text(
          isSettingNew ? 'Set New PIN' : 'Confirm New PIN',
          style: AppText.poppins(
            color: palette.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 12),
        Text(
          isSettingNew
              ? 'Enter your new 4-digit PIN'
              : 'Re-enter your PIN to confirm',
          style: AppText.poppins(
            color: palette.textSecondary,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 30),
        // PIN Display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final currentPin = isSettingNew ? _newPin : _confirmPin;
            final isFilled = index < currentPin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 55,
              height: 55,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color:
                    isFilled ? palette.primaryContainer : palette.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFilled ? palette.primary : palette.cardBorder,
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isFilled ? palette.primary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        ).animate().fadeIn(delay: 300.ms),
        if (!isSettingNew) ...[
          const SizedBox(height: 20),
          Text(
            '${_newPin.length} / 4',
            style: AppText.poppins(
              color: palette.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberButton('1'),
            _buildNumberButton('2'),
            _buildNumberButton('3'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberButton('4'),
            _buildNumberButton('5'),
            _buildNumberButton('6'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberButton('7'),
            _buildNumberButton('8'),
            _buildNumberButton('9'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 70, height: 70),
            _buildNumberButton('0'),
            _buildDeleteButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number) {
    final theme = Theme.of(context);
    final palette = _ForgotPinPalette(theme);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNumberPressed(number),
        customBorder: const CircleBorder(),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.surfaceContainerHighest,
            boxShadow: [
              BoxShadow(
                color: palette.isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.04),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: AppText.poppins(
                color: palette.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    final theme = Theme.of(context);
    final palette = _ForgotPinPalette(theme);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onDeletePressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.surfaceContainerHighest,
            boxShadow: [
              BoxShadow(
                color: palette.isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.04),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              color: palette.textPrimary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicButton(
      String text, IconData icon, VoidCallback onPressed) {
    final theme = Theme.of(context);
    final palette = _ForgotPinPalette(theme);

    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: Icon(icon, size: 24),
      label: Text(
        text,
        style: AppText.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
