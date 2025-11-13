import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../models/receipt_model.dart';
import '../models/user_model.dart';
import 'dart:io';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Pick image from gallery or camera
  Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      rethrow;
    }
  }

  // Process receipt image and extract data
  Future<ReceiptModel?> processReceipt(
    File imageFile,
    List<FeeRange> feeRanges,
  ) async {
    try {
      final InputImage inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      return _extractReceiptData(recognizedText.text, feeRanges);
    } catch (e) {
      print('Error processing receipt: $e');
      rethrow;
    }
  }

  // Extract receipt data from OCR text
  ReceiptModel? _extractReceiptData(String text, List<FeeRange> feeRanges) {
    try {
      // Extract recipient name (e.g., "MA****N M.")
      String recipientName = _extractRecipientName(text);

      // Extract phone number (e.g., "+63 915 609 1737")
      String phoneNumber = _extractPhoneNumber(text);

      // Extract amount (e.g., "1,400.00")
      double amount = _extractAmount(text);

      // Calculate fee based on amount and fee ranges
      double fee = _calculateFee(amount, feeRanges);

      // Extract reference number (e.g., "5034 322 274670")
      String refNumber = _extractReferenceNumber(text);

      // Extract date (e.g., "Nov 04, 2025 10:31 AM")
      DateTime date = _extractDate(text);

      if (recipientName.isEmpty || phoneNumber.isEmpty || amount == 0) {
        print('Failed to extract required data');
        return null;
      }

      return ReceiptModel(
        recipientName: recipientName,
        phoneNumber: phoneNumber,
        amount: amount,
        refNumber: refNumber,
        date: date,
        fee: fee,
        source: _detectSource(text),
      );
    } catch (e) {
      print('Error extracting receipt data: $e');
      return null;
    }
  }

  // Extract recipient name (handles patterns like MA****N M., MA••••N M.)
  String _extractRecipientName(String text) {
    // Pattern for names like "MA****N M." or "MA••••N M."
    final namePattern = RegExp(
      r'([A-Z]{2}[•*\.]{1,8}[A-Z]\s+[A-Z]\.)',
      caseSensitive: true,
    );

    final match = namePattern.firstMatch(text);
    if (match != null) {
      return match.group(0)!.trim();
    }

    // Try alternative pattern for full names
    final fullNamePattern = RegExp(
      r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)',
      caseSensitive: true,
    );

    final fullNameMatch = fullNamePattern.firstMatch(text);
    if (fullNameMatch != null) {
      return fullNameMatch.group(0)!.trim();
    }

    return '';
  }

  // Extract phone number (handles +63 format)
  String _extractPhoneNumber(String text) {
    // Pattern for phone numbers like "+63 915 609 1737" or "639156091737"
    final phonePattern = RegExp(
      r'\+?63\s*\d{3}\s*\d{3}\s*\d{4}',
    );

    final match = phonePattern.firstMatch(text);
    if (match != null) {
      String phone = match.group(0)!;
      // Normalize phone number format
      phone = phone.replaceAll(RegExp(r'\s+'), '');
      if (!phone.startsWith('+')) {
        phone = '+$phone';
      }
      return phone;
    }

    return '';
  }

  // Extract amount
  double _extractAmount(String text) {
    // Pattern for amounts like "1,400.00" or "1400.00"
    final amountPattern = RegExp(
      r'Amount\s*[\r\n]+\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    );

    var match = amountPattern.firstMatch(text);
    if (match != null) {
      String amountStr = match.group(1)!.replaceAll(',', '');
      return double.tryParse(amountStr) ?? 0.0;
    }

    // Alternative pattern
    final altPattern = RegExp(r'₱?\s*([\d,]+\.\d{2})');
    match = altPattern.firstMatch(text);
    if (match != null) {
      String amountStr = match.group(1)!.replaceAll(',', '');
      return double.tryParse(amountStr) ?? 0.0;
    }

    return 0.0;
  }

  // Calculate fee based on amount and fee ranges
  double _calculateFee(double amount, List<FeeRange> feeRanges) {
    for (var range in feeRanges) {
      if (amount >= range.from && amount <= range.to) {
        return range.fee.toDouble();
      }
    }
    // Default fee if no range matches
    return 0.0;
  }

  // Extract reference number
  String _extractReferenceNumber(String text) {
    // Pattern for ref numbers like "5034 322 274670"
    final refPattern = RegExp(
      r'Ref\s*No\.?\s*([\d\s]+)',
      caseSensitive: false,
    );

    final match = refPattern.firstMatch(text);
    if (match != null) {
      return match.group(1)!.trim();
    }

    // Alternative pattern for long numbers
    final altPattern = RegExp(r'\d{4}\s*\d{3}\s*\d{6}');
    final altMatch = altPattern.firstMatch(text);
    if (altMatch != null) {
      return altMatch.group(0)!.trim();
    }

    return '';
  }

  // Extract date
  DateTime _extractDate(String text) {
    // Pattern for dates like "Nov 04, 2025 10:31 AM"
    final datePattern = RegExp(
      r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2},\s+\d{4}\s+\d{1,2}:\d{2}\s+(AM|PM)',
      caseSensitive: false,
    );

    final match = datePattern.firstMatch(text);
    if (match != null) {
      String dateStr = match.group(0)!;
      try {
        // Parse the date string
        return _parseDate(dateStr);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    return DateTime.now();
  }

  // Parse date string
  DateTime _parseDate(String dateStr) {
    // This is a simple parser - you might want to use intl package for better parsing
    final months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12
    };

    final parts = dateStr.split(RegExp(r'[\s,]+'));
    if (parts.length >= 5) {
      final month = months[parts[0].toLowerCase()] ?? 1;
      final day = int.tryParse(parts[1]) ?? 1;
      final year = int.tryParse(parts[2]) ?? DateTime.now().year;
      final timeParts = parts[3].split(':');
      var hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      final ampm = parts[4].toUpperCase();

      if (ampm == 'PM' && hour != 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;

      return DateTime(year, month, day, hour, minute);
    }

    return DateTime.now();
  }

  // Detect source from text
  String _detectSource(String text) {
    final lowerText = text.toLowerCase();
    if (lowerText.contains('gcash')) return 'GCash';
    if (lowerText.contains('palawan')) return 'Palawan';
    if (lowerText.contains('paymaya')) return 'PayMaya';
    return 'GCash'; // Default
  }

  // Dispose
  void dispose() {
    _textRecognizer.close();
  }
}
