/// Base exception class for application errors
abstract class AppException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

/// Database-related exceptions
class DatabaseException extends AppException {
  const DatabaseException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

/// File operation exceptions
class FileException extends AppException {
  const FileException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

/// Printer-related exceptions
class PrinterException extends AppException {
  const PrinterException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

