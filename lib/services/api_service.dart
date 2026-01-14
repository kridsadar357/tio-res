import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu_item.dart';

/// API Service for syncing with php-orders backend
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _keyApiEnabled = 'api_enabled';
  static const String _keyBaseUrl = 'api_base_url';
  static const String _keyApiKey = 'api_key';

  String? _baseUrl;
  String? _apiKey;
  bool _enabled = false;

  /// Initialize the service (call on app start)
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_keyApiEnabled) ?? false;
    _baseUrl = prefs.getString(_keyBaseUrl);
    _apiKey = prefs.getString(_keyApiKey);
  }

  /// Check if API is enabled
  bool get isEnabled => _enabled && _baseUrl != null && _baseUrl!.isNotEmpty;

  /// Get web ordering URL for QR code
  String getWebOrderUrl({
    required int tableId,
    required String tableName,
    int? tierId,
    int? orderId,
  }) {
    if (_baseUrl == null) return '';

    // Remove /api suffix if present to get base web URL
    String webBase = _baseUrl!.replaceAll(RegExp(r'/api/?$'), '');

    final params = <String, String>{
      'table': tableId.toString(),
      'name': tableName,
    };
    if (tierId != null) params['tier'] = tierId.toString();
    if (orderId != null) params['order'] = orderId.toString();

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$webBase/?$queryString';
  }

  /// Common headers
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_apiKey != null && _apiKey!.isNotEmpty) 'X-API-Key': _apiKey!,
      };

  /// Sync menu items to server (for menu updates)
  Future<bool> syncMenuItems(List<MenuItem> items) async {
    if (!isEnabled) return false;

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/update_items.php'),
        headers: _headers,
        body: jsonEncode({
          'items': items
              .map((item) => {
                    'id': item.id,
                    'name': item.name,
                    'price': item.price,
                    'description': item.description,
                    'image_url': item.imagePath,
                    'category_id': item.categoryId,
                    'is_available': item.isAvailable ? 1 : 0,
                  })
              .toList(),
        }),
      );

      final data = jsonDecode(response.body);
      debugPrint('API Sync: ${data['message'] ?? 'Success'}');
      return data['success'] == true;
    } catch (e) {
      debugPrint('API Sync Error: $e');
      return false;
    }
  }

  /// Sync single menu item
  Future<bool> syncMenuItem(MenuItem item) async {
    return syncMenuItems([item]);
  }

  /// Delete menu items from server
  Future<bool> deleteMenuItems(List<int> ids) async {
    if (!isEnabled || ids.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/delete_items.php'),
        headers: _headers,
        body: jsonEncode({'ids': ids}),
      );

      final data = jsonDecode(response.body);
      debugPrint('API Delete: ${data['message'] ?? 'Success'}');
      return data['success'] == true;
    } catch (e) {
      debugPrint('API Delete Error: $e');
      return false;
    }
  }

  /// Fetch pending orders from web customers
  Future<List<WebOrder>> fetchPendingOrders() async {
    if (!isEnabled) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/get_pending_orders.php'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);
      if (data['success'] != true) return [];

      return (data['orders'] as List? ?? [])
          .map((o) => WebOrder.fromJson(o))
          .toList();
    } catch (e) {
      debugPrint('API Fetch Orders Error: $e');
      return [];
    }
  }

  /// Acknowledge order receipt (mark as received by POS)
  Future<bool> acknowledgeOrder(int orderId) async {
    if (!isEnabled) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/acknowledge_order.php'),
        headers: _headers,
        body: jsonEncode({'order_id': orderId}),
      );

      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      debugPrint('API Acknowledge Error: $e');
      return false;
    }
  }
}

/// Model for web orders
class WebOrder {
  final int id;
  final int tableId;
  final String tableName;
  final List<WebOrderItem> items;
  final double totalAmount;
  final DateTime createdAt;

  WebOrder({
    required this.id,
    required this.tableId,
    required this.tableName,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
  });

  factory WebOrder.fromJson(Map<String, dynamic> json) {
    return WebOrder(
      id: json['id'] ?? 0,
      tableId: json['table_id'] ?? 0,
      tableName: json['table_name'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((i) => WebOrderItem.fromJson(i))
          .toList(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class WebOrderItem {
  final int itemId;
  final String name;
  final int quantity;
  final double price;
  final String? notes;

  WebOrderItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.price,
    this.notes,
  });

  factory WebOrderItem.fromJson(Map<String, dynamic> json) {
    return WebOrderItem(
      itemId: json['item_id'] ?? json['menu_item_id'] ?? 0,
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      notes: json['notes'],
    );
  }
}
