import 'dart:typed_data';

/// Abstract base class for all printer adapters (Bluetooth, Network, USB)
abstract class PrinterAdapter {
  /// Connect to the printer
  Future<bool> connect(String identifier);

  /// Disconnect from the printer
  Future<void> disconnect();

  /// Check connection status
  Future<bool> get isConnected;

  /// Print data (bytes)
  Future<bool> print(Uint8List data);
}
