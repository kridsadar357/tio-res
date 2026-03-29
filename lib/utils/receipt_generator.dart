import 'dart:typed_data';
import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/logger.dart';
import '../models/receipt_layout.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/table_model.dart';

/// Shop info loaded from settings
class _ShopInfo {
  final String name;
  final String address;
  final String tel;
  final String logoPath;
  
  _ShopInfo({
    this.name = '',
    this.address = '',
    this.tel = '',
    this.logoPath = '',
  });
  
  static Future<_ShopInfo> load() async {
    final prefs = await SharedPreferences.getInstance();
    return _ShopInfo(
      name: prefs.getString('shop_name') ?? '',
      address: prefs.getString('shop_address') ?? '',
      tel: prefs.getString('shop_tel') ?? '',
      logoPath: prefs.getString('shop_logo_path') ?? '',
    );
  }
}

/// Receipt localization helper - loads strings based on saved language setting
class _ReceiptL10n {
  final String buffetCharges;
  final String extraItems;
  final String buffetSubtotal;
  final String extrasSubtotal;
  final String grandTotal;
  final String thankYou;
  final String adult;
  final String child;
  final String table;
  final String order;
  final String date;
  final String time;
  final String guests;
  final String payment;
  final String orderItems;
  final String subtotal;
  
  _ReceiptL10n._({
    required this.buffetCharges,
    required this.extraItems,
    required this.buffetSubtotal,
    required this.extrasSubtotal,
    required this.grandTotal,
    required this.thankYou,
    required this.adult,
    required this.child,
    required this.table,
    required this.order,
    required this.date,
    required this.time,
    required this.guests,
    required this.payment,
    required this.orderItems,
    required this.subtotal,
  });
  
  static Future<_ReceiptL10n> load() async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString('language') ?? 'th';
    
    if (language == 'th') {
      return _ReceiptL10n._(
        buffetCharges: 'ค่าบุฟเฟต์',
        extraItems: 'รายการเพิ่มเติม',
        buffetSubtotal: 'รวมค่าบุฟเฟต์',
        extrasSubtotal: 'รวมค่าเพิ่มเติม',
        grandTotal: 'ยอดรวมทั้งหมด',
        thankYou: 'ขอบคุณที่มาใช้บริการ!',
        adult: 'ผู้ใหญ่',
        child: 'เด็ก',
        table: 'โต๊ะ',
        order: 'ออเดอร์',
        date: 'วันที่',
        time: 'เวลา',
        guests: 'จำนวน',
        payment: 'ชำระเงิน',
        orderItems: 'รายการสั่ง',
        subtotal: 'ยอดรวม',
      );
    } else {
      return _ReceiptL10n._(
        buffetCharges: 'BUFFET CHARGES',
        extraItems: 'EXTRA ITEMS',
        buffetSubtotal: 'Buffet Subtotal',
        extrasSubtotal: 'Extras Subtotal',
        grandTotal: 'GRAND TOTAL',
        thankYou: 'Thank you for dining with us!',
        adult: 'Adult',
        child: 'Child',
        table: 'Table',
        order: 'Order',
        date: 'Date',
        time: 'Time',
        guests: 'Guests',
        payment: 'Payment',
        orderItems: 'ORDER ITEMS',
        subtotal: 'Subtotal',
      );
    }
  }
}

/// Utility class for generating ESC/POS receipt bytes
class ReceiptGenerator {
  static const int _defaultAdultPrice = 25;
  static const int _defaultChildPrice = 15;

  /// Check if text contains non-ASCII characters (Thai, etc.)
  static bool _hasNonAscii(String text) {
    return text.runes.any((rune) => rune > 127);
  }
  
  /// Print a row with label and value, supporting Thai characters
  /// Uses _safeText for proper Thai encoding
  static List<int> _safeRow(
    Generator generator, 
    String label, 
    String value, {
    bool labelBold = false,
    bool valueBold = false,
    PosAlign valueAlign = PosAlign.right,
  }) {
    List<int> bytes = [];
    
    // For Thai text, print label and value on same line using tabs/spaces
    final hasThaiLabel = _hasNonAscii(label);
    final hasThaiValue = _hasNonAscii(value);
    
    if (hasThaiLabel || hasThaiValue) {
      // Use Thai-safe printing
      // Print the full line with padding
      final paddedLabel = label.padRight(16);
      final line = '$paddedLabel$value';
      
      bytes += _safeText(
        generator, 
        line, 
        PosStyles(bold: labelBold || valueBold),
      );
    } else {
      // ASCII only - use standard row
      bytes += generator.row([
        PosColumn(
          text: label,
          width: 6,
          styles: PosStyles(bold: labelBold),
        ),
        PosColumn(
          text: value,
          width: 6,
          styles: PosStyles(align: valueAlign, bold: valueBold),
        ),
      ]);
    }
    
    return bytes;
  }

  /// Safely print text with Thai character support
  /// Uses CP874 encoding for Thai characters
  static List<int> _safeText(Generator generator, String text, PosStyles styles) {
    // Check if text contains non-ASCII characters
    final hasThai = _hasNonAscii(text);
    
    if (hasThai) {
      // For Thai characters, we need to use CP874 encoding
      // ESC/POS command: ESC t n (n = 30 for CP874 / TIS-620)
      // Command: 0x1B 0x74 0x1E (ESC t 30)
      List<int> bytes = [];
      
      // Select code page 874 (Thai) - ESC t 30 (0x1E)
      bytes += [0x1B, 0x74, 0x1E]; // ESC t 30
      
      // Apply styles first
      if (styles.bold == true) {
        bytes += [0x1B, 0x45, 0x01]; // ESC E 1 (Bold on)
      }
      
      // Apply alignment
      switch (styles.align) {
        case PosAlign.center:
          bytes += [0x1B, 0x61, 0x01]; // ESC a 1 (Center)
          break;
        case PosAlign.right:
          bytes += [0x1B, 0x61, 0x02]; // ESC a 2 (Right)
          break;
        default:
          bytes += [0x1B, 0x61, 0x00]; // ESC a 0 (Left)
      }
      
      // Convert UTF-8 to CP874 (Windows-874/TIS-620) encoding
      try {
        // Method 1: Try using UTF-8 bytes directly
        // Many modern thermal printers support UTF-8 even with CP874 code page
        final utf8Bytes = utf8.encode(text);
        
        // Some printers can handle UTF-8 with CP874 code page selected
        // If this doesn't work, we'll need charset_converter package for proper CP874 conversion
        bytes += utf8Bytes;
        
        // Reset bold if was set
        if (styles.bold == true) {
          bytes += [0x1B, 0x45, 0x00]; // ESC E 0 (Bold off)
        }
        
        bytes += [0x0A]; // Line feed
        
        return bytes;
      } catch (e) {
        debugPrint('Error encoding Thai text to CP874: $e');
        // Fallback: try generator.text() which might handle it
        try {
          return generator.text(text, styles: styles);
        } catch (e2) {
          debugPrint('Fallback text() also failed: $e2');
          // Last resort: replace with '?'
          final sanitized = text.replaceAll(RegExp(r'[^\x00-\x7F]'), '?');
          return generator.text(sanitized, styles: styles);
        }
      }
    } else {
      // ASCII-only text, use normal method
      try {
        return generator.text(text, styles: styles);
      } catch (e) {
        debugPrint('Text encoding failed for ASCII text: $e');
        return [];
      }
    }
  }

  /// Generate receipt bytes
  static Future<Uint8List> generateReceipt({
    required TableModel table,
    required Order order,
    required List<OrderItem> orderItems,
    String restaurantName = 'ResPOS Restaurant',
    String restaurantAddress = '123 Main St, City',
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    // Try to load custom layout
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('receipt_layout_config');
      if (jsonString != null && jsonString.isNotEmpty) {
        debugPrint('Loading custom checkout receipt layout from SharedPreferences');
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        final layout = ReceiptLayout.fromJson(jsonMap);
        
        if (layout.components.isNotEmpty) {
          debugPrint('Using custom checkout layout with ${layout.components.length} components');
          // Use layout's paper size if specified, otherwise use parameter
          final layoutPaperSize = layout.paperSizeMm == 80 ? PaperSize.mm80 : PaperSize.mm58;
          return _generateFromLayout(
            layout: layout,
            table: table,
            order: order,
            orderItems: orderItems,
            qrPayload: null,
            restaurantName: restaurantName,
            paperSize: layoutPaperSize,
            isOpenTable: false,
          );
        } else {
          debugPrint('Custom checkout layout has no components, falling back to default');
        }
      } else {
        debugPrint('No custom checkout receipt layout found in SharedPreferences');
      }
    } catch (e, stackTrace) {
      // Fallback to default
      debugPrint('Error loading custom checkout layout: $e');
      debugPrint('Stack trace: $stackTrace');
      Logger.error('Error loading custom layout', error: e);
    }

    // Default receipt generation (fallback)
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
      if (jsonString != null && jsonString.isNotEmpty) {
        debugPrint('Loading custom open table layout from SharedPreferences');
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        final layout = ReceiptLayout.fromJson(jsonMap);
        
        if (layout.components.isNotEmpty) {
          debugPrint('Using custom layout with ${layout.components.length} components');
          // Use layout's paper size if specified, otherwise use parameter
          final layoutPaperSize = layout.paperSizeMm == 80 ? PaperSize.mm80 : PaperSize.mm58;
          return _generateFromLayout(
            layout: layout,
            table: table,
            order: order,
            orderItems: [], // Not needed for open table
            qrPayload: qrPayload,
            restaurantName: restaurantName,
            paperSize: layoutPaperSize,
            isOpenTable: true,
          );
        } else {
          debugPrint('Custom layout has no components, falling back to default');
        }
      } else {
        debugPrint('No custom open table layout found in SharedPreferences');
      }
    } catch (e, stackTrace) {
      // Fallback to default
      debugPrint('Error loading custom layout: $e');
      debugPrint('Stack trace: $stackTrace');
      Logger.error('Error loading custom layout', error: e);
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

  /// Generate kitchen order slip for web orders
  static Future<Uint8List> generateKitchenOrder({
    required String tableName,
    required List<Map<String, dynamic>> items,
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text(
      '** KITCHEN ORDER **',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        width: PosTextSize.size2,
        height: PosTextSize.size2,
      ),
    );
    bytes += generator.feed(1);
    
    // Table Name
    bytes += _safeText(
      generator,
      tableName,
      const PosStyles(
        align: PosAlign.center,
        bold: true,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.feed(1);
    
    // Time
    final now = DateTime.now();
    bytes += generator.text(
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();
    bytes += generator.feed(1);

    // Items
    for (final item in items) {
      final name = item['name'] as String? ?? '';
      final qty = item['quantity'] as int? ?? 1;
      final notes = item['notes'] as String? ?? '';

      // Quantity x Item Name
      bytes += _safeText(
        generator,
        '${qty}x  $name',
        const PosStyles(
          bold: true,
          width: PosTextSize.size1,
          height: PosTextSize.size2,
        ),
      );
      
      // Notes if any
      if (notes.isNotEmpty) {
        bytes += _safeText(
          generator,
          '    >> $notes',
          const PosStyles(fontType: PosFontType.fontB),
        );
      }
      bytes += generator.feed(1);
    }

    bytes += generator.hr();
    bytes += generator.text(
      'Total Items: ${items.length}',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
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
    // Use paper size from layout if available, otherwise use parameter
    final layoutPaperSize = layout.paperSizeMm == 80 ? PaperSize.mm80 : PaperSize.mm58;
    final generator = Generator(layoutPaperSize, profile);
    List<int> bytes = [];
    
    // Load localized strings based on language setting
    final l10n = await _ReceiptL10n.load();

    for (final component in layout.components) {
      final align = _getPosAlign(component.style['alignment'] as String?);
      final isBold = (component.style['bold'] as bool?) == true;

      // Simple mapping for font size: > 20 is size2
      final fontSize = (component.style['fontSize'] as num?)?.toInt() ?? 14;
      final textSize = fontSize > 20
          ? PosTextSize.size2
          : PosTextSize.size1;

      switch (component.type) {
        case ReceiptComponentType.header:
          final headerText = (component.data['text'] as String?) ?? restaurantName;
          bytes += _safeText(
            generator,
            headerText,
            PosStyles(
              align: align,
              bold: isBold,
              width: textSize,
              height: textSize,
            ),
          );
          break;
        case ReceiptComponentType.text:
          final textContent = (component.data['text'] as String?) ?? '';
          bytes += _safeText(
            generator,
            textContent,
            PosStyles(
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
          final height = (component.style['height'] as num?)?.toDouble() ?? 20.0;
          final lines = (height / 20).ceil();
          bytes += generator.feed(lines);
          break;
        case ReceiptComponentType.qrcode:
          if (qrPayload != null) {
            // Get QR size from component style, default to size4
            final qrSizeValue = (component.style['size'] as num?)?.toInt() ?? 4;
            // Map slider value (1-8) to QRSize enum (size1-size8, but esc_pos_utils uses size4-size8)
            QRSize qrSize;
            if (qrSizeValue <= 3) {
              qrSize = QRSize.size4;
            } else if (qrSizeValue <= 5) {
              qrSize = QRSize.size5;
            } else if (qrSizeValue <= 6) {
              qrSize = QRSize.size6;
            } else {
              qrSize = QRSize.size8;
            }
            bytes += generator.qrcode(qrPayload, size: qrSize, cor: QRCorrection.L);
            // Optionally print the payload below if specified in component data
            final showPayload = component.data['showPayload'] as bool? ?? true;
            if (showPayload) {
              bytes += generator.text(qrPayload,
                  styles: PosStyles(align: align, fontType: PosFontType.fontB));
            }
          }
          break;
        case ReceiptComponentType.dynamicItems:
          if (isOpenTable) {
            // Render Table Info Block
            try {
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
            } catch (e) {
              debugPrint('Error printing dynamicItems (open table): $e');
              // Fallback: print simplified version
              bytes += generator.text('TABLE OPENED',
                  styles: const PosStyles(
                      align: PosAlign.center,
                      bold: true,
                      height: PosTextSize.size2));
            }
          } else {
            // Render Order Items for checkout receipt
            try {
              // Debug: Log order data
              debugPrint('=== CHECKOUT RECEIPT DATA ===');
              debugPrint('Order ID: ${order.id}');
              debugPrint('Table: ${table.tableName}');
              debugPrint('Adult Headcount: ${order.adultHeadcount}');
              debugPrint('Child Headcount: ${order.childHeadcount}');
              debugPrint('Buffet Tier Price: ${order.buffetTierPrice}');
              debugPrint('Total Amount: ${order.totalAmount}');
              debugPrint('Order Items Count: ${orderItems.length}');
              debugPrint('============================');
              
              // Use actual buffet tier price from order
              final buffetPrice = order.buffetTierPrice;
              final isBuffetOrder = buffetPrice > 0 && (order.adultHeadcount > 0 || order.childHeadcount > 0);
              
              // Order Info Header - Use Thai localized labels
              bytes += generator.hr();
              bytes += _safeRow(generator, '${l10n.table}:', table.tableName, labelBold: true);
              bytes += _safeRow(generator, '${l10n.order}:', '#${order.id}', labelBold: true);
              bytes += _safeRow(generator, '${l10n.date}:', _formatDate(order.startDateTime), labelBold: true);
              bytes += _safeRow(generator, '${l10n.time}:', _formatTime(order.startDateTime), labelBold: true);
              
              // Only show guests for buffet orders
              if (isBuffetOrder) {
                bytes += _safeRow(generator, '${l10n.guests}:', '${order.adultHeadcount}A / ${order.childHeadcount}C', labelBold: true);
              }
              bytes += generator.hr();
              bytes += generator.feed(1);
              
              // BUFFET ORDER: Show buffet charges
              if (isBuffetOrder) {
                final adultCharge = order.adultHeadcount * buffetPrice;
                final childCharge = order.childHeadcount * buffetPrice;
                final buffetSubtotal = adultCharge + childCharge;
                
                // Buffet charges section - Thai header
                bytes += _safeText(
                  generator,
                  l10n.buffetCharges,
                  const PosStyles(bold: true, align: PosAlign.left),
                );
                bytes += generator.feed(1);
                
                // Adult line with Thai label
                final adultLine = '${l10n.adult} ${order.adultHeadcount} x ${buffetPrice.toStringAsFixed(0)}';
                bytes += _safeRow(generator, adultLine, '${adultCharge.toStringAsFixed(2)}');
                
                // Child line with Thai label
                final childLine = '${l10n.child} ${order.childHeadcount} x ${buffetPrice.toStringAsFixed(0)}';
                bytes += _safeRow(generator, childLine, '${childCharge.toStringAsFixed(2)}');
                
                bytes += generator.hr(ch: '-');
                bytes += _safeRow(
                  generator, 
                  l10n.buffetSubtotal, 
                  '${buffetSubtotal.toStringAsFixed(2)}',
                  labelBold: true,
                  valueBold: true,
                );
                
                // Extra items section (items with price > 0) for buffet
                final extraItems = orderItems.where((item) => item.hasExtraCharge).toList();
                if (extraItems.isNotEmpty) {
                  final extrasSubtotal = extraItems.fold<double>(
                    0.0,
                    (sum, item) => sum + item.totalPrice,
                  );
                  
                  bytes += generator.hr();
                  bytes += _safeText(
                    generator,
                    l10n.extraItems,
                    const PosStyles(bold: true, align: PosAlign.left),
                  );
                  
                  for (final item in extraItems) {
                    // Use item name if available, otherwise use ID
                    final itemName = item.menuItemName.isNotEmpty 
                        ? item.menuItemName 
                        : 'Item #${item.menuItemId}';
                    final itemLine = '$itemName x${item.quantity}';
                    bytes += _safeRow(generator, itemLine, '${item.totalPrice.toStringAsFixed(2)}');
                  }
                  
                  bytes += _safeRow(
                    generator,
                    l10n.extrasSubtotal,
                    '${extrasSubtotal.toStringAsFixed(2)}',
                    labelBold: true,
                    valueBold: true,
                  );
                }
              } else {
                // TAKE AWAY / NON-BUFFET ORDER: Show all items directly
                if (orderItems.isNotEmpty) {
                  bytes += _safeText(
                    generator,
                    l10n.orderItems,
                    const PosStyles(bold: true, align: PosAlign.left),
                  );
                  bytes += generator.feed(1);
                  
                  double itemsTotal = 0.0;
                  for (final item in orderItems) {
                    // Use item name if available, otherwise use ID
                    final itemName = item.menuItemName.isNotEmpty 
                        ? item.menuItemName 
                        : 'Item #${item.menuItemId}';
                    final itemLine = '$itemName x${item.quantity}';
                    final itemPrice = item.totalPrice;
                    itemsTotal += itemPrice;
                    bytes += _safeRow(generator, itemLine, '${itemPrice.toStringAsFixed(2)}');
                  }
                  
                  bytes += generator.hr(ch: '-');
                  bytes += _safeRow(
                    generator,
                    l10n.subtotal,
                    '${itemsTotal.toStringAsFixed(2)}',
                    labelBold: true,
                    valueBold: true,
                  );
                }
              }
            } catch (e) {
              debugPrint('Error printing dynamicItems (checkout): $e');
            }
          }
          break;
        case ReceiptComponentType.dynamicTotal:
          if (!isOpenTable) {
            // Render totals for checkout receipt
            try {
              // Use actual buffet tier price from order
              final buffetPrice = order.buffetTierPrice;
              final buffetSubtotal = (order.adultHeadcount * buffetPrice) +
                  (order.childHeadcount * buffetPrice);
              final extraItems = orderItems.where((item) => item.hasExtraCharge).toList();
              final extrasSubtotal = extraItems.fold<double>(
                0.0,
                (sum, item) => sum + item.totalPrice,
              );
              final grandTotal = buffetSubtotal + extrasSubtotal;
              
              bytes += generator.hr();
              bytes += generator.feed(1);
              
              bytes += _safeRow(generator, l10n.buffetSubtotal, '${buffetSubtotal.toStringAsFixed(2)}');
              
              if (extrasSubtotal > 0) {
                bytes += _safeRow(generator, l10n.extrasSubtotal, '${extrasSubtotal.toStringAsFixed(2)}');
              }
              
              bytes += generator.hr();
              
              // Grand Total - use order.totalAmount if available, otherwise calculate
              final displayTotal = order.totalAmount > 0 ? order.totalAmount : grandTotal;
              
              // Print grand total with larger text using _safeText
              bytes += _safeText(
                generator,
                '${l10n.grandTotal}  ${displayTotal.toStringAsFixed(2)}',
                const PosStyles(
                  bold: true,
                  height: PosTextSize.size2,
                  width: PosTextSize.size2,
                  align: PosAlign.center,
                ),
              );
              
              bytes += generator.hr();
              bytes += generator.feed(1);
              
              // Payment Info
              if (order.paymentMethod != null) {
                bytes += _safeRow(
                  generator,
                  '${l10n.payment}:',
                  order.paymentMethod!,
                  labelBold: true,
                  valueBold: true,
                );
              }
              
              bytes += generator.feed(1);
              bytes += _safeText(
                generator,
                l10n.thankYou,
                const PosStyles(align: PosAlign.center),
              );
            } catch (e) {
              debugPrint('Error printing dynamicTotal: $e');
            }
          }
          break;
        case ReceiptComponentType.image:
          // Print image from path
          final imagePath = component.data['path'] as String?;
          if (imagePath != null && imagePath.isNotEmpty) {
            try {
              final imageBytes = await _loadAndProcessImage(imagePath, generator, paperSize);
              if (imageBytes.isNotEmpty) {
                bytes += imageBytes;
              }
            } catch (e) {
              debugPrint('Error printing image: $e');
            }
          }
          break;
        case ReceiptComponentType.shopLogo:
          // Load shop logo from settings
          try {
            final shopInfo = await _ShopInfo.load();
            if (shopInfo.logoPath.isNotEmpty) {
              final imageBytes = await _loadAndProcessImage(shopInfo.logoPath, generator, paperSize);
              if (imageBytes.isNotEmpty) {
                bytes += imageBytes;
              }
            }
          } catch (e) {
            debugPrint('Error printing shop logo: $e');
          }
          break;
        case ReceiptComponentType.shopName:
          // Load shop name from settings
          try {
            final shopInfo = await _ShopInfo.load();
            if (shopInfo.name.isNotEmpty) {
              bytes += _safeText(
                generator,
                shopInfo.name,
                PosStyles(
                  align: align,
                  bold: isBold,
                  width: textSize,
                  height: textSize,
                ),
              );
            }
          } catch (e) {
            debugPrint('Error printing shop name: $e');
          }
          break;
        case ReceiptComponentType.shopAddress:
          // Load shop address from settings
          try {
            final shopInfo = await _ShopInfo.load();
            if (shopInfo.address.isNotEmpty) {
              bytes += _safeText(
                generator,
                shopInfo.address,
                PosStyles(
                  align: align,
                  bold: isBold,
                ),
              );
            }
          } catch (e) {
            debugPrint('Error printing shop address: $e');
          }
          break;
        case ReceiptComponentType.shopTel:
          // Load shop tel from settings
          try {
            final shopInfo = await _ShopInfo.load();
            if (shopInfo.tel.isNotEmpty) {
              bytes += _safeText(
                generator,
                'Tel: ${shopInfo.tel}',
                PosStyles(
                  align: align,
                  bold: isBold,
                ),
              );
            }
          } catch (e) {
            debugPrint('Error printing shop tel: $e');
          }
          break;
        default:
          break;
      }
    }

    bytes += generator.cut();
    return Uint8List.fromList(bytes);
  }
  
  /// Load and process image for printing
  static Future<List<int>> _loadAndProcessImage(
    String imagePath,
    Generator generator,
    PaperSize paperSize,
  ) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        debugPrint('Image file not found: $imagePath');
        return [];
      }
      
      final imageBytes = await file.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        debugPrint('Failed to decode image: $imagePath');
        return [];
      }
      
      // Resize image to fit paper width
      final maxWidth = paperSize == PaperSize.mm80 ? 400 : 300;
      img.Image processedImage = image;
      
      if (image.width > maxWidth) {
        // Use a new image instance to avoid fixed-length list issues
        processedImage = img.copyResize(
          image, 
          width: maxWidth,
          interpolation: img.Interpolation.average,
        );
      }
      
      // Convert to grayscale for thermal printing using img.grayscale
      final grayscaleImage = img.grayscale(processedImage);
      
      // Encode to PNG first, then decode to get a clean image
      final pngBytes = img.encodePng(grayscaleImage);
      final cleanImage = img.decodePng(pngBytes);
      
      if (cleanImage == null) {
        debugPrint('Failed to create clean image for printing');
        return [];
      }
      
      // Print image using esc_pos_utils
      final result = <int>[];
      try {
        // Use image() method which is more compatible
        final imageBytes = generator.image(cleanImage, align: PosAlign.center);
        result.addAll(imageBytes);
        debugPrint('Image printed successfully using image() method');
      } catch (e) {
        debugPrint('image() error: $e');
        // Try raster as fallback
        try {
          final rasterBytes = generator.imageRaster(cleanImage, align: PosAlign.center);
          result.addAll(rasterBytes);
          debugPrint('Image printed successfully using imageRaster() method');
        } catch (e2) {
          debugPrint('imageRaster() also failed: $e2');
          // Image printing not supported, continue without image
        }
      }
      
      return result;
    } catch (e, stack) {
      debugPrint('Error processing image for printing: $e');
      debugPrint('Stack: $stack');
      return [];
    }
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
