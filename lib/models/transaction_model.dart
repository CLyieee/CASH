class TransactionModel {
  final String id;
  final String userId;
  final String recipientName;
  final String phoneNumber;
  final double amount;
  final double fee;
  final double totalAmount;
  final String refNumber;
  final DateTime date;
  final String source;
  final String transactionType; // 'Cash In' or 'Cash Out'
  final DateTime createdAt;
  final double separateFee; // Fee paid separately (not included in amount)

  TransactionModel({
    required this.id,
    required this.userId,
    required this.recipientName,
    required this.phoneNumber,
    required this.amount,
    required this.fee,
    required this.totalAmount,
    required this.refNumber,
    required this.date,
    required this.source,
    required this.transactionType,
    required this.createdAt,
    this.separateFee = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'fee': fee,
      'totalAmount': totalAmount,
      'refNumber': refNumber,
      'date': date.millisecondsSinceEpoch,
      'source': source,
      'transactionType': transactionType,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'separateFee': separateFee,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      recipientName: map['recipientName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      fee: (map['fee'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      refNumber: map['refNumber'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      source: map['source'] ?? '',
      transactionType: map['transactionType'] ?? 'Cash In',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      separateFee: (map['separateFee'] ?? 0).toDouble(),
    );
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? recipientName,
    String? phoneNumber,
    double? amount,
    double? fee,
    double? totalAmount,
    String? refNumber,
    DateTime? date,
    String? source,
    String? transactionType,
    DateTime? createdAt,
    double? separateFee,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      totalAmount: totalAmount ?? this.totalAmount,
      refNumber: refNumber ?? this.refNumber,
      date: date ?? this.date,
      source: source ?? this.source,
      transactionType: transactionType ?? this.transactionType,
      createdAt: createdAt ?? this.createdAt,
      separateFee: separateFee ?? this.separateFee,
    );
  }
}
