import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/receipt_layout.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/table_model.dart';

/// Utility class for generating ESC/POS receipt bytes
class ReceiptGenerator {
  static const int _defaultAdultPrice = 25;
  static const int _defaultChildPrice = 15;

  /// Generate receipt bytes
  static Future<Uint8List> generateReceipt({
    required TableModel table,
    required Order order,
    required List<OrderItem> orderItems,
    String restaurantName = 'ResPOS Restaurant',
    String restaurantAddress = '123 Main St, City',
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text(
      restaurantName,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        width: PosTextSize.size2,
        height: PosTextSize.size2,
      ),
    );

    bytes += generator.text(
      restaurantAddress,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: false,
      ),
    );

    bytes += generator.hr();
    bytes += generator.feed(1);

    // Order Info
    bytes += generator.row([
      PosColumn(
        text: 'Table:',
        width: 4,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: table.tableName,
        width: 8,
      ),
    ]);

    bytes += generator.row([
      PosColumn(
        text: 'Order:',
        width: 4,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: '#${order.id}',
        width: 8,
      ),
    ]);

    bytes += generator.row([
      PosColumn(
        text: 'Date:',
        width: 4,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: _formatDate(order.startDateTime),
        width: 8,
      ),
    ]);

    bytes += generator.row([
      PosColumn(
        text: 'Time:',
        width: 4,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: _formatTime(order.startDateTime),
        width: 8,
      ),
    ]);

    bytes += generator.hr();
    bytes += generator.feed(1);

    // Buffet Breakdown
    bytes += generator.text(
      'BUFFET CHARGES',
      styles: const PosStyles(bold: true),
    );

    bytes += generator.row([
      PosColumn(
        text: 'Adult Buffet (${order.adultHeadcount}x)',
        width: 10,
      ),
      PosColumn(
        text:
            '\$${(order.adultHeadcount * _defaultAdultPrice).toStringAsFixed(2)}',
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.row([
      PosColumn(
        text: 'Child Buffet (${order.childHeadcount}x)',
        width: 10,
      ),
      PosColumn(
        text:
            '\$${(order.childHeadcount * _defaultChildPrice).toStringAsFixed(2)}',
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    final buffetSubtotal = (order.adultHeadcount * _defaultAdultPrice) +
        (order.childHeadcount * _defaultChildPrice);

    bytes += generator.row([
      PosColumn(
        text: 'Buffet Subtotal',
        width: 10,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: '\$${buffetSubtotal.toStringAsFixed(2)}',
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    bytes += generator.hr();

    // Extra Items
    final extraItems = orderItems.where((item) => item.hasExtraCharge).toList();

    // Calculate extrasSubtotal
    final extrasSubtotal = extraItems.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );

    if (extraItems.isNotEmpty) {
      bytes += generator.feed(1);
      bytes += generator.text(
        'EXTRA ITEMS',
        styles: const PosStyles(bold: true),
      );

      for (final item in extraItems) {
        bytes += generator.row([
          PosColumn(
            text: 'Item #${item.menuItemId}',
            width: 7,
          ),
          PosColumn(
            text: 'x${item.quantity}',
            width: 2,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: item.formattedTotal,
            width: 7,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      bytes += generator.row([
        PosColumn(
          text: 'Extras Subtotal',
          width: 10,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: '\$${extrasSubtotal.toStringAsFixed(2)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      bytes += generator.hr();
    }

    // Totals
    bytes += generator.feed(1);
    bytes += generator.row([
      PosColumn(
        text: 'BUFFET SUBTOTAL',
        width: 10,
      ),
      PosColumn(
        text: '\$${buffetSubtotal.toStringAsFixed(2)}',
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.row([
      PosColumn(
        text: 'EXTRAS SUBTOTAL',
        width: 10,
      ),
      PosColumn(
        text: '\$${extrasSubtotal.toStringAsFixed(2)}',
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.hr();
    bytes += generator.feed(1);

    // Grand Total
    bytes += generator.row([
      PosColumn(
        text: 'GRAND TOTAL',
        width: 10,
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size2,
        ),
      ),
      PosColumn(
        text: '\$${order.totalAmount.toStringAsFixed(2)}',
        width: 6,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
        ),
      ),
    ]);

    bytes += generator.hr();
    bytes += generator.feed(1);

    // Payment Info
    bytes += generator.row([
      PosColumn(
        text: 'Payment Method:',
        width: 10,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: order.paymentMethod ?? 'N/A',
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    bytes += generator.feed(2);

    // Footer
    bytes += generator.text(
      'Thank you for dining with us!',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.feed(2);
    bytes += generator.hr();
    bytes += generator.text(
      'Powered by ResPOS',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(3);
    bytes += generator.cut();

    return Uint8List.fromList(bytes);
  }

  /// Generate "Open Table" receipt with QR Code
  static Future<Uint8List> generateOpenTableReceipt({
    required TableModel table,
    required Order order,
    required String qrPayload,
    String restaurantName = 'ResPOS Restaurant',
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    // Try to load custom layout
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('receipt_layout_opentable');
      if (jsonString != null) {
        final jsonMap = jsonDecode(jsonString);
        final layout = ReceiptLayout.fromJson(jsonMap);
        return _generateFromLayout(
          layout: layout,
          table: table,
          order: order,
          orderItems: [], // Not needed for open table
          qrPayload: qrPayload,
          restaurantName: restaurantName,
          paperSize: paperSize,
          isOpenTable: true,
        );
      }
    } catch (e) {
      // Fallback to default
      print('Error loading custom layout: $e');
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text(
      restaurantName,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        width: PosTextSize.size2,
        height: PosTextSize.size2,
      ),
    );
    bytes += generator.feed(1);
    bytes += generator.hr();

    // Table Info
    bytes += generator.text(
      'TABLE OPENED',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
      ),
    );
    bytes += generator.feed(1);

    bytes += generator.row([
      PosColumn(
        text: 'Table Name:',
        width: 6,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: table.tableName,
        width: 6,
        styles: const PosStyles(bold: true, width: PosTextSize.size2),
      ),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Order ID:', width: 6),
      PosColumn(text: '#${order.id}', width: 6),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Pax:', width: 6),
      PosColumn(
          text: '${order.adultHeadcount}A / ${order.childHeadcount}C',
          width: 6),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Start:', width: 6),
      PosColumn(text: _formatTime(order.startDateTime), width: 6),
    ]);

    bytes += generator.feed(1);
    bytes += generator.hr();
    bytes += generator.feed(1);

    // QR Code Section
    bytes += generator.text(
      'Scan to Order',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.feed(1);

    // Print QR Code
    // Size 4-8 is simplified range for esc_pos_utils
    bytes +=
        generator.qrcode(qrPayload, size: QRSize.size4, cor: QRCorrection.L);

    bytes += generator.feed(1);
    bytes += generator.text(
      qrPayload,
      styles:
          const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
    );

    bytes += generator.feed(2);
    bytes += generator.text(
      'Please keep this receipt',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(3);
    bytes += generator.cut();

    return Uint8List.fromList(bytes);
  }

  /// Generate test receipt bytes
  static Future<Uint8List> generateTestReceipt(
      {PaperSize paperSize = PaperSize.mm58}) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    bytes += generator.text(
      'TEST RECEIPT',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        width: PosTextSize.size2,
        height: PosTextSize.size2,
      ),
    );
    bytes += generator.feed(1);
    bytes += generator.hr();
    bytes += generator.feed(1);
    bytes += generator.text('This is a test receipt to verify',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('that your printer is',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('working correctly.',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.hr();
    bytes += generator.text('Test Complete!',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.feed(3);
    bytes += generator.cut();

    return Uint8List.fromList(bytes);
  }

  /// internal helper to render from layout
  static Future<Uint8List> _generateFromLayout({
    required ReceiptLayout layout,
    required TableModel table,
    required Order order,
    required List<OrderItem> orderItems,
    String? qrPayload,
    required String restaurantName,
    required PaperSize paperSize,
    bool isOpenTable = false,
  }) async {
    final profile = await CapabilityProfile.load();
    // Override paper size if specified in layout (optional, but good)
    // final generator = Generator(layout.paperSizeMm == 58 ? PaperSize.mm58 : PaperSize.mm80, profile);
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    for (final component in layout.components) {
      final align = _getPosAlign(component.style['alignment']);
      final isBold = component.style['bold'] == true;

      // Simple mapping for font size: > 20 is size2
      final textSize = (component.style['fontSize'] ?? 14) > 20
          ? PosTextSize.size2
          : PosTextSize.size1;

      switch (component.type) {
        case ReceiptComponentType.header:
          bytes += generator.text(
            component.data['text'] ?? restaurantName,
            styles: PosStyles(
              align: align,
              bold: isBold,
              width: textSize,
              height: textSize,
            ),
          );
          break;
        case ReceiptComponentType.text:
          bytes += generator.text(
            component.data['text'] ?? '',
            styles: PosStyles(
              align: align,
              bold: isBold,
              width: textSize,
              height: textSize,
            ),
          );
          break;
        case ReceiptComponentType.divider:
          bytes += generator.hr();
          break;
        case ReceiptComponentType.space:
          final lines = ((component.style['height'] ?? 20) / 20).ceil();
          bytes += generator.feed(lines);
          break;
        case ReceiptComponentType.qrcode:
          if (qrPayload != null) {
            bytes += generator.qrcode(qrPayload,
                size: QRSize.size4, cor: QRCorrection.L);
            // Optionally print the payload below
            bytes += generator.text(qrPayload,
                styles: const PosStyles(align: PosAlign.center));
          }
          break;
        case ReceiptComponentType.dynamicItems:
          if (isOpenTable) {
            // Render Table Info Block
            bytes += generator.text('TABLE OPENED',
                styles: const PosStyles(
                    align: PosAlign.center,
                    bold: true,
                    height: PosTextSize.size2));
            bytes += generator.feed(1);
            bytes += generator.row([
              PosColumn(
                  text: 'Table:',
                  width: 6,
                  styles: const PosStyles(bold: true)),
              PosColumn(
                  text: table.tableName,
                  width: 6,
                  styles:
                      const PosStyles(bold: true, width: PosTextSize.size2)),
            ]);
            bytes += generator.row([
              PosColumn(text: 'Order ID:', width: 6),
              PosColumn(text: '#${order.id}', width: 6),
            ]);
            bytes += generator.row([
              PosColumn(text: 'Pax:', width: 6),
              PosColumn(
                  text: '${order.adultHeadcount}A / ${order.childHeadcount}C',
                  width: 6),
            ]);
            bytes += generator.row([
              PosColumn(text: 'Start:', width: 6),
              PosColumn(text: _formatTime(order.startDateTime), width: 6),
            ]);
          } else {
            // Render Order Items (Check existing logic implementation if needed, but for now we focus on Open Table)
          }
          break;
        case ReceiptComponentType.image:
          // Placeholder
          break;
        default:
          break;
      }
    }

    bytes += generator.cut();
    return Uint8List.fromList(bytes);
  }

  static PosAlign _getPosAlign(String? align) {
    switch (align) {
      case 'center':
        return PosAlign.center;
      case 'right':
        return PosAlign.right;
      default:
        return PosAlign.left;
    }
  }

  /// Format date as YYYY-MM-DD
  static String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// Format time as HH:MM
  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
