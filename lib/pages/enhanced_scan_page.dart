import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/gemini_service.dart';
import '../services/ocr_service.dart';
import '../controllers/app_controller.dart';
import '../models/receipt_model.dart';
import 'receipt_preview_page.dart';

/// Enhanced Scan Page - Uses BOTH Google ML Kit OCR and Gemini AI
/// Falls back to OCR if Gemini fails
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

        // If Gemini fails, fallback to traditional OCR
        if (receipt == null) {
          setState(() => processingStatus = 'Gemini failed, trying OCR...');
          receipt = await _ocrService.processReceipt(
            imageFile,
            controller.feeRanges.toList(),
          );
        }
      } else {
        // Use traditional OCR
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
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red.shade400,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(20),
      borderRadius: 16,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E5EC),
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        backgroundColor: const Color(0xFFE0E5EC),
        elevation: 0,
        actions: [
          // Toggle between Gemini and OCR
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                Text(
                  useGemini ? 'AI' : 'OCR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: useGemini ? Colors.blue[700] : Colors.grey[600],
                  ),
                ),
                Switch(
                  value: useGemini,
                  onChanged: (value) {
                    setState(() => useGemini = value);
                  },
                  activeColor: Colors.blue[700],
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isProcessing ? _buildProcessingView() : _buildScanOptions(),
      ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            processingStatus,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOptions() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Icon(
            Icons.document_scanner,
            size: 100,
            color: Colors.blue[700],
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Scan Money Transfer Receipt',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            'Take a photo or select an image of your GCash, Palawan, or other money transfer receipt',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),

          // AI Badge
          if (useGemini)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue[700]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Enhanced with Gemini AI',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 40),

          // Camera Button
          ElevatedButton.icon(
            onPressed: () => _pickAndProcessImage(fromCamera: true),
            icon: const Icon(Icons.camera_alt, size: 28),
            label: const Text(
              'Take Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
          ),
          const SizedBox(height: 16),

          // Gallery Button
          OutlinedButton.icon(
            onPressed: () => _pickAndProcessImage(fromCamera: false),
            icon: const Icon(Icons.photo_library, size: 28),
            label: const Text(
              'Choose from Gallery',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[700],
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: Colors.blue[700]!, width: 2),
            ),
          ),
          const SizedBox(height: 32),

          // What we extract
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'We extract:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem('Recipient Name'),
            _buildInfoItem('Phone Number'),
            _buildInfoItem('Amount Sent'),
            _buildInfoItem('Transaction Fee'),
            _buildInfoItem('Reference Number'),
            _buildInfoItem('Date & Time'),
            _buildInfoItem('Service Provider'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
