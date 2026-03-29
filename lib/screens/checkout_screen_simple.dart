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
/// - Payment method tabs (CASH only)
/// - Numeric keypad for cash entry
/// - Change calculation (Received - Grand Total)
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
  // Payment method (Cash only in this version - QR functionality requires additional dependencies)
  // Cash payment state
  final TextEditingController _amountReceivedController =
      TextEditingController();
  double _changeAmount = 0.0;
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
          child: _buildReceiptPane(),
        ),
        // Vertical Divider
        VerticalDivider(width: 1.w, thickness: 2, color: Colors.grey.shade300),
        // RIGHT PANE: Payment Controls (Cash only)
        Expanded(
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
            total: _buffetSubtotal,
          ),
          SizedBox(height: 8.h),
          // Extras subtotal
          ReceiptLine(
            label: 'Extras Subtotal',
            total: _extrasSubtotal,
          ),
          SizedBox(height: 8.h),
          const Divider(),
          SizedBox(height: 12.h),
          // GRAND TOTAL
          ReceiptLine(
            label: 'GRAND TOTAL',
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
          // Amount display
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Text(
                  'AMOUNT TO PAY',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '\$${_grandTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 36.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          // Numeric keypad
          _buildNumericKeypad(),
          SizedBox(height: 24.h),
          // Change display
          _buildChangeDisplay(),
          const Spacer(),
          // Finalize button
          _buildFinalizeButton(),
        ],
      ),
    );
  }

  /// Build custom numeric keypad
  Widget _buildNumericKeypad() {
    final buttons = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['C', '0', '.'],
    ];

    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          for (final row in buttons)
            Row(
              children: [
                for (final button in row)
                  Expanded(
                    child: KeypadButton(
                      label: button,
                      onTap: () => _handleKeypadInput(button),
                      isSpecial: button == 'C' || button == '.',
                    ),
                  ),
              ],
            ),
          // Bottom row: Enter/Clear keys
          Row(
            children: [
              Expanded(
                child: KeypadButton(
                  label: 'Enter',
                  onTap: () => _calculateChange(),
                  isAction: true,
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: KeypadButton(
                  label: 'Clear',
                  onTap: () => _clearInput(),
                  isAction: true,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Handle keypad input
  void _handleKeypadInput(String value) {
    final currentText = _amountReceivedController.text;

    if (value == 'C') {
      // Clear input
      _amountReceivedController.clear();
    } else if (value == '.') {
      // Add decimal point
      if (!currentText.contains('.')) {
        _amountReceivedController.text = '$currentText.';
      }
    } else {
      // Add number
      _amountReceivedController.text = currentText + value;
    }
  }

  /// Clear input
  void _clearInput() {
    _amountReceivedController.clear();
    _changeAmount = 0.0;
  }

  /// Calculate change
  void _calculateChange() {
    final receivedText = _amountReceivedController.text.trim();
    if (receivedText.isEmpty) {
      setState(() => _changeAmount = 0.0);
      return;
    }

    final received = double.tryParse(receivedText) ?? 0.0;
    final change = received - _grandTotal;

    setState(() => _changeAmount = change);
  }

  /// Build change display
  Widget _buildChangeDisplay() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: _changeAmount >= 0 ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Text(
            'CHANGE',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '\$${_changeAmount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: _changeAmount >= 0
                  ? Colors.green.shade700
                  : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FINALIZE BUTTON ====================

  /// Build finalize order button
  Widget _buildFinalizeButton() {
    // Validation: Disable if Amount received < grand total
    final canFinish =
        _changeAmount >= 0 && _amountReceivedController.text.isNotEmpty;

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

      // Cash payment: Use amount received
      final receivedText = _amountReceivedController.text.trim();
      final amountReceived = double.tryParse(receivedText) ?? 0.0;

      await dbHelper.checkoutOrder(
        orderId: widget.order.id,
        paymentMethod: 'CASH',
        amountReceived: amountReceived,
      );

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
    showDialog<void>(
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

                      if (!mounted) return;
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
    showDialog<void>(
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
