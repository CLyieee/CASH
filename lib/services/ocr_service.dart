import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../models/receipt_model.dart';
import '../models/user_model.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'gemini_service.dart';

/// OCRService - Standalone OCR with intelligent GCash receipt structure detection
///
/// GCASH RECEIPT STRUCTURE (Money Transfer):
/// Understands the standard GCash receipt layout:
/// 1. Recipient Name (top section) - masked format like "JE....Y Z." or full name
/// 2. Phone Number (below name) - format: +63 XXX XXX XXXX
/// 3. Service indicator - "Sent via GCash"
/// 4. Amount section - labeled "Amount" with value
/// 5. Total display - "Total Amount Sent ₱XXX.XX"
/// 6. Reference section (bottom) - "Ref No." with number and date/time
///
/// MOBILE LOAD RECEIPT STRUCTURE:
/// Understands mobile load receipt layout based on position:
/// 1. Load/Promo Name (TOP - red annotation area) - e.g., "EasySURF50+5G+FunALIW+"
/// 2. Mobile Number (BELOW - blue annotation area) - format: +63 XXX XXX XXXX
/// 3. Service indicator - "Paid via GCash"
/// 4. Load Amount (MIDDLE - violet annotation area) - labeled "Amount" with value
/// 5. Convenience Fee - additional fee for the load
/// 6. Total display - includes amount + fee
/// 7. Date/Time (BOTTOM - orange annotation area) - transaction timestamp
/// 8. Reference Number (BOTTOM - pink annotation area) - transaction reference
///
/// BANK TRANSFER RECEIPT STRUCTURE:
/// Understands bank transfer receipt layout based on position:
/// 1. Bank Name (RED annotation area) - e.g., "RCBC/DiskarTech", "MariBank"
/// 2. Account Number (ORANGE annotation area) - masked format: "............5153"
/// 3. Account Name (YELLOW annotation area) - full name: "LOUISE KYLA ABRIGO"
/// 4. Transfer Date/Time (BLUE annotation area) - e.g., "Dec 12,2025 05:29 PM"
/// 5. Transfer Amount - the amount being transferred (without fee)
/// 6. Bank Fee (+Fee) - the transfer fee charged
/// 7. Total Amount (VIOLET annotation area) - transfer amount + fee
/// 8. Reference Number (bottom) - labeled "Ref No." (NOT InstaPay Invoice No.)
///
/// Extracts data based on text positioning and structure patterns.
class OCRService {
  TextRecognizer? _textRecognizer;
  final GeminiService _geminiService = GeminiService();
  XFile? _lastPickedImage; // Store the XFile for web access

  OCRService() {
    // Only initialize ML Kit on mobile platforms
    if (!kIsWeb) {
      try {
        _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        print('✅ TextRecognizer initialized successfully');
      } catch (e) {
        print('❌ Failed to initialize TextRecognizer: $e');
      }
    }
  }

  // Pick image from gallery or camera
  Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        _lastPickedImage = image; // Store for web access
        final imageFile = File(image.path);

        // Auto-save to app directory if taken from camera
        if (fromCamera) {
          try {
            // Get app's documents directory
            final directory = await getApplicationDocumentsDirectory();
            final receiptsDir = Directory('${directory.path}/receipts');

            // Create receipts folder if it doesn't exist
            if (!await receiptsDir.exists()) {
              await receiptsDir.create(recursive: true);
            }

            // Copy image to receipts folder with timestamp
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final savedImagePath = '${receiptsDir.path}/receipt_$timestamp.jpg';
            await imageFile.copy(savedImagePath);

            print('✅ Image saved to app directory: $savedImagePath');

            // Try to save to gallery using platform channel (Android)
            if (Platform.isAndroid) {
              try {
                const platform = MethodChannel('com.cash.receipts/media_store');
                await platform.invokeMethod('saveToGallery', {
                  'path': savedImagePath,
                  'name': 'receipt_$timestamp.jpg',
                });
                print('✅ Image also saved to gallery');
              } catch (e) {
                print(
                    '⚠️ Could not save to gallery (will be in app folder): $e');
              }
            }
          } catch (e) {
            print('⚠️ Failed to save image: $e');
            // Continue even if saving fails
          }
        }

        return imageFile;
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      rethrow;
    }
  }

  // Validate if extracted text contains receipt-like content
  bool _isValidReceiptContent(String text) {
    if (text.isEmpty || text.length < 20) {
      print('❌ Text too short to be a receipt');
      return false;
    }

    final lowerText = text.toLowerCase();
    int validationScore = 0;

    // Check for currency symbols/indicators (strong indicator)
    final currencyPatterns = [
      RegExp(r'[₱\$€£¥]'), // Currency symbols
      RegExp(r'\bphp\b|\bpeso\b|\busd\b|\bdollar\b', caseSensitive: false),
    ];
    for (var pattern in currencyPatterns) {
      if (pattern.hasMatch(text)) {
        validationScore += 3;
        print('✓ Currency symbol/indicator found (+3)');
        break;
      }
    }

    // Check for price patterns (very strong indicator)
    final pricePattern = RegExp(r'[₱\$]?\s*\d{1,3}(?:,\d{3})*\.\d{2}');
    final priceMatches = pricePattern.allMatches(text).length;
    if (priceMatches >= 2) {
      validationScore += 4;
      print('✓ Multiple price patterns found: $priceMatches (+4)');
    } else if (priceMatches == 1) {
      validationScore += 2;
      print('✓ Price pattern found (+2)');
    }

    // Check for receipt/transaction keywords
    final receiptKeywords = [
      'receipt',
      'transaction',
      'gcash',
      'payment',
      'transfer',
      'amount',
      'total',
      'paid',
      'sent',
      'received',
      'reference',
      'ref no',
      'transaction no',
      'order',
      'subtotal',
      'tax',
      'vat',
      'discount'
    ];
    int keywordMatches = 0;
    for (var keyword in receiptKeywords) {
      if (lowerText.contains(keyword)) {
        keywordMatches++;
      }
    }
    if (keywordMatches >= 3) {
      validationScore += 3;
      print('✓ Receipt keywords found: $keywordMatches (+3)');
    } else if (keywordMatches >= 1) {
      validationScore += 1;
      print('✓ Receipt keyword found (+1)');
    }

    // Check for merchant/store indicators
    final merchantKeywords = [
      'store',
      'shop',
      'mall',
      'market',
      'restaurant',
      'cafe',
      'gcash',
      'paymaya',
      'bank',
      'branch',
      'merchant',
      'seller',
      'cashier',
      'pos',
      'ltd',
      'inc',
      'corp'
    ];
    for (var keyword in merchantKeywords) {
      if (lowerText.contains(keyword)) {
        validationScore += 2;
        print('✓ Merchant indicator found (+2)');
        break;
      }
    }

    // Check for date patterns (common in receipts)
    final datePatterns = [
      RegExp(r'\d{1,2}/\d{1,2}/\d{2,4}'), // 12/13/2024
      RegExp(r'\d{4}-\d{2}-\d{2}'), // 2024-12-13
      RegExp(
          r'(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{1,2},?\s*\d{4}',
          caseSensitive: false),
    ];
    for (var pattern in datePatterns) {
      if (pattern.hasMatch(text)) {
        validationScore += 1;
        print('✓ Date pattern found (+1)');
        break;
      }
    }

    // Check for phone number patterns (common in money transfer receipts)
    final phonePattern = RegExp(r'(\+?63|0)\s*\d{3}\s*\d{3}\s*\d{4}');
    if (phonePattern.hasMatch(text)) {
      validationScore += 2;
      print('✓ Phone number found (+2)');
    }

    // Check for reference/transaction number patterns
    final refPattern = RegExp(
        r'(ref|reference|transaction|order)\s*(no|number)?\s*:?\s*[A-Z0-9]{6,}',
        caseSensitive: false);
    if (refPattern.hasMatch(text)) {
      validationScore += 2;
      print('✓ Reference number pattern found (+2)');
    }

    // Anti-patterns: Check for common non-receipt content
    final antiPatterns = [
      RegExp(r'(screenshot|wallpaper|meme|photo|selfie)', caseSensitive: false),
      RegExp(r'(instagram|facebook|twitter|tiktok)', caseSensitive: false),
    ];
    for (var pattern in antiPatterns) {
      if (pattern.hasMatch(text)) {
        validationScore -= 5;
        print('✗ Non-receipt indicator found (-5)');
        break;
      }
    }

    print(
        '📊 Receipt validation score: $validationScore (minimum required: 5)');

    // Need at least score of 5 to be considered a valid receipt
    // This ensures we have multiple indicators before accepting
    return validationScore >= 5;
  }

  // Process receipt image and extract data
  Future<ReceiptModel?> processReceipt(
    File imageFile,
    List<FeeRange> feeRanges,
  ) async {
    try {
      print('🔍 Starting receipt processing with OCR...');

      // Use Gemini AI for web platform
      if (kIsWeb) {
        print('🌐 Using Gemini AI for web platform...');
        return await _processReceiptWithGemini(imageFile, feeRanges);
      }

      if (_textRecognizer == null) {
        print('❌ Text recognizer not initialized');
        return null;
      }

      final InputImage inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer!.processImage(inputImage);

      final text = recognizedText.text;
      print('📄 Extracted text length: ${text.length}');
      print('📝 RAW OCR TEXT:\n$text\n---END RAW TEXT---');

      // Validate if this is actually a receipt
      print('🔍 Validating receipt content...');
      if (!_isValidReceiptContent(text)) {
        print('❌ Image does not appear to be a valid receipt');
        throw Exception(
            'This image does not appear to be a receipt. Please upload a valid receipt or transaction image.');
      }
      print('✅ Receipt validation passed');

      // Normalize and structure the text
      final normalizedText = _normalizeReceiptText(text);
      print('🔄 NORMALIZED TEXT:\n$normalizedText\n---END NORMALIZED---');

      // Detect transaction type first
      final isBankTransfer = _isBankTransfer(normalizedText);
      print(
          '💳 Transaction type: ${isBankTransfer ? "BANK TRANSFER" : "MONEY TRANSFER"}');

      if (isBankTransfer) {
        return _extractBankTransferData(normalizedText, feeRanges);
      } else {
        return _extractReceiptData(normalizedText, feeRanges);
      }
    } catch (e) {
      print('❌ Error processing receipt: $e');
      rethrow;
    }
  }

  // Process receipt using Gemini AI for text extraction on web, then use OCR logic
  // NOTE: For GCash receipts with colored boxes (yellow, blue, red), Gemini AI
  // in gemini_service.dart is better equipped to identify and extract data from
  // the colored regions. This method is mainly for simple text extraction.
  Future<ReceiptModel?> _processReceiptWithGemini(
    File imageFile,
    List<FeeRange> feeRanges,
  ) async {
    try {
      print('🤖 Using Gemini AI to extract text from image...');

      // Read image bytes from stored XFile (works on web)
      if (_lastPickedImage == null) {
        print('❌ No image file available');
        return null;
      }

      final imageBytes = await _lastPickedImage!.readAsBytes();
      print('✅ Read ${imageBytes.length} bytes from image');

      // Use Gemini to extract ALL text from the image
      // For GCash receipts with colored boxes, the analyzeReceiptImage method
      // in GeminiService provides better extraction with color-box detection
      const prompt = '''
Extract ALL text from this receipt image. 
Output ONLY the text exactly as it appears, line by line.
Do not add any analysis, formatting, or explanations.
Just output the raw text content.
''';

      final extractedText = await _geminiService.generateContentWithImage(
        prompt,
        imageBytes,
      );

      if (extractedText == null || extractedText.isEmpty) {
        print('❌ Gemini AI could not extract text');
        return null;
      }

      print('📄 Extracted text length: ${extractedText.length}');
      print('📝 RAW TEXT FROM GEMINI:\n$extractedText\n---END RAW TEXT---');

      // Validate if this is actually a receipt
      print('🔍 Validating receipt content...');
      if (!_isValidReceiptContent(extractedText)) {
        print('❌ Image does not appear to be a valid receipt');
        throw Exception(
            'This image does not appear to be a receipt. Please upload a valid receipt or transaction image.');
      }
      print('✅ Receipt validation passed');

      // Now use YOUR existing OCR logic to parse the text
      final normalizedText = _normalizeReceiptText(extractedText);
      print('🔄 NORMALIZED TEXT:\n$normalizedText\n---END NORMALIZED---');

      // Detect transaction type first
      final isBankTransfer = _isBankTransfer(normalizedText);
      print(
          '💳 Transaction type: ${isBankTransfer ? "BANK TRANSFER" : "MONEY TRANSFER"}');

      // Use YOUR extraction logic
      if (isBankTransfer) {
        return _extractBankTransferData(normalizedText, feeRanges);
      } else {
        return _extractReceiptData(normalizedText, feeRanges);
      }
    } catch (e) {
      print('❌ Error processing with Gemini: $e');
      rethrow;
    }
  }

  // Convert Gemini AI result to ReceiptModel

  // Convert all masking characters (asterisks and dots) to bullets for consistency
  String _convertMaskingToBullets(String name) {
    // Convert asterisks (*) to bullets (•)
    String converted = name.replaceAll('*', '•');

    // Convert dots (.) to bullets (•), but preserve the final dot at the end
    if (converted.endsWith('.')) {
      // Replace all dots except the last one
      final withoutEnd = converted.substring(0, converted.length - 1);
      final endDot = converted.substring(converted.length - 1);
      converted = withoutEnd.replaceAll('.', '•') + endDot;
    } else {
      // No ending period, replace all dots
      converted = converted.replaceAll('.', '•');
    }

    return converted;
  }

  // Clean receipt text by removing promotional and UI noise
  String _cleanReceiptText(String rawText) {
    final lines = rawText.split('\n');
    final cleanedLines = <String>[];

    // Noise patterns to ignore (promotional text, UI elements, etc.)
    final noisePatterns = [
      // Promotional text
      RegExp(r'reward|unlock|surprise|claim|download', caseSensitive: false),
      // Carbon footprint text
      RegExp(r'carbon|footprint|digital|transportation|paper|plastic|gco2e',
          caseSensitive: false),
      // UI elements
      RegExp(r'^[xX]\s*$', caseSensitive: false),
      RegExp(r'^>\s*$', caseSensitive: false),
      RegExp(r'^\d{1,2}:\d{2}\s*>\s*$'), // Time with arrow like "12:47 >"
      // Network/data indicators
      RegExp(r'\d+G\s*,\s*\d+G', caseSensitive: false), // "45G, 4G."
      RegExp(r'kr/s|kg/s|mb/s', caseSensitive: false),
      // Button text
      RegExp(r'^(share|claim|download|view|login|win)\s*$',
          caseSensitive: false),
      // Random promotional text patterns
      RegExp(r'(logim|cetso|spm|tsuperic|realwin|jljl|temu)',
          caseSensitive: false),
      RegExp(r'sinusuportahan|nangungun|free gift|receive',
          caseSensitive: false),
      // Labels that look like names but aren't
      RegExp(
          r'^(reference no|ref no|amount|total|date|schedule|convenience fee)\.$',
          caseSensitive: false),
      // Random short lines with symbols
      RegExp(r'^[^\w\s]{2,}$'), // Lines with only symbols
      // Numbers without context (standalone random numbers under 100)
      RegExp(r'^\d{1,2}$'), // Single/double digit lines like "91"
      // Random number combinations with commas
      RegExp(r'^\d+,\s*\d+,\s*$'), // Like "40, 456,"
    ];

    for (int i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.isEmpty) continue;

      // Check if line matches any noise pattern
      bool isNoise = false;
      for (var pattern in noisePatterns) {
        if (pattern.hasMatch(trimmed)) {
          isNoise = true;
          print('🗑️ Filtered noise: "$trimmed"');
          break;
        }
      }

      // ALSO check if the NEXT line is noise - if so, this might be related noise
      if (!isNoise && i + 1 < lines.length) {
        final nextLine = lines[i + 1].trim();
        // If current line is just a small number and next line is noise, skip it
        if (RegExp(r'^\d+\.\d{2}$').hasMatch(trimmed)) {
          for (var pattern in noisePatterns) {
            if (pattern.hasMatch(nextLine)) {
              isNoise = true;
              print('🗑️ Filtered noise (before noise): "$trimmed"');
              break;
            }
          }
        }
      }

      if (!isNoise) {
        cleanedLines.add(trimmed);
      }
    }

    return cleanedLines.join('\n');
  }

  // Detect GCash receipt structure pattern
  // GCash receipts have a specific layout:
  // 1. Recipient name at top (may be masked like "JE....Y Z.")
  // 2. Phone number below name
  // 3. "Sent via GCash" indicator
  // 4. "Amount" section with value
  // 5. "Total Amount Sent" display
  // 6. "Ref No." with reference number and date at bottom
  bool _isGCashStructuredReceipt(List<String> lines) {
    // Check for GCash receipt indicators
    final text = lines.join('\n').toLowerCase();
    if (!text.contains('gcash') && !text.contains('sent via gcash')) {
      return false;
    }

    // Check if we have the typical GCash receipt structure:
    // - A name pattern near the top
    // - A phone number below it
    // - Amount labeled section
    // - Ref number at bottom
    int nameLineIndex = -1;
    int phoneLineIndex = -1;
    int amountLineIndex = -1;
    int refLineIndex = -1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();

      // Name pattern (masked like "JE....Y Z." or full name)
      if (nameLineIndex == -1 &&
          RegExp(r'^[A-Za-z]{2}[A-Za-z•*\.\s]{2,10}[A-Za-z]\.?$')
              .hasMatch(lines[i])) {
        nameLineIndex = i;
      }

      // Phone pattern
      if (phoneLineIndex == -1 &&
          RegExp(r'\+?63\s*\d{3}\s*\d{3}\s*\d{4}').hasMatch(lines[i])) {
        phoneLineIndex = i;
      }

      // Amount section
      if (amountLineIndex == -1 && line.contains('amount')) {
        amountLineIndex = i;
      }

      // Ref number section
      if (refLineIndex == -1 &&
          (line.contains('ref') || line.contains('reference'))) {
        refLineIndex = i;
      }
    }

    // If we have name -> phone -> amount -> ref in that order, it's a standard GCash receipt
    final hasStructure = nameLineIndex >= 0 &&
        phoneLineIndex > nameLineIndex &&
        amountLineIndex > phoneLineIndex &&
        refLineIndex > amountLineIndex;

    if (hasStructure) {
      print('📱 Detected standard GCash receipt structure!');
    }

    return hasStructure;
  }

  // Extract data from standard GCash receipt structure
  Map<String, String?> _extractFromGCashStructure(List<String> lines) {
    print('📱 Extracting data from GCash receipt structure...');

    String? recipientName;
    String? phoneNumber;
    String? amount;
    String? refNumber;
    String? dateStr;

    // SECTION 1 (TOP) - Recipient Name
    // Look for name pattern in first 10-15 lines (before "sent via gcash")
    for (int i = 0; i < lines.length && i < 15; i++) {
      final line = lines[i].trim();
      if (line.toLowerCase().contains('sent via') ||
          line.toLowerCase().contains('gcash') ||
          line.toLowerCase().contains('amount')) {
        break; // Stop at service name or amount section
      }

      // Match name patterns: "JE....Y Z." (dots), "MA****N M." (asterisks), or full names
      if (RegExp(r'^[A-Za-z]{2}[A-Za-z•*\.\s]{1,10}[A-Za-z]{1,2}\.?$')
          .hasMatch(line)) {
        recipientName = _convertMaskingToBullets(line);
        print('📋 [Top Section] Recipient Name: "$recipientName"');
        break;
      }
    }

    // SECTION 2 - Phone Number (below recipient name)
    // Look for phone right after name or before amount section
    for (int i = 0; i < lines.length && i < 20; i++) {
      final line = lines[i];
      if (RegExp(r'\+?63\s*\d{3}\s*\d{3}\s*\d{4}|0\d{3}\s*\d{3}\s*\d{4}')
          .hasMatch(line)) {
        final match =
            RegExp(r'\+?63\s*\d{3}\s*\d{3}\s*\d{4}|0\d{3}\s*\d{3}\s*\d{4}')
                .firstMatch(line);
        if (match != null) {
          phoneNumber = match.group(0);
          print('📞 [Below Name] Phone Number: "$phoneNumber"');
          break;
        }
      }
    }

    // SECTION 3 - Amount (in "Amount" section)
    // Look for "Amount" label followed by the value
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      if (line.contains('amount') && !line.contains('total')) {
        // Amount value is usually on the same line or next line
        final amountMatch =
            RegExp(r'[P₱]?\s*[\d,]+\.\d{2}').firstMatch(lines[i]);
        if (amountMatch != null) {
          amount = amountMatch.group(0);
          print('💰 [Amount Section] Amount: "$amount"');
          break;
        } else if (i + 1 < lines.length) {
          final nextMatch =
              RegExp(r'[P₱]?\s*[\d,]+\.\d{2}').firstMatch(lines[i + 1]);
          if (nextMatch != null) {
            amount = nextMatch.group(0);
            print('💰 [Amount Section] Amount: "$amount"');
            break;
          }
        }
      }
    }

    // SECTION 4 (BOTTOM) - Reference Number & Date
    // Look for "Ref No" section, usually near bottom
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      if (line.contains('ref') &&
          (line.contains('no') || line.contains('number'))) {
        // Ref number is usually on same line or next line
        final refMatch =
            RegExp(r'\d{4}\s+\d{3}\s+\d{6,9}|\d{10,20}').firstMatch(lines[i]);
        if (refMatch != null) {
          refNumber = refMatch.group(0);
          print('🔢 [Bottom Section] Ref Number: "$refNumber"');
        } else if (i + 1 < lines.length) {
          final nextMatch = RegExp(r'\d{4}\s+\d{3}\s+\d{6,9}|\d{10,20}')
              .firstMatch(lines[i + 1]);
          if (nextMatch != null) {
            refNumber = nextMatch.group(0);
            print('🔢 [Bottom Section] Ref Number: "$refNumber"');
          }
        }

        // Date is usually on same line or right after ref number
        final datePattern = RegExp(
            r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2},?\s*\d{4}\s+\d{1,2}:\d{2}\s*(AM|PM)',
            caseSensitive: false);

        // Check current line and next few lines
        for (int j = i; j < lines.length && j < i + 3; j++) {
          final dateMatch = datePattern.firstMatch(lines[j]);
          if (dateMatch != null) {
            dateStr = dateMatch.group(0);
            print('📅 [Bottom Section] Date: "$dateStr"');
            break;
          }
        }
        break;
      }
    }

    return {
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'refNumber': refNumber,
      'dateStr': dateStr,
    };
  }

  // Normalize and structure OCR text into consistent format
  String _normalizeReceiptText(String rawText) {
    // Filter out noise and promotional text first
    final cleanedText = _cleanReceiptText(rawText);

    final lines = cleanedText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // 📱 CHECK FOR STANDARD GCASH RECEIPT STRUCTURE FIRST
    final isGCashStructured = _isGCashStructuredReceipt(lines);
    if (isGCashStructured) {
      final gcashData = _extractFromGCashStructure(lines);

      // If we successfully extracted from GCash structure, use that data
      if (gcashData['recipientName'] != null ||
          gcashData['phoneNumber'] != null ||
          gcashData['amount'] != null) {
        print('✅ Using GCash structure extraction results');

        // Build normalized text with GCash structure data
        final normalized = StringBuffer();
        normalized.writeln('--- GCASH RECEIPT ---');
        if (gcashData['recipientName'] != null) {
          normalized.writeln('Recipient: ${gcashData['recipientName']}');
        }
        if (gcashData['phoneNumber'] != null) {
          normalized.writeln('Phone: ${gcashData['phoneNumber']}');
        }
        if (gcashData['amount'] != null) {
          normalized.writeln('Amount: ${gcashData['amount']}');
        }
        if (gcashData['refNumber'] != null) {
          normalized.writeln('Ref No: ${gcashData['refNumber']}');
        }
        if (gcashData['dateStr'] != null) {
          normalized.writeln('Date: ${gcashData['dateStr']}');
        }
        normalized.writeln('--- END RECEIPT ---');
        normalized.writeln('\nORIGINAL TEXT:');
        normalized.writeln(rawText);

        return normalized.toString();
      }
    }

    // Define field patterns and their normalized keys
    final fieldMappings = {
      'recipient':
          RegExp(r'^[A-Za-z]{2}[A-Za-z•*\.eom_\-\s]{0,10}[A-Za-z]{1,2}\.?$'),
      'phone': RegExp(r'\+?63\s*\d{3}\s*\d{3}\s*\d{4}|0\d{3}\s*\d{3}\s*\d{4}'),
      'amount': RegExp(r'[P₱]?\s*[\d,]+\.\d{2}'),
      'ref_number': RegExp(r'\d{4}\s+\d{3}\s+\d{6,9}|\d{10,20}'),
      'date': RegExp(
          r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2},?\s*\d{4}',
          caseSensitive: false),
    };

    String? recipientName;
    String? phoneNumber;
    String? amount;
    String? refNumber;
    String? dateStr;

    // PRIORITY 1: Check if this is a LOAD transaction
    // If load, extract the product name at the TOP as recipient
    final isLoad = _isLoadTransaction(cleanedText, cleanedText.toLowerCase());
    if (isLoad) {
      // MOBILE LOAD STRUCTURE:
      // - TOP SECTION (red annotation area) = Load/Promo Name
      // - BELOW (blue annotation area) = Mobile Number
      // Extract the FIRST/TOP line that looks like a product name
      // This appears at the very top before the phone number

      for (int i = 0; i < lines.length && i < 10; i++) {
        final line = lines[i].trim();
        // Match product names like "EasySURF50+5G+FunALIW+", "GIGA50", "AllNet99"
        // These are in the TOP section (red annotation area)
        // Look for: mixed case, numbers, special chars, NOT person name format
        if (line.length >= 5 &&
            RegExp(r'[A-Z0-9][A-Za-z0-9\s+\-]{2,}', caseSensitive: true)
                .hasMatch(line)) {
          // Avoid labels and common words
          if (!RegExp(
                  r'(paid|via|amount|total|date|fee|gcash|reference|convenience)',
                  caseSensitive: false)
              .hasMatch(line)) {
            // This is likely the load/promo name at the TOP
            recipientName = line.endsWith('.') ? line : line + '.';
            print(
                '✅ [Normalization] LOAD transaction - promo name from TOP: "$recipientName"');
            break;
          }
        }
      }
      // Fallback if no product name found
      if (recipientName == null) {
        recipientName = 'Load.';
        print('✅ [Normalization] LOAD transaction - using default "Load."');
      }
    }

    // PRIORITY 2: Look for recipient name immediately before phone number
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // If this line is a phone number, check the previous line for name
      if (fieldMappings['phone']!.hasMatch(line) &&
          i > 0 &&
          recipientName == null) {
        final prevLine = lines[i - 1].trim();
        // Check if previous line looks like a name (letters, spaces, dots)
        // But NOT a label like "Reference No.", "Amount", etc.
        if (RegExp(r'^[A-Za-z]{2}[A-Za-z•*\.\s]+[A-Za-z]\.?$',
                    caseSensitive: false)
                .hasMatch(prevLine) &&
            !RegExp(r'(reference|amount|total|date|fee|schedule|no\.)',
                    caseSensitive: false)
                .hasMatch(prevLine)) {
          recipientName = _convertMaskingToBullets(prevLine);
          print(
              '✅ [Normalization] Found recipient BEFORE phone: "$recipientName"');
          break;
        }
      }
    }

    // First pass: Extract labeled data
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lowerLine = line.toLowerCase();

      // Extract recipient name (usually appears before phone or after "Amount" label)
      if (recipientName == null &&
          fieldMappings['recipient']!.hasMatch(line) &&
          !RegExp(r'(gcash|via|sent|transfer|amount|fee|total|ref)',
                  caseSensitive: false)
              .hasMatch(line)) {
        recipientName = _convertMaskingToBullets(line);
        print('✅ [Normalization] Found recipient: "$recipientName"');
      }

      // Extract phone number
      if (phoneNumber == null && fieldMappings['phone']!.hasMatch(line)) {
        final match = fieldMappings['phone']!.firstMatch(line);
        if (match != null) {
          phoneNumber = match.group(0);
          print('✅ [Normalization] Found phone: "$phoneNumber"');
        }
      }

      // Extract reference number
      if ((lowerLine.contains('ref') || lowerLine.contains('reference')) &&
          refNumber == null) {
        // Check current line and next lines
        final refMatch = fieldMappings['ref_number']!.firstMatch(line);
        if (refMatch != null) {
          refNumber = refMatch.group(0);
          print('✅ [Normalization] Found ref from current line: "$refNumber"');
        } else if (i + 1 < lines.length) {
          final nextMatch =
              fieldMappings['ref_number']!.firstMatch(lines[i + 1]);
          if (nextMatch != null) {
            refNumber = nextMatch.group(0);
            print('✅ [Normalization] Found ref from next line: "$refNumber"');
          }
        }
      }

      // Extract amount (look for "Total Amount Sent" or standalone amount)
      if (amount == null &&
          (lowerLine.contains('amount') || lowerLine.contains('total'))) {
        // Check current line first
        final amountMatch = fieldMappings['amount']!.firstMatch(line);
        if (amountMatch != null) {
          amount = amountMatch.group(0);
          print('✅ [Normalization] Found amount from current line: "$amount"');
        } else {
          // PRIORITY: Look for "Total Amount Sent" specifically, then get LARGEST STANDALONE amount
          if (lowerLine.contains('total') &&
              lowerLine.contains('amount') &&
              lowerLine.contains('sent')) {
            // Check next lines and collect ALL standalone amounts
            final foundAmounts = <String>[];
            for (int j = i + 1; j < lines.length && j < i + 15; j++) {
              final nextLine = lines[j].trim();
              // Match STANDALONE amount line: just "850.00" or "P850.00" or "₱850.00"
              final standaloneMatch =
                  RegExp(r'^[P₱]?\s*[\d,]+\.\d{2}$').firstMatch(nextLine);
              if (standaloneMatch != null) {
                foundAmounts.add(standaloneMatch.group(0)!);
              }
            }

            // Pick the LARGEST amount (the actual transaction amount, not fees or random numbers)
            if (foundAmounts.isNotEmpty) {
              double maxValue = 0.0;
              String maxAmount = '';
              for (var amt in foundAmounts) {
                final cleaned = amt.replaceAll(RegExp(r'[P₱,\s]'), '');
                final value = double.tryParse(cleaned) ?? 0.0;
                if (value > maxValue) {
                  maxValue = value;
                  maxAmount = amt;
                }
              }
              if (maxAmount.isNotEmpty) {
                amount = maxAmount;
                print(
                    '✅ [Normalization] Found LARGEST amount after Total Amount Sent: "$amount" (from ${foundAmounts.length} candidates)');
              }
            }
          } else {
            // Fallback: Check next few lines for any amount
            for (int j = i + 1; j < lines.length && j < i + 3; j++) {
              final nextLine = lines[j].trim();
              // Skip lines with other text (like "KR/S", "kg", etc.)
              if (RegExp(r'[A-Za-z]{2,}')
                  .hasMatch(nextLine.replaceAll(RegExp(r'^[P₱]\s*'), ''))) {
                continue; // Skip if line has letters after removing currency
              }
              final nextAmount = fieldMappings['amount']!.firstMatch(nextLine);
              if (nextAmount != null) {
                amount = nextAmount.group(0);
                print(
                    '✅ [Normalization] Found amount from next line: "$amount"');
                break;
              }
            }
          }
        }
      }

      // Extract date
      if (dateStr == null && fieldMappings['date']!.hasMatch(line)) {
        dateStr = line;
      }
    }

    // Second pass: If amount not found, look for standalone currency values
    if (amount == null) {
      for (final line in lines) {
        if (fieldMappings['amount']!.hasMatch(line) &&
            !RegExp(r'(fee|service|carbon)', caseSensitive: false)
                .hasMatch(line)) {
          amount = line;
          break;
        }
      }
    }

    // Build normalized text with consistent structure
    final normalized = StringBuffer();

    normalized.writeln('--- GCASH RECEIPT ---');
    if (recipientName != null) {
      normalized.writeln('Recipient: $recipientName');
    }
    if (phoneNumber != null) {
      normalized.writeln('Phone: $phoneNumber');
    }
    if (amount != null) {
      normalized.writeln('Amount: $amount');
    }
    if (refNumber != null) {
      normalized.writeln('Ref No: $refNumber');
    }
    if (dateStr != null) {
      normalized.writeln('Date: $dateStr');
    }
    normalized.writeln('--- END RECEIPT ---');

    // Also append original text for fallback
    normalized.writeln('\nORIGINAL TEXT:');
    normalized.writeln(rawText);

    return normalized.toString();
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

  // Extract bank transfer data - SMART EXTRACTION with multiple strategies
  ReceiptModel? _extractBankTransferData(
      String text, List<FeeRange> feeRanges) {
    try {
      print('🏦 Extracting bank transfer data with SMART extraction...');

      // Extract bank name with fallbacks
      String bankName = _extractBankName(text);
      if (bankName.isEmpty) {
        bankName = _extractBankNameSmart(text);
      }
      print('Bank: $bankName');

      // Extract account number
      String accountNumber = _extractAccountNumber(text);
      print('Account Number: $accountNumber');

      // Extract account name with fallbacks
      String accountName = _extractAccountName(text);
      if (accountName.isEmpty) {
        accountName = _extractAccountNameSmart(text);
      }
      print('Account Name: $accountName');

      // Extract receipt email
      String receiptEmail = _extractEmail(text);
      print('Receipt Email: $receiptEmail');

      // Extract transfer amount with fallbacks
      double amount = _extractAmount(text);
      if (amount == 0) {
        amount = _extractAmountSmart(text);
      }
      print('Transfer Amount: $amount');

      // Extract bank fee from "+Fee" label
      double bankFee = _extractBankFee(text);
      print('Bank Fee (+Fee): $bankFee');

      // Extract total from "Total" label
      double total = _extractTotal(text);
      print('Total: $total');

      // If amount is still 0 but we have total and fee, calculate it
      if (amount == 0 && total > 0) {
        amount = total - bankFee;
        print('💡 Calculated amount from total: $amount');
      }

      // Extract reference number with fallbacks
      String refNumber = _extractReferenceNumber(text);
      if (refNumber.isEmpty) {
        refNumber = _extractReferenceNumberSmart(text);
      }
      print('Ref No: $refNumber');

      // Extract transfer date from "Transfer Date" label
      DateTime date = _extractDate(text);
      print('Transfer Date: $date');

      // SMART VALIDATION: Be more lenient
      // Need at least: (account name OR bank name) AND amount
      final hasIdentifier = accountName.isNotEmpty || bankName.isNotEmpty;
      final hasAmount = amount > 0;

      if (!hasIdentifier && !hasAmount) {
        print('❌ Failed to extract ANY bank transfer data');
        return null;
      }

      // Use defaults for missing fields
      if (accountName.isEmpty) {
        accountName = 'Unknown Account';
        print('⚠️ Warning: Account name not found, using default');
      }
      if (bankName.isEmpty) {
        bankName = 'Unknown Bank';
        print('⚠️ Warning: Bank name not found, using default');
      }

      print(
          '✅ Bank transfer extraction successful (some fields may be partial)!');

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
        accountNumber: accountNumber.isNotEmpty ? accountNumber : null,
        receiptEmail: receiptEmail.isNotEmpty ? receiptEmail : null,
      );
    } catch (e) {
      print('❌ Error extracting bank transfer data: $e');
      return null;
    }
  }

  // SMART BANK NAME EXTRACTION
  String _extractBankNameSmart(String text) {
    final commonBanks = [
      'MariBank',
      'BPI',
      'BDO',
      'Metrobank',
      'UnionBank',
      'Security Bank',
      'Chinabank',
      'RCBC',
      'PNB',
      'Landbank',
      'DBP',
      'PSBank',
      'EastWest',
      'CIMB',
      'ING',
      'Komo',
      'Tonik',
      'Maya Bank',
      'GCash',
      'SeaBank',
      'GoTyme',
      'UNO Digital'
    ];

    final lowerText = text.toLowerCase();
    for (var bank in commonBanks) {
      if (lowerText.contains(bank.toLowerCase())) {
        print('✅ Smart extraction found bank: "$bank"');
        return bank;
      }
    }
    return '';
  }

  // SMART ACCOUNT NAME EXTRACTION
  String _extractAccountNameSmart(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Look for ALL CAPS names (common in bank transfers)
    final allCapsPattern = RegExp(r'^[A-Z][A-Z\s\.]{3,40}$');

    for (var line in lines) {
      // Skip common labels
      if (RegExp(
              r'(BANK|TRANSFER|AMOUNT|FEE|TOTAL|REF|ACCOUNT\s*NO|RECEIPT|GCASH|INSTAPAY|PESONET)',
              caseSensitive: false)
          .hasMatch(line)) {
        continue;
      }

      if (allCapsPattern.hasMatch(line)) {
        // Check it looks like a name (has letters, maybe spaces/dots)
        final wordCount = line.split(RegExp(r'\s+')).length;
        if (wordCount >= 1 && wordCount <= 4 && line.length >= 4) {
          print('✅ Smart extraction found account name: "$line"');
          return line;
        }
      }
    }

    return '';
  }

  // Extract receipt data from OCR text - SMART EXTRACTION with multiple strategies
  ReceiptModel? _extractReceiptData(String text, List<FeeRange> feeRanges) {
    try {
      print('📊 Extracting receipt data with SMART extraction...');

      // STRATEGY 1: Try normalized section first
      String recipientName = _extractFromNormalized(text, 'Recipient');
      if (recipientName.isEmpty) {
        recipientName = _extractRecipientName(text);
      }

      // STRATEGY 2: If still empty, try alternative name extraction
      if (recipientName.isEmpty) {
        recipientName = _extractRecipientNameSmart(text);
      }
      print('👤 Recipient Name: "$recipientName"');

      // Extract phone number with multiple strategies
      String phoneNumber = _extractFromNormalized(text, 'Phone');
      if (phoneNumber.isEmpty) {
        phoneNumber = _extractPhoneNumber(text);
      }
      // STRATEGY 2: Try smart phone extraction
      if (phoneNumber.isEmpty) {
        phoneNumber = _extractPhoneNumberSmart(text);
      }
      print('📱 Phone Number: "$phoneNumber"');

      // Extract amount with multiple strategies
      double amount = 0.0;
      final amountStr = _extractFromNormalized(text, 'Amount');
      if (amountStr.isNotEmpty) {
        final cleaned = amountStr.replaceAll(RegExp(r'[P₱,\s]'), '');
        amount = double.tryParse(cleaned) ?? 0.0;
      }
      if (amount == 0.0) {
        amount = _extractAmount(text);
      }
      // STRATEGY 2: Try smart amount extraction
      if (amount == 0.0) {
        amount = _extractAmountSmart(text);
      }
      print('💵 Amount: ₱$amount');

      // Calculate fee based on amount and fee ranges
      double fee = _calculateFee(amount, feeRanges);

      // Extract reference number with fallbacks
      String refNumber = _extractFromNormalized(text, 'Ref No');
      if (refNumber.isEmpty) {
        refNumber = _extractReferenceNumber(text);
      }
      // STRATEGY 2: Try smart reference extraction
      if (refNumber.isEmpty) {
        refNumber = _extractReferenceNumberSmart(text);
      }
      print('🔢 Reference Number: "$refNumber"');

      // Extract date
      DateTime date = DateTime.now();
      final dateStr = _extractFromNormalized(text, 'Date');
      if (dateStr.isNotEmpty) {
        try {
          date = _parseDate(dateStr);
        } catch (e) {
          date = _extractDate(text);
        }
      } else {
        date = _extractDate(text);
      }
      print('📅 Date: $date');

      // SMART VALIDATION: Be more lenient - allow partial data
      // At minimum, we need at least ONE of: (name OR phone) AND amount
      final hasIdentifier = recipientName.isNotEmpty || phoneNumber.isNotEmpty;
      final hasAmount = amount > 0;

      if (!hasIdentifier && !hasAmount) {
        print('❌ Failed to extract ANY required data:');
        print('   - Recipient: ${recipientName.isEmpty ? "MISSING" : "OK"}');
        print('   - Phone: ${phoneNumber.isEmpty ? "MISSING" : "OK"}');
        print('   - Amount: ${amount == 0 ? "MISSING" : "OK"}');
        return null;
      }

      // Warn about missing but non-critical fields
      if (recipientName.isEmpty) {
        print('⚠️ Warning: Recipient name not found, using "Unknown"');
        recipientName = 'Unknown';
      }
      if (phoneNumber.isEmpty) {
        print('⚠️ Warning: Phone number not found');
      }
      if (amount == 0) {
        print('⚠️ Warning: Amount is 0 - might need manual entry');
      }

      print('✅ Data extracted (some fields may be partial)!');
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
      print('❌ Error extracting receipt data: $e');
      return null;
    }
  }

  // SMART NAME EXTRACTION - More aggressive patterns
  String _extractRecipientNameSmart(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // PRIORITY: Look for names with bullet dots first (MA•S B., MA......S B., AL•OC., etc.)
    for (var line in lines) {
      if (line.contains('•') || line.contains('*') || line.contains('.')) {
        // Check if it matches masked name pattern (with multiple symbols)
        final maskedPattern = RegExp(
            r'^[A-Z]{2}[•*\.]+[A-Z]{1,3}(?:\s+[A-Z]\.)?$',
            caseSensitive: true);
        if (maskedPattern.hasMatch(line)) {
          final normalized =
              _convertMaskingToBullets(line.endsWith('.') ? line : '$line.');
          print('✅ Smart extraction found bullet-dot name: "$normalized"');
          return normalized;
        }
      }
    }

    // Pattern 1: Look for any line that looks like a name (2+ words, mostly letters)
    final namePattern = RegExp(r'^[A-Za-z][A-Za-z\s\.\*•\-]{3,30}[A-Za-z\.]$');

    for (var line in lines) {
      // Skip common non-name lines
      if (RegExp(
              r'(gcash|maya|bank|transfer|amount|fee|total|ref|via|sent|receipt|transaction|service|powered|carbon|digital|instapay|pesonet)',
              caseSensitive: false)
          .hasMatch(line)) {
        continue;
      }

      if (namePattern.hasMatch(line)) {
        // Validate it looks like a name
        final wordCount = line.split(RegExp(r'\s+')).length;
        if (wordCount >= 1 && wordCount <= 5) {
          final normalized =
              _convertMaskingToBullets(line.endsWith('.') ? line : '$line.');
          print('✅ Smart extraction found name: "$normalized"');
          return normalized;
        }
      }
    }

    // Pattern 2: Look for masked name format anywhere
    final maskedPattern = RegExp(r'[A-Z]{2}[\*•\.]{1,10}[A-Z](?:\s+[A-Z]\.?)?',
        caseSensitive: false);
    final maskedMatch = maskedPattern.firstMatch(text);
    if (maskedMatch != null) {
      final name = maskedMatch.group(0)!.trim();
      if (name.length >= 4) {
        final normalized =
            _convertMaskingToBullets(name.endsWith('.') ? name : '$name.');
        print('✅ Smart extraction found masked name: "$normalized"');
        return normalized;
      }
    }

    // Pattern 3: Look for name after common labels
    final labelPatterns = [
      RegExp(
          r'(?:to|recipient|send\s*to|receiver)[:\s]+([A-Za-z][A-Za-z\s\.\*•\-]{2,30})',
          caseSensitive: false),
      RegExp(r'(?:name)[:\s]+([A-Za-z][A-Za-z\s\.\*•\-]{2,30})',
          caseSensitive: false),
    ];

    for (var pattern in labelPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final name = match.group(1)!.trim();
        if (name.length >= 3 &&
            !RegExp(r'(gcash|maya|bank)', caseSensitive: false)
                .hasMatch(name)) {
          print('✅ Smart extraction found labeled name: "$name"');
          final normalized =
              _convertMaskingToBullets(name.endsWith('.') ? name : '$name.');
          return normalized;
        }
      }
    }

    return '';
  }

  // SMART PHONE EXTRACTION - More aggressive patterns
  String _extractPhoneNumberSmart(String text) {
    // Remove all whitespace first for easier matching
    final cleanText = text.replaceAll(RegExp(r'\s+'), ' ');

    // Pattern 1: Any sequence of 10-13 digits that looks like a phone
    final digitGroups = RegExp(r'[\d\s]{10,15}').allMatches(cleanText);
    for (var match in digitGroups) {
      final digits = match.group(0)!.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 10 && digits.length <= 13) {
        // Check if it starts with valid PH prefix
        if (digits.startsWith('63') ||
            digits.startsWith('9') ||
            digits.startsWith('0')) {
          String phone = digits;
          if (phone.startsWith('0')) {
            phone = '+63${phone.substring(1)}';
          } else if (phone.startsWith('9') && phone.length == 10) {
            phone = '+63$phone';
          } else if (phone.startsWith('63')) {
            phone = '+$phone';
          }
          print('✅ Smart extraction found phone: "$phone"');
          return phone;
        }
      }
    }

    return '';
  }

  // SMART AMOUNT EXTRACTION - Find the largest currency value
  double _extractAmountSmart(String text) {
    // Find ALL numbers that look like money
    final amountPattern = RegExp(r'[P₱]?\s*([\d,]+\.?\d{0,2})');
    final matches = amountPattern.allMatches(text);

    double maxAmount = 0.0;
    for (var match in matches) {
      final amountStr = match.group(1)?.replaceAll(',', '') ?? '';
      final amount = double.tryParse(amountStr) ?? 0.0;

      // Skip values that look like phone numbers (too many digits without decimal)
      if (amountStr.length > 7 && !amountStr.contains('.')) continue;

      // Skip very small values (likely fees) and very large (likely ref numbers)
      if (amount >= 1.0 && amount <= 500000.0) {
        // Prefer amounts that seem like transaction amounts (larger, rounded)
        if (amount > maxAmount) {
          maxAmount = amount;
        }
      }
    }

    if (maxAmount > 0) {
      print('✅ Smart extraction found amount: ₱$maxAmount');
    }
    return maxAmount;
  }

  // SMART REFERENCE EXTRACTION - Find any long alphanumeric sequence
  // Handles formats like: 803512902111S, 5034124744068, etc.
  String _extractReferenceNumberSmart(String text) {
    final lines = text.split('\n');

    // Strategy 1: Look for "Ref No." line specifically and extract value
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lowerLine = line.toLowerCase();

      // Skip InstaPay Invoice lines
      if (lowerLine.contains('instapay') || lowerLine.contains('invoice'))
        continue;

      // Look for ref no patterns (more flexible)
      if (lowerLine.contains('ref') && !lowerLine.contains('invoice')) {
        // Try to get alphanumeric value from same line (reduced minimum from 10 to 8)
        final match = RegExp(r'[:\s]([A-Za-z0-9]{8,20})$').firstMatch(line);
        if (match != null) {
          final refStr = match.group(1)!;
          final digitsOnly = refStr.replaceAll(RegExp(r'[^0-9]'), '');
          if (digitsOnly.length >= 8) {
            print(
                '✅ Smart extraction found reference (Ref No line): "$refStr"');
            return refStr;
          }
        }

        // Check next 1-2 lines more flexibly
        for (int j = i + 1; j < lines.length && j < i + 3; j++) {
          final nextLine = lines[j].trim();
          if (nextLine.isEmpty) continue;

          // Match alphanumeric reference (8+ chars, more flexible)
          if (RegExp(r'^[A-Za-z0-9\s\-]{8,25}$').hasMatch(nextLine)) {
            final cleaned = nextLine.replaceAll(RegExp(r'\s+'), '');
            final digitsOnly = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
            if (digitsOnly.length >= 8) {
              print(
                  '✅ Smart extraction found reference (Next line): "$cleaned"');
              return cleaned;
            }
          }
        }
      }
    }

    // Strategy 2: Look for alphanumeric patterns like 803512902111S (more aggressive)
    final alphanumericPatterns = [
      // Numbers followed by letters (803512902111S, 12345ABC)
      RegExp(r'\b(\d{8,20}[A-Za-z]{1,5})\b'),
      // Pure numbers 10+ digits (lowered from 12)
      RegExp(r'\b(\d{10,20})\b'),
      // Numbers with spaces (5034 322 274670)
      RegExp(r'\b(\d{4}\s+\d{3}\s+\d{5,8})\b'),
      // Numbers with dashes (5034-322-274670)
      RegExp(r'\b(\d{4}-\d{3}-\d{5,8})\b'),
      // Mixed alphanumeric (A1B2C3D4E5F6)
      RegExp(r'\b([A-Z0-9]{10,20})\b'),
    ];

    for (var pattern in alphanumericPatterns) {
      final matches = pattern.allMatches(text);
      for (var match in matches) {
        final refStr = match.group(1)!;
        final digitsOnly = refStr.replaceAll(RegExp(r'[^0-9]'), '');

        // Valid reference: 8-20 digits (lowered from 10), not a phone number
        if (digitsOnly.length >= 8 && digitsOnly.length <= 20) {
          // Skip if it looks like a phone number
          if (digitsOnly.startsWith('63') ||
              digitsOnly.startsWith('09') ||
              digitsOnly.startsWith('9')) {
            if (digitsOnly.length == 10 ||
                digitsOnly.length == 11 ||
                digitsOnly.length == 12) {
              continue; // Skip phone numbers
            }
          }
          print('✅ Smart extraction found reference: "${refStr.trim()}"');
          return refStr.trim();
        }
      }
    }

    // Strategy 3: Generic fallback - any long number sequence (more lenient)
    final refPattern = RegExp(r'\b(\d[\d\s\-]{7,25})\b');
    final matches = refPattern.allMatches(text);

    for (var match in matches) {
      final refStr = match.group(1)!;
      final digitsOnly = refStr.replaceAll(RegExp(r'\D'), '');

      // Valid reference: 8-20 digits (lowered from 10), not a phone number
      if (digitsOnly.length >= 8 && digitsOnly.length <= 20) {
        // Skip if it looks like a phone number
        if (digitsOnly.startsWith('63') ||
            digitsOnly.startsWith('09') ||
            digitsOnly.startsWith('9')) {
          if (digitsOnly.length == 10 ||
              digitsOnly.length == 11 ||
              digitsOnly.length == 12) {
            continue; // Skip phone numbers
          }
        }
        print('✅ Smart extraction found reference: "${refStr.trim()}"');
        return refStr.trim();
      }
    }

    return '';
  }

  // Extract value from normalized sectionup
  String _extractFromNormalized(String text, String label) {
    // Look for "Label: Value" pattern in normalized section
    final pattern = RegExp('$label:\\s*(.+)', caseSensitive: false);
    final match = pattern.firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!.trim();
    }
    return '';
  }

  // Extract recipient name (handles GCash patterns like CL*****M M., MA****N M., CE••••A B., AL•OC., MA•S B.)
  String _extractRecipientName(String text) {
    final lines = text.split('\n');

    // Pattern variations for GCash masked names:
    // Format: First(2+mask+1) [Middle(2+mask+1)] Last(Initial)
    // Examples:
    // - "CL*****M M." - First + Last initial
    // - "MA•S B." - Short masked with bullet dot
    // - "CL*****M O***A M." - First + Middle + Last initial
    // - "JO****N D****E C." - First + Middle + Last initial
    // - "CLeMO." - Short masked format without spaces
    // - "Juan Cho M." - Full first name + middle/last
    final patterns = [
      // PRIORITY Pattern 1: Short format with bullet/asterisk/dot (MA•S B., MA......S B., AL*O C., JO.N D.)
      RegExp(r'[A-Z]{2}[•*\.]+[A-Z]{1,3}(?:\s+[A-Z]\.)?', caseSensitive: true),

      // Pattern 2: Full name with middle initial (Juan Cho M., Maria Cruz A.)
      RegExp(r'[A-Z][a-z]{2,}\s+[A-Z][a-z]{2,}\s+[A-Z]\.', caseSensitive: true),

      // Pattern 3: Short format without spaces (CLeMO., ALemO., etc.) - case insensitive
      RegExp(r'[A-Za-z]{2}[A-Za-z•*\.eom_\-]{1,5}[A-Za-z]{1,2}\.?',
          caseSensitive: false),

      // Pattern 4: Long name with middle name - asterisks (CL***M O***A M.)
      RegExp(r'[A-Z]{2}[•*\.]{1,10}[A-Z]\s+[A-Z]{2}[•*\.]{1,10}[A-Z]\s+[A-Z]\.',
          caseSensitive: true),

      // Pattern 5: Standard with asterisks (CL*****M M.)
      RegExp(r'[A-Z]{2}\*{1,10}[A-Z]\s+[A-Z]\.', caseSensitive: true),

      // Pattern 6: Long name with middle name - bullet dots (CE••••A B••••O M.)
      RegExp(r'[A-Z]{2}[•]{1,10}[A-Z]\s+[A-Z]{2}[•]{1,10}[A-Z]\s+[A-Z]\.',
          caseSensitive: true),

      // Pattern 7: Standard with bullet dots (CE••••A B.)
      RegExp(r'[A-Z]{2}[•]{1,10}[A-Z]\s+[A-Z]\.', caseSensitive: true),

      // Pattern 8: Long name with middle name - regular dots (MA....N I....O M.)
      RegExp(r'[A-Z]{2}[\.]{1,10}[A-Z]\s+[A-Z]{2}[\.]{1,10}[A-Z]\s+[A-Z]\.',
          caseSensitive: true),

      // Pattern 9: Standard with regular dots (MA....N M.)
      RegExp(r'[A-Z]{2}[\.]{1,10}[A-Z]\s+[A-Z]\.', caseSensitive: true),

      // Pattern 10: Mixed symbols with middle name (CL•*•*M O*••A M.)
      RegExp(r'[A-Z]{2}[•*\.]{1,10}[A-Z]\s+[A-Z]{2}[•*\.]{1,10}[A-Z]\s+[A-Z]\.',
          caseSensitive: true),

      // Pattern 11: Short format with one or more symbols (AL•OC., AL...OC., AL*OC., AL.OC.)
      RegExp(r'[A-Z]{2}[•*\.]+[A-Z]{2,}\.', caseSensitive: true),

      // Pattern 12: Very short format (2-3 letters + one or more symbols + 2-3 letters)
      RegExp(r'[A-Z]{2,3}[•*\.]+[A-Z]{2,3}\.?', caseSensitive: true),

      // Pattern 13: Case-insensitive masked name with spaces (handles lowercase OCR errors)
      RegExp(r'[A-Za-z]{2}[•*\.]{1,10}[A-Za-z]\s+[A-Za-z]\.?',
          caseSensitive: false),

      // Pattern 14: Name with underscores or dashes as masks
      RegExp(r'[A-Z]{2}[_\-]{1,10}[A-Z]\s+[A-Z]\.', caseSensitive: true),
    ];

    // Strategy 1: Try each pattern on full text
    for (var pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (var match in matches) {
        final name = match.group(0)!.trim();
        // Validate it's not a false positive and has reasonable length
        if (name.length >= 4 &&
            name.length <= 50 &&
            !RegExp(r'(GCash|Transfer|Amount|Receipt|Sent|Total|Fee|Ref|Via)',
                    caseSensitive: false)
                .hasMatch(name)) {
          print('✅ Found recipient name (Pattern match): "$name"');
          final normalized =
              _convertMaskingToBullets(name.endsWith('.') ? name : '$name.');
          return normalized;
        }
      }
    }

    // Strategy 2: Search line by line near phone numbers
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Look for lines with phone numbers or "Send Money" context
      if (line.contains('+63') ||
          line.contains('639') ||
          line.toLowerCase().contains('send money') ||
          line.toLowerCase().contains('money sent')) {
        // Check previous lines (usually 1-3 lines before)
        for (int j = i - 1; j >= 0 && j >= i - 5; j--) {
          final prevLine = lines[j].trim();
          if (prevLine.isEmpty) continue;

          // Check if line matches name pattern
          for (var pattern in patterns) {
            if (pattern.hasMatch(prevLine)) {
              final name = pattern.firstMatch(prevLine)!.group(0)!.trim();
              if (name.length >= 4 &&
                  !RegExp(r'(GCash|Amount|Via)', caseSensitive: false)
                      .hasMatch(name)) {
                print('✅ Found recipient name (Before phone): "$name"');
                final normalized = _convertMaskingToBullets(
                    name.endsWith('.') ? name : '$name.');
                return normalized;
              }
            }
          }
        }

        // Check next lines (sometimes appears after)
        for (int j = i + 1; j < lines.length && j < i + 5; j++) {
          final nextLine = lines[j].trim();
          if (nextLine.isEmpty) continue;

          for (var pattern in patterns) {
            if (pattern.hasMatch(nextLine)) {
              final name = pattern.firstMatch(nextLine)!.group(0)!.trim();
              if (name.length >= 4 &&
                  !RegExp(r'(GCash|Amount|Via)', caseSensitive: false)
                      .hasMatch(name)) {
                print('✅ Found recipient name (After phone): "$name"');
                final normalized = _convertMaskingToBullets(
                    name.endsWith('.') ? name : '$name.');
                return normalized;
              }
            }
          }
        }
      }
    }

    // Strategy 3: Look for "To:" or "Recipient:" labels
    final labelPatterns = [
      RegExp(r'(?:to|recipient|send\s+to)[:\s]+([A-Z•*\.]{5,})(?:[\s\n]|$)',
          caseSensitive: false),
      RegExp(
          r'(?:^|\n)([A-Za-z]{2}[a-z•*\.eom_\-]{1,5}[A-Za-z]{1,2}\.?)(?:\n|$)',
          multiLine: true),
    ];

    for (var pattern in labelPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final name = match.group(1)!.trim();
        if (name.length >= 4 &&
            !RegExp(r'(GCash|Amount|Via|Sent)', caseSensitive: false)
                .hasMatch(name)) {
          print('✅ Found recipient name (Label match): "$name"');
          final normalized =
              _convertMaskingToBullets(name.endsWith('.') ? name : '$name.');
          return normalized;
        }
      }
    }

    // Strategy 4: Try full name pattern (for non-masked names)
    final fullNamePattern = RegExp(
      r'[A-Z][a-z]+(?:\s+[A-Z][a-z]+)+',
      caseSensitive: true,
    );

    final fullNameMatches = fullNamePattern.allMatches(text);
    for (var match in fullNameMatches) {
      final name = match.group(0)!.trim();
      // Avoid matching common words and validate reasonable name length
      if (!RegExp(r'(GCash|Transfer|Amount|Receipt|Sent|Total|Fee|Money|Account|Service|Carbon|Digital|Powered|Via)',
                  caseSensitive: false)
              .hasMatch(name) &&
          name.length >= 5 &&
          name.length <= 50) {
        print('✅ Found recipient name (Full name): "$name"');
        final normalized =
            _convertMaskingToBullets(name.endsWith('.') ? name : '$name.');
        return normalized;
      }
    }

    // Strategy 5: Look for any capitalized text with mask characters near phone
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      // Check if line looks like a masked name (has letters and mask characters)
      if (RegExp(r'[A-Za-z]{2}[a-z•*\.eom_\-]{1,5}[A-Za-z]{1,2}\.?',
                  caseSensitive: false)
              .hasMatch(line) &&
          line.length >= 4 &&
          line.length <= 20) {
        // Verify it's not a common word
        if (!RegExp(r'(GCash|Amount|Via|Sent|Transfer|Fee|Total|Ref)',
                caseSensitive: false)
            .hasMatch(line)) {
          print('✅ Found recipient name (Line scan): "$line"');
          return line.toUpperCase();
        }
      }
    }

    // Strategy 6: Look for any capitalized text near amount (last resort)
    final amountIndex = text.indexOf(RegExp(r'[P₱]\s*[\d,]+\.\d{2}'));
    if (amountIndex > 0) {
      final beforeAmount = text.substring(0, amountIndex);
      final capsPattern =
          RegExp(r'([A-Z•*\.]{5,}(?:\s+[A-Z•*\.]+)*)\s*$', multiLine: true);
      final match = capsPattern.firstMatch(beforeAmount);
      if (match != null) {
        final name = match.group(1)!.trim();
        if (name.length >= 5) {
          print('✅ Found recipient name (Near amount): "$name"');
          return name;
        }
      }
    }

    print('❌ Could not extract recipient name');
    return '';
  }

  // Extract phone number - flexible pattern for Philippine numbers
  String _extractPhoneNumber(String text) {
    // Try multiple phone number patterns
    final patterns = [
      // Pattern 1: +63 with spaces (e.g., "+63 915 609 1737")
      RegExp(r'\+63\s*\d{3}\s*\d{3}\s*\d{4}'),

      // Pattern 2: 63 without + (e.g., "63 915 609 1737" or "639156091737")
      RegExp(r'\b63\s*\d{3}\s*\d{3}\s*\d{4}'),

      // Pattern 3: 09 format (e.g., "0915 609 1737" or "09156091737")
      RegExp(r'\b0\d{3}\s*\d{3}\s*\d{4}'),

      // Pattern 4: Just 10 digits starting with 9 (e.g., "915 609 1737")
      RegExp(r'\b9\d{2}\s*\d{3}\s*\d{4}'),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String phone = match.group(0)!;

        // Normalize phone number format
        phone = phone.replaceAll(RegExp(r'\s+'), '');

        // Convert to +63 format
        if (phone.startsWith('0')) {
          phone = '+63' + phone.substring(1);
        } else if (phone.startsWith('9')) {
          phone = '+63' + phone;
        } else if (phone.startsWith('63') && !phone.startsWith('+')) {
          phone = '+' + phone;
        }

        return phone;
      }
    }

    return '';
  }

  // Extract amount - flexible pattern matching for various receipt formats
  double _extractAmount(String text) {
    final lines = text.split('\n');

    // PRIORITY: Look for 'Total Amount Sent' label and get the next standalone amount
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      if (line.contains('total') &&
          line.contains('amount') &&
          line.contains('sent')) {
        // Check next 1-3 lines for standalone amount
        for (int j = i + 1; j < lines.length && j < i + 4; j++) {
          final nextLine = lines[j].trim();
          // Match standalone amount like "850.00" or "P850.00" or "₱850.00"
          final amountMatch =
              RegExp(r'^[P₱]?\s*([\d,]+\.\d{2})$').firstMatch(nextLine);
          if (amountMatch != null) {
            final amountStr = amountMatch.group(1)!.replaceAll(',', '');
            final parsed = double.tryParse(amountStr);
            if (parsed != null && parsed >= 1.0 && parsed <= 1000000.0) {
              print('✅ Found amount after "Total Amount Sent": ₱$parsed');
              return parsed;
            }
          }
        }
      }
    }

    // Try multiple patterns in order of specificity
    final patterns = [
      // Pattern 1: Transfer Amount (for bank transfers)
      RegExp(r'transfer\s+amount[:\s]*([P₱]?\s*[\d,]+\.?\d{0,2})',
          caseSensitive: false),

      // Pattern 2: Total Amount Sent with amount on same line
      RegExp(r'total\s+amount\s+sent[:\s]*([P₱]?\s*[\d,]+\.?\d{0,2})',
          caseSensitive: false),

      // Pattern 3: Amount Sent
      RegExp(r'amount\s+sent[:\s]*([P₱]?\s*[\d,]+\.?\d{0,2})',
          caseSensitive: false),

      // Pattern 4: Generic Amount with label
      RegExp(r'amount[:\s]+([P₱]?\s*[\d,]+\.?\d{0,2})', caseSensitive: false),

      // Pattern 5: Currency symbol followed by amount (anywhere in text)
      RegExp(r'[P₱]\s*([\d,]+\.\d{2})\b'),

      // Pattern 6: Large standalone number with 2 decimal places (likely amount)
      RegExp(r'\b([\d,]+\.\d{2})\b'),
    ];

    for (var pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (var match in matches) {
        String amountStr = match.group(1) ?? match.group(0) ?? '';
        // Clean up the amount string
        amountStr = amountStr.replaceAll(RegExp(r'[P₱,\s]'), '');
        final parsed = double.tryParse(amountStr);

        // Validate amount is reasonable (between 1 and 1,000,000)
        if (parsed != null && parsed >= 1.0 && parsed <= 1000000.0) {
          // Skip if it looks like a phone number (has 10+ digits without decimal)
          if (!amountStr.contains('.') && amountStr.length >= 10) continue;

          // Skip if it's likely a reference number (too many digits)
          if (amountStr.replaceAll('.', '').length > 10) continue;

          return parsed;
        }
      }
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

  // Extract reference number - flexible pattern matching for various formats
  // SUPPORTS: numeric (1234567890) and alphanumeric (803512902111S) references
  String _extractReferenceNumber(String text) {
    final lines = text.split('\n');

    // PRIORITY 0: STRICT MONEY TRANSFER FORMAT - Exactly 13 digits in format: **** *** ******
    // This is the most specific and reliable pattern for money transfer receipts
    final moneyTransferPattern = RegExp(r'\b(\d{4})\s+(\d{3})\s+(\d{6})\b');
    final mtMatch = moneyTransferPattern.firstMatch(text);
    if (mtMatch != null) {
      final refNumber =
          '${mtMatch.group(1)} ${mtMatch.group(2)} ${mtMatch.group(3)}';
      // Verify it has exactly 13 digits (no spaces)
      final digitsOnly = refNumber.replaceAll(' ', '');
      if (digitsOnly.length == 13) {
        print('✅ Found MONEY TRANSFER reference (13 digits): "$refNumber"');
        return refNumber;
      }
    }

    // PRIORITY 1: Look for ANY variation of reference number labels
    // Extended list of reference number keywords
    final refKeywords = [
      'reference number',
      'reference no',
      'ref number',
      'ref no',
      'ref num',
      'ref #',
      'ref:',
      'reference:',
      'transaction ref',
      'trxn ref',
      'transaction no',
      'trxn no',
      'receipt no',
      'receipt number',
      'confirmation no',
      'confirmation number',
      'tracking no',
      'tracking number',
      'control no',
      'control number',
    ];

    // Build patterns for all variations
    final refNoPatterns = <RegExp>[];
    for (var keyword in refKeywords) {
      // Pattern with colon or space separator
      refNoPatterns.add(RegExp(
          r'' + RegExp.escape(keyword) + r'\.?[:\s]+([A-Za-z0-9\s\-]{6,30})',
          caseSensitive: false));
    }

    // Try each pattern
    for (var pattern in refNoPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        String refStr = match.group(1)!.trim();
        final cleaned = _cleanAndValidateRefNumber(refStr);
        if (cleaned.isNotEmpty) {
          print('✅ Found reference number (keyword match): "$cleaned"');
          return cleaned;
        }
      }
    }

    // PRIORITY 2: Line-by-line search - find any reference keyword and get value
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim().toLowerCase();

      // Skip InstaPay Invoice lines
      if (line.contains('instapay') && line.contains('invoice')) continue;

      // Check if line contains any reference keyword
      bool hasRefKeyword = false;
      for (var keyword in refKeywords) {
        if (line.contains(keyword.toLowerCase())) {
          hasRefKeyword = true;
          break;
        }
      }

      if (hasRefKeyword) {
        // Try to extract value from same line first
        final sameLineMatch = RegExp(
                r'(?:reference|ref|trxn|transaction|receipt|confirmation|tracking|control)\.?\s*(?:number|no|num|#)?\.?[:\s]+([A-Za-z0-9\s\-]{6,30})',
                caseSensitive: false)
            .firstMatch(lines[i]);
        if (sameLineMatch != null) {
          final cleaned =
              _cleanAndValidateRefNumber(sameLineMatch.group(1)!.trim());
          if (cleaned.isNotEmpty) {
            print('✅ Found reference number (Same line): "$cleaned"');
            return cleaned;
          }
        }

        // Check next 1-3 lines for the number
        for (int j = i + 1; j < lines.length && j < i + 4; j++) {
          final nextLine = lines[j].trim();
          if (nextLine.isEmpty) continue;

          // Match alphanumeric reference number format (6+ chars, lowered threshold)
          if (RegExp(r'^[A-Za-z0-9\s\-]{6,30}$').hasMatch(nextLine)) {
            final cleaned = _cleanAndValidateRefNumber(nextLine);
            if (cleaned.isNotEmpty) {
              print('✅ Found reference number (Next line): "$cleaned"');
              return cleaned;
            }
          }
        }
      }
    }

    // PRIORITY 3: Try other labeled patterns (expanded)
    final labeledPatterns = [
      // Reference variations
      RegExp(r'reference[:\s]+([A-Za-z0-9\s\-]{8,25})', caseSensitive: false),
      RegExp(r'ref\s+code[:\s]+([A-Za-z0-9\s\-]{8,25})', caseSensitive: false),
      RegExp(r'ref\s+num[:\s]+([A-Za-z0-9\s\-]{8,25})', caseSensitive: false),

      // Transaction ID/Number (alphanumeric)
      RegExp(
          r'trans(?:action)?\s*(?:id|no\.?|number)?[:\s]+([A-Za-z0-9\s\-]{8,25})',
          caseSensitive: false),
      RegExp(r'trx\s*(?:id|no\.?)?[:\s]+([A-Za-z0-9\s\-]{8,25})',
          caseSensitive: false),

      // Receipt Number (alphanumeric)
      RegExp(r'receipt\s*(?:no\.?|number|#)?[:\s]+([A-Za-z0-9\s\-]{8,25})',
          caseSensitive: false),

      // Confirmation Code/Number (alphanumeric)
      RegExp(
          r'confirmation\s*(?:code|no\.?|number)?[:\s]+([A-Za-z0-9\s\-]{8,25})',
          caseSensitive: false),
      RegExp(r'confirm\s*(?:code|no\.?)?[:\s]+([A-Za-z0-9\s\-]{8,25})',
          caseSensitive: false),

      // Control Number
      RegExp(r'control\s*(?:no\.?|number)?[:\s]+([A-Za-z0-9\s\-]{8,25})',
          caseSensitive: false),

      // Tracking Number
      RegExp(r'tracking\s*(?:no\.?|number)?[:\s]+([A-Za-z0-9\s\-]{8,25})',
          caseSensitive: false),

      // Serial Number
      RegExp(r'serial\s*(?:no\.?|number)?[:\s]+([A-Za-z0-9\s\-]{8,25})',
          caseSensitive: false),
    ];

    for (var pattern in labeledPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        String refStr = match.group(1)!.trim();
        final cleaned = _cleanAndValidateRefNumber(refStr);
        if (cleaned.isNotEmpty) {
          print('✅ Found reference number (Labeled): "$cleaned"');
          return cleaned;
        }
      }
    }

    // PRIORITY 4: Generic long alphanumeric patterns (more aggressive)
    final genericPatterns = [
      // 13-20 digits with spaces (GCash format: "5034 322 274670")
      RegExp(r'\b(\d{4}\s+\d{3}\s+\d{6,8})\b'),

      // 10-13 digits with spaces (common format: "1234 567 8901")
      RegExp(r'\b(\d{4}\s+\d{3}\s+\d{3,5})\b'),

      // Alphanumeric with numbers first then letters (803512902111S format)
      RegExp(r'\b(\d{8,20}[A-Za-z]{1,5})\b'),

      // Letters then numbers (ABC123456789)
      RegExp(r'\b([A-Z]{2,5}\d{8,15})\b'),

      // Mixed alphanumeric (A1B2C3D4E5F6G7H8)
      RegExp(r'\b([A-Z0-9]{12,20})\b'),

      // 8-20 digits with optional spaces/dashes (lowered from 10)
      RegExp(r'\b(\d[\d\s\-]{7,19})\b'),

      // Continuous 8-16 digit string (lowered from 12)
      RegExp(r'\b(\d{8,16})\b'),

      // Hyphenated format (1234-5678-9012)
      RegExp(r'\b(\d{4}-\d{4}-\d{4,8})\b'),

      // UUID-like format (shortened)
      RegExp(r'\b([A-Fa-f0-9]{8}-[A-Fa-f0-9]{4,12})\b'),
    ];

    for (var pattern in genericPatterns) {
      final matches = pattern.allMatches(text);
      for (var match in matches) {
        String refStr = match.group(1) ?? '';
        final cleaned = _cleanAndValidateRefNumber(refStr);
        if (cleaned.isNotEmpty) {
          print('✅ Found reference number (Generic pattern): "$cleaned"');
          return cleaned;
        }
      }
    }

    // LAST RESORT: Find the longest numeric sequence (8-20 digits) that's not a phone number
    print('⚠️ Using last resort extraction - finding longest numeric sequence');
    final allNumbers = RegExp(r'\b(\d{8,20})\b').allMatches(text);
    String longestRef = '';
    for (var match in allNumbers) {
      final num = match.group(1) ?? '';
      // Skip phone numbers
      if (num.startsWith('63') || num.startsWith('09') || num.startsWith('+63'))
        continue;
      // Skip if looks like timestamp
      if (num.contains('202') && num.length >= 12) continue;

      if (num.length > longestRef.length) {
        longestRef = num;
      }
    }

    if (longestRef.length >= 8) {
      print('✅ Last resort found reference: "$longestRef"');
      return longestRef;
    }

    print('❌ Could not extract reference number');
    return '';
  }

  // Helper: Clean and validate reference number
  // SUPPORTS: alphanumeric references like "803512902111S" and money transfer format (13 digits)
  String _cleanAndValidateRefNumber(String refStr) {
    if (refStr.isEmpty) return '';

    // Remove icon characters that OCR might misread (copy button icons, etc.)
    // Common icon characters: □, ☐, ☑, ✓, ✔, ⬜, 📋, 📄, and various Unicode symbols
    String cleaned = refStr
        .replaceAll(RegExp(r'[\u2610-\u2612]'), '') // Checkbox icons
        .replaceAll(RegExp(r'[\u2713-\u2714]'), '') // Checkmark icons
        .replaceAll(RegExp(r'[\u25A0-\u25FF]'), '') // Geometric shapes
        .replaceAll(RegExp(r'[\u2B1B-\u2B1C]'), '') // Black/white squares
        .replaceAll(
            RegExp(r'[\u1F4CB-\u1F4CE]'), '') // Clipboard/document emojis
        .replaceAll(RegExp(r'[\u2B55-\u2B59]'), '') // Circle icons
        .replaceAll(
            RegExp(r'[⌐¬º°•◯○●◉◌]'), '') // Misc special chars and circles
        .trim();

    // Remove standalone "0" at the end if it looks like a misread copy icon
    // Only if there's other content before it
    if (cleaned.endsWith(' 0') ||
        cleaned.endsWith('-0') ||
        cleaned.endsWith('0 ')) {
      final withoutTrailingZero =
          cleaned.substring(0, cleaned.length - 2).trim();
      if (withoutTrailingZero.isNotEmpty &&
          RegExp(r'\d').hasMatch(withoutTrailingZero)) {
        cleaned = withoutTrailingZero;
        print('🧹 Removed trailing "0" (likely copy icon): "$cleaned"');
      }
    } else if (cleaned.endsWith('0') && cleaned.length > 1) {
      // Check if the 0 is isolated (not part of a sequence like "100" or "20")
      final beforeZero = cleaned.substring(0, cleaned.length - 1);
      if (beforeZero.endsWith(' ') || beforeZero.endsWith('-')) {
        cleaned = beforeZero.trim();
        print('🧹 Removed trailing "0" (likely copy icon): "$cleaned"');
      }
    }

    // Clean up reference number - remove spaces and dashes for validation
    final cleanedStr = cleaned.replaceAll(RegExp(r'[\s\-]'), '');

    // SPECIAL CASE: Money transfer format with exactly 13 digits
    final digitCount = cleanedStr.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (digitCount == 13 && cleanedStr.length == 13) {
      // Verify it matches the money transfer pattern **** *** ******
      if (RegExp(r'^\d{4}\s*\d{3}\s*\d{6}$').hasMatch(refStr.trim())) {
        return refStr.trim(); // Return with original spacing
      }
    }

    // LOWERED: Validate it's a reasonable reference number (6-30 alphanumeric chars)
    // Changed from 8-25 to 6-30 to accept shorter reference numbers
    if (cleanedStr.length < 6 || cleanedStr.length > 30) return '';

    // RELAXED: Check if it's mostly numeric (at least 60% digits instead of 70%)
    // Some receipts have more alphanumeric reference codes
    if (digitCount < cleanedStr.length * 0.6) return ''; // Too many letters

    // Make sure it's not a phone number (check start pattern)
    if (cleanedStr.startsWith('+63') ||
        cleanedStr.startsWith('63') ||
        cleanedStr.startsWith('09') ||
        (cleanedStr.startsWith('9') && cleanedStr.length <= 12)) return '';

    // Exclude if it looks like an amount (has decimal)
    if (cleaned.contains('.') && RegExp(r'\.\d{2}$').hasMatch(cleaned))
      return '';

    // Exclude if it's timestamp-like (too many zeros or sequential)
    if (cleanedStr.contains('000000') || cleanedStr.contains('123456'))
      return '';

    // LOWERED THRESHOLD: Accept 6+ digits (was 8+) to match enhanced patterns
    // This allows shorter but valid reference numbers to pass through
    if (digitCount < 6) return '';

    return cleaned.trim();
  }

  // Extract date - flexible pattern matching for various date formats
  DateTime _extractDate(String text) {
    // Try multiple date patterns
    final patterns = [
      // Pattern 1: Month DD, YYYY HH:MM AM/PM (e.g., "Nov 04, 2025 10:31 AM")
      RegExp(
          r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2},?\s*\d{4}\s+\d{1,2}:\d{2}\s+(AM|PM)',
          caseSensitive: false),

      // Pattern 2: DD/MM/YYYY or MM/DD/YYYY
      RegExp(r'\b(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})\b'),

      // Pattern 3: YYYY-MM-DD (ISO format)
      RegExp(r'\b(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})\b'),

      // Pattern 4: Month DD, YYYY (without time)
      RegExp(
          r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2},?\s*\d{4}',
          caseSensitive: false),

      // Pattern 5: Just date with time anywhere
      RegExp(r'\d{1,2}:\d{2}\s+(AM|PM)', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          String dateStr = match.group(0)!;
          // Normalize: ensure space after comma
          dateStr = dateStr.replaceAll(RegExp(r'(\d+),(\d{4})'), r'$1, $2');
          return _parseDate(dateStr);
        } catch (e) {
          print('Error parsing date with pattern: $e');
          continue;
        }
      }
    }

    // If no date found, return current date/time
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

    // Check if it's a load transaction first
    if (_isLoadTransaction(text, lowerText)) {
      return 'Load';
    }

    if (lowerText.contains('gcash')) return 'GCash';
    if (lowerText.contains('palawan')) return 'Palawan';
    if (lowerText.contains('paymaya')) return 'PayMaya';
    return 'GCash'; // Default
  }

  /// Detect if this is a mobile load transaction
  ///
  /// MOBILE LOAD INDICATORS:
  /// 1. Load/promo keywords (load, autoload, easysurf, giga, etc.)
  /// 2. Mobile network providers (smart, globe, tnt, etc.)
  /// 3. 9-digit reference numbers (typical for load receipts)
  /// 4. "Paid via GCash" instead of "Sent via GCash"
  /// 5. "Schedule for Autoload" text
  /// 6. "Convenience Fee" instead of just "Fee"
  ///
  /// STRUCTURE DETECTION:
  /// Load receipts have a distinct structure with:
  /// - Promo name at TOP (not a person's name)
  /// - Mobile number BELOW the promo name
  /// - "Paid via GCash" service indicator
  /// - Amount + Convenience Fee breakdown
  bool _isLoadTransaction(String text, String lowerText) {
    // Check for load-related keywords
    final loadKeywords = [
      'load',
      'autoload',
      'easysurf',
      'giga',
      'unlisurf',
      'allnet',
      'funaliw',
      'gigasurf',
      'gotscombokea',
      'giga stories',
      'schedule for autoload',
      'convenience fee',
      'paid via',
    ];

    bool hasLoadKeyword = false;
    for (final keyword in loadKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        hasLoadKeyword = true;
        print('🔍 Load keyword detected: "$keyword"');
        break;
      }
    }

    // Check for mobile network provider names
    final providers = [
      'smart',
      'globe',
      'tnt',
      'tm',
      'dito',
      'sun',
    ];

    bool hasProvider = false;
    for (final provider in providers) {
      if (lowerText.contains(provider)) {
        hasProvider = true;
        print('🔍 Provider detected: "$provider"');
        break;
      }
    }

    // Check if reference number is exactly 9 digits (common for load receipts)
    final nineDigitRef = RegExp(r'\b\d{9}\b');
    final hasNineDigitRef = nineDigitRef.hasMatch(text);
    if (hasNineDigitRef) {
      print('🔍 9-digit reference number detected (typical for load)');
    }

    // Determine if it's a load transaction:
    // 1. Has 9-digit ref number AND (has load keyword OR provider)
    // 2. OR has "autoload" or "load" keyword with provider
    // 3. OR has "paid via" (instead of "sent via") with load keywords
    final isLoad = (hasNineDigitRef && (hasLoadKeyword || hasProvider)) ||
        (hasLoadKeyword && hasProvider);

    if (isLoad) {
      print('✅ Detected as MOBILE LOAD transaction');
    }

    return isLoad;
  }

  // Extract bank name - flexible pattern matching for Philippine banks
  String _extractBankName(String text) {
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

    // First try: Find exact bank name matches (case-insensitive)
    final textLower = text.toLowerCase();
    for (var bankName in bankNames) {
      if (textLower.contains(bankName.toLowerCase())) {
        return bankName;
      }
    }

    // Second try: Use flexible patterns
    final patterns = [
      // Pattern 1: "Bank: <Name>"
      RegExp(r'bank[:\s]+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)?)',
          caseSensitive: false, multiLine: true),

      // Pattern 2: "To <Bank Name> Bank"
      RegExp(r'to\s+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)?)\s+bank',
          caseSensitive: false, multiLine: true),

      // Pattern 3: Bank name before "Account"
      RegExp(r'([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)?)\s+account',
          caseSensitive: false, multiLine: true),

      // Pattern 4: Any capitalized 2-3 word phrase near "bank" keyword
      RegExp(r'bank[^\n]{0,20}\n+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)?)',
          caseSensitive: false, multiLine: true),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        String bankName = match.group(1)!.trim();

        // Validate bank name
        if (bankName.length > 2 &&
            bankName.length < 30 &&
            !RegExp(r'(successful|transfer|receipt|sent|amount|fee|total|ref|invoice|date|complete|name)',
                    caseSensitive: false)
                .hasMatch(bankName)) {
          return bankName;
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

  // Extract account name - flexible pattern matching for bank transfers
  String _extractAccountName(String text) {
    // Try multiple patterns for account names
    final patterns = [
      // Pattern 1: After "Account Name:" label
      RegExp(r'account\s+name[:\s]+([A-Z][A-Z\s\.]+?)(?:\n|$)',
          caseSensitive: false, multiLine: true),

      // Pattern 2: After "Name:" in bank context
      RegExp(r'name[:\s]+([A-Z][A-Z\s\.]{2,48})(?:\n|account)',
          caseSensitive: false, multiLine: true),

      // Pattern 3: ALL CAPS name near bank or account keywords
      RegExp(
          r'(?:bank|account)[^\n]*\n+([A-Z]{3,}(?:\s+[A-Z]+)*(?:\s+[A-Z]\.)?)',
          caseSensitive: false,
          multiLine: true),

      // Pattern 4: Name with dots (e.g., "CLYTHEM O.")
      RegExp(r'\n([A-Z]{2,}(?:\s+[A-Z]+)*\s+[A-Z]\.)\n', multiLine: true),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        String name = match.group(1)!.trim();

        // Validate account name:
        // - Length between 3 and 50 characters
        // - ALL CAPS format
        // - Not a common label, email, or masked data
        if (name.length >= 3 &&
            name.length < 50 &&
            RegExp(r'^[A-Z][A-Z\s\.]+$').hasMatch(name) &&
            !name.contains('@') &&
            !name.contains('***') &&
            !name.contains('•••') &&
            !RegExp(r'(RECEIPT|TRANSFER|AMOUNT|FEE|TOTAL|REFERENCE|INVOICE|DATE|SENT|GCASH|POWERED|INSTAPAY)',
                    caseSensitive: false)
                .hasMatch(name)) {
          return name;
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

  // Extract bank fee - flexible pattern matching
  double _extractBankFee(String text) {
    // Try multiple patterns for fees
    final patterns = [
      // Pattern 1: +Fee with amount
      RegExp(r'\+\s*fee[:\s]+([P₱]?\s*\d{1,3}\.\d{2})', caseSensitive: false),

      // Pattern 2: Fee or Service Fee
      RegExp(r'(?:service\s+)?fee[:\s]+([P₱]?\s*\d{1,3}\.\d{2})',
          caseSensitive: false),

      // Pattern 3: Transaction fee
      RegExp(r'transaction\s+fee[:\s]+([P₱]?\s*\d{1,3}\.\d{2})',
          caseSensitive: false),

      // Pattern 4: Small amount between 0.01 and 99.99 (likely a fee)
      RegExp(r'\b([P₱]?\s*(?:[1-9]\d?|0)\.\d{2})\b'),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String feeStr = match.group(1) ?? '';
        feeStr = feeStr.replaceAll(RegExp(r'[P₱\s]'), '');
        final parsed = double.tryParse(feeStr);

        // Validate fee is reasonable (between 0 and 100)
        if (parsed != null && parsed >= 0.0 && parsed < 100.0) {
          return parsed;
        }
      }
    }

    return 0.0;
  }

  // Extract total - flexible pattern matching
  double _extractTotal(String text) {
    // Try multiple patterns for total amount
    final patterns = [
      // Pattern 1: Total with currency symbol
      RegExp(r'total[:\s]+[P₱]\s*([\.\d,]+)', caseSensitive: false),

      // Pattern 2: Total Amount
      RegExp(r'total\s+amount[:\s]+([P₱]?\s*[\d,]+\.\d{2})',
          caseSensitive: false),

      // Pattern 3: Just "Total" followed by amount
      RegExp(r'total[:\s]+([P₱]?\s*[\d,]+\.\d{2})', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String totalStr = match.group(1) ?? '';
        totalStr = totalStr.replaceAll(RegExp(r'[P₱,\s]'), '');
        final parsed = double.tryParse(totalStr);

        // Validate total is reasonable
        if (parsed != null && parsed > 0 && parsed <= 1000000.0) {
          return parsed;
        }
      }
    }

    return 0.0;
  }

  // Old rigid extraction kept as fallback
  double _extractTotalOld(String text) {
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
    _textRecognizer?.close();
  }
}
