/// OrderItem: Represents an item that has been ordered to a table
///
/// Key feature:
/// - priceAtMoment: Snapshots the price at the time of ordering
///   This prevents future price changes from affecting historical orders
class OrderItem {
  final int id;
  final int orderId;
  final int menuItemId;
  final int quantity;
  final double priceAtMoment; // Price when item was added
  final String menuItemName; // Name of the menu item (joined from menu_items table)

  OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.quantity,
    required this.priceAtMoment,
    this.menuItemName = '',
  });

  /// Create OrderItem from database map
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as int,
      orderId: map['order_id'] as int,
      menuItemId: map['menu_item_id'] as int,
      quantity: map['quantity'] as int,
      priceAtMoment: (map['price_at_moment'] as num).toDouble(),
      menuItemName: (map['menu_item_name'] as String?) ?? '',
    );
  }

  /// Convert OrderItem to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'menu_item_id': menuItemId,
      'quantity': quantity,
      'price_at_moment': priceAtMoment,
    };
  }

  /// Create a copy with modified fields
  OrderItem copyWith({
    int? id,
    int? orderId,
    int? menuItemId,
    int? quantity,
    double? priceAtMoment,
    String? menuItemName,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      menuItemId: menuItemId ?? this.menuItemId,
      quantity: quantity ?? this.quantity,
      priceAtMoment: priceAtMoment ?? this.priceAtMoment,
      menuItemName: menuItemName ?? this.menuItemName,
    );
  }

  /// Calculate total price for this item (quantity * price)
  double get totalPrice => quantity * priceAtMoment;

  /// Check if item has an extra charge
  bool get hasExtraCharge => priceAtMoment > 0;

  /// Get formatted total price string
  String get formattedTotal => '\$${totalPrice.toStringAsFixed(2)}';

  /// Get formatted unit price string
  String get formattedUnitPrice => '\$${priceAtMoment.toStringAsFixed(2)}';
}
