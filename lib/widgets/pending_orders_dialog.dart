import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/api_service.dart';
import '../services/printer_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'premium_toast.dart';

/// Dialog to display and manage pending web orders
/// Supports swipe navigation between multiple table orders
class PendingOrdersDialog extends StatefulWidget {
  final List<WebOrder> orders;
  final VoidCallback onOrdersUpdated;

  const PendingOrdersDialog({
    super.key,
    required this.orders,
    required this.onOrdersUpdated,
  });

  static Future<void> show(
    BuildContext context,
    List<WebOrder> orders,
    VoidCallback onOrdersUpdated,
  ) async {
    if (orders.isEmpty) {
      PremiumToast.show(context, 'No pending orders');
      return;
    }

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return PendingOrdersDialog(
          orders: orders,
          onOrdersUpdated: onOrdersUpdated,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  @override
  State<PendingOrdersDialog> createState() => _PendingOrdersDialogState();
}

class _PendingOrdersDialogState extends State<PendingOrdersDialog> {
  late PageController _pageController;
  late List<WebOrder> _orders;
  int _currentPage = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _orders = List.from(widget.orders);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_orders.isEmpty) {
      // Auto close if no more orders
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 500.w,
          height: 600.h,
          margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 48.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E2530), Color(0xFF151A22)],
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(l10n),
              
              // Page Indicator (if multiple orders)
              if (_orders.length > 1) _buildPageIndicator(),
              
              // Orders PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _orders.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    return _buildOrderPage(_orders[index], l10n);
                  },
                ),
              ),
              
              // Action Buttons
              _buildActionButtons(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.withValues(alpha: 0.2), Colors.deepOrange.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(
          bottom: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active,
              color: Colors.orange,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 16.w),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.pendingOrders,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_orders.length} ${l10n.tables}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          
          // Close Button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.white54, size: 24.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left Arrow
          IconButton(
            onPressed: _currentPage > 0
                ? () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                : null,
            icon: Icon(
              Icons.chevron_left,
              color: _currentPage > 0 ? Colors.white : Colors.white24,
              size: 28.sp,
            ),
          ),
          
          // Page Dots
          Row(
            children: List.generate(_orders.length, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                width: isActive ? 24.w : 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: isActive ? Colors.orange : Colors.white24,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              );
            }),
          ),
          
          // Right Arrow
          IconButton(
            onPressed: _currentPage < _orders.length - 1
                ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                : null,
            icon: Icon(
              Icons.chevron_right,
              color: _currentPage < _orders.length - 1 ? Colors.white : Colors.white24,
              size: 28.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderPage(WebOrder order, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Info Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.table_restaurant, color: Colors.blue, size: 32.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.tableName.isNotEmpty ? order.tableName : 'Table ${order.tableId}',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${order.items.length} ${l10n.items}',
                        style: TextStyle(fontSize: 13.sp, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                // Time
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 14.sp, color: Colors.white54),
                      SizedBox(width: 4.w),
                      Text(
                        _formatTime(order.createdAt),
                        style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Items List
          Text(
            l10n.orderItems,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
            ),
          ),
          SizedBox(height: 8.h),
          
          ...order.items.map((item) => _buildOrderItem(item)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(WebOrderItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Quantity Badge
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Text(
                '${item.quantity}x',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (item.notes != null && item.notes!.isNotEmpty)
                  Text(
                    item.notes!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.amber,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          
          // Status
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'Pending',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    if (_orders.isEmpty) return const SizedBox.shrink();
    
    final currentOrder = _orders[_currentPage];
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
      ),
      child: Row(
        children: [
          // Print to Kitchen Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _printToKitchen(currentOrder),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: Icon(Icons.print, size: 20.sp),
              label: Text(
                l10n.printToKitchen,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // Served Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _markAsServed(currentOrder),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusAvailable,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: _isProcessing
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : Icon(Icons.check_circle, size: 20.sp),
              label: Text(
                l10n.served,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _printToKitchen(WebOrder order) async {
    setState(() => _isProcessing = true);
    
    try {
      // Build kitchen receipt with items
      await PrinterService().printKitchenOrder(
        tableName: order.tableName.isNotEmpty ? order.tableName : 'Table ${order.tableId}',
        items: order.items.map((item) => {
          'name': item.name,
          'quantity': item.quantity,
          'notes': item.notes ?? '',
        }).toList(),
      );
      
      if (mounted) {
        PremiumToast.show(context, AppLocalizations.of(context)!.printSuccess);
      }
    } catch (e) {
      if (mounted) {
        PremiumToast.show(context, 'Print error: $e', isError: true);
      }
    }
    
    setState(() => _isProcessing = false);
  }

  Future<void> _markAsServed(WebOrder order) async {
    setState(() => _isProcessing = true);
    
    try {
      final success = await ApiService().acknowledgeOrder(order.id);
      
      if (success) {
        // Remove from local list
        setState(() {
          _orders.removeWhere((o) => o.id == order.id);
          if (_currentPage >= _orders.length && _orders.isNotEmpty) {
            _currentPage = _orders.length - 1;
            _pageController.jumpToPage(_currentPage);
          }
        });
        
        widget.onOrdersUpdated();
        
        if (mounted && _orders.isNotEmpty) {
          PremiumToast.show(context, AppLocalizations.of(context)!.orderServed);
        }
      } else {
        if (mounted) {
          PremiumToast.show(context, 'Failed to update order', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        PremiumToast.show(context, 'Error: $e', isError: true);
      }
    }
    
    setState(() => _isProcessing = false);
  }
}
