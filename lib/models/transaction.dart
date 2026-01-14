/// Transaction: Represents a completed payment transaction
///
/// Separates payment history from order data for better reporting
class Transaction {
  final int id;
  final int orderId;
  final double totalAmount;
  final String paymentMethod; // 'CASH', 'QR'
  final double? amountReceived; // For cash payments
  final double? changeAmount; // Calculated change for cash payments
  final int transactionTime; // Milliseconds since epoch

  Transaction({
    required this.id,
    required this.orderId,
    required this.totalAmount,
    required this.paymentMethod,
    this.amountReceived,
    this.changeAmount,
    required this.transactionTime,
  });

  /// Create Transaction from database map
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int,
      orderId: map['order_id'] as int,
      totalAmount: (map['total_amount'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String,
      amountReceived: map['amount_received'] as double?,
      changeAmount: map['change_amount'] as double?,
      transactionTime: map['transaction_time'] as int,
    );
  }

  /// Convert Transaction to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'amount_received': amountReceived,
      'change_amount': changeAmount,
      'transaction_time': transactionTime,
    };
  }

  /// Create a copy with modified fields
  Transaction copyWith({
    int? id,
    int? orderId,
    double? totalAmount,
    String? paymentMethod,
    double? amountReceived,
    double? changeAmount,
    int? transactionTime,
  }) {
    return Transaction(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountReceived: amountReceived ?? this.amountReceived,
      changeAmount: changeAmount ?? this.changeAmount,
      transactionTime: transactionTime ?? this.transactionTime,
    );
  }

  /// Check if payment was made with cash
  bool get isCashPayment => paymentMethod == 'CASH';

  /// Check if payment was made with QR
  bool get isQRPayment => paymentMethod == 'QR';

  /// Get transaction time as DateTime
  DateTime get transactionDateTime =>
      DateTime.fromMillisecondsSinceEpoch(transactionTime);

  /// Get formatted total amount string
  String get formattedTotal => '\$${totalAmount.toStringAsFixed(2)}';

  /// Get formatted amount received string
  String? get formattedAmountReceived =>
      amountReceived != null ? '\$${amountReceived!.toStringAsFixed(2)}' : null;

  /// Get formatted change amount string
  String? get formattedChangeAmount =>
      changeAmount != null ? '\$${changeAmount!.toStringAsFixed(2)}' : null;
}
