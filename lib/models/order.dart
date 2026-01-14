/// Order: Represents a dining session at a table
///
/// Core Buffet Logic:
/// - Tracks headcount (adults and children) separately
/// - Stores buffet tier price at time of opening (prevents price changes affecting active sessions)
/// - Total calculated at checkout: (Headcount * BuffetPrice) + ExtraOrders
class Order {
  final int id;
  final int? tableId; // Nullable for takeaway orders
  final int startTime; // Milliseconds since epoch
  final int? endTime;
  final int adultHeadcount;
  final int childHeadcount;
  final double buffetTierPrice; // Price per person at time of opening
  final double totalAmount; // Final total calculated at checkout
  final String? paymentMethod; // 'CASH', 'QR'
  final String status; // 'OPEN', 'COMPLETED', 'CANCELLED'
  final int? promotionId;
  final double discountAmount;

  Order({
    required this.id,
    this.tableId,
    required this.startTime,
    this.endTime,
    required this.adultHeadcount,
    required this.childHeadcount,
    required this.buffetTierPrice,
    required this.totalAmount,
    this.paymentMethod,
    required this.status,
    this.promotionId,
    this.discountAmount = 0.0,
  });

  /// Create Order from database map
  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int,
      tableId: map['table_id'] as int?,
      startTime: map['start_time'] as int,
      endTime: map['end_time'] as int?,
      adultHeadcount: map['adult_headcount'] as int,
      childHeadcount: map['child_headcount'] as int,
      buffetTierPrice: (map['buffet_tier_price'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String?,
      status: map['status'] as String,
      promotionId: map['promotion_id'] as int?,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convert Order to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_id': tableId,
      'start_time': startTime,
      'end_time': endTime,
      'adult_headcount': adultHeadcount,
      'child_headcount': childHeadcount,
      'buffet_tier_price': buffetTierPrice,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'status': status,
      'promotion_id': promotionId,
      'discount_amount': discountAmount,
    };
  }

  /// Create a copy with modified fields
  Order copyWith({
    int? id,
    int? tableId,
    int? startTime,
    int? endTime,
    int? adultHeadcount,
    int? childHeadcount,
    double? buffetTierPrice,
    double? totalAmount,
    String? paymentMethod,
    String? status,
    bool clearPaymentMethod = false,
    bool clearEndTime = false,
    int? promotionId,
    bool clearPromotion = false,
    double? discountAmount,
  }) {
    return Order(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      startTime: startTime ?? this.startTime,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      adultHeadcount: adultHeadcount ?? this.adultHeadcount,
      childHeadcount: childHeadcount ?? this.childHeadcount,
      buffetTierPrice: buffetTierPrice ?? this.buffetTierPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod:
          clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
      status: status ?? this.status,
      promotionId: clearPromotion ? null : (promotionId ?? this.promotionId),
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  /// Get total headcount (adults + children)
  int get totalHeadcount => adultHeadcount + childHeadcount;

  /// Check if order is currently open
  bool get isOpen => status == 'OPEN';

  /// Check if order is completed
  bool get isCompleted => status == 'COMPLETED';

  /// Check if order is cancelled
  bool get isCancelled => status == 'CANCELLED';

  /// Calculate buffet portion of total (before extra items)
  double get buffetCharge => totalHeadcount * buffetTierPrice;

  /// Get start time as DateTime
  DateTime get startDateTime => DateTime.fromMillisecondsSinceEpoch(startTime);

  /// Get end time as DateTime (null if not ended)
  DateTime? get endDateTime =>
      endTime != null ? DateTime.fromMillisecondsSinceEpoch(endTime!) : null;

  /// Calculate duration of the session (in minutes)
  /// Returns null if session hasn't ended
  int? getDurationInMinutes() {
    if (endTime == null) return null;
    final duration = endDateTime!.difference(startDateTime);
    return duration.inMinutes;
  }
}
