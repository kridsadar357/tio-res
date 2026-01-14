import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

/// Utility class for currency formatting using app settings
class CurrencyHelper {
  /// Format a value with the app's currency symbol
  /// Example: formatCurrency(context, 123.45) => "฿123.45" or "$123.45"
  static String format(BuildContext context, double value, {int decimals = 2}) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final symbol = settings.currency;
    return '$symbol${value.toStringAsFixed(decimals)}';
  }

  static String formatWhole(BuildContext context, double value) {
    return format(context, value, decimals: 0);
  }

  /// Format compact number (e.g. 1.2k, 1M)
  static String formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  /// Get just the currency symbol
  static String symbol(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    return settings.currency;
  }
}
