import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:g/utils/app_text.dart';
import 'package:g/utils/responsive_helper.dart';
import '../controllers/app_controller.dart';
import '../models/user_model.dart';
import 'dashboard_page.dart';

/// Material 3 Palette for Setup Page
class _SetupPalette {
  _SetupPalette(ThemeData theme)
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
            : const Color(0xFF1E3A5F);

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
}

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final AppController controller = Get.find<AppController>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _SetupPalette(theme);

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
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
                'Account Setup',
                style: AppText.poppins(
                  color: palette.textPrimary,
                  fontSize: ResponsiveHelper.fontSize(context, mobile: 20),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          centerTitle: true,
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          // Welcome message
                          _buildWelcomeSection(context)
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: -0.3, end: 0),
                          const SizedBox(height: 30),
                          Text(
                            'Personal Information',
                            style: AppText.poppins(
                              color: palette.textPrimary,
                              fontSize: ResponsiveHelper.fontSize(context,
                                  mobile: 24),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                              .animate(delay: 50.ms)
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: -0.3, end: 0),
                          const SizedBox(height: 12),
                          Text(
                            'This information helps us personalize your experience',
                            style: AppText.poppins(
                              color: palette.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
                          const SizedBox(height: 24),
                          _buildModernInput(
                            context: context,
                            label: 'First Name',
                            controller: firstNameController,
                            icon: Icons.person_outline,
                            hint: 'Enter your first name',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'First name is required';
                              }
                              if (value.trim().length < 2) {
                                return 'First name must be at least 2 characters';
                              }
                              return null;
                            },
                          )
                              .animate(delay: 150.ms)
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: -0.2, end: 0),
                          const SizedBox(height: 20),
                          _buildModernInput(
                            context: context,
                            label: 'Last Name',
                            controller: lastNameController,
                            icon: Icons.person_outline,
                            hint: 'Enter your last name',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Last name is required';
                              }
                              if (value.trim().length < 2) {
                                return 'Last name must be at least 2 characters';
                              }
                              return null;
                            },
                          )
                              .animate(delay: 200.ms)
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: -0.2, end: 0),
                          const SizedBox(height: 20),
                          _buildModernInput(
                            context: context,
                            label: 'Mobile Number (Optional)',
                            controller: phoneController,
                            icon: Icons.phone_outlined,
                            hint: 'e.g., 09123456789',
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (!RegExp(r'^[0-9]{11}$').hasMatch(value)) {
                                  return 'Please enter a valid 11-digit mobile number';
                                }
                              }
                              return null;
                            },
                          )
                              .animate(delay: 250.ms)
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: -0.2, end: 0),
                          const SizedBox(height: 40),
                          Text(
                            'Fee Configuration',
                            style: AppText.poppins(
                              color: palette.textPrimary,
                              fontSize: ResponsiveHelper.fontSize(context,
                                  mobile: 20),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                              .animate(delay: 300.ms)
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: -0.3, end: 0),
                          const SizedBox(height: 12),
                          Text(
                            'Define fee ranges for your cash transactions (Optional)',
                            style: AppText.poppins(
                              color: palette.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ).animate(delay: 350.ms).fadeIn(duration: 400.ms),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: palette.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: palette.primary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: palette.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Example: From ₱0 to ₱100 = ₱5 fee',
                                    style: AppText.poppins(
                                      color: palette.onPrimaryContainer,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate(delay: 380.ms).fadeIn(duration: 400.ms),
                          const SizedBox(height: 20),
                          Obx(() => Column(
                                children: List.generate(
                                  controller.feeRanges.length,
                                  (index) => _buildFeeRangeItem(index)
                                      .animate(delay: (400 + index * 100).ms)
                                      .fadeIn(duration: 400.ms)
                                      .slideX(begin: -0.2, end: 0),
                                ),
                              )),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () {
                              controller.addFeeRange(
                                  FeeRange(from: 0, to: 0, fee: 0));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: palette.cardSurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: palette.cardBorder),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: palette.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              palette.primary.withOpacity(0.4),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Add Fee Range',
                                    style: AppText.poppins(
                                      color: palette.primary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          GestureDetector(
                            onTap: _isLoading ? null : _handleCompleteSetup,
                            child: Container(
                              height: 68,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: _isLoading
                                    ? LinearGradient(
                                        colors: [
                                          palette.primary.withOpacity(0.5),
                                          palette.primary.withOpacity(0.3),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : LinearGradient(
                                        colors: [
                                          palette.primary,
                                          palette.primary.withOpacity(0.8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                boxShadow: [
                                  BoxShadow(
                                    color: palette.primary.withOpacity(0.4),
                                    offset: const Offset(0, 8),
                                    blurRadius: 24,
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap:
                                      _isLoading ? null : _handleCompleteSetup,
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Complete Setup',
                                                style: AppText.poppins(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.3),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          )
                              .animate(delay: 600.ms)
                              .fadeIn(duration: 500.ms)
                              .scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1, 1)),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _SetupPalette(theme);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.primary,
            palette.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withOpacity(0.3),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.waving_hand,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome!',
                  style: AppText.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Let\'s set up your account in just a few steps',
                  style: AppText.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCompleteSetup() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        'Incomplete Information',
        'Please fill in all required fields correctly',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fullName =
          '${firstNameController.text.trim()} ${lastNameController.text.trim()}';
      controller.setUserName(fullName);

      // Save phone number if provided
      if (phoneController.text.trim().isNotEmpty) {
        controller.setPhoneNumber(phoneController.text.trim());
      }

      // Save all user data to Firestore
      await controller.saveUserData();

      Get.offAll(
        () => DashboardPage(userName: fullName),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 500),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Error',
        'Failed to save your data. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    }
  }

  Widget _buildModernInput({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final palette = _SetupPalette(theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppText.poppins(
                color: palette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (validator == null)
              Text(
                ' (Optional)',
                style: AppText.poppins(
                  color: palette.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: palette.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.cardBorder),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: AppText.poppins(
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: palette.primary,
              ),
              border: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              hintText: hint ?? 'Enter $label',
              hintStyle: AppText.poppins(
                color: palette.textSecondary.withOpacity(0.6),
                fontSize: 16,
              ),
              errorStyle: AppText.poppins(
                color: Colors.redAccent,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeeRangeItem(int index) {
    final theme = Theme.of(context);
    final palette = _SetupPalette(theme);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Range ${index + 1}',
                style: AppText.poppins(
                  color: palette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (controller.feeRanges.length > 1)
                GestureDetector(
                  onTap: () => controller.removeFeeRange(index),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSmallNeuInput(
                  label: 'From',
                  value: controller.feeRanges[index].from.toString(),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      controller.updateFeeRange(
                          index,
                          FeeRange(
                            from: int.parse(value),
                            to: controller.feeRanges[index].to,
                            fee: controller.feeRanges[index].fee,
                          ));
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSmallNeuInput(
                  label: 'To',
                  value: controller.feeRanges[index].to.toString(),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      controller.updateFeeRange(
                          index,
                          FeeRange(
                            from: controller.feeRanges[index].from,
                            to: int.parse(value),
                            fee: controller.feeRanges[index].fee,
                          ));
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSmallNeuInput(
                  label: 'Fee',
                  value: controller.feeRanges[index].fee.toString(),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      controller.updateFeeRange(
                          index,
                          FeeRange(
                            from: controller.feeRanges[index].from,
                            to: controller.feeRanges[index].to,
                            fee: int.parse(value),
                          ));
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallNeuInput({
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    final theme = Theme.of(context);
    final palette = _SetupPalette(theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.poppins(
            color: palette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: palette.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.cardBorder),
          ),
          child: TextField(
            controller: TextEditingController(text: value),
            keyboardType: TextInputType.number,
            style: AppText.poppins(
              color: palette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 12,
              ),
              hintText: '0',
              hintStyle: AppText.poppins(
                color: palette.textSecondary.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
