# CASH App - User Guide

## Table of Contents
1. [Getting Started](#getting-started)
2. [Dashboard Overview](#dashboard-overview)
3. [Scanning Receipts](#scanning-receipts)
4. [AI Chat Assistant](#ai-chat-assistant)
5. [Manual Transaction Entry](#manual-transaction-entry)
6. [Transaction History](#transaction-history)
7. [Profile & Settings](#profile--settings)
8. [Tips & Best Practices](#tips--best-practices)

---

## Getting Started

### First Time Setup
1. **Sign Up / Login**
   - Open the app
   - Sign in with your Google account
   - Grant necessary permissions (camera, storage)

2. **Dashboard Access**
   - After logging in, you'll see the main dashboard
   - This is your transaction hub

---

## Dashboard Overview

### What You'll See:
- **Total Cash In** - All money you've received
- **Total Cash Out** - All money you've sent
- **Total Fees** - All transaction fees paid
- **Available Funds** - Your current balance (Cash In - Cash Out, excluding fees)

### Quick Actions:
- **📸 Scan Receipt** - Capture and scan transaction receipts
- **💬 AI Chat** - Get help from AI assistant
- **➕ Add Transaction** - Manually add a transaction
- **📊 Transaction History** - View all your transactions

---

## Scanning Receipts

### How to Scan:
1. **Tap the "Scan Receipt" button** on the dashboard
2. **Take a photo** of your receipt
   - Make sure the receipt is clear and well-lit
   - Include all important details (amount, reference number, date)
   - Avoid shadows and glare

3. **AI Processing**
   - The app will automatically extract:
     - Transaction amount
     - Reference number
     - Date and time
     - Recipient name
     - Phone number
     - Bank fees
     - Total amount

4. **Review & Edit**
   - Check the extracted information
   - Edit any incorrect details
   - The app will warn you if:
     - Reference number is missing
     - Reference number already exists (duplicate)

5. **Save**
   - Tap "Save Transaction" to add it to your records
   - Transaction type is automatically detected (Cash In/Out)

### Supported Receipt Types:
- ✅ GCash receipts
- ✅ Bank transfer receipts (BDO, BPI, UnionBank, etc.)
- ✅ PayMaya receipts
- ✅ Palawan Express receipts
- ✅ Money transfer receipts

### Tips for Better Scanning:
- Use good lighting
- Keep the camera steady
- Capture the entire receipt
- Avoid wrinkled or damaged receipts
- Works on both Android and Web (web shows helpful messages)

---

## AI Chat Assistant

### What Can AI Do?
The AI assistant can help you with:
1. **Scan receipts from chat**
   - Send receipt images directly in chat
   - AI extracts and saves transaction data

2. **Answer questions** about your transactions
   - "How much did I spend this month?"
   - "Show my largest transaction"
   - "What's my total balance?"

3. **Transaction insights**
   - Get summaries of your spending
   - View transaction patterns

### How to Use:
1. **Tap the "AI Chat" button** on dashboard
2. **Type your question** or **attach a receipt image**
3. **Wait for AI response**
4. **Review extracted data** (if you sent a receipt)
5. **Confirm to save** the transaction

### Important Notes:
- ✅ AI can add new transactions
- ❌ AI cannot edit existing transactions (transactions are permanent)
- ⚠️ Always review AI-extracted data before confirming
- 📱 Chat works on both mobile and web

---

## Manual Transaction Entry

### When to Use Manual Entry:
- When you don't have a receipt
- When scan quality is poor
- When you want to add a custom transaction

### How to Add Manually:
1. **Tap "Add Transaction"** from dashboard
2. **Fill in the details:**
   - **Transaction Type**: Cash In or Cash Out
   - **Amount**: Enter the amount (required)
   - **Reference Number**: Unique identifier (required, no duplicates)
   - **Date**: Select transaction date
   - **Source**: GCash, Bank, PayMaya, etc.
   - **Recipient/Sender Name**: Person or company name
   - **Phone Number**: Contact number (if available)
   - **Bank Name**: For bank transfers
   - **Account Name**: For bank transfers
   - **Bank Fee**: If applicable
   - **Notes**: Additional information

3. **Save**
   - Tap "Save Transaction"
   - App validates reference number uniqueness

### Validation Rules:
- ✅ Reference numbers must be unique
- ✅ Reference numbers: 8-20 characters
- ✅ Amount must be greater than 0
- ⚠️ Duplicate references will be rejected

---

## Transaction History

### Viewing Transactions:
1. **Tap "Transaction History"** from dashboard
2. **See all transactions** in chronological order
3. **Each transaction shows:**
   - Transaction type (Cash In/Out)
   - Amount
   - Reference number
   - Date and time
   - Source (GCash, Bank, etc.)
   - Recipient/Sender details

### Transaction Details:
- **Tap any transaction** to view full details
- See all information including:
  - Bank fees
  - Account details
  - Phone numbers
  - Notes

### What You CAN'T Do:
- ❌ **Edit transactions** - Transactions are permanent once saved
- ❌ **Change amounts or dates** - For accuracy and record keeping
- ✅ **Delete transactions** - You can remove incorrect entries

---

## Profile & Settings

### Profile Information:
- View your account details
- See your display name and email
- Profile photo from Google account

### Logout:
1. Tap "Logout" in profile
2. Confirm logout
3. You'll return to login screen

---

## Tips & Best Practices

### For Accurate Records:
1. **Scan receipts immediately** after transactions
2. **Always check extracted data** before saving
3. **Use unique reference numbers** for each transaction
4. **Keep receipts clear and readable**

### For Better Organization:
1. **Add notes** to transactions for context
2. **Use consistent naming** for recipients
3. **Record bank fees** separately for accurate tracking
4. **Review your dashboard regularly**

### For Security:
1. **Logout** when using shared devices
2. **Keep your account secure** (Google account)
3. **Don't share reference numbers** publicly

### Understanding Balance:
- **Total Balance** = All Cash In - All Cash Out
- **Available Funds** = Total Balance (fees excluded from both sides)
- **Fees** = Separate tracking of all transaction fees

---

## Frequently Asked Questions (FAQ)

### Q: Can I edit a transaction after saving?
**A:** No, transactions are permanent once saved. This ensures accuracy and prevents tampering with financial records. If you made a mistake, delete the transaction and create a new one.

### Q: What if my reference number is duplicate?
**A:** The app will warn you and prevent saving. Each reference number must be unique. Use a different reference or check if the transaction already exists.

### Q: Does OCR work on all receipts?
**A:** The app supports most common receipt formats (GCash, banks, PayMaya). It uses flexible pattern matching to extract data from various layouts. Always review extracted data for accuracy.

### Q: Can I use the app without internet?
**A:** Some features require internet (AI chat, receipt scanning with AI). Basic transaction viewing may work offline, but syncing requires connection.

### Q: Where is my data stored?
**A:** Your transactions are securely stored in Firebase/Firestore cloud database, linked to your Google account.

### Q: What if scanning doesn't work?
**A:** Try these steps:
1. Improve lighting
2. Clean your camera lens
3. Take a clearer photo
4. Use manual entry as backup
5. On web, use mobile app for better OCR

### Q: How do I delete a transaction?
**A:** Tap on the transaction in history, then look for the delete option. Confirm deletion when prompted.

---

## Troubleshooting

### Receipt Scanning Issues:
- **Blurry images**: Use better lighting, hold steady
- **Missing data**: Edit manually after scan
- **Wrong amounts**: Always review before saving

### AI Chat Issues:
- **AI not responding**: Check internet connection
- **Wrong extraction**: Review and edit data before confirming
- **Can't save**: Check for duplicate reference numbers

### General Issues:
- **App crashes**: Restart the app
- **Slow loading**: Check internet speed
- **Login problems**: Verify Google account

---

## Contact & Support

For additional help or to report issues:
- Check this guide first
- Review the transaction history for patterns
- Contact app administrator

---

**Version:** 1.0  
**Last Updated:** November 26, 2025

---

## Quick Reference Card

| Feature | Button/Location | Purpose |
|---------|----------------|---------|
| Scan Receipt | Dashboard → 📸 | Quick receipt capture |
| AI Chat | Dashboard → 💬 | Ask questions, scan via chat |
| Add Transaction | Dashboard → ➕ | Manual entry |
| History | Dashboard → 📊 | View all transactions |
| Profile | Top right avatar | Account & logout |

### Transaction Rules:
- ✅ Reference numbers must be unique
- ✅ Amounts must be > 0
- ❌ Cannot edit after saving
- ✅ Can delete transactions
- ⚠️ Always review scanned data

---

**Happy Tracking! 💰**
