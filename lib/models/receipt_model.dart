class ReceiptModel {
  final String recipientName;
  final String phoneNumber;
  final double amount;
  final String refNumber;
  final DateTime date;
  final double fee;
  final String source; // e.g., "GCash", "Palawan", etc.
  final String transactionType; // "money_transfer" or "bank_transfer"
  final String? accountNumber; // For bank transfers (masked account number)
  final String?
      receiptEmail; // For bank transfers (email where receipt was sent)

  ReceiptModel({
    required this.recipientName,
    required this.phoneNumber,
    required this.amount,
    required this.refNumber,
    required this.date,
    required this.fee,
    this.source = 'GCash',
    this.transactionType = 'money_transfer',
    this.accountNumber,
    this.receiptEmail,
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
      'transactionType': transactionType,
      'accountNumber': accountNumber,
      'receiptEmail': receiptEmail,
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
      transactionType: map['transactionType'] ?? 'money_transfer',
      accountNumber: map['accountNumber'],
      receiptEmail: map['receiptEmail'],
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
    String? transactionType,
    String? accountNumber,
    String? receiptEmail,
  }) {
    return ReceiptModel(
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      amount: amount ?? this.amount,
      refNumber: refNumber ?? this.refNumber,
      date: date ?? this.date,
      fee: fee ?? this.fee,
      source: source ?? this.source,
      transactionType: transactionType ?? this.transactionType,
      accountNumber: accountNumber ?? this.accountNumber,
      receiptEmail: receiptEmail ?? this.receiptEmail,
    );
  }
}
