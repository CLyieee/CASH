class UserModel {
  final String uid;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? photoUrl;
  final String? pin;
  final DateTime createdAt;
  final DateTime lastLogin;
  final List<FeeRange> feeRanges;

  UserModel({
    required this.uid,
    required this.name,
    this.email,
    this.phoneNumber,
    this.photoUrl,
    this.pin,
    required this.createdAt,
    required this.lastLogin,
    this.feeRanges = const [],
  });

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'pin': pin,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLogin': lastLogin.millisecondsSinceEpoch,
      'feeRanges': feeRanges.map((range) => range.toMap()).toList(),
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      photoUrl: map['photoUrl'],
      pin: map['pin'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastLogin: DateTime.fromMillisecondsSinceEpoch(map['lastLogin'] ?? 0),
      feeRanges: (map['feeRanges'] as List<dynamic>?)
              ?.map((item) => FeeRange.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    String? pin,
    DateTime? createdAt,
    DateTime? lastLogin,
    List<FeeRange>? feeRanges,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      pin: pin ?? this.pin,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      feeRanges: feeRanges ?? this.feeRanges,
    );
  }
}

class FeeRange {
  final int from;
  final int to;
  final int fee;

  FeeRange({
    required this.from,
    required this.to,
    required this.fee,
  });

  Map<String, dynamic> toMap() {
    return {
      'from': from,
      'to': to,
      'fee': fee,
    };
  }

  factory FeeRange.fromMap(Map<String, dynamic> map) {
    return FeeRange(
      from: map['from'] ?? 0,
      to: map['to'] ?? 0,
      fee: map['fee'] ?? 0,
    );
  }
}
