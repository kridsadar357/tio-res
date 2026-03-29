import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../l10n/app_localizations.dart';
import '../models/table_model.dart';
import '../core/constants/app_constants.dart';
import '../models/layout_object_model.dart';
import '../services/database_helper.dart';
import '../widgets/right_menu.dart';
import '../widgets/visual_floor_plan.dart';
import '../widgets/takeaway_order_panel.dart';
import '../services/api_service.dart';
import 'pos_screen.dart';

import 'menu_management/menu_management_screen.dart';
import 'receipt_designer/visual_receipt_designer_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';
import 'settings/printer_settings_screen.dart';
import 'shift/shift_screen.dart';
import '../widgets/layout_side_panel.dart';
import 'management/buffet_tier_screen.dart';
import 'management/table_layout_screen.dart';
import 'management/customers_screen.dart';
import 'management/promotions_screen.dart';
import '../theme/app_theme.dart';
import '../services/printer_service.dart';
import '../services/api_service.dart';
import '../utils/currency_helper.dart';
import '../models/buffet_tier.dart';
import '../widgets/premium_toast.dart';
import '../widgets/pending_orders_dialog.dart';
import '../providers/notification_provider.dart';

/// Provider to fetch all tables
final tablesProvider =
    FutureProvider.autoDispose<List<TableModel>>((ref) async {
  final dbHelper = DatabaseHelper();
  return await dbHelper.getAllTables();
});

final layoutObjectsProvider =
    FutureProvider.autoDispose<List<LayoutObjectModel>>((ref) async {
  return await DatabaseHelper().getAllLayoutObjects();
});

/// TableSelectionScreen: Grid view of all restaurant tables
///
/// Features:
/// - Grid layout optimized for tablets
/// - Color-coded status indicators (Green/Red/Yellow)
/// - Tap to open table with headcount and buffet tier selection
/// - Swipe gestures for quick actions (future enhancement)
class TableSelectionScreen extends ConsumerStatefulWidget {
  const TableSelectionScreen({super.key});

  @override
  ConsumerState<TableSelectionScreen> createState() =>
      _TableSelectionScreenState();
}

class _TableSelectionScreenState extends ConsumerState<TableSelectionScreen> {
  // Buffet tier prices loaded from database
  List<BuffetTier> _buffetTiers = [];

  // Buffet tier selection for opening a table
  BuffetTier? _selectedTier;

  // Filter state: -1: All, 0: Available, 1: Occupied, 2: Cleaning
  int _selectedFilter = -1;

  // View Mode: 0 = List, 1 = Map
  int _viewMode = 0;

  // Takeaway panel expanded state
  bool _takeawayExpanded = false;

  // Track seen order item IDs to detect truly new items
  Set<int> _seenOrderItemIds = {};
  int _previousOrderCount = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadBuffetTiers();
  }

  Future<void> _loadBuffetTiers() async {
    final tiersData = await DatabaseHelper().getAllBuffetTiers();
    setState(() {
      _buffetTiers = tiersData
          .map((m) => BuffetTier.fromMap(m))
          .where((t) => t.isActive)
          .toList();
      if (_buffetTiers.isNotEmpty) {
        _selectedTier = _buffetTiers.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Listen for new pending orders and show notification
    ref.listen<NotificationState>(notificationProvider, (previous, next) {
      // Collect all current order item IDs
      final currentItemIds = <int>{};
      for (final order in next.pendingOrders) {
        for (final item in order.items) {
          currentItemIds.add(item.id);
        }
      }
      
      // Find truly new items (not seen before)
      final newItemIds = currentItemIds.difference(_seenOrderItemIds);
      final hasNewOrders = next.count > _previousOrderCount;
      final hasNewItems = newItemIds.isNotEmpty;
      
      // Only show notification if this is not the initial load (previous != null)
      if (previous != null && (hasNewOrders || hasNewItems) && next.pendingOrders.isNotEmpty) {
        // New orders or items arrived - show toast and auto-open dialog
        final newItemCount = newItemIds.length;
        final newOrderCount = next.count - _previousOrderCount;
        
        // Show appropriate message based on what's new
        String message;
        if (newOrderCount > 0 && newItemCount > 0) {
          message = '🔔 $newOrderCount ${l10n.pendingOrders} ($newItemCount ${l10n.items})!';
        } else if (newItemCount > 0) {
          message = '🔔 $newItemCount ${l10n.items} ${l10n.pendingOrders}!';
        } else {
          message = '🔔 $newOrderCount ${l10n.pendingOrders}!';
        }
        
        PremiumToast.show(context, message);
        
        // Auto-show dialog for new orders
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && next.pendingOrders.isNotEmpty) {
            PendingOrdersDialog.show(
              context,
              next.pendingOrders,
              () {
                // When dialog is closed via callback (refresh), mark current items as seen
                // This prevents re-showing dialog for the same items
                _seenOrderItemIds = currentItemIds;
                ref.read(notificationProvider.notifier).refresh();
              },
            );
          }
        });
        
        // Mark new items as seen immediately after showing dialog
        _seenOrderItemIds.addAll(newItemIds);
      }
      
      // Update order count tracking
      _previousOrderCount = next.count;
      
      // Clean up: remove IDs that are no longer pending (acknowledged items)
      _seenOrderItemIds = _seenOrderItemIds.intersection(currentItemIds);
    });
    
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildRightMenu(l10n),
      body: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A1F2C), // Deep premium navy
                    Color(0xFF13161F), // Darker shade
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor, // Solid color for light theme
                  ],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Premium Frosted Glass Header
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.8),
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.yellow
                              : Colors.indigo,
                          width: 5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // TioRes Branding with Multi-Color
                        Row(
                          children: [
                            Text(
                              'Tio',
                              style: TextStyle(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF00D9FF), // Cyan
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              'Res',
                              style: TextStyle(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFFF6B6B), // Coral Red
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 20.w),
                        // Date & Time Display
                        StreamBuilder(
                          stream: Stream<int>.periodic(const Duration(seconds: 1), (i) => i),
                          builder: (context, snapshot) {
                            final now = DateTime.now();
                            final locale =
                                Localizations.localeOf(context).languageCode;
                            final dateFormat = locale == 'th'
                                ? '${now.day}/${now.month}/${now.year + 543}'
                                : '${now.day}/${now.month}/${now.year}';
                            final timeFormat =
                                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                            return Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.1)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 14.sp, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                                  SizedBox(width: 6.w),
                                  Text(
                                    dateFormat,
                                    style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                        fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(width: 12.w),
                                  Icon(Icons.access_time,
                                      size: 14.sp, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                                  SizedBox(width: 6.w),
                                  Text(
                                    timeFormat,
                                    style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Spacer(),

                        // View Mode Toggle - Premium Style
                        Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.yellow.withValues(alpha: 0.08)
                                : Colors.indigo.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.yellow.withValues(alpha: 0.1)
                                  : Colors.indigo.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildViewModeButton(Icons.grid_view_rounded, 0),
                              SizedBox(width: 4.w),
                              _buildViewModeButton(Icons.map_rounded, 1),
                            ],
                          ),
                        ),
                        SizedBox(width: 20.w),

                        // Segmented Filter Pills
                        Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.yellow.withValues(alpha: 0.06)
                                : Colors.indigo.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.yellow.withValues(alpha: 0.08)
                                  : Colors.indigo.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildSegmentedFilter(l10n.all, -1, null),
                              _buildSegmentedFilter(
                                  l10n.available, 0, AppTheme.statusAvailable),
                              _buildSegmentedFilter(
                                  l10n.occupied, 1, AppTheme.statusOccupied),
                              _buildSegmentedFilter(
                                  l10n.cleaning, 2, AppTheme.statusCleaning),
                            ],
                          ),
                        ),

                        SizedBox(width: 16.w),

                        // Notification Bell - Premium Style
                        Consumer(builder: (context, ref, child) {
                          final notifState = ref.watch(notificationProvider);
                          final count = notifState.count;
                          final orders = notifState.pendingOrders;
                          return Container(
                            decoration: BoxDecoration(
                              color: count > 0 
                                  ? Colors.orange.withValues(alpha: 0.15)
                                  : Theme.of(context).brightness == Brightness.dark
                                      ? Colors.yellow.withValues(alpha: 0.08)
                                      : Colors.indigo.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12.r),
                              border: count > 0 ? Border.all(color: Colors.orange.withValues(alpha: 0.3)) : null,
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    if (count > 0 && orders.isNotEmpty) {
                                      // Show pending orders dialog
                                      PendingOrdersDialog.show(
                                        context,
                                        orders,
                                        () {
                                          // Refresh notification state
                                          ref.read(notificationProvider.notifier).refresh();
                                        },
                                      );
                                    } else {
                                      // Manual check for new orders
                                      ref.read(notificationProvider.notifier).refresh();
                                      PremiumToast.show(context, l10n.noPendingOrders);
                                    }
                                  },
                                  icon: Icon(
                                    count > 0 ? Icons.notifications_active : Icons.notifications_outlined,
                                    color: count > 0 
                                        ? Colors.orange 
                                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), 
                                    size: 24.sp,
                                  ),
                                ),
                                if (count > 0)
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFF6B6B),
                                            Color(0xFFEE5A5A)
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withValues(alpha: 0.5),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      constraints: BoxConstraints(
                                        minWidth: 20.w,
                                        minHeight: 20.w,
                                      ),
                                      child: Text(
                                        '$count',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),

                        SizedBox(width: 8.w),

                        // Menu Button - Premium Style
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.yellow.withValues(alpha: 0.08)
                                : Colors.indigo.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.menu_rounded,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 24.sp),
                            onPressed: () {
                              _scaffoldKey.currentState?.openEndDrawer();
                            },
                            tooltip: 'Open Menu',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Main Content with Toggle
              Expanded(
                child: Stack(
                  children: [
                    // Tables View (shown when takeaway collapsed)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: 0,
                      right: _takeawayExpanded ? MediaQuery.of(context).size.width : 40.w,
                      top: 0,
                      bottom: 0,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _takeawayExpanded ? 0.0 : 1.0,
                        child: Consumer(
                          builder: (context, ref, child) {
                            final tablesAsync = ref.watch(tablesProvider);

                            return tablesAsync.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (error, stack) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline,
                                        size: 64.sp, color: Colors.red),
                                    SizedBox(height: 16.h),
                                    Text(
                                      'Error loading tables',
                                      style: TextStyle(fontSize: 18.sp),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      error.toString(),
                                      style: TextStyle(
                                          fontSize: 14.sp, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              data: (tables) {
                                if (tables.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.table_restaurant,
                                            size: 64.sp, color: Colors.grey),
                                        SizedBox(height: 16.h),
                                        Text(
                                          'No tables available',
                                          style: TextStyle(fontSize: 18.sp),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                // Filter tables
                                final filteredTables = _selectedFilter == -1
                                    ? tables
                                    : tables
                                        .where((table) =>
                                            table.status == _selectedFilter)
                                        .toList();

                                // Calculate grid columns based on screen width
                                final crossAxisCount = _getCrossAxisCount();

                                return _viewMode == 0
                                    ? Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 32.w, vertical: 16.h),
                                        child: filteredTables.isEmpty
                                            ? Center(
                                                child: Text(
                                                  'No tables found',
                                                  style: TextStyle(
                                                      fontSize: 16.sp,
                                                      color: Colors.grey),
                                                ),
                                              )
                                            : GridView.builder(
                                                gridDelegate:
                                                    SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: crossAxisCount,
                                                  crossAxisSpacing: 20.w,
                                                  mainAxisSpacing: 20.h,
                                                  childAspectRatio:
                                                      1.0, // Square cards (shorter height)
                                                ),
                                                itemCount: filteredTables.length,
                                                cacheExtent: 500,
                                                itemBuilder: (context, index) {
                                                  final table =
                                                      filteredTables[index];
                                                  return RepaintBoundary(
                                                    child: _buildTableCard(table),
                                                  );
                                                },
                                              ),
                                      )
                                    : _buildMapView(filteredTables);
                              },
                            );
                          },
                        ),
                      ),
                    ),

                    // Takeaway Panel (shown when expanded)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: _takeawayExpanded ? 40.w : MediaQuery.of(context).size.width,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _takeawayExpanded ? 1.0 : 0.0,
                        child: TakeawayOrderPanel(
                          onOrderComplete: () {
                            // Optionally refresh or show success
                          },
                        ),
                      ),
                    ),

                    // Toggle Button - always visible on right edge
                    Positioned(
                      right: _takeawayExpanded ? null : 0,
                      left: _takeawayExpanded ? 0 : null,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _takeawayExpanded = !_takeawayExpanded;
                          });
                        },
                        child: Container(
                          width: 40.w,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.orange, Colors.deepOrange],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _takeawayExpanded
                                    ? Icons.keyboard_double_arrow_right
                                    : Icons.keyboard_double_arrow_left,
                                color: Colors.white,
                                size: 28.sp,
                              ),
                              SizedBox(height: 16.h),
                              RotatedBox(
                                quarterTurns: _takeawayExpanded ? 1 : 3,
                                child: Text(
                                  l10n.takeAway.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Icon(
                                Icons.takeout_dining,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Premium View Mode Button
  Widget _buildViewModeButton(IconData icon, int mode) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          icon,
          size: 20.sp,
          color: isSelected 
              ? Theme.of(context).primaryColor 
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  /// Premium Segmented Filter Pill
  Widget _buildSegmentedFilter(String label, int value, Color? accentColor) {
    final isSelected = _selectedFilter == value;
    final color = accentColor ?? Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: isSelected
              ? Border.all(color: color.withValues(alpha: 0.4), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected && value != -1) ...[
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? color 
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a single table card with Premium Design
  Widget _buildTableCard(TableModel table) {
    final statusColor = _getStatusColor(table.status);
    final isOccupied = table.status == 1;
    final isCleaning = table.status == 2;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          decoration: BoxDecoration(
            gradient: Theme.of(context).brightness == Brightness.dark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.03),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).cardColor,
                      Theme.of(context).cardColor,
                    ],
                  ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isOccupied
                  ? statusColor.withValues(alpha: 0.3)
                  : Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
              width: isOccupied ? 1.5 : 1,
            ),
            boxShadow: isOccupied
                ? [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Material(
              color: _getStatusColor(table.status).withValues(alpha: 0.5),
              child: InkWell(
                onTap: () => _handleTableTap(table),
                onLongPress:
                    isOccupied ? () => _handleTableLongPress(table) : null,
                borderRadius: BorderRadius.circular(24.r),
                splashColor: statusColor.withValues(alpha: 0.1),
                highlightColor: statusColor.withValues(alpha: 0.05),
                child: Stack(
                  children: [
                    // Status Glow - Top Right Corner
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 100.w,
                        height: 100.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              statusColor.withValues(alpha: 0.25),
                              statusColor.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Cleaning Overlay Pattern
                    if (isCleaning)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24.r),
                            color:
                                AppTheme.statusCleaning.withValues(alpha: 0.05),
                          ),
                        ),
                      ),

                    Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Row: Table Name + Status Icon
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Table Name
                              Expanded(
                                child: Text(
                                  table.tableName,
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Status Icon with Glow
                              Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  _getTableIcon(table.status),
                                  size: 14.sp,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 4.h),

                          // Content: Price (Occupied) or Status Badge
                          if (isOccupied && table.totalAmount != null) ...[
                            Text(
                              '฿${_formatCurrency(table.totalAmount!)}',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ] else ...[
                            // Status Badge - Compact
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                    color: Colors.black.withValues(alpha: 0.1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6.w,
                                    height: 6.w,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    table.statusText,
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }

  /// Handle table tap based on status
  Future<void> _handleTableTap(TableModel table) async {
    // Check if shift is open
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

    if (table.status == 0) {
      // Available - open table with headcount and tier selection
      _showOpenTableDialog(table);
    } else if (table.status == 1) {
      // Occupied - navigate to POS screen
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => POSScreen(table: table),
        ),
      );
    } else {
      // Cleaning - show cleaning dialog
      _showCleaningDialog(table);
    }
  }

  /// Show dialog to finish cleaning
  void _showCleaningDialog(TableModel table) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context)!.cancel,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 400.w,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                    width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 32,
                    spreadRadius: 8,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppTheme.statusCleaning.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cleaning_services_rounded,
                      size: 48.sp,
                      color: AppTheme.statusCleaning,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Header
                  Text(
                    AppLocalizations.of(context)!
                        .cleaningTable(table.tableName),
                    style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    AppLocalizations.of(context)!.tableBeingCleaned,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                  ),
                  SizedBox(height: 32.h),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 18.h),
                            side: BorderSide(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.2)),
                            foregroundColor: Theme.of(context).colorScheme.onSurface,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r)),
                          ),
                          child: Text(AppLocalizations.of(context)!.cancel,
                              style: TextStyle(fontSize: 16.sp)),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.statusAvailable,
                            foregroundColor: Theme.of(context).colorScheme.onSurface,
                            elevation: 8,
                            shadowColor:
                                AppTheme.statusAvailable.withValues(alpha: 0.4),
                            padding: EdgeInsets.symmetric(vertical: 18.h),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r)),
                          ),
                          onPressed: () async {
                            final dbHelper = DatabaseHelper();
                            try {
                              await dbHelper.markTableAvailable(table.id);
                              // Sync to cloud (Set to Available: 0)
                              await ApiService().updateTableStatus(table.id, 0);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ref.invalidate(tablesProvider);
                                PremiumToast.show(
                                  context,
                                  AppLocalizations.of(context)!
                                      .tableNowAvailable(table.tableName),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                PremiumToast.show(
                                  context,
                                  'Error: $e',
                                  isError: true,
                                );
                              }
                            }
                          },
                          child: Text(
                            AppLocalizations.of(context)!.finishCleaning,
                            style: TextStyle(
                                fontSize: 16.sp, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(scale: anim1.value, child: child);
      },
    );
  }

  /// Show modern dialog to open a table
  void _showOpenTableDialog(TableModel table) {
    int adults = 1;
    int children = 0;
    bool printReceipt = true; // Default to printing
    _selectedTier = _buffetTiers.isNotEmpty ? _buffetTiers.first : null;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 420.w,
                  padding: EdgeInsets.all(28.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 32,
                        spreadRadius: 8,
                      )
                    ],
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      // Header
                      Text(
                        'Open ${table.tableName}',
                        style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).textTheme.titleLarge?.color),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        AppLocalizations.of(context)!.selectGuestsAndTier,
                        style: TextStyle(
                            fontSize: 14.sp,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.7)),
                      ),
                      SizedBox(height: 24.h), // Reduced spacing

                      // Counters
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildModernCounter(
                              AppLocalizations.of(context)!.adults,
                              adults,
                              (val) => setDialogState(() => adults = val)),
                          Container(
                              width: 1,
                              height: 50.h,
                              color: Theme.of(context)
                                  .dividerColor), // Reduced height
                          _buildModernCounter(
                              AppLocalizations.of(context)!.children,
                              children,
                              (val) => setDialogState(() => children = val)),
                        ],
                      ),

                      SizedBox(height: 24.h), // Reduced spacing

                      // Buffet Tiers
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(AppLocalizations.of(context)!.buffetTier,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600)),
                      ),
                      SizedBox(height: 12.h), // Reduced spacing
                      Row(
                        children: _buffetTiers.map((tier) {
                          final isSelected = _selectedTier == tier;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4.w), // Reduced padding
                              child: InkWell(
                                onTap: () =>
                                    setDialogState(() => _selectedTier = tier),
                                borderRadius: BorderRadius.circular(16.r),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12.h), // Reduced padding
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context)
                                            .scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Theme.of(context).dividerColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(tier.name,
                                          style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.color,
                                              fontWeight: FontWeight.bold,
                                              fontSize:
                                                  14.sp)), // Reduced font size
                                      SizedBox(height: 4.h),
                                      Text(
                                          '${CurrencyHelper.symbol(context)}${tier.price.toInt()}',
                                          style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white.withOpacity(0.9) // White on colored background when selected
                                                  : Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.color,
                                              fontSize:
                                                  12.sp)), // Reduced font size
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      SizedBox(height: 24.h),

                      // Print Option
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.yellow.withValues(alpha: 0.1)
                                  : Colors.indigo.withValues(alpha: 0.1)),
                        ),
                        child: SwitchListTile(
                          value: printReceipt,
                          onChanged: (val) =>
                              setDialogState(() => printReceipt = val),
                          title: Text(
                              AppLocalizations.of(context)!.printReceipt,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          secondary: Icon(Icons.print,
                              color: Theme.of(context).primaryColor),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),

                      SizedBox(height: 40.h),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 18.h),
                              ),
                              child: Text(AppLocalizations.of(context)!.cancel,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color,
                                      fontSize: 16.sp)),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                foregroundColor: Colors.black,
                                elevation: 8,
                                shadowColor: Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withValues(alpha: 0.4),
                                padding: EdgeInsets.symmetric(vertical: 18.h),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.r)),
                              ),
                              onPressed: () async {
                                if (_selectedTier == null) return;
                                final dbHelper = DatabaseHelper();
                                try {
                                  final orderId = await dbHelper.openTable(
                                    tableId: table.id,
                                    adults: adults,
                                    children: children,
                                    buffetTierPrice: _selectedTier!.price,
                                  );

                                  // Sync table status to hosting (1 = occupied)
                                  ApiService().updateTableStatus(table.id, 1);

                                  // Print Receipt if requested
                                  if (printReceipt) {
                                    final order =
                                        await dbHelper.getOrder(orderId);
                                    if (order != null) {
                                      await PrinterService().printOpenTableReceipt(
                                        table: table,
                                        order: order,
                                        buffetTierId: _selectedTier?.id,
                                      );
                                    }
                                  }

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ref.invalidate(tablesProvider);
                                    PremiumToast.show(
                                      context,
                                      '${table.tableName} opened!',
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    PremiumToast.show(
                                      context,
                                      'Error: $e',
                                      isError: true,
                                    );
                                  }
                                }
                              },
                              child: Text(
                                  AppLocalizations.of(context)!
                                      .openTable
                                      .toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0)),
                            ),
                          ),
                        ],
                      )
                    ]),
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(opacity: anim1.value, child: child),
        );
      },
    );
  }

  /// Handle Long Press on Occupied Table (Move/Cancel)
  void _handleTableLongPress(TableModel table) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle Bar
              Container(
                margin: EdgeInsets.only(top: 12.h, bottom: 20.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Text(
                table.tableName,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24.h),

              // Options
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.drive_file_move, color: Colors.blue),
                ),
                title: Text(AppLocalizations.of(context)!.moveTable),
                onTap: () {
                  Navigator.pop(context);
                  _showMoveTableDialog(table);
                },
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cancel, color: Colors.red),
                ),
                title: Text(
                  AppLocalizations.of(context)!.cancelTable,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmCancelTable(table);
                },
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Show Move Table Dialog
  void _showMoveTableDialog(TableModel fromTable) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final tablesAsync = ref.watch(tablesProvider);
          return tablesAsync.when(
            data: (tables) {
              final availableTables = tables
                  .where((t) => t.status == AppConstants.tableAvailable)
                  .toList();

              return AlertDialog(
                title: Text(AppLocalizations.of(context)!.selectDestinationTable),
                content: SizedBox(
                  width: double.maxFinite,
                  child: availableTables.isEmpty
                      ? Center(child: Text(AppLocalizations.of(context)!.table)) 
                      : GridView.builder(
                          shrinkWrap: true,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10.h,
                            crossAxisSpacing: 10.w,
                            childAspectRatio: 1.5,
                          ),
                          itemCount: availableTables.length,
                          itemBuilder: (context, index) {
                            final table = availableTables[index];
                            return InkWell(
                              onTap: () async {
                                final dbHelper = DatabaseHelper();
                                try {
                                  await dbHelper.moveTable(fromTable.id, table.id);
                                  // Update API
                                  await ApiService().updateTableStatus(fromTable.id, 0);
                                  await ApiService().updateTableStatus(table.id, 1); // Assuming 1 is occupied
                                  
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ref.invalidate(tablesProvider);
                                    PremiumToast.show(
                                      context,
                                      AppLocalizations.of(context)!.tableMoved,
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    PremiumToast.show(context, 'Error: $e', isError: true);
                                  }
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.statusAvailable.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: AppTheme.statusAvailable),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  table.tableName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.statusAvailable,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          );
        },
      ),
    );
  }

  /// Confirm Cancel Table
  void _confirmCancelTable(TableModel table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.cancelTable),
        content: Text(AppLocalizations.of(context)!.confirmCancelTable),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              final dbHelper = DatabaseHelper();
              try {
                await dbHelper.cancelTableOrder(table.id);
                // Update API
                await ApiService().updateTableStatus(table.id, 0);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(tablesProvider);
                  PremiumToast.show(
                    context,
                    AppLocalizations.of(context)!.tableCancelled,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                   PremiumToast.show(context, 'Error: $e', isError: true);
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );
  }

  /// Get color based on table status
  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return AppTheme.statusAvailable;
      case 1:
        return AppTheme.statusOccupied;
      case 2:
        return AppTheme.statusCleaning;
      default:
        return Theme.of(context).disabledColor;
    }
  }

  /// Get icon based on table status
  IconData _getTableIcon(int status) {
    switch (status) {
      case 0: // Available
        return Icons.table_restaurant;
      case 1: // Occupied
        return Icons.dining;
      case 2: // Cleaning
        return Icons.cleaning_services;
      default:
        return Icons.table_restaurant;
    }
  }

  /// Calculate number of columns based on screen width
  int _getCrossAxisCount() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return 2;
    if (screenWidth < 900) return 3;
    if (screenWidth < 1200) return 4;
    return 5;
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  Widget _buildModernCounter(String label, int value, void Function(int) onChanged) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500)),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: Theme.of(context).textTheme.bodyMedium?.color,
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
              ),
              Container(
                width: 40.w,
                alignment: Alignment.center,
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 20.sp, // Reduced font size
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                color: Theme.of(context).colorScheme.secondary,
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightMenu(AppLocalizations l10n) {
    return RightMenuWidget(
      menuItems: [
        RightMenuItem(
          icon: Icons.dashboard_rounded,
          label: l10n.reports,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const ReportsScreen()),
          ),
        ),
        RightMenuItem(
          icon: Icons.logout_rounded,
          label: l10n.shift,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const ShiftScreen()),
          ),
        ),
        RightMenuItem(
          icon: Icons.restaurant_menu_rounded,
          label: l10n.menu,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const MenuManagementScreen()),
          ).then((_) => ref.invalidate(tablesProvider)),
        ),
        RightMenuItem(
          icon: Icons.local_offer_rounded,
          label: 'Buffet Tiers',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const BuffetTierScreen()),
          ),
        ),
        RightMenuItem(
          icon: Icons.table_restaurant_rounded,
          label: 'Tables',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const TableLayoutScreen()),
          ).then((_) => ref.invalidate(tablesProvider)),
        ),
        RightMenuItem(
          icon: Icons.people_rounded,
          label: 'Customers',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const CustomersScreen()),
          ),
        ),
        RightMenuItem(
          icon: Icons.discount_rounded,
          label: 'Promotions',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const PromotionsScreen()),
          ),
        ),
        RightMenuItem(
          icon: Icons.print_rounded,
          label: l10n.printers,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const PrinterSettingsScreen()),
          ),
        ),
        RightMenuItem(
          icon: Icons.receipt_long_rounded,
          label: l10n.layout,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
                builder: (_) => const VisualReceiptDesignerScreen()),
          ),
        ),
        RightMenuItem(
          icon: Icons.settings_rounded,
          label: l10n.settings,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
          ),
        ),
        RightMenuItem(
          icon: Icons.refresh_rounded,
          label: l10n.refresh,
          onTap: () => ref.invalidate(tablesProvider),
        ),
      ],
    );
  }

  Widget _buildMapView(List<TableModel> filteredTables) {
    return RepaintBoundary(
      child: Consumer(
        builder: (context, ref, child) {
          final objectsAsync = ref.watch(layoutObjectsProvider);
          return objectsAsync.when(
            data: (objects) {
              return Row(
                children: [
                  Expanded(
                    child: VisualFloorPlan(
                      tables: filteredTables,
                      objects: objects,
                      isEditable: false,
                      onTableTap: _handleTableTap,
                    ),
                  ),
                  RepaintBoundary(
                    child: LayoutSidePanel(tables: filteredTables),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error loading layout')),
          );
        },
      ),
    );
  }
}

