/// Result type for error handling
/// 
/// Provides a functional approach to error handling
/// instead of using exceptions for control flow
sealed class Result<T> {
  const Result();
}

/// Success result containing data
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Error result containing error information
class Failure<T> extends Result<T> {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  
  const Failure(
    this.message, {
    this.error,
    this.stackTrace,
  });
}

/// Extension methods for Result
extension ResultExtensions<T> on Result<T> {
  /// Check if result is success
  bool get isSuccess => this is Success<T>;
  
  /// Check if result is failure
  bool get isFailure => this is Failure<T>;
  
  /// Get data if success, null otherwise
  T? get dataOrNull => switch (this) {
    Success(data: final d) => d,
    Failure() => null,
  };
  
  /// Get error message if failure, null otherwise
  String? get errorOrNull => switch (this) {
    Success() => null,
    Failure(message: final m) => m,
  };
  
  /// Map success data to another type
  Result<R> map<R>(R Function(T) mapper) {
    return switch (this) {
      Success(data: final d) => Success(mapper(d)),
      Failure(message: final m, error: final e, stackTrace: final s) => 
        Failure<R>(m, error: e, stackTrace: s),
    };
  }
  
  /// Map failure to another type
  Result<T> mapError(String Function(String) mapper) {
    return switch (this) {
      Success() => this,
      Failure(message: final m, error: final e, stackTrace: final s) => 
        Failure<T>(mapper(m), error: e, stackTrace: s),
    };
  }
}

