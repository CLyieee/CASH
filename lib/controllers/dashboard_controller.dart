import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
  var selectedPeriod = 'Daily'.obs;

  void setPeriod(String period) {
    selectedPeriod.value = period;
  }

  Map<String, double> getChartData() {
    if (recentTransactions.isEmpty) return {};

    final now = DateTime.now();
    Map<String, double> data = {};

    if (selectedPeriod.value == 'Daily') {
      // Last 7 days
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final key = DateFormat('EEE').format(date);
        data[key] = 0.0;
      }

      for (var transaction in recentTransactions) {
        final daysDiff = now.difference(transaction.createdAt).inDays;
        if (daysDiff < 7) {
          final key = DateFormat('EEE').format(transaction.createdAt);
          data[key] = (data[key] ?? 0) + transaction.fee;
        }
      }
    } else if (selectedPeriod.value == 'Weekly') {
      // Last 4 weeks
      for (int i = 3; i >= 0; i--) {
        final key = 'W${4 - i}';
        data[key] = 0.0;
      }

      for (var transaction in recentTransactions) {
        final weeksDiff =
            (now.difference(transaction.createdAt).inDays / 7).floor();
        if (weeksDiff < 4) {
          final key = 'W${4 - weeksDiff}';
          data[key] = (data[key] ?? 0) + transaction.fee;
        }
      }
    } else {
      // Last 6 months
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final key = DateFormat('MMM').format(month);
        data[key] = 0.0;
      }

      for (var transaction in recentTransactions) {
        final monthsDiff = (now.year - transaction.createdAt.year) * 12 +
            (now.month - transaction.createdAt.month);
        if (monthsDiff < 6) {
          final key = DateFormat('MMM').format(transaction.createdAt);
          data[key] = (data[key] ?? 0) + transaction.fee;
        }
      }
    }

    return data;
  }

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
