import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  // Create or update user data
  Future<void> saveUser(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error saving user: $e');
      rethrow;
    }
  }

  // Get user data by UID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      rethrow;
    }
  }

  // Check if user exists
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  // Update user name
  Future<void> updateUserName(String uid, String name) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'name': name,
      });
    } catch (e) {
      print('Error updating user name: $e');
      rethrow;
    }
  }

  // Update user phone number
  Future<void> updateUserPhone(String uid, String phoneNumber) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'phoneNumber': phoneNumber,
      });
    } catch (e) {
      print('Error updating phone number: $e');
      rethrow;
    }
  }

  // Update user PIN
  Future<void> updateUserPin(String uid, String pin) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'pin': pin,
      });
    } catch (e) {
      print('Error updating PIN: $e');
      rethrow;
    }
  }

  // Update fee ranges
  Future<void> updateFeeRanges(String uid, List<FeeRange> feeRanges) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'feeRanges': feeRanges.map((range) => range.toMap()).toList(),
      });
    } catch (e) {
      print('Error updating fee ranges: $e');
      rethrow;
    }
  }

  // Update last login timestamp
  Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'lastLogin': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error updating last login: $e');
      rethrow;
    }
  }

  // Delete user data
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // Stream user data (real-time updates)
  Stream<UserModel?> streamUser(String uid) {
    return _firestore
        .collection(_usersCollection)
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  // Search users by name
  Future<List<UserModel>> searchUsersByName(String name) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('name', isGreaterThanOrEqualTo: name)
          .where('name', isLessThanOrEqualTo: name + '\uf8ff')
          .limit(10)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Get all users (admin function)
  Future<List<UserModel>> getAllUsers({int limit = 50}) async {
    try {
      final querySnapshot =
          await _firestore.collection(_usersCollection).limit(limit).get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }
}
