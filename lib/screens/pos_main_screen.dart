import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/menu_category.dart';
import '../models/menu_item.dart';
import '../models/table_model.dart';
import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../services/database_helper.dart';
import '../widgets/menu_item_image.dart';
import 'bluetooth_printer_screen.dart';

/// POSMainScreen: Core POS interface for selecting food items
///
/// Layout: Master-Detail / Split-View for Tablet Landscape
///
/// Left Side (Flex: 2/3): The Menu Grid
/// - Top: Horizontal category chips/tabs for filtering
/// - Body: GridView displaying MenuItem cards
///
/// Right Side (Flex: 1/3): The Order Summary Panel
/// - Header: Table Number & Current Headcount
/// - Body: List of items in cart with Quantity +/- controls
/// - Footer: Total Amount & "Confirm Order" button
class POSMainScreen extends ConsumerStatefulWidget {
  final TableModel table;
  final Order order;

  const POSMainScreen({
    super.key,
    required this.table,
    required this.order,
  });

  @override
  ConsumerState<POSMainScreen> createState() => _POSMainScreenState();
}

class _POSMainScreenState extends ConsumerState<POSMainScreen> {
  int _selectedCategoryId = 1;
  final ScrollController _categoryScrollController = ScrollController();
  final ScrollController _itemsScrollController = ScrollController();
  final ScrollController _cartScrollController = ScrollController();

  List<MenuItem> _filteredItems = [];
  List<MenuCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load categories
      final categories = await DatabaseHelper().getAllCategories();
      if (mounted && categories.isNotEmpty) {
        setState(() {
          _categories = categories;
          _selectedCategoryId = categories.first.id ?? 0;
        });
      }

      // Load items for selected category
      await _loadItemsForCategory(_selectedCategoryId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadItemsForCategory(int categoryId) async {
    try {
      final items = await DatabaseHelper().getMenuItemsByCategory(categoryId);
      if (mounted) {
        setState(() => _filteredItems = items);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading items: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // LEFT SIDE (2/3): Menu Grid
            Expanded(
              flex: 2,
              child: _buildMenuSection(),
            ),
            // Vertical Divider
            VerticalDivider(
                width: 1.w, thickness: 1, color: Colors.grey.shade300),
            // RIGHT SIDE (1/3): Order Summary Panel
            Expanded(
              flex: 1,
              child: _buildOrderSummaryPanel(),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MENU SECTION (LEFT SIDE) ====================

  /// Build the left side menu section
  Widget _buildMenuSection() {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Top: Category Chips
          _buildCategoryChips(),
          const Divider(height: 1),
          // Body: Menu Items Grid
          Expanded(
            child: _buildMenuItemsGrid(),
          ),
        ],
      ),
    );
  }

  /// Build horizontal scrollable category chips at the top
  Widget _buildCategoryChips() {
    return Container(
      height: 80.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: ListView.builder(
        controller: _categoryScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category.id == _selectedCategoryId;

          return Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: FilterChip(
              label: Text(category.name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategoryId = category.id ?? 0);
                  _loadItemsForCategory(category.id ?? 0);
                }
              },
              selectedColor: Colors.deepOrange.shade100,
              checkmarkColor: Colors.deepOrange,
              labelStyle: TextStyle(
                fontSize: 14.sp,
                color: isSelected
                    ? Colors.deepOrange.shade900
                    : Colors.grey.shade700,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              side: BorderSide(
                color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build menu items grid using SliverGridDelegate
  Widget _buildMenuItemsGrid() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 64.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              'No items in this category',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: GridView.builder(
        controller: _itemsScrollController,
        // Using SliverGridDelegateWithMaxCrossAxisExtent for responsive cards
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200.w, // Cards resize gracefully
          mainAxisSpacing: 16.h,
          crossAxisSpacing: 16.w,
          childAspectRatio: 0.85,
        ),
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return _buildMenuItemCard(item);
        },
      ),
    );
  }

  /// Build a single menu item card
  Widget _buildMenuItemCard(MenuItem item) {
    final cart = ref.watch(cartProvider);
    final cartItem = _getCartItem(cart, item.id.toString());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () => _handleItemTap(item),
        borderRadius: BorderRadius.circular(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top: Image (flex 3)
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Image or placeholder
                  MenuItemImage.card(imagePath: item.imagePath),
                  // Quantity badge if in cart
                  if (cartItem != null)
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          '${cartItem.quantity}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Buffet indicator
                  if (item.price == 0)
                    Positioned(
                      top: 8.h,
                      left: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'Buffet',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Middle & Bottom: Details (flex 2)
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Item name
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Price or included indicator
                    Row(
                      children: [
                        if (item.price > 0) ...[
                          Text(
                            '\$${item.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ] else ...[
                          Icon(
                            Icons.check_circle_outline,
                            size: 16.sp,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Included',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const Spacer(),
                        // Add icon
                        Icon(
                          Icons.add_circle,
                          size: 24.sp,
                          color: Colors.deepOrange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get cart item from cart list
  CartItem? _getCartItem(List<CartItem> cart, String menuItemId) {
    try {
      return cart.firstWhere((item) => item.menuItemId == menuItemId);
    } catch (e) {
      return null;
    }
  }

  /// Handle item tap - add to cart
  void _handleItemTap(MenuItem item) {
    ref.read(cartProvider.notifier).addItem(
          item.id.toString(),
          item.name,
          item.price,
          imagePath: item.imagePath,
        );

    // Optional: Haptic feedback
    // HapticFeedback.lightImpact();
  }

  // ==================== ORDER SUMMARY PANEL (RIGHT SIDE) ====================

  /// Build the right side order summary panel
  Widget _buildOrderSummaryPanel() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header: Table Number & Headcount
          _buildOrderHeader(),
          const Divider(height: 1),
          // Body: Cart items list
          Expanded(
            child: _buildCartItemsList(),
          ),
          const Divider(height: 1),
          // Footer: Total & Confirm Order button
          _buildOrderFooter(),
        ],
      ),
    );
  }

  /// Build order header with table info
  Widget _buildOrderHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepOrange.shade400,
            Colors.deepOrange.shade600,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table number and printer button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.table_restaurant,
                    size: 24.sp,
                    color: Colors.white,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    widget.table.tableName,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              // Printer settings button
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BluetoothPrinterScreen(),
                  ),
                ),
                tooltip: 'Printer Settings',
                color: Colors.white,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Headcount info
          Row(
            children: [
              Icon(
                Icons.people,
                size: 18.sp,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              SizedBox(width: 8.w),
              Text(
                '${widget.order.adultHeadcount} Adults + ${widget.order.childHeadcount} Children',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Total: ${widget.order.totalHeadcount} @ \$${widget.order.buffetTierPrice.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// Build cart items list with quantity controls
  Widget _buildCartItemsList() {
    final cartItems = ref.watch(cartProvider);

    if (cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64.sp,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16.h),
            Text(
              'Cart is empty',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Tap items on the left to add',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _cartScrollController,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final item = cartItems[index];
        return _buildCartItemTile(item);
      },
    );
  }

  /// Build a single cart item tile with quantity controls
  Widget _buildCartItemTile(CartItem item) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          children: [
            // Thumbnail
            MenuItemImage.listItem(imagePath: item.imagePath),
            SizedBox(width: 12.w),
            // Item name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item.formattedPrice,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: item.isBuffetItem
                          ? Colors.green.shade600
                          : Colors.deepOrange.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Quantity controls
            Column(
              children: [
                // Quantity display
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${item.quantity}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                // Quantity buttons
                Row(
                  children: [
                    // Remove button
                    InkWell(
                      onTap: () => _decrementQuantity(item),
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 18.sp,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Add button
                    InkWell(
                      onTap: () => _incrementQuantity(item),
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          size: 18.sp,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Increment quantity of cart item
  void _incrementQuantity(CartItem item) {
    ref.read(cartProvider.notifier).addItem(
          item.menuItemId,
          item.name,
          item.price,
          imagePath: item.imagePath,
        );
  }

  /// Decrement quantity of cart item
  void _decrementQuantity(CartItem item) {
    ref.read(cartProvider.notifier).removeItem(item.menuItemId);
  }

  /// Build order footer with total and confirm button
  Widget _buildOrderFooter() {
    final cart = ref.watch(cartProvider);
    final buffetCharge = widget.order.buffetCharge;
    final cartSubtotal = _calculateSubtotal(cart);
    final grandTotal = buffetCharge + cartSubtotal;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: Column(
        children: [
          // Buffet charge row
          _SummaryRow(
            label:
                'Buffet Charge (${widget.order.totalHeadcount} × \$${widget.order.buffetTierPrice.toStringAsFixed(2)})',
            value: buffetCharge,
          ),
          SizedBox(height: 8.h),
          // Cart subtotal row
          _SummaryRow(
            label: 'Extra Items (${cart.length} items)',
            value: cartSubtotal,
          ),
          const Divider(),
          SizedBox(height: 12.h),
          // Grand total row
          _SummaryRow(
            label: 'TOTAL',
            value: grandTotal,
            isBold: true,
            valueColor: Colors.deepOrange,
          ),
          SizedBox(height: 16.h),
          // Confirm Order button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: cart.isEmpty ? null : _confirmOrder,
              icon: const Icon(Icons.check_circle),
              label: Text(
                'Confirm Order',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                backgroundColor:
                    cart.isEmpty ? Colors.grey.shade300 : Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate subtotal for cart items
  double _calculateSubtotal(List<CartItem> cart) {
    return cart.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Confirm order - save cart items to database
  Future<void> _confirmOrder() async {
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartItems = ref.read(cartProvider);

    try {
      final dbHelper = DatabaseHelper();

      // Add all cart items to order
      for (final item in cartItems) {
        await dbHelper.addItemToOrder(
          orderId: widget.order.id,
          menuItemId: int.parse(item.menuItemId),
          quantity: item.quantity,
          priceAtMoment: item.price,
        );
      }

      // Clear cart
      cartNotifier.clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${cartItems.length} items added to order'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    _itemsScrollController.dispose();
    _cartScrollController.dispose();
    super.dispose();
  }
}

/// Helper widget for summary rows
class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isBold ? 18.sp : 16.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
