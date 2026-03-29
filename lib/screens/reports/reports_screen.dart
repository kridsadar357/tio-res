import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/premium_scaffold.dart';
import '../../services/database_helper.dart';
import '../../utils/currency_helper.dart';
import '../../l10n/app_localizations.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Report state
  bool _isLoading = true;
  double _salesTotal = 0.0;
  int _ordersTotal = 0;
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _hourlySales = [];
  List<Map<String, dynamic>> _categorySales = [];

  // Date Filter
  DateTime _selectedDate = DateTime.now();

  // Pagination
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _offset = 0;
        _recentTransactions = [];
        _hasMore = true;
      });
    }

    // Calculate start/end of day
    final startOfDay =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)
            .millisecondsSinceEpoch;
    final endOfDay = DateTime(_selectedDate.year, _selectedDate.month,
            _selectedDate.day, 23, 59, 59, 999)
        .millisecondsSinceEpoch;

    // Fetch summaries only on initial load or date change
    if (reset) {
      final summary = await DatabaseHelper()
          .getSalesSummary(startTime: startOfDay, endTime: endOfDay);
      final hourly =
          await DatabaseHelper().getHourlySales(startOfDay, endOfDay);
      final categories = await DatabaseHelper().getTopSellingCategories(
          startTime: startOfDay, endTime: endOfDay, limit: 5);

      if (mounted) {
        setState(() {
          _salesTotal = summary['total_sales'] as double;
          _ordersTotal = summary['total_orders'] as int;
          _hourlySales = hourly;
          _categorySales = categories;
        });
      }
    }

    // Fetch transactions with pagination
    final transactions = await DatabaseHelper().getRecentTransactions(
      limit: _limit,
      offset: _offset,
      startTime: startOfDay,
      endTime: endOfDay,
    );

    if (mounted) {
      setState(() {
        if (reset) {
          _recentTransactions = transactions;
        } else {
          _recentTransactions.addAll(transactions);
        }
        _offset += transactions.length;
        _hasMore = transactions.length == _limit;
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              onPrimary: Colors.white,
              surface: Color(0xFF1E2129),
              onSurface: Colors.white,
            ),
            dialogTheme:
                const DialogThemeData(backgroundColor: Color(0xFF1E2129)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadReportData(reset: true);
    }
  }

  Future<void> _showOrderDetails(int orderId) async {
    // Show loading
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final items = await DatabaseHelper().getOrderDetails(orderId);
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        barrierColor: Colors.black.withValues(alpha: 0.8),
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, anim1, anim2) {
          return Center(
            child: _buildDetailsDialog(orderId, items),
          );
        },
        transitionBuilder: (context, anim1, anim2, child) {
          return Transform.scale(
            scale: Curves.easeOutBack.transform(anim1.value),
            child: FadeTransition(opacity: anim1, child: child),
          );
        },
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading details: $e')),
      );
    }
  }

  Widget _buildDetailsDialog(int orderId, List<Map<String, dynamic>> items) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 450.w,
        constraints: BoxConstraints(maxHeight: 600.h),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2D3A).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 40,
              spreadRadius: 10,
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.transparent
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #$orderId',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${items.length} Items',
                            style: GoogleFonts.outfit(
                              color: Colors.white54,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
                // List
                Flexible(
                  child: ListView.separated(
                    padding: EdgeInsets.all(24.w),
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (context, index) => Divider(
                        color: Colors.white.withValues(alpha: 0.05),
                        height: 32.h),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final name = item['name'] as String;
                      final qty = item['quantity'] as int;
                      final price = item['price'] as double;
                      final total = item['total'] as double;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              '${qty}x',
                              style: GoogleFonts.outfit(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  '@ ${CurrencyHelper.format(context, price)}',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white38,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyHelper.format(context, total),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Footer
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    border: Border(
                      top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 16.sp,
                        ),
                      ),
                      // We need to sum up here or pass total from parent.
                      // Recalculating for now to be safe
                      Text(
                        CurrencyHelper.format(
                            context,
                            items.isEmpty
                                ? 0
                                : items.fold(
                                    0,
                                    (sum, item) =>
                                        sum + (item['total'] as double))),
                        style: GoogleFonts.outfit(
                          color: Colors.greenAccent,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            BoxShadow(
                                color:
                                    Colors.greenAccent.withValues(alpha: 0.3),
                                blurRadius: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PremiumScaffold(
      header: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Row(
          children: [
            _buildGlassButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
            SizedBox(width: 24.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.salesReports,
                  style: GoogleFonts.outfit(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4.h),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(50.r),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14.sp, color: const Color(0xFF6C63FF)),
                        SizedBox(width: 8.w),
                        Text(
                          DateFormat.yMMMMEEEEd().format(_selectedDate),
                          style: GoogleFonts.outfit(
                            fontSize: 14.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(Icons.keyboard_arrow_down,
                            size: 16.sp, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            _buildGlassButton(
              icon: Icons.refresh,
              onTap: () => _loadReportData(reset: true),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKpiGrid(),
                  SizedBox(height: 24.h), // Reduced spacing
                  SizedBox(
                    height: 300.h, // Reduced from 400.h
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildHourlyChartCard(),
                        ),
                        SizedBox(width: 24.w),
                        Expanded(
                          flex: 2,
                          child: _buildCategoryPieCard(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h), // Reduced spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.recentTransactions,
                        style: GoogleFonts.outfit(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (_recentTransactions.isNotEmpty)
                        Text(
                          'Showing ${_recentTransactions.length} of ${_hasMore ? "many" : "all"}',
                          style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: 14.sp,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12.h), // Reduced spacing
                  _buildTransactionsList(),
                  if (_hasMore)
                    Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 16.h), // Reduced padding
                      child: Center(
                        child: _isLoadingMore
                            ? const CircularProgressIndicator()
                            : TextButton(
                                onPressed: () {
                                  setState(() => _isLoadingMore = true);
                                  _loadReportData(reset: false);
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24.w, vertical: 12.h),
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.05),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(50.r)),
                                ),
                                child: Text('Load More Transactions',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white70)),
                              ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildGlassButton(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: Colors.white70, size: 20.sp),
      ),
    );
  }

  Widget _buildKpiGrid() {
    final l10n = AppLocalizations.of(context)!;
    final avgOrder = _ordersTotal > 0 ? _salesTotal / _ordersTotal : 0.0;
    final topCategory = _categorySales.isNotEmpty
        ? _categorySales.first['category_name'] as String
        : '-';

    return Row(
      children: [
        _buildKpiCard(
          l10n.totalSales,
          CurrencyHelper.formatWhole(context, _salesTotal),
          Icons.attach_money,
          const Color(0xFF00C853), // Green for money
        ),
        SizedBox(width: 24.w),
        _buildKpiCard(
          l10n.totalOrders,
          _ordersTotal.toString(),
          Icons.receipt_long,
          const Color(0xFF2962FF), // Blue for volume
        ),
        SizedBox(width: 24.w),
        _buildKpiCard(
          'Avg. Order', // Need localization
          CurrencyHelper.formatWhole(context, avgOrder),
          Icons.analytics,
          const Color(0xFFFFAB00), // Amber for analytics
        ),
        SizedBox(width: 24.w),
        _buildKpiCard(
          'Top Category', // Need localization
          topCategory,
          Icons.star,
          const Color(0xFFAA00FF), // Purple for premium
        ),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        height: 125.h, // Increased slightly from 110.h to fix overflow
        padding: EdgeInsets.all(12.w), // Reduced padding from 16.w
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22.sp, // Reduced from 24.sp
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 2.h), // Reduced from 4.h
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 12.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyChartCard() {
    List<FlSpot> spots = [];
    if (_hourlySales.isEmpty) {
      // Empty data placeholders
      for (int i = 0; i < 24; i += 4) {
        spots.add(FlSpot(i.toDouble(), 0));
      }
    } else {
      // Fill 0-23 hours
      for (int i = 0; i < 24; i++) {
        final hourData = _hourlySales.firstWhere(
            (e) => int.parse(e['hour'] as String) == i,
            orElse: () => {});
        if (hourData.isNotEmpty) {
          spots
              .add(FlSpot(i.toDouble(), (hourData['total'] as num).toDouble()));
        } else {
          spots.add(FlSpot(i.toDouble(), 0));
        }
      }
    }

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales Trend', // Localization needed
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'Performance',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF00C853),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            ],
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  verticalInterval: 6,
                  horizontalInterval: _salesTotal > 0 ? _salesTotal / 4 : 100,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 4,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${value.toInt()}:00',
                            style: GoogleFonts.outfit(
                              color: Colors.white38,
                              fontSize: 12.sp,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          CurrencyHelper.formatCompact(value),
                          style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: 10.sp,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 23,
                minY: 0,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          const Color(0xFF2A2D3A).withValues(alpha: 0.95),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                              '${spot.x.toInt()}:00\n',
                              GoogleFonts.outfit(
                                  color: Colors.white70, fontSize: 12.sp),
                              children: [
                                TextSpan(
                                  text: CurrencyHelper.formatWhole(
                                      context, spot.y),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                )
                              ]);
                        }).toList();
                      }),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35, // Smoother curve
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C853), Color(0xFF2962FF)],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: const Color(0xFF2962FF),
                          );
                        }),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00C853).withValues(alpha: 0.3),
                          const Color(0xFF2962FF).withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPieCard() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales by Category',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: _categorySales.isEmpty
                ? const Center(
                    child: Text('No Sales Data',
                        style: TextStyle(color: Colors.white30)))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 4, // Spaced out sections
                      centerSpaceRadius: 40, // Reduced radius
                      sections: _generatePieSections(),
                      pieTouchData: PieTouchData(
                          // Could add touch interactions here
                          ),
                    ),
                  ),
          ),
          SizedBox(height: 16.h),
          // Scrollable Legend if many categories
          Container(
            constraints: BoxConstraints(maxHeight: 100.h),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12.w,
                runSpacing: 8.h,
                alignment: WrapAlignment.center,
                children: _categorySales.map((item) {
                  final index = _categorySales.indexOf(item);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                            color: _getPieColor(index),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: _getPieColor(index)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 6)
                            ]),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        item['category_name'] as String,
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 12.sp),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3A).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          // BackdropFilter optional here depending on performance
          child: child),
    );
  }

  List<PieChartSectionData> _generatePieSections() {
    return List.generate(_categorySales.length, (i) {
      final item = _categorySales[i];
      final total = item['total_sales'] as double;
      final isLarge = i == 0;
      final radius =
          isLarge ? 20.0 : 16.0; // Smaller radius for donut thickness

      return PieChartSectionData(
        color: _getPieColor(i),
        value: total,
        title: '${(total / _salesTotal * 100).toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: GoogleFonts.outfit(
          fontSize: isLarge ? 14.sp : 12.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: isLarge ? _buildPieBadge(item['category_name'] as String) : null,
        badgePositionPercentageOffset: 1.5,
      );
    });
  }

  Widget _buildPieBadge(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(4.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)
          ]),
      child: Text(
        text,
        style: GoogleFonts.outfit(
            color: Colors.black87,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getPieColor(int index) {
    const colors = [
      Color(0xFF2962FF), // Blue
      Color(0xFFAA00FF), // Purple
      Color(0xFFFFAB00), // Amber
      Color(0xFF00C853), // Green
      Color(0xFFD50000), // Red
    ];
    return colors[index % colors.length];
  }

  Widget _buildTransactionsList() {
    final l10n = AppLocalizations.of(context)!;

    if (_recentTransactions.isEmpty) {
      // ... empty state ...
      return Center(
          child: Text("No transactions",
              style: GoogleFonts.outfit(color: Colors.white54)));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentTransactions.length,
      separatorBuilder: (context, index) => SizedBox(height: 8.h), // Reduced
      itemBuilder: (context, index) {
        final tx = _recentTransactions[index];
        final amount = tx['total_amount'] as double? ?? 0.0;
        final timeMs = tx['transaction_time'] as int? ?? 0;
        final time = DateFormat('HH:mm')
            .format(DateTime.fromMillisecondsSinceEpoch(timeMs));
        final id = tx['order_id']; // Use order_id instead of transaction id
        final paymentMethod = (tx['payment_method'] as String?) ?? 'CASH';

        final tableName = tx['table_name'];
        final orderType = tableName == null ? 'Takeaway' : 'Table $tableName';

        return InkWell(
          onTap: () => _showOrderDetails(id as int),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: 20.w, vertical: 12.h), // Reduced vertical padding
            decoration: BoxDecoration(
              color: const Color(0xFF2A2D3A).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w, // Reduced from 48
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: (paymentMethod == 'CASH'
                            ? const Color(0xFF00C853)
                            : const Color(0xFF2962FF))
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    paymentMethod == 'CASH'
                        ? Icons.payments_outlined
                        : Icons.qr_code_2,
                    color: (paymentMethod == 'CASH'
                        ? const Color(0xFF00C853)
                        : const Color(0xFF2962FF)),
                    size: 20.sp, // Reduced
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${l10n.order} #$id',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                                color: tableName == null
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4.r)),
                            child: Text(
                              orderType,
                              style: GoogleFonts.outfit(
                                  color: tableName == null
                                      ? Colors.orange
                                      : Colors.blue,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        time,
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyHelper.formatWhole(context, amount),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r)),
                      child: Text(
                        paymentMethod,
                        style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
                SizedBox(width: 8.w),
                Icon(Icons.chevron_right, color: Colors.white24, size: 20.sp),
              ],
            ),
          ),
        );
      },
    );
  }
}
