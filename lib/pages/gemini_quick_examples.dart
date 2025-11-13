import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/gemini_controller.dart';

/// Quick example showing the 3 ways to analyze images with Gemini AI
class GeminiQuickExample extends StatelessWidget {
  const GeminiQuickExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gemini AI Examples')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Example 1: Receipt Analysis
          _ExampleCard(
            title: '1. Automatic Receipt Analysis',
            description: 'Get structured data from receipts automatically',
            onPressed: () => _example1ReceiptAnalysis(),
          ),

          // Example 2: Custom Fields
          _ExampleCard(
            title: '2. Extract Specific Fields',
            description: 'Tell AI exactly what fields to extract',
            onPressed: () => _example2CustomFields(),
          ),

          // Example 3: Custom Analysis
          _ExampleCard(
            title: '3. Custom Analysis Requirements',
            description: 'Describe what you want to analyze in plain language',
            onPressed: () => _example3CustomAnalysis(),
          ),
        ],
      ),
    );
  }

  /// Example 1: Automatic Receipt Analysis
  /// Returns structured JSON data with common receipt fields
  Future<void> _example1ReceiptAnalysis() async {
    // Pick image
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // Get controller
    final geminiController = Get.put(GeminiController());

    // Read image bytes
    final bytes = await File(image.path).readAsBytes();

    // Analyze receipt - returns Map<String, dynamic>
    final result = await geminiController.analyzeReceiptImage(bytes);

    if (result != null) {
      print('=== RECEIPT ANALYSIS RESULT ===');
      print('Merchant: ${result['merchant_name']}');
      print('Total: ${result['total_amount']}');
      print('Currency: ${result['currency']}');
      print('Date: ${result['date']}');
      print('Time: ${result['time']}');
      print('Receipt #: ${result['receipt_number']}');
      print('Tax: ${result['tax']}');
      print('Subtotal: ${result['subtotal']}');
      print('Payment: ${result['payment_method']}');
      print('Address: ${result['address']}');
      print('Phone: ${result['phone']}');

      // Access items array
      if (result['items'] is List) {
        print('\nITEMS:');
        for (var item in result['items']) {
          print(
              '  - ${item['name']}: ${item['price']} (Qty: ${item['quantity']})');
        }
      }

      // Use the data
      _saveToDatabase(result);
      _showSuccessMessage('Receipt analyzed successfully!');
    } else {
      _showErrorMessage('Failed to analyze receipt');
    }
  }

  /// Example 2: Extract Specific Fields
  /// Perfect when you know exactly what you need
  Future<void> _example2CustomFields() async {
    // Pick image
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // Get controller
    final geminiController = Get.put(GeminiController());

    // Define exactly what fields you want
    final fieldsToExtract = [
      'Total amount',
      'Date of transaction',
      'Merchant or store name',
      'Payment method used',
      'Receipt or transaction number',
    ];

    // Read image bytes
    final bytes = await File(image.path).readAsBytes();

    // Extract custom fields
    final result = await geminiController.extractCustomInfo(
      bytes,
      fieldsToExtract,
    );

    if (result != null) {
      print('=== CUSTOM FIELD EXTRACTION ===');
      print(result);
      _showSuccessMessage('Fields extracted successfully!');
    } else {
      _showErrorMessage('Failed to extract fields');
    }
  }

  /// Example 3: Custom Analysis Requirements
  /// Describe what you want in natural language
  Future<void> _example3CustomAnalysis() async {
    // Pick image
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // Get controller
    final geminiController = Get.put(GeminiController());

    // Describe your analysis needs
    final requirements = '''
    From this receipt/document, please:
    1. List all product names and their individual prices
    2. Calculate the total discount amount (if any)
    3. Identify the store category (grocery, restaurant, retail, etc.)
    4. Check if there are any promotional offers mentioned
    5. Extract the cashier or server name if visible
    6. Note any special instructions or messages
    ''';

    // Read image bytes
    final bytes = await File(image.path).readAsBytes();

    // Analyze with custom requirements
    final result = await geminiController.analyzeCustomDocument(
      bytes,
      requirements,
    );

    if (result != null) {
      print('=== CUSTOM ANALYSIS RESULT ===');
      print(result);
      _showSuccessMessage('Analysis completed!');
    } else {
      _showErrorMessage('Failed to analyze document');
    }
  }

  // Helper methods
  void _saveToDatabase(Map<String, dynamic> data) {
    // TODO: Implement your database save logic
    print('Saving to database: $data');
  }

  void _showSuccessMessage(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _showErrorMessage(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onPressed;

  const _ExampleCard({
    required this.title,
    required this.description,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Try it →',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PRACTICAL USE CASE EXAMPLES
// =============================================================================

/// Use Case 1: Expense Tracker Integration
class ExpenseTrackerExample {
  final geminiController = Get.put(GeminiController());

  Future<void> scanAndSaveExpense() async {
    // 1. Take photo of receipt
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image == null) return;

    // 2. Analyze receipt
    final bytes = await File(image.path).readAsBytes();
    final data = await geminiController.analyzeReceiptImage(bytes);

    if (data == null) return;

    // 3. Parse and save
    final amount = double.tryParse(data['total_amount'] ?? '0') ?? 0.0;
    final merchant = data['merchant_name'] ?? 'Unknown';
    final dateStr = data['date'] ?? '';
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();

    // 4. Create expense entry
    final expense = {
      'amount': amount,
      'merchant': merchant,
      'date': date,
      'category': _categorizeExpense(merchant),
      'receipt_path': image.path,
      'raw_data': data,
    };

    // 5. Save to your database
    print('Saving expense: $expense');
    // await FirestoreService().addExpense(expense);
  }

  String _categorizeExpense(String merchant) {
    // Simple categorization logic
    final lowerMerchant = merchant.toLowerCase();
    if (lowerMerchant.contains('restaurant') ||
        lowerMerchant.contains('cafe') ||
        lowerMerchant.contains('food')) {
      return 'Food & Dining';
    } else if (lowerMerchant.contains('market') ||
        lowerMerchant.contains('grocery')) {
      return 'Groceries';
    } else if (lowerMerchant.contains('gas') ||
        lowerMerchant.contains('fuel')) {
      return 'Transportation';
    }
    return 'Other';
  }
}

/// Use Case 2: Invoice Processing
class InvoiceProcessorExample {
  final geminiController = Get.put(GeminiController());

  Future<void> processInvoice(File invoiceImage) async {
    final bytes = await invoiceImage.readAsBytes();

    // Define what to extract from invoice
    final fields = [
      'Invoice number',
      'Client company name',
      'Client address',
      'Invoice date',
      'Due date',
      'All line items with descriptions and amounts',
      'Subtotal amount',
      'Tax amount',
      'Total amount due',
      'Payment terms',
      'Your company name and details',
    ];

    final result = await geminiController.extractCustomInfo(bytes, fields);

    if (result != null) {
      print('Invoice processed:');
      print(result);

      // Parse and save invoice
      // await saveInvoiceToDatabase(result);
    }
  }
}

/// Use Case 3: Business Card Scanner
class BusinessCardScannerExample {
  final geminiController = Get.put(GeminiController());

  Future<Map<String, dynamic>?> scanBusinessCard(File cardImage) async {
    final bytes = await cardImage.readAsBytes();

    final fields = [
      'Full name',
      'Job title or position',
      'Company name',
      'Email address',
      'Phone number',
      'Mobile number',
      'Office address',
      'Website URL',
      'Social media handles',
    ];

    final result = await geminiController.extractCustomInfo(bytes, fields);

    if (result != null) {
      // Create contact
      return {
        'name': _extractField(result, 'Full name'),
        'title': _extractField(result, 'Job title'),
        'company': _extractField(result, 'Company name'),
        'email': _extractField(result, 'Email'),
        'phone': _extractField(result, 'Phone'),
        'address': _extractField(result, 'address'),
        'website': _extractField(result, 'Website'),
      };
    }

    return null;
  }

  String _extractField(String text, String fieldName) {
    // Parse the field from the result text
    // This is a simple example - adjust based on actual response format
    final lines = text.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().contains(fieldName.toLowerCase())) {
        return line.split(':').last.trim();
      }
    }
    return 'Not found';
  }
}
