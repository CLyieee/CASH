import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _transactionsCollection = 'transactions';

  // Save transaction
  Future<void> saveTransaction(TransactionModel transaction) async {
    try {
      await _firestore
          .collection(_transactionsCollection)
          .doc(transaction.id)
          .set(transaction.toMap());
    } catch (e) {
      print('Error saving transaction: $e');
      rethrow;
    }
  }

  // Get user transactions
  Future<List<TransactionModel>> getUserTransactions(String userId,
      {int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_transactionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  // Get transactions by type
  Future<List<TransactionModel>> getTransactionsByType(
    String userId,
    String transactionType, {
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_transactionsCollection)
          .where('userId', isEqualTo: userId)
          .where('transactionType', isEqualTo: transactionType)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting transactions by type: $e');
      return [];
    }
  }

  // Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStats(String userId) async {
    try {
      final transactions = await getUserTransactions(userId, limit: 1000);

      double totalCashIn = 0;
      double totalCashOut = 0;
      double totalFees = 0;
      Map<String, double> sourceBreakdown = {};

      for (var transaction in transactions) {
        if (transaction.transactionType == 'Cash In') {
          totalCashIn += transaction.amount;
        } else {
          totalCashOut += transaction.amount;
        }
        totalFees += transaction.fee;

        // Source breakdown
        sourceBreakdown[transaction.source] =
            (sourceBreakdown[transaction.source] ?? 0) + transaction.amount;
      }

      return {
        'totalCashIn': totalCashIn,
        'totalCashOut': totalCashOut,
        'totalFees': totalFees,
        'totalTransactions': transactions.length,
        'sourceBreakdown': sourceBreakdown,
        'recentTransactions': transactions.take(10).toList(),
      };
    } catch (e) {
      print('Error getting transaction stats: $e');
      return {
        'totalCashIn': 0.0,
        'totalCashOut': 0.0,
        'totalFees': 0.0,
        'totalTransactions': 0,
        'sourceBreakdown': {},
        'recentTransactions': [],
      };
    }
  }

  // Stream user transactions (real-time)
  Stream<List<TransactionModel>> streamUserTransactions(String userId) {
    return _firestore
        .collection(_transactionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Update transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _firestore
          .collection(_transactionsCollection)
          .doc(transaction.id)
          .update(transaction.toMap());
    } catch (e) {
      print('Error updating transaction: $e');
      rethrow;
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .delete();
    } catch (e) {
      print('Error deleting transaction: $e');
      rethrow;
    }
  }
}
