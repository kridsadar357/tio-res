import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'printer_adapter.dart';
import '../bluetooth_printer_service.dart'; // Import stubbed BluetoothDevice

class BluetoothPrinterAdapter implements PrinterAdapter {
  BluetoothDevice? _connectedDevice;
  bool _isConnected = false;

  Future<bool> checkPermissions() async {
    return true;
  }

  Future<List<BluetoothDevice>> scanDevices() async {
    return [];
  }

  @override
  Future<bool> connect(String identifier) async {
    return false;
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> get isConnected async {
    return false;
  }

  @override
  Future<bool> print(Uint8List data) async {
    return false;
  }
}
