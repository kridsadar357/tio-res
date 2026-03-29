/// Application-wide constants
/// 
/// This file contains all constants used throughout the application
/// to ensure consistency and easy maintenance.
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  // App Information
  static const String appName = 'ResPOS';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Buffet Restaurant POS System';

  // Database
  static const String databaseName = 'respos.db';
  static const int databaseVersion = 13;

  // Table Names
  static const String tablesTable = 'tables';
  static const String menuCategoriesTable = 'menu_categories';
  static const String menuItemsTable = 'menu_items';
  static const String ordersTable = 'orders';
  static const String orderItemsTable = 'order_items';
  static const String transactionsTable = 'transactions';
  static const String shiftsTable = 'shifts';
  static const String buffetTiersTable = 'buffet_tiers';
  static const String layoutObjectsTable = 'layout_objects';
  static const String customersTable = 'customers';
  static const String promotionsTable = 'promotions';

  // Table Status
  static const int tableAvailable = 0;
  static const int tableOccupied = 1;
  static const int tableCleaning = 2;

  // Order Status
  static const String orderOpen = 'OPEN';
  static const String orderCompleted = 'COMPLETED';
  static const String orderCancelled = 'CANCELLED';

  // Shift Status
  static const String shiftOpen = 'OPEN';
  static const String shiftClosed = 'CLOSED';

  // Payment Methods
  static const String paymentCash = 'CASH';
  static const String paymentQR = 'QR';
  static const String paymentCard = 'CARD';

  // Discount Types
  static const String discountPercent = 'PERCENT';
  static const String discountFixed = 'FIXED';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultIconSize = 24.0;

  // Screen Design Size (Tablet 10.1")
  static const double designWidth = 1280.0;
  static const double designHeight = 800.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Cache Keys
  static const String cacheKeySettings = 'app_settings';
  static const String cacheKeyLastSync = 'last_sync_time';

  // File Paths
  static const String menuImagesPath = 'menu_images';
  static const String receiptsPath = 'receipts';
}

