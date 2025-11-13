import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:g/utils/app_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/app_controller.dart';
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

  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: () => _onNumberPressed(number),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE0E5EC),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              offset: const Offset(-4, -4),
              blurRadius: 10,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(4, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Text(
            number,
            style: AppText.poppins(
              color: const Color(0xFF2C3E50),
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _onDeletePressed,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE0E5EC),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              offset: const Offset(-4, -4),
              blurRadius: 10,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(4, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            color: Color(0xFF64B5F6),
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return GestureDetector(
      onTap: _authenticateWithBiometric,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE0E5EC),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              offset: const Offset(-4, -4),
              blurRadius: 10,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(4, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.fingerprint,
            color: Color(0xFF64B5F6),
            size: 32,
          ),
        ),
      ),
    );
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            children: [
              const SizedBox(height: 5),

              // Title
              Text(
                'Enter PIN',
                style: AppText.poppins(
                  color: const Color(0xFF2C3E50),
                  fontSize: 28,
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
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3, end: 0),

              const Spacer(),

              // Lock Icon
              Container(
                width: 80,
                height: 80,
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
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: const Color(0xFF64B5F6),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF64B5F6).withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 24),

              Text(
                'Enter your 4-digit PIN',
                style: AppText.poppins(
                  color: const Color(0xFF64B5F6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 24),

              // PIN Display
              Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pinLength, (index) {
                      return Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E5EC),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: index < _pin.value.length
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(4, 4),
                                    blurRadius: 8,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.7),
                                    offset: const Offset(-4, -4),
                                    blurRadius: 8,
                                  ),
                                ]
                              : [
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
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: index < _pin.value.length
                                  ? const Color(0xFF64B5F6)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }),
                  )),

              const Spacer(),

              // Number Keypad
              Column(
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
                      Obx(() => _isBiometricAvailable.value
                          ? _buildBiometricButton()
                          : const SizedBox(width: 70, height: 70)),
                      _buildNumberButton('0'),
                      _buildDeleteButton(),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
