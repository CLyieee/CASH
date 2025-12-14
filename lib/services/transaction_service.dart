import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _transactionsCollection = 'transactions';

  // Get current user ID
  String getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    return user.uid;
  }

  // Add transaction (alias for saveTransaction)
  Future<void> addTransaction(TransactionModel transaction) async {
    return saveTransaction(transaction);
  }

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
      double availableFunds = 0;
      Map<String, double> sourceBreakdown = {};

      for (var transaction in transactions) {
        if (transaction.transactionType == 'Cash In') {
          totalCashIn += transaction.amount;
          // Available funds increases with cash in (full amount, no fee deduction)
          availableFunds += transaction.amount;
        } else {
          totalCashOut += transaction.amount;
          // Available funds decreases with cash out (amount + fee)
          availableFunds -= transaction.amount;
          availableFunds -= transaction.fee;
        }
        totalFees += transaction.fee;

        // Source breakdown
        sourceBreakdown[transaction.source] =
            (sourceBreakdown[transaction.source] ?? 0) + transaction.amount;
      }

      // Ensure available funds is never negative
      if (availableFunds < 0) {
        availableFunds = 0;
      }

      return {
        'totalCashIn': totalCashIn,
        'totalCashOut': totalCashOut,
        'totalFees': totalFees,
        'availableFunds': availableFunds,
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
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Check if reference number already exists for a user
  Future<bool> isReferenceNumberDuplicate(
    String userId,
    String refNumber, {
    String? excludeTransactionId,
  }) async {
    try {
      if (refNumber.trim().isEmpty) return false;

      final querySnapshot = await _firestore
          .collection(_transactionsCollection)
          .where('userId', isEqualTo: userId)
          .where('refNumber', isEqualTo: refNumber.trim())
          .get();

      // If excluding a transaction (for updates), filter it out
      if (excludeTransactionId != null) {
        return querySnapshot.docs.any((doc) => doc.id != excludeTransactionId);
      }

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking duplicate reference: $e');
      return false;
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
