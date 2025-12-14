import 'package:get/get.dart';
import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_service.dart';
import '../services/transaction_service.dart';
import '../services/ocr_service.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import 'app_controller.dart';
import 'package:intl/intl.dart';

class GeminiController extends GetxController {
  final GeminiService _geminiService = GeminiService();
  final TransactionService _transactionService = TransactionService();
  final AppController _appController = Get.find<AppController>();

  final RxString currentResponse = ''.obs;
  final RxBool isLoading = false.obs;
  final RxList<ChatMessage> chatHistory = <ChatMessage>[].obs;
  final RxString error = ''.obs;
  // Pending action (waiting for user confirmation)
  final Rxn<ActionRequest> pendingAction = Rxn<ActionRequest>();

  // Chat session management
  final RxList<ChatSession> savedChatSessions = <ChatSession>[].obs;
  DateTime? _currentSessionStart;

  List<TransactionModel> _userTransactions = [];
  final currencyFormat =
      NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

  @override
  void onInit() {
    super.onInit();
    _loadUserTransactions();
    _loadChatHistory();
  }

  /// Parse simple user commands and return an ActionRequest if found
  ActionRequest? _parseUserCommand(String message) {
    final lower = message.toLowerCase();

    // Check if user wants to modify pending transaction type
    if (pendingAction.value != null &&
        pendingAction.value!.type == ActionType.saveTransaction) {
      if (lower.contains('cash in')) {
        pendingAction.value!.payload['transactionType'] = 'Cash In';
        chatHistory.add(ChatMessage(
            text:
                'Transaction type updated to Cash In. Reply "yes" to confirm and save.',
            isUser: false,
            timestamp: DateTime.now()));
        return null;
      } else if (lower.contains('cash out')) {
        pendingAction.value!.payload['transactionType'] = 'Cash Out';
        chatHistory.add(ChatMessage(
            text:
                'Transaction type updated to Cash Out. Reply "yes" to confirm and save.',
            isUser: false,
            timestamp: DateTime.now()));
        return null;
      }
    }

    // Clear all transactions: "clear all transactions" or "delete all transactions"
    if (RegExp(r'(clear|delete)\s+all\s+transactions?', caseSensitive: false)
        .hasMatch(lower)) {
      return ActionRequest(
        type: ActionType.clearAllTransactions,
        payload: {},
        description:
            'Delete ALL transactions (${_userTransactions.length} total)',
      );
    }

    // Delete by recipient: "delete transactions to John" or "remove all payments to Mary"
    final recipientMatch = RegExp(
            r'(?:delete|remove).*(?:to|for|from)\s+([a-z\s]+)',
            caseSensitive: false)
        .firstMatch(lower);
    if (recipientMatch != null && !lower.contains('amount')) {
      final recipient = recipientMatch.group(1)!.trim();
      final matchingTxs = _userTransactions
          .where((t) => t.recipientName.toLowerCase().contains(recipient))
          .toList();
      if (matchingTxs.isNotEmpty) {
        return ActionRequest(
          type: ActionType.deleteByRecipient,
          payload: {'recipientName': recipient},
          description:
              'Delete ${matchingTxs.length} transaction(s) to/from "$recipient"',
        );
      }
    }

    // Delete transaction by id: "delete transaction 123"
    final deleteMatch = RegExp(r'delete transaction(?: id| #)?\s*([\w\-]+)',
            caseSensitive: false)
        .firstMatch(lower);
    if (deleteMatch != null) {
      final id = deleteMatch.group(1)!;
      return ActionRequest(
        type: ActionType.deleteTransaction,
        payload: {'transactionId': id},
        description: 'Delete transaction with id $id',
      );
    }

    // Update fee range: "set fee for 1-500 to 15" or "update fee range 1-500 fee 10"
    // Matches patterns like: "fee for 100-500 to 15", "set fee range 1 to 500 fee 10", "update fee 100-200 to 20"
    final feeMatch = RegExp(
            r'(?:set|update)?\s*(?:fee|fee\s+range|fee\s+for)\s+(?:range)?\s*(\d+)\s*(?:-|to)\s*(\d+)\s+(?:fee\s+)?(?:to\s+)?(\d+)',
            caseSensitive: false)
        .firstMatch(lower);
    if (feeMatch != null) {
      final from = int.parse(feeMatch.group(1)!);
      final to = int.parse(feeMatch.group(2)!);
      final fee = int.parse(feeMatch.group(3)!);
      return ActionRequest(
        type: ActionType.updateFeeRange,
        payload: {'from': from, 'to': to, 'fee': fee},
        description: 'Set fee ₱${fee} for range ₱${from} - ₱${to}',
      );
    }

    // Clear chat history: "clear chat" or "reset conversation"
    if (RegExp(r'(clear|reset|delete)\s+(chat|conversation|history)',
            caseSensitive: false)
        .hasMatch(lower)) {
      return ActionRequest(
        type: ActionType.clearChat,
        payload: {},
        description: 'Clear chat history',
      );
    }

    return null;
  }

  /// Request confirmation and store pending action
  Future<void> requestAction(ActionRequest action) async {
    pendingAction.value = action;
    // Add assistant message asking for confirmation
    chatHistory.add(ChatMessage(
      text:
          'I detected this action: ${action.description}. Do you want to proceed? Reply "yes" to confirm or "no" to cancel.',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  /// Confirm and execute the pending action
  Future<void> confirmPendingAction() async {
    final action = pendingAction.value;
    if (action == null) return;

    // Execute
    try {
      switch (action.type) {
        case ActionType.deleteTransaction:
          final id = action.payload['transactionId'] as String;
          await _transactionService.deleteTransaction(id);
          chatHistory.add(ChatMessage(
              text: 'Transaction $id deleted.',
              isUser: false,
              timestamp: DateTime.now()));
          break;
        case ActionType.updateFeeRange:
          final from = action.payload['from'] as int;
          final to = action.payload['to'] as int;
          final fee = action.payload['fee'] as int;
          // Find matching range index in AppController
          final idx = _appController.feeRanges
              .indexWhere((r) => r.from == from && r.to == to);
          if (idx >= 0) {
            _appController.updateFeeRange(
                idx, FeeRange(from: from, to: to, fee: fee));
            chatHistory.add(ChatMessage(
                text: 'Fee range updated: ₱${from}-₱${to} -> ₱${fee}.',
                isUser: false,
                timestamp: DateTime.now()));
          } else {
            // If not found, add as new range
            _appController.addFeeRange(FeeRange(from: from, to: to, fee: fee));
            chatHistory.add(ChatMessage(
                text: 'Fee range added: ₱${from}-₱${to} -> ₱${fee}.',
                isUser: false,
                timestamp: DateTime.now()));
          }
          break;
        case ActionType.clearAllTransactions:
          // Delete all user transactions
          final userId = _appController.currentUserId.value;
          final allTxs = await _transactionService.getUserTransactions(userId,
              limit: 10000);
          int deleted = 0;
          for (final tx in allTxs) {
            try {
              await _transactionService.deleteTransaction(tx.id);
              deleted++;
            } catch (e) {
              print('Failed to delete ${tx.id}: $e');
            }
          }
          await _loadUserTransactions();
          chatHistory.add(ChatMessage(
              text: 'Deleted $deleted transaction(s).',
              isUser: false,
              timestamp: DateTime.now()));
          break;
        case ActionType.deleteByRecipient:
          final recipientName = action.payload['recipientName'] as String;
          final matchingTxs = _userTransactions
              .where((t) => t.recipientName
                  .toLowerCase()
                  .contains(recipientName.toLowerCase()))
              .toList();
          int deleted = 0;
          for (final tx in matchingTxs) {
            try {
              await _transactionService.deleteTransaction(tx.id);
              deleted++;
            } catch (e) {
              print('Failed to delete ${tx.id}: $e');
            }
          }
          await _loadUserTransactions();
          chatHistory.add(ChatMessage(
              text: 'Deleted $deleted transaction(s) for "$recipientName".',
              isUser: false,
              timestamp: DateTime.now()));
          break;
        case ActionType.clearChat:
          clearChat();
          chatHistory.add(ChatMessage(
              text: 'Chat history cleared.',
              isUser: false,
              timestamp: DateTime.now()));
          break;
        case ActionType.saveTransaction:
          final recipientName = action.payload['recipientName'] as String;
          final amount = (action.payload['amount'] as num).toDouble();
          final refNumber = action.payload['refNumber'] as String;
          final phoneNumber = action.payload['phoneNumber'] as String;
          final transactionType = action.payload['transactionType'] as String;

          // Check for duplicate reference number
          if (refNumber.isNotEmpty) {
            final isDuplicate =
                await _transactionService.isReferenceNumberDuplicate(
              _appController.currentUserId.value,
              refNumber,
            );

            if (isDuplicate) {
              chatHistory.add(ChatMessage(
                  text: '⚠️ **Duplicate Reference Number Detected**\n\n'
                      'Reference number "$refNumber" already exists in your transaction history.\n\n'
                      '**What you can do:**\n'
                      '• Edit the reference number to make it unique\n'
                      '• Check if this transaction was already recorded\n'
                      '• Scan a different receipt\n\n'
                      'Each reference number must be unique to avoid duplicate entries.',
                  isUser: false,
                  timestamp: DateTime.now()));
              pendingAction.value = null;
              return;
            }
          }

          // Calculate fee based on amount
          final fee = _calculateFee(amount);
          final totalAmount = amount + fee;

          // Create transaction model
          final transaction = TransactionModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: _appController.currentUserId.value,
            recipientName: recipientName,
            phoneNumber: phoneNumber,
            amount: amount,
            fee: fee,
            totalAmount: totalAmount,
            refNumber: refNumber,
            date: DateTime.now(),
            source: 'AI Chat',
            transactionType: transactionType,
            createdAt: DateTime.now(),
          );

          // Save transaction
          await _transactionService.saveTransaction(transaction);
          await _loadUserTransactions();

          chatHistory.add(ChatMessage(
              text: '''✅ Transaction saved successfully!

📄 Details:
• Recipient: $recipientName
• Amount: ${currencyFormat.format(amount)}
• Fee: ${currencyFormat.format(fee)}
• Total: ${currencyFormat.format(totalAmount)}
• Reference: $refNumber
• Type: $transactionType

Added to your transaction history.''',
              isUser: false,
              timestamp: DateTime.now()));
          break;
      }
    } catch (e) {
      chatHistory.add(ChatMessage(
          text: 'Failed to execute action: $e',
          isUser: false,
          timestamp: DateTime.now()));
    } finally {
      pendingAction.value = null;
    }
  }

  /// Cancel pending action
  void cancelPendingAction() {
    pendingAction.value = null;
    chatHistory.add(ChatMessage(
        text: 'Action cancelled.', isUser: false, timestamp: DateTime.now()));
  }

  Future<void> _loadUserTransactions() async {
    try {
      final userId = _appController.currentUserId.value;
      if (userId.isNotEmpty) {
        _userTransactions =
            await _transactionService.getUserTransactions(userId);
      }
    } catch (e) {
      print('Error loading transactions for AI: $e');
    }
  }

  String _buildContextPrompt() {
    if (_userTransactions.isEmpty) {
      return '''You are a financial assistant for the GCash receipt scanning app. 
The user has no transaction history yet.
Help them understand the app features and how to track their finances.''';
    }

    final totalIncome = _userTransactions
        .where((t) => t.transactionType == 'Cash In')
        .fold<double>(0, (sum, t) => sum + t.amount);

    final totalExpenses = _userTransactions
        .where((t) => t.transactionType == 'Cash Out')
        .fold<double>(0, (sum, t) => sum + t.amount);

    final balance = totalIncome - totalExpenses;
    final transactionCount = _userTransactions.length;

    // Calculate analytics
    final cashInCount =
        _userTransactions.where((t) => t.transactionType == 'Cash In').length;
    final cashOutCount =
        _userTransactions.where((t) => t.transactionType == 'Cash Out').length;

    final avgIncome = cashInCount > 0 ? totalIncome / cashInCount : 0.0;
    final avgExpense = cashOutCount > 0 ? totalExpenses / cashOutCount : 0.0;

    // Top recipients by transaction count
    final recipientFrequency = <String, int>{};
    final recipientTotal = <String, double>{};
    for (final tx in _userTransactions) {
      recipientFrequency[tx.recipientName] =
          (recipientFrequency[tx.recipientName] ?? 0) + 1;
      recipientTotal[tx.recipientName] =
          (recipientTotal[tx.recipientName] ?? 0) + tx.amount;
    }
    final topRecipients = recipientFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topRecipientsStr = topRecipients
        .take(3)
        .map((e) =>
            '${e.key} (${e.value} txs, ${currencyFormat.format(recipientTotal[e.key] ?? 0)})')
        .join(', ');

    // Largest and smallest transactions
    if (_userTransactions.isNotEmpty) {
      final sortedByAmount = List<TransactionModel>.from(_userTransactions)
        ..sort((a, b) => b.amount.compareTo(a.amount));
      final largest = sortedByAmount.first;
      final smallest = sortedByAmount.last;
      final largestTx =
          '${currencyFormat.format(largest.amount)} to ${largest.recipientName}';
      final smallestTx =
          '${currencyFormat.format(smallest.amount)} to ${smallest.recipientName}';

      // Recent transactions summary
      final recentTransactions = _userTransactions
          .take(5)
          .map((t) =>
              '${t.transactionType}: ${currencyFormat.format(t.amount)} to ${t.recipientName} on ${DateFormat('MMM dd').format(t.createdAt)}')
          .join('; ');

      // Date range
      final oldestDate = _userTransactions
          .map((t) => t.createdAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final newestDate = _userTransactions
          .map((t) => t.createdAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final daysDiff = newestDate.difference(oldestDate).inDays + 1;
      final transactionsPerDay = transactionCount / daysDiff;

      return '''You are a financial assistant for the GCash receipt scanning app with FULL CONTROL over the app.

📊 COMPREHENSIVE FINANCIAL ANALYSIS:

Dashboard Summary:
- Total Cash In: ${currencyFormat.format(totalIncome)} ($cashInCount transactions)
- Total Cash Out: ${currencyFormat.format(totalExpenses)} ($cashOutCount transactions)
- Available Funds: ${currencyFormat.format(balance)}
- All Transactions: $transactionCount
- Total Fees Paid: Tracked separately

Transaction Analytics:
- Average Income per Transaction: ${currencyFormat.format(avgIncome)}
- Average Expense per Transaction: ${currencyFormat.format(avgExpense)}
- Largest Transaction: $largestTx
- Smallest Transaction: $smallestTx
- Transaction Frequency: ${transactionsPerDay.toStringAsFixed(1)} transactions/day
- Data Period: ${DateFormat('MMM dd, yyyy').format(oldestDate)} to ${DateFormat('MMM dd, yyyy').format(newestDate)} ($daysDiff days)

Top Recipients:
$topRecipientsStr

Recent Transactions (Last 5):
$recentTransactions

Financial Insights:
- Money Sent Ratio: ${((totalExpenses / totalIncome) * 100).toStringAsFixed(1)}% of received
- Net Balance Rate: ${(((totalIncome - totalExpenses) / totalIncome) * 100).toStringAsFixed(1)}%
- Average Daily Cash Out: ${currencyFormat.format(totalExpenses / daysDiff)}

IMPORTANT: You have the ability to:
- Delete transactions (single, by recipient, or all)
- Set or update fee ranges
- Clear chat history
- Analyze and provide financial advice

Note: Transactions cannot be edited once saved. If a transaction is incorrect, it must be deleted and a new one created.

When a user asks you to modify data (like "set fee for 1-500 to 15"), you WILL execute the action after user confirmation. Do not say you cannot perform these actions. You CAN and WILL do them.

Provide helpful, concise financial advice based on this data. When asked about income, expenses, balance, or transactions, use the data above. Be friendly and supportive.''';
    } else {
      // Fallback for empty or insufficient data
      return '''You are a financial assistant for the GCash receipt scanning app with FULL CONTROL over the app.

User's Dashboard Summary:
- Total Cash In: ${currencyFormat.format(totalIncome)}
- Total Cash Out: ${currencyFormat.format(totalExpenses)}
- Available Funds: ${currencyFormat.format(balance)}
- All Transactions: $transactionCount

IMPORTANT: You have the ability to:
- Delete transactions (single, by recipient, or all)
- Set or update fee ranges
- Clear chat history
- Analyze and provide financial advice

Note: Transactions cannot be edited once saved. If a transaction is incorrect, it must be deleted and a new one created.

When a user asks you to modify data (like "set fee for 1-500 to 15"), you WILL execute the action after user confirmation. Do not say you cannot perform these actions. You CAN and WILL do them.

Provide helpful, concise financial advice. Be friendly and supportive.''';
    }
  }

  /// Check if the query is finance-related and needs full context
  bool _isFinanceRelatedQuery(String lowerMessage) {
    final financeKeywords = [
      'balance',
      'money',
      'cash',
      'transaction',
      'spend',
      'spent',
      'income',
      'expense',
      'payment',
      'paid',
      'receive',
      'received',
      'total',
      'amount',
      'fee',
      'fees',
      'recipient',
      'send',
      'sent',
      'transfer',
      'how much',
      'analytics',
      'report',
      'summary',
      'dashboard',
      'history',
      'record',
      'save',
      'delete',
      'remove',
      'clear',
      'show',
      'list',
      'view',
      'cash in',
      'cash out',
      'load',
      'bank transfer',
      'pesos',
      '₱',
      'financial',
      'budget',
      'savings',
      'debt',
      'owe',
      'owes'
    ];

    return financeKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  /// Quick, rule-based answers for frequent questions (fees, totals, counts)
  String? _buildQuickAnswer(String lowerMessage) {
    if (_userTransactions.isEmpty) {
      return null;
    }

    final totalIncome = _userTransactions
        .where((t) => t.transactionType == 'Cash In')
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpenses = _userTransactions
        .where((t) => t.transactionType == 'Cash Out')
        .fold<double>(0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpenses;
    final totalFees =
        _userTransactions.fold<double>(0, (sum, t) => sum + t.fee);
    final txCount = _userTransactions.length;

    // Total fees asked
    if (lowerMessage.contains('total fee') ||
        lowerMessage.contains('fees total') ||
        lowerMessage.contains('how much fee') ||
        lowerMessage.contains('all my fee')) {
      return 'Total fees paid: ${currencyFormat.format(totalFees)} across $txCount transactions.';
    }

    // Balance
    if (lowerMessage.contains('balance')) {
      return 'Balance (Cash In - Cash Out): ${currencyFormat.format(balance)}\nCash In: ${currencyFormat.format(totalIncome)}\nCash Out: ${currencyFormat.format(totalExpenses)}';
    }

    // Totals
    if (lowerMessage.contains('total cash in') ||
        lowerMessage.contains('total income')) {
      return 'Total Cash In: ${currencyFormat.format(totalIncome)} across ${_userTransactions.where((t) => t.transactionType == 'Cash In').length} transactions.';
    }
    if (lowerMessage.contains('total cash out') ||
        lowerMessage.contains('total expense')) {
      return 'Total Cash Out: ${currencyFormat.format(totalExpenses)} across ${_userTransactions.where((t) => t.transactionType == 'Cash Out').length} transactions.';
    }

    // Recent transactions quick view
    if (lowerMessage.contains('last 5') ||
        lowerMessage.contains('recent transactions')) {
      final recent = _userTransactions.take(5).toList();
      final lines = recent
          .map((t) =>
              '${t.transactionType}: ${currencyFormat.format(t.amount)} to ${t.recipientName} on ${DateFormat('MMM dd').format(t.createdAt)}')
          .join('\n');
      return 'Here are your last ${recent.length} transactions:\n$lines';
    }

    return null;
  }

  String _commandsCatalog() {
    return '''I can do these for you (no tech-speak needed):

• Check money: "what's my balance?", "total cash in", "total cash out", or "how much are all my fees?".
• Recent activity: "show my last 5 transactions" or "recent transactions".
• Scan a receipt: "scan this receipt" (attach a photo). If the type is wrong, reply "cash in" or "cash out", then say "yes" to save.
• Update fees: "set fee for 1-500 to 15" (use any number range and amount).
• Fix the chat: "clear chat" or "reset conversation".
• Confirm or cancel: reply "yes" / "confirm" or "no" / "cancel" when I ask.''';
  }

  /// Generate simple text response using Gemini AI
  Future<void> generateResponse(String prompt) async {
    isLoading.value = true;
    error.value = '';
    currentResponse.value = '';

    try {
      final response = await _geminiService.generateContent(prompt);
      if (response != null) {
        currentResponse.value = response;
      } else {
        error.value = 'Failed to generate response';
      }
    } catch (e) {
      error.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Send chat message and maintain history using Gemini AI
  Future<void> sendChatMessage(String message,
      {bool skipAddingUserMessage = false}) async {
    isLoading.value = true;
    error.value = '';

    await _loadUserTransactions();

    if (!skipAddingUserMessage) {
      chatHistory.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _saveChatHistory(); // Save after user message
    }

    final lower = message.toLowerCase().trim();

    // Show command catalog
    if (lower.contains('show commands') ||
        lower.contains('list commands') ||
        lower == 'help' ||
        lower.contains('what can you do')) {
      chatHistory.add(ChatMessage(
        text: _commandsCatalog(),
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _saveChatHistory();
      isLoading.value = false;
      return;
    }

    // Confirmation flow
    if (pendingAction.value != null &&
        (lower == 'yes' || lower == 'y' || lower == 'confirm')) {
      await confirmPendingAction();
      isLoading.value = false;
      return;
    }
    if (pendingAction.value != null &&
        (lower == 'no' || lower == 'n' || lower == 'cancel')) {
      cancelPendingAction();
      isLoading.value = false;
      return;
    }

    // Check for actionable commands first
    final actionRequest = _parseUserCommand(message);
    if (actionRequest != null) {
      await requestAction(actionRequest);
      isLoading.value = false;
      return;
    }

    // Quick answers for common questions (totals, balances, fees)
    final quickAnswer = _buildQuickAnswer(lower);
    if (quickAnswer != null) {
      chatHistory.add(ChatMessage(
        text: quickAnswer,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _saveChatHistory();
      isLoading.value = false;
      return;
    }

    // Use Gemini AI for general conversation
    try {
      // Check if user is asking about finances or just casual conversation
      final isFinanceQuery = _isFinanceRelatedQuery(lower);

      // Build context-aware prompt only for finance queries
      String fullMessage;
      if (isFinanceQuery) {
        final contextPrompt = _buildContextPrompt();
        fullMessage = '$contextPrompt\n\nUser Question: $message';
      } else {
        // For casual conversation, use minimal prompt
        fullMessage =
            '''You are a friendly financial assistant for the GCash receipt scanning app.
Keep responses brief and natural. If the user asks about their finances, transactions, or balance, let them know you can help with that.

User: $message''';
      }

      // Convert chat history to Gemini Content format (only AI responses for context)
      final history = chatHistory
          .where((msg) => !msg.isUser)
          .map((msg) => Content.text(msg.text))
          .toList();

      final response = await _geminiService.chat(fullMessage, history);

      if (response != null) {
        chatHistory.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _saveChatHistory(); // Auto-save after each message
      } else {
        error.value = 'Failed to get response';
      }
    } catch (e) {
      error.value = 'Error: $e';
      chatHistory.add(ChatMessage(
        text: 'Sorry, I encountered an error. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      isLoading.value = false;
    }
  }

  /// Send chat message with image (for receipt scanning)
  Future<void> sendChatMessageWithImage(String message, File? imageFile) async {
    print('🟢 [CONTROLLER] sendChatMessageWithImage called');
    print('🟢 [CONTROLLER] Message: "$message"');
    print('🟢 [CONTROLLER] Has image: ${imageFile != null}');
    print('🟢 [CONTROLLER] isLoading: ${isLoading.value}');
    print('🟢 [CONTROLLER] Current chat history length: ${chatHistory.length}');

    // Prevent duplicate calls - check both loading state and recent identical messages
    if (isLoading.value) {
      print('⛔ [CONTROLLER] Already loading, returning');
      return;
    }

    final messageText =
        imageFile != null ? '$message [Image attached]' : message;
    print('🟢 [CONTROLLER] Final message text: "$messageText"');

    // Check if identical message was sent within last 2 seconds (debounce)
    if (chatHistory.isNotEmpty && chatHistory.last.isUser) {
      final lastMessage = chatHistory.last;
      final timeDiff =
          DateTime.now().difference(lastMessage.timestamp).inSeconds;
      print('🟢 [CONTROLLER] Last message: "${lastMessage.text}"');
      print('🟢 [CONTROLLER] Time diff: $timeDiff seconds');
      if (lastMessage.text == messageText && timeDiff < 2) {
        print('⛔ [CONTROLLER] Duplicate detected within 2 seconds, returning');
        return; // Ignore duplicate within 2 seconds
      }
    }

    isLoading.value = true;
    print('🟢 [CONTROLLER] Set isLoading to true');
    error.value = '';

    // Reload transactions to get latest data
    await _loadUserTransactions();

    // Track session start time if this is the first message
    if (chatHistory.isEmpty) {
      _currentSessionStart = DateTime.now();
    }

    // Add user message to history
    print('🟢 [CONTROLLER] Adding user message to chat history...');
    chatHistory.add(ChatMessage(
      text: messageText,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    print('🟢 [CONTROLLER] Message added. New length: ${chatHistory.length}');

    try {
      String? response;

      if (imageFile != null) {
        // Image processing handled by OCR service
        // Read image bytes
        await imageFile.readAsBytes();

        // Check if user wants to scan receipt and save
        final isReceiptScan = message.toLowerCase().contains('scan') ||
            message.toLowerCase().contains('receipt') ||
            message.toLowerCase().contains('save') ||
            message.toLowerCase().contains('transaction');

        if (isReceiptScan) {
          // Use OCR service to extract receipt data (handles both money transfer and bank transfer)
          chatHistory.add(ChatMessage(
            text: 'Analyzing receipt image...',
            isUser: false,
            timestamp: DateTime.now(),
          ));

          final ocrService = OCRService();
          final receiptModel = await ocrService.processReceipt(
            imageFile,
            _appController.feeRanges,
          );

          if (receiptModel != null) {
            // Extract transaction data from OCR result
            final recipientName = receiptModel.recipientName;
            final amount = receiptModel.amount;
            final refNumber = receiptModel.refNumber;
            final phoneNumber = receiptModel.phoneNumber;
            final transactionType = receiptModel.transactionType;

            // Show extracted data to user for confirmation
            response = '''✅ Receipt scanned successfully!

📄 Extracted Data:
• Recipient: $recipientName
• Amount: ${currencyFormat.format(amount)}
• Reference: $refNumber
• Phone: ${phoneNumber.isNotEmpty ? phoneNumber : 'Not found'}
• Type: $transactionType

Please confirm if you want to save this transaction by typing "yes" or "save".
To change the transaction type, reply with:
- "cash in" for Cash In
- "cash out" for Cash Out''';

            // Store pending transaction for confirmation
            pendingAction.value = ActionRequest(
              type: ActionType.saveTransaction,
              payload: {
                'recipientName': recipientName,
                'amount': amount,
                'refNumber': refNumber,
                'phoneNumber': phoneNumber,
                'transactionType': transactionType,
              },
              description: 'Save scanned receipt as transaction',
            );
          } else {
            response =
                '❌ Could not scan receipt. Please make sure the image is clear and shows a GCash receipt (Money Transfer or Bank Transfer).';
          }
        } else {
          // General image analysis disabled in manual mode
          response =
              'Image understanding is available only for receipt scanning right now. Try saying "scan this receipt" with a clear receipt image.';
        }
      } else {
        // No image, just text message - user message already added above, so skip adding it again
        print(
            '🟢 [CONTROLLER] No image, delegating to sendChatMessage (user message already added)');
        isLoading.value =
            false; // Reset loading since sendChatMessage will set it
        await sendChatMessage(message, skipAddingUserMessage: true);
        return;
      }

      print('🟢 [CONTROLLER] Adding AI response to chat history...');
      chatHistory.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      print(
          '🟢 [CONTROLLER] AI response added. New length: ${chatHistory.length}');
    } catch (e) {
      error.value = 'Error: $e';
      print('❌ [CONTROLLER] Error: $e');
      chatHistory.add(ChatMessage(
        text: 'Sorry, I encountered an error processing your request: $e',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      isLoading.value = false;
      print('🟢 [CONTROLLER] Set isLoading to false');
      print('🟢 [CONTROLLER] Final chat history length: ${chatHistory.length}');
    }
  }

  /// Calculate fee based on amount and fee ranges
  double _calculateFee(double amount) {
    for (final range in _appController.feeRanges) {
      if (amount >= range.from && amount <= range.to) {
        return range.fee.toDouble();
      }
    }
    return 0.0;
  }

  /// Stream response for real-time generation using Gemini AI
  void streamResponse(String prompt, Function(String) onChunk) async {
    isLoading.value = true;
    error.value = '';
    currentResponse.value = '';

    try {
      await for (final chunk in _geminiService.generateContentStream(prompt)) {
        currentResponse.value += chunk;
        onChunk(chunk);
      }
    } catch (e) {
      error.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Analyze transaction using AI
  Future<String?> analyzeTransaction(String transactionDetails) async {
    try {
      return await _geminiService.analyzeTransaction(transactionDetails);
    } catch (e) {
      error.value = 'Error: $e';
      return null;
    }
  }

  /// Get financial advice
  Future<String?> getFinancialAdvice({
    required double balance,
    required double expenses,
    required double income,
  }) async {
    try {
      return await _geminiService.getFinancialAdvice(
        balance,
        expenses,
        income,
      );
    } catch (e) {
      error.value = 'Error: $e';
      return null;
    }
  }

  /// Validate if an image is a receipt
  Future<bool> validateReceiptImage(List<int> imageBytes) async {
    try {
      final prompt = '''
Analyze this image and determine if it is a receipt or transaction document.

A valid receipt should contain:
- Transaction amounts or prices
- Date or timestamp
- Merchant/store name or reference numbers
- Payment details or transaction type

Respond with ONLY "true" if this is a receipt/transaction document, or "false" if it's not (like a selfie, random photo, screenshot, etc.).

Response (true/false):''';

      final response =
          await _geminiService.generateContentWithImage(prompt, imageBytes);

      if (response == null) return false;

      final cleanResponse = response.trim().toLowerCase();
      return cleanResponse.contains('true');
    } catch (e) {
      print('Error validating receipt: $e');
      return false;
    }
  }

  /// Analyze receipt image - returns structured data
  Future<Map<String, dynamic>?> analyzeReceiptImage(
      List<int> imageBytes) async {
    try {
      return await _geminiService.analyzeReceiptImage(imageBytes);
    } catch (e) {
      error.value = 'Error: $e';
      return null;
    }
  }

  /// Extract custom information from image using custom prompt
  Future<String?> extractCustomInfo(
    List<int> imageBytes,
    List<String> fieldsToExtract, {
    String? additionalInstructions,
  }) async {
    try {
      final prompt = '''
Extract the following information from this image:
${fieldsToExtract.map((field) => '- $field').join('\n')}

${additionalInstructions ?? ''}''';
      return await _geminiService.generateContentWithImage(prompt, imageBytes);
    } catch (e) {
      error.value = 'Error: $e';
      return null;
    }
  }

  /// Analyze any document with custom requirements
  Future<String?> analyzeCustomDocument(
    List<int> imageBytes,
    String requirements,
  ) async {
    try {
      return await _geminiService.generateContentWithImage(
          requirements, imageBytes);
    } catch (e) {
      error.value = 'Error: $e';
      return null;
    }
  }

  /// Delete a specific message by index
  void deleteMessage(int index) {
    if (index >= 0 && index < chatHistory.length) {
      chatHistory.removeAt(index);
      _saveChatHistory();
    }
  }

  /// Start a new conversation (saves current to history)
  void startNewConversation() {
    // Auto-save current chat to history if there are messages
    if (chatHistory.isNotEmpty) {
      _autoSaveChatSession();
    }
    chatHistory.clear();
    currentResponse.value = '';
    error.value = '';
    _currentSessionStart = DateTime.now();
    _saveChatHistory(); // Save empty state
  }

  /// Clear chat history
  void clearChat() {
    // Auto-save current chat before clearing if there are messages
    if (chatHistory.isNotEmpty) {
      _autoSaveChatSession();
    }
    chatHistory.clear();
    currentResponse.value = '';
    error.value = '';
    _currentSessionStart = null;
    _saveChatHistory(); // Save empty state
  }

  /// Auto-save current chat session with date-based title
  void _autoSaveChatSession() {
    if (chatHistory.isEmpty) return;

    // Generate title from first user message or use date
    String title = _generateChatTitle();

    final session = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      messages: List.from(chatHistory),
      savedAt: _currentSessionStart ?? DateTime.now(),
      messageCount: chatHistory.length,
    );

    savedChatSessions.insert(0, session);
  }

  /// Generate a title for the chat session
  String _generateChatTitle() {
    // Find first user message
    final firstUserMessage = chatHistory.firstWhere(
      (msg) => msg.isUser,
      orElse: () => chatHistory.first,
    );

    // Use first 40 characters of first message, or date if too short
    if (firstUserMessage.text.length > 10) {
      String title = firstUserMessage.text;
      if (title.length > 40) {
        title = '${title.substring(0, 40)}...';
      }
      return title;
    }

    // Fallback to date-based title
    final now = _currentSessionStart ?? DateTime.now();
    final dateFormat = DateFormat('MMM dd, yyyy \'at\' h:mm a');
    return 'Chat - ${dateFormat.format(now)}';
  }

  /// Save current chat session with custom title (manual save)
  void saveChatSession(String title) {
    if (chatHistory.isEmpty) return;

    final session = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      messages: List.from(chatHistory),
      savedAt: _currentSessionStart ?? DateTime.now(),
      messageCount: chatHistory.length,
    );

    savedChatSessions.insert(0, session);
  }

  /// Load a saved chat session
  void loadChatSession(String sessionId) {
    final session = savedChatSessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => throw Exception('Session not found'),
    );

    chatHistory.clear();
    chatHistory.addAll(session.messages);
  }

  /// Delete a saved chat session
  void deleteChatSession(String sessionId) {
    savedChatSessions.removeWhere((s) => s.id == sessionId);
  }

  /// Save chat history to persistent storage
  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _appController.currentUserId.value;

      if (userId.isEmpty) return;

      // Convert chat history to JSON
      final chatData = chatHistory
          .map((msg) => {
                'text': msg.text,
                'isUser': msg.isUser,
                'timestamp': msg.timestamp.millisecondsSinceEpoch,
              })
          .toList();

      await prefs.setString('chat_history_$userId', jsonEncode(chatData));
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }

  /// Load chat history from persistent storage
  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _appController.currentUserId.value;

      if (userId.isEmpty) return;

      final chatData = prefs.getString('chat_history_$userId');
      if (chatData == null) return;

      final List<dynamic> decodedData = jsonDecode(chatData);
      final loadedMessages = decodedData
          .map((msg) => ChatMessage(
                text: msg['text'] as String,
                isUser: msg['isUser'] as bool,
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                    msg['timestamp'] as int),
              ))
          .toList();

      chatHistory.clear();
      chatHistory.addAll(loadedMessages);
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }
}

/// Model for chat messages
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// Model for saved chat sessions
class ChatSession {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime savedAt;
  final int messageCount;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.savedAt,
    required this.messageCount,
  });
}

/// Action types that AI can request
enum ActionType {
  deleteTransaction,
  updateFeeRange,
  clearAllTransactions,
  deleteByRecipient,
  clearChat,
  saveTransaction
}

/// Simple action request model used for confirmation flow
class ActionRequest {
  final ActionType type;
  final Map<String, dynamic> payload;
  final String description;

  ActionRequest({
    required this.type,
    required this.payload,
    required this.description,
  });
}
