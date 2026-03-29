import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import '../models/menu_item.dart';
import '../models/menu_category.dart';
import '../services/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../screens/checkout_dialog.dart';
import '../widgets/premium_toast.dart';
import '../utils/currency_helper.dart';

/// TakeawayOrderPanel: Optimized panel for quick takeaway orders
/// 
/// Layout: 60% Menu Items | 40% Order List + Total + Checkout
/// Optimized for low-spec devices and mobile screens
class TakeawayOrderPanel extends StatefulWidget {
  final VoidCallback? onOrderComplete;

  const TakeawayOrderPanel({super.key, this.onOrderComplete});

  @override
  State<TakeawayOrderPanel> createState() => _TakeawayOrderPanelState();
}

class _TakeawayOrderPanelState extends State<TakeawayOrderPanel> {
  List<MenuCategory> _categories = [];
  List<MenuItem> _menuItems = [];
  io.Directory? _appDocsDir;
  int _selectedCategoryId = -1;

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
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper();
    final results = await Future.wait([
      db.getAllCategories(),
      db.getAllMenuItems(),
      getApplicationDocumentsDirectory(),
    ]);

    if (mounted) {
      setState(() {
        _categories = results[0] as List<MenuCategory>;
        _menuItems = (results[1] as List<MenuItem>)
            .where((item) => item.isAvailable)
            .toList();
        _appDocsDir = results[2] as io.Directory;
        _isLoading = false;
      });
    }
  }

  List<MenuItem> get _filteredItems {
    List<MenuItem> items = _menuItems;

    if (_selectedCategoryId != -1) {
      items = items
          .where((item) => item.categoryId == _selectedCategoryId)
          .toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items.where((item) {
        return item.name.toLowerCase().contains(query) ||
            (item.nameTh?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return items;
  }

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
    final orderId = await db.createTakeawayOrder();

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

    final order = await db.getOrder(orderId);
    if (order == null || !mounted) return;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: Use column layout on narrow screens (mobile)
        final isNarrow = constraints.maxWidth < 600;
        
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Theme.of(context).cardColor,
            border: Border(
              left: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(l10n, isDark),
              
              // Main Content: 60/40 split
              Expanded(
                child: isNarrow
                    ? _buildMobileLayout(l10n, isDark)
                    : _buildDesktopLayout(l10n, isDark),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Desktop Layout: 60% Items | 40% Cart
  Widget _buildDesktopLayout(AppLocalizations l10n, bool isDark) {
    return Row(
      children: [
        // 60% - Menu Items
        Expanded(
          flex: 6,
          child: Column(
            children: [
              // Category Tabs
              if (!_isSearching) _buildCategoryTabs(l10n, isDark),
              // Menu Grid
              Expanded(child: _buildMenuGrid(isDark)),
            ],
          ),
        ),
        
        // Divider
        Container(
          width: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
        
        // 40% - Order List + Total + Checkout
        Expanded(
          flex: 4,
          child: _buildCartSection(l10n, isDark),
        ),
      ],
    );
  }

  /// Mobile Layout: Vertical stack with collapsible cart
  Widget _buildMobileLayout(AppLocalizations l10n, bool isDark) {
    return Column(
      children: [
        // Category Tabs
        if (!_isSearching) _buildCategoryTabs(l10n, isDark),
        // Menu Grid (60%)
        Expanded(
          flex: 6,
          child: _buildMenuGrid(isDark),
        ),
        // Divider
        Container(
          height: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
        // Cart Section (40%)
        Expanded(
          flex: 4,
          child: _buildCartSection(l10n, isDark),
        ),
      ],
    );
  }

  Widget _buildHeader(AppLocalizations l10n, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          if (_isSearching)
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14.sp,
                ),
                decoration: InputDecoration(
                  hintText: 'ค้นหารายการ...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            )
          else ...[
            Icon(Icons.shopping_bag, color: Colors.orange, size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                l10n.takeAway,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          // Search Toggle
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: _isSearching
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                  : Colors.orange,
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
            visualDensity: VisualDensity.compact,
          ),
          if (_cart.isNotEmpty && !_isSearching) ...[
            SizedBox(width: 8.w),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red, size: 20.sp),
              onPressed: _clearCart,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(AppLocalizations l10n, bool isDark) {
    return SizedBox(
      height: 36.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCategoryChip(-1, l10n.all, isDark);
          }
          final cat = _categories[index - 1];
          return _buildCategoryChip(cat.id!, cat.name, isDark);
        },
      ),
    );
  }

  Widget _buildCategoryChip(int id, String name, bool isDark) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: EdgeInsets.only(right: 6.w),
      child: InkWell(
        onTap: () => setState(() => _selectedCategoryId = id),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.orange
                : isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected
                  ? Colors.orange
                  : isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            name,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGrid(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = _filteredItems;
    if (items.isEmpty) {
      return Center(
        child: Text(
          'ไม่พบรายการ',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 14.sp,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid columns
        int crossAxisCount = 3;
        if (constraints.maxWidth > 600) crossAxisCount = 4;
        if (constraints.maxWidth > 900) crossAxisCount = 5;
        if (constraints.maxWidth < 300) crossAxisCount = 2;

        return GridView.builder(
          padding: EdgeInsets.all(6.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 6.w,
            mainAxisSpacing: 6.h,
            childAspectRatio: 0.85,
          ),
          itemCount: items.length,
          cacheExtent: 200, // Reduced for low-spec devices
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          itemBuilder: (context, index) {
            return _MenuItemCard(
              key: ValueKey(items[index].id),
              item: items[index],
              quantity: _cart[items[index].id] ?? 0,
              appDocsDir: _appDocsDir,
              onTap: () => _addToCart(items[index]),
              isDark: isDark,
            );
          },
        );
      },
    );
  }

  Widget _buildCartSection(AppLocalizations l10n, bool isDark) {
    return Column(
      children: [
        // Cart Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.black.withValues(alpha: 0.02),
          ),
          child: Row(
            children: [
              Icon(
                Icons.receipt_long,
                size: 16.sp,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  '${l10n.orderItems} ($_totalItems)',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Cart Items List
        Expanded(
          child: _cart.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    // Only show icon if there's enough space
                    final showIcon = constraints.maxHeight > 60;
                    return Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showIcon) ...[
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 28.sp,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                                ),
                                SizedBox(height: 4.h),
                              ],
                              Text(
                                'ไม่มีรายการ',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  itemCount: _cart.length,
                  itemBuilder: (context, index) {
                    final itemId = _cart.keys.elementAt(index);
                    final qty = _cart[itemId]!;
                    final item = _cartItems[itemId]!;
                    return _CartItemRow(
                      key: ValueKey(itemId),
                      item: item,
                      quantity: qty,
                      onAdd: () => _addToCart(item),
                      onRemove: () => _removeFromCart(itemId),
                      isDark: isDark,
                    );
                  },
                ),
        ),

        // Total & Checkout Button
        Container(
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            border: Border(
              top: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Total Row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.total,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      CurrencyHelper.formatWhole(context, _totalAmount),
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ),
              // Checkout Button
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _cart.isEmpty ? null : _checkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.checkout,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Optimized Menu Item Card - Separate widget to minimize rebuilds
class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final int quantity;
  final io.Directory? appDocsDir;
  final VoidCallback onTap;
  final bool isDark;

  const _MenuItemCard({
    super.key,
    required this.item,
    required this.quantity,
    required this.appDocsDir,
    required this.onTap,
    required this.isDark,
  });

  String? _getImagePath() {
    if (item.imagePath == null || item.imagePath!.isEmpty || appDocsDir == null) {
      return null;
    }
    final path = item.imagePath!.startsWith('/')
        ? item.imagePath!
        : '${appDocsDir!.path}/${item.imagePath}';
    return io.File(path).existsSync() ? path : null;
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _getImagePath();

    return RepaintBoundary(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: quantity > 0
                  ? Colors.orange.withValues(alpha: 0.6)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
              width: quantity > 0 ? 2 : 1,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image or placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(7.r),
                child: imagePath != null
                    ? Image.file(
                        io.File(imagePath),
                        fit: BoxFit.cover,
                        cacheWidth: 150, // Memory optimization
                        errorBuilder: (_, __, ___) => _buildPlaceholder(context),
                      )
                    : _buildPlaceholder(context),
              ),
              
              // Gradient overlay for text readability
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(7.r),
                      bottomRight: Radius.circular(7.r),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        CurrencyHelper.formatWhole(context, item.price),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quantity Badge
              if (quantity > 0)
                Positioned(
                  top: 4.h,
                  right: 4.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      'x$quantity',
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
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.grey.withValues(alpha: 0.1),
      child: Icon(
        Icons.restaurant,
        size: 24.sp,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
      ),
    );
  }
}

/// Optimized Cart Item Row - Separate widget
class _CartItemRow extends StatelessWidget {
  final MenuItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool isDark;

  const _CartItemRow({
    super.key,
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          // Item info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '฿${(item.price * quantity).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Quantity controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QuantityButton(
                icon: Icons.remove,
                color: Colors.red,
                onTap: onRemove,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  '$quantity',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              _QuantityButton(
                icon: Icons.add,
                color: Colors.green,
                onTap: onAdd,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quantity Button - Reusable
class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuantityButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4.r),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Icon(icon, size: 14.sp, color: color),
      ),
    );
  }
}
