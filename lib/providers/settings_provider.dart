import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SettingsProvider: Manages app settings with SharedPreferences persistence
class SettingsProvider extends ChangeNotifier {
  static const String _keyShopName = 'shop_name';
  static const String _keyShopAddress = 'shop_address';
  static const String _keyShopTel = 'shop_tel';
  static const String _keyShopLogoPath = 'shop_logo_path';
  static const String _keyOpenTime = 'open_time';
  static const String _keyCloseTime = 'close_time';
  static const String _keyPromptPayId = 'promptpay_id';
  static const String _keyPromptPayQrPath = 'promptpay_qr_path';
  static const String _keyCurrency = 'currency';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguage = 'language';
  static const String _keyTaxRate = 'tax_rate';
  static const String _keyServiceCharge = 'service_charge';
  static const String _keyEnableSound = 'enable_sound';
  static const String _keyEnableNotifications = 'enable_notifications';

  SharedPreferences? _prefs;

  // Shop Info
  String _shopName = '';
  String _shopAddress = '';
  String _shopTel = '';
  String _shopLogoPath = '';
  String _openTime = '09:00';
  String _closeTime = '22:00';

  // Payment
  String _promptPayId = '';
  String _promptPayQrPath = '';

  // Preferences
  String _currency = '฿';
  String _themeMode = 'dark'; // dark, light, system
  String _language = 'th'; // th, en

  // POS Settings
  double _taxRate = 7.0;
  double _serviceCharge = 10.0;
  bool _enableSound = true;
  bool _enableNotifications = false;

  // Getters
  String get shopName => _shopName;
  String get shopAddress => _shopAddress;
  String get shopTel => _shopTel;
  String get shopLogoPath => _shopLogoPath;
  String get openTime => _openTime;
  String get closeTime => _closeTime;
  String get promptPayId => _promptPayId;
  String get promptPayQrPath => _promptPayQrPath;
  String get currency => _currency;
  String get themeMode => _themeMode;
  String get language => _language;
  double get taxRate => _taxRate;
  double get serviceCharge => _serviceCharge;
  bool get enableSound => _enableSound;
  bool get enableNotifications => _enableNotifications;

  ThemeMode get themeModeEnum {
    switch (_themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Initialize the provider by loading settings from SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    if (_prefs == null) return;

    _shopName = _prefs!.getString(_keyShopName) ?? '';
    _shopAddress = _prefs!.getString(_keyShopAddress) ?? '';
    _shopTel = _prefs!.getString(_keyShopTel) ?? '';
    _shopLogoPath = _prefs!.getString(_keyShopLogoPath) ?? '';
    _openTime = _prefs!.getString(_keyOpenTime) ?? '09:00';
    _closeTime = _prefs!.getString(_keyCloseTime) ?? '22:00';
    _promptPayId = _prefs!.getString(_keyPromptPayId) ?? '';
    _promptPayQrPath = _prefs!.getString(_keyPromptPayQrPath) ?? '';
    _currency = _prefs!.getString(_keyCurrency) ?? '฿';
    _themeMode = _prefs!.getString(_keyThemeMode) ?? 'dark';
    _language = _prefs!.getString(_keyLanguage) ?? 'th';
    _taxRate = _prefs!.getDouble(_keyTaxRate) ?? 7.0;
    _serviceCharge = _prefs!.getDouble(_keyServiceCharge) ?? 10.0;
    _enableSound = _prefs!.getBool(_keyEnableSound) ?? true;
    _enableNotifications = _prefs!.getBool(_keyEnableNotifications) ?? false;
    _pointsPerBaht = _prefs!.getInt(_keyPointsPerBaht) ?? 100;

    notifyListeners();
  }

  // Setters with persistence

  Future<void> setShopName(String value) async {
    _shopName = value;
    await _prefs?.setString(_keyShopName, value);
    notifyListeners();
  }

  Future<void> setShopAddress(String value) async {
    _shopAddress = value;
    await _prefs?.setString(_keyShopAddress, value);
    notifyListeners();
  }

  Future<void> setShopTel(String value) async {
    _shopTel = value;
    await _prefs?.setString(_keyShopTel, value);
    notifyListeners();
  }

  Future<void> setShopLogoPath(String value) async {
    _shopLogoPath = value;
    await _prefs?.setString(_keyShopLogoPath, value);
    notifyListeners();
  }

  Future<void> setOpenTime(String value) async {
    _openTime = value;
    await _prefs?.setString(_keyOpenTime, value);
    notifyListeners();
  }

  Future<void> setCloseTime(String value) async {
    _closeTime = value;
    await _prefs?.setString(_keyCloseTime, value);
    notifyListeners();
  }

  Future<void> setPromptPayId(String value) async {
    _promptPayId = value;
    await _prefs?.setString(_keyPromptPayId, value);
    notifyListeners();
  }

  Future<void> setPromptPayQrPath(String value) async {
    _promptPayQrPath = value;
    await _prefs?.setString(_keyPromptPayQrPath, value);
    notifyListeners();
  }

  Future<void> setCurrency(String value) async {
    _currency = value;
    await _prefs?.setString(_keyCurrency, value);
    notifyListeners();
  }

  Future<void> setThemeMode(String value) async {
    _themeMode = value;
    await _prefs?.setString(_keyThemeMode, value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    await _prefs?.setString(_keyLanguage, value);
    notifyListeners();
  }

  Future<void> setTaxRate(double value) async {
    _taxRate = value;
    await _prefs?.setDouble(_keyTaxRate, value);
    notifyListeners();
  }

  Future<void> setServiceCharge(double value) async {
    _serviceCharge = value;
    await _prefs?.setDouble(_keyServiceCharge, value);
    notifyListeners();
  }

  Future<void> setEnableSound(bool value) async {
    _enableSound = value;
    await _prefs?.setBool(_keyEnableSound, value);
    notifyListeners();
  }

  Future<void> setEnableNotifications(bool value) async {
    _enableNotifications = value;
    await _prefs?.setBool(_keyEnableNotifications, value);
    notifyListeners();
  }

  /// Save all shop info at once
  Future<void> saveShopInfo({
    required String name,
    required String address,
    required String tel,
    required String logoPath,
    required String openTime,
    required String closeTime,
  }) async {
    _shopName = name;
    _shopAddress = address;
    _shopTel = tel;
    _shopLogoPath = logoPath;
    _openTime = openTime;
    _closeTime = closeTime;

    await _prefs?.setString(_keyShopName, name);
    await _prefs?.setString(_keyShopAddress, address);
    await _prefs?.setString(_keyShopTel, tel);
    await _prefs?.setString(_keyShopLogoPath, logoPath);
    await _prefs?.setString(_keyOpenTime, openTime);
    await _prefs?.setString(_keyCloseTime, closeTime);

    notifyListeners();
  }

  /// Save payment settings at once
  Future<void> savePaymentSettings({
    required String promptPayId,
    required String promptPayQrPath,
  }) async {
    _promptPayId = promptPayId;
    _promptPayQrPath = promptPayQrPath;

    await _prefs?.setString(_keyPromptPayId, promptPayId);
    await _prefs?.setString(_keyPromptPayQrPath, promptPayQrPath);

    notifyListeners();
  }

  // --- Loyalty Points System ---
  static const String _keyPointsPerBaht = 'points_per_baht';
  int _pointsPerBaht = 100; // Default: 100 Baht = 1 Point

  int get pointsPerBaht => _pointsPerBaht;

  Future<void> setPointsPerBaht(int value) async {
    _pointsPerBaht = value;
    await _prefs?.setInt(_keyPointsPerBaht, value);
    notifyListeners();
  }
}
