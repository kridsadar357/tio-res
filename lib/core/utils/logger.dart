import 'dart:developer' as developer;

/// Centralized logging utility
/// 
/// Provides consistent logging throughout the application
/// with different log levels and formatting
class Logger {
  Logger._(); // Private constructor

  static const String _defaultTag = 'ResPOS';

  /// Log debug messages (only in debug mode)
  static void debug(String message, {String? tag}) {
    assert(() {
      developer.log(message, name: tag ?? _defaultTag);
      return true;
    }());
  }

  /// Log info messages
  static void info(String message, {String? tag}) {
    developer.log(message, name: tag ?? _defaultTag);
  }

  /// Log warning messages
  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: tag ?? _defaultTag,
      level: 900, // Warning level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log error messages
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag ?? _defaultTag,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log fatal errors
  static void fatal(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag ?? _defaultTag,
      level: 1200, // Fatal level
      error: error,
      stackTrace: stackTrace,
    );
  }
}

