import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// EDC Terminal Types supported in Thailand
enum EdcTerminalType {
  kasikorn, // K-EDC / Kasikorn Bank
  scb, // Siam Commercial Bank
  bbl, // Bangkok Bank
  krungthai, // Krungthai Bank
  ttb, // TMBThanachart
  krungsri, // Bank of Ayudhya
  generic, // Generic/Other
}

/// EDC Connection Types
enum EdcConnectionType {
  serial, // RS232/Serial COM port
  network, // TCP/IP (Socket)
  usb, // USB connection
  bluetooth, // Bluetooth
}

/// EDC Payment Status
enum EdcPaymentStatus {
  idle,
  connecting,
  waitingForCard,
  processing,
  approved,
  declined,
  cancelled,
  error,
}

/// EDC Transaction Result
class EdcTransactionResult {
  final bool success;
  final String? approvalCode;
  final String? cardType; // VISA, MASTERCARD, etc.
  final String? last4Digits;
  final double amount;
  final String? errorMessage;
  final DateTime timestamp;

  EdcTransactionResult({
    required this.success,
    this.approvalCode,
    this.cardType,
    this.last4Digits,
    required this.amount,
    this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// EDC Service - Handles communication with EDC terminals
class EdcService extends ChangeNotifier {
  static final EdcService _instance = EdcService._internal();
  factory EdcService() => _instance;
  EdcService._internal();

  // Settings Keys
  static const String _keyEnabled = 'edc_enabled';
  static const String _keyTerminalType = 'edc_terminal_type';
  static const String _keyConnectionType = 'edc_connection_type';
  static const String _keyAddress = 'edc_address'; // IP:Port or COM port
  static const String _keyTerminalId = 'edc_terminal_id';
  static const String _keyMerchantId = 'edc_merchant_id';

  // State
  bool _enabled = false;
  EdcTerminalType _terminalType = EdcTerminalType.kasikorn;
  EdcConnectionType _connectionType = EdcConnectionType.network;
  String _address = '';
  String _terminalId = '';
  String _merchantId = '';
  EdcPaymentStatus _status = EdcPaymentStatus.idle;
  EdcTransactionResult? _lastTransaction;

  // Getters
  bool get isEnabled => _enabled;
  EdcTerminalType get terminalType => _terminalType;
  EdcConnectionType get connectionType => _connectionType;
  String get address => _address;
  String get terminalId => _terminalId;
  String get merchantId => _merchantId;
  EdcPaymentStatus get status => _status;
  EdcTransactionResult? get lastTransaction => _lastTransaction;

  /// Initialize service and load settings
  Future<void> init() async {
    await _loadSettings();
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_keyEnabled) ?? false;
    _terminalType = EdcTerminalType.values[prefs.getInt(_keyTerminalType) ?? 0];
    _connectionType =
        EdcConnectionType.values[prefs.getInt(_keyConnectionType) ?? 0];
    _address = prefs.getString(_keyAddress) ?? '';
    _terminalId = prefs.getString(_keyTerminalId) ?? '';
    _merchantId = prefs.getString(_keyMerchantId) ?? '';
    notifyListeners();
  }

  /// Save settings
  Future<void> saveSettings({
    required bool enabled,
    required EdcTerminalType terminalType,
    required EdcConnectionType connectionType,
    required String address,
    required String terminalId,
    required String merchantId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    await prefs.setInt(_keyTerminalType, terminalType.index);
    await prefs.setInt(_keyConnectionType, connectionType.index);
    await prefs.setString(_keyAddress, address);
    await prefs.setString(_keyTerminalId, terminalId);
    await prefs.setString(_keyMerchantId, merchantId);

    _enabled = enabled;
    _terminalType = terminalType;
    _connectionType = connectionType;
    _address = address;
    _terminalId = terminalId;
    _merchantId = merchantId;
    notifyListeners();
  }

  /// Test connection to EDC terminal
  Future<bool> testConnection() async {
    if (!_enabled || _address.isEmpty) return false;

    _status = EdcPaymentStatus.connecting;
    notifyListeners();

    try {
      // TODO: Implement actual connection test based on terminal type
      // This is a placeholder that simulates connection
      await Future<void>.delayed(const Duration(seconds: 2));

      // Simulate successful connection
      _status = EdcPaymentStatus.idle;
      notifyListeners();
      debugPrint('EDC: Connection test successful to $_address');
      return true;
    } catch (e) {
      _status = EdcPaymentStatus.error;
      notifyListeners();
      debugPrint('EDC: Connection test failed: $e');
      return false;
    }
  }

  /// Send payment request to EDC terminal
  /// Returns transaction result
  Future<EdcTransactionResult> sendPayment({
    required double amount,
    String? reference,
  }) async {
    if (!_enabled) {
      return EdcTransactionResult(
        success: false,
        amount: amount,
        errorMessage: 'EDC is not enabled',
      );
    }

    _status = EdcPaymentStatus.connecting;
    notifyListeners();

    try {
      // TODO: Implement actual EDC communication based on terminal type
      // Each bank has different protocols:
      // - Kasikorn: TCP/IP with specific packet format
      // - SCB: Similar TCP/IP protocol
      // - Others: Varies

      debugPrint(
          'EDC: Sending payment request for ฿${amount.toStringAsFixed(2)}');

      // Simulate connecting
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _status = EdcPaymentStatus.waitingForCard;
      notifyListeners();

      // Simulate card insertion/tap
      await Future<void>.delayed(const Duration(seconds: 2));
      _status = EdcPaymentStatus.processing;
      notifyListeners();

      // Simulate processing
      await Future<void>.delayed(const Duration(seconds: 2));

      // Simulate successful transaction
      _lastTransaction = EdcTransactionResult(
        success: true,
        approvalCode:
            'A${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        cardType: 'VISA',
        last4Digits: '4242',
        amount: amount,
      );

      _status = EdcPaymentStatus.approved;
      notifyListeners();

      debugPrint('EDC: Payment approved - ${_lastTransaction!.approvalCode}');
      return _lastTransaction!;
    } catch (e) {
      _lastTransaction = EdcTransactionResult(
        success: false,
        amount: amount,
        errorMessage: e.toString(),
      );
      _status = EdcPaymentStatus.error;
      notifyListeners();
      debugPrint('EDC: Payment failed: $e');
      return _lastTransaction!;
    }
  }

  /// Cancel current transaction
  Future<void> cancelTransaction() async {
    if (_status == EdcPaymentStatus.waitingForCard ||
        _status == EdcPaymentStatus.processing) {
      // TODO: Send cancel command to terminal
      _status = EdcPaymentStatus.cancelled;
      notifyListeners();
      debugPrint('EDC: Transaction cancelled');
    }
  }

  /// Reset status to idle
  void resetStatus() {
    _status = EdcPaymentStatus.idle;
    notifyListeners();
  }

  /// Get display name for terminal type
  static String getTerminalTypeName(EdcTerminalType type) {
    switch (type) {
      case EdcTerminalType.kasikorn:
        return 'Kasikorn (K-EDC)';
      case EdcTerminalType.scb:
        return 'SCB';
      case EdcTerminalType.bbl:
        return 'Bangkok Bank';
      case EdcTerminalType.krungthai:
        return 'Krungthai';
      case EdcTerminalType.ttb:
        return 'TTB (TMBThanachart)';
      case EdcTerminalType.krungsri:
        return 'Krungsri';
      case EdcTerminalType.generic:
        return 'Generic/Other';
    }
  }

  /// Get display name for connection type
  static String getConnectionTypeName(EdcConnectionType type) {
    switch (type) {
      case EdcConnectionType.serial:
        return 'Serial (COM)';
      case EdcConnectionType.network:
        return 'Network (TCP/IP)';
      case EdcConnectionType.usb:
        return 'USB';
      case EdcConnectionType.bluetooth:
        return 'Bluetooth';
    }
  }

  /// Get status message
  String getStatusMessage() {
    switch (_status) {
      case EdcPaymentStatus.idle:
        return 'Ready';
      case EdcPaymentStatus.connecting:
        return 'Connecting to terminal...';
      case EdcPaymentStatus.waitingForCard:
        return 'Please insert/tap card';
      case EdcPaymentStatus.processing:
        return 'Processing payment...';
      case EdcPaymentStatus.approved:
        return 'Payment approved';
      case EdcPaymentStatus.declined:
        return 'Payment declined';
      case EdcPaymentStatus.cancelled:
        return 'Transaction cancelled';
      case EdcPaymentStatus.error:
        return 'Error occurred';
    }
  }
}
