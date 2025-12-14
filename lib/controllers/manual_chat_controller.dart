import 'package:get/get.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';
import 'app_controller.dart';
import 'package:intl/intl.dart';

/// Manual chat controller - No AI, just command parsing and local responses
/// Use this if you want the chat feature without Gemini AI API calls
class ManualChatController extends GetxController {
  final TransactionService _transactionService = TransactionService();
  final AppController _appController = Get.find<AppController>();

  final RxBool isLoading = false.obs;
  final RxList<ChatMessage> chatHistory = <ChatMessage>[].obs;
  final RxString error = ''.obs;
  final Rxn<ActionRequest> pendingAction = Rxn<ActionRequest>();

  List<TransactionModel> _userTransactions = [];
  final currencyFormat =
      NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

  @override
  void onInit() {
    super.onInit();
    _loadUserTransactions();
  }

  Future<void> _loadUserTransactions() async {
    final userId = _appController.currentUserId.value;
    if (userId.isEmpty) return;
    _userTransactions = await _transactionService.getUserTransactions(userId);
    _userTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Send chat message with local processing only
  Future<void> sendChatMessage(String message) async {
    isLoading.value = true;
    error.value = '';

    await _loadUserTransactions();

    chatHistory.add(ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    final lower = message.toLowerCase().trim();

    // Show help
    if (lower == 'help' || lower.contains('what can you do')) {
      chatHistory.add(ChatMessage(
        text: _getHelpText(),
        isUser: false,
        timestamp: DateTime.now(),
      ));
      isLoading.value = false;
      return;
    }

    // Quick stats
    final quickAnswer = _buildQuickAnswer(lower);
    if (quickAnswer != null) {
      chatHistory.add(ChatMessage(
        text: quickAnswer,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      isLoading.value = false;
      return;
    }

    // Default response
    chatHistory.add(ChatMessage(
      text: _buildSummaryResponse(),
      isUser: false,
      timestamp: DateTime.now(),
    ));

    isLoading.value = false;
  }

  String _buildSummaryResponse() {
    if (_userTransactions.isEmpty) {
      return 'You have no transactions yet. Scan a receipt to get started!';
    }

    final totalIncome = _userTransactions
        .where((t) => t.transactionType == 'Cash In')
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpenses = _userTransactions
        .where((t) => t.transactionType == 'Cash Out')
        .fold<double>(0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpenses;

    return '''Here's your financial summary:

💰 Cash In: ${currencyFormat.format(totalIncome)}
💸 Cash Out: ${currencyFormat.format(totalExpenses)}
📊 Balance: ${currencyFormat.format(balance)}

Recent transactions:
${_userTransactions.take(3).map((t) => '• ${t.transactionType}: ${currencyFormat.format(t.amount)} to ${t.recipientName}').join('\n')}

Type "help" to see what I can do.''';
  }

  String? _buildQuickAnswer(String lower) {
    if (_userTransactions.isEmpty) return null;

    final totalIncome = _userTransactions
        .where((t) => t.transactionType == 'Cash In')
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpenses = _userTransactions
        .where((t) => t.transactionType == 'Cash Out')
        .fold<double>(0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpenses;

    if (lower.contains('balance')) {
      return 'Your balance is ${currencyFormat.format(balance)}';
    }
    if (lower.contains('total cash in') || lower.contains('income')) {
      return 'Total Cash In: ${currencyFormat.format(totalIncome)}';
    }
    if (lower.contains('total cash out') || lower.contains('expense')) {
      return 'Total Cash Out: ${currencyFormat.format(totalExpenses)}';
    }
    if (lower.contains('recent') || lower.contains('last')) {
      final recent = _userTransactions.take(5);
      return 'Recent transactions:\n${recent.map((t) => '• ${t.transactionType}: ${currencyFormat.format(t.amount)} to ${t.recipientName}').join('\n')}';
    }

    return null;
  }

  String _getHelpText() {
    return '''I can help you with:

📊 Check your finances:
  • "what's my balance?"
  • "total cash in"
  • "total cash out"
  • "recent transactions"

📸 Scan receipts to save transactions automatically

💡 This is manual mode - no AI processing, just quick local responses.''';
  }

  void clearChat() {
    chatHistory.clear();
    error.value = '';
  }
}

// Reuse the same models from gemini_controller
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

enum ActionType {
  deleteTransaction,
  deleteByRecipient,
  clearAllTransactions,
  setFeeRange,
  saveTransaction,
}
