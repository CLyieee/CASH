import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/gemini_service.dart';
import '../services/ocr_service.dart';
import '../services/notification_service.dart';
import '../controllers/app_controller.dart';
import '../models/receipt_model.dart';
import 'receipt_preview_page.dart';
import 'package:g/utils/responsive_helper.dart';
import 'package:g/utils/app_text.dart';

class _EnhancedScanPagePalette {
  _EnhancedScanPagePalette(ThemeData theme)
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
        accentGreen = const Color(0xFF10B981);

  final bool isDark;
  final Color background;
  final Color cardSurface;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentBlue;
  final Color accentGreen;
}

/// Enhanced Scan Page - Uses BOTH Google ML Kit OCR and Gemini AI
/// Falls back to OCR if Gemini fails (OCR only works on mobile, not web)
class EnhancedScanPage extends StatefulWidget {
  const EnhancedScanPage({super.key});

  @override
  State<EnhancedScanPage> createState() => _EnhancedScanPageState();
}

class _EnhancedScanPageState extends State<EnhancedScanPage> {
  final GeminiService _geminiService = GeminiService();
  final OCRService _ocrService = OCRService();
  final AppController controller = Get.find<AppController>();
  final ImagePicker _picker = ImagePicker();

  bool isProcessing = false;
  String processingStatus = '';
  bool useGemini = true; // Toggle between Gemini AI and traditional OCR

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcessImage({bool fromCamera = false}) async {
    try {
      setState(() {
        isProcessing = true;
        processingStatus = 'Selecting image...';
      });

      // Pick image
      final XFile? image = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() => isProcessing = false);
        return;
      }

      final imageFile = File(image.path);
      ReceiptModel? receipt;

      if (useGemini) {
        // Try Gemini AI first
        setState(() => processingStatus = 'Analyzing with Gemini AI...');
        receipt = await _geminiService.processReceipt(
          imageFile,
          controller.feeRanges.toList(),
        );

        // If Gemini fails, fallback to traditional OCR (only on mobile)
        if (receipt == null && !kIsWeb) {
          setState(() => processingStatus = 'Gemini failed, trying OCR...');
          receipt = await _ocrService.processReceipt(
            imageFile,
            controller.feeRanges.toList(),
          );
        }
      } else {
        // Use traditional OCR (only works on mobile)
        if (kIsWeb) {
          _showError(
            'OCR Not Available',
            'OCR is only available on mobile devices. Please use Gemini AI mode instead.',
          );
          setState(() => isProcessing = false);
          return;
        }
        setState(() => processingStatus = 'Processing with OCR...');
        receipt = await _ocrService.processReceipt(
          imageFile,
          controller.feeRanges.toList(),
        );
      }

      setState(() => isProcessing = false);

      if (receipt != null) {
        // Navigate to receipt preview page
        Get.to(
          () => ReceiptPreviewPage(receipt: receipt!, imageFile: imageFile),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 300),
        );
      } else {
        _showError(
          'Scan Failed',
          'Could not extract receipt information. Please try again with a clearer image.',
        );
      }
    } catch (e) {
      setState(() => isProcessing = false);
      _showError('Error', 'Failed to process image: ${e.toString()}');
    }
  }

  void _showError(String title, String message) {
    NotificationService.showError(
      message,
      title: title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _EnhancedScanPagePalette(Theme.of(context));

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(
          'Scan Receipt',
          style: AppText.poppins(
            color: palette.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: palette.cardSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: palette.textPrimary),
          onPressed: () => Get.back(),
        ),
        actions: [
          // Toggle between Gemini and OCR
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                Text(
                  useGemini ? 'AI' : 'OCR',
                  style: AppText.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        useGemini ? palette.accentBlue : palette.textSecondary,
                  ),
                ),
                Switch(
                  value: useGemini,
                  onChanged: (value) {
                    setState(() => useGemini = value);
                  },
                  activeColor: palette.accentBlue,
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isProcessing
            ? _buildProcessingView(palette)
            : _buildScanOptions(palette),
      ),
    );
  }

  Widget _buildProcessingView(palette) {
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
          const SizedBox(height: 24),
          Text(
            processingStatus,
            style: AppText.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: palette.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds...',
            style: AppText.poppins(
              fontSize: 14,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOptions(palette) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveHelper.horizontalPadding(context)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Icon(
            Icons.document_scanner_rounded,
            size: ResponsiveHelper.iconSize(context, base: 100),
            color: palette.accentBlue,
          ),
          SizedBox(height: ResponsiveHelper.spacing(context, mobile: 24)),

          // Title
          Text(
            'Scan Money Transfer Receipt',
            textAlign: TextAlign.center,
            style: AppText.poppins(
              fontSize: ResponsiveHelper.fontSize(context, mobile: 24),
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          SizedBox(height: ResponsiveHelper.spacing(context, mobile: 12)),

          // Description
          Text(
            'Take a photo or select an image of your GCash, Palawan, or other money transfer receipt',
            textAlign: TextAlign.center,
            style: AppText.poppins(
              fontSize: ResponsiveHelper.fontSize(context, mobile: 14),
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // AI Badge
          if (useGemini)
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: palette.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: palette.accentBlue),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 16, color: palette.accentBlue),
                    const SizedBox(width: 4),
                    Text(
                      'Enhanced with Gemini AI',
                      style: AppText.poppins(
                        fontSize: 12,
                        color: palette.accentBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 40),

          // Camera Button
          FilledButton.icon(
            onPressed: () => _pickAndProcessImage(fromCamera: true),
            icon: Icon(Icons.camera_alt_rounded,
                size: ResponsiveHelper.iconSize(context, base: 24)),
            label: Text(
              'Take Photo',
              style: AppText.poppins(
                  fontSize: ResponsiveHelper.fontSize(context, mobile: 18),
                  fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: palette.accentBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                  vertical: ResponsiveHelper.spacing(context, mobile: 18)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Gallery Button
          OutlinedButton.icon(
            onPressed: () => _pickAndProcessImage(fromCamera: false),
            icon: Icon(Icons.photo_library_rounded,
                size: ResponsiveHelper.iconSize(context, base: 24)),
            label: Text(
              'Choose from Gallery',
              style: AppText.poppins(
                  fontSize: ResponsiveHelper.fontSize(context, mobile: 18),
                  fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.accentBlue,
              padding: EdgeInsets.symmetric(
                  vertical: ResponsiveHelper.spacing(context, mobile: 18)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: palette.accentBlue, width: 2),
            ),
          ),
          const SizedBox(height: 32),

          // What we extract
          _buildInfoCard(palette),
        ],
      ),
    );
  }

  Widget _buildInfoCard(palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: palette.accentBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'We extract:',
                style: AppText.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('Recipient Name', palette),
          _buildInfoItem('Phone Number', palette),
          _buildInfoItem('Amount Sent', palette),
          _buildInfoItem('Transaction Fee', palette),
          _buildInfoItem('Reference Number', palette),
          _buildInfoItem('Date & Time', palette),
          _buildInfoItem('Service Provider', palette),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text, palette) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              size: 16, color: palette.accentGreen),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppText.poppins(
              fontSize: 13,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
