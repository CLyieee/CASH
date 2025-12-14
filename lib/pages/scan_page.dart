import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:g/utils/app_text.dart';
import 'package:g/utils/responsive_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../services/ocr_service.dart';
import '../controllers/app_controller.dart';
import 'receipt_preview_page.dart';

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
  String? scannedCode;
  bool isProcessing = false;
  late _ScanPagePalette palette;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcessImage({bool fromCamera = false}) async {
    try {
      setState(() => isProcessing = true);

      // On web, only allow file upload (no camera)
      if (kIsWeb && fromCamera) {
        setState(() => isProcessing = false);
        Get.snackbar(
          'Camera Not Available',
          'Camera is not available on web. Please use file upload instead.',
          backgroundColor: const Color(0xFFFF9800),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Pick image - works on both mobile and web
      final imageFile = await _ocrService.pickImage(fromCamera: fromCamera);

      if (imageFile == null) {
        setState(() => isProcessing = false);
        return;
      }

      // On web, show message that we're using Gemini AI
      if (kIsWeb) {
        Get.snackbar(
          'Processing with AI',
          'Using Gemini AI to process receipt on web...',
          backgroundColor: palette.accentBlue,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 2),
        );
      }

      // Process receipt with OCR (or fallback to Gemini on web)
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

      // Check if it's a validation error
      final errorMessage = e.toString();
      final isValidationError =
          errorMessage.contains('does not appear to be a receipt');

      Get.snackbar(
        isValidationError ? 'Invalid Image' : 'Error',
        isValidationError
            ? 'Please upload a valid receipt or transaction image with visible text, amounts, and transaction details.'
            : 'Failed to process image: $errorMessage',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    palette = _ScanPagePalette(theme);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.cardSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: palette.textPrimary, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Scan Receipt',
          style: AppText.poppins(
            color: palette.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: isProcessing
            ? _buildProcessingView(palette)
            : _buildScanView(palette),
      ),
    );
  }

  Widget _buildProcessingView(_ScanPagePalette palette) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(palette.accentBlue),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Processing Receipt',
            style: AppText.poppins(
              color: palette.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Extracting transaction details...',
            style: AppText.poppins(
              color: palette.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      )
          .animate()
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.1, end: 0, duration: 300.ms),
    );
  }

  Widget _buildScanView(_ScanPagePalette palette) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.accentBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: palette.accentBlue.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.accentBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Tip',
                        style: AppText.poppins(
                          color: palette.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Capture a clear image of your money transfer receipt for best results',
                        style: AppText.poppins(
                          color: palette.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1, end: 0),

          const SizedBox(height: 24),

          // Web-specific info message
          if (kIsWeb)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: palette.accentBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: palette.accentBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'On web, receipts are processed using Gemini AI for best results',
                      style: AppText.poppins(
                        color: palette.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: 32),

          // Receipt Preview Container
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: palette.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: palette.cardBorder,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                // Dashed border effect
                Center(
                  child: Container(
                    width: 200,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: palette.accentBlue.withOpacity(0.3),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(
                        duration: 2000.ms,
                        color: palette.accentBlue.withOpacity(0.2),
                      ),
                ),
                // Center icon
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: palette.accentBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          size: 60,
                          color: palette.accentBlue,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Ready to Scan',
                        style: AppText.poppins(
                          color: palette.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Choose how you want to upload your receipt',
                          style: AppText.poppins(
                            color: palette.textSecondary,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 500.ms)
              .scale(begin: const Offset(0.9, 0.9)),

          const SizedBox(height: 32),

          // Camera Button (hidden on web)
          if (!kIsWeb)
            FilledButton.icon(
              onPressed: () => _pickAndProcessImage(fromCamera: true),
              icon: const Icon(Icons.camera_alt_rounded, size: 24),
              label: Text(
                'Take Photo',
                style: AppText.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: palette.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0),

          if (!kIsWeb) const SizedBox(height: 16),

          // Gallery/Upload Button
          FilledButton.icon(
            onPressed: () => _pickAndProcessImage(fromCamera: false),
            icon: Icon(
              kIsWeb ? Icons.upload_file_rounded : Icons.photo_library_rounded,
              size: 24,
            ),
            label: Text(
              kIsWeb ? 'Upload Receipt Image' : 'Choose from Gallery',
              style: AppText.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: palette.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),

          const SizedBox(height: 32),

          // Features Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: palette.accentBlue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'What We Extract',
                      style: AppText.poppins(
                        color: palette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(palette, 'Recipient name'),
                _buildFeatureItem(palette, 'Phone number'),
                _buildFeatureItem(palette, 'Amount sent'),
                _buildFeatureItem(palette, 'Transaction fee'),
                _buildFeatureItem(palette, 'Reference number'),
                _buildFeatureItem(palette, 'Date & time'),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(_ScanPagePalette palette, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: palette.accentGreen,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: AppText.poppins(
              color: palette.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
