import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../controllers/app_controller.dart';
import '../services/ocr_service.dart';
import '../utils/app_text.dart';
import 'receipt_preview_page.dart';

class _ScanCameraPalette {
  _ScanCameraPalette(ThemeData theme)
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

/// Scan page with live camera preview (camera starts automatically)
/// and still shows the options card (Take Photo / Choose from Gallery).
class ScanCameraPage extends StatefulWidget {
  const ScanCameraPage({super.key});

  @override
  State<ScanCameraPage> createState() => _ScanCameraPageState();
}

class _ScanCameraPageState extends State<ScanCameraPage>
    with WidgetsBindingObserver {
  final OCRService _ocrService = OCRService();
  final AppController controller = Get.find<AppController>();

  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _isProcessing = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // camera plugin is not supported on web
    if (!kIsWeb) {
      _initCamera();
    } else {
      _cameraError = 'Camera preview is not available on web.';
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
        backgroundColor: palette.background,
        appBar: AppBar(
          backgroundColor: palette.cardSurface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: palette.textPrimary, size: 20),
            onPressed: () => Get.back(),
          ),
          title: Row(
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
              Flexible(
                child: Text(
                  'Scan Receipt',
                  overflow: TextOverflow.ellipsis,
                  style: AppText.poppins(
                    color: palette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          child: _isProcessing
              ? _buildProcessingView(palette)
              : _buildScanView(palette),
        ),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),

    Widget _buildProcessingView(_ScanCameraPalette palette) {
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

    Widget _buildScanView(_ScanCameraPalette palette) {
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

            // Live Preview Container (previous design, now with live camera)
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
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _buildPreviewLayer(palette),
                  ),

                  // Bottom scrim for buttons readability
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.55),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Overlay buttons (requested: visible while camera is live)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _chooseFromGallery,
                            icon: Icon(
                              kIsWeb
                                  ? Icons.upload_file_rounded
                                  : Icons.photo_library_rounded,
                              size: 20,
                            ),
                            label: Text(
                              kIsWeb ? 'Upload' : 'Choose from Gallery',
                              overflow: TextOverflow.ellipsis,
                              style: AppText.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: palette.accentBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        if (!kIsWeb) const SizedBox(width: 12),
                        if (!kIsWeb)
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _takePhoto,
                              icon: const Icon(Icons.camera_alt_rounded, size: 20),
                              label: Text(
                                'Take Photo',
                                overflow: TextOverflow.ellipsis,
                                style: AppText.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: palette.accentBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 350.ms)
                        .slideY(begin: 0.15, end: 0),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 500.ms)
                .scale(begin: const Offset(0.98, 0.98)),

            const SizedBox(height: 32),

            // Features Card (same as previous design)
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
                  _buildFeatureItem(palette, 'Transaction charge'),
                  _buildFeatureItem(palette, 'Reference number'),
                  _buildFeatureItem(palette, 'Date & time'),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
      );
    }

    Widget _buildFeatureItem(_ScanCameraPalette palette, String text) {
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

    Widget _buildPreviewLayer(_ScanCameraPalette palette) {
      // Web: no camera preview
      if (kIsWeb) {
        return _buildPlaceholderLayer(
          palette,
          title: 'Ready to Scan',
          subtitle: 'Upload a receipt image to continue',
        );
      }

      if (_cameraError != null) {
        return _buildPlaceholderLayer(
          palette,
          title: 'Camera Error',
          subtitle: _cameraError!,
          showIcon: true,
        );
      }

      if (!_cameraReady || _cameraController == null) {
        return _buildPlaceholderLayer(
          palette,
          title: 'Starting camera...',
          subtitle: 'Please wait a moment',
          showSpinner: true,
        );
      }

      return Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),
          // subtle overlay so UI matches the old "card" look
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(palette.isDark ? 0.05 : 0.12),
            ),
          ),
        ],
      );
    }

    Widget _buildPlaceholderLayer(
      _ScanCameraPalette palette, {
      required String title,
      required String subtitle,
      bool showSpinner = false,
      bool showIcon = true,
    }) {
      return Container(
        color: palette.cardSurface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showSpinner)
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(palette.accentBlue),
                )
              else if (showIcon)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: palette.accentBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 52,
                    color: palette.accentBlue,
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                title,
                style: AppText.poppins(
                  color: palette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Text(
                  subtitle,
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
      );
    }
  }

  Future<void> _chooseFromGallery() async {
    if (_isProcessing) return;
    final file = await _ocrService.pickImage(fromCamera: false);
    if (file == null) return;
    await _processFile(file);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _ScanCameraPalette(Theme.of(context));

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _buildCameraLayer(palette),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Scan Receipt',
                      style: AppText.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Options card overlay
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildOptionsCard(palette)
                  .animate()
                  .fadeIn(duration: 250.ms)
                  .slideY(begin: 0.15, end: 0),
            ),

            if (_isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(palette.accentBlue),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Processing...',
                          style: AppText.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraLayer(_ScanCameraPalette palette) {
    if (_cameraError != null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Text(
          _cameraError!,
          textAlign: TextAlign.center,
          style: AppText.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (!_cameraReady || _cameraController == null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(palette.accentBlue),
        ),
      );
    }

    final controller = _cameraController!;

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 720,
          height: controller.value.previewSize?.width ?? 1280,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  Widget _buildOptionsCard(_ScanCameraPalette palette) {
    final subtitle = DateFormat('MMM dd').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardSurface.withOpacity(palette.isDark ? 0.92 : 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ready to Scan',
            style: AppText.poppins(
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Take a photo or choose from gallery ($subtitle)',
            style: AppText.poppins(
              color: palette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isProcessing ? null : _takePhoto,
            icon: const Icon(Icons.camera_alt_rounded, size: 20),
            label: Text(
              'Take Photo',
              style: AppText.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: palette.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _chooseFromGallery,
            icon: Icon(Icons.photo_library_rounded,
                size: 20, color: palette.accentBlue),
            label: Text(
              'Choose from Gallery',
              style: AppText.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: palette.accentBlue,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: palette.accentBlue, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
