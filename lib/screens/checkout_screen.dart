import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/table_model.dart';
import '../services/database_helper.dart';
import '../services/bluetooth_printer_service.dart';

/// ReceiptLine: Helper widget for receipt lines
class ReceiptLine extends StatelessWidget {
  final String label;
  final double? price;
  final double total;
  final bool isBold;
  final bool isTotal;

  const ReceiptLine({
    super.key,
    required this.label,
    this.price,
    required this.total,
    this.isBold = false,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18.sp : 14.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.deepOrange : Colors.grey.shade700,
          ),
        ),
        if (price != null) ...[
          Text(
            '\$${price!.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
        Text(
          '\$${total.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 24.sp : 16.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? Colors.deepOrange : Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}

/// PaymentMethodTab: Widget for payment method selection
class PaymentMethodTab extends StatelessWidget {
  final String method;
  final String selectedMethod;
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const PaymentMethodTab({
    super.key,
    required this.method,
    required this.selectedMethod,
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = method == selectedMethod;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected
              ? (method == 'CASH' ? Colors.green.shade50 : Colors.blue.shade50)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? (method == 'CASH' ? Colors.green : Colors.blue)
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28.sp,
              color: isSelected
                  ? (method == 'CASH'
                      ? Colors.green.shade700
                      : Colors.blue.shade700)
                  : Colors.grey.shade500,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (method == 'CASH'
                        ? Colors.green.shade700
                        : Colors.blue.shade700)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// KeypadButton: Widget for numeric keypad buttons
class KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSpecial;
  final bool isAction;
  final Color color;

  const KeypadButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isSpecial = false,
    this.isAction = false,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          decoration: BoxDecoration(
            color: isAction ? color : Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: isSpecial ? FontWeight.normal : FontWeight.bold,
                color: isAction
                    ? Colors.white
                    : (isSpecial ? Colors.deepOrange : Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// CheckoutScreen: Finalize transaction with payment processing
///
/// Layout: Split-View for Tablet Landscape
///
/// Left Pane (Receipt Preview):
/// - Buffet breakdown (Adult/Child pricing)
/// - List of extra items
/// - Grand total display
///
/// Right Pane (Payment Controls):
/// - Payment method tabs (CASH/QR SCAN)
/// - Numeric keypad for cash entry
/// - Change calculation (Received - Grand Total)
/// - QR code generation for QR SCAN mode
/// - Finalize button
///
/// Buffet Math Calculation:
/// - Buffet Subtotal = (Adults × Adult Price) + (Children × Child Price)
/// - Extras Subtotal = Sum of items with price > 0
/// - Grand Total = Buffet Subtotal + Extras Subtotal
class CheckoutScreen extends ConsumerStatefulWidget {
  final TableModel table;
  final Order order;

  const CheckoutScreen({
    super.key,
    required this.table,
    required this.order,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  // Payment methods
  String _paymentMethod = 'CASH';
  // Cash payment state
  final TextEditingController _amountReceivedController =
      TextEditingController();
  double _changeAmount = 0.0;
  // QR payment state
  String? _qrCodeData;
  bool _isQRConfirmed = false;
  // Order data
  List<OrderItem> _orderItems = [];
  double _buffetSubtotal = 0.0;
  double _extrasSubtotal = 0.0;
  double _grandTotal = 0.0;
  bool _isLoading = false;
  // Printer service
  final BluetoothPrinterService _printerService = BluetoothPrinterService();
  bool _isPrintingReceipt = false;

  // Buffet pricing (could be configured per restaurant)
  static const double _adultBuffetPrice = 25.0; // Example price per adult
  static const double _childBuffetPrice = 15.0; // Example price per child

  @override
  void initState() {
    super.initState();
    _loadOrderItems();
    _generateQRCode();
  }

  /// Load order items from database
  Future<void> _loadOrderItems() async {
    try {
      final dbHelper = DatabaseHelper();
      final items = await dbHelper.getOrderItems(widget.order.id);

      if (mounted) {
        setState(() {
          _orderItems = items;
          _calculateTotals();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading order items: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Generate QR code data for payment
  void _generateQRCode() {
    // Format: promptpay://[SHOP_ID]?amount=[GRAND_TOTAL]
    // For testing: Simple JSON format
    _qrCodeData = '''
{
  "shop_id": "respos_001",
  "table_id": "${widget.table.id}",
  "order_id": "${widget.order.id}",
  "amount": "$_grandTotal",
  "timestamp": "${DateTime.now().millisecondsSinceEpoch}"
}
'''
        .trim();
  }

  /// Calculate bill totals using "Buffet Math"
  void _calculateTotals() {
    // Buffet Subtotal: (Adult Count × Adult Price) + (Child Count × Child Price)
    final adultsCharge = widget.order.adultHeadcount * _adultBuffetPrice;
    final childrenCharge = widget.order.childHeadcount * _childBuffetPrice;
    _buffetSubtotal = adultsCharge + childrenCharge;

    // Extras Subtotal: Sum of all order_items where price > 0
    _extrasSubtotal = 0.0;
    for (final item in _orderItems) {
      if (item.hasExtraCharge) {
        _extrasSubtotal += item.totalPrice;
      }
    }

    // Grand Total: Buffet Subtotal + Extras Subtotal
    _grandTotal = _buffetSubtotal + _extrasSubtotal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSplitPaneLayout(),
    );
  }

  /// Build split-pane layout
  Widget _buildSplitPaneLayout() {
    return Row(
      children: [
        // LEFT PANE: Receipt Preview
        Expanded(
          flex: 1,
          child: _buildReceiptPane(),
        ),
        // Vertical Divider
        VerticalDivider(width: 1.w, thickness: 2, color: Colors.grey.shade300),
        // RIGHT PANE: Payment Controls
        Expanded(
          flex: 1,
          child: _buildPaymentPane(),
        ),
      ],
    );
  }

  // ==================== RECEIPT PANE (LEFT SIDE) ====================

  /// Build left pane with receipt preview
  Widget _buildReceiptPane() {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Receipt header
          _buildReceiptHeader(),
          const Divider(height: 2),
          // Receipt body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Buffet breakdown
                  _buildBuffetBreakdown(),
                  const Divider(),
                  // Extra items list
                  _buildExtraItemsList(),
                ],
              ),
            ),
          ),
          // Receipt footer (Grand Total)
          _buildReceiptFooter(),
        ],
      ),
    );
  }

  /// Build receipt header
  Widget _buildReceiptHeader() {
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
          // Table and order info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Table ${widget.table.tableName}',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Order #${widget.order.id}',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
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
          // Start time
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14.sp,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              SizedBox(width: 6.w),
              Text(
                'Started: ${_formatTime(widget.order.startDateTime)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build buffet breakdown section
  Widget _buildBuffetBreakdown() {
    final adultsCharge = widget.order.adultHeadcount * _adultBuffetPrice;
    final childrenCharge = widget.order.childHeadcount * _childBuffetPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BUFFET CHARGE',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 12.h),
        // Adult buffet line
        ReceiptLine(
          label: 'Adult Buffet x ${widget.order.adultHeadcount}',
          price: _adultBuffetPrice,
          total: adultsCharge,
        ),
        SizedBox(height: 8.h),
        // Child buffet line
        ReceiptLine(
          label: 'Child Buffet x ${widget.order.childHeadcount}',
          price: _childBuffetPrice,
          total: childrenCharge,
        ),
        SizedBox(height: 8.h),
        // Buffet subtotal line
        ReceiptLine(
          label: 'BUFFET SUBTOTAL',
          price: null,
          total: _buffetSubtotal,
          isBold: true,
        ),
      ],
    );
  }

  /// Build extra items list
  Widget _buildExtraItemsList() {
    final extraItems =
        _orderItems.where((item) => item.hasExtraCharge).toList();

    if (extraItems.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.restaurant_menu_outlined,
                size: 48.sp,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 12.h),
              Text(
                'No extra items',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EXTRA ITEMS',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 12.h),
        ...extraItems.map((item) => _buildExtraItemTile(item)),
      ],
    );
  }

  /// Build a single extra item tile
  Widget _buildExtraItemTile(OrderItem item) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          children: [
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item #${item.menuItemId}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item.formattedUnitPrice,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Quantity
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'x${item.quantity}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange.shade900,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Total price
            Text(
              item.formattedTotal,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build receipt footer with grand total
  Widget _buildReceiptFooter() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: Column(
        children: [
          // Buffet subtotal
          ReceiptLine(
            label: 'Buffet Subtotal',
            price: null,
            total: _buffetSubtotal,
          ),
          SizedBox(height: 8.h),
          // Extras subtotal
          ReceiptLine(
            label: 'Extras Subtotal',
            price: null,
            total: _extrasSubtotal,
          ),
          SizedBox(height: 8.h),
          const Divider(),
          SizedBox(height: 12.h),
          // GRAND TOTAL
          ReceiptLine(
            label: 'GRAND TOTAL',
            price: null,
            total: _grandTotal,
            isBold: true,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  // ==================== PAYMENT PANE (RIGHT SIDE) ====================

  /// Build right pane with payment controls
  Widget _buildPaymentPane() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Payment method tabs
          _buildPaymentMethodTabs(),
          const Divider(height: 2),
          // Payment content
          Expanded(
            child: _paymentMethod == 'CASH'
                ? _buildCashPayment()
                : _buildQRPayment(),
          ),
          // Finalize button
          _buildFinalizeButton(),
        ],
      ),
    );
  }

  /// Build payment method tabs
  Widget _buildPaymentMethodTabs() {
    return Container(
      padding: EdgeInsets.all(8.w),
      child: Row(
        children: [
          Expanded(
            child: PaymentMethodTab(
              method: 'CASH',
              selectedMethod: _paymentMethod,
              onTap: () {
                setState(() => _paymentMethod = 'CASH');
                _resetPaymentState();
              },
              icon: Icons.payments,
              label: 'Cash',
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: PaymentMethodTab(
              method: 'QR',
              selectedMethod: _paymentMethod,
              onTap: () {
                setState(() => _paymentMethod = 'QR');
                _resetPaymentState();
              },
              icon: Icons.qr_code_scanner,
              label: 'QR Scan',
            ),
          ),
        ],
      ),
    );
  }

  /// Reset payment state when switching methods
  void _resetPaymentState() {
    _amountReceivedController.clear();
    _changeAmount = 0.0;
    _isQRConfirmed = false;
  }

  // ==================== CASH PAYMENT MODE ====================

  /// Build cash payment interface with numpad
  Widget _buildCashPayment() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Total Amount Display
          Container(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade100, Colors.grey.shade50],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ยอดชำระ',
                  style:
                      TextStyle(fontSize: 16.sp, color: Colors.grey.shade600),
                ),
                Text(
                  '฿${_grandTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Amount Received Input
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.green.shade300, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'จำนวนเงินที่รับ',
                  style:
                      TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Text(
                      '฿',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _amountReceivedController.text.isEmpty
                            ? '0.00'
                            : _amountReceivedController.text,
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Quick Amount Buttons
          _buildQuickAmountButtons(),
          SizedBox(height: 16.h),

          // Numeric Keypad
          _buildNumericKeypad(),
          SizedBox(height: 16.h),

          // Change Display
          _buildChangeDisplay(),
        ],
      ),
    );
  }

  /// Build quick amount preset buttons
  Widget _buildQuickAmountButtons() {
    final quickAmounts = [20, 50, 100, 500, 1000];

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        // Exact amount button
        _buildQuickAmountBtn(
          label: 'พอดี',
          onTap: () {
            setState(() {
              _amountReceivedController.text = _grandTotal.toStringAsFixed(2);
              _calculateChange();
            });
          },
          isExact: true,
        ),
        // Quick amounts
        ...quickAmounts.map((amount) => _buildQuickAmountBtn(
              label: '฿$amount',
              onTap: () {
                setState(() {
                  final current =
                      double.tryParse(_amountReceivedController.text) ?? 0;
                  _amountReceivedController.text =
                      (current + amount).toStringAsFixed(0);
                  _calculateChange();
                });
              },
            )),
      ],
    );
  }

  Widget _buildQuickAmountBtn({
    required String label,
    required VoidCallback onTap,
    bool isExact = false,
  }) {
    return Material(
      color: isExact ? Colors.green.shade100 : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isExact ? Colors.green.shade400 : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: isExact ? Colors.green.shade700 : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  /// Build custom numeric keypad
  Widget _buildNumericKeypad() {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          // Row 1: 7 8 9
          Row(
            children: [
              _buildKeypadBtn('7'),
              _buildKeypadBtn('8'),
              _buildKeypadBtn('9'),
              _buildKeypadBtn('⌫', isAction: true, color: Colors.orange),
            ],
          ),
          // Row 2: 4 5 6
          Row(
            children: [
              _buildKeypadBtn('4'),
              _buildKeypadBtn('5'),
              _buildKeypadBtn('6'),
              _buildKeypadBtn('C', isAction: true, color: Colors.red),
            ],
          ),
          // Row 3: 1 2 3
          Row(
            children: [
              _buildKeypadBtn('1'),
              _buildKeypadBtn('2'),
              _buildKeypadBtn('3'),
              _buildKeypadBtn('00'),
            ],
          ),
          // Row 4: 0 . Enter
          Row(
            children: [
              _buildKeypadBtn('0'),
              _buildKeypadBtn('.'),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Material(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12.r),
                    child: InkWell(
                      onTap: _calculateChange,
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: Center(
                          child: Text(
                            'ตกลง',
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadBtn(String label, {bool isAction = false, Color? color}) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Material(
          color: isAction ? (color ?? Colors.grey) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          elevation: 1,
          child: InkWell(
            onTap: () => _handleKeypadInput(label),
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: isAction ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handle keypad input
  void _handleKeypadInput(String value) {
    final currentText = _amountReceivedController.text;

    setState(() {
      if (value == 'C') {
        // Clear all
        _amountReceivedController.clear();
        _changeAmount = 0.0;
      } else if (value == '⌫') {
        // Backspace
        if (currentText.isNotEmpty) {
          _amountReceivedController.text =
              currentText.substring(0, currentText.length - 1);
        }
      } else if (value == '.') {
        // Add decimal point
        if (!currentText.contains('.') && currentText.isNotEmpty) {
          _amountReceivedController.text = '$currentText.';
        } else if (currentText.isEmpty) {
          _amountReceivedController.text = '0.';
        }
      } else if (value == '00') {
        // Add double zero
        if (currentText.isNotEmpty && currentText != '0') {
          _amountReceivedController.text = '${currentText}00';
        }
      } else {
        // Add number
        if (currentText == '0' && value != '.') {
          _amountReceivedController.text = value;
        } else {
          _amountReceivedController.text = currentText + value;
        }
      }
      // Auto-calculate change on each input
      _calculateChange();
    });
  }

  /// Clear input
  void _clearInput() {
    setState(() {
      _amountReceivedController.clear();
      _changeAmount = 0.0;
    });
  }

  /// Calculate change
  void _calculateChange() {
    final receivedText = _amountReceivedController.text.trim();
    if (receivedText.isEmpty) {
      _changeAmount = 0.0;
      return;
    }

    final received = double.tryParse(receivedText) ?? 0.0;
    _changeAmount = received - _grandTotal;
  }

  /// Build change display
  Widget _buildChangeDisplay() {
    final isPositive = _changeAmount >= 0;
    final received = double.tryParse(_amountReceivedController.text) ?? 0;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: received > 0
              ? (isPositive
                  ? [Colors.green.shade50, Colors.green.shade100]
                  : [Colors.red.shade50, Colors.red.shade100])
              : [Colors.grey.shade100, Colors.grey.shade200],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: received > 0
              ? (isPositive ? Colors.green.shade300 : Colors.red.shade300)
              : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'เงินทอน',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: received > 0
                  ? (isPositive ? Colors.green.shade700 : Colors.red.shade700)
                  : Colors.grey.shade600,
            ),
          ),
          Text(
            '฿${_changeAmount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: received > 0
                  ? (isPositive ? Colors.green.shade700 : Colors.red.shade700)
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== QR PAYMENT MODE ====================

  /// Build QR payment interface
  Widget _buildQRPayment() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          // QR Code Display
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Text(
                  'QR CODE PAYMENT',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 16.h),
                // QR Code display
                Container(
                  width: 200.sp,
                  height: 200.sp,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      'QR Code',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Scan to pay',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 8.h),
                // Amount display
                Text(
                  '\$${_grandTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          // Payment confirmation checkbox
          _buildQRConfirmation(),
          SizedBox(height: 24.h),
          // QR Code details (expandable)
          _buildQRDetails(),
        ],
      ),
    );
  }

  /// Build QR confirmation checkbox
  Widget _buildQRConfirmation() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.blue.shade300,
          width: 1,
        ),
      ),
      child: CheckboxListTile(
        value: _isQRConfirmed,
        onChanged: (value) {
          setState(() => _isQRConfirmed = value ?? false);
        },
        title: Text(
          'Payment Confirmed by Customer',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade900,
          ),
        ),
        subtitle: Text(
          'Check after customer scans: QR code',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.blue.shade700,
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        activeColor: Colors.blue,
      ),
    );
  }

  /// Build expandable QR details
  Widget _buildQRDetails() {
    return ExpansionTile(
      title: Text(
        'View QR Code Details',
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.blue.shade700,
        ),
      ),
      leading: const Icon(Icons.info_outline),
      children: [
        Padding(
          padding: EdgeInsets.all(16.w),
          child: SelectableText(
            _qrCodeData ?? 'No QR code generated',
            style: TextStyle(
              fontSize: 12.sp,
              fontFamily: 'monospace',
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== FINALIZE BUTTON ====================

  /// Build finalize order button
  Widget _buildFinalizeButton() {
    // Validation: Disable if:
    // - Cash: Amount received < grand total
    // - QR: Not confirmed
    final canFinish = _paymentMethod == 'CASH'
        ? (_changeAmount >= 0 && _amountReceivedController.text.isNotEmpty)
        : _isQRConfirmed;

    return Container(
      padding: EdgeInsets.all(20.w),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: canFinish ? _finalizeOrder : null,
          icon: const Icon(Icons.check_circle),
          label: Text(
            'Finish & Close Table',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 18.h),
            backgroundColor: canFinish ? Colors.green : Colors.grey.shade300,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== ORDER FINALIZATION ====================

  /// Finalize order and update database
  Future<void> _finalizeOrder() async {
    setState(() => _isLoading = true);

    try {
      final dbHelper = DatabaseHelper();

      // Process payment
      if (_paymentMethod == 'CASH') {
        // Cash payment: Use amount received
        final receivedText = _amountReceivedController.text.trim();
        final amountReceived = double.tryParse(receivedText) ?? 0.0;

        await dbHelper.checkoutOrder(
          orderId: widget.order.id,
          paymentMethod: 'CASH',
          amountReceived: amountReceived,
        );
      } else {
        // QR payment: No amount received needed
        await dbHelper.checkoutOrder(
          orderId: widget.order.id,
          paymentMethod: 'QR',
        );
      }

      if (mounted) {
        // Show print receipt dialog
        _showPrintReceiptDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error finalizing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Format time as HH:MM
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Show print receipt dialog
  void _showPrintReceiptDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Print Receipt?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text('Would you like to print a receipt for this order?'),
            const SizedBox(height: 8),
            Text(
              'Order #${widget.order.id}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _navigateBackToTableSelection();
            },
            child: const Text('Skip'),
          ),
          ElevatedButton.icon(
            onPressed: _isPrintingReceipt
                ? null
                : () async {
                    try {
                      setState(() => _isPrintingReceipt = true);
                      Navigator.of(context).pop(); // Close dialog

                      // Initialize printer
                      await _printerService.init();

                      // Print receipt
                      final success = await _printerService.printReceipt(
                        table: widget.table,
                        order: widget.order,
                        orderItems: _orderItems,
                      );

                      if (mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Receipt printed successfully'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          _showPrintErrorDialog();
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        _showPrintErrorDialog(errorMessage: e.toString());
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isPrintingReceipt = false);
                      }
                    }
                  },
            icon: _isPrintingReceipt
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print),
            label: const Text('Print Receipt'),
          ),
        ],
      ),
    );
  }

  /// Show print error dialog
  void _showPrintErrorDialog({String? errorMessage}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Print Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage ??
                  'Failed to print receipt. Please check your printer connection.',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateBackToTableSelection();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Navigate back to table selection
  void _navigateBackToTableSelection() {
    Navigator.of(context).pop();
    Navigator.of(context).pop(); // Pop back to TableSelectionScreen
  }

  @override
  void dispose() {
    _amountReceivedController.dispose();
    _printerService.dispose();
    super.dispose();
  }
}
