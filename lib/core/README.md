# Core Module

This directory contains the core infrastructure and utilities used throughout the application.

## Structure

```
core/
├── constants/          # Application-wide constants
│   ├── app_constants.dart    # Database, table names, status codes
│   └── app_colors.dart        # Color definitions
├── config/            # Configuration management
│   └── app_config.dart        # Environment and feature flags
├── errors/            # Exception classes
│   └── app_exceptions.dart   # Custom exception types
└── utils/             # Utility classes
    ├── logger.dart            # Centralized logging
    ├── result.dart            # Result type for error handling
    └── performance.dart       # Performance monitoring
```

## Usage

### Constants

```dart
import 'package:respos/core/constants/app_constants.dart';

// Use constants instead of magic numbers/strings
final tableStatus = AppConstants.tableOccupied;
final dbName = AppConstants.databaseName;
```

### Logging

```dart
import 'package:respos/core/utils/logger.dart';

Logger.info('User logged in');
Logger.error('Database error', error: e, stackTrace: stackTrace);
```

### Result Type

```dart
import 'package:respos/core/utils/result.dart';

Result<User> getUser(int id) {
  try {
    final user = database.getUser(id);
    return Success(user);
  } catch (e) {
    return Failure('Failed to get user', error: e);
  }
}

// Usage
final result = getUser(1);
if (result.isSuccess) {
  final user = result.dataOrNull;
} else {
  final error = result.errorOrNull;
}
```

### Performance Monitoring

```dart
import 'package:respos/core/utils/performance.dart';

final data = await PerformanceMonitor.measureAsync(
  () => fetchData(),
  label: 'Fetch Data',
);
```

### Configuration

```dart
import 'package:respos/core/config/app_config.dart';

if (AppConfig.isDebug) {
  // Debug-only code
}
```

## Best Practices

1. **Always use constants** from `app_constants.dart` instead of hardcoding values
2. **Use Logger** instead of `print()` for better debugging
3. **Use Result type** for functions that can fail instead of throwing exceptions
4. **Monitor performance** in critical paths using `PerformanceMonitor`
5. **Check AppConfig** before enabling debug features

