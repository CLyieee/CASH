import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/gemini_service.dart';
import '../services/transaction_service.dart';
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

  List<TransactionModel> _userTransactions = [];
  final currencyFormat =
      NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

  @override
  void onInit() {
    super.onInit();
    _loadUserTransactions();
  }

  /// Parse simple user commands and return an ActionRequest if found
  ActionRequest? _parseUserCommand(String message) {
    final lower = message.toLowerCase();

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

    // Update transaction amount: "update transaction 123 set amount to 500"
    final updateMatch = RegExp(
            r'update transaction(?: id| #)?\s*([\w\-]+).*amount to\s*([0-9]+(?:\.[0-9]+)?)',
            caseSensitive: false)
        .firstMatch(lower);
    if (updateMatch != null) {
      final id = updateMatch.group(1)!;
      final amt = double.tryParse(updateMatch.group(2)!) ?? 0.0;
      return ActionRequest(
        type: ActionType.updateTransaction,
        payload: {'transactionId': id, 'amount': amt},
        description:
            'Update transaction $id amount to ${currencyFormat.format(amt)}',
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
        case ActionType.updateTransaction:
          final id = action.payload['transactionId'] as String;
          final amount = (action.payload['amount'] as num).toDouble();
          // fetch transaction, update amount, save
          final txs = await _transactionService.getUserTransactions(
              _appController.currentUserId.value,
              limit: 1000);
          final tx = txs.firstWhere((t) => t.id == id,
              orElse: () => throw 'Transaction not found');
          final updated = TransactionModel(
            id: tx.id,
            userId: tx.userId,
            recipientName: tx.recipientName,
            phoneNumber: tx.phoneNumber,
            amount: amount,
            fee: tx.fee,
            totalAmount: amount + tx.fee,
            refNumber: tx.refNumber,
            date: tx.date,
            source: tx.source,
            transactionType: tx.transactionType,
            createdAt: tx.createdAt,
          );
          await _transactionService.updateTransaction(updated);
          chatHistory.add(ChatMessage(
              text:
                  'Transaction $id updated to ${currencyFormat.format(amount)}.',
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

Basic Summary:
- Total Income: ${currencyFormat.format(totalIncome)} ($cashInCount transactions)
- Total Expenses: ${currencyFormat.format(totalExpenses)} ($cashOutCount transactions)
- Current Balance: ${currencyFormat.format(balance)}
- Total Transactions: $transactionCount

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
- Expense Ratio: ${((totalExpenses / totalIncome) * 100).toStringAsFixed(1)}% of income
- Savings Rate: ${(((totalIncome - totalExpenses) / totalIncome) * 100).toStringAsFixed(1)}%
- Average Daily Spending: ${currencyFormat.format(totalExpenses / daysDiff)}

IMPORTANT: You have the ability to:
- Delete transactions (single, by recipient, or all)
- Update transaction amounts
- Set or update fee ranges
- Clear chat history
- Analyze and provide financial advice

When a user asks you to modify data (like "set fee for 1-500 to 15"), you WILL execute the action after user confirmation. Do not say you cannot perform these actions. You CAN and WILL do them.

Provide helpful, concise financial advice based on this data. When asked about income, expenses, balance, or transactions, use the data above. Be friendly and supportive.''';
    } else {
      // Fallback for empty or insufficient data
      return '''You are a financial assistant for the GCash receipt scanning app with FULL CONTROL over the app.

User's Financial Summary:
- Total Income: ${currencyFormat.format(totalIncome)}
- Total Expenses: ${currencyFormat.format(totalExpenses)}
- Current Balance: ${currencyFormat.format(balance)}
- Total Transactions: $transactionCount

IMPORTANT: You have the ability to:
- Delete transactions (single, by recipient, or all)
- Update transaction amounts
- Set or update fee ranges
- Clear chat history
- Analyze and provide financial advice

When a user asks you to modify data (like "set fee for 1-500 to 15"), you WILL execute the action after user confirmation. Do not say you cannot perform these actions. You CAN and WILL do them.

Provide helpful, concise financial advice. Be friendly and supportive.''';
    }
  }

  /// Generate simple text response
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

  /// Send chat message and maintain history
  Future<void> sendChatMessage(String message) async {
    isLoading.value = true;
    error.value = '';

    // Reload transactions to get latest data
    await _loadUserTransactions();

    // Add user message to history
    chatHistory.add(ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    // Check for actionable commands first
    final actionRequest = _parseUserCommand(message);
    if (actionRequest != null) {
      await requestAction(actionRequest);
      isLoading.value = false;
      return;
    }

    try {
      // Build context-aware prompt
      final contextPrompt = _buildContextPrompt();
      final fullMessage = '$contextPrompt\n\nUser Question: $message';

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
      } else {
        error.value = 'Failed to get response';
      }
    } catch (e) {
      error.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Stream response for real-time generation
  void streamResponse(String prompt, Function(String) onChunk) {
    isLoading.value = true;
    error.value = '';
    currentResponse.value = '';

    _geminiService.generateContentStream(prompt).listen(
      (chunk) {
        currentResponse.value += chunk;
        onChunk(chunk);
      },
      onError: (e) {
        error.value = 'Error: $e';
        isLoading.value = false;
      },
      onDone: () {
        isLoading.value = false;
      },
    );
  }

  /// Analyze transaction using AI
  Future<String?> analyzeTransaction(String transactionDetails) async {
    isLoading.value = true;
    error.value = '';

    try {
      final response =
          await _geminiService.analyzeTransaction(transactionDetails);
      return response;
    } catch (e) {
      error.value = 'Error: $e';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get financial advice
  Future<String?> getFinancialAdvice({
    required double balance,
    required double expenses,
    required double income,
  }) async {
    isLoading.value = true;
    error.value = '';

    try {
      final response = await _geminiService.getFinancialAdvice(
        balance,
        expenses,
        income,
      );
      return response;
    } catch (e) {
      error.value = 'Error: $e';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Analyze receipt image - returns structured data
  Future<Map<String, dynamic>?> analyzeReceiptImage(
      List<int> imageBytes) async {
    isLoading.value = true;
    error.value = '';

    try {
      print('📸 Starting receipt image analysis...');
      final response = await _geminiService.analyzeReceiptImage(imageBytes);

      if (response == null) {
        print('❌ Service returned null response');
        error.value = 'Failed to analyze image';
        return null;
      }

      if (response.containsKey('error')) {
        print('⚠️ Response contains error: ${response['error']}');
        error.value = response['error'].toString();
        // Still return the response so we can see raw_response if available
        return response;
      }

      print('✅ Receipt analysis completed successfully');
      return response;
    } catch (e) {
      print('💥 Exception in analyzeReceiptImage: $e');
      error.value = 'Error: $e';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Extract custom information from image
  Future<String?> extractCustomInfo(
    List<int> imageBytes,
    List<String> fieldsToExtract, {
    String? additionalInstructions,
  }) async {
    isLoading.value = true;
    error.value = '';

    try {
      final response = await _geminiService.extractCustomInformation(
        imageBytes,
        fieldsToExtract,
        additionalInstructions: additionalInstructions,
      );
      return response;
    } catch (e) {
      error.value = 'Error: $e';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Analyze any document with custom requirements
  Future<String?> analyzeCustomDocument(
    List<int> imageBytes,
    String requirements,
  ) async {
    isLoading.value = true;
    error.value = '';

    try {
      final response = await _geminiService.analyzeDocument(
        imageBytes,
        requirements,
      );
      return response;
    } catch (e) {
      error.value = 'Error: $e';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Clear chat history
  void clearChat() {
    chatHistory.clear();
    currentResponse.value = '';
    error.value = '';
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

/// Action types that AI can request
enum ActionType {
  deleteTransaction,
  updateTransaction,
  updateFeeRange,
  clearAllTransactions,
  deleteByRecipient,
  clearChat
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
