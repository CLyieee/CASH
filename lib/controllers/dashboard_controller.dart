import 'package:get/get.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class DashboardController extends GetxController {
  final TransactionService _transactionService = TransactionService();

  var totalCashIn = 0.0.obs;
  var totalCashOut = 0.0.obs;
  var totalFees = 0.0.obs;
  var totalTransactions = 0.obs;
  var recentTransactions = <TransactionModel>[].obs;
  var sourceBreakdown = <String, double>{}.obs;
  var isLoading = false.obs;

  Future<void> loadDashboardData(String userId) async {
    try {
      isLoading.value = true;

      final stats = await _transactionService.getTransactionStats(userId);

      totalCashIn.value = stats['totalCashIn'] ?? 0.0;
      totalCashOut.value = stats['totalCashOut'] ?? 0.0;
      totalFees.value = stats['totalFees'] ?? 0.0;
      totalTransactions.value = stats['totalTransactions'] ?? 0;
      recentTransactions.value = stats['recentTransactions'] ?? [];
      sourceBreakdown.value =
          Map<String, double>.from(stats['sourceBreakdown'] ?? {});

      isLoading.value = false;
    } catch (e) {
      print('Error loading dashboard data: $e');
      isLoading.value = false;
    }
  }

  void streamDashboardData(String userId) {
    _transactionService.streamUserTransactions(userId).listen((transactions) {
      // Recalculate stats from transactions
      double cashIn = 0;
      double cashOut = 0;
      double fees = 0;
      Map<String, double> sources = {};

      for (var transaction in transactions) {
        if (transaction.transactionType == 'Cash In') {
          cashIn += transaction.amount;
        } else {
          cashOut += transaction.amount;
        }
        fees += transaction.fee;

        sources[transaction.source] =
            (sources[transaction.source] ?? 0) + transaction.amount;
      }

      totalCashIn.value = cashIn;
      totalCashOut.value = cashOut;
      totalFees.value = fees;
      totalTransactions.value = transactions.length;
      recentTransactions.value = transactions.take(10).toList();
      sourceBreakdown.value = sources;
    });
  }
}
