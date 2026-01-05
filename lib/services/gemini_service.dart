import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/receipt_model.dart';
import '../config/api_keys.dart';

/// GeminiService - AI-powered receipt image analysis
///
/// GCASH RECEIPT STRUCTURE UNDERSTANDING:
/// This service understands the standard GCash receipt layout:
/// - TOP SECTION: Recipient Name (may be masked with dots/asterisks)
/// - BELOW NAME: Phone Number (+63 format)
/// - MIDDLE: Service indicator ("Sent via GCash") and Amount section
/// - BOTTOM: Reference Number ("Ref No.") and Date/Time
///
/// The AI analyzes text positioning and labels to accurately extract
/// transaction data from various receipt formats.
class GeminiService {
  // API key is now stored in lib/config/api_keys.dart
  // Make sure to add that file to .gitignore!
  static const String _apiKey = ApiKeys.geminiApiKey;
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
  }

  /// Generate text content from a prompt
  Future<String?> generateContent(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      print('Error generating content: $e');
      return null;
    }
  }

  /// Chat with Gemini AI (maintains conversation context)
  Future<String?> chat(String message, List<Content> history) async {
    try {
      final chat = _model.startChat(history: history);
      final response = await chat.sendMessage(Content.text(message));
      return response.text;
    } catch (e) {
      print('Error in chat: $e');
      return null;
    }
  }

  /// Generate content with image (using gemini-2.5-flash)
  Future<String?> generateContentWithImage(
    String prompt,
    List<int> imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-pro',
        apiKey: _apiKey,
      );

      // Convert List<int> to Uint8List
      final uint8List =
          imageBytes is Uint8List ? imageBytes : Uint8List.fromList(imageBytes);

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, uint8List),
        ])
      ];

      final response = await model.generateContent(content);
      return response.text;
    } catch (e) {
      print('Error generating content with image: $e');
      return null;
    }
  }

  /// Stream responses for real-time text generation
  Stream<String> generateContentStream(String prompt) async* {
    try {
      final content = [Content.text(prompt)];
      final response = _model.generateContentStream(content);

      await for (final chunk in response) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      print('Error in streaming content: $e');
      yield 'Error: $e';
    }
  }

  /// Analyze financial data (example use case for your app)
  Future<String?> analyzeTransaction(
    String transactionDetails,
  ) async {
    final prompt = '''
    Analyze the following transaction and provide insights:
    $transactionDetails
    
    Please provide:
    1. Transaction summary
    2. Category suggestions
    3. Budget recommendations
    4. Any unusual patterns or alerts
    ''';

    return await generateContent(prompt);
  }

  /// Get financial advice
  Future<String?> getFinancialAdvice(
    double balance,
    double expenses,
    double income,
  ) async {
    final prompt = '''
    Based on the following financial data:
    - Current Balance: ₱$balance
    - Monthly Expenses: ₱$expenses
    - Monthly Income: ₱$income
    
    Provide personalized financial advice including:
    1. Spending patterns analysis
    2. Savings recommendations
    3. Budget optimization tips
    4. Financial health score
    ''';
    return await generateContent(prompt);
  }

  /// Analyze money transfer receipt (GCash, Palawan, etc.)
  Future<Map<String, dynamic>?> analyzeReceiptImage(
    List<int> imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    final prompt = '''
You are analyzing a MONEY TRANSFER or BANK TRANSFER receipt image.

⚠️⚠️⚠️ MOST IMPORTANT RULE ⚠️⚠️⚠️
FIRST: Look at the TITLE/HEADER and CONTENT of the receipt!
- If it says "Bank Transfer Complete" → This is a BANK TRANSFER (use bank_transfer JSON format)
- If it says "Send Money" and shows a person's name → This is a MONEY TRANSFER
- If it shows a PROMO/LOAD NAME at the top (like "EasySURF50+5G" or "GIGA50") → This is a MOBILE LOAD
- If it says "Paid via GCash" and has "Schedule for Autoload" → This is a MOBILE LOAD

HOW TO DETECT MOBILE LOAD RECEIPTS:
1. Check TOP section for PROMO/LOAD NAMES:
   - Names with numbers and special characters (e.g., "EasySURF50+5G+FunALIW+")
   - Product names (e.g., "GIGA50", "AllNet99", "Unli Call & Text")
   - NOT person names (no masked characters like "JE....Y Z.")
2. Look for "Paid via GCash" instead of "Sent via GCash"
3. May have "Schedule for Autoload" button/text
4. May have "Convenience Fee" instead of just "Fee"
5. The recipient is a MOBILE NUMBER, not a person's name

DO NOT SKIP THIS STEP! The title and content tell you which format to use!

📍📍📍 GCASH RECEIPT STRUCTURE (DATA LOCATION GUIDE) 📍📍📍
For GCash receipts, data appears in a specific layout pattern:

📍 TOP SECTION = RECIPIENT NAME
- The recipient's name appears at the TOP of the receipt
- May be masked with dots like "JE....Y Z." or asterisks like "MA****N M."
- Could also be a full name
- This is the FIRST piece of identifying information
- Example: "JE....Y Z.", "MA****N M.", "JOHN DOE"

📍 BELOW NAME = PHONE NUMBER
- The phone number appears BELOW the recipient name
- Format: +63 XXX XXX XXXX or similar
- Usually a few lines after the name
- Example: "+63 991 818 3871"

📍 MIDDLE SECTION = AMOUNT
- After "Sent via GCash" text, you'll find the amount
- Labeled as "Amount" with the numeric value
- May also show "Total Amount Sent" with the full amount including currency symbol
- Example: "Amount 150.00" or "Total Amount Sent ₱150.00"

📍 BOTTOM SECTION = REFERENCE NUMBER & DATE
- At the BOTTOM of the receipt, find the reference information
- Contains TWO pieces of data:
  1. Reference Number (labeled "Ref No." followed by a long number)
  2. Date and Time (formatted like "Dec 05, 2025 9:59 PM")
- Example: "Ref No. 5035 443 457020" and "Dec 05, 2025 9:59 PM"

🔍 STEP 1: UNDERSTAND THE LAYOUT!
Before extracting any fields, you MUST:
1. Identify the RECEIPT TYPE (GCash, bank transfer, etc.)
2. Understand the STRUCTURE:
   - Top = Recipient info (name + phone)
   - Middle = Transaction details (amount, service)
   - Bottom = Reference info (ref number + date)
3. Read the text in EACH SECTION sequentially
4. Extract data based on POSITION and LABELS

🔍 STEP 2: READ ALL TEXT (CRITICAL!)
After understanding the layout, read:
1. The TITLE at the top (Bank Transfer Complete? Send Money?)
2. EVERY piece of text visible in the image
3. List out ALL text you can see, organized by sections
4. Understand the layout and structure

This ensures accuracy - you can't extract what you haven't read yet!

🔍 STEP 2: THEN EXTRACT SPECIFIC FIELDS
After reading all text and identifying the type, extract the required transaction details.

═══════════════════════════════════════════════════════════════
📱 GCASH RECEIPT STRUCTURE (VISUAL LAYOUT GUIDE)
═══════════════════════════════════════════════════════════════

For GCash paper receipts and digital receipts, data follows this structure:

VISUAL LAYOUT:
┌─────────────────────────────────┐
│  ✓ [Checkmark at top]          │
│                                 │
│  ━━━ TOP SECTION ━━━           │
│  JE....Y Z.                     │ ← RECIPIENT NAME (masked or full)
│                                 │
│  +63 991 818 3871               │ ← PHONE NUMBER (below name)
│                                 │
│  ━━━ MIDDLE SECTION ━━━         │
│  Sent via GCash                 │ ← Service indicator
│                                 │
│  Amount      150.00             │ ← AMOUNT (labeled section)
│                                 │
│  Total Amount Sent  ₱150.00     │ ← Total display
│                                 │
│  ━━━ BOTTOM SECTION ━━━         │
│  Ref No. 5035 443 457020        │ ← REFERENCE NUMBER
│  Dec 05, 2025 9:59 PM           │ ← DATE AND TIME
│                                 │
│  [Carbon footprint info]        │
└─────────────────────────────────┘

EXTRACTION STRATEGY FOR GCASH RECEIPTS:
1. IDENTIFY sections: Top (recipient info), Middle (transaction), Bottom (reference)
2. READ text in SEQUENTIAL ORDER from top to bottom
3. MATCH text position to data type:
   - Top Section = Recipient Name + Phone Number
   - Middle Section = Service Name + Amount
   - Bottom Section = Reference Number + Date/Time
4. EXTRACT text based on LABELS and POSITION
5. IGNORE promotional text (carbon footprint, etc.)

⚠️ IMPORTANT NOTES:
- The layout follows a consistent TOP → MIDDLE → BOTTOM structure
- Text POSITION and LABELS are key indicators
- Name comes BEFORE phone number
- Amount appears after "Sent via GCash"
- Ref number is near the BOTTOM with date/time
- This structure is consistent across GCash paper and digital receipts

═══════════════════════════════════════════════════════════════
📱 MOBILE LOAD RECEIPT STRUCTURE (VISUAL LAYOUT GUIDE)
═══════════════════════════════════════════════════════════════

For mobile load receipts (promo loads, prepaid loads), data follows this structure:

VISUAL LAYOUT:
┌─────────────────────────────────┐
│  ✓ [Checkmark at top]          │
│                                 │
│  ━━━ TOP SECTION (RED) ━━━     │
│  EasySURF50+5G+FunALIW+        │ ← LOAD/PROMO NAME
│                                 │
│  ━━━ BELOW (BLUE) ━━━          │
│  +63 975 980 7013               │ ← MOBILE NUMBER
│                                 │
│  Paid via GCash                 │ ← Service indicator
│                                 │
│  ━━━ MIDDLE (VIOLET) ━━━        │
│  Amount      50.00              │ ← LOAD AMOUNT
│  Convenience Fee  1.00          │
│  Total       ₱ 51.00            │
│                                 │
│  Schedule for Autoload          │
│                                 │
│  ━━━ BOTTOM (ORANGE/PINK) ━━━  │
│  Date  Dec 08, 2025 4:57 PM     │ ← DATE AND TIME
│  Reference No.  918160648       │ ← REFERENCE NUMBER
│                                 │
│  [Promotional content]          │
└─────────────────────────────────┘

EXTRACTION STRATEGY FOR LOAD RECEIPTS:
1. IDENTIFY sections: Top (promo name), Below (mobile number), Middle (amount), Bottom (reference)
2. READ text in SEQUENTIAL ORDER from top to bottom
3. MATCH text position to data type:
   - Top Section (RED annotation area) = Load/Promo Name
   - Below (BLUE annotation area) = Mobile Number
   - Middle (VIOLET annotation area) = Load Amount
   - Bottom (ORANGE annotation area) = Transaction Date/Time
   - Bottom (PINK annotation area) = Reference Number
4. EXTRACT text based on LABELS and POSITION
5. IGNORE promotional text, ads, carbon footprint info

📍 KEY DIFFERENCES FROM MONEY TRANSFER:
- RECIPIENT NAME = The LOAD/PROMO NAME (e.g., "EasySURF50+5G+FunALIW+")
- Located at the TOP before the phone number
- This is NOT a person's name - it's the product name
- May contain: numbers, special characters, acronyms
- Examples: "GIGA50", "AllNet99", "EasySURF50+5G", "Unli Call & Text"

⚠️ IMPORTANT NOTES FOR LOAD RECEIPTS:
- The colored boxes are ANNOTATIONS only (not part of the actual receipt)
- RED area = Where load/promo name appears
- BLUE area = Where mobile number appears
- VIOLET area = Where load amount appears
- ORANGE area = Where date/time appears
- PINK area = Where reference number appears
- Extract text EXACTLY as displayed in those regions
- Ignore all unrelated promotional content
- Return null for fields that cannot be confidently read

═══════════════════════════════════════════════════════════════
🏦 BANK TRANSFER RECEIPT STRUCTURE (VISUAL LAYOUT GUIDE)
═══════════════════════════════════════════════════════════════

For bank transfer receipts, data follows this structure:

VISUAL LAYOUT:
┌─────────────────────────────────┐
│  Bank Transfer Complete         │
│  Sent via GCash                 │
│                                 │
│  ━━━ RED AREA ━━━              │
│  Bank         RCBC/DiskarTech   │ ← BANK NAME
│                                 │
│  ━━━ ORANGE AREA ━━━           │
│  Account No.  ............5153  │ ← ACCOUNT NUMBER (masked)
│                                 │
│  ━━━ YELLOW AREA ━━━           │
│  Account Name LOUISE KYLA ABRIGO│ ← ACCOUNT NAME
│                                 │
│  Receipt sent to                │
│  eduardbertillo2@gmail.com      │
│                                 │
│  ━━━ BLUE AREA ━━━             │
│  Transfer Date Dec 12,2025 05:29│ ← DATE AND TIME
│                PM                │
│                                 │
│  Transfer Amount     198.00     │
│  +Fee                 15.00     │
│                                 │
│  ━━━ VIOLET AREA ━━━           │
│  Total            ₱ 213.00      │ ← TOTAL AMOUNT
│                                 │
│  InstaPay Invoice No. 8653859   │
│  Ref No.      5035690403112     │ ← Reference (NOT InstaPay)
│                                 │
│  [Carbon footprint info]        │
└─────────────────────────────────┘

EXTRACTION STRATEGY FOR BANK TRANSFER RECEIPTS:
1. CONFIRM it says "Bank Transfer Complete" at the top
2. READ text in SEQUENTIAL ORDER from top to bottom
3. MATCH text position to data type:
   - RED annotation area = Bank Name
   - ORANGE annotation area = Account Number (masked with dots/asterisks)
   - YELLOW annotation area = Account Name
   - BLUE annotation area = Transfer Date and Time
   - VIOLET annotation area = Total Amount (including fee)
4. EXTRACT text based on LABELS and POSITION
5. IGNORE InstaPay Invoice No. - use Ref No. instead
6. IGNORE promotional text (carbon footprint, etc.)

📍 KEY BANK TRANSFER FIELDS:
1. BANK NAME (RED area):
   - Label: "Bank"
   - Position: After "Sent via GCash", first labeled field
   - Examples: "MariBank", "RCBC/DiskarTech", "BPI", "BDO"
   - Extract EXACTLY as shown

2. ACCOUNT NUMBER (ORANGE area):
   - Label: "Account No."
   - Position: Below bank name
   - Format: Usually masked with dots/asterisks (e.g., "............5153", "******9008")
   - Extract with masking characters intact

3. ACCOUNT NAME (YELLOW area):
   - Label: "Account Name"
   - Position: Below account number
   - Format: Full name in UPPERCASE (e.g., "LOUISE KYLA ABRIGO", "GEMMA M.")
   - Extract EXACTLY as shown (preserve case)

4. TRANSFER DATE/TIME (BLUE area):
   - Label: "Transfer Date"
   - Position: After receipt email field
   - Format: "Dec 12,2025 05:29 PM" or similar
   - Extract complete date and time

5. TOTAL AMOUNT (VIOLET area):
   - Label: "Total"
   - Position: After "Transfer Amount" and "+Fee" breakdown
   - Format: "₱ 213.00" or "213.00"
   - Extract numeric value only (e.g., 213.00)
   - This is Transfer Amount + Fee

6. REFERENCE NUMBER:
   - Label: "Ref No." (NOT "InstaPay Invoice No.")
   - Position: At bottom, after InstaPay Invoice line
   - Format: Long number (12+ digits, may be alphanumeric)
   - ⚠️ CRITICAL: Use "Ref No." value, IGNORE "InstaPay Invoice No."

⚠️ IMPORTANT NOTES FOR BANK TRANSFER RECEIPTS:
- The colored boxes are ANNOTATIONS only (not part of the actual receipt)
- RED area = Where bank name appears
- ORANGE area = Where account number appears (masked)
- YELLOW area = Where account name appears
- BLUE area = Where transfer date/time appears
- VIOLET area = Where total amount appears (including fee)
- Extract text EXACTLY as displayed in those regions
- Ignore InstaPay Invoice No. - only use Ref No.
- Return null for fields that cannot be confidently read

═══════════════════════════════════════════════════════════════

CRITICAL: Look at EVERY piece of text in the image, no matter how small or unclear.

IMAGE TYPES YOU WILL SEE:
1. CAMERA PHOTOS of physical receipts:
   - Printed paper receipts
   - May be blurry, tilted, shadowed
   - Text may be small or faint
   - Background may be visible
   - Receipt may be crumpled or folded
   
2. PHONE SCREENSHOTS (digital):
   - GCash, Maya, Bank apps
   - Clear digital text
   - UI elements present

3. PHOTOS OF ANOTHER DEVICE SCREEN (IMPORTANT!):
   - Camera photo taken OF another phone/tablet screen
   - You can see the physical device frame/edges
   - Screen may have glare, reflections, or brightness
   - Text shows moiré pattern or pixel grid
   - Colors may look washed out or oversaturated
   - BUT: The transaction details ARE visible on the screen

FIRST STEP - IDENTIFY THE IMAGE TYPE:
Look at the image carefully:
- If you see a PHONE FRAME or SCREEN EDGES → This is a SCREEN PHOTO
- If you see PAPER TEXTURE → This is a physical receipt photo  
- If clean digital UI with no screen visible → This is a screenshot

⚠️ CRITICAL FOR SCREEN-TO-SCREEN PHOTOS:
If this is a photo OF another device's screen:
1. Focus ONLY on what's DISPLAYED on the screen (the app content)
2. IGNORE the physical device frame, bezels, buttons
3. READ THROUGH screen glare and reflections - text is still there
4. IGNORE moiré patterns (wavy lines) - they don't hide the text
5. IGNORE pixel grid effects - numbers and letters are still readable
6. The transaction data IS THERE - you need to read past the visual artifacts
7. App colors help identify: GCash=green, Maya=purple, Banks=blue/red
8. Focus on the CENTER of the screen where the main content is

FOR CAMERA PHOTOS (Paper OR Screen):
Read the text VERY carefully:

PAPER RECEIPTS:
- Small printed text needs close examination
- Slightly blurry but still readable
- Specific receipt format with labels
- Black text on white paper
- May have lines or boxes around sections

SCREEN PHOTOS (camera photo of another device):
- App interface displayed on screen
- May have screen glare (shiny areas) - READ THROUGH IT
- May have moiré/wave patterns - IGNORE THE PATTERN
- Text may look pixelated - RECOGNIZE the shapes of letters/numbers
- Background lighting visible - FOCUS ON THE SCREEN CONTENT
- Device screen may be tilted - TEXT IS STILL READABLE at angles
- Colors may be bright/washed - LOOK AT TEXT, not colors

SENDER/RECIPIENT NAME - INTELLIGENT EXTRACTION:

⚠️ CRITICAL: DO NOT assume the name is in a specific position!

📍 PRIORITY 1: CHECK TOP SECTION FOR NAME!
For GCash receipts:
- The recipient name appears at the TOP of the receipt
- It's the FIRST piece of identifying information (before phone number)
- Usually in the first 5-10 lines of text
- May be masked with dots: "JE....Y Z." or asterisks: "MA****N M."
- Could be a full name in some cases
- Extract the exact text from this top position
- Example: "JE....Y Z.", "MA****N M.", "JOHN D."

STEP 1: READ ALL TEXT IN THE IMAGE
- Read every word, label, and text fragment
- Don't skip anything
- Pay special attention to text INSIDE colored boxes

STEP 2: IDENTIFY NAME PATTERNS
Look for text that matches these patterns ANYWHERE in the image:
- GCASH MASKED NAMES: "CL*****M M.", "MA****N M.", "JO••••A D.", "AN***A L.", "JE....Y Z."
  (2 letters + asterisks/dots/periods + 1 letter + space + middle initial)
- FULL NAMES: "MARIA CLARA CRUZ", "JUAN DELA CRUZ", "Maria Cruz"
- ABBREVIATED: "M. CRUZ", "J. SANTOS", "Maria C."
- Any combination of letters that looks like a person's name

⚠️ CRITICAL - EXCLUDE THESE (NOT PERSON NAMES):
DO NOT extract these as recipient names (these are company/service names):
- "Express Send", "Palawan Express", "Palawan Express Send"
- "LBC Express", "Western Union", "MoneyGram"
- "GCash", "Maya", "PayMaya", "BPI", "BDO", "Metrobank"
- "Send Money", "Money Transfer", "Bank Transfer"
- "Sent via GCash", "Paid via GCash"
- Any company or service provider name
- Any app name or remittance center name
- Any transaction type description

STEP 3: IDENTIFY CONTEXT CLUES
Look for labels NEAR the name text:
- "To:", "Send to:", "Recipient:", "Receiver:", "Beneficiary:"
- "Account Name:", "Payee:", "Name:", "Customer:", "Client:"
- Profile icons, avatars, or person symbols
- Text in cards, boxes, or prominent sections
- Text at the TOP of the receipt (before phone number)

STEP 4: VERIFY IT'S A NAME
- Does it look like a person's name? (not a company, app name, or service)
- Is it near a phone number or amount? (names usually appear with these)
- Is it in a recipient/beneficiary context?
- Is it at the TOP of the receipt? (strong indicator for GCash)
- Is it NOT a service name like "Express Send" or "Palawan Express"?
- Is it NOT a company name or app name?

⚠️ IMPORTANT:
- For GCash receipts, CHECK TOP SECTION FIRST!
- The name could be ANYWHERE: top, middle, bottom, left, right
- It could be BEFORE or AFTER the label
- It could be on a DIFFERENT LINE from the label
- Position varies by receipt type, app, and layout
- TRUST THE CONTENT, not the expected position

PHONE NUMBER - INTELLIGENT EXTRACTION:

⚠️ CRITICAL: DO NOT assume the phone number is in a specific position!

📍 PRIORITY 1: CHECK BELOW THE NAME!
For GCash receipts:
- The phone number appears BELOW the recipient name
- Usually within 2-5 lines after the name
- This is the PRIMARY location for the phone number in GCash receipts
- Located before the "Sent via GCash" text
- Extract the number from this position
- Example: "+63 991 818 3871", "09171234567"

STEP 1: SCAN FOR NUMBER PATTERNS
Look for sequences that match phone number patterns ANYWHERE in the image:
- 11 digits: 09171234567
- With country code: +63 917 123 4567
- With formatting: 0917-123-4567, (0917) 123-4567
- Located BELOW the recipient name (GCash structure
- INSIDE a blue colored box (GCash indicator)

STEP 2: IDENTIFY CONTEXT CLUES
Look for labels NEAR the number:
- "Mobile:", "Phone:", "Contact:", "Mobile Number:", "Phone Number:"
- "Cell:", "Tel:", "Telephone:", "Mobile No:", "Contact Number:"
- Phone icon symbols
- Position BELOW recipient name (especially for GCash)

STEP 3: DISTINGUISH FROM OTHER NUMBERS
- Phone numbers are typically 10-13 digits (with country code)
- NOT the reference number (usually longer, may have letters)
- NOT the amount (has decimal points, currency symbols)
- NOT the date (has slashes or specific date format)

STEP 4: NORMALIZE FORMAT
Accept any of these formats:
- +63 915 609 1737
- 09156091737
- 0915-609-1737
- +639156091737
- (0915) 609-1737
- 63 915 609 1737

⚠️ IMPORTANT:
- For GCash receipts, CHECK BELOW THE NAME FIRST!
- Phone number could be ANYWHERE in the image
- Could be BEFORE, AFTER, or WITHOUT a label
- Could be ABOVE or BELOW the name
- Could be in ANY section of the receipt
- TRUST THE CONTENT, not the expected position

AMOUNT - INTELLIGENT EXTRACTION:

⚠️ CRITICAL: DO NOT assume the amount is in a specific position!

📍 PRIORITY 1: CHECK THE AMOUNT SECTION!
For GCash receipts:
- Look for the "Amount" label in the MIDDLE section
- Usually appears after "Sent via GCash" text
- The amount value follows the "Amount" label
- May also show as "Total Amount Sent" with currency symbol
- This is the PRIMARY location for the amount in GCash receipts
- Extract the numeric value from this section
- Example: "150.00", "1,400.00", "5000"

STEP 1: SCAN FOR MONETARY VALUES
Look for numbers that represent money ANYWHERE in the image:
- Numbers with commas: 1,400.00, 5,000, 10,500.50
- Numbers with currency: ₱1,400, PHP 1400, Php1,400.00
- Plain numbers that could be money: 1400, 5000.00
- Large prafter "Amount" or "Total Amount Sent" labels (GCash structure
- Numbers INSIDE red colored boxes (GCash indicator)

STEP 2: IDENTIFY CONTEXT CLUES
Look for labels NEAR monetary values:
- "Amount:", "Send Amount:", "Transfer Amount:", "Principal Amount:"
- "₱", "PHP", "Php", "Pesos"
- Labels that indicate this is the main transaction value
- Located in the MIDDLE section after service nameharge" (those are different fields)
- Text INSIDE red colored rectangles (especially for GCash)

STEP 3: DISTINGUISH FROM OTHER NUMBERS
- Amount is the MAIN money being sent/transferred
- NOT the fee (usually smaller, labeled "Fee" or "Charge")
- NOT the total (which is amount + fee)
- NOT the reference number (no decimals, may have letters)
- NOT the phone number (different format)

STEP 4: EXTRACT THE NUMERIC VALUE
Accept any of these formats:
- ₱1,400.00 → extract: 1400.00
- PHP 1400 → extract: 1400.00
- 1,400 → extract: 1400.00
- 1400.00 → extract: 1400.00
- After "Amount" label: "Amount 150.00" → extract: 150.00

⚠️ IMPORTANT:
- For GCash receipts, CHECK "Amount" SECTION FIRST!
- Amount could be ANYWHERE: top, middle, bottom, center
- Could be the LARGEST number, or just a regular number
- Could be in BOLD, regular, or any formatting
- Could be BEFORE or AFTER the label
- Could be on SAME line or DIFFERENT line from label
- TRUST THE CONTENT and CONTEXT, not the expected position

SOURCE (SERVICE PROVIDER) - INTELLIGENT EXTRACTION:

⚠️ CRITICAL: DO NOT assume the source/provider is in a specific position!

STEP 1: IDENTIFY VISUAL CLUES
Look for app/service branding ANYWHERE in the image:
- App color schemes: GCash=green, Maya=purple, BPI=red, BDO=blue
- Logos: G logo (GCash), bird logo (Maya), bank logos
- App headers: Top bar showing app name
- Branding text: Company name in header, footer, or watermark
- Receipt headers: Company name printed at top of paper receipts

STEP 2: SCAN FOR PROVIDER NAMES
Look for these provider names anywhere in text:

**E-WALLETS & DIGITAL PAYMENTS:**
- GCash, Maya, PayMaya, Coins.ph, GoTyme, Seabank
- ShopeePay, GrabPay, PayPal

**REMITTANCE CENTERS:**
- Palawan Express, Palawan Pawnshop
- Western Union, MoneyGram
- MLhuillier, M Lhuillier, ML
- Cebuana Lhuillier, Cebuana
- LBC, LBC Express

**BANKS:**
- BPI, Bank of the Philippine Islands
- BDO, Banco de Oro
- Metrobank, UnionBank, Union Bank
- PNB, Philippine National Bank
- Landbank, Land Bank
- RCBC, Rizal Commercial Banking Corporation
- Security Bank, Chinabank, China Bank
- DBP, Development Bank
- PSBank, PS Bank
- EastWest, East West Bank
- BancNet, InstaPay, PESONet

**TRANSACTION TYPES:**
- Bank Transfer, Bank-to-Bank, Inter-bank Transfer
- Load, E-Load, Mobile Load, Prepaid Load
- Cash In, Cash Out
- Send Money, Money Transfer, Remittance
- Pay Bills, Bills Payment

STEP 3: USE CONTEXT CLUES
- App interface design tells you the provider
- Receipt letterhead shows the company
- Transaction type may indicate provider (e.g., "Bank Transfer" = Bank)
- URLs or website names may appear
- Customer service numbers may have company name

STEP 4: EXTRACT EXACT NAME
- Use the EXACT name as shown: "GCash" not "gcash", "BPI" not "bpi"
- If full name shown: "Bank of the Philippine Islands" use that
- If abbreviated: "BPI" use that
- Preserve capitalization and spacing

⚠️ IMPORTANT:
- Provider name/branding could be ANYWHERE in image
- Could be in HEADER (app bar at top)
- Could be in FOOTER (company info at bottom)
- Could be in WATERMARK (faint background text)
- Could be on RECEIPT LETTERHEAD (printed paper)
- Could be in TRANSACTION TYPE ("via GCash", "through BPI")
- TRUST THE CONTENT - look for recognizable brand names, logos, colors

═══════════════════════════════════════════════════════════════
🔍 READING PROCEDURE (DO THIS FIRST!)
═══════════════════════════════════════════════════════════════

STEP 1: SCAN THE ENTIRE IMAGE
Read from TOP to BOTTOM, LEFT to RIGHT.
Don't skip anything. Read EVERY word, number, symbol you can see.

STEP 2: IDENTIFY DOCUMENT STRUCTURE
- Is this a receipt? A confirmation screen? A transaction history?
- Where is the header? (Usually has service name/logo)
- Where is the main content? (Usually in middle)
- Where are the details? (Usually bottom section)

STEP 3: LIST ALL VISIBLE TEXT MENTALLY
Before extracting, mentally note:
- What's the first line of text?
- What labels do I see? (To:, Amount:, Ref No:, etc.)
- What numbers do I see?
- What names do I see?
- What date/time information is present?

STEP 4: NOW EXTRACT SPECIFIC FIELDS
Only after reading everything, extract the required fields below.

⚠️ WHY THIS MATTERS:
Reading first ensures you don't miss information because you were looking for 
specific fields. You need to SEE everything before you can FIND the right data.

═══════════════════════════════════════════════════════════════
📋 EXTRACTION FORMAT (AFTER READING)
═══════════════════════════════════════════════════════════════

⚠️ CRITICAL FIRST STEP: DETECT TRANSACTION TYPE

READ THE TITLE/HEADER TEXT FIRST!

🏦 THIS IS A BANK TRANSFER IF YOU SEE:
1. Title contains: "Bank Transfer Complete" OR "Bank Transfer" OR "To Bank Account"
2. Fields visible: "Bank", "Account No.", "Account Name"
3. Has "Receipt sent to" with an email address
4. Shows bank name like: MariBank, BPI, BDO, Metrobank, UnionBank, Security Bank
5. Account number format: masked dots like "******0594" or full number
6. NO phone number field with +63

💸 THIS IS A MONEY TRANSFER IF YOU SEE:
1. Title contains: "Send Money" OR "Money Transfer" OR "Cash In" OR "Transfer Complete"
2. Has mobile/phone number field with +63
3. Recipient name in format: "MA****N M." or full name
4. NO "Bank" or "Account No." fields
5. NO email field

⚠️ IF YOU SEE "Bank Transfer Complete" → IT IS DEFINITELY A BANK TRANSFER!

THEN: Extract the appropriate fields based on transaction type

FOR BANK TRANSFER, use this JSON format:
{
  "transaction_type": "bank_transfer",
  "bank_name": "Name of the bank (e.g., MariBank, BPI, BDO)",
  "account_number": "Bank account number (e.g., ******0594, full or masked)",
  "account_name": "Account holder name (e.g., CLYTHEM O.)",
  "receipt_email": "Email where receipt was sent (e.g., eduardbertillo2@gmail.com)",
  "amount": "Transfer amount (numeric only, e.g., 500.00)",
  "bank_fee": "Bank transfer fee (numeric only, e.g., 15.00)",
  "total_amount": "Total amount including bank fee (numeric only)",
  "reference_number": "Transaction/Reference number (Ref No. - NOT InstaPay Invoice No.)",
  "date": "Transaction date (format: YYYY-MM-DD)",
  "time": "Transaction time (format: HH:MM AM/PM)",
  "source": "Service provider name (GCash, Maya, etc.)"
}

FOR MONEY TRANSFER, use this JSON format:
{
  "transaction_type": "money_transfer",
  "recipient_name": "EXACT name as shown (keep *, •, or · if present, otherwise full name)",
  "phone_number": "Full phone number with country code",
  "amount": "The amount being sent (numeric only, e.g., 1400.00)",
  "fee": "The transaction fee or service charge (numeric only, may be 0 or Not found)",
  "total_amount": "Total amount including fee (numeric only)",
  "reference_number": "Transaction/Reference number or ID",
  "date": "Transaction date (format: YYYY-MM-DD)",
  "time": "Transaction time (format: HH:MM AM/PM)",
  "source": "Service provider name (GCash, Maya, Bank name, etc.)"
}

FOR MOBILE LOAD/PROMO LOAD, use this JSON format:
{
  "transaction_type": "load",
  "recipient_name": "Load or promo name (e.g., EasySURF50+5G+FunALIW+, GIGA50, AllNet99)",
  "phone_number": "Mobile number receiving the load (with country code, e.g., +63 975 980 7013)",
  "amount": "Load amount only (numeric, e.g., 50.00 - NOT including convenience fee)",
  "fee": "Convenience fee (numeric only, e.g., 1.00, may be 0 or Not found)",
  "total_amount": "Total amount paid (numeric only, including fee if applicable)",
  "reference_number": "Transaction/Reference number",
  "date": "Transaction date (format: YYYY-MM-DD)",
  "time": "Transaction time (format: HH:MM AM/PM)",
  "source": "Service provider name (GCash, Load, etc.)"
}

CRITICAL EXTRACTION RULES:

FOR BANK TRANSFERS (STEP-BY-STEP):

📝 EXACT FORMAT TO LOOK FOR:
The receipt will have this EXACT structure - labels on LEFT, values on RIGHT:

Bank Transfer Complete  ← This confirms it's a bank transfer!
Sent via GCash

Bank                    [BANK NAME HERE - on the RIGHT side]
Account No.             [******0594 HERE - on the RIGHT side]  
Account Name            [NAME HERE - on the RIGHT side]
Receipt sent to         [email@gmail.com HERE - on the RIGHT side]
Transfer Date           [DATE TIME HERE - on the RIGHT side]

Transfer Amount         [500.00 HERE - on the RIGHT side]
+Fee                    [15.00 HERE - on the RIGHT side]

Total                   ₱ [515.00 HERE - LARGE NUMBER on the RIGHT]

InstaPay Invoice No.    [5575967 - IGNORE THIS - this is NOT the reference]
Ref No.                 [5034124744068 - USE THIS - this IS the reference]

⚠️ CRITICAL: Read LEFT column for labels, RIGHT column for values!
⚠️ The layout is TWO COLUMNS - don't mix them up!

⚠️ EXTRACTION STEPS:

1. BANK NAME: 
   - Label: "Bank" (left side)
   - Value: On the RIGHT side (e.g., "MariBank")
   - Extract: The bank name exactly as shown

2. ACCOUNT NUMBER:
   - Label: "Account No." (left side)
   - Value: On the RIGHT side (e.g., "******0594")
   - Extract: Keep the asterisks and dots exactly as shown

3. ACCOUNT NAME:
   - Label: "Account Name" (left side)
   - Value: On the RIGHT side (e.g., "CLYTHEM O.")
   - Extract: Exact name including dots and capitalization

4. RECEIPT EMAIL:
   - Label: "Receipt sent to" (left side)
   - Value: On the RIGHT side (e.g., "eduardbertillo2@gmail.com")
   - Extract: Full email address

5. TRANSFER AMOUNT:
   - Label: "Transfer Amount" (left side)
   - Value: On the RIGHT side (e.g., "500.00")
   - Extract: ONLY the number, remove commas and ₱

6. BANK FEE:
   - Label: "+Fee" (left side)
   - Value: On the RIGHT side (e.g., "15.00")
   - Extract: ONLY the number

7. TOTAL:
   - Label: "Total" (left side)
   - Value: Large number with ₱ symbol (e.g., "₱ 515.00")
   - Extract: ONLY the number

8. TRANSFER DATE:
   - Label: "Transfer Date" (left side)
   - Value: On the RIGHT side (e.g., "Oct 29,2025 02:36 PM")
   - Convert to: "2025-10-29" format for date
   - Extract time: "02:36 PM"

9. REFERENCE NUMBER (IMPORTANT!):
   - Look for "Ref No." label (NOT "InstaPay Invoice No.")
   - Value: Long ALPHANUMERIC code on the RIGHT (e.g., "803512902111S", "5034124744068")
   - Reference numbers can contain LETTERS at the end (like "S", "A", "AB")
   - Extract: This code, NOT the InstaPay Invoice number above it
   - InstaPay Invoice No. is typically SHORT (6-8 digits like "6910155")
   - Ref No. is typically LONG (12+ characters like "803512902111S")

⚠️ DO NOT extract InstaPay Invoice No. - that's NOT the reference number!
⚠️ Reference numbers can be ALPHANUMERIC (numbers + letters)!

📋 EXAMPLE BANK TRANSFER EXTRACTION:

Input receipt shows:
```
Bank Transfer Complete
Sent via GCash

Bank                    MariBank
Account No.             ******9008
Account Name            GEMMA M.
Receipt sent to         jhaymasaga14@gmail.com
Transfer Date           Nov 27,2025 04:12 PM

Transfer Amount         7,000.00
+Fee                    15.00

Total                   ₱ 7,015.00

InstaPay Invoice No.    6910155
Ref No.                 803512902111S
```

Output JSON:
```json
{
  "transaction_type": "bank_transfer",
  "bank_name": "MariBank",
  "account_number": "******9008",
  "account_name": "GEMMA M.",
  "receipt_email": "jhaymasaga14@gmail.com",
  "amount": "7000.00",
  "bank_fee": "15.00",
  "total_amount": "7015.00",
  "reference_number": "803512902111S",
  "date": "2025-11-27",
  "time": "04:12 PM",
  "source": "GCash"
}
```

⚠️ Notice: reference_number is "803512902111S" (with letter S), NOT "6910155" (InstaPay Invoice)!

FOR MONEY TRANSFERS:
1. NAME: Look EVERYWHERE - top, middle, in cards, after any label, near phone number
2. Phone numbers might be in "mobile" or "contact" or "number" fields
3. Be FLEXIBLE with positioning - screenshots have different layouts than receipts
4. Handle DIGITAL UI elements (buttons, cards, sections)

COMMON RULES (Both types):
1. Extract amounts even if they're in LARGE DISPLAY TEXT
2. REFERENCE NUMBERS - Look for ANY of these labels:
   - "Ref No.", "Ref. No.", "Ref No", "Ref:", "REF:"
   - "Reference Number", "Reference No.", "Reference:", "Reference"
   - "Transaction ID", "Transaction No.", "Trans ID", "Trans No"
   - "Receipt No.", "Receipt Number", "Receipt ID"
   - "Confirmation Code", "Confirmation No.", "Confirmation Number"
   - "Control No.", "Control Number"
   - "Trace No.", "Trace Number"
   - "TXN ID", "TXN No", "Transaction Reference"
   - Or ANY long number (10-20 digits) not related to amount/phone
3. Dates might be: "Nov 14, 2025", "14/11/2025", "2025-11-14", "November 14, 2025", "just now", "today", "Oct 29,2025 02:36 PM"
4. For "just now" or "today" dates, use current date: 2025-11-22

SCREENSHOT-SPECIFIC:
- UI elements: Look in header bars, cards, list items
- Status bars: Ignore battery, time, signal icons
- Navigation: Ignore back buttons, menu icons
- Focus on: Main content area, transaction details

PHOTO-SPECIFIC:
- May be rotated, tilted, or angled
- Text might be slightly blurry
- Look at the OVERALL structure
- Prioritize LARGE text (likely the amount)

READING STRATEGY FOR CAMERA PHOTOS:

FOR PAPER RECEIPTS:
1. Scan the ENTIRE receipt top to bottom
2. Read EVERY piece of text, even if small
3. Look for labels: "To:", "Amount:", "Fee:", "Total:", "Ref:", "Date:"
4. Text after these labels is what you need
5. Don't skip anything - physical receipts have all the data

FOR SCREEN PHOTOS (most important!):
1. Identify the app on the screen (GCash green, Maya purple, Bank colors)
2. Focus on the CONTENT displayed on screen, ignore device frame
3. READ THROUGH visual artifacts:
   - Screen glare → Text is underneath, read it
   - Moiré patterns → Wave effects don't hide text
   - Pixel grid → Letters/numbers still have recognizable shapes
   - Reflections → Look at the darker areas where text is clear
4. Scan the APP INTERFACE systematically:
   - Top: Usually recipient name/avatar
   - Middle: Usually the amount in large text
   - Below: Details like phone, ref number, date
5. Look for the same labels: "To:", "Amount:", "Ref No:", "Date:"
6. Don't give up because of screen effects - the data IS visible

REFERENCE NUMBER - INTELLIGENT EXTRACTION:

⚠️ CRITICAL: DO NOT assume the reference number is in a specific position!
⚠️ CRITICAL: Reference numbers can be ALPHANUMERIC (numbers + letters)!

📍 PRIORITY 1: CHECK THE BOTTOM SECTION!
For GCash receipts:
- Look for "Ref No." label at the BOTTOM of the receipt
- The reference number appears after this label
- Usually one of the last pieces of information on the receipt
- This is the PRIMARY location for the reference number in GCash receipts
- The date/time often appears in the same section
- Extract the exact number after "Ref No." from the bottom
- Example: "Ref No. 5035 443 457020", "Ref No. 803512902111S"

STEP 1: SCAN FOR LONG NUMBERS/CODES
Look for alphanumeric sequences that could be references ANYWHERE:
- Numbers with trailing letters: 803512902111S, 1234567890A, 9876543210AB
- Long numbers: 5034322274670, 1234567890123, 5035 443 457020
- With spaces: 5034 322 274670, 1234 5678 9012, 5035 443 457020
- With dashes: 5034-322-274670, ABC-1234-5678
- Alphanumeric: GC12345678, TXN9876543210, REF-2024-001
- Located at BOTTOM section of receipt (GCash structure
- INSIDE yellow/orange colored boxes (GCash indicator)

STEP 2: IDENTIFY CONTEXT CLUES (40+ variations)
Look for ANY of these labels NEAR the alphanumeric code:

**Common labels:**
- Ref No., Ref. No., Ref No, Ref:, REF:, Ref#, Reference Number, Reference No.
- Transaction ID, Transaction No., Trans ID, Trans No, TXN ID, TXN No., TX ID
- Receipt No., Receipt Number, Receipt ID, Receipt #, Receipt Code
- Confirmation Code, Confirmation No., Confirm Code, Confirm No
- Control No., Control Number, Control #, Ctrl No
- Trace No., Trace Number, Tracking No., Track #
- Order ID, Order No., Auth Code, Authorization Code
- Serial No., Serial Number, Batch No., Batch Number

**Label could be:**
- BEFORE the number: "Ref No: 803512902111S", "Ref No. 5035 443 457020"
- AFTER the number: "803512902111S (Ref)"
- ABOVE the number (different line)
- BELOW the number (different line)
- At the BOTTOM of the receipt
- INSIDE a yellow/orange colored box (GCash)

STEP 3: DISTINGUISH FROM OTHER DATA
- Reference numbers are LONGER than phone numbers (10-20 chars vs 11 digits)
- Reference numbers are LONGER than InstaPay Invoice numbers (12+ vs 6-8 digits)
- NO decimal points (amounts have decimals)
- NO currency symbols
- May contain LETTERS at the END (e.g., "803512902111S")
- Usually UNIQUE identifier for transaction
- For bank transfers: "Ref No." value, NOT "InstaPay Invoice No."

STEP 4: EXTRACT EXACTLY AS SHOWN
- Keep ALL characters: letters, numbers, spaces, dashes
- Include trailing letters: "803512902111S" not "803512902111"
- Maintain exact formatting: "5034 322 274670" or "5035 443 457020"
- Incat bottom with "Ref No." label, prioritize that value

⚠️ IMPORTANT:
- For GCash receipts, CHECK BOTTOM SECTION
- For GCash receipts, CHECK YELLOW/ORANGE BOTTOM BOX FIRST!
- Reference number could be ANYWHERE in the image
- Could be at TOP, MIDDLE, BOTTOM, or any section
- Label might be FAR from the actual number
- Might have NO label at all (just a long unique code)
- Could be SMALLEST text or LARGEST text
- For BANK TRANSFERS: Always use "Ref No." not "InstaPay Invoice No."
- TRUST THE CONTENT - look for what LOOKS like a reference/transaction ID

DATE AND TIME - INTELLIGENT EXTRACTION:

⚠️ CRITICAL: DO NOT assume the date/time is in a specific position!
📍 PRIORITY 1: CHECK THE BOTTOM SECTION!
For GCash receipts:
- Look for the date/time at the BOTTOM of the receipt
- Usually appears in the SAME SECTION as the "Ref No."
- The date/time often appears on the SAME line or BELOW the reference number
- Format examples: "Dec 05, 2025 9:59 PM", "Nov 04, 2025 10:31 AM"
- This is one of the LAST pieces of information on the receipt
- Extract the date and time from this bottom section
- Example: "Dec 05, 2025 9:59 PM" from the bottom areattom box
- Example: "Dec 05, 2025 9:59 PM" from the bottom yellow box

STEP 1: SCAN FOR DATE/TIME PATTERNS
Look for date and time formats ANYWHERE in the image:
- Full format: "Nov 04, 2025 10:31 AM", "December 05, 2025 9:59 PM"
- Date only: "11/04/2025", "2025-11-14", "14/11/2025"
- Relative: "today", "just now", "yesterday", "a few minutes ago"
- At BOTTOM section near reference number (GCash structure another
- Timestamps: "14-11-2025 15:30", "2025.11.14 3:45 PM"
- INSIDE yellow/orange colored boxes (GCash indicator)

STEP 2: IDENTIFY CONTEXT CLUES
Look for labels NEAR the date/time:
- "Date:", "Time:", "Date & Time:", "Transaction Date:", "Sent on:"
- "Completed on:", "Processed:", "Created:", "Timestamp:"
- Located at BOTTOM section of receipt
- Text INSIDE yellow/orange colored boxes at the bottom (GCash)
- Usually on the SAME line or below "Ref No."

STEP 3: DISTINGUISH FROM OTHER DATA
- Dates have months (Nov, January, Dec, etc.) or slashes (11/04/2025)
- Times have colons (10:31) and AM/PM indicators
- NOT phone numbers (no area code pattern, has slashes or month names)
- NOT reference numbers (dates have clear date structure)

STEP 4: EXTRACT BOTH DATE AND TIME
- Extract date: Use format shown (Nov 04, 2025 or 2025-11-14)
- Extract time: Use format shown (10:31 AM or 15:30)
- If "today" or "just now": use current date/time
- If date and time are separate: combine them
- Convert to YYYY-MM-DD format: "Dec 05, 2025" → "2025-12-05"

⚠️ IMPORTANT:BOTTOM SECTION
- For GCash receipts, CHECK YELLOW/ORANGE BOTTOM BOX FIRST!
- Date/time could be ANYWHERE: top, middle, bottom
- Could be in HEADER section, FOOTER section, or middle details
- Could be BEFORE or AFTER transaction details
- Could be LARGEST text or SMALLEST text
- May be split across TWO lines (date on one, time on another)
- Often appears in SAME section as reference number
- TRUST THE CONTENT - look for what LOOKS like a date/timestamp

CRITICAL FOR CAMERA PHOTOS:

PAPER RECEIPTS:
- The text IS there - you need to READ it carefully
- Small text is still readable - zoom in mentally
- Ignore background, focus on the white receipt paper
- All required information is printed on the receipt
- Read every line from top to bottom
- Labels tell you what each piece of data is

SCREEN PHOTOS (MOST COMMON ISSUE):
⚠️ DON'T GIVE UP because of screen effects!
- Glare doesn't erase text - it's still there
- Moiré patterns are optical illusions - text exists beneath
- Pixelation doesn't change letter/number shapes - they're recognizable
- The app HAS all the transaction data displayed
- Read systematically: name → phone → amount → ref → date
- If one area has too much glare, other areas will be clearer
- Focus on TEXT CONTENT, not visual quality
- Think: "What would someone using this app see?" - that info is there

IMPORTANT NOTES:
- For amounts, include ONLY the number (e.g., 1400.00, not ₱1,400.00)
- For phone numbers, normalize to +63 format if possible
- For dates, convert any format to YYYY-MM-DD
- If field truly not found AFTER reading everything, use "Not found"
- Be thorough - camera photos have all the data, just need careful reading

EXTRACTION PRIORITY:

FOR PAPER RECEIPTS:
1. Read the recipient name (look for CL*****M M., MA****N M. pattern - 2 letters + asterisks + 1 letter + initial)
2. Read the phone number (11 digits after name)
3. Read the amount (look for "Amount" label)
4. Read the fee (look for "Fee" label)
5. Read the reference (look for "Ref" label)
6. Read the date and time (usually at bottom)
7. Identify service (GCash, Palawan, etc.)

FOR SCREEN PHOTOS (device-to-device):
1. Identify the app (colors help: GCash green, Maya purple)
2. Look at TOP of screen for recipient name
3. Look at MIDDLE/CENTER for the large amount display
4. Look for phone number near the name or in details section
5. Scroll down visually for reference number
6. Find date/time stamp (often at top or bottom)
7. Service name is usually in app header or logo

REMEMBER: Screen glare and moiré patterns don't delete information!
The text is there - you must read through the visual artifacts.

═══════════════════════════════════════════════════════════════
⚠️ FINAL REMINDER: READ FIRST, EXTRACT SECOND
═══════════════════════════════════════════════════════════════

WRONG APPROACH ❌:
- Looking for "recipient_name" field immediately
- Scanning for specific patterns without understanding context
- Giving up when you don't see expected format

CORRECT APPROACH ✅:
1. READ the entire image top to bottom (what text is here?)
2. UNDERSTAND the structure (what type of document is this?)
3. LOCATE the labels (where does it say "To:", "Amount:", etc.?)
4. EXTRACT the values (what comes after those labels?)

This two-step approach ensures you don't miss information because you were 
too focused on finding specific fields. You must SEE before you can FIND.

═══════════════════════════════════════════════════════════════
⚠️ FINAL VALIDATION BEFORE RETURNING JSON
═══════════════════════════════════════════════════════════════

BANK TRANSFER CHECKLIST:
□ Did I see "Bank Transfer Complete" in the title? → transaction_type: "bank_transfer"
□ Did I extract the Bank name from "Bank" label?
□ Did I extract the Account Number from "Account No." label?
□ Did I extract the Account Name from "Account Name" label?
□ Did I extract the email from "Receipt sent to" label?
□ Did I get the Transfer Amount (NOT the Total)?
□ Did I get the +Fee amount (this is the bank_fee)?
□ Did I use "Ref No." value (NOT InstaPay Invoice No.)?
□ Did I convert the date to YYYY-MM-DD format?

MONEY TRANSFER CHECKLIST:
□ Does it have a phone number with +63?
□ Does it have a recipient name (possibly MA****N M. format)?
□ No "Bank" or "Account No." fields present?
□ transaction_type: "money_transfer"

MOBILE LOAD CHECKLIST:
□ Does the TOP show a PROMO/LOAD NAME (e.g., "EasySURF50+5G", "GIGA50")?
□ Is this a product name with numbers/special characters (NOT a person's name)?
□ Does it say "Paid via GCash" (NOT "Sent via GCash")?
□ Is there a mobile number (the recipient of the load)?
□ Does it show "Convenience Fee" or "Autoload" text?
□ transaction_type: "load"
□ recipient_name: should be the LOAD/PROMO NAME (e.g., "EasySURF50+5G+FunALIW+")
□ phone_number: should be the MOBILE NUMBER receiving the load
□ amount: should be the LOAD AMOUNT (NOT including convenience fee)
□ fee: should be the "Convenience Fee" value
□ total_amount: should include load amount + convenience fee

MOBILE LOAD EXTRACTION GUIDE:
For mobile load receipts, follow this structure:

1. TOP SECTION (annotated RED area):
   - Look for the LOAD/PROMO NAME
   - Examples: "EasySURF50+5G+FunALIW+", "GIGA50", "AllNet99"
   - This is NOT a person's name - it's a product/promo name
   - Extract EXACTLY as displayed
   - This becomes the recipient_name field

2. BELOW TOP (annotated BLUE area):
   - Look for the MOBILE NUMBER
   - Format: +63 XXX XXX XXXX
   - This is the number receiving the load
   - Extract with country code if present

3. MIDDLE SECTION (annotated VIOLET area):
   - Look for "Amount" label
   - This is the LOAD AMOUNT ONLY (exclude convenience fee)
   - Extract numeric value only (e.g., 50.00)
   - Look for "Convenience Fee" - this is separate
   - Look for "Total" - this includes amount + fee

4. BOTTOM SECTION (annotated ORANGE/PINK areas):
   - ORANGE: Look for "Date" label (e.g., "Dec 08, 2025 4:57 PM")
   - PINK: Look for "Reference No." label (e.g., "918160648")
   - Extract both exactly as shown
   - Convert date to YYYY-MM-DD format

5. SOURCE:
   - Usually "GCash" for load receipts
   - May say "Paid via GCash"

⚠️ CRITICAL: If you see "Bank Transfer Complete", you MUST use the bank_transfer format!
⚠️ CRITICAL: If you see a PROMO NAME at top (not a person's name), you MUST use the load format!

═══════════════════════════════════════════════════════════════

Return ONLY valid JSON format.
''';

    try {
      final response = await generateContentWithImage(prompt, imageBytes,
          mimeType: mimeType);
      if (response == null) return null;

      // Try to parse JSON from response
      try {
        // Remove markdown code blocks if present
        String cleanedResponse = response.trim();
        if (cleanedResponse.startsWith('```json')) {
          cleanedResponse = cleanedResponse.substring(7);
        } else if (cleanedResponse.startsWith('```')) {
          cleanedResponse = cleanedResponse.substring(3);
        }
        if (cleanedResponse.endsWith('```')) {
          cleanedResponse =
              cleanedResponse.substring(0, cleanedResponse.length - 3);
        }
        cleanedResponse = cleanedResponse.trim();

        print('=== GEMINI RAW RESPONSE ===');
        print(response);
        print('=== CLEANED RESPONSE ===');
        print(cleanedResponse);

        // Parse JSON
        final data =
            Map<String, dynamic>.from(_parseJsonString(cleanedResponse));

        print('=== PARSED DATA ===');
        print(data);

        // Check transaction type
        final transactionType =
            data['transaction_type']?.toString() ?? 'money_transfer';

        // Validate based on transaction type
        bool isValid = false;

        if (transactionType == 'bank_transfer') {
          // Bank transfer validation
          final hasBankName = data['bank_name'] != null &&
              data['bank_name'] != 'Not found' &&
              data['bank_name']?.toString().isNotEmpty == true;
          final hasAccountNumber = data['account_number'] != null &&
              data['account_number'] != 'Not found' &&
              data['account_number']?.toString().isNotEmpty == true;
          final hasAccountName = data['account_name'] != null &&
              data['account_name'] != 'Not found' &&
              data['account_name']?.toString().isNotEmpty == true;
          final hasAmount = data['amount'] != null &&
              data['amount'] != 'Not found' &&
              data['amount']?.toString() != '0' &&
              data['amount']?.toString() != '0.0' &&
              data['amount']?.toString().isNotEmpty == true;

          print('=== BANK TRANSFER VALIDATION ===');
          print('hasBankName: $hasBankName');
          print('hasAccountNumber: $hasAccountNumber');
          print('hasAccountName: $hasAccountName');
          print('hasAmount: $hasAmount');

          isValid =
              hasBankName || hasAccountNumber || hasAccountName || hasAmount;
        } else {
          // Money transfer validation (original)
          final hasRecipient = data['recipient_name'] != null &&
              data['recipient_name'] != 'Not found' &&
              data['recipient_name']?.toString().isNotEmpty == true;
          final hasPhone = data['phone_number'] != null &&
              data['phone_number'] != 'Not found' &&
              data['phone_number']?.toString().isNotEmpty == true;
          final hasAmount = data['amount'] != null &&
              data['amount'] != 'Not found' &&
              data['amount']?.toString() != '0' &&
              data['amount']?.toString() != '0.0' &&
              data['amount']?.toString().isNotEmpty == true;

          print('=== MONEY TRANSFER VALIDATION ===');
          print('hasRecipient: $hasRecipient');
          print('hasPhone: $hasPhone');
          print('hasAmount: $hasAmount');

          isValid = hasRecipient || hasPhone || hasAmount;
        }

        // Return data if validation passes
        if (isValid) {
          print('✓ Validation passed - returning data');
          return data;
        } else {
          print('✗ Validation failed - no fields found');
          return {
            'raw_response': response,
            'parsed_data': data,
            'error': 'Could not extract required fields from image'
          };
        }
      } catch (e) {
        print('Error parsing JSON response: $e');
        // Return raw response if JSON parsing fails
        return {
          'raw_response': response,
          'error': 'Failed to parse structured data'
        };
      }
    } catch (e) {
      print('Error analyzing receipt image: $e');
      return null;
    }
  }

  /// Helper method to parse JSON string
  Map<String, dynamic> _parseJsonString(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'error': 'Invalid JSON structure'};
    } catch (e) {
      print('JSON parse error: $e');
      return {'error': 'Failed to parse JSON', 'raw': jsonStr};
    }
  }

  /// Extract specific information from any document/image
  Future<String?> extractCustomInformation(
    List<int> imageBytes,
    List<String> fieldsToExtract, {
    String mimeType = 'image/jpeg',
    String? additionalInstructions,
  }) async {
    final fieldsList = fieldsToExtract.map((field) => '- $field').join('\n');

    final prompt = '''
You are a precise data extraction assistant. Analyze this image and extract ONLY the following information:

$fieldsList

CRITICAL RULES:
1. Extract ONLY information that is CLEARLY VISIBLE in the image
2. If a field is not found or unclear, explicitly state "Not found"
3. Do not invent, assume, or provide example data
4. Be extremely accurate with numbers, dates, and text
5. Maintain the exact formatting as it appears in the image

${additionalInstructions ?? ''}

Provide the extracted information in a clear, structured format.
''';

    return await generateContentWithImage(prompt, imageBytes,
        mimeType: mimeType);
  }

  /// Debug method - Get full text extraction to see what AI can read
  Future<String?> debugExtractAllText(
    List<int> imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    final prompt = '''
ANALYZE this money transfer image and show me EVERYTHING you can read.

This could be:
- Physical receipt photo
- Phone screenshot (GCash, Maya, Bank app)
- Digital document
- PDF screenshot

Extract and list ALL text you can see, organized by sections:

FORMAT YOUR RESPONSE LIKE THIS:

=== IMAGE TYPE ===
[Is this a photo of paper receipt or a phone screenshot?]

=== TOP SECTION ===
[All text at the top 1/3 of image]

=== RECIPIENT/NAME SECTION ===
[Any text that looks like a person's name, including labels]

=== PHONE/CONTACT SECTION ===
[Any phone numbers or contact information]

=== AMOUNT SECTION ===
[Any amounts, prices, or currency]

=== REFERENCE/ID SECTION ===
[Any reference numbers, transaction IDs]

=== DATE/TIME SECTION ===
[Any dates or timestamps]

=== OTHER TEXT ===
[Everything else]

IMPORTANT:
- Show EXACT text including symbols (*, •, ·, ₱, +, etc.)
- Don't skip anything
- Include UI elements if it's a screenshot
- Show me masking characters if present
- Note which section each text appears in
''';

    return await generateContentWithImage(prompt, imageBytes,
        mimeType: mimeType);
  }

  /// Extract ONLY the sender/recipient name from money transfer receipt
  /// This method focuses specifically on finding names in ANY format
  Future<String?> extractRecipientName(
    List<int> imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    final prompt = '''
CRITICAL TASK: Find the SENDER/RECIPIENT NAME from this money transfer image.

═══════════════════════════════════════════════════════════════
🔍 STEP 1: READ THE IMAGE FIRST
═══════════════════════════════════════════════════════════════

Before looking for the name specifically:
1. Scan the ENTIRE image top to bottom
2. Read ALL text you can see
3. Identify where labels are: "To:", "Send to:", "Recipient:", etc.
4. Note where names appear (usually near top or after "To:" label)
5. Read through any screen glare or moiré patterns

⚠️ This ensures you actually SEE the name before trying to extract it!

═══════════════════════════════════════════════════════════════
🔍 STEP 2: IDENTIFY IMAGE TYPE
═══════════════════════════════════════════════════════════════

FIRST - Determine the IMAGE TYPE:
1. PAPER RECEIPT PHOTO: Camera picture of printed paper (may be blurry, small text)
2. PURE SCREENSHOT: Digital capture from phone/computer (clear, no device visible)
3. SCREEN PHOTO: Camera photo OF another device's screen (device frame visible, may have glare)

This could be from:
- Physical paper receipt (camera photo)
- GCash/Maya/Bank app (screenshot OR screen photo)
- Transaction confirmation screen
- Email receipt display
- Another phone showing the receipt

⚠️ IF THIS IS A PHOTO OF ANOTHER SCREEN:
- You'll see the physical device (phone frame, screen edges)
- Screen may have GLARE or REFLECTIONS
- Text may show MOIRÉ PATTERN (wavy lines)
- Colors may be BRIGHT or WASHED OUT
- BUT: The name IS THERE on the screen display
- Focus on reading the APP CONTENT, ignore device frame
- Read THROUGH the visual effects

NAME FORMATS BY IMAGE TYPE:

PAPER RECEIPT PHOTO:
- Pattern: XX****X X. or XX*****X X. (2 letters + asterisks/dots + 1 letter + space + initial)
- Example: "CL*****M M.", "MA****N M.", "JO****A D.", "AN***A L."
- The asterisks (*) or dots (•) are PRINTED on paper - they're real characters
- Usually after "To:" label
- Text is SMALL but READABLE
- Read character by character

SCREEN PHOTO (camera photo of device):
- Could show FULL NAME: "MARIA CLARA CRUZ" (if app displays full name)
- Or MASKED: "CL*****M M.", "MA****N M." (if app has privacy masking)
- Name is on the SCREEN DISPLAY
- May have screen glare over it - READ THROUGH the glare
- Letters may look PIXELATED - shapes are still recognizable
- Usually in TOP of app interface
- Often LARGE or BOLD text
- Near avatar/profile icon

PURE SCREENSHOT (digital):
1. MASKED: "CL*****M M.", "MA****N M.", "JO••••A D." (privacy setting - GCash format)
2. FULL NAME: "MARIA CLARA CRUZ", "JUAN DELA CRUZ" (most common)
3. PARTIAL: "Maria C.", "Juan D."
4. ABBREVIATED: "M. CRUZ", "J. SANTOS"

WHERE TO LOOK - SPECIFIC INSTRUCTIONS:

FOR CAMERA PHOTOS (physical receipts):
� STEP 1: Find the "To:" label
   - Usually in TOP section (first 1/3) of receipt
   - Look for the word "To:" or "Send to:"
   
🔍 STEP 2: Read the text RIGHT AFTER "To:"
   - The name is on the SAME line or NEXT line after "To:"
   - Pattern: XX****X X. or XX*****X X. (2 letters + asterisks/dots + 1 letter + space + initial)
   - Examples: "CL*****M M.", "MA****N M.", "JO****A D."
   - This is usually the FIRST or SECOND line after service name
   
� STEP 3: Verify it's a GCash name pattern
   - Must START with exactly 2 capital letters
   - Must have asterisks (*) or dots (•) in the middle
   - Must have exactly 1 capital letter before the space
   - Must end with space + capital letter + dot (" M." or " D." or " C.")
   - Total length usually 10-14 characters
   
� STEP 4: Read character by character
   - Don't guess - READ each character
   - Count the asterisks/dots (usually 4-7)
   - Include the space before the initial
   - Include the dot after the initial

FOR SCREENSHOTS (digital):
📍 After labels:
   - "To:", "Send to:", "Recipient:", "Receiver:", "Beneficiary:"
   - "Account Name:", "Payee:", "Send Money to:", "Transfer to:"

📍 In card/box layouts:
   - Name in a card with border
   - Name under avatar/profile icon
   - Name in prominent display

📍 Position hints:
   - TOP section of screen
   - Next to or above phone number
   - In BOLD or LARGER text

READING TIPS:

FOR PAPER RECEIPTS:
⚠️ TEXT MAY BE SMALL - But it's readable if you look carefully

FOR SCREEN PHOTOS (Critical!):
⚠️ DON'T BE FOOLED BY VISUAL EFFECTS:
- Screen glare = Reflection on glass, text is behind it
- Moiré pattern = Optical illusion from camera+screen interaction
- Pixelation = Screen pixels visible, but letters recognizable
- Brightness = May wash out colors, but text outline visible

⚠️ SYSTEMATIC READING FOR SCREENS:
1. Identify the app (GCash green, Maya purple, Bank logos)
2. Locate the main content area (center of screen)
3. Find the name section (usually top of transaction)
4. Read letter by letter, even through artifacts
5. Verify it's a name (has letters, may have dots/asterisks)
⚠️ MAY BE SLIGHTLY BLURRY - But pattern is still recognizable
⚠️ FOCUS ON THE RECEIPT - Ignore background/table/hands
⚠️ READ TOP TO BOTTOM - Name is usually in first 3-5 lines

WHAT TO EXTRACT - CHARACTER BY CHARACTER:
✓ If PHOTO: Extract EXACTLY including every asterisk
   Example input: "To: CL*****M M."
   Extract: "CL*****M M."
   
✓ If SCREENSHOT: Extract the full name or masked name as shown
   Example input: "Send to: Maria Cruz"
   Extract: "Maria Cruz"

✓ Keep the EXACT format for GCash masked names:
   - Start with 2 capital letters (CL, MA, JO, etc.)
   - Every asterisk (*) or dot (•) in the middle
   - Exactly 1 capital letter before space
   - Every space
   - Every dot (.)
   - Exact capitalization
   - The middle initial at the end (M., D., C., etc.)

CORRECT EXAMPLES:
✓ "CL*****M M." ← Two letters, 5 asterisks, letter, space, M dot (GCash format)
✓ "MA****N M." ← Two letters, 4 asterisks, letter, space, M dot
✓ "JO****A D." ← Two letters, 4 asterisks, letter, space, D dot
✓ "AN***A M." ← Two letters, 3 asterisks, letter, space, M dot
✓ "MARIA CRUZ" ← Full name from screenshot
✓ "Maria C." ← Short form from screenshot

WRONG EXAMPLES (Don't do this):
✗ "MARIAN M" ← Missing asterisks (if photo)
✗ "MA****N" ← Missing the initial
✗ "Ma****n m." ← Wrong capitalization
✗ "MA ****N M." ← Extra space
✗ Just returning "M." or "MARIAN" ← Incomplete

DO NOT:
✗ Remove masking characters
✗ Change capitalization
✗ Add words that aren't there
✗ Return phone numbers
✗ Return amounts
✗ Return labels like "To:" or "Recipient:"

CONTEXT CLUES:
- If you see multiple names, choose the one that looks like a RECIPIENT
- Skip "Sender:" names (you want the TO/RECIPIENT)
- Ignore app names (GCash, Maya, etc.)
- Ignore bank names
- Focus on PERSON names

SPECIAL INSTRUCTIONS FOR DIFFICULT PHOTOS:

PAPER RECEIPTS:
1. If text is small: Zoom in mentally and read carefully
2. If slightly blurry: The pattern XX****X X. or XX*****X X. (like CL*****M M.) is still recognizable
3. If angled: Text is still readable even at an angle
4. If shadowed: Focus on the white paper area where text is clearest
5. If folded: Look at the visible flat sections

SCREEN PHOTOS (device-to-device):
1. If screen has GLARE:
   - Look at the darker/clearer portions first
   - Glare often on top half, name may be visible in less bright area
   - Read what you CAN see, piece it together
2. If MOIRÉ pattern visible:
   - Ignore the wavy lines - they're not real
   - Focus on letter shapes
   - Text is underneath the pattern effect
3. If text is PIXELATED:
   - Look at overall letter shapes: M has peaks, A has triangle
   - Numbers have distinct shapes: 0 is round, 1 is line
   - Don't need perfect clarity - recognition is enough
4. If colors WASHED OUT:
   - Focus on contrast between text and background
   - Text edges are still visible
   - Content matters, not color accuracy
5. If screen is TILTED/ANGLED:
   - Text is readable at angles
   - App layout still recognizable
   - Look at screen content, not device angle

VERIFICATION CHECKLIST:
Before returning the name, verify:

FOR PAPER RECEIPTS:
□ Does it START with 2 capital letters? (Must be YES for GCash)
□ Does it have asterisks in the middle? (Must be YES)
□ Does it end with 1 capital letter + space + initial + dot? (Must be YES)
□ Is it 10-15 characters total? (Should be YES)
□ Did you read it character by character? (Must be YES)
□ Does it match XX****X X. or XX*****X X. pattern? (YES for GCash paper)

FOR SCREEN PHOTOS:
□ Did I look past the screen glare? (Must be YES)
□ Did I ignore moiré patterns? (Must be YES)
□ Did I focus on app content, not device frame? (Must be YES)
□ Is this a person's name (not app/bank name)? (Must be YES)
□ Could be full name OR masked (either is valid)

FOR ALL TYPES:
□ Is it a person's name? (Must be YES)
□ Did I return EXACT format from image? (Must be YES)

FINAL INSTRUCTIONS:
The name IS in this image. You MUST find it.

FOR PAPER RECEIPTS:
- Look for "To:" label
- Read the XX****X X. or XX*****X X. pattern after it (like CL*****M M.)
- Read character by character: 2 letters + asterisks/dots + 1 letter + space + initial

FOR SCREEN PHOTOS (very common issue!):
- Don't give up because of glare/moiré/pixels
- The app HAS the name displayed - it's there
- Read systematically through the screen content
- Focus on TOP of app where names usually are
- Look past all visual artifacts - they don't erase text

FOR PURE SCREENSHOTS:
- Look for recipient/beneficiary fields
- Could be full name or masked

⚠️ SCREEN PHOTOS ARE THE MOST COMMON FAILURE CASE
The problem is NOT that the name isn't there.
The problem is reading past screen glare and moiré patterns.
The text EXISTS on the screen - you must READ it.

═══════════════════════════════════════════════════════════════
⚠️ CRITICAL: YOUR PROCESS MUST BE
═══════════════════════════════════════════════════════════════

STEP 1: READ the entire image (what text do I see?)
STEP 2: LOCATE the "To:" or "Recipient:" label (where is it?)
STEP 3: READ the text right after that label (what does it say?)
STEP 4: EXTRACT it exactly as shown (character by character)

Don't jump to step 4 without doing steps 1-3 first!
You must READ before you can EXTRACT.

═══════════════════════════════════════════════════════════════

Return ONLY the name text, nothing else. No labels, no explanations.
If absolutely no name found after thorough search, return "Not found".
''';

    final response =
        await generateContentWithImage(prompt, imageBytes, mimeType: mimeType);
    return response?.trim();
  }

  /// Analyze any document with custom requirements
  Future<String?> analyzeDocument(
    List<int> imageBytes,
    String analysisRequirements, {
    String mimeType = 'image/jpeg',
  }) async {
    final prompt = '''
Analyze this document/image based on the following requirements:

$analysisRequirements

IMPORTANT:
- Only extract information that is actually visible in the image
- Be precise and accurate
- If information is not available, clearly state it
- Do not make assumptions or provide placeholder data
''';

    return await generateContentWithImage(prompt, imageBytes,
        mimeType: mimeType);
  }

  /// Process receipt image and return ReceiptModel (compatible with existing OCR flow)
  /// Uses SMART EXTRACTION with retry and multiple strategies
  Future<ReceiptModel?> processReceipt(
    File imageFile,
    List<dynamic> feeRanges,
  ) async {
    try {
      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();

      print('🔍 Starting SMART receipt processing with Gemini AI...');

      // STRATEGY 1: Main extraction attempt
      Map<String, dynamic>? geminiResponse =
          await analyzeReceiptImage(imageBytes);

      // STRATEGY 2: If main extraction failed, try with debug extraction first
      if (geminiResponse == null || geminiResponse.containsKey('error')) {
        print('⚠️ Main extraction failed, trying debug extraction...');
        final debugText = await debugExtractAllText(imageBytes);
        if (debugText != null && debugText.isNotEmpty) {
          print('📝 Debug extraction got text, retrying analysis...');
          // Retry with a simpler prompt for difficult images
          geminiResponse = await _analyzeReceiptSimple(imageBytes);
        }
      }

      if (geminiResponse == null || geminiResponse.containsKey('error')) {
        print('❌ All extraction strategies failed');
        return null;
      }

      // Convert to ReceiptModel format
      var receiptData = convertToReceiptModel(geminiResponse, feeRanges);

      if (receiptData == null) {
        print('⚠️ Conversion failed, trying lenient extraction...');
        receiptData = _extractLenient(geminiResponse, feeRanges);
      }

      if (receiptData == null) {
        return null;
      }

      // STRATEGY 3: If recipient name is missing, try dedicated name extraction
      if (receiptData['recipientName'] == null ||
          receiptData['recipientName'] == 'Not found' ||
          receiptData['recipientName'] == 'Unknown' ||
          receiptData['recipientName'].toString().trim().isEmpty) {
        print(
            '⚠️ Name missing in main extraction, trying focused name extraction...');

        final extractedName = await extractRecipientName(imageBytes);
        if (extractedName != null &&
            extractedName != 'Not found' &&
            extractedName.trim().isNotEmpty) {
          receiptData['recipientName'] = extractedName;
          print('✅ Successfully extracted name: $extractedName');
        } else {
          print('⚠️ Focused extraction also failed, using "Unknown"');
          receiptData['recipientName'] = 'Unknown';
        }
      }

      // STRATEGY 4: If phone is missing but we have amount, still allow it
      if ((receiptData['phoneNumber'] == null ||
              receiptData['phoneNumber'].toString().isEmpty) &&
          receiptData['amount'] != null &&
          receiptData['amount'] > 0) {
        print('⚠️ Phone missing but amount found - allowing partial data');
        receiptData['phoneNumber'] = '';
      }

      // Create and return appropriate model based on transaction type
      final transactionType =
          receiptData['transactionType'] ?? 'money_transfer';

      if (transactionType == 'bank_transfer') {
        // For bank transfers, store as money transfer with special fields
        // Use account name as recipient name for compatibility
        return ReceiptModel(
          recipientName: receiptData['accountName'] ??
              receiptData['recipientName'] ??
              'Unknown',
          phoneNumber: receiptData['receiptEmail'] ??
              receiptData['bankName'] ??
              '', // Store email or bank name
          amount: receiptData['amount'] ?? 0.0,
          refNumber: receiptData['refNumber'] ?? '',
          date: DateTime.fromMillisecondsSinceEpoch(
              receiptData['date'] ?? DateTime.now().millisecondsSinceEpoch),
          fee: receiptData['bankFee'] ??
              receiptData['fee'] ??
              0.0, // Use bankFee for fee field
          source: receiptData['source'] ?? 'GCash',
          transactionType: 'bank_transfer',
        );
      } else {
        // Regular money transfer
        return ReceiptModel(
          recipientName: receiptData['recipientName'] ?? 'Unknown',
          phoneNumber: receiptData['phoneNumber'] ?? '',
          amount: receiptData['amount'] ?? 0.0,
          refNumber: receiptData['refNumber'] ?? '',
          date: DateTime.fromMillisecondsSinceEpoch(
              receiptData['date'] ?? DateTime.now().millisecondsSinceEpoch),
          fee: receiptData['fee'] ?? 0.0,
          source: receiptData['source'] ?? 'GCash',
          transactionType: 'money_transfer',
        );
      }
    } catch (e) {
      print('Error processing receipt with Gemini: $e');
      return null;
    }
  }

  /// Simpler analysis for difficult images
  Future<Map<String, dynamic>?> _analyzeReceiptSimple(
      List<int> imageBytes) async {
    final prompt = '''
SIMPLE EXTRACTION - Read this receipt image and extract:

1. NAME: The recipient/receiver name (could be masked like "MA****N M." or full name)
2. PHONE: Phone number starting with +63, 09, or 63
3. AMOUNT: The main money amount being transferred (NOT the fee, NOT the total)
4. REFERENCE: Any long number (10+ digits) that looks like a transaction ID
5. DATE: Transaction date
6. SOURCE: GCash, Maya, BPI, BDO, or other service name

Return JSON format:
{
  "recipient_name": "name here or Not found",
  "phone_number": "phone here or Not found",
  "amount": "number only like 1000.00",
  "reference_number": "ref number or Not found",
  "date": "YYYY-MM-DD",
  "source": "GCash or Maya etc"
}

Be flexible - extract whatever you can see clearly. If something is unclear, still try your best guess.
''';

    try {
      final response = await generateContentWithImage(prompt, imageBytes);
      if (response == null) return null;

      String cleanedResponse = response.trim();
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      } else if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse =
            cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      cleanedResponse = cleanedResponse.trim();

      return Map<String, dynamic>.from(_parseJsonString(cleanedResponse));
    } catch (e) {
      print('Simple extraction error: $e');
      return null;
    }
  }

  /// Lenient extraction that accepts partial data
  Map<String, dynamic>? _extractLenient(
    Map<String, dynamic> geminiResponse,
    List<dynamic> feeRanges,
  ) {
    try {
      // Extract whatever we can find
      final recipientName = geminiResponse['recipient_name']?.toString() ??
          geminiResponse['account_name']?.toString() ??
          '';
      final phoneNumber = geminiResponse['phone_number']?.toString() ?? '';
      final amountStr = geminiResponse['amount']?.toString() ?? '0';
      final refNumber = geminiResponse['reference_number']?.toString() ?? '';
      final source = geminiResponse['source']?.toString() ?? 'GCash';

      final amount = double.tryParse(
              amountStr.replaceAll(',', '').replaceAll('₱', '').trim()) ??
          0.0;

      // Very lenient - just need SOMETHING
      if (amount > 0 || recipientName.isNotEmpty || phoneNumber.isNotEmpty) {
        print('✅ Lenient extraction found some data');
        return {
          'transactionType': 'money_transfer',
          'recipientName':
              recipientName.isNotEmpty && recipientName != 'Not found'
                  ? recipientName
                  : 'Unknown',
          'phoneNumber': phoneNumber != 'Not found'
              ? _normalizePhoneNumber(phoneNumber)
              : '',
          'amount': amount,
          'fee': 0.0,
          'refNumber': refNumber != 'Not found' ? refNumber : '',
          'date': DateTime.now().millisecondsSinceEpoch,
          'source': source != 'Not found' ? source : 'GCash',
        };
      }

      return null;
    } catch (e) {
      print('Lenient extraction error: $e');
      return null;
    }
  }

  /// Convert Gemini response to ReceiptModel format (handles both money transfer and bank transfer)
  Map<String, dynamic>? convertToReceiptModel(
    Map<String, dynamic> geminiResponse,
    List<dynamic> feeRanges,
  ) {
    try {
      final transactionType =
          geminiResponse['transaction_type']?.toString() ?? 'money_transfer';

      if (transactionType == 'bank_transfer') {
        return _convertBankTransfer(geminiResponse, feeRanges);
      } else {
        return _convertMoneyTransfer(geminiResponse, feeRanges);
      }
    } catch (e) {
      print('Error converting to ReceiptModel: $e');
      return null;
    }
  }

  /// Convert bank transfer response
  Map<String, dynamic>? _convertBankTransfer(
    Map<String, dynamic> geminiResponse,
    List<dynamic> feeRanges,
  ) {
    try {
      // Extract bank transfer specific values
      final bankName = geminiResponse['bank_name']?.toString() ?? '';
      final accountNumber = geminiResponse['account_number']?.toString() ?? '';
      final accountName = geminiResponse['account_name']?.toString() ?? '';
      final receiptEmail = geminiResponse['receipt_email']?.toString() ?? '';
      final amountStr = geminiResponse['amount']?.toString() ?? '0';
      final bankFeeStr = geminiResponse['bank_fee']?.toString() ?? '0';
      final refNumber = geminiResponse['reference_number']?.toString() ?? '';
      final dateStr = geminiResponse['date']?.toString() ?? '';
      final timeStr = geminiResponse['time']?.toString() ?? '';
      final source = geminiResponse['source']?.toString() ?? 'GCash';

      // Parse amount
      final amount = double.tryParse(
              amountStr.replaceAll(',', '').replaceAll('₱', '').trim()) ??
          0.0;

      // Parse bank fee
      double bankFee = double.tryParse(
              bankFeeStr.replaceAll(',', '').replaceAll('₱', '').trim()) ??
          0.0;

      // Parse date
      DateTime date = DateTime.now();
      if (dateStr != 'Not found' && dateStr.isNotEmpty) {
        date = _parseDate(dateStr, timeStr);
      }

      // Validate required fields for bank transfer
      print('=== BANK TRANSFER FIELD VALIDATION ===');
      print('Bank Name: "$bankName"');
      print('Account Number: "$accountNumber"');
      print('Account Name: "$accountName"');
      print('Amount: $amount');

      final hasValidBank =
          bankName != 'Not found' && bankName.trim().isNotEmpty;
      final hasValidAccount =
          accountNumber != 'Not found' && accountNumber.trim().isNotEmpty;
      final hasValidAccountName =
          accountName != 'Not found' && accountName.trim().isNotEmpty;
      final hasValidAmount = amount > 0.0;

      print('hasValidBank: $hasValidBank');
      print('hasValidAccount: $hasValidAccount');
      print('hasValidAccountName: $hasValidAccountName');
      print('hasValidAmount: $hasValidAmount');

      // Require at least account name OR (bank + amount)
      if (!hasValidAccountName && !(hasValidBank && hasValidAmount)) {
        print(
            '❌ Validation failed: Need at least account name OR (bank + amount)');
        return null;
      }

      print('✅ Bank Transfer Validation passed');

      return {
        'transactionType': 'bank_transfer',
        'bankName': hasValidBank ? bankName : 'Unknown',
        'accountNumber': hasValidAccount ? accountNumber : '',
        'accountName': hasValidAccountName ? accountName : 'Unknown',
        'receiptEmail': receiptEmail == 'Not found' ? '' : receiptEmail,
        'amount': amount,
        'bankFee': bankFee,
        'refNumber': refNumber == 'Not found' ? '' : refNumber,
        'date': date.millisecondsSinceEpoch,
        'source': source == 'Not found' ? 'GCash' : source,
        'totalAmount': amount + bankFee,
      };
    } catch (e) {
      print('Error converting bank transfer: $e');
      return null;
    }
  }

  /// Convert money transfer response
  Map<String, dynamic>? _convertMoneyTransfer(
    Map<String, dynamic> geminiResponse,
    List<dynamic> feeRanges,
  ) {
    try {
      // Extract values
      final recipientName = geminiResponse['recipient_name']?.toString() ?? '';
      final phoneNumber = geminiResponse['phone_number']?.toString() ?? '';
      final amountStr = geminiResponse['amount']?.toString() ?? '0';
      final feeStr = geminiResponse['fee']?.toString() ?? '0';
      final refNumber = geminiResponse['reference_number']?.toString() ?? '';
      final dateStr = geminiResponse['date']?.toString() ?? '';
      final timeStr = geminiResponse['time']?.toString() ?? '';
      final source = geminiResponse['source']?.toString() ?? 'GCash';

      // Parse amount
      final amount = double.tryParse(
              amountStr.replaceAll(',', '').replaceAll('₱', '').trim()) ??
          0.0;

      // Parse or calculate fee
      double fee = double.tryParse(
              feeStr.replaceAll(',', '').replaceAll('₱', '').trim()) ??
          0.0;

      // If fee is "Not found", calculate it based on amount and fee ranges
      if (fee == 0.0 && feeRanges.isNotEmpty) {
        fee = _calculateFeeFromRanges(amount, feeRanges);
      }

      // Parse date
      DateTime date = DateTime.now();
      if (dateStr != 'Not found' && dateStr.isNotEmpty) {
        date = _parseDate(dateStr, timeStr);
      }

      // Validate required fields - more lenient now
      print('=== MONEY TRANSFER FIELD VALIDATION ===');
      print('Recipient Name: "$recipientName"');
      print('Phone Number: "$phoneNumber"');
      print('Amount: $amount');

      final hasValidName =
          recipientName != 'Not found' && recipientName.trim().isNotEmpty;
      final hasValidPhone =
          phoneNumber != 'Not found' && phoneNumber.trim().isNotEmpty;
      final hasValidAmount = amount > 0.0;

      print('hasValidName: $hasValidName');
      print('hasValidPhone: $hasValidPhone');
      print('hasValidAmount: $hasValidAmount');

      // Require at least name OR (phone + amount)
      if (!hasValidName && !(hasValidPhone && hasValidAmount)) {
        print('❌ Validation failed: Need at least name OR (phone + amount)');
        print('Gemini Response Data:');
        print(geminiResponse);
        return null;
      }

      print('✅ Money Transfer Validation passed');

      return {
        'transactionType': 'money_transfer',
        'recipientName': hasValidName ? recipientName : 'Unknown',
        'phoneNumber': hasValidPhone ? _normalizePhoneNumber(phoneNumber) : '',
        'amount': amount,
        'fee': fee,
        'refNumber': refNumber == 'Not found' ? '' : refNumber,
        'date': date.millisecondsSinceEpoch,
        'source': source == 'Not found' ? 'GCash' : source,
        'totalAmount': amount + fee,
      };
    } catch (e) {
      print('Error converting money transfer: $e');
      return null;
    }
  }

  /// Process receipt and return complete data map (includes all bank transfer fields)
  Future<Map<String, dynamic>?> processReceiptAsMap(
    File imageFile,
    List<dynamic> feeRanges,
  ) async {
    try {
      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();

      // Analyze with Gemini AI
      final geminiResponse = await analyzeReceiptImage(imageBytes);

      if (geminiResponse == null || geminiResponse.containsKey('error')) {
        return null;
      }

      // Convert to receipt data format
      var receiptData = convertToReceiptModel(geminiResponse, feeRanges);

      return receiptData;
    } catch (e) {
      print('Error processing receipt as map: $e');
      return null;
    }
  }

  /// Calculate fee based on amount and fee ranges
  double _calculateFeeFromRanges(double amount, List<dynamic> feeRanges) {
    for (var range in feeRanges) {
      if (range is Map) {
        final minAmount = (range['minAmount'] ?? 0).toDouble();
        final maxAmount = (range['maxAmount'] ?? double.infinity).toDouble();
        final fee = (range['fee'] ?? 0).toDouble();

        if (amount >= minAmount && amount <= maxAmount) {
          return fee;
        }
      }
    }
    return 0.0;
  }

  /// Normalize phone number to +63 format
  String _normalizePhoneNumber(String phone) {
    // Remove all spaces and special characters except +
    String normalized = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Ensure it starts with +63
    if (normalized.startsWith('63') && !normalized.startsWith('+')) {
      normalized = '+$normalized';
    } else if (normalized.startsWith('0')) {
      normalized = '+63${normalized.substring(1)}';
    } else if (!normalized.startsWith('+63')) {
      // If it's just the 10-digit number
      if (normalized.length == 10) {
        normalized = '+63$normalized';
      }
    }

    return normalized;
  }

  /// Parse date from various formats including relative dates
  DateTime _parseDate(String dateStr, String timeStr) {
    try {
      // Handle relative dates from screenshots
      final lowerDate = dateStr.toLowerCase();
      if (lowerDate.contains('today') ||
          lowerDate.contains('just now') ||
          lowerDate.contains('now') ||
          lowerDate.isEmpty ||
          lowerDate == 'not found') {
        return DateTime.now();
      }

      if (lowerDate.contains('yesterday')) {
        return DateTime.now().subtract(const Duration(days: 1));
      }

      // If already in YYYY-MM-DD format
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
        final dateParts = dateStr.split('-');
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);

        // Parse time if available
        int hour = 0, minute = 0;
        if (timeStr != 'Not found' && timeStr.isNotEmpty) {
          final timeParts = timeStr.split(':');
          if (timeParts.length >= 2) {
            hour = int.tryParse(timeParts[0]) ?? 0;
            final minutePart = timeParts[1].split(' ')[0];
            minute = int.tryParse(minutePart) ?? 0;

            // Handle AM/PM
            if (timeStr.toUpperCase().contains('PM') && hour != 12) {
              hour += 12;
            } else if (timeStr.toUpperCase().contains('AM') && hour == 12) {
              hour = 0;
            }
          }
        }

        return DateTime(year, month, day, hour, minute);
      }

      // Try DD/MM/YYYY format
      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(dateStr)) {
        final parts = dateStr.split('/');
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }

      // Try MM/DD/YYYY format
      if (RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$').hasMatch(dateStr)) {
        final parts = dateStr.split('/');
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }

    return DateTime.now();
  }
}
