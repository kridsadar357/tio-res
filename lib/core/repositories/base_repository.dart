import '../utils/result.dart';
import '../utils/logger.dart';
import '../errors/app_exceptions.dart';

/// Base repository interface
/// 
/// Provides common CRUD operations and error handling
abstract class BaseRepository<T, ID> {
  /// Get all entities
  Future<Result<List<T>>> getAll();

  /// Get entity by ID
  Future<Result<T?>> getById(ID id);

  /// Create new entity
  Future<Result<T>> create(T entity);

  /// Update existing entity
  Future<Result<T>> update(ID id, T entity);

  /// Delete entity by ID
  Future<Result<void>> delete(ID id);

  /// Handle errors consistently
  Failure<T> handleError(Object error, [StackTrace? stackTrace]) {
    Logger.error(
      'Repository error: ${error.toString()}',
      error: error,
      stackTrace: stackTrace,
    );

    if (error is AppException) {
      return Failure<T>(error.message, error: error, stackTrace: stackTrace);
    }

    return Failure<T>(
      'An unexpected error occurred',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

