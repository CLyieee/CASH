class BankTransferModel {
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String receiptEmail;
  final double amount;
  final double bankFee;
  final String refNumber;
  final DateTime date;
  final String source; // e.g., "GCash"

  BankTransferModel({
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.receiptEmail,
    required this.amount,
    required this.bankFee,
    required this.refNumber,
    required this.date,
    this.source = 'GCash',
  });

  double get totalAmount => amount + bankFee;

  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'receiptEmail': receiptEmail,
      'amount': amount,
      'bankFee': bankFee,
      'refNumber': refNumber,
      'date': date.millisecondsSinceEpoch,
      'source': source,
      'totalAmount': totalAmount,
      'transactionType': 'bank_transfer',
    };
  }

  factory BankTransferModel.fromMap(Map<String, dynamic> map) {
    return BankTransferModel(
      bankName: map['bankName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      accountName: map['accountName'] ?? '',
      receiptEmail: map['receiptEmail'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      bankFee: (map['bankFee'] ?? 0).toDouble(),
      refNumber: map['refNumber'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      source: map['source'] ?? 'GCash',
    );
  }

  BankTransferModel copyWith({
    String? bankName,
    String? accountNumber,
    String? accountName,
    String? receiptEmail,
    double? amount,
    double? bankFee,
    String? refNumber,
    DateTime? date,
    String? source,
  }) {
    return BankTransferModel(
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      receiptEmail: receiptEmail ?? this.receiptEmail,
      amount: amount ?? this.amount,
      bankFee: bankFee ?? this.bankFee,
      refNumber: refNumber ?? this.refNumber,
      date: date ?? this.date,
      source: source ?? this.source,
    );
  }
}
