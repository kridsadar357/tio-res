/// Promotion: Represents a discount/promotion
class Promotion {
  final int? id;
  final String name;
  final String discountType; // 'PERCENT' or 'FIXED'
  final double discountValue;
  final int? startDate; // milliseconds since epoch
  final int? endDate;
  final bool isActive;

  Promotion({
    this.id,
    required this.name,
    required this.discountType,
    required this.discountValue,
    this.startDate,
    this.endDate,
    this.isActive = true,
  });

  factory Promotion.fromMap(Map<String, dynamic> map) {
    return Promotion(
      id: map['id'] as int?,
      name: map['name'] as String,
      discountType: map['discount_type'] as String,
      discountValue: (map['discount_value'] as num).toDouble(),
      startDate: map['start_date'] as int?,
      endDate: map['end_date'] as int?,
      isActive: (map['is_active'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'discount_type': discountType,
      'discount_value': discountValue,
      'start_date': startDate,
      'end_date': endDate,
      'is_active': isActive ? 1 : 0,
    };
  }

  Promotion copyWith({
    int? id,
    String? name,
    String? discountType,
    double? discountValue,
    int? startDate,
    int? endDate,
    bool? isActive,
  }) {
    return Promotion(
      id: id ?? this.id,
      name: name ?? this.name,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Check if promotion is currently valid
  bool get isCurrentlyValid {
    if (!isActive) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (startDate != null && now < startDate!) return false;
    if (endDate != null && now > endDate!) return false;
    return true;
  }

  /// Get formatted discount string
  String get formattedDiscount {
    if (discountType == 'PERCENT') {
      return '${discountValue.toStringAsFixed(0)}%';
    } else {
      return '\$${discountValue.toStringAsFixed(2)}';
    }
  }
}
