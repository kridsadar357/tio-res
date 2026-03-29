import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../services/database_helper.dart';
import '../utils/currency_helper.dart';
import '../utils/promptpay_helper.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_localizations.dart';
import 'management/customers_screen.dart';
import '../widgets/premium_toast.dart';
import '../services/printer_service.dart';
import '../models/table_model.dart';

/// CheckoutDialog: Handles payment and order completion
///
/// Features:
/// - Two payment methods: Cash and QR Code
/// - For Cash: Input received amount and calculate change
/// - For QR: Generate placeholder QR code (mockup)
/// - Displays order summary breakdown
/// - Confirms and completes the order
class CheckoutDialog extends StatefulWidget {
  final Order order;
  final double total;
  final VoidCallback onCheckoutSuccess;

  const CheckoutDialog({
    super.key,
    required this.order,
    required this.total,
    required this.onCheckoutSuccess,
  });

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  String _paymentMethod = 'CASH';
  final TextEditingController _amountReceivedController =
      TextEditingController();
  double _changeAmount = 0.0;

  // Loyalty Points
  Customer? _selectedCustomer;

  // Text-to-speech for Thai voice
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('th-TH');
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _amountReceivedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 900.w,
            constraints: BoxConstraints(
              maxHeight: 0.85.sh,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(),
                // Content
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Pane: Summary & Method
                      Expanded(
                        flex: 5,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(24.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildOrderSummary(),
                              SizedBox(height: 24.h),
                              _buildPaymentMethodSelection(),
                            ],
                          ),
                        ),
                      ),
                      // Divider
                      Container(
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      // Right Pane: Payment Details
                      Expanded(
                        flex: 6,
                        child: Container(
                          padding: EdgeInsets.all(24.w),
                          alignment: Alignment.topCenter,
                          child: _buildPaymentDetails(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Footer with buttons
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build dialog header
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Icon(Icons.payment,
              color: Theme.of(context).primaryColor, size: 28.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.checkout,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${AppLocalizations.of(context)!.order} #${widget.order.id} • ${widget.order.tableId != null ? "${AppLocalizations.of(context)!.table} ${widget.order.tableId}" : "Takeaway"}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            onPressed: () => Navigator.pop(context),
            tooltip: AppLocalizations.of(context)!.cancel,
          ),
        ],
      ),
    );
  }

  /// Build order summary section
  Widget _buildOrderSummary() {
    // Calculate breakdown
    final buffetCharge = widget.order.buffetCharge;
    final extraCharge = widget.total - buffetCharge;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt, size: 16.sp, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
              SizedBox(width: 8.w),
              Text(
                AppLocalizations.of(context)!.orderSummary,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _SummaryRow(
            label:
                '${AppLocalizations.of(context)!.buffetCharge} (${widget.order.totalHeadcount} × ${CurrencyHelper.symbol(context)}${widget.order.buffetTierPrice.toStringAsFixed(2)})',
            value: buffetCharge,
          ),
          SizedBox(height: 8.h),
          _SummaryRow(
            label: AppLocalizations.of(context)!.items,
            value: extraCharge,
          ),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 16.h),

          // Customer Selection
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => CustomersScreen(
                    isSelectionMode: true,
                    onSelect: (customer) {
                      setState(() {
                        _selectedCustomer = customer;
                      });
                    },
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedCustomer != null
                        ? Icons.person
                        : Icons.person_add_alt_1,
                    size: 20.sp,
                    color: _selectedCustomer != null
                        ? const Color(0xFF00E096)
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCustomer != null
                              ? _selectedCustomer!.name
                              : AppLocalizations.of(context)!.selectCustomer,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (_selectedCustomer != null)
                          Text(
                            '${_selectedCustomer!.points} pts',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_selectedCustomer != null)
                    Icon(Icons.edit, size: 16.sp, color: Colors.white54)
                  else
                    Icon(Icons.chevron_right,
                        size: 20.sp, color: Colors.white54),
                ],
              ),
            ),
          ),

          if (_selectedCustomer != null) ...[
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Loyalty Points',
                    style: TextStyle(
                        fontSize: 14.sp, color: const Color(0xFF00E096)),
                  ),
                ),
                Consumer<SettingsProvider>(
                  builder: (context, settings, child) {
                    final points =
                        (widget.total / settings.pointsPerBaht).floor();
                    return Text(
                      '+$points pts',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00E096),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 24.h),
          _SummaryRow(
            label: AppLocalizations.of(context)!.total.toUpperCase(),
            value: widget.total,
            isBold: true,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  /// Build payment method selection
  Widget _buildPaymentMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.paymentMethod,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _PaymentMethodCard(
                method: 'CASH',
                selectedMethod: _paymentMethod,
                onTap: () {
                  setState(() {
                    _paymentMethod = 'CASH';
                  });
                },
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _PaymentMethodCard(
                method: 'QR',
                selectedMethod: _paymentMethod,
                onTap: () {
                  setState(() {
                    _paymentMethod = 'QR';
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build payment details section
  Widget _buildPaymentDetails() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0), // Slide from right
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ));

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      child: _paymentMethod == 'CASH'
          ? _buildCashPaymentDetails()
          : _buildQRPaymentDetails(),
    );
  }

  /// Build cash payment details with numpad
  Widget _buildCashPaymentDetails() {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          // Amount to pay row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.amountToPay,
                style: TextStyle(fontSize: 13.sp, color: Colors.white70),
              ),
              Text(
                '฿${widget.total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Amount received display
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                  color: Colors.greenAccent.withValues(alpha: 0.3), width: 2),
            ),
            child: Row(
              children: [
                Text(
                  '฿',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _amountReceivedController.text.isEmpty
                        ? AppLocalizations.of(context)!.enterAmount
                        : _amountReceivedController.text,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: _amountReceivedController.text.isEmpty
                          ? Colors.white30
                          : Colors.greenAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6.h),

          // Quick amount buttons
          _buildQuickAmountRow(),
          SizedBox(height: 6.h),

          // Numpad
          _buildNumpad(),
          SizedBox(height: 6.h),

          // Change display
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: _changeAmount >= 0
                  ? Colors.greenAccent.withValues(alpha: 0.1)
                  : Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: _changeAmount >= 0
                    ? Colors.greenAccent.withValues(alpha: 0.3)
                    : Colors.redAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.change,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: _changeAmount >= 0
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                ),
                Text(
                  '฿${_changeAmount.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: _changeAmount >= 0
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// Build quick amount buttons row
  Widget _buildQuickAmountRow() {
    final quickAmounts = [
      {'label': 'พอดี', 'value': -1}, // -1 means exact amount
      {'label': '฿20', 'value': 20},
      {'label': '฿50', 'value': 50},
      {'label': '฿100', 'value': 100},
      {'label': '฿500', 'value': 500},
      {'label': '฿1000', 'value': 1000},
    ];

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: quickAmounts.map((item) {
        final isExact = item['value'] == -1;
        return Material(
          color: isExact
              ? Colors.greenAccent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
          child: InkWell(
            onTap: () {
              setState(() {
                if (isExact) {
                  _amountReceivedController.text =
                      widget.total.toStringAsFixed(2);
                } else {
                  final current =
                      double.tryParse(_amountReceivedController.text) ?? 0;
                  _amountReceivedController.text =
                      (current + (item['value'] as int)).toStringAsFixed(0);
                }
                _calculateChange();
              });
            },
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Text(
                item['label'] as String,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: isExact ? Colors.greenAccent : Colors.white70,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Build numpad
  Widget _buildNumpad() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Row(children: [
            _buildNumpadBtn('7'),
            _buildNumpadBtn('8'),
            _buildNumpadBtn('9'),
            _buildNumpadBtn('⌫', isAction: true, color: Colors.orange),
          ]),
          Row(children: [
            _buildNumpadBtn('4'),
            _buildNumpadBtn('5'),
            _buildNumpadBtn('6'),
            _buildNumpadBtn('C', isAction: true, color: Colors.red),
          ]),
          Row(children: [
            _buildNumpadBtn('1'),
            _buildNumpadBtn('2'),
            _buildNumpadBtn('3'),
            _buildNumpadBtn('00'),
          ]),
          Row(children: [
            _buildNumpadBtn('0'),
            _buildNumpadBtn('.'),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Material(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10.r),
                  child: InkWell(
                    onTap: _calculateChange,
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: Center(
                        child: Text(
                          'ตกลง',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildNumpadBtn(String label, {bool isAction = false, Color? color}) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Material(
          color: isAction
              ? (color ?? Colors.grey).withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.r),
          child: InkWell(
            onTap: () => _handleNumpadInput(label),
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleNumpadInput(String value) {
    final currentText = _amountReceivedController.text;

    setState(() {
      if (value == 'C') {
        _amountReceivedController.clear();
        _changeAmount = 0.0;
      } else if (value == '⌫') {
        if (currentText.isNotEmpty) {
          _amountReceivedController.text =
              currentText.substring(0, currentText.length - 1);
        }
      } else if (value == '.') {
        if (!currentText.contains('.') && currentText.isNotEmpty) {
          _amountReceivedController.text = '$currentText.';
        } else if (currentText.isEmpty) {
          _amountReceivedController.text = '0.';
        }
      } else if (value == '00') {
        if (currentText.isNotEmpty && currentText != '0') {
          _amountReceivedController.text = '${currentText}00';
        }
      } else {
        if (currentText == '0' && value != '.') {
          _amountReceivedController.text = value;
        } else {
          _amountReceivedController.text = currentText + value;
        }
      }
      _calculateChange();
    });
  }

  /// Build QR payment details
  Widget _buildQRPaymentDetails() {
    // Get PromptPay ID from Settings
    // Since we are inside a Dialog, we need access to the provider.
    // Assuming Provider is set up above MaterialApp/Scaffold.
    String promptPayId = '';
    try {
      promptPayId = context
          .read<SettingsProvider>()
          .promptPayId; // Use read to get current value
      // Or verify if consumer is needed. Settings won't change while dialog is open usually.
    } catch (_) {
      // Fallback or ignore if provider not found
    }

    // Generate Payload
    final qrData = PromptPayHelper.generatePayload(promptPayId, widget.total);

    return Container(
      key: const ValueKey('QR'), // Key for AnimatedSwitcher
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2, size: 20.sp, color: Colors.blueAccent),
              SizedBox(width: 8.w),
              Text(
                AppLocalizations.of(context)!.scanToPay,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          // QR Code
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: qrData.isNotEmpty
                ? QrImageView(
                    data: qrData,
                    size: 200.w,
                    backgroundColor: Colors.white,
                  )
                : SizedBox(
                    width: 200.w,
                    height: 200.w,
                    child: const Center(
                        child: Text('Setup PromptPay ID in Settings')),
                  ),
          ),
          SizedBox(height: 16.h),
          // Amount to pay
          _AmountRow(
            label: AppLocalizations.of(context)!.amountToPay,
            amount: widget.total,
            isBold: true,
            color: Colors.white,
          ),
          SizedBox(height: 16.h),
          // Scan instructions
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16.sp,
                  color: Colors.blueAccent,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Scan with any banking app',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// Build footer with action buttons
  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border:
            Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(fontSize: 18.sp),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _canCheckout ? _processCheckout : null,
              icon: const Icon(Icons.check_circle),
              label: Text(
                AppLocalizations.of(context)!.completeOrder,
                style: TextStyle(fontSize: 18.sp),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
                disabledBackgroundColor: Colors.grey.withValues(alpha: 0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate change based on amount received
  void _calculateChange() {
    final receivedText = _amountReceivedController.text.trim();
    if (receivedText.isEmpty) {
      setState(() {
        _changeAmount = 0.0;
      });
      return;
    }

    final received = double.tryParse(receivedText) ?? 0.0;
    setState(() {
      _changeAmount = received - widget.total;
    });
  }

  /// Check if checkout can proceed
  bool get _canCheckout {
    if (_paymentMethod == 'CASH') {
      final receivedText = _amountReceivedController.text.trim();
      final received = double.tryParse(receivedText) ?? 0.0;
      return received >= widget.total;
    }
    return true; // QR payment can proceed
  }

  /// Process checkout - shows confirmation dialog first
  Future<void> _processCheckout() async {
    double? amountReceived;
    if (_paymentMethod == 'CASH') {
      final receivedText = _amountReceivedController.text.trim();
      amountReceived = double.tryParse(receivedText);
      if (amountReceived == null || amountReceived < widget.total) {
        if (mounted) {
            PremiumToast.show(
            context,
            'Insufficient funds',
            isError: true,
          );
        }
        return;
      }

      // Show confirmation dialog with Thai voice
      final confirmed = await _showPaymentConfirmationDialog(amountReceived);
      if (!confirmed) return;
    }

    if (!mounted) return;

    try {
      final settings = context.read<SettingsProvider>();
      int pointsEarned = 0;
      if (_selectedCustomer != null) {
        pointsEarned = (widget.total / settings.pointsPerBaht).floor();
      }

      await DatabaseHelper().checkoutOrder(
        orderId: widget.order.id,
        paymentMethod: _paymentMethod,
        amountReceived: amountReceived,
        customerId: _selectedCustomer?.id,
        pointsEarned: pointsEarned,
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        
        // Print receipt after successful checkout
        try {
          // Get table and order items for printing
          final dbHelper = DatabaseHelper();
          TableModel? table;
          if (widget.order.tableId != null) {
            table = await dbHelper.getTable(widget.order.tableId!);
          }
          
          // If table not found, create a dummy table for printing
          table ??= TableModel(
            id: widget.order.tableId ?? 0,
            tableName: 'Table ${widget.order.tableId ?? 'N/A'}',
            status: 1,
            x: 0,
            y: 0,
            width: 100,
            height: 100,
          );
          
          final orderItems = await dbHelper.getOrderItems(widget.order.id);
          
          // Reload order to get updated total and payment method
          final updatedOrder = await dbHelper.getOrder(widget.order.id);
          final orderToPrint = updatedOrder ?? widget.order.copyWith(
            totalAmount: widget.total,
            paymentMethod: _paymentMethod,
          );
          
          // Print receipt
          await PrinterService().init();
          final printSuccess = await PrinterService().printReceipt(
            table: table,
            order: orderToPrint,
            orderItems: orderItems,
          );
          
          if (printSuccess) {
            // Receipt printed successfully - show message after a delay
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                PremiumToast.show(context, 'Receipt printed successfully');
              }
            });
          }
        } catch (e) {
          debugPrint('Error printing receipt: $e');
          // Don't block checkout if printing fails
        }

        Navigator.pop(context); // Close dialog
        widget.onCheckoutSuccess();

        // Success Message
        PremiumToast.show(
          context,
          '${l10n.order} #${widget.order.id} completed',
        );

        // Points Message
        if (pointsEarned > 0) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              PremiumToast.show(
                context,
                'Earned $pointsEarned points!',
              );
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        PremiumToast.show(
          context,
          'Error: $e',
          isError: true,
        );
      }
    }
  }

  /// Show payment confirmation dialog with Thai TTS
  Future<bool> _showPaymentConfirmationDialog(double amountReceived) async {
    final change = amountReceived - widget.total;

    // Speak the change amount in Thai
    await _speakChangeAmount(change);

    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 400.w,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success icon
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 48.sp,
                      color: Colors.greenAccent,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Title
                  Text(
                    'ยืนยันการชำระเงิน',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Amount details
                  _buildConfirmRow('ยอดชำระ', widget.total),
                  SizedBox(height: 8.h),
                  _buildConfirmRow('รับเงิน', amountReceived),
                  SizedBox(height: 8.h),
                  Divider(color: Colors.white.withValues(alpha: 0.2)),
                  SizedBox(height: 8.h),

                  // Change amount - highlighted
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                          color: Colors.greenAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'เงินทอน',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                        Text(
                          '฿${change.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3)),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child:
                              Text('ยกเลิก', style: TextStyle(fontSize: 16.sp)),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child:
                              Text('ยืนยัน', style: TextStyle(fontSize: 16.sp)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return result ?? false;
  }

  Widget _buildConfirmRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16.sp, color: Colors.white70),
        ),
        Text(
          '฿${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Speak the change amount in Thai
  Future<void> _speakChangeAmount(double change) async {
    try {
      final changeInt = change.floor();
      final changeSatang = ((change - changeInt) * 100).round();

      String speechText;
      if (changeSatang > 0) {
        speechText = 'เงินทอน $changeInt บาท $changeSatang สตางค์';
      } else {
        speechText = 'เงินทอน $changeInt บาท';
      }

      await _flutterTts.speak(speechText);
    } catch (e) {
      // Silently handle TTS errors to not interrupt checkout flow
      debugPrint('TTS Error: $e');
    }
  }
}

/// Widget for displaying a summary row
class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16.sp : 14.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isTotal
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.white70,
            ),
          ),
        ),
        Text(
          CurrencyHelper.format(context, value),
          style: TextStyle(
            fontSize: isTotal ? 18.sp : 14.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isTotal
                ? Theme.of(context).colorScheme.secondary
                : Colors.white,
            shadows: isTotal
                ? [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.5),
                      blurRadius: 10,
                    )
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}

/// Widget for displaying an amount row
class _AmountRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;
  final bool isBold;

  const _AmountRow({
    required this.label,
    required this.amount,
    this.color,
    this.isBold = false,
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
            color: Colors.white,
          ),
        ),
        Text(
          CurrencyHelper.format(context, amount),
          style: TextStyle(
            fontSize: isBold ? 18.sp : 16.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.white,
            shadows: isBold || color != null
                ? [
                    BoxShadow(
                      color: (color ?? Colors.white).withValues(alpha: 0.5),
                      blurRadius: 8,
                    )
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}

/// Widget for payment method selection card
class _PaymentMethodCard extends StatelessWidget {
  final String method;
  final String selectedMethod;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.method,
    required this.selectedMethod,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = method == selectedMethod;
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                isSelected ? primaryColor : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              method == 'CASH' ? Icons.money : Icons.qr_code_2,
              size: 32.sp,
              color: isSelected ? primaryColor : Colors.white54,
            ),
            SizedBox(height: 8.h),
            Text(
              method == 'CASH'
                  ? AppLocalizations.of(context)!.cash
                  : AppLocalizations.of(context)!.qrCode,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isSelected ? primaryColor : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
