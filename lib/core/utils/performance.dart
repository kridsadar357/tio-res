import 'dart:async';
import 'package:flutter/foundation.dart';

/// Performance monitoring utilities
class PerformanceMonitor {
  PerformanceMonitor._();

  /// Measure execution time of a function
  static Future<T> measureAsync<T>(
    Future<T> Function() function, {
    String? label,
    void Function(Duration duration)? onComplete,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await function();
    } finally {
      stopwatch.stop();
      if (kDebugMode && label != null) {
        debugPrint('⏱️ $label: ${stopwatch.elapsedMilliseconds}ms');
      }
      onComplete?.call(stopwatch.elapsed);
    }
  }

  /// Measure execution time of a synchronous function
  static T measureSync<T>(
    T Function() function, {
    String? label,
    void Function(Duration duration)? onComplete,
  }) {
    final stopwatch = Stopwatch()..start();
    try {
      return function();
    } finally {
      stopwatch.stop();
      if (kDebugMode && label != null) {
        debugPrint('⏱️ $label: ${stopwatch.elapsedMicroseconds}μs');
      }
      onComplete?.call(stopwatch.elapsed);
    }
  }

  /// Track memory usage (debug only)
  static void trackMemory(String label) {
    if (kDebugMode) {
      // Memory tracking can be implemented with platform channels if needed
      debugPrint('💾 Memory: $label');
    }
  }
}

