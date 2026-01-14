import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/premium_scaffold.dart';
import '../../services/database_helper.dart';
import '../../utils/currency_helper.dart';
import '../../l10n/app_localizations.dart';

class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  // Shift state
  bool _isLoading = true;
  Map<String, dynamic>? _currentShift;
  final TextEditingController _cashController =
      TextEditingController(text: '1000');

  // Calculated values for closing shift
  double _salesTotal = 0.0;
  double _expectedCash = 0.0;

  @override
  void initState() {
    super.initState();
    _loadShiftData();
  }

  Future<void> _loadShiftData() async {
    setState(() => _isLoading = true);
    final shift = await DatabaseHelper().getCurrentShift();

    if (shift != null) {
      // Shift is open, calculate current sales
      final startTime = shift['start_time'] as int;
      final startingCash = shift['starting_cash'] as double;
      final sales = await DatabaseHelper().getSalesTotalSince(startTime);

      if (mounted) {
        setState(() {
          _currentShift = shift;
          _salesTotal = sales;
          _expectedCash = startingCash + sales;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _currentShift = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleOpenShift() async {
    final startingCash = double.tryParse(_cashController.text) ?? 0.0;
    await DatabaseHelper().openShift(startingCash);
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shiftOpenedSuccessfully)),
      );
      _loadShiftData();
    }
  }

  Future<void> _handleCloseShift() async {
    // For now assuming actual cash matches expected (or user could input it)
    // In a real app we might ask for "Actual Cash" input
    await DatabaseHelper().closeShift(
      actualCash: _expectedCash, // verifying full amount
      expectedCash: _expectedCash,
    );

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shiftClosedSuccessfully)),
      );
      _loadShiftData();
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isShiftOpen = _currentShift != null;
    final l10n = AppLocalizations.of(context)!;

    return PremiumScaffold(
      header: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
            SizedBox(width: 16.w),
            Text(
              l10n.shiftManagement,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(isShiftOpen),
                  SizedBox(height: 32.h),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isShiftOpen
                        ? _buildCloseShiftForm()
                        : _buildOpenShiftForm(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(bool isShiftOpen) {
    final l10n = AppLocalizations.of(context)!;
    String statusText = isShiftOpen
        ? l10n.shiftOpen.toUpperCase()
        : l10n.shiftClosed.toUpperCase();
    String subText = isShiftOpen
        ? l10n.startedAt(_formatTime(_currentShift!['start_time']))
        : l10n.readyToStartNewShift;

    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isShiftOpen
              ? Colors.green.withValues( alpha : 0.3)
              : Colors.red.withValues( alpha : 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isShiftOpen
                ? Colors.green.withValues( alpha : 0.1)
                : Colors.red.withValues( alpha : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
                color: isShiftOpen
                    ? Colors.green.withValues( alpha : 0.1)
                    : Colors.red.withValues( alpha : 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isShiftOpen
                        ? Colors.green.withValues( alpha : 0.2)
                        : Colors.red.withValues( alpha : 0.2),
                    blurRadius: 12,
                  )
                ]),
            child: Icon(
              isShiftOpen ? Icons.check_circle_outline : Icons.lock_outline,
              size: 48.sp,
              color: isShiftOpen ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            statusText,
            style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0,
                shadows: [
                  BoxShadow(
                    color: isShiftOpen
                        ? Colors.greenAccent.withValues( alpha : 0.5)
                        : Colors.redAccent.withValues( alpha : 0.5),
                    blurRadius: 10,
                  )
                ]),
          ),
          SizedBox(height: 8.h),
          Text(
            subText,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int milliseconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildOpenShiftForm() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.startingCashFloat,
          style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: _cashController,
          keyboardType: TextInputType.number,
          style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixText: '฿ ',
            prefixStyle: TextStyle(color: Colors.white70, fontSize: 24.sp),
            filled: true,
            fillColor: Colors.white.withValues( alpha : 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: Colors.white.withValues( alpha : 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: Colors.greenAccent),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          ),
        ),
        SizedBox(height: 32.h),
        ElevatedButton(
          onPressed: _handleOpenShift,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 20.h),
            elevation: 8,
            shadowColor: Colors.green.withValues( alpha : 0.4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
          ),
          child: Text(
            l10n.openShiftAction,
            style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0),
          ),
        ),
      ],
    );
  }

  Widget _buildCloseShiftForm() {
    final startingCash =
        _currentShift != null ? _currentShift!['starting_cash'] as double : 0.0;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              _buildInfoRow(l10n.startingCash,
                  CurrencyHelper.formatWhole(context, startingCash)),
              _buildInfoRow(l10n.totalSalesCash,
                  CurrencyHelper.formatWhole(context, _salesTotal)),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Divider(color: Colors.white.withValues(alpha: 0.1)),
              ),
              _buildInfoRow(l10n.expectedCash,
                  CurrencyHelper.formatWhole(context, _expectedCash),
                  isBold: true, highlight: true),
            ],
          ),
        ),
        SizedBox(height: 48.h),
        ElevatedButton(
          onPressed: _handleCloseShift,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 20.h),
            elevation: 8,
            shadowColor: Colors.redAccent.withValues( alpha : 0.4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
          ),
          child: Text(
            l10n.closeShiftAction,
            style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isBold = false, bool highlight = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 16.sp)),
          Text(value,
              style: TextStyle(
                  color:
                      highlight ? Theme.of(context).primaryColor : Colors.white,
                  fontSize: 18.sp,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
