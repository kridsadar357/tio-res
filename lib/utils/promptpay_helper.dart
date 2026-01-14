import 'dart:convert';

class PromptPayHelper {
  /// Generate PromptPay QR Payload (EMVCo)
  static String generatePayload(String promptPayId, double amount) {
    if (promptPayId.isEmpty) return '';

    final target = _formatTarget(promptPayId);
    final amountStr = amount.toStringAsFixed(2);

    final sb = StringBuffer();
    // 00: Format Indicator
    sb.write(_f('00', '01'));
    // 01: Point of Initiation Method (12 = Dynamic, 11 = Static)
    sb.write(_f('01', amount > 0 ? '12' : '11'));
    // 29: Merchant Account Information
    final merchantInfo = StringBuffer();
    merchantInfo.write(_f('00', 'A000000677010111')); // AID
    merchantInfo
        .write(_f('01', target)); // Target (Phone/TaxID) formatted already
    // Wait, Phone needs 0066 prefix and remove leading 0. TaxID is direct.
    // Let's refine _formatTarget.

    sb.write(_f('29', merchantInfo.toString()));

    // 53: Currency (764 = THB)
    sb.write(_f('53', '764'));
    // 54: Amount
    if (amount > 0) {
      sb.write(_f('54', amountStr));
    }
    // 58: Country Code (TH)
    sb.write(_f('58', 'TH'));

    // 63: CRC
    final String dataToCrc = '${sb.toString()}6304';
    final crc = _calculateCrc16(dataToCrc);
    return '$dataToCrc$crc';
  }

  static String _formatTarget(String id) {
    String cleanId = id.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanId.length == 10) {
      // Mobile: 08x xxx xxxx -> 668x xxx xxxx
      return '0066${cleanId.substring(1)}';
    }
    // Tax ID or E-Wallet (13-15 chars) - Return as is
    return cleanId;
  }

  static String _f(String id, String value) {
    return '$id${value.length.toString().padLeft(2, '0')}$value';
  }

  static String _calculateCrc16(String data) {
    int crc = 0xFFFF; // Initial value
    final bytes = utf8.encode(data);

    for (final byte in bytes) {
      crc ^= (byte << 8);
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021; // Polynomial
        } else {
          crc <<= 1;
        }
      }
      crc &= 0xFFFF; // Keep only 16 bits
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
