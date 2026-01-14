import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/table_model.dart';
import '../models/menu_category.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../services/database_helper.dart';
import '../services/image_storage_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/premium_toast.dart';
import '../utils/currency_helper.dart';
import 'table_selection_screen.dart';
import 'checkout_dialog.dart';
import 'bluetooth_printer_screen.dart';

/// POSScreen: Main ordering interface with two-pane Master-Detail layout
///
/// Left Pane: Menu Categories and Item Grid
/// Right Pane: Current Table Order Summary and Action Buttons
class POSScreen extends ConsumerStatefulWidget {
  final TableModel table;

  const POSScreen({
    super.key,
    required this.table,
  });

  @override
  ConsumerState<POSScreen> createState() => POSScreenState();
}

class POSScreenState extends ConsumerState<POSScreen> {
  Future<Order?> _orderFuture = Future.value(null);
  int _selectedCategoryId = 1;
  final ScrollController _itemsScrollController = ScrollController();
  final ImageStorageService _imageService = ImageStorageService();

  @override
  void initState() {
    super.initState();
    _orderFuture = _loadOrder();
  }

  Future<Order?> _loadOrder() async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.getCurrentOrderForTable(widget.table.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              const Color(0xFF202533),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              _buildHeader(),

              // Main Content
              Expanded(
                child: FutureBuilder<Order?>(
                  future: _orderFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64.sp, color: Colors.red),
                            SizedBox(height: 16.h),
                            Text(
                              'Error loading order',
                              style: TextStyle(fontSize: 18.sp),
                            ),
                          ],
                        ),
                      );
                    }

                    final order = snapshot.data;

                    if (order == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64.sp, color: Colors.orange),
                            SizedBox(height: 16.h),
                            Text(
                              'No active order found',
                              style: TextStyle(fontSize: 18.sp),
                            ),
                            SizedBox(height: 16.h),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Back to Tables'),
                            ),
                          ],
                        ),
                      );
                    }

                    // Two-pane Master-Detail layout
                    return Row(
                      children: [
                        // Left Pane: Menu (60% of width)
                        Expanded(
                          flex: 6,
                          child: _buildMenuPane(order),
                        ),
                        // Right Pane: Order Summary (40% of width)
                        Expanded(
                          flex: 4,
                          child: _buildOrderSummaryPane(order),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back to Tables',
          ),
          SizedBox(width: 16.w),
          Text(
            '${widget.table.tableName} - Order',
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BluetoothPrinterScreen(),
              ),
            ),
            tooltip: 'Printer Settings',
          ),
        ],
      ),
    );
  }

  /// Build the left pane with categories and menu items
  Widget _buildMenuPane(Order order) {
    return Column(
      children: [
        // Category selection
        _buildCategorySelector(),

        // Menu items grid
        Expanded(
          child: _buildMenuItemsGrid(order),
        ),
      ],
    );
  }

  /// Build category selector at the top of left pane
  Widget _buildCategorySelector() {
    return FutureBuilder<List<MenuCategory>>(
      future: DatabaseHelper().getAllCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
              height: 70.h,
              child: const Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final categories = snapshot.data!;

        return Container(
          height: 70.h,
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category.id == _selectedCategoryId;

              return Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: Center(
                  child: FilterChip(
                    label: Text(category.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (category.id != null) {
                        setState(() {
                          _selectedCategoryId = category.id!;
                        });
                      }
                    },
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    selectedColor: Theme.of(context).primaryColor,
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                    labelStyle: TextStyle(
                      fontSize: 14.sp,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    showCheckmark: false,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Build the menu items grid
  Widget _buildMenuItemsGrid(Order order) {
    return FutureBuilder<List<MenuItem>>(
      future: DatabaseHelper().getMenuItemsByCategory(_selectedCategoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading items',
              style: TextStyle(fontSize: 16.sp),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 64.sp, color: Colors.grey),
                SizedBox(height: 16.h),
                Text(
                  'No items in this category',
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final items = snapshot.data!;

        return Padding(
          padding: EdgeInsets.all(16.w),
          child: GridView.builder(
            controller: _itemsScrollController,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _calculateCrossAxisCount(),
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 0.85, // Adjusted for better fit
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildMenuItemCard(item, order);
            },
          ),
        );
      },
    );
  }

  /// Build a single menu item card
  Widget _buildMenuItemCard(MenuItem item, Order order) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _addMenuItemToOrder(item, order),
            borderRadius: BorderRadius.circular(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image or placeholder
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16.r)),
                    ),
                    child: item.hasImage
                        ? FutureBuilder<File?>(
                            future: _imageService.getImageFile(item.imagePath!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              if (snapshot.hasData && snapshot.data != null) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16.r),
                                  ),
                                  child: Image.file(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildImagePlaceholder(item.name);
                                    },
                                  ),
                                );
                              }

                              return _buildImagePlaceholder(item.name);
                            },
                          )
                        : _buildImagePlaceholder(item.name),
                  ),
                ),
                // Item details
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Item name
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Price or included indicator
                        Row(
                          children: [
                            if (item.hasExtraCharge) ...[
                              Text(
                                '${CurrencyHelper.symbol(context)}${item.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary, // Neon Green/Mint
                                    shadows: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      )
                                    ]),
                              ),
                            ] else ...[
                              Icon(
                                Icons.check_circle_outline,
                                size: 16.sp,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  'Included',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            const Spacer(),
                            // Add icon
                            Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]),
                              child: Icon(
                                Icons.add,
                                size: 16.sp,
                                color: Colors.white,
                              ),
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
        ),
      ),
    );
  }

  /// Build image placeholder when no image is available
  Widget _buildImagePlaceholder(String itemName) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade400,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 40.sp,
              color: Colors.grey.shade600,
            ),
            SizedBox(height: 8.h),
            Text(
              'No Image',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the right pane with order summary
  Widget _buildOrderSummaryPane(Order order) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 16.w, 16.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Order header
                _buildOrderHeader(order),
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                // Order items list
                Expanded(
                  child: _buildOrderItemsList(order),
                ),
                // Buffet info
                _buildBuffetInfo(order),
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                // Footer with total and checkout button
                _buildOrderFooter(order),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build order header with table info
  Widget _buildOrderHeader(Order order) {
    return Container(
      padding: EdgeInsets.all(20.w),
      color: Colors.white.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.currentOrder,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: Icon(
                      Icons.local_offer,
                      color: order.promotionId != null
                          ? Theme.of(context).primaryColor
                          : Colors.white54,
                      size: 20.sp,
                    ),
                    onPressed: () => _showPromotionDialog(order),
                    tooltip: AppLocalizations.of(context)!.selectPromotion,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                      color: Theme.of(context).primaryColor, width: 1),
                ),
                child: Text(
                  '${AppLocalizations.of(context)!.table} ${widget.table.tableName}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.access_time, size: 14.sp, color: Colors.grey),
              SizedBox(width: 4.w),
              Text(
                'Started: ${_formatTime(order.startDateTime)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey,
                ),
              ),
              SizedBox(width: 12.w),
              if (order.getDurationInMinutes() != null) ...[
                Icon(Icons.timer_outlined, size: 14.sp, color: Colors.grey),
                SizedBox(width: 4.w),
                Text(
                  '${order.getDurationInMinutes()} min',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Build the list of ordered items
  Widget _buildOrderItemsList(Order order) {
    return FutureBuilder<List<OrderItem>>(
      future: DatabaseHelper().getOrderItems(order.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading items',
              style: TextStyle(fontSize: 14.sp, color: Colors.white70),
            ),
          );
        }

        final orderItems = snapshot.data ?? [];

        if (orderItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined,
                    size: 48.sp, color: Colors.white24),
                SizedBox(height: 16.h),
                Text(
                  'No items ordered yet',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white54,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Tap items on the left to add',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white30,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          itemCount: orderItems.length,
          itemBuilder: (context, index) {
            final orderItem = orderItems[index];
            return _buildOrderItemTile(orderItem);
          },
        );
      },
    );
  }

  /// Build a single order item tile
  Widget _buildOrderItemTile(OrderItem orderItem) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        dense: true,
        title: Text(
          'Item #${orderItem.menuItemId}',
          style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white),
        ),
        subtitle: Text(
          orderItem.formattedUnitPrice,
          style: TextStyle(fontSize: 12.sp, color: Colors.white60),
        ),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Quantity badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                'x${orderItem.quantity}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // Total price
            Text(
              orderItem.formattedTotal,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: orderItem.hasExtraCharge
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.secondary,
              ),
            ),
            SizedBox(width: 8.w),
            // Remove button
            IconButton(
              icon: Icon(Icons.remove_circle_outline, size: 20.sp),
              onPressed: () => _removeOrderItem(orderItem.id),
              color: Theme.of(context).colorScheme.error,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build buffet information section
  Widget _buildBuffetInfo(Order order) {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people,
                  size: 20.sp, color: Theme.of(context).primaryColor),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.buffetHeadcount,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppLocalizations.of(context)!.adults}: ${order.adultHeadcount}',
                style: TextStyle(fontSize: 14.sp, color: AppTheme.textPrimary),
              ),
              Text(
                '${AppLocalizations.of(context)!.children}: ${order.childHeadcount}',
                style: TextStyle(fontSize: 14.sp, color: AppTheme.textPrimary),
              ),
              Text(
                '${AppLocalizations.of(context)!.total}: ${order.totalHeadcount}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context)!.tierPricePerson(
                '${CurrencyHelper.symbol(context)}${order.buffetTierPrice.toStringAsFixed(2)}'),
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Build footer with total and checkout button
  Widget _buildOrderFooter(Order order) {
    return FutureBuilder<List<double>>(
      future: Future.wait([
        DatabaseHelper().calculateOrderGrossTotal(order.id),
        DatabaseHelper().calculateOrderTotal(order.id),
      ]),
      builder: (context, snapshot) {
        final grossTotal = snapshot.data?[0] ?? 0.0;
        final netTotal = snapshot.data?[1] ?? 0.0;
        final discount = grossTotal - netTotal;

        return Container(
          padding: EdgeInsets.all(16.w),
          color: Theme.of(context).cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (discount > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.subtotalLabel,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      CurrencyHelper.format(context, grossTotal),
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppLocalizations.of(context)!.discountLabel}:',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    Text(
                      '-${CurrencyHelper.format(context, discount)}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Divider(
                    height: 24.h, color: Colors.white.withValues(alpha: 0.1)),
              ],
              // Total amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.total}:',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    CurrencyHelper.format(context, netTotal),
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              // Checkout button
              ElevatedButton.icon(
                onPressed: () => _showCheckoutDialog(order, netTotal),
                icon: const Icon(Icons.payment),
                label: Text(
                  AppLocalizations.of(context)!.checkout,
                  style: TextStyle(fontSize: 16.sp),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Add menu item to order
  Future<void> _addMenuItemToOrder(MenuItem item, Order order) async {
    if (item.id == null) {
      if (mounted) {
        PremiumToast.show(context, 'Error: Invalid menu item', isError: true);
      }
      return;
    }

    try {
      // Calculate price: if item is included in buffet AND this is a buffet order (tier price > 0), price is 0.
      double priceToCharge = item.price;
      if (item.isBuffetIncluded && order.buffetTierPrice > 0) {
        priceToCharge = 0.0;
      }

      await DatabaseHelper().addItemToOrder(
        orderId: order.id,
        menuItemId: item.id!,
        quantity: 1,
        priceAtMoment: priceToCharge,
      );

      if (mounted) {
        PremiumToast.show(context, '${item.name} added to order');
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        PremiumToast.show(context, 'Error adding item: $e', isError: true);
      }
    }
  }

  /// Remove order item
  Future<void> _removeOrderItem(int orderItemId) async {
    try {
      await DatabaseHelper().removeItemFromOrder(orderItemId);

      if (mounted) {
        setState(() {});
        PremiumToast.show(context, 'Item removed');
      }
    } catch (e) {
      if (mounted) {
        PremiumToast.show(context, 'Error removing item: $e', isError: true);
      }
    }
  }

  /// Show checkout dialog
  void _showCheckoutDialog(Order order, double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CheckoutDialog(
        order: order,
        total: total,
        onCheckoutSuccess: () {
          Navigator.pop(context); // Go back to tables
          ref.invalidate(tablesProvider);
        },
      ),
    );
  }

  /// Format time as HH:MM
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Calculate grid columns based on available width
  int _calculateCrossAxisCount() {
    final width = MediaQuery.of(context).size.width * 0.6; // 60% of screen
    if (width < 400) return 2;
    if (width < 600) return 3;
    if (width < 800) return 4;
    return 5;
  }

  Future<void> _applyPromotion(Order order, int? promotionId) async {
    await DatabaseHelper().applyPromotionToOrder(order.id, promotionId);
    if (mounted) {
      // Close dialog if open (handled by onTap in dialog, but safe to check)
      // Actually onTap calls _applyPromotion which should probably reload order directly.
      // Dialog closing logic can be inside dialog or here.
      // In _showPromotionDialog, I set onTap: () => _applyPromotion
      // So I should close dialog here.
      Navigator.of(context).pop();
      setState(() {
        _orderFuture = _loadOrder();
      });
    }
  }

  void _showPromotionDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252836),
        title: Text(AppLocalizations.of(context)!.selectPromotion,
            style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 400.w,
          height: 400.h,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: DatabaseHelper().getActivePromotions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                    child: Text(AppLocalizations.of(context)!.noPromotionsFound,
                        style: const TextStyle(color: Colors.white70)));
              }
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final promo = snapshot.data![index];
                  final isSelected = order.promotionId == promo['id'];
                  return Card(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    margin: EdgeInsets.symmetric(vertical: 4.h),
                    child: ListTile(
                      title: Text(promo['name'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        promo['discount_type'] == 'PERCENT'
                            ? '${promo['discount_value']}% Off'
                            : '${CurrencyHelper.symbol(context)}${promo['discount_value']} Off',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle,
                              color: Theme.of(context).primaryColor)
                          : null,
                      onTap: () => _applyPromotion(order, promo['id']),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          if (order.promotionId != null)
            TextButton(
              onPressed: () => _applyPromotion(order, null),
              child: Text(AppLocalizations.of(context)!.removePromotion,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _itemsScrollController.dispose();
    super.dispose();
  }
}
