import 'package:flutter/material.dart';
import 'package:g/utils/app_text.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../services/ocr_service.dart';
import '../controllers/app_controller.dart';
import '../models/receipt_model.dart';
import 'receipt_preview_page.dart';
import 'dart:io';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final OCRService _ocrService = OCRService();
  final AppController controller = Get.find<AppController>();
  String? scannedCode;
  bool isProcessing = false;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcessImage({bool fromCamera = false}) async {
    try {
      setState(() => isProcessing = true);

      // Pick image
      final imageFile = await _ocrService.pickImage(fromCamera: fromCamera);

      if (imageFile == null) {
        setState(() => isProcessing = false);
        return;
      }

      // Process receipt with OCR
      final receipt = await _ocrService.processReceipt(
        imageFile,
        controller.feeRanges.toList(),
      );

      setState(() => isProcessing = false);

      if (receipt != null) {
        // Navigate to receipt preview page
        Get.to(
          () => ReceiptPreviewPage(receipt: receipt, imageFile: imageFile),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 300),
        );
      } else {
        Get.snackbar(
          'Scan Failed',
          'Could not extract receipt information. Please try again.',
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(20),
          borderRadius: 16,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      setState(() => isProcessing = false);
      Get.snackbar(
        'Error',
        'Failed to process image: ${e.toString()}',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20),
        borderRadius: 16,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E5EC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
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

                  Text(
                    'Scan QR Code',
                    style: AppText.poppins(
                      color: const Color(0xFF2C3E50),
                      fontSize: 20,
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
                  ),

                  const SizedBox(width: 48), // Balance for back button
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3, end: 0),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Scanner Container
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E5EC),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(6, 6),
                              blurRadius: 12,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.7),
                              offset: const Offset(-6, -6),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            children: [
                              // Scanner temporarily disabled (mobile_scanner removed)
                              Container(
                                color: Colors.black12,
                                child: Center(
                                  child: Text(
                                    'Scanner temporarily disabled',
                                    style: AppText.poppins(
                                      color: const Color(0xFF2C3E50),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              // Scanning Frame Overlay
                              Center(
                                child: Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFF64B5F6),
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Corner decorations
                                      Positioned(
                                        top: -3,
                                        left: -3,
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF64B5F6),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(17),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: -3,
                                        right: -3,
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF64B5F6),
                                            borderRadius: BorderRadius.only(
                                              topRight: Radius.circular(17),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: -3,
                                        left: -3,
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF64B5F6),
                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(17),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: -3,
                                        right: -3,
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF64B5F6),
                                            borderRadius: BorderRadius.only(
                                              bottomRight: Radius.circular(17),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                    .animate(
                                        onPlay: (controller) =>
                                            controller.repeat())
                                    .shimmer(
                                        duration: 2000.ms,
                                        color: const Color(0xFF64B5F6)
                                            .withOpacity(0.3)),
                              ),

                              // Instructions
                              Positioned(
                                bottom: 40,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Align QR code within frame',
                                      style: AppText.poppins(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 500.ms)
                          .scale(begin: const Offset(0.9, 0.9)),
                    ),

                    const SizedBox(height: 30),

                    // Upload buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: isProcessing
                                ? null
                                : () => _pickAndProcessImage(fromCamera: false),
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E5EC),
                                borderRadius: BorderRadius.circular(16),
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
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF64B5F6),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF64B5F6)
                                              .withOpacity(0.4),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.photo_library_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Gallery',
                                    style: AppText.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2C3E50),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: isProcessing
                                ? null
                                : () => _pickAndProcessImage(fromCamera: true),
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E5EC),
                                borderRadius: BorderRadius.circular(16),
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
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF4CAF50)
                                              .withOpacity(0.4),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Camera',
                                    style: AppText.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2C3E50),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

                    if (isProcessing) ...[
                      const SizedBox(height: 24),
                      Column(
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF64B5F6)),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Processing receipt...',
                            style: AppText.poppins(
                              color: const Color(0xFF64B5F6),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(),
                    ],

                    const SizedBox(height: 20),

                    // Flash button hidden (no camera active)

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
