import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/app_localizations.dart';

class IconHelper {
  static final List<IconData> _icons = [
    FontAwesomeIcons.restroom,
    FontAwesomeIcons.kitchenSet,
    FontAwesomeIcons.martiniGlass,
    FontAwesomeIcons.cashRegister,
    FontAwesomeIcons.doorOpen,
    FontAwesomeIcons.plantWilt,
    FontAwesomeIcons.chair,
    FontAwesomeIcons.couch,
    FontAwesomeIcons.tv,
    FontAwesomeIcons.music,
    FontAwesomeIcons.wifi,
    FontAwesomeIcons.fan,
    FontAwesomeIcons.fireExtinguisher,
  ];

  static IconData? getIconByCodePoint(int? codePoint) {
    if (codePoint == null || codePoint == 0) return null;
    try {
      return _icons.firstWhere((icon) => icon.codePoint == codePoint);
    } catch (_) {
      // Fallback if not found in list, try best effort with default Free/Solid family
      return IconData(codePoint,
          fontFamily: 'FontAwesome6Free', fontPackage: 'font_awesome_flutter');
    }
  }

  static List<Map<String, dynamic>> getAvailableIcons(AppLocalizations l10n) {
    return [
      {'name': l10n.none, 'icon': null},
      {'name': l10n.restroom, 'icon': FontAwesomeIcons.restroom},
      {'name': l10n.kitchen, 'icon': FontAwesomeIcons.kitchenSet},
      {'name': l10n.bar, 'icon': FontAwesomeIcons.martiniGlass},
      {'name': l10n.cashier, 'icon': FontAwesomeIcons.cashRegister},
      {'name': l10n.door, 'icon': FontAwesomeIcons.doorOpen},
      {'name': l10n.plant, 'icon': FontAwesomeIcons.plantWilt},
      {'name': l10n.chair, 'icon': FontAwesomeIcons.chair},
      {'name': l10n.couch, 'icon': FontAwesomeIcons.couch},
      {'name': l10n.tv, 'icon': FontAwesomeIcons.tv},
      {'name': l10n.music, 'icon': FontAwesomeIcons.music},
      {'name': l10n.wifi, 'icon': FontAwesomeIcons.wifi},
      {'name': l10n.fan, 'icon': FontAwesomeIcons.fan},
      {'name': l10n.fire, 'icon': FontAwesomeIcons.fireExtinguisher},
    ];
  }
}
