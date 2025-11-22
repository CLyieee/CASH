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
      print('🔍 Starting receipt processing with OCR...');

      final InputImage inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      final text = recognizedText.text;
      print('📄 Extracted text length: ${text.length}');
      print('📝 RAW OCR TEXT:\n$text\n---END RAW TEXT---');

      // Detect transaction type first
      final isBankTransfer = _isBankTransfer(text);
      print(
          '💳 Transaction type: ${isBankTransfer ? "BANK TRANSFER" : "MONEY TRANSFER"}');

      if (isBankTransfer) {
        return _extractBankTransferData(text, feeRanges);
      } else {
        return _extractReceiptData(text, feeRanges);
      }
    } catch (e) {
      print('❌ Error processing receipt: $e');
      rethrow;
    }
  }

  // Detect if this is a bank transfer receipt
  bool _isBankTransfer(String text) {
    final lowerText = text.toLowerCase();

    // Check for bank transfer indicators
    if (lowerText.contains('bank transfer complete') ||
        lowerText.contains('bank transfer') ||
        lowerText.contains('to bank account')) {
      return true;
    }

    // Check for bank-specific fields
    if ((lowerText.contains('bank') || lowerText.contains('account no')) &&
        (lowerText.contains('account name') ||
            lowerText.contains('receipt sent to'))) {
      return true;
    }

    return false;
  }

  // Extract bank transfer data
  ReceiptModel? _extractBankTransferData(
      String text, List<FeeRange> feeRanges) {
    try {
      print('🏦 Extracting bank transfer data...');

      // Extract bank name from "Bank" label
      String bankName = _extractBankName(text);
      print('Bank: $bankName');

      // Extract account name from "Account Name" label (e.g., "JUAN A.")
      String accountName = _extractAccountName(text);
      print('Account Name: $accountName');

      // Extract transfer amount from "Transfer Amount" label
      double amount = _extractAmount(text);
      print('Transfer Amount: $amount');

      // Extract bank fee from "+Fee" label
      double bankFee = _extractBankFee(text);
      print('Bank Fee (+Fee): $bankFee');

      // Extract total from "Total" label
      double total = _extractTotal(text);
      print('Total: $total');

      // Extract reference number from "Ref No." label
      String refNumber = _extractReferenceNumber(text);
      print('Ref No: $refNumber');

      // Extract transfer date from "Transfer Date" label
      DateTime date = _extractDate(text);
      print('Transfer Date: $date');

      if (accountName.isEmpty || amount == 0) {
        print('❌ Failed to extract required bank transfer data');
        return null;
      }

      print('✅ Bank transfer extraction successful!');

      // Return as ReceiptModel with transactionType = bank_transfer
      return ReceiptModel(
        recipientName: accountName,
        phoneNumber:
            bankName, // Store bank name in phone field for bank transfers
        amount: amount,
        refNumber: refNumber,
        date: date,
        fee: bankFee,
        source: _detectSource(text),
        transactionType: 'bank_transfer',
      );
    } catch (e) {
      print('❌ Error extracting bank transfer data: $e');
      return null;
    }
  }

  // Extract receipt data from OCR text
  ReceiptModel? _extractReceiptData(String text, List<FeeRange> feeRanges) {
    try {
      // Extract recipient name (e.g., "CL*****M M.", "MA****N M.")
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

  // Extract recipient name (handles GCash patterns like CL*****M M., MA****N M., CE••••A B.)
  String _extractRecipientName(String text) {
    final lines = text.split('\n');

    // Pattern variations for GCash masked names:
    // 1. "CL*****M M." - 2 letters + asterisks + 1 letter + space + initial
    // 2. "CE••••A B." - 2 letters + dots + 1 letter + space + initial
    // 3. "MA....N M." - 2 letters + regular dots + 1 letter + space + initial
    final patterns = [
      // Pattern 1: With asterisks (CL*****M M.)
      RegExp(r'[A-Z]{2}\*{1,10}[A-Z]\s+[A-Z]\.', caseSensitive: true),
      // Pattern 2: With bullet dots (CE••••A B.)
      RegExp(r'[A-Z]{2}[•]{1,10}[A-Z]\s+[A-Z]\.', caseSensitive: true),
      // Pattern 3: With regular dots (MA....N M.)
      RegExp(r'[A-Z]{2}[\.]{1,10}[A-Z]\s+[A-Z]\.', caseSensitive: true),
      // Pattern 4: Mixed symbols (CL•*•*M M.)
      RegExp(r'[A-Z]{2}[•*\.]{1,10}[A-Z]\s+[A-Z]\.', caseSensitive: true),
    ];

    // Try each pattern
    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(0)!.trim();
      }
    }

    // Alternative: Search line by line for name after phone number
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Look for lines with phone numbers, name usually appears before or after
      if (line.contains('+63') || line.contains('639')) {
        // Check previous lines
        for (int j = i - 1; j >= 0 && j >= i - 5; j--) {
          final prevLine = lines[j].trim();
          // Check if line matches name pattern
          for (var pattern in patterns) {
            if (pattern.hasMatch(prevLine)) {
              return pattern.firstMatch(prevLine)!.group(0)!.trim();
            }
          }
        }
        // Check next lines
        for (int j = i + 1; j < lines.length && j < i + 5; j++) {
          final nextLine = lines[j].trim();
          for (var pattern in patterns) {
            if (pattern.hasMatch(nextLine)) {
              return pattern.firstMatch(nextLine)!.group(0)!.trim();
            }
          }
        }
      }
    }

    // Last resort: Try full name pattern (for non-masked names)
    final fullNamePattern = RegExp(
      r'[A-Z][a-z]+(?:\s+[A-Z][a-z]+)+',
      caseSensitive: true,
    );

    final fullNameMatch = fullNamePattern.firstMatch(text);
    if (fullNameMatch != null) {
      final name = fullNameMatch.group(0)!.trim();
      // Avoid matching common words
      if (!name.contains('GCash') &&
          !name.contains('Transfer') &&
          !name.contains('Amount') &&
          name.length > 5) {
        return name;
      }
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

  // Extract amount - handles both bank transfers (Transfer Amount) and regular receipts
  double _extractAmount(String text) {
    final lines = text.split('\n');

    // For bank transfers, look for "Transfer Amount" label
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.toLowerCase() == 'transfer amount') {
        // Look ahead for amount value (format: 500.00)
        for (int j = i + 1; j < lines.length && j < i + 5; j++) {
          final nextLine = lines[j].trim();

          // Match amount format: digits with optional comma and decimal
          final amountMatch = RegExp(r'^([\d,]+\.\d{2})$').firstMatch(nextLine);
          if (amountMatch != null) {
            String amountStr = amountMatch.group(1)!.replaceAll(',', '');
            final parsed = double.tryParse(amountStr);
            if (parsed != null && parsed > 0) {
              return parsed;
            }
          }
        }
      }
    }

    // Fallback: Generic "Amount" pattern for regular receipts
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
    print('💰 Calculating fee for amount: $amount');
    print('📋 Fee ranges count: ${feeRanges.length}');

    if (feeRanges.isEmpty) {
      print('⚠️ No fee ranges configured!');
      return 0.0;
    }

    for (var range in feeRanges) {
      print('  Checking range: ${range.from} - ${range.to} = ₱${range.fee}');
      if (amount >= range.from && amount <= range.to) {
        print('✅ Fee matched: ₱${range.fee}');
        return range.fee.toDouble();
      }
    }

    print('❌ No matching fee range found for amount $amount');
    return 0.0;
  }

  // Extract reference number - look for "Ref No." label, ignore InstaPay Invoice No.
  String _extractReferenceNumber(String text) {
    final lines = text.split('\n');

    // First, find the InstaPay Invoice No. to skip it
    String? instapayNumber;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.toLowerCase().contains('instapay')) {
        // Get the number after InstaPay label (shorter number, ~7 digits)
        for (int k = i + 1; k < lines.length && k < i + 5; k++) {
          final numLine = lines[k].trim();
          if (RegExp(r'^\d{6,8}$').hasMatch(numLine)) {
            instapayNumber = numLine;
            break;
          }
        }
      }
    }

    // Now find Ref No.
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Look for "Ref No." label - can be on same line or separate line
      if (line.toLowerCase().contains('ref no.')) {
        // Check if ref number is on the same line (e.g., "Ref No. 5034 929 919808 Nov 21, 2025")
        final sameLine =
            line.substring(line.toLowerCase().indexOf('ref no.') + 7).trim();
        if (sameLine.isNotEmpty) {
          // Extract digits with spaces (e.g., "5034 929 919808")
          final refMatch = RegExp(r'(\d[\d\s]{10,})').firstMatch(sameLine);
          if (refMatch != null) {
            return refMatch.group(1)!.trim();
          }
        }

        // Look ahead for reference number (long digit string)
        // Need to search far ahead because ref number appears near the end
        for (int j = i + 1; j < lines.length && j < i + 20; j++) {
          final nextLine = lines[j].trim();

          // Skip empty lines, text, and labels
          if (nextLine.isEmpty ||
              nextLine.toLowerCase().contains('sent') ||
              nextLine.toLowerCase().contains('gcash') ||
              nextLine.toLowerCase().contains('g ') ||
              nextLine.toLowerCase().contains('transportation') ||
              nextLine.toLowerCase().contains('paper') ||
              nextLine.toLowerCase().contains('plastic') ||
              nextLine.toLowerCase().contains('maribank') ||
              nextLine.toLowerCase().contains('clythem') ||
              nextLine.toLowerCase().contains('powered') ||
              nextLine.toLowerCase().contains('instapay') ||
              nextLine.toLowerCase().contains('.com') ||
              nextLine.toLowerCase().contains('by going') ||
              nextLine.toLowerCase().contains('@') ||
              nextLine.contains('***') ||
              nextLine.contains('•') ||
              nextLine.startsWith('P')) {
            continue;
          }

          // Reference number: digits with optional spaces (e.g., "5034 929 919808" or "5034124744068")
          // Remove spaces to check length, must be longer than 10 digits
          final digitsOnly = nextLine.replaceAll(' ', '');
          if (RegExp(r'^\d{10,}$').hasMatch(digitsOnly) &&
              digitsOnly != instapayNumber) {
            return nextLine; // Return with spaces as formatted
          }
        }
      }
    }

    return '';
  }

  // Extract date - handles both "Oct 29,2025 02:36 PM" and "Nov 04, 2025 10:31 AM"
  DateTime _extractDate(String text) {
    // Pattern for dates with or without space after comma
    final datePattern = RegExp(
      r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2},?\s*\d{4}\s+\d{1,2}:\d{2}\s+(AM|PM)',
      caseSensitive: false,
    );

    final match = datePattern.firstMatch(text);
    if (match != null) {
      String dateStr = match.group(0)!;
      try {
        // Normalize: ensure space after comma
        dateStr = dateStr.replaceAll(RegExp(r'(\d+),(\d{4})'), r'$1, $2');
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

  // Extract bank name - look for "Bank" label, value is several lines after
  String _extractBankName(String text) {
    final lines = text.split('\n');

    // Common bank names to look for
    final bankNames = [
      'MariBank',
      'BPI',
      'BDO',
      'Metrobank',
      'UnionBank',
      'Security Bank',
      'Chinabank',
      'RCBC',
      'PNB',
      'Landbank'
    ];

    // First try: Find common bank names in the text
    for (var bankName in bankNames) {
      if (text.contains(bankName)) {
        return bankName;
      }
    }

    // Second try: Find "Bank" label line and look ahead
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.toLowerCase() == 'bank') {
        // Look ahead for bank name (should be capitalized, not too long)
        for (int j = i + 1; j < lines.length && j < i + 20; j++) {
          final nextLine = lines[j].trim();

          // Skip empty lines and known labels
          if (nextLine.isEmpty ||
              nextLine.toLowerCase().contains('successful') ||
              nextLine.toLowerCase().contains('account') ||
              nextLine.toLowerCase().contains('transfer') ||
              nextLine.toLowerCase().contains('receipt') ||
              nextLine.toLowerCase().contains('sent') ||
              nextLine.toLowerCase().contains('amount') ||
              nextLine.toLowerCase().contains('fee') ||
              nextLine.toLowerCase().contains('total') ||
              nextLine.toLowerCase().contains('ref') ||
              nextLine.toLowerCase().contains('invoice') ||
              nextLine.toLowerCase().contains('date') ||
              nextLine.toLowerCase().contains('complete')) {
            continue;
          }

          // Bank names: usually one or two words, capitalized
          if (RegExp(r'^[A-Z][a-zA-Z]+(\s+[A-Z][a-zA-Z]+)?$')
                  .hasMatch(nextLine) &&
              nextLine.length < 30 &&
              nextLine.length > 2) {
            return nextLine;
          }
        }
      }
    }

    return '';
  }

  // Extract account number
  String _extractAccountNumber(String text) {
    // Pattern for "Account No." followed by masked or full number
    final accountPattern = RegExp(
      r'Account\s*No\.?\s*([\*\d]+)',
      caseSensitive: false,
    );

    final match = accountPattern.firstMatch(text);
    if (match != null) {
      return match.group(1)!.trim();
    }

    // Try pattern with dots
    final dotsPattern = RegExp(
      r'Account\s*No\.?\s*([\•\*\.]+\d+)',
      caseSensitive: false,
    );

    final dotsMatch = dotsPattern.firstMatch(text);
    if (dotsMatch != null) {
      return dotsMatch.group(1)!.trim();
    }

    return '';
  }

  // Extract account name - look for "Account Name" label, value like "CLYTHEM O."
  String _extractAccountName(String text) {
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Look for "Account Name" label
      if (line.toLowerCase() == 'account name') {
        // Look ahead for account name (ALL CAPS with dots)
        for (int j = i + 1; j < lines.length && j < i + 15; j++) {
          final nextLine = lines[j].trim();

          // Skip empty lines, labels, and common text
          if (nextLine.isEmpty ||
              nextLine.toLowerCase().contains('receipt') ||
              nextLine.toLowerCase().contains('transfer') ||
              nextLine.toLowerCase().contains('amount') ||
              nextLine.toLowerCase().contains('fee') ||
              nextLine.toLowerCase().contains('total') ||
              nextLine.toLowerCase().contains('ref') ||
              nextLine.toLowerCase().contains('invoice') ||
              nextLine.toLowerCase().contains('date') ||
              nextLine.toLowerCase().contains('sent') ||
              nextLine.toLowerCase().contains('gcash') ||
              nextLine.toLowerCase().contains('powered') ||
              nextLine.toLowerCase().contains('instapay') ||
              nextLine.toLowerCase().contains('@') || // skip email
              nextLine.contains('***') || // skip masked account number
              nextLine.contains('•••')) {
            // skip masked account number
            continue;
          }

          // Account names: ALL CAPS with possible dots (e.g., "CLYTHEM O.")
          if (RegExp(r'^[A-Z][A-Z\s\.]+$').hasMatch(nextLine) &&
              nextLine.length >= 3 &&
              nextLine.length < 50) {
            return nextLine;
          }
        }
      }
    }

    return '';
  }

  // Extract email address
  String _extractEmail(String text) {
    // Pattern for email addresses
    final emailPattern = RegExp(
      r'[\w\.-]+@[\w\.-]+\.\w+',
      caseSensitive: false,
    );

    final match = emailPattern.firstMatch(text);
    if (match != null) {
      return match.group(0)!.trim();
    }

    return '';
  }

  // Extract bank fee - look for "+Fee" label specifically
  double _extractBankFee(String text) {
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Look for "+Fee" label (exact match)
      if (line == '+Fee' || line == '+ Fee' || line == '+fee') {
        // Look ahead for fee value (format: 15.00)
        // In the OCR output, 15.00 appears several lines after +Fee
        for (int j = i + 1; j < lines.length && j < i + 20; j++) {
          final nextLine = lines[j].trim();

          // Skip empty lines, labels and known text
          if (nextLine.isEmpty ||
              nextLine.toLowerCase().contains('total') ||
              nextLine.toLowerCase().contains('instapay') ||
              nextLine.toLowerCase().contains('ref') ||
              nextLine.toLowerCase().contains('by going') ||
              nextLine.toLowerCase().contains('carbon') ||
              nextLine.toLowerCase().contains('digital') ||
              nextLine.toLowerCase().contains('sent') ||
              nextLine.toLowerCase().contains('gcash') ||
              nextLine.contains('P515') || // Skip total
              nextLine.startsWith('P') || // Skip amounts with P
              nextLine.startsWith('₱')) {
            // Skip amounts with ₱
            continue;
          }

          // Match fee format: exactly 2 decimal places, small amount
          final feeMatch = RegExp(r'^(\d{1,2}\.\d{2})$').firstMatch(nextLine);
          if (feeMatch != null) {
            String feeStr = feeMatch.group(1)!;
            final parsed = double.tryParse(feeStr);
            // Fee is typically small (< 100) and greater than 0
            if (parsed != null && parsed > 0 && parsed < 100) {
              return parsed;
            }
          }
        }
      }
    }

    return 0.0;
  }

  // Extract total - look for "Total" label with ₱ or P symbol
  double _extractTotal(String text) {
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Look for "Total" label (exact match)
      if (line.toLowerCase() == 'total') {
        // Look ahead for total value (format: P515.00 or ₱515.00)
        for (int j = i + 1; j < lines.length && j < i + 15; j++) {
          final nextLine = lines[j].trim();

          // Skip empty lines, labels and known text
          if (nextLine.isEmpty ||
              nextLine.toLowerCase().contains('instapay') ||
              nextLine.toLowerCase().contains('ref') ||
              nextLine.toLowerCase().contains('by going') ||
              nextLine.toLowerCase().contains('carbon') ||
              nextLine.toLowerCase().contains('digital') ||
              nextLine.toLowerCase().contains('footprint')) {
            continue;
          }

          // Match total format with P or ₱ symbol (with optional space)
          final totalMatch =
              RegExp(r'^[P₱]\s*([\d,]+\.\d{2})$').firstMatch(nextLine);
          if (totalMatch != null) {
            String totalStr = totalMatch.group(1)!.replaceAll(',', '');
            final parsed = double.tryParse(totalStr);
            if (parsed != null && parsed > 0) {
              return parsed;
            }
          }

          // Also try without symbol requirement for amounts > 100
          final amountMatch = RegExp(r'^([\d,]+\.\d{2})$').firstMatch(nextLine);
          if (amountMatch != null) {
            String amountStr = amountMatch.group(1)!.replaceAll(',', '');
            final parsed = double.tryParse(amountStr);
            // Total should be larger than 100 and appear as P515.00 format
            if (parsed != null && parsed > 100) {
              // Check if previous context had P or ₱
              if (i > 0 && j > 0) {
                final prevLine = lines[j - 1].trim();
                if (prevLine.isEmpty || prevLine.toLowerCase() == 'total') {
                  return parsed;
                }
              }
            }
          }
        }
      }
    }

    return 0.0;
  }

  // Dispose
  void dispose() {
    _textRecognizer.close();
  }
}
