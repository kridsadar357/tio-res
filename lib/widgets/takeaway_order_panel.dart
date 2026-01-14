import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart'; // Added path_provider
import '../models/menu_item.dart';
import '../models/menu_category.dart';
import '../services/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../screens/checkout_dialog.dart';
import '../widgets/premium_toast.dart';
import '../utils/currency_helper.dart';

/// TakeawayOrderPanel: Compact panel for quick takeaway orders
///
/// Features:
/// - Category tabs for quick navigation
/// - Menu item grid with +/- buttons
/// - Order cart with quantities
/// - Total display and checkout button
class TakeawayOrderPanel extends StatefulWidget {
  final VoidCallback? onOrderComplete;

  const TakeawayOrderPanel({super.key, this.onOrderComplete});

  @override
  State<TakeawayOrderPanel> createState() => _TakeawayOrderPanelState();
}

class _TakeawayOrderPanelState extends State<TakeawayOrderPanel> {
  List<MenuCategory> _categories = [];
  List<MenuItem> _menuItems = [];
  io.Directory? _appDocsDir; // Store app docs dir
  int _selectedCategoryId = -1; // -1 = All
  bool _isCartExpanded = false; // Toggle for expanding cart list

  // Search
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Cart: Map of MenuItem ID to quantity
  final Map<int, int> _cart = {};
  final Map<int, MenuItem> _cartItems = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper();
    final categories = await db.getAllCategories();
    final items = await db.getAllMenuItems();
    final appDir = await getApplicationDocumentsDirectory();

    if (mounted) {
      setState(() {
        _categories = categories;
        _menuItems = items.where((item) => item.isAvailable).toList();
        _appDocsDir = appDir;
        _isLoading = false;
      });
    }
  }

  List<MenuItem> get _filteredItems {
    List<MenuItem> items = _menuItems;

    // Category Filter
    if (_selectedCategoryId != -1) {
      items = items
          .where((item) => item.categoryId == _selectedCategoryId)
          .toList();
    }

    // Search Filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items.where((item) {
        final matchesName = item.name.toLowerCase().contains(query);
        final matchesTh = item.nameTh?.toLowerCase().contains(query) ?? false;
        return matchesName || matchesTh;
      }).toList();
    }

    return items;
  }

  // ... (keeping _totalAmount, _totalItems, _addToCart, _removeFromCart, _clearCart, _checkout methods same - omitted for brevity in replace block if possible, but replace_file_content needs full block or chunks. I will assume I need to keep the ones in between or use multi_replace if too sparse. Since I'm editing the class structure and methods, I should include them or use multi-replace to target specific areas. Wait, replace_file_content replaces a chunk. I can replace the class start down to build method, and then the _buildMenuItem method separately?

  double get _totalAmount {
    double total = 0;
    _cart.forEach((itemId, qty) {
      final item = _cartItems[itemId];
      if (item != null) {
        total += item.price * qty;
      }
    });
    return total;
  }

  int get _totalItems {
    int count = 0;
    _cart.forEach((_, qty) => count += qty);
    return count;
  }

  Future<void> _addToCart(MenuItem item) async {
    // Check shift status
    final currentShift = await DatabaseHelper().getCurrentShift();
    if (currentShift == null) {
      if (!mounted) return;
      PremiumToast.show(
        context,
        AppLocalizations.of(context)!.shiftClosedError,
        isError: true,
      );
      return;
    }

    setState(() {
      _cart[item.id!] = (_cart[item.id!] ?? 0) + 1;
      _cartItems[item.id!] = item;
    });
  }

  void _removeFromCart(int itemId) {
    setState(() {
      final current = _cart[itemId] ?? 0;
      if (current > 1) {
        _cart[itemId] = current - 1;
      } else {
        _cart.remove(itemId);
        _cartItems.remove(itemId);
      }
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _cartItems.clear();
    });
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;

    final db = DatabaseHelper();

    // Create takeaway order (no table)
    final orderId = await db.createTakeawayOrder();

    // Add items to order
    for (final entry in _cart.entries) {
      final item = _cartItems[entry.key];
      if (item != null) {
        await db.addItemToOrder(
          orderId: orderId,
          menuItemId: item.id!,
          quantity: entry.value,
          priceAtMoment: item.price,
        );
      }
    }

    // Get the order
    final order = await db.getOrder(orderId);
    if (order == null || !mounted) return;

    // Show checkout dialog
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CheckoutDialog(
        order: order,
        total: _totalAmount,
        onCheckoutSuccess: () {
          _clearCart();
          widget.onOrderComplete?.call();
        },
      ),
    );

    if (result == true) {
      _clearCart();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border(
          left: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                if (_isSearching)
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      decoration: InputDecoration(
                        hintText: 'Search items...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) {
                        // Keep searching, maybe lose focus
                      },
                    ),
                  )
                else ...[
                  Icon(Icons.shopping_bag, color: Colors.orange, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Takeaway',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const Spacer(),
                ],

                // Search Toggle
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: _isSearching ? Colors.white70 : Colors.orange,
                    size: 20.sp,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_isSearching) {
                        _isSearching = false;
                        _searchController.clear();
                      } else {
                        _isSearching = true;
                        _searchFocusNode.requestFocus();
                      }
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: 8.w),
                if (_cart.isNotEmpty && !_isSearching)
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: Colors.red, size: 20.sp),
                    onPressed: _clearCart,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          // Category Tabs (Hide when searching maybe? Or keep. Keep for now)
          if (!_isSearching)
            SizedBox(
              height: 40.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                children: [
                  _buildCategoryChip(-1, l10n.all),
                  ..._categories
                      .map((cat) => _buildCategoryChip(cat.id!, cat.name)),
                ],
              ),
            ),

          // Menu Items Grid
          Expanded(
            flex: _isCartExpanded ? 1 : 10, // Shrink or fit available space
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          'No items found',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 14.sp),
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.all(8.w),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 6.w,
                          mainAxisSpacing: 6.h,
                          childAspectRatio: 1.0, // Square for images
                        ),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return _buildMenuItem(item);
                        },
                      ),
          ),

          // Divider
          Container(height: 1, color: Colors.white.withOpacity(0.1)),

          // Cart Summary
          Expanded(
            flex: _isCartExpanded ? 10 : 8, // Expand significantly
            child: Column(
              children: [
                // Cart Header
                InkWell(
                  onTap: () {
                    setState(() {
                      _isCartExpanded = !_isCartExpanded;
                    });
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    color: Colors.white.withOpacity(0.02),
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long,
                            size: 16.sp, color: Colors.white54),
                        SizedBox(width: 6.w),
                        Text(
                          'Order ($_totalItems items)',
                          style:
                              TextStyle(fontSize: 12.sp, color: Colors.white70),
                        ),
                        const Spacer(),
                        // Collapse/Expand Icon
                        Icon(
                          _isCartExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          size: 20.sp,
                          color: Colors.white54,
                        ),
                      ],
                    ),
                  ),
                ),

                // Cart Items
                Expanded(
                  child: _cart.isEmpty
                      ? Center(
                          child: Text(
                            'No items in cart',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 12.sp),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final itemId = _cart.keys.elementAt(index);
                            final qty = _cart[itemId]!;
                            final item = _cartItems[itemId]!;
                            return _buildCartItem(item, qty);
                          },
                        ),
                ),

                // Total & Checkout
                Container(
                  padding: EdgeInsets.zero, // Remove padding for edge-to-edge
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    border: Border(
                      top: BorderSide(color: Colors.green.withOpacity(0.3)),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              CurrencyHelper.formatWhole(context, _totalAmount),
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 60.h, // Increased height
                        child: ElevatedButton(
                          onPressed: _cart.isEmpty ? null : _checkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero, // Square corners
                            ),
                            disabledBackgroundColor:
                                Colors.grey.withOpacity(0.3),
                            elevation: 0,
                          ),
                          child: Text(
                            'Checkout',
                            style: TextStyle(
                                fontSize: 18.sp, // Larger font
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(int id, String name) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: EdgeInsets.only(right: 6.w),
      child: InkWell(
        onTap: () => setState(() => _selectedCategoryId = id),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? Colors.orange : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Text(
            name,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    final qty = _cart[item.id] ?? 0;

    // Resolve full path
    String? fullPath;
    if (item.imagePath != null &&
        item.imagePath!.isNotEmpty &&
        _appDocsDir != null) {
      if (item.imagePath!.startsWith('/')) {
        fullPath = item.imagePath;
      } else {
        fullPath = '${_appDocsDir!.path}/${item.imagePath}';
      }
    }

    // Verify existence (optional but prevents error spam)
    final hasImage = fullPath != null && io.File(fullPath).existsSync();

    return InkWell(
      onTap: () => _addToCart(item),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: qty > 0
                ? Colors.orange.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
          // Background Image
          image: hasImage
              ? DecorationImage(
                  image: FileImage(io.File(fullPath!)),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.4), BlendMode.darken))
              : null,
        ),
        child: Stack(
          children: [
            // Text Content (Bottom)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  gradient: hasImage
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ])
                      : null,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8.r),
                      bottomRight: Radius.circular(8.r)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        shadows: hasImage
                            ? [Shadow(blurRadius: 2, color: Colors.black)]
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      CurrencyHelper.formatWhole(context, item.price),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                        shadows: hasImage
                            ? [Shadow(blurRadius: 2, color: Colors.black)]
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quantity Badge
            if (qty > 0)
              Positioned(
                top: 4.h,
                right: 4.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    'x$qty',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(MenuItem item, int qty) {
    return Container(
      margin: EdgeInsets.only(bottom: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(fontSize: 11.sp, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '฿${(item.price * qty).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ),
          // Quantity controls
          Row(
            children: [
              InkWell(
                onTap: () => _removeFromCart(item.id!),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Icon(Icons.remove, size: 14.sp, color: Colors.red),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  '$qty',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _addToCart(item),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Icon(Icons.add, size: 14.sp, color: Colors.green),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
