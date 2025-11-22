import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/app_controller.dart';
import '../models/user_model.dart';
import '../utils/app_text.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FeeSettingsPage extends StatefulWidget {
  const FeeSettingsPage({super.key});

  @override
  State<FeeSettingsPage> createState() => _FeeSettingsPageState();
}

class _FeeSettingsPageState extends State<FeeSettingsPage> {
  final AppController controller = Get.find<AppController>();
  bool _isSaving = false;

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
        title: Text(
          'Fee Configuration',
          style: AppText.poppins(
            color: const Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E5EC),
                      borderRadius: BorderRadius.circular(20),
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
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF64B5F6).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: Color(0xFF64B5F6),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Set up fee ranges for money transfers. The fee will be automatically calculated based on the transaction amount.',
                            style: AppText.poppins(
                              color: const Color(0xFF2C3E50),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.2, end: 0),

                  const SizedBox(height: 30),

                  // Fee Ranges List
                  Obx(() => Column(
                        children: List.generate(
                          controller.feeRanges.length,
                          (index) => _buildFeeRangeCard(index)
                              .animate(delay: (index * 100).ms)
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: -0.2, end: 0),
                        ),
                      )),

                  const SizedBox(height: 20),

                  // Add Fee Range Button
                  GestureDetector(
                    onTap: () {
                      controller.addFeeRange(FeeRange(from: 0, to: 0, fee: 0));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E5EC),
                        borderRadius: BorderRadius.circular(16),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF64B5F6),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF64B5F6).withOpacity(0.4),
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
                              color: const Color(0xFF64B5F6),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 100), // Space for floating button
                ],
              ),
            ),
          ),

          // Save Button (Fixed at bottom)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E5EC),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              child: GestureDetector(
                onTap: _isSaving ? null : _saveFeeSettings,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64B5F6).withOpacity(0.4),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: AppText.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRangeCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E5EC),
        borderRadius: BorderRadius.circular(20),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Range ${index + 1}',
                style: AppText.poppins(
                  color: const Color(0xFF2C3E50),
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
                      color: const Color(0xFFE0E5EC),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.8),
                          offset: const Offset(-2, -2),
                          blurRadius: 4,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
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
                child: _buildInput(
                  label: 'From (₱)',
                  value: controller.feeRanges[index].from.toString(),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      controller.updateFeeRange(
                        index,
                        FeeRange(
                          from: int.parse(value),
                          to: controller.feeRanges[index].to,
                          fee: controller.feeRanges[index].fee,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInput(
                  label: 'To (₱)',
                  value: controller.feeRanges[index].to.toString(),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      controller.updateFeeRange(
                        index,
                        FeeRange(
                          from: controller.feeRanges[index].from,
                          to: int.parse(value),
                          fee: controller.feeRanges[index].fee,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInput(
                  label: 'Fee (₱)',
                  value: controller.feeRanges[index].fee.toString(),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      controller.updateFeeRange(
                        index,
                        FeeRange(
                          from: controller.feeRanges[index].from,
                          to: controller.feeRanges[index].to,
                          fee: int.parse(value),
                        ),
                      );
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

  Widget _buildInput({
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.poppins(
            color: const Color(0xFF2C3E50).withOpacity(0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE0E5EC),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                offset: const Offset(-2, -2),
                blurRadius: 6,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(2, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: TextFormField(
            initialValue: value,
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            style: AppText.poppins(
              color: const Color(0xFF2C3E50),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              hintText: '0',
              hintStyle: AppText.poppins(
                color: const Color(0xFF2C3E50).withOpacity(0.3),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveFeeSettings() async {
    // Validate fee ranges
    for (int i = 0; i < controller.feeRanges.length; i++) {
      final range = controller.feeRanges[i];
      if (range.from <= 0 || range.to <= 0 || range.fee < 0) {
        Get.snackbar(
          'Invalid Range',
          'Range ${i + 1}: Please enter valid values',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(20),
          borderRadius: 16,
        );
        return;
      }
      if (range.from >= range.to) {
        Get.snackbar(
          'Invalid Range',
          'Range ${i + 1}: "From" must be less than "To"',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(20),
          borderRadius: 16,
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await controller.saveUserData();

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        Get.snackbar(
          'Success',
          'Fee settings saved successfully!',
          backgroundColor: const Color(0xFF4CAF50),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(20),
          borderRadius: 16,
        );

        // Go back after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Get.back();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        Get.snackbar(
          'Error',
          'Failed to save fee settings: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(20),
          borderRadius: 16,
        );
      }
    }
  }
}
