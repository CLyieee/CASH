import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';

class BackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _autoBackupKey = 'auto_backup_enabled';
  static const String _lastBackupKey = 'last_backup_timestamp';
  static const String _backupsCollection = 'backups';

  // Check if auto backup is enabled
  Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupKey) ?? false;
  }

  // Enable/disable auto backup
  Future<void> setAutoBackup(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, enabled);
  }

  // Get last backup timestamp
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastBackupKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  // Create backup to Firestore (more reliable than Storage)
  Future<String> createBackup(String userId) async {
    try {
      // 1. Get all user data
      final userData = await _getUserData(userId);
      final transactions = await _getTransactions(userId);
      final settings = await _getSettings();

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 2. Create backup document in Firestore
      final backupData = {
        'version': '1.0',
        'timestamp': timestamp,
        'userId': userId,
        'userData': userData,
        'transactionCount': transactions.length,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Store metadata in backups collection
      final backupId = 'backup_$userId\_$timestamp';
      await _firestore
          .collection(_backupsCollection)
          .doc(backupId)
          .set(backupData);

      // 3. Store transactions in sub-collection (Firestore has 1MB doc limit)
      final batch = _firestore.batch();
      for (int i = 0; i < transactions.length; i++) {
        final transactionRef = _firestore
            .collection(_backupsCollection)
            .doc(backupId)
            .collection('transactions')
            .doc(transactions[i].id);
        batch.set(transactionRef, transactions[i].toMap());
      }
      await batch.commit();

      // 4. Store settings in sub-document
      await _firestore
          .collection(_backupsCollection)
          .doc(backupId)
          .collection('data')
          .doc('settings')
          .set(settings);

      // 5. Update last backup timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastBackupKey, timestamp);

      return 'Backup created successfully';
    } catch (e) {
      print('Error creating backup: $e');
      throw Exception('Failed to create backup: $e');
    }
  }

  // Restore from backup
  Future<String> restoreBackup(String userId, String backupId) async {
    try {
      // 1. Get backup metadata
      final backupDoc =
          await _firestore.collection(_backupsCollection).doc(backupId).get();

      if (!backupDoc.exists) {
        throw Exception('Backup not found');
      }

      final backupData = backupDoc.data()!;

      // 2. Validate backup
      if (backupData['userId'] != userId) {
        throw Exception('Backup does not belong to this user');
      }

      // 3. Restore user data
      if (backupData['userData'] != null) {
        await _restoreUserData(userId, backupData['userData']);
      }

      // 4. Restore transactions from sub-collection
      final transactionsSnapshot = await _firestore
          .collection(_backupsCollection)
          .doc(backupId)
          .collection('transactions')
          .get();

      final transactions =
          transactionsSnapshot.docs.map((doc) => doc.data()).toList();

      if (transactions.isNotEmpty) {
        await _restoreTransactions(transactions);
      }

      // 5. Restore settings
      final settingsDoc = await _firestore
          .collection(_backupsCollection)
          .doc(backupId)
          .collection('data')
          .doc('settings')
          .get();

      if (settingsDoc.exists) {
        await _restoreSettings(settingsDoc.data()!);
      }

      return 'Backup restored successfully';
    } catch (e) {
      print('Error restoring backup: $e');
      throw Exception('Failed to restore backup: $e');
    }
  }

  // List available backups
  Future<List<Map<String, dynamic>>> listBackups(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_backupsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final backups = <Map<String, dynamic>>[];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        backups.add({
          'id': doc.id,
          'name': doc.id,
          'timestamp': data['timestamp'],
          'created': DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
          'transactionCount': data['transactionCount'] ?? 0,
          'version': data['version'] ?? '1.0',
        });
      }

      return backups;
    } catch (e) {
      print('Error listing backups: $e');
      return [];
    }
  }

  // Delete all transaction data for user
  Future<void> deleteAllData(String userId) async {
    try {
      print('🗑️ Deleting transaction data for user: $userId');

      // Delete all transactions for this user only
      final transactionQuery = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in transactionQuery.docs) {
        await doc.reference.delete();
      }

      print('✅ Deleted ${transactionQuery.docs.length} transactions');
    } catch (e) {
      print('❌ Error deleting data: $e');
      throw Exception('Failed to delete data: $e');
    }
  }

  // Auto backup (call this periodically)
  Future<void> performAutoBackup(String userId) async {
    final isEnabled = await isAutoBackupEnabled();
    if (!isEnabled) return;

    final lastBackup = await getLastBackupTime();
    final now = DateTime.now();

    // Backup once per day
    if (lastBackup == null || now.difference(lastBackup).inDays >= 1) {
      try {
        await createBackup(userId);
        print('✅ Auto backup completed');
      } catch (e) {
        print('❌ Auto backup failed: $e');
      }
    }
  }

  // Helper: Get user data
  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Helper: Get transactions
  Future<List<TransactionModel>> _getTransactions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  // Helper: Get settings
  Future<Map<String, dynamic>> _getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final settings = <String, dynamic>{};

    for (var key in keys) {
      final value = prefs.get(key);
      if (value != null) {
        settings[key] = value;
      }
    }

    return settings;
  }

  // Helper: Restore user data
  Future<void> _restoreUserData(
      String userId, Map<String, dynamic> userData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .set(userData, SetOptions(merge: true));
    } catch (e) {
      print('Error restoring user data: $e');
      rethrow;
    }
  }

  // Helper: Restore transactions
  Future<void> _restoreTransactions(List<dynamic> transactions) async {
    try {
      final batch = _firestore.batch();

      for (var transactionData in transactions) {
        final transaction =
            TransactionModel.fromMap(transactionData, transactionData['id']);
        final ref = _firestore.collection('transactions').doc(transaction.id);
        batch.set(ref, transaction.toMap());
      }

      await batch.commit();
    } catch (e) {
      print('Error restoring transactions: $e');
      rethrow;
    }
  }

  // Helper: Restore settings
  Future<void> _restoreSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      for (var entry in settings.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is String) {
          await prefs.setString(key, value);
        } else if (value is List<String>) {
          await prefs.setStringList(key, value);
        }
      }
    } catch (e) {
      print('Error restoring settings: $e');
      rethrow;
    }
  }
}
