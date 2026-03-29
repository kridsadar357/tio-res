import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu_item.dart';
import '../models/menu_category.dart';
import '../models/buffet_tier.dart';
import '../models/table_model.dart';
import 'database_helper.dart';

/// API Service for syncing with php-orders backend
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _keyApiEnabled = 'api_enabled';
  static const String _keyBaseUrl = 'api_base_url';
  static const String _keyApiKey = 'api_key';
  static const String _keyQrOrderEnabled = 'qr_order_enabled';
  static const String _keyQrBaseUrl = 'qr_base_url';

  String? _baseUrl;
  String? _apiKey;
  bool _enabled = false;
  bool _qrOrderEnabled = false;
  String? _qrBaseUrl;
  
  // Track consecutive timeout errors for log spam reduction
  static int _timeoutErrorCount = 0;

  /// Initialize the service (call on app start)
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_keyApiEnabled) ?? false;
    _baseUrl = _normalizeApiUrl(prefs.getString(_keyBaseUrl));
    _apiKey = prefs.getString(_keyApiKey);
    _qrOrderEnabled = prefs.getBool(_keyQrOrderEnabled) ?? false;
    _qrBaseUrl = prefs.getString(_keyQrBaseUrl);
  }

  /// Normalize API base URL to ensure it ends with /api
  String? _normalizeApiUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    // Remove trailing slash
    url = url.replaceAll(RegExp(r'/$'), '');
    
    // Ensure URL ends with /api
    if (!url.endsWith('/api')) {
      // Check if it ends with /api/ (remove trailing slash case)
      if (!url.contains('/api')) {
        url = '$url/api';
      }
    }
    
    return url;
  }

  /// Build full API URL for an endpoint
  /// Includes api_key as query param for hosts that strip custom headers
  String _buildApiUrl(String endpoint, {Map<String, String>? extraParams}) {
    if (_baseUrl == null || _baseUrl!.isEmpty) return '';
    // Ensure endpoint doesn't start with /
    endpoint = endpoint.replaceAll(RegExp(r'^/'), '');
    
    String url = '$_baseUrl/$endpoint';
    
    // Add API key as query parameter (fallback for hosts that strip headers)
    final params = <String, String>{};
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      params['api_key'] = _apiKey!;
    }
    if (extraParams != null) {
      params.addAll(extraParams);
    }
    
    if (params.isNotEmpty) {
      final queryString = params.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      url = '$url?$queryString';
    }
    
    return url;
  }

  /// Check if API is enabled
  bool get isEnabled => _enabled && _baseUrl != null && _baseUrl!.isNotEmpty;
  
  /// Check if QR ordering is enabled
  bool get isQrOrderEnabled => _qrOrderEnabled && _qrBaseUrl != null && _qrBaseUrl!.isNotEmpty;
  
  /// Get QR base URL
  String? get qrBaseUrl => _qrBaseUrl;

  /// Get web ordering URL for QR code (Open Table)
  /// Uses the separate QR base URL if configured, otherwise falls back to API base URL
  String getWebOrderUrl({
    required int tableId,
    required String tableName,
    int? tierId,
    int? orderId,
  }) {
    // First check QR ordering settings
    if (_qrOrderEnabled && _qrBaseUrl != null && _qrBaseUrl!.isNotEmpty) {
      // Use query parameter format: https://tiores.ttmb-tech.com/?table=6&tier=2
      String url = _qrBaseUrl!.replaceAll(RegExp(r'/$'), ''); // Remove trailing slash
      
      final params = <String, String>{
        'table': tableId.toString(),
      };
      if (tierId != null) params['tier'] = tierId.toString();
      if (orderId != null) params['order'] = orderId.toString();
      
      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      return '$url/?$queryString';
    }
    
    // Fallback to API base URL if QR ordering not configured
    if (_baseUrl == null || _baseUrl!.isEmpty) return '';

    // Remove /api suffix if present to get base web URL
    String webBase = _baseUrl!.replaceAll(RegExp(r'/api/?$'), '');

    final params = <String, String>{
      'table': tableId.toString(),
    };
    if (tierId != null) params['tier'] = tierId.toString();
    if (orderId != null) params['order'] = orderId.toString();

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$webBase/?$queryString';
  }
  
  /// Get menu page URL for QR code
  String getMenuUrl({
    required int tableId,
    required String tableName,
    int? tierId,
  }) {
    String? baseUrl = _qrBaseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      baseUrl = _baseUrl?.replaceAll(RegExp(r'/api/?$'), '');
    }
    if (baseUrl == null || baseUrl.isEmpty) return '';
    
    baseUrl = baseUrl.replaceAll(RegExp(r'/$'), '');
    
    final params = <String, String>{
      'table': tableId.toString(),
      'name': tableName,
    };
    if (tierId != null) params['tier'] = tierId.toString();
    
    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '$baseUrl/?$queryString';
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
        Uri.parse(_buildApiUrl('update_items.php')),
        headers: _headers,
        body: jsonEncode({
          'items': items
              .map((item) => {
                    'id': item.id,
                    'name': item.name,
                    'name_en': item.nameEn,
                    'name_th': item.nameTh,
                    'name_cn': item.nameCn,
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
        Uri.parse(_buildApiUrl('delete_items.php')),
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
      final url = _buildApiUrl('get_pending_orders.php');
      debugPrint('API Fetch Orders URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 15), // Increased from 8 to 15 seconds
        onTimeout: () {
          throw TimeoutException('Request timeout after 15 seconds', const Duration(seconds: 15));
        },
      );

      // Check if response is successful
      if (response.statusCode != 200) {
        debugPrint('API Fetch Orders HTTP Error: ${response.statusCode} - ${response.body}');
        return [];
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        debugPrint('API Fetch Orders: Server returned success=false - ${data['message'] ?? 'Unknown error'}');
        return [];
      }

      // Reset timeout error counter on success
      _timeoutErrorCount = 0;
      
      final orders = (data['orders'] as List<dynamic>? ?? [])
          .map((o) => WebOrder.fromJson(o as Map<String, dynamic>))
          .toList();
      
      if (orders.isNotEmpty) {
        debugPrint('API Fetch Orders: Found ${orders.length} orders with ${orders.fold<int>(0, (sum, o) => sum + o.items.length)} items');
      }
      
      return orders;
    } on TimeoutException catch (e) {
      _timeoutErrorCount++;
      // Only log every 5th timeout to reduce log spam
      if (_timeoutErrorCount == 1 || _timeoutErrorCount % 5 == 0) {
        debugPrint('API Fetch Orders Timeout (attempt $_timeoutErrorCount): $e');
      }
      return [];
    } on SocketException catch (e) {
      // Connection reset, refused, or network unavailable
      debugPrint('API Fetch Orders Network Error: ${e.message} (${e.osError?.message ?? 'No OS error'})');
      return [];
    } on HttpException catch (e) {
      debugPrint('API Fetch Orders HTTP Error: ${e.message}');
      return [];
    } on FormatException catch (e) {
      debugPrint('API Fetch Orders Parse Error: $e');
      return [];
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
        Uri.parse(_buildApiUrl('acknowledge_order.php')),
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

  /// Update table status on hosting (when POS opens/closes a table)
  /// status: 0=available, 1=occupied, 2=cleaning
  Future<bool> updateTableStatus(int tableId, int status) async {
    if (!isEnabled) return false;

    try {
      final response = await http.post(
        Uri.parse(_buildApiUrl('update_table_status.php')),
        headers: _headers,
        body: jsonEncode({
          'table_id': tableId,
          'status': status,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        debugPrint('API Table Status Updated: Table $tableId -> $status');
        return true;
      } else {
        debugPrint('API Table Status Error: ${data['error'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      debugPrint('API Table Status Error: $e');
      return false;
    }
  }

  /// Sync all categories to server
  Future<SyncResult> syncCategories(List<MenuCategory> categories) async {
    if (!isEnabled) return SyncResult(success: false, message: 'API not enabled');

    try {
      final categoriesData = categories.map((cat) {
        return <String, dynamic>{
          'id': cat.id,
          'name': cat.name,
          'name_en': cat.nameEn,
          'name_th': cat.name, // Thai is the default name
          'name_cn': cat.nameCn,
          'sort_order': 0,
          'is_active': 1,
        };
      }).toList();

      final response = await http.post(
        Uri.parse(_buildApiUrl('sync_categories.php')),
        headers: _headers,
        body: jsonEncode({'categories': categoriesData}),
      );

      final data = jsonDecode(response.body);
      return SyncResult(
        success: data['success'] == true,
        message: (data['message'] as String?) ?? 'Categories synced',
        count: (data['synced_count'] as int?) ?? categories.length,
      );
    } catch (e) {
      debugPrint('API Sync Categories Error: $e');
      return SyncResult(success: false, message: e.toString());
    }
  }

  /// Sync all buffet tiers to server
  Future<SyncResult> syncBuffetTiers(List<BuffetTier> tiers) async {
    if (!isEnabled) return SyncResult(success: false, message: 'API not enabled');

    try {
      final tiersData = tiers.map((tier) {
        return <String, dynamic>{
          'id': tier.id,
          'name': tier.name,
          'name_th': tier.name,
          'price': tier.price,
          'is_active': tier.isActive ? 1 : 0,
          'sort_order': 0,
          'excluded_category_ids': tier.excludedCategoryIds.isEmpty ? null : jsonEncode(tier.excludedCategoryIds),
        };
      }).toList();

      final response = await http.post(
        Uri.parse(_buildApiUrl('sync_buffet_tiers.php')),
        headers: _headers,
        body: jsonEncode({'buffet_tiers': tiersData}),
      );

      final data = jsonDecode(response.body);
      return SyncResult(
        success: data['success'] == true,
        message: (data['message'] as String?) ?? 'Buffet tiers synced',
        count: (data['synced_count'] as int?) ?? tiers.length,
      );
    } catch (e) {
      debugPrint('API Sync Buffet Tiers Error: $e');
      return SyncResult(success: false, message: e.toString());
    }
  }

  /// Sync all tables to server
  Future<SyncResult> syncTables(List<TableModel> tables) async {
    if (!isEnabled) return SyncResult(success: false, message: 'API not enabled');

    try {
      final tablesData = tables.map((table) {
        return <String, dynamic>{
          'id': table.id,
          'table_name': table.tableName,
          'seats': 4,
          'zone': 'Main',
          'position_x': table.x.toInt(),
          'position_y': table.y.toInt(),
        };
      }).toList();

      final response = await http.post(
        Uri.parse(_buildApiUrl('sync_tables.php')),
        headers: _headers,
        body: jsonEncode({'tables': tablesData}),
      );

      final data = jsonDecode(response.body);
      return SyncResult(
        success: data['success'] == true,
        message: (data['message'] as String?) ?? 'Tables synced',
        count: (data['synced_count'] as int?) ?? tables.length,
      );
    } catch (e) {
      debugPrint('API Sync Tables Error: $e');
      return SyncResult(success: false, message: e.toString());
    }
  }

  /// Sync all menu items to server (full sync)
  /// If uploadImages is true, uploads local images first
  Future<SyncResult> syncAllMenuItems(
    List<MenuItem> items, {
    Map<String, String>? imageUrlMap,
    void Function(String status)? onProgress,
  }) async {
    if (!isEnabled) return SyncResult(success: false, message: 'API not enabled');

    try {
      // Upload images if not already done
      Map<String, String> finalImageUrls = imageUrlMap ?? {};
      
      if (imageUrlMap == null) {
        // Collect local image paths
        final localPaths = items
            .where((item) => item.imagePath != null && 
                            item.imagePath!.isNotEmpty &&
                            !item.imagePath!.startsWith('http'))
            .map((item) => item.imagePath!)
            .toSet()
            .toList();
        
        if (localPaths.isNotEmpty) {
          onProgress?.call('กำลังอัพโหลดรูปภาพ ${localPaths.length} รูป...');
          int uploaded = 0;
          
          for (final path in localPaths) {
            final url = await uploadImage(path);
            if (url != null) {
              finalImageUrls[path] = url;
              uploaded++;
              onProgress?.call('อัพโหลดรูปภาพ $uploaded/${localPaths.length}...');
            }
          }
        }
      }

      onProgress?.call('กำลังซิงค์เมนู...');
      
      final response = await http.post(
        Uri.parse(_buildApiUrl('sync_menu_items.php')),
        headers: _headers,
        body: jsonEncode({
          'items': items.map((item) {
            // Use uploaded URL if available, otherwise keep original
            String? imageUrl = item.imagePath;
            if (imageUrl != null && finalImageUrls.containsKey(imageUrl)) {
              imageUrl = finalImageUrls[imageUrl];
            }
            
            return {
              'id': item.id,
              'name': item.name,
              'name_en': item.nameEn,
              'name_th': item.nameTh,
              'name_cn': item.nameCn,
              'price': item.price,
              'description': item.description,
              'image_url': imageUrl,
              'category_id': item.categoryId,
              'buffet_tier_id': null, // Not tracked in current model
              'is_available': item.isAvailable ? 1 : 0,
              'is_extra_charge': item.price > 0 ? 1 : 0,
              'sort_order': 0,
            };
          }).toList(),
        }),
      );

      final data = jsonDecode(response.body);
      final uploadedCount = finalImageUrls.length;
      return SyncResult(
        success: data['success'] == true,
        message: uploadedCount > 0 
            ? 'Menu synced ($uploadedCount images uploaded)'
            : (data['message'] as String?) ?? 'Menu items synced',
        count: (data['synced_count'] as int?) ?? items.length,
      );
    } catch (e) {
      debugPrint('API Sync Menu Items Error: $e');
      return SyncResult(success: false, message: e.toString());
    }
  }

  /// Sync store info to server
  Future<SyncResult> syncStoreInfo(Map<String, dynamic> storeInfo) async {
    if (!isEnabled) return SyncResult(success: false, message: 'API not enabled');

    try {
      final response = await http.post(
        Uri.parse(_buildApiUrl('sync_store_info.php')),
        headers: _headers,
        body: jsonEncode(storeInfo),
      );

      final data = jsonDecode(response.body);
      return SyncResult(
        success: data['success'] == true,
        message: (data['message'] as String?) ?? 'Store info synced',
        count: 1,
      );
    } catch (e) {
      debugPrint('API Sync Store Info Error: $e');
      return SyncResult(success: false, message: e.toString());
    }
  }

  /// Resolve relative image path to absolute path
  /// Images are stored in app documents directory with relative paths like 'menu_images/item_xxx.jpg'
  Future<String?> _resolveImagePath(String relativePath) async {
    // If already absolute path, return as is
    if (relativePath.startsWith('/') || relativePath.contains('://')) {
      return relativePath;
    }
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      return '${appDir.path}/$relativePath';
    } catch (e) {
      debugPrint('Error resolving image path: $e');
      return null;
    }
  }

  /// Upload a single image to server
  /// Accepts either relative path (menu_images/xxx.jpg) or absolute path
  /// Returns the public URL of the uploaded image, or null if failed
  Future<String?> uploadImage(String localPath, {int? itemId}) async {
    if (!isEnabled) return null;
    
    // Resolve relative path to absolute
    final absolutePath = await _resolveImagePath(localPath);
    if (absolutePath == null) {
      debugPrint('Could not resolve image path: $localPath');
      return null;
    }
    
    final file = File(absolutePath);
    if (!file.existsSync()) {
      debugPrint('Image file not found: $absolutePath (from: $localPath)');
      return null;
    }

    try {
      final uri = Uri.parse(_buildApiUrl('upload_image.php'));
      final request = http.MultipartRequest('POST', uri);
      
      // Add API key header
      if (_apiKey != null && _apiKey!.isNotEmpty) {
        request.headers['X-API-Key'] = _apiKey!;
      }
      
      // Add item_id if provided
      if (itemId != null) {
        request.fields['item_id'] = itemId.toString();
      }
      
      // Add API key as field too (fallback)
      if (_apiKey != null && _apiKey!.isNotEmpty) {
        request.fields['api_key'] = _apiKey!;
      }
      
      // Add file
      request.files.add(await http.MultipartFile.fromPath('image', absolutePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('Image uploaded: ${data['image_url']}');
          return data['image_url'] as String?;
        }
      }
      
      debugPrint('Image upload failed: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  /// Upload multiple images and return map of local path -> server URL
  Future<Map<String, String>> uploadImages(
    List<String> localPaths, {
    void Function(int current, int total)? onProgress,
  }) async {
    final results = <String, String>{};
    
    for (int i = 0; i < localPaths.length; i++) {
      final path = localPaths[i];
      onProgress?.call(i + 1, localPaths.length);
      
      final url = await uploadImage(path);
      if (url != null) {
        results[path] = url;
      }
    }
    
    return results;
  }

  /// Send ALL data to server (first-time setup)
  /// Returns detailed results for each data type
  Future<FullSyncResult> syncAllData({
    void Function(String status)? onProgress,
    Map<String, dynamic>? storeInfo,
  }) async {
    if (!isEnabled) {
      return FullSyncResult(
        success: false,
        message: 'API not enabled',
        storeInfo: SyncResult(success: false, message: 'Skipped'),
        categories: SyncResult(success: false, message: 'Skipped'),
        buffetTiers: SyncResult(success: false, message: 'Skipped'),
        tables: SyncResult(success: false, message: 'Skipped'),
        menuItems: SyncResult(success: false, message: 'Skipped'),
      );
    }

    final db = DatabaseHelper();
    
    // 0. Sync Store Info (if provided)
    SyncResult storeResult = SyncResult(success: true, message: 'No store info', count: 0);
    if (storeInfo != null && storeInfo.isNotEmpty) {
      onProgress?.call('กำลังซิงค์ข้อมูลร้าน...');
      storeResult = await syncStoreInfo(storeInfo);
    }
    
    // 1. Sync Categories
    onProgress?.call('กำลังซิงค์หมวดหมู่...');
    final categories = await db.getAllCategories();
    final catResult = await syncCategories(categories);
    
    // 2. Sync Buffet Tiers
    onProgress?.call('กำลังซิงค์ราคาบุฟเฟต์...');
    final tiersData = await db.getAllBuffetTiers();
    final tiers = tiersData.map((m) => BuffetTier.fromMap(m)).toList();
    final tierResult = await syncBuffetTiers(tiers);
    
    // 3. Sync Tables
    onProgress?.call('กำลังซิงค์โต๊ะ...');
    final tables = await db.getAllTables();
    final tableResult = await syncTables(tables);
    
    // 4. Sync Menu Items (including image upload)
    onProgress?.call('กำลังซิงค์เมนู...');
    final menuItems = await db.getAllMenuItems();
    final menuResult = await syncAllMenuItems(
      menuItems,
      onProgress: onProgress,
    );
    
    final allSuccess = storeResult.success && catResult.success && tierResult.success && 
                       tableResult.success && menuResult.success;
    
    return FullSyncResult(
      success: allSuccess,
      message: allSuccess ? 'ซิงค์ข้อมูลทั้งหมดสำเร็จ' : 'บางรายการซิงค์ไม่สำเร็จ',
      storeInfo: storeResult,
      categories: catResult,
      buffetTiers: tierResult,
      tables: tableResult,
      menuItems: menuResult,
    );
  }

  /// Test API connection
  Future<bool> testConnection() async {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      debugPrint('API Test: Base URL is empty');
      return false;
    }

    try {
      final url = _buildApiUrl('get_items.php');
      debugPrint('Testing API connection: $url');
      debugPrint('API Key: ${_apiKey != null ? '${_apiKey!.substring(0, 4)}...' : 'null'}');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      debugPrint('API connection test result: ${response.statusCode}');
      debugPrint('API response body: ${response.body}');
      
      // 200 = success, also accept if store was auto-created
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('API Connection Test Error: $e');
      return false;
    }
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int count;

  SyncResult({
    required this.success,
    required this.message,
    this.count = 0,
  });
}

/// Result of full data sync
class FullSyncResult {
  final bool success;
  final String message;
  final SyncResult storeInfo;
  final SyncResult categories;
  final SyncResult buffetTiers;
  final SyncResult tables;
  final SyncResult menuItems;

  FullSyncResult({
    required this.success,
    required this.message,
    required this.storeInfo,
    required this.categories,
    required this.buffetTiers,
    required this.tables,
    required this.menuItems,
  });

  int get totalSynced => 
      storeInfo.count + categories.count + buffetTiers.count + tables.count + menuItems.count;
}

/// Helper to parse number from JSON (handles both num and String)
int _parseIntFromJson(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

double _parseDoubleFromJson(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
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
      id: _parseIntFromJson(json['id']),
      tableId: _parseIntFromJson(json['table_id']),
      tableName: (json['table_name'] as String?) ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => WebOrderItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      totalAmount: _parseDoubleFromJson(json['total_amount']),
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}

class WebOrderItem {
  final int id; // Unique order_item ID for tracking
  final int itemId;
  final String name;
  final int quantity;
  final double price;
  final String? notes;

  WebOrderItem({
    required this.id,
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.price,
    this.notes,
  });

  factory WebOrderItem.fromJson(Map<String, dynamic> json) {
    return WebOrderItem(
      id: _parseIntFromJson(json['id']), // order_item.id from database
      itemId: _parseIntFromJson(json['item_id']) != 0 
          ? _parseIntFromJson(json['item_id']) 
          : _parseIntFromJson(json['menu_item_id']),
      name: (json['name'] as String?) ?? '',
      quantity: _parseIntFromJson(json['quantity'], 1),
      price: _parseDoubleFromJson(json['price']),
      notes: json['notes'] as String?,
    );
  }
}
