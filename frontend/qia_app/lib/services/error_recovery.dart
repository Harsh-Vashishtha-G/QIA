import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

class ErrorRecovery {
  static final ErrorRecovery _instance = ErrorRecovery._internal();
  factory ErrorRecovery() => _instance;
  ErrorRecovery._internal();

  final _errorCounts = <String, int>{};
  final _lastErrors = <String, DateTime>{};
  final _recoveryStrategies = <String, Future<void> Function()>{};
  
  // Maximum number of retry attempts
  static const _maxRetries = 3;
  // Cooldown period between retries
  static const _cooldownPeriod = Duration(minutes: 5);

  void registerRecoveryStrategy(String errorType, Future<void> Function() strategy) {
    _recoveryStrategies[errorType] = strategy;
  }

  Future<T> tryOperation<T>({
    required Future<T> Function() operation,
    required String operationType,
    T Function(dynamic error)? fallback,
    Duration? timeout,
  }) async {
    try {
      if (timeout != null) {
        return await operation().timeout(timeout);
      }
      return await operation();
    } catch (e) {
      return await _handleError<T>(e, operationType, operation, fallback);
    }
  }

  Future<T> _handleError<T>(
    dynamic error,
    String operationType,
    Future<T> Function() operation,
    T Function(dynamic error)? fallback,
  ) async {
    Logger.error('Operation failed: $operationType', error: error);

    // Update error tracking
    _errorCounts[operationType] = (_errorCounts[operationType] ?? 0) + 1;
    _lastErrors[operationType] = DateTime.now();

    // Check if we should attempt recovery
    if (_shouldAttemptRecovery(operationType)) {
      try {
        // Execute recovery strategy if available
        final strategy = _recoveryStrategies[operationType];
        if (strategy != null) {
          await strategy();
          // Retry operation after recovery
          return await operation();
        }
      } catch (recoveryError) {
        Logger.error(
          'Recovery failed for: $operationType',
          error: recoveryError,
        );
      }
    }

    // If recovery failed or not available, use fallback or rethrow
    if (fallback != null) {
      return fallback(error);
    }
    throw error;
  }

  bool _shouldAttemptRecovery(String operationType) {
    final errorCount = _errorCounts[operationType] ?? 0;
    final lastError = _lastErrors[operationType];

    // Check if we're within retry limits
    if (errorCount >= _maxRetries) {
      // Check if cooldown period has passed
      if (lastError != null && 
          DateTime.now().difference(lastError) > _cooldownPeriod) {
        // Reset error count after cooldown
        _errorCounts[operationType] = 0;
        return true;
      }
      return false;
    }
    return true;
  }

  void resetErrorCount(String operationType) {
    _errorCounts.remove(operationType);
    _lastErrors.remove(operationType);
  }
} 