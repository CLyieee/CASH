import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ocr_service.dart';
import 'transaction_service.dart';
import 'package:get/get.dart';
import '../controllers/app_controller.dart';
import '../models/transaction_model.dart';

class AutoReceiptScannerService {
  static const String _autoScanEnabledKey = 'auto_receipt_scan_enabled';
  static const String _lastScannedTimestampKey = 'last_scanned_timestamp';

  final OCRService _ocrService = OCRService();
  final TransactionService _transactionService = TransactionService();

  /// Check if auto-scan is enabled
  Future<bool> isAutoScanEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoScanEnabledKey) ?? false;
  }

  /// Enable or disable auto-scan
  Future<void> setAutoScanEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoScanEnabledKey, enabled);
  }

  /// Request storage permission
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+, use photos permission
      if (await Permission.photos.request().isGranted) {
        return true;
      }
      // Fallback to storage for older Android versions
      if (await Permission.storage.request().isGranted) {
        return true;
      }
      return false;
    } else if (Platform.isIOS) {
      return await Permission.photos.request().isGranted;
    }
    return false;
  }

  /// Scan all images in Pictures folder
  Future<ScanResult> scanPicturesFolder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastScannedTimestamp = prefs.getInt(_lastScannedTimestampKey) ?? 0;

      List<File> newImages = [];

      if (Platform.isAndroid) {
        // Android: Check DCIM/Camera and Pictures folders
        final externalDir = Directory('/storage/emulated/0');
        final pictureDirs = [
          Directory('${externalDir.path}/DCIM/Camera'),
          Directory('${externalDir.path}/Pictures'),
          Directory('${externalDir.path}/Download'),
        ];

        for (final dir in pictureDirs) {
          if (await dir.exists()) {
            final files = await dir.list().toList();
            for (final file in files) {
              if (file is File && _isImageFile(file.path)) {
                final stat = await file.stat();
                if (stat.modified.millisecondsSinceEpoch >
                    lastScannedTimestamp) {
                  newImages.add(file);
                }
              }
            }
          }
        }
      } else if (Platform.isIOS) {
        // iOS: Use app's photo library access
        // Note: iOS restricts direct file system access to Photos
        // This would require photo_manager package for full implementation
        return ScanResult(
          success: false,
          message: 'iOS photo scanning requires manual selection',
          scannedCount: 0,
          savedCount: 0,
        );
      }

      // Sort by modification date (newest first)
      newImages.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      // Limit to 10 most recent images to avoid performance issues
      final imagesToScan = newImages.take(10).toList();

      int savedCount = 0;
      final appController = Get.find<AppController>();
      final userId = appController.currentUserId.value;

      for (final imageFile in imagesToScan) {
        try {
          // Get fee ranges from controller
          final feeRanges = appController.feeRanges;

          // Process receipt using OCR
          final receipt =
              await _ocrService.processReceipt(imageFile, feeRanges);

          // CRITICAL: Reference number is required - it's the life of the receipt
          if (receipt != null &&
              receipt.amount > 0 &&
              receipt.refNumber.isNotEmpty) {
            // Generate fallback values only for non-critical fields
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final fileName = imageFile.path.split('/').last;

            // Create transaction model
            final transaction = TransactionModel(
              id: timestamp.toString(),
              userId: userId,
              recipientName: receipt.recipientName.isNotEmpty
                  ? receipt.recipientName
                  : 'Auto-scan: $fileName',
              phoneNumber:
                  receipt.phoneNumber.isNotEmpty ? receipt.phoneNumber : 'N/A',
              amount: receipt.amount,
              fee: receipt.fee,
              totalAmount: receipt.totalAmount,
              transactionType: 'Cash Out',
              source: receipt.source.isNotEmpty ? receipt.source : 'Auto-scan',
              refNumber: receipt.refNumber, // MUST have valid ref number
              date: receipt.date,
              createdAt: DateTime.now(),
            );

            // Save transaction
            await _transactionService.saveTransaction(transaction);
            savedCount++;
            print(
                '✅ Auto-saved: ${receipt.recipientName} - ₱${receipt.amount} [Ref: ${receipt.refNumber}]');
          } else {
            if (receipt == null) {
              print(
                  '⚠️ Skipped ${imageFile.path}: OCR failed to extract receipt data');
            } else if (receipt.amount <= 0) {
              print('⚠️ Skipped ${imageFile.path}: No valid amount found');
            } else if (receipt.refNumber.isEmpty) {
              print(
                  '⚠️ Skipped ${imageFile.path}: Missing reference number (CRITICAL)');
            }
          }
        } catch (e) {
          print('❌ Error scanning ${imageFile.path}: $e');
          // Continue with next image
        }
      }

      // Update last scanned timestamp
      await prefs.setInt(
          _lastScannedTimestampKey, DateTime.now().millisecondsSinceEpoch);

      return ScanResult(
        success: true,
        message:
            'Scanned ${imagesToScan.length} images, saved $savedCount receipts',
        scannedCount: imagesToScan.length,
        savedCount: savedCount,
      );
    } catch (e) {
      return ScanResult(
        success: false,
        message: 'Error: $e',
        scannedCount: 0,
        savedCount: 0,
      );
    }
  }

  /// Check if file is an image
  bool _isImageFile(String path) {
    final extension = path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'heic', 'webp'].contains(extension);
  }
}

class ScanResult {
  final bool success;
  final String message;
  final int scannedCount;
  final int savedCount;

  ScanResult({
    required this.success,
    required this.message,
    required this.scannedCount,
    required this.savedCount,
  });
}
