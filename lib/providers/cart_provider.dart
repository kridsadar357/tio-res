import 'package:flutter_riverpod/flutter_riverpod.dart';

/// CartItem: Represents an item in the temporary shopping cart
/// Used before saving to the database order
class CartItem {
  final String menuItemId;
  final String name;
  final double price;
  int quantity;
  final String? imagePath;

  CartItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imagePath,
  });

  /// Calculate total price for this cart item
  double get totalPrice => price * quantity;

  /// Check if this is a buffet included item (price == 0)
  bool get isBuffetItem => price == 0;

  /// Get formatted price display
  String get formattedPrice => isBuffetItem ? 'Included' : '\$${price.toStringAsFixed(2)}';

  /// Create a copy with modified quantity
  CartItem copyWith({int? quantity}) {
    return CartItem(
      menuItemId: menuItemId,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      imagePath: imagePath,
    );
  }
}

/// CartProvider: Manages temporary cart state before saving to database
/// 
/// Logic:
/// - Check if item exists in cart → increment quantity
/// - If item doesn't exist → add new entry
/// - Decrement quantity or remove when quantity reaches 0
/// - Calculate running subtotal
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  /// Add item to cart
  /// If item exists, increment quantity; otherwise, add new entry
  void addItem(String menuItemId, String name, double price, {String? imagePath}) {
    final existingIndex = state.indexWhere(
      (item) => item.menuItemId == menuItemId,
    );

    if (existingIndex != -1) {
      // Item exists, increment quantity
      final existingItem = state[existingIndex];
      state = [
        ...state.sublist(0, existingIndex),
        existingItem.copyWith(quantity: existingItem.quantity + 1),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      // Item doesn't exist, add new entry
      state = [
        ...state,
        CartItem(
          menuItemId: menuItemId,
          name: name,
          price: price,
          quantity: 1,
          imagePath: imagePath,
        ),
      ];
    }
  }

  /// Remove one quantity of item
  /// If quantity reaches 0, remove item entirely
  void removeItem(String menuItemId) {
    final existingIndex = state.indexWhere(
      (item) => item.menuItemId == menuItemId,
    );

    if (existingIndex == -1) return;

    final existingItem = state[existingIndex];

    if (existingItem.quantity > 1) {
      // Decrement quantity
      state = [
        ...state.sublist(0, existingIndex),
        existingItem.copyWith(quantity: existingItem.quantity - 1),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      // Remove item entirely
      state = [
        ...state.sublist(0, existingIndex),
        ...state.sublist(existingIndex + 1),
      ];
    }
  }

  /// Remove all quantities of item (delete from cart)
  void deleteItem(String menuItemId) {
    state = state.where((item) => item.menuItemId != menuItemId).toList();
  }

  /// Clear all items from cart
  void clearCart() {
    state = [];
  }

  /// Get item by menuItemId
  CartItem? getItem(String menuItemId) {
    try {
      return state.firstWhere((item) => item.menuItemId == menuItemId);
    } catch (e) {
      return null;
    }
  }

  /// Get item quantity
  int getItemQuantity(String menuItemId) {
    final item = getItem(menuItemId);
    return item?.quantity ?? 0;
  }

  /// Calculate cart subtotal
  double get subtotal {
    return state.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Get total number of items in cart
  int get totalItems {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Get number of unique items
  int get uniqueItemCount => state.length;

  /// Check if cart is empty
  bool get isEmpty => state.isEmpty;

  /// Check if cart has items
  bool get isNotEmpty => state.isNotEmpty;
}

/// Provider for cart state
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
