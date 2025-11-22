import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/gemini_service.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';
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
  
  List<TransactionModel> _userTransactions = [];
  final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);
  
  @override
  void onInit() {
    super.onInit();
    _loadUserTransactions();
  }
  
  Future<void> _loadUserTransactions() async {
    try {
      final userId = _appController.currentUserId.value;
      if (userId.isNotEmpty) {
        _userTransactions = await _transactionService.getUserTransactions(userId);
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
    
    // Recent transactions summary
    final recentTransactions = _userTransactions
        .take(5)
        .map((t) => '${t.transactionType}: ${currencyFormat.format(t.amount)} to ${t.recipientName} on ${DateFormat('MMM dd').format(t.createdAt)}')
        .join('; ');
    
    return '''You are a financial assistant for the GCash receipt scanning app.

User's Financial Summary:
- Total Income: ${currencyFormat.format(totalIncome)}
- Total Expenses: ${currencyFormat.format(totalExpenses)}
- Current Balance: ${currencyFormat.format(balance)}
- Total Transactions: $transactionCount

Recent Transactions:
$recentTransactions

Provide helpful, concise financial advice based on this data. When asked about income, expenses, balance, or transactions, use the data above. Be friendly and supportive.''';
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
