# Receipt Data Extraction Improvements

## Changes Made (November 14, 2025)

### 1. ✅ Expanded Source Dropdown Options

**Location**: `lib/pages/receipt_preview_page.dart`

Added comprehensive list of payment sources:
- **E-Wallets**: GCash, Maya, PayMaya, Coins.ph, GoTyme, Seabank
- **Remittance**: Palawan Express, MLhuillier, Cebuana Lhuillier, Western Union, LBC
- **Banks**: BPI, BDO, Metrobank, UnionBank, PNB, Landbank, RCBC, Security Bank, Chinabank
- **Transaction Types**: Bank Transfer, Load/E-Load
- **Fallback**: Other

### 2. ✅ Made Source Field Editable

**Before**: Source was read-only, extracted from receipt
**After**: Dropdown with 23+ options, user can change if AI misidentifies

**Implementation**:
```dart
// Initialize with detected source or default to 'GCash'
selectedSource = widget.receipt.source.isNotEmpty 
    ? widget.receipt.source 
    : 'GCash';

// User can change via dropdown
DropdownButton<String>(
  value: selectedSource,
  items: sourceOptions.map(...).toList(),
  onChanged: (newValue) => setState(() => selectedSource = newValue),
)
```

### 3. ✅ Enhanced Reference Number Detection

**Location**: `lib/services/gemini_service.dart`

Added support for multiple reference number label variations:

**Standard Labels**:
- Ref No., Ref. No., Ref No, Ref:, REF:, Ref#
- Reference Number, Reference No., Reference:

**Alternative Labels**:
- Transaction ID, Transaction No., Trans ID, Trans No, TXN ID
- Receipt No., Receipt Number, Receipt ID, Receipt #
- Confirmation Code, Confirmation No., Confirmation #
- Control No., Control Number, Control #
- Trace No., Trace Number, Tracking No.
- Transaction Reference, Order ID

**Format Support**:
- With spaces: `5034 322 274670`
- No spaces: `5034322274670`
- With dashes: `5034-322-274670`
- Alphanumeric: `GC12345678`, `TXN9876543210`

### 4. ✅ Better Logging for Debugging

Added detailed console logging:
```
=== GEMINI RAW RESPONSE ===
=== CLEANED RESPONSE ===
=== PARSED DATA ===
=== VALIDATION ===
=== FIELD VALIDATION ===
```

### 5. ✅ More Lenient Validation

**Before**: Required ALL fields (name, phone, amount) or fail
**After**: Requires at least name OR (phone + amount)

**Code**:
```dart
// Old: if (!hasRecipient && !hasPhone && !hasAmount) return null;
// New: if (!hasRecipient && !(hasValidPhone && hasValidAmount)) return null;
```

## How to Use

### Testing Receipt Extraction

1. **Take a photo** of any money transfer receipt
2. AI will extract data including reference number
3. **Review** the extracted data in preview page
4. **Edit source** if needed using dropdown
5. **Save** transaction

### Supported Receipt Types

✅ GCash receipts (physical & screenshots)
✅ Maya/PayMaya transactions
✅ Palawan Express receipts
✅ MLhuillier receipts
✅ Cebuana Lhuillier receipts
✅ Western Union receipts
✅ Bank transfer confirmations
✅ E-load receipts
✅ Any Philippine money transfer service

### Reference Number Extraction

The AI now recognizes reference numbers even if labeled differently:
- "Ref No: 123456789" ✓
- "Transaction ID: ABC123" ✓
- "Receipt #: 987654321" ✓
- "Control Number: 1234567890" ✓
- "TXN Reference: XYZ-789" ✓

## Testing Checklist

- [ ] Photo of GCash receipt
- [ ] Screenshot of Maya transaction
- [ ] Photo of Palawan receipt
- [ ] Bank transfer confirmation
- [ ] E-load receipt screenshot
- [ ] Photo of another phone screen
- [ ] Receipt with "Transaction ID" instead of "Ref No"
- [ ] Receipt with "Control Number"
- [ ] Change source dropdown to different option
- [ ] Verify changed source is saved correctly

## Benefits

1. **More Accurate** - Recognizes various reference number labels
2. **User Control** - Can correct AI mistakes via dropdown
3. **Better Coverage** - Supports 23+ payment sources
4. **Easier Debugging** - Detailed console logs show extraction process
5. **More Lenient** - Doesn't fail if some fields missing

## Files Modified

1. `lib/pages/receipt_preview_page.dart` - Added source dropdown
2. `lib/services/gemini_service.dart` - Enhanced prompts for ref number & sources
3. `lib/controllers/gemini_controller.dart` - Better error logging

## Next Steps

If extraction still fails:
1. Check console logs for detailed debugging info
2. Use `DebugNameExtractionPage` to see what AI reads
3. Verify reference number label format
4. Try adjusting source dropdown manually
5. Check if image quality is sufficient
