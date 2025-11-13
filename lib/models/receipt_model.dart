class ReceiptModel {
  final String recipientName;
  final String phoneNumber;
  final double amount;
  final String refNumber;
  final DateTime date;
  final double fee;
  final String source; // e.g., "GCash", "Palawan", etc.

  ReceiptModel({
    required this.recipientName,
    required this.phoneNumber,
    required this.amount,
    required this.refNumber,
    required this.date,
    required this.fee,
    this.source = 'GCash',
  });

  double get totalAmount => amount + fee;

  Map<String, dynamic> toMap() {
    return {
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'refNumber': refNumber,
      'date': date.millisecondsSinceEpoch,
      'fee': fee,
      'source': source,
      'totalAmount': totalAmount,
    };
  }

  factory ReceiptModel.fromMap(Map<String, dynamic> map) {
    return ReceiptModel(
      recipientName: map['recipientName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      refNumber: map['refNumber'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      fee: (map['fee'] ?? 0).toDouble(),
      source: map['source'] ?? 'GCash',
    );
  }

  ReceiptModel copyWith({
    String? recipientName,
    String? phoneNumber,
    double? amount,
    String? refNumber,
    DateTime? date,
    double? fee,
    String? source,
  }) {
    return ReceiptModel(
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      amount: amount ?? this.amount,
      refNumber: refNumber ?? this.refNumber,
      date: date ?? this.date,
      fee: fee ?? this.fee,
      source: source ?? this.source,
    );
  }
}
