import 'package:flutter/foundation.dart';

/// Application configuration
/// 
/// Centralized configuration management for different environments
class AppConfig {
  AppConfig._();

  /// Check if running in debug mode
  static bool get isDebug => kDebugMode;

  /// Check if running in release mode
  static bool get isRelease => kReleaseMode;

  /// Check if running in profile mode
  static bool get isProfile => kProfileMode;

  /// Enable verbose logging
  static bool get enableVerboseLogging => isDebug;

  /// Database query timeout (seconds)
  static const int databaseTimeout = 30;

  /// API request timeout (seconds)
  static const int apiTimeout = 30;

  /// Maximum retry attempts for network requests
  static const int maxRetryAttempts = 3;

  /// Cache expiration time (hours)
  static const int cacheExpirationHours = 24;

  /// Image compression quality (0.0 - 1.0)
  static const double imageCompressionQuality = 0.85;

  /// Maximum image size (MB)
  static const int maxImageSizeMB = 5;

  /// Enable performance monitoring
  static bool get enablePerformanceMonitoring => isDebug;

  /// Enable error reporting
  static bool get enableErrorReporting => isRelease;
}

