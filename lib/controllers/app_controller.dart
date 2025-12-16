deimport 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class AppController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

  var userName = ''.obs;
  var phoneNumber = ''.obs;
  var photoUrl = ''.obs;
  var pin = ''.obs;
  var isLoading = false.obs;
  var currentUserId = ''.obs;

  // Fee ranges
  var feeRanges = <FeeRange>[
    FeeRange(from: 1, to: 500, fee: 5),
    FeeRange(from: 501, to: 1000, fee: 10),
    FeeRange(from: 1001, to: 5000, fee: 20),
  ].obs;

  // Load user data from Firestore
  Future<void> loadUserData(String uid) async {
    try {
      isLoading.value = true;
      currentUserId.value = uid;

      final user = await _firestoreService.getUser(uid);

      if (user != null) {
        userName.value = user.name;
        phoneNumber.value = user.phoneNumber ?? '';
        photoUrl.value = user.photoUrl ?? '';
        pin.value = user.pin ?? '';

        if (user.feeRanges.isNotEmpty) {
          feeRanges.value = user.feeRanges;
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Save user data to Firestore
  Future<void> saveUserData() async {
    if (currentUserId.value.isEmpty) return;

    try {
      isLoading.value = true;

      final user = UserModel(
        uid: currentUserId.value,
        name: userName.value,
        phoneNumber: phoneNumber.value.isNotEmpty ? phoneNumber.value : null,
        photoUrl: photoUrl.value.isNotEmpty ? photoUrl.value : null,
        pin: pin.value.isNotEmpty ? pin.value : null,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        feeRanges: feeRanges.toList(),
      );

      await _firestoreService.saveUser(user);
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  void setUserName(String name) {
    userName.value = name;
    if (currentUserId.value.isNotEmpty) {
      _firestoreService.updateUserName(currentUserId.value, name);
    }
  }

  void setPhoneNumber(String phone) {
    phoneNumber.value = phone;
    if (currentUserId.value.isNotEmpty) {
      _firestoreService.updateUserPhone(currentUserId.value, phone);
    }
  }

  void setPhotoUrl(String url) {
    photoUrl.value = url;
    if (currentUserId.value.isNotEmpty) {
      _firestoreService.updateUserPhotoUrl(currentUserId.value, url);
    }
  }

  void setPin(String pinCode) {
    pin.value = pinCode;
    if (currentUserId.value.isNotEmpty) {
      _firestoreService.updateUserPin(currentUserId.value, pinCode);
    }
  }

  void addFeeRange(FeeRange range) {
    feeRanges.add(range);
    if (currentUserId.value.isNotEmpty) {
      _firestoreService.updateFeeRanges(
          currentUserId.value, feeRanges.toList());
    }
  }

  void removeFeeRange(int index) {
    if (feeRanges.length > 1) {
      feeRanges.removeAt(index);
      if (currentUserId.value.isNotEmpty) {
        _firestoreService.updateFeeRanges(
            currentUserId.value, feeRanges.toList());
      }
    }
  }

  void updateFeeRange(int index, FeeRange range) {
    feeRanges[index] = range;
    if (currentUserId.value.isNotEmpty) {
      _firestoreService.updateFeeRanges(
          currentUserId.value, feeRanges.toList());
    }
  }

  double getFeeForAmount(double amount) {
    for (var range in feeRanges) {
      if (amount >= range.from && amount <= range.to) {
        return range.fee.toDouble();
      }
    }
    return 0.0;
  }

  @override
  void onClose() {
    // Clean up resources when controller is disposed
    // GetX automatically calls onClose() when controller is removed
    super.onClose();
  }
}
