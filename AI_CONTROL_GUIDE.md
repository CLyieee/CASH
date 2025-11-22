I/flutter (31439): Error exporting report: PlatformException(channel-error, Unable to establish connection on channel: "dev.flutter.pigeon.path_provider_android.PathProviderApi.getTemporaryPath"., null, null)
# AI Control Guide - Full App Control via AI Chat

## Overview
Your AI assistant now has **full control** over your app's data and settings. You can manage transactions, fee ranges, and app settings using natural language commands.

## 🎯 Available Commands

### 1. Transaction Management

#### Delete Single Transaction
```
"delete transaction TX12345"
"remove transaction #TX67890"
```

#### Delete by Recipient Name
```
"delete all transactions to John"
"remove payments to Mary"
"delete transactions from Store ABC"
```

#### Clear All Transactions
```
"clear all transactions"
"delete all transactions"
"remove all my transactions"
```

⚠️ **Warning**: These operations are destructive and cannot be undone!

#### Update Transaction Amount
```
"update transaction TX12345 amount to 500"
"change transaction #TX67890 set amount to 1200.50"
```

### 2. Fee Range Management

#### Update Existing Fee Range
```
"set fee range 1-500 fee 10"
"update fee for 1-500 to 15"
"set fee 20 for range 501 to 1000"
```

#### Add New Fee Range
If the fee range doesn't exist, the AI will automatically create it.

### 3. Chat Management

#### Clear Chat History
```
"clear chat"
"reset conversation"
"delete chat history"
```

### 4. Financial Queries

The AI is context-aware and knows your financial data:

```
"What's my balance?"
"How much did I spend this month?"
"Show me transactions to John"
"What's my total income?"
"Give me financial advice"
```

## 🔐 Confirmation Flow

For security, all destructive actions require confirmation:

1. **User issues command**: "delete transaction TX123"
2. **AI detects action**: Shows a pending action card
3. **User confirms**: Tap "Confirm" button or reply "yes"
4. **Action executes**: Transaction is deleted
5. **Confirmation message**: AI confirms completion

You can cancel anytime by:
- Tapping the "Cancel" button
- Replying "no"

## 📝 Command Examples

### Example 1: Update Fee
```
You: "Set fee for 1-500 to 15"
AI: [Pending Action Card]
    "Set fee ₱15 for range ₱1 - ₱500"
    [Confirm] [Cancel]
You: [Tap Confirm]
AI: "Fee range updated: ₱1-₱500 -> ₱15."
```

### Example 2: Delete Transactions
```
You: "Delete all payments to John Doe"
AI: [Pending Action Card]
    "Delete 5 transaction(s) to/from 'john doe'"
    [Confirm] [Cancel]
You: [Tap Confirm]
AI: "Deleted 5 transaction(s) for 'john doe'."
```

### Example 3: Financial Query (No Confirmation Needed)
```
You: "What's my total spending?"
AI: "Based on your transaction history, your total expenses are ₱12,450.00 
     across 23 transactions. Your income is ₱18,000.00, giving you a 
     positive balance of ₱5,550.00."
```

## 🛡️ Security Recommendations

1. **PIN Protection**: Consider requiring PIN confirmation for destructive actions
2. **Backup Data**: Regularly backup your Firestore data
3. **Test Commands**: Test on sample data before using on production data
4. **Review Actions**: Always review the pending action description before confirming
5. **API Key**: Store your Gemini API key securely (not in code)

## 🔧 Technical Details

### Parsed Command Patterns

The AI uses regex patterns to detect commands:

- **Delete by ID**: `delete transaction(?: id| #)?\s*([\w\-]+)`
- **Delete by recipient**: `(?:delete|remove).*(?:to|for|from)\s+([a-z\s]+)`
- **Clear all**: `(clear|delete)\s+all\s+transactions?`
- **Update amount**: `update transaction(?: id| #)?\s*([\w\-]+).*amount to\s*([0-9]+(?:\.[0-9]+)?)`
- **Update fee**: `(?:fee range|fee for)\s*(\d+)\s*[-to]+\s*(\d+).*?(?:fee|set to)\s*([0-9]+)`
- **Clear chat**: `(clear|reset|delete)\s+(chat|conversation|history)`

### Action Types

```dart
enum ActionType { 
  deleteTransaction,      // Delete single transaction
  updateTransaction,      // Update transaction amount
  updateFeeRange,         // Update/add fee range
  clearAllTransactions,   // Delete all transactions
  deleteByRecipient,      // Delete by recipient name
  clearChat              // Clear chat history
}
```

### Controller Methods

- `_parseUserCommand(String)`: Detects actionable commands
- `requestAction(ActionRequest)`: Stores pending action for confirmation
- `confirmPendingAction()`: Executes the pending action
- `cancelPendingAction()`: Cancels the pending action

## 🚀 Future Enhancements

Potential additions:
- [ ] Add transaction with voice/text
- [ ] Export transactions to CSV/PDF
- [ ] Schedule recurring transactions
- [ ] Budget alerts and limits
- [ ] Multi-language command support
- [ ] More sophisticated NLU (instead of regex)
- [ ] Undo last action
- [ ] Batch operations with filters

## ⚠️ Known Limitations

1. **Command Format**: Must match regex patterns exactly
2. **Transaction IDs**: Must use exact transaction ID (case-sensitive)
3. **Recipient Matching**: Uses partial lowercase matching
4. **No Undo**: Deleted transactions cannot be recovered
5. **Firestore Limits**: Bulk operations may timeout on large datasets

## 📞 Support

If you encounter issues:
1. Check error messages in the AI chat
2. Verify command format matches examples
3. Check Firestore rules and permissions
4. Review console logs for detailed errors

---

**Version**: 1.0  
**Last Updated**: November 23, 2025  
**Model**: Gemini 2.5 Flash
