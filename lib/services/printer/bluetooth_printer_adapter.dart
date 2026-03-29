import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as bt;
import 'printer_adapter.dart';

class BluetoothPrinterAdapter implements PrinterAdapter {
  bt.BlueThermalPrinter? _printer;
  bt.BluetoothDevice? _connectedDevice;
  bool _isConnected = false;

  Future<bool> checkPermissions() async {
    if (defaultTargetPlatform != defaultTargetPlatform) {
      // Only needed on Android
      final bluetoothScan = await Permission.bluetoothScan.request();
      final bluetoothConnect = await Permission.bluetoothConnect.request();
      final bluetooth = await Permission.bluetooth.request();
      
      return bluetoothScan.isGranted && 
             bluetoothConnect.isGranted && 
             bluetooth.isGranted;
    }
    return true;
  }

  Future<List<bt.BluetoothDevice>> scanDevices() async {
    _printer ??= bt.BlueThermalPrinter.instance;
    
    // Check if Bluetooth is available
    final isAvailable = await _printer!.isAvailable;
    if (isAvailable != true) {
      debugPrint('Bluetooth is not available');
      return [];
    }

    // Get bonded devices (already paired)
    try {
      final devices = await _printer!.getBondedDevices();
      return devices;
    } catch (e) {
      debugPrint('Error scanning devices: $e');
      return [];
    }
  }

  /// Start discovering nearby Bluetooth devices
  Future<bool> startDiscovery() async {
    _printer ??= bt.BlueThermalPrinter.instance;
    try {
      final result = await _printer!.startDiscovery();
      return result == true;
    } catch (e) {
      debugPrint('Error starting discovery: $e');
      return false;
    }
  }

  /// Stop discovering devices
  Future<bool> stopDiscovery() async {
    _printer ??= bt.BlueThermalPrinter.instance;
    try {
      final result = await _printer!.stopDiscovery();
      return result == true;
    } catch (e) {
      debugPrint('Error stopping discovery: $e');
      return false;
    }
  }

  /// Get discovered devices
  Future<List<bt.BluetoothDevice>> getDiscoveredDevices() async {
    _printer ??= bt.BlueThermalPrinter.instance;
    try {
      final devices = await _printer!.getDiscoveredDevices();
      return devices;
    } catch (e) {
      debugPrint('Error getting discovered devices: $e');
      return [];
    }
  }

  @override
  Future<bool> connect(String identifier) async {
    try {
      _printer ??= bt.BlueThermalPrinter.instance;

      // Check permissions first
      final hasPermissions = await checkPermissions();
      if (!hasPermissions) {
        debugPrint('Bluetooth permissions not granted');
        return false;
      }

      // Check if Bluetooth is available
      final isAvailable = await _printer!.isAvailable;
      if (isAvailable != true) {
        debugPrint('Bluetooth is not available');
        return false;
      }

      // Try to find device in bonded devices first
      bt.BluetoothDevice device;
      try {
        final devices = await _printer!.getBondedDevices();
        device = devices.firstWhere(
          (d) => d.address == identifier,
          orElse: () => throw Exception('Not in bonded devices'),
        );
        debugPrint('Found device in bonded devices: ${device.name}');
      } catch (e) {
        // Device not in bonded devices - create device object from address
        // This allows connecting to discovered devices that aren't paired yet
        debugPrint('Device not in bonded devices, creating from address: $identifier');
        device = bt.BluetoothDevice(null, identifier);
      }

      // Check if already connected to this device
      try {
        final isDeviceConnected = await _printer!.isDeviceConnected(device);
        if (isDeviceConnected == true) {
          _connectedDevice = device;
          _isConnected = true;
          debugPrint('Already connected to ${device.name ?? device.address}');
          return true;
        }
      } catch (e) {
        // Device might not be paired yet, continue with connection attempt
        debugPrint('Could not check connection status, proceeding with connect: $e');
      }

      // Connect to the device (this will trigger pairing if not already paired)
      await _printer!.connect(device);
      
      // Wait longer for connection/pairing to establish
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      
      // Verify connection
      final connected = await _printer!.isConnected;
      if (connected == true) {
        // Try to get the actual device info from bonded devices now
        try {
          final devices = await _printer!.getBondedDevices();
          final bondedDevice = devices.firstWhere(
            (d) => d.address == identifier,
            orElse: () => device,
          );
          _connectedDevice = bondedDevice;
        } catch (e) {
          _connectedDevice = device;
        }
        _isConnected = true;
        debugPrint('Connected to ${_connectedDevice?.name ?? _connectedDevice?.address ?? identifier}');
        return true;
      } else {
        _isConnected = false;
        debugPrint('Failed to connect to ${device.name ?? device.address}');
        return false;
      }
    } catch (e) {
      debugPrint('BluetoothPrinterAdapter connect error: $e');
      _isConnected = false;
      _connectedDevice = null;
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      if (_printer != null && _isConnected) {
        await _printer!.disconnect();
        _isConnected = false;
        _connectedDevice = null;
        debugPrint('Disconnected from printer');
      }
    } catch (e) {
      debugPrint('BluetoothPrinterAdapter disconnect error: $e');
    }
  }

  @override
  Future<bool> get isConnected async {
    if (_printer == null) return false;
    
    try {
      final connected = await _printer!.isConnected;
      _isConnected = connected == true;
      return _isConnected;
    } catch (e) {
      debugPrint('BluetoothPrinterAdapter isConnected error: $e');
      _isConnected = false;
      return false;
    }
  }

  @override
  Future<bool> print(Uint8List data) async {
    if (!_isConnected || _printer == null) {
      debugPrint('Cannot print: not connected');
      return false;
    }

    try {
      // Use writeBytes to send ESC/POS commands
      await _printer!.writeBytes(data);
      debugPrint('Print data sent successfully (${data.length} bytes)');
      return true;
    } catch (e) {
      debugPrint('BluetoothPrinterAdapter print error: $e');
      return false;
    }
  }

  bt.BluetoothDevice? get connectedDevice => _connectedDevice;
}
