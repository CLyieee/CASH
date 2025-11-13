# Custom Image Analysis Guide

## Overview
This guide shows how to use the enhanced Gemini AI to extract **exactly** what you need from images, not just example/template data.

## Key Improvements

### ✅ What's New
1. **Structured JSON Output** - Receipt data returned in organized format
2. **Custom Field Extraction** - Specify exactly what fields you want
3. **Custom Analysis Requirements** - Describe your own analysis needs
4. **Accurate Data Only** - AI returns "Not found" instead of making up data
5. **Multiple Image Formats** - Supports JPEG, PNG, WebP

## Usage Examples

### 1. Basic Receipt Analysis (Structured Data)

```dart
import 'dart:io';
import 'package:get/get.dart';

// Initialize controller
final geminiController = Get.put(GeminiController());

// Read image
final imageFile = File('path/to/receipt.jpg');
final imageBytes = await imageFile.readAsBytes();

// Analyze receipt - returns Map<String, dynamic>
final result = await geminiController.analyzeReceiptImage(imageBytes);

if (result != null) {
  print('Merchant: ${result['merchant_name']}');
  print('Total: ${result['total_amount']}');
  print('Date: ${result['date']}');
  print('Items: ${result['items']}');
  
  // Access nested data
  if (result['items'] is List) {
    for (var item in result['items']) {
      print('Item: ${item['name']} - ${item['price']}');
    }
  }
}
```

**Expected Output Format:**
```json
{
  "merchant_name": "SuperMart",
  "total_amount": "1234.56",
  "currency": "₱",
  "date": "2025-11-13",
  "time": "14:30",
  "items": [
    {
      "name": "Product A",
      "quantity": "2",
      "price": "500.00"
    }
  ],
  "payment_method": "Cash",
  "receipt_number": "RCP-123456",
  "tax": "123.45",
  "subtotal": "1111.11",
  "address": "123 Main St",
  "phone": "123-456-7890",
  "additional_info": "Thank you for shopping"
}
```

### 2. Extract Specific Fields Only

Perfect when you know exactly what you need:

```dart
final geminiController = Get.put(GeminiController());

// Define the exact fields you want
final fieldsToExtract = [
  'Total amount',
  'Date of purchase',
  'Merchant name',
  'Payment method',
];

final imageBytes = await File('receipt.jpg').readAsBytes();

final result = await geminiController.extractCustomInfo(
  imageBytes,
  fieldsToExtract,
);

print(result);
```

**Example Output:**
```
Total amount: ₱1,234.56
Date of purchase: November 13, 2025
Merchant name: SuperMart Store
Payment method: Not found
```

### 3. Custom Analysis Requirements

For complex or unique analysis needs:

```dart
final geminiController = Get.put(GeminiController());

final requirements = '''
From this invoice image, please:
1. Extract all product SKUs
2. Calculate total discount percentage
3. Identify if this is a wholesale or retail purchase
4. Check if there are any special promotions mentioned
5. Extract the salesperson name if visible
''';

final imageBytes = await File('invoice.jpg').readAsBytes();

final result = await geminiController.analyzeCustomDocument(
  imageBytes,
  requirements,
);

print(result);
```

### 4. Integration with Image Picker

Complete example with image selection:

```dart
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MyReceiptScanner extends StatefulWidget {
  @override
  _MyReceiptScannerState createState() => _MyReceiptScannerState();
}

class _MyReceiptScannerState extends State<MyReceiptScanner> {
  final geminiController = Get.put(GeminiController());
  final ImagePicker _picker = ImagePicker();
  
  Map<String, dynamic>? receiptData;

  Future<void> scanReceipt() async {
    // Pick image
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    
    if (image == null) return;
    
    // Read bytes
    final bytes = await File(image.path).readAsBytes();
    
    // Analyze with AI
    final result = await geminiController.analyzeReceiptImage(bytes);
    
    setState(() {
      receiptData = result;
    });
    
    // Use the data
    if (result != null) {
      final amount = double.tryParse(result['total_amount'] ?? '0') ?? 0.0;
      final merchant = result['merchant_name'] ?? 'Unknown';
      
      // Save to database, update UI, etc.
      print('Amount: ₱$amount from $merchant');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: scanReceipt,
              child: Text('Scan Receipt'),
            ),
            if (receiptData != null)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Merchant: ${receiptData!['merchant_name']}'),
                      Text('Total: ₱${receiptData!['total_amount']}'),
                      Text('Date: ${receiptData!['date']}'),
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
```

### 5. Extract from Multiple Receipt Types

Handle different receipt formats:

```dart
Future<void> processReceipt(File imageFile) async {
  final bytes = await imageFile.readAsBytes();
  final geminiController = Get.put(GeminiController());
  
  // Try structured receipt analysis first
  final receiptData = await geminiController.analyzeReceiptImage(bytes);
  
  if (receiptData != null && receiptData['total_amount'] != 'Not found') {
    // Successfully extracted structured data
    saveToDatabase(receiptData);
  } else {
    // Fallback: Use custom extraction for unusual formats
    final customFields = [
      'Any total amount visible',
      'Any date visible',
      'Any merchant or store name',
      'List all numbers with currency symbols',
    ];
    
    final result = await geminiController.extractCustomInfo(
      bytes,
      customFields,
    );
    
    // Parse and save the custom result
    parseCustomResult(result);
  }
}
```

## Practical Use Cases

### Use Case 1: Expense Tracker
```dart
// Scan receipt and auto-create expense entry
Future<void> addExpenseFromReceipt() async {
  final image = await ImagePicker().pickImage(source: ImageSource.camera);
  if (image == null) return;
  
  final bytes = await File(image.path).readAsBytes();
  final data = await geminiController.analyzeReceiptImage(bytes);
  
  if (data != null) {
    final expense = ExpenseModel(
      amount: double.tryParse(data['total_amount'] ?? '0') ?? 0.0,
      merchant: data['merchant_name'] ?? 'Unknown',
      date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
      category: categorizeFromMerchant(data['merchant_name']),
      receiptImage: image.path,
    );
    
    await saveExpense(expense);
  }
}
```

### Use Case 2: Invoice Processing
```dart
Future<void> processInvoice() async {
  final requirements = '''
  Extract from this invoice:
  1. Invoice number
  2. Client name and address
  3. All line items with descriptions and amounts
  4. Subtotal, tax, and grand total
  5. Payment terms
  6. Due date
  ''';
  
  final bytes = await getInvoiceImage();
  final result = await geminiController.analyzeCustomDocument(
    bytes,
    requirements,
  );
  
  // Process the extracted invoice data
  createInvoiceRecord(result);
}
```

### Use Case 3: Price Comparison
```dart
Future<void> compareReceipts(List<File> receiptImages) async {
  final results = <Map<String, dynamic>>[];
  
  for (final image in receiptImages) {
    final bytes = await image.readAsBytes();
    final data = await geminiController.analyzeReceiptImage(bytes);
    if (data != null) results.add(data);
  }
  
  // Compare prices across different stores
  final comparison = analyzePrices(results);
  showComparisonUI(comparison);
}
```

## Tips for Best Results

### 1. Image Quality
```dart
// Use high quality when capturing
final image = await ImagePicker().pickImage(
  source: ImageSource.camera,
  imageQuality: 85, // 70-90 recommended
  maxWidth: 1920,
  maxHeight: 1080,
);
```

### 2. Lighting
- Ensure good lighting
- Avoid glare and shadows
- Flatten the receipt before scanning

### 3. Error Handling
```dart
Future<Map<String, dynamic>?> safeAnalyzeReceipt(File image) async {
  try {
    final bytes = await image.readAsBytes();
    final result = await geminiController.analyzeReceiptImage(bytes);
    
    // Validate critical fields
    if (result != null) {
      final hasTotal = result['total_amount'] != 'Not found';
      final hasMerchant = result['merchant_name'] != 'Not found';
      
      if (!hasTotal && !hasMerchant) {
        // Image quality might be poor, try again
        return null;
      }
    }
    
    return result;
  } catch (e) {
    print('Error: $e');
    return null;
  }
}
```

### 4. Handling "Not found" Values
```dart
void displayReceiptData(Map<String, dynamic> data) {
  final amount = data['total_amount'];
  final displayAmount = amount == 'Not found' 
      ? 'Unable to detect' 
      : '₱$amount';
  
  print('Total: $displayAmount');
}
```

## Navigation Integration

### Add to Dashboard
```dart
// In dashboard_page.dart
FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomImageAnalysisPage(),
      ),
    );
  },
  child: Icon(Icons.document_scanner),
)
```

### Add to Navigation Drawer
```dart
ListTile(
  leading: Icon(Icons.psychology),
  title: Text('AI Image Analysis'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomImageAnalysisPage(),
      ),
    );
  },
)
```

## API Limits & Optimization

### Rate Limiting
```dart
class RateLimiter {
  static DateTime? _lastCall;
  static const _minDelay = Duration(seconds: 1);
  
  static Future<void> waitIfNeeded() async {
    if (_lastCall != null) {
      final elapsed = DateTime.now().difference(_lastCall!);
      if (elapsed < _minDelay) {
        await Future.delayed(_minDelay - elapsed);
      }
    }
    _lastCall = DateTime.now();
  }
}

// Usage
await RateLimiter.waitIfNeeded();
final result = await geminiController.analyzeReceiptImage(bytes);
```

### Caching Results
```dart
final Map<String, Map<String, dynamic>> _cache = {};

Future<Map<String, dynamic>?> getCachedOrAnalyze(String imagePath) async {
  if (_cache.containsKey(imagePath)) {
    return _cache[imagePath];
  }
  
  final bytes = await File(imagePath).readAsBytes();
  final result = await geminiController.analyzeReceiptImage(bytes);
  
  if (result != null) {
    _cache[imagePath] = result;
  }
  
  return result;
}
```

## Troubleshooting

### Issue: Returns "Not found" for everything
- **Solution**: Improve image quality, better lighting, ensure text is readable

### Issue: JSON parsing error
- **Solution**: The AI returns raw text in `result['raw_response']`, parse manually

### Issue: Slow response
- **Solution**: Reduce image size, use `imageQuality: 70` in ImagePicker

### Issue: Incorrect amounts
- **Solution**: Use custom field extraction with specific instructions:
```dart
final fields = [
  'The final total amount at the bottom of the receipt',
  'The largest number with a currency symbol',
];
```

## Complete Example Project

See `lib/pages/custom_image_analysis_page.dart` for a full working example with:
- ✅ Image selection (camera/gallery)
- ✅ Three analysis modes (Receipt, Custom Fields, Custom Analysis)
- ✅ Structured results display
- ✅ Error handling
- ✅ Loading states

Run the example:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CustomImageAnalysisPage(),
  ),
);
```
