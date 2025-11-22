import 'package:flutter/material.dart';
import 'package:g/utils/app_text.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../services/ocr_service.dart';
import '../controllers/app_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/receipt_model.dart';
import 'receipt_preview_page.dart';
import 'dart:io';

class _ScanPagePalette {
  _ScanPagePalette(ThemeData theme)
      : isDark = theme.brightness == Brightness.dark,
        background = theme.brightness == Brightness.dark
            ? const Color(0xFF0F1419)
            : const Color(0xFFF8F9FA),
        cardSurface = theme.brightness == Brightness.dark
            ? const Color(0xFF1C2128)
            : Colors.white,
        cardBorder = theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.06),
        textPrimary = theme.brightness == Brightness.dark
            ? const Color(0xFFE6EDF3)
            : const Color(0xFF1F2937),
        textSecondary = theme.brightness == Brightness.dark
            ? const Color(0xFF8B949E)
            : const Color(0xFF6B7280),
        accentBlue = theme.colorScheme.primary,
        accentGreen = const Color(0xFF10B981),
        scannerOverlay = theme.brightness == Brightness.dark
            ? Colors.black.withOpacity(0.7)
            : Colors.black.withOpacity(0.5);

  final bool isDark;
  final Color background;
  final Color cardSurface;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentBlue;
  final Color accentGreen;
  final Color scannerOverlay;
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final OCRService _ocrService = OCRService();
  final AppController controller = Get.find<AppController>();
  final ThemeController _themeController = Get.find<ThemeController>();
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
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      setState(() => isProcessing = false);
      Get.snackbar(
        'Error',
        'Failed to process image: ${e.toString()}',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ScanPagePalette(theme);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: BoxDecoration(
                color: palette.cardSurface,
                border: Border(
                  bottom: BorderSide(
                    color: palette.cardBorder,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: palette.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: palette.cardBorder,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: palette.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan Receipt',
                          style: AppText.poppins(
                            color: palette.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Upload or capture receipt image',
                          style: AppText.poppins(
                            color: palette.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
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
                          color: palette.cardSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: palette.cardBorder,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            children: [
                              // Background
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      palette.isDark
                                          ? const Color(0xFF1C2128)
                                          : const Color(0xFFF3F4F6),
                                      palette.isDark
                                          ? const Color(0xFF0F1419)
                                          : const Color(0xFFE5E7EB),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: palette.accentBlue
                                              .withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.receipt_long_rounded,
                                          size: 64,
                                          color: palette.accentBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'Upload Receipt Image',
                                        style: AppText.poppins(
                                          color: palette.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 40),
                                        child: Text(
                                          'Use camera or gallery to capture your receipt',
                                          style: AppText.poppins(
                                            color: palette.textSecondary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Scanning Frame Overlay
                              Center(
                                child: Container(
                                  width: 240,
                                  height: 240,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          palette.accentBlue.withOpacity(0.5),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Corner decorations
                                      Positioned(
                                        top: -2,
                                        left: -2,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: palette.accentBlue,
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(18),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: -2,
                                        right: -2,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: palette.accentBlue,
                                            borderRadius:
                                                const BorderRadius.only(
                                              topRight: Radius.circular(18),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: -2,
                                        left: -2,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: palette.accentBlue,
                                            borderRadius:
                                                const BorderRadius.only(
                                              bottomLeft: Radius.circular(18),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: -2,
                                        right: -2,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: palette.accentBlue,
                                            borderRadius:
                                                const BorderRadius.only(
                                              bottomRight: Radius.circular(18),
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
                                        color: palette.accentBlue
                                            .withOpacity(0.3)),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 100.ms, duration: 500.ms)
                          .scale(begin: const Offset(0.95, 0.95)),
                    ),

                    const SizedBox(height: 24),

                    // Upload buttons
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: isProcessing
                                  ? null
                                  : () =>
                                      _pickAndProcessImage(fromCamera: false),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: palette.cardSurface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: palette.cardBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: palette.accentBlue
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.photo_library_rounded,
                                        color: palette.accentBlue,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Gallery',
                                      style: AppText.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: isProcessing
                                  ? null
                                  : () =>
                                      _pickAndProcessImage(fromCamera: true),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      palette.accentGreen,
                                      palette.accentGreen.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          palette.accentGreen.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
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
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                    if (isProcessing) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: palette.cardSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: palette.cardBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  palette.accentBlue),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Processing receipt...',
                              style: AppText.poppins(
                                color: palette.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Extracting transaction details',
                              style: AppText.poppins(
                                color: palette.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(),
                    ],

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
