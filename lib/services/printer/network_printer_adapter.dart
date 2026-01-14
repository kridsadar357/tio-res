import 'dart:io';
import 'dart:typed_data';
import 'printer_adapter.dart';

/// Adapter for Network Printers (Port 9100)
class NetworkPrinterAdapter implements PrinterAdapter {
  Socket? _socket;
  String? _host;
  int _port = 9100;

  @override
  Future<bool> connect(String identifier) async {
    try {
      final parts = identifier.split(':');
      _host = parts[0];
      _port = parts.length > 1 ? int.tryParse(parts[1]) ?? 9100 : 9100;

      _socket = await Socket.connect(_host!, _port,
          timeout: const Duration(seconds: 5));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    await _socket?.flush();
    await _socket?.close();
    _socket = null;
  }

  @override
  Future<bool> get isConnected async {
    return _socket != null;
  }

  @override
  Future<bool> print(Uint8List data) async {
    try {
      if (_socket == null) return false;
      _socket!.add(data);
      await _socket!.flush();
      return true;
    } catch (e) {
      disconnect();
      return false;
    }
  }
}
