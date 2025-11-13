# 🔍 Name Extraction Fix & Debug Guide

## 🎯 The Problem
The sender/recipient name is **partially masked** on money transfer receipts:
- Examples: `MA****N M.`, `JO••••A D.`, `MARI* C.`
- Traditional OCR struggles with these patterns
- Gemini AI needed better instructions to find them

## ✅ What Was Fixed

### 1. Enhanced AI Prompts
The AI now specifically looks for:
- **Masked name patterns** with *, •, or ·
- **Location hints** (near "To:", "Recipient:", top of receipt)
- **Exact extraction** (keeps all masking characters)

### 2. Dual Extraction Strategy
```
┌─────────────────────────────────────┐
│ 1. Full Receipt Analysis            │
│    (Extracts all fields)            │
└──────────────┬──────────────────────┘
               │
               ▼
        Name found? ───Yes──> ✓ Done
               │
               No
               │
               ▼
┌─────────────────────────────────────┐
│ 2. Focused Name Extraction          │
│    (Dedicated prompt for names)     │
└──────────────┬──────────────────────┘
               │
               ▼
        Name found? ───Yes──> ✓ Done
               │
               No
               │
               ▼
           ❌ Return null
```

### 3. Debug Tools
Added methods to see what AI detects:
- `extractRecipientName()` - Focused name extraction
- `debugExtractAllText()` - Shows all text AI can see
- Debug page with visual testing

## 🚀 How to Test

### Option 1: Use Debug Page (Recommended)

Navigate to the debug page:
```dart
import 'package:g/pages/debug_name_extraction_page.dart';

// Navigate to it
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => DebugNameExtractionPage(),
  ),
);
```

**What it shows:**
1. ✅ **Extracted Name** - What the focused extraction found
2. 📄 **All Text AI Can See** - Complete text detection
3. 📋 **Full Receipt Data** - All extracted fields

### Option 2: Test in Code

```dart
import '../services/gemini_service.dart';
import 'dart:io';

final geminiService = GeminiService();
final imageFile = File('path/to/receipt.jpg');
final imageBytes = await imageFile.readAsBytes();

// Test name extraction
final name = await geminiService.extractRecipientName(imageBytes);
print('Extracted name: $name');

// Debug: See all text
final allText = await geminiService.debugExtractAllText(imageBytes);
print('All text:\n$allText');

// Full receipt
final receipt = await geminiService.analyzeReceiptImage(imageBytes);
print('Full receipt: $receipt');
```

## 🎯 Common Name Patterns

The AI now looks for these patterns:

| Pattern | Example | Where It Appears |
|---------|---------|------------------|
| Letters + asterisks | `MA****N M.` | GCash, Palawan |
| Letters + dots | `JO••••A D.` | Some receipts |
| Mixed | `MARI* C.` | Various services |
| Short form | `M****A L.` | Compact receipts |
| Two letters | `AN***A M.` | Various formats |

## 📍 Where AI Looks for Names

The AI searches in this order:

1. **After "To:"** label
   ```
   To: MA****N M.
   +63 915 609 1737
   ```

2. **After "Send to:"** label
   ```
   Send to: JO••••A D.
   Phone: +639156091737
   ```

3. **After "Recipient:"** label
   ```
   Recipient: MARI* C.
   Contact: +63 915 609 1737
   ```

4. **Near top with icon**
   ```
   👤 MA****N M.
   ☎️ +63 915 609 1737
   ```

5. **First text line after logo**
   ```
   [GCash Logo]
   MA****N M.
   ```

## 🔧 Troubleshooting

### Issue 1: Name Shows "Not found"

**Possible causes:**
- Image quality too poor
- Name field in unusual location
- Different masking pattern

**Solutions:**
```dart
// 1. Check what AI can see
final allText = await geminiService.debugExtractAllText(imageBytes);
print('AI sees: $allText');

// 2. Look for the name in the output
// Is it there but in different format?

// 3. Try with better image quality
final image = await ImagePicker().pickImage(
  source: ImageSource.camera,
  imageQuality: 90, // Higher quality
);
```

### Issue 2: Name Extracted Without Masking

**Example:** Returns "MARIAN M." instead of "MA****N M."

**This means:**
- The receipt doesn't have masking (full name visible)
- ✓ This is actually good - you got the full name!

### Issue 3: Wrong Name Detected

**Example:** Returns phone number or other text

**Solutions:**
```dart
// Use the debug page to see what's being detected
// Check the "All Text AI Can See" section
// Look for the actual name location

// If needed, you can add more location hints
```

## 💡 Tips for Better Results

### 1. Image Quality
```dart
// Use high quality for name detection
final image = await ImagePicker().pickImage(
  source: ImageSource.camera,
  imageQuality: 85, // 80-90 recommended
  maxWidth: 1920,
  maxHeight: 1080,
);
```

### 2. Good Lighting
- ✅ Ensure even lighting
- ✅ Avoid shadows on the name area
- ✅ No glare on the paper

### 3. Focus on Top Section
- ✅ Make sure the top of receipt is clear
- ✅ Name area should be in focus
- ✅ No creases or folds in that area

### 4. Straight Capture
- ✅ Hold phone directly above receipt
- ✅ Avoid extreme angles
- ✅ Keep receipt flat

## 🧪 Testing Different Services

### GCash
```
Expected format: "MA****N M."
Location: After "To:" or "Send to"
```

### Palawan Express
```
Expected format: "JO••••A D."
Location: Near "Receiver:" label
```

### MLhuillier
```
Expected format: "MARI* C."
Location: Top section, near recipient info
```

### Cebuana Lhuillier
```
Expected format: Various
Location: Check "Beneficiary:" field
```

## 📊 Test Results Table

Use this to track your tests:

| Receipt Type | Image Quality | Name Found? | Extracted Name | Notes |
|--------------|---------------|-------------|----------------|-------|
| GCash        | Good          | ✅          | MA****N M.     | Works |
| Palawan      | Good          | ✅          | JO••••A D.     | Works |
| MLhuillier   | Blurry        | ❌          | Not found      | Retry |
| GCash        | Good          | ✅          | MARI* C.       | Works |

## 🔄 Fallback Strategy

If name extraction still fails, the system will:

1. **Try AI twice** (full + focused extraction)
2. **Fall back to traditional OCR** (if enabled)
3. **Return null** if all methods fail
4. **Show error to user** with option to retry

```dart
// This is already implemented in EnhancedScanPage
final receipt = await geminiService.processReceipt(imageFile, feeRanges);

if (receipt == null) {
  // Try traditional OCR
  receipt = await ocrService.processReceipt(imageFile, feeRanges);
}

if (receipt == null) {
  // Ask user to retry or enter manually
  showRetryDialog();
}
```

## 📱 Quick Test Workflow

1. **Open Debug Page**
   ```dart
   Navigator.push(context, 
     MaterialPageRoute(builder: (_) => DebugNameExtractionPage())
   );
   ```

2. **Take Photo** of a receipt

3. **Click "Test Extraction"**

4. **Check Results:**
   - ✅ Extracted Name section - Is it correct?
   - 📄 All Text section - Can you see the name there?
   - 📋 Full Data section - What else was extracted?

5. **If Name Missing:**
   - Check "All Text" - Is name visible there?
   - If yes: AI sees it but isn't extracting correctly
   - If no: Image quality issue, retake photo

## 🎓 Example Output

### Good Extraction:
```json
{
  "recipient_name": "MA****N M.",
  "phone_number": "+639156091737",
  "amount": "1400.00",
  "fee": "15.00"
}
```

### Name Found in Second Try:
```
Console Output:
> Name not found in main extraction, trying focused name extraction...
> Successfully extracted name: MA****N M.
```

### Complete Failure:
```
Console Output:
> Name not found in main extraction, trying focused name extraction...
> Could not extract recipient name
> Returned: null
```

## 🚀 Next Steps

1. **Test with your actual receipts** using Debug Page
2. **Check the "All Text" output** to see what AI detects
3. **Share problem cases** - Save images where name isn't found
4. **Adjust image quality** if needed
5. **Use Enhanced Scan Page** for production

The system now has:
- ✅ Better name detection
- ✅ Fallback extraction
- ✅ Debug tools
- ✅ Clear error messages

Test it with your receipts and let me know the results! 🎯
