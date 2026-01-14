import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'printer/printer_adapter.dart';
import 'printer/bluetooth_printer_adapter.dart';
import 'printer/network_printer_adapter.dart';
import 'api_service.dart';
import '../utils/receipt_generator.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/table_model.dart';

enum PrinterType { bluetooth, network, usb }

class PrinterService extends ChangeNotifier {
  static final PrinterService _instance = PrinterService._internal();

  factory PrinterService() => _instance;

  PrinterService._internal();

  PrinterAdapter? _adapter;
  PrinterType _type = PrinterType.bluetooth;
  String? _address;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  PrinterType get type => _type;
  String? get address => _address;
  PrinterAdapter? get adapter => _adapter;

  // Settings Keys
  static const String _keyType = 'printer_type';
  static const String _keyAddress = 'printer_address';

  /// Initialize and try to auto-connect
  Future<void> init() async {
    await _loadSettings();
    await connect();
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final typeStr = prefs.getString(_keyType) ?? 'BLUETOOTH';
    _address = prefs.getString(_keyAddress);

    switch (typeStr) {
      case 'NETWORK':
        _type = PrinterType.network;
        break;
      case 'USB':
        _type = PrinterType.usb; // Placeholder
        break;
      default:
        _type = PrinterType.bluetooth;
    }
  }

  /// Save settings
  Future<void> saveSettings(PrinterType type, String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyType, type.toString().split('.').last.toUpperCase());
    await prefs.setString(_keyAddress, address);

    _type = type;
    _address = address;

    // Reconnect with new settings
    await disconnect();
    await connect();
  }

  /// Connect to the configured printer
  Future<bool> connect() async {
    if (_address == null || _address!.isEmpty) return false;

    // Dispose old adapter if type changed or force reconnect
    _adapter ??= _createAdapter(_type);

    try {
      _isConnected = await _adapter!.connect(_address!);
      notifyListeners();
      return _isConnected;
    } catch (e) {
      debugPrint('PrinterService Connect Error: $e');
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  /// Create adapter instance
  PrinterAdapter _createAdapter(PrinterType type) {
    switch (type) {
      case PrinterType.bluetooth:
        return BluetoothPrinterAdapter();
      case PrinterType.network:
        return NetworkPrinterAdapter();
      default:
        return BluetoothPrinterAdapter(); // Default to BT
    }
  }

  /// Disconnect
  Future<void> disconnect() async {
    if (_adapter != null) {
      await _adapter!.disconnect();
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Print Receipt
  Future<bool> printReceipt({
    required TableModel table,
    required Order order,
    required List<OrderItem> orderItems,
  }) async {
    if (!_isConnected || _adapter == null) {
      // Try to reconnect
      final reconnected = await connect();
      if (!reconnected) return false;
    }

    try {
      final bytes = await ReceiptGenerator.generateReceipt(
        table: table,
        order: order,
        orderItems: orderItems,
      );
      return await _adapter!.print(bytes);
    } catch (e) {
      debugPrint('Print Receipt Error: $e');
      return false;
    }
  }

  /// Print Test Receipt
  Future<bool> printTest() async {
    if (!_isConnected || _adapter == null) {
      final reconnected = await connect();
      if (!reconnected) return false;
    }

    try {
      final bytes = await ReceiptGenerator.generateTestReceipt();
      return await _adapter!.print(bytes);
    } catch (e) {
      debugPrint('Print Test Error: $e');
      return false;
    }
  }

  /// Print Open Table Receipt (QR)
  Future<bool> printOpenTableReceipt({
    required TableModel table,
    required Order order,
    int? buffetTierId,
  }) async {
    if (!_isConnected || _adapter == null) {
      final reconnected = await connect();
      if (!reconnected) return false;
    }

    // Generate QR Payload: Use web ordering URL if API enabled, else fallback
    final apiService = ApiService();
    String qrPayload;

    if (apiService.isEnabled) {
      qrPayload = apiService.getWebOrderUrl(
        tableId: table.id,
        tableName: table.tableName,
        tierId: buffetTierId,
        orderId: order.id,
      );
    } else {
      // Fallback to simple order reference
      qrPayload = 'order:${order.id}|table:${table.tableName}';
    }

    try {
      final bytes = await ReceiptGenerator.generateOpenTableReceipt(
        table: table,
        order: order,
        qrPayload: qrPayload,
      );
      return await _adapter!.print(bytes);
    } catch (e) {
      debugPrint('Print Open Table Receipt Error: $e');
      return false;
    }
  }
}
