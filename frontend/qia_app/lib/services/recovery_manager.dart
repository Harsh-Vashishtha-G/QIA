import 'dart:async';
import '../utils/logger.dart';
import 'package:flutter/foundation.dart';

enum RecoveryStrategy {
  retry,
  fallback,
  reset,
  selfHeal,
  manualIntervention
}

class RecoveryManager extends ChangeNotifier {
  static final RecoveryManager _instance = RecoveryManager._internal();
  factory RecoveryManager() => _instance;
  RecoveryManager._internal();

  final Map<String, RecoveryConfig> _recoveryConfigs = {};
  final Map<String, int> _failureCount = {};
  final Map<String, DateTime> _lastFailure = {};
  final Map<String, Completer<void>> _recoveryInProgress = {};
  bool _isInSelfHealMode = false;

  void registerRecoveryConfig(String operationType, RecoveryConfig config) {
    _recoveryConfigs[operationType] = config;
  }

  Future<T> executeWithRecovery<T>({
    required String operationType,
    required Future<T> Function() primaryOperation,
    Future<T> Function()? fallbackOperation,
    T Function(dynamic error)? errorHandler,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      return await _executeWithTimeout(
        primaryOperation,
        timeout,
        operationType,
      );
    } catch (e) {
      return await _handleOperationFailure(
        operationType,
        e,
        primaryOperation,
        fallbackOperation,
        errorHandler,
      );
    }
  }

  Future<T> _executeWithTimeout<T>(
    Future<T> Function() operation,
    Duration timeout,
    String operationType,
  ) async {
    try {
      return await operation().timeout(timeout);
    } on TimeoutException {
      throw OperationException(
        'Operation timed out',
        operationType,
        RecoveryStrategy.retry,
      );
    }
  }

  Future<T> _handleOperationFailure<T>(
    String operationType,
    dynamic error,
    Future<T> Function() primaryOperation,
    Future<T> Function()? fallbackOperation,
    T Function(dynamic error)? errorHandler,
  ) async {
    final config = _recoveryConfigs[operationType];
    if (config == null) {
      Logger.error('No recovery config for: $operationType');
      if (errorHandler != null) return errorHandler(error);
      rethrow;
    }

    _updateFailureMetrics(operationType);
    
    // Check if we're already attempting recovery
    if (_recoveryInProgress[operationType]?.isCompleted == false) {
      await _recoveryInProgress[operationType]?.future;
      return primaryOperation();
    }

    _recoveryInProgress[operationType] = Completer<void>();

    try {
      final strategy = _determineRecoveryStrategy(operationType, config);
      final result = await _executeRecoveryStrategy(
        strategy,
        operationType,
        primaryOperation,
        fallbackOperation,
      );
      
      _recoveryInProgress[operationType]?.complete();
      _resetFailureMetrics(operationType);
      return result;
    } catch (recoveryError) {
      _recoveryInProgress[operationType]?.completeError(recoveryError);
      
      if (errorHandler != null) {
        return errorHandler(recoveryError);
      }
      rethrow;
    }
  }

  RecoveryStrategy _determineRecoveryStrategy(
    String operationType,
    RecoveryConfig config,
  ) {
    final failureCount = _failureCount[operationType] ?? 0;
    final lastFailure = _lastFailure[operationType];
    final timeSinceLastFailure = lastFailure != null
        ? DateTime.now().difference(lastFailure)
        : Duration.zero;

    if (failureCount >= config.maxRetries) {
      if (timeSinceLastFailure > config.cooldownPeriod) {
        _resetFailureMetrics(operationType);
        return RecoveryStrategy.retry;
      }
      return config.fallbackAvailable
          ? RecoveryStrategy.fallback
          : RecoveryStrategy.manualIntervention;
    }

    if (_isInSelfHealMode) {
      return RecoveryStrategy.selfHeal;
    }

    return RecoveryStrategy.retry;
  }

  Future<T> _executeRecoveryStrategy<T>(
    RecoveryStrategy strategy,
    String operationType,
    Future<T> Function() primaryOperation,
    Future<T> Function()? fallbackOperation,
  ) async {
    Logger.info('Executing recovery strategy: $strategy for $operationType');

    switch (strategy) {
      case RecoveryStrategy.retry:
        return await _retryWithBackoff(primaryOperation, operationType);
        
      case RecoveryStrategy.fallback:
        if (fallbackOperation != null) {
          return await fallbackOperation();
        }
        throw OperationException(
          'No fallback available',
          operationType,
          strategy,
        );
        
      case RecoveryStrategy.selfHeal:
        await _attemptSelfHeal(operationType);
        return await primaryOperation();
        
      case RecoveryStrategy.reset:
        await _resetService(operationType);
        return await primaryOperation();
        
      case RecoveryStrategy.manualIntervention:
        _notifyManualInterventionRequired(operationType);
        throw OperationException(
          'Manual intervention required',
          operationType,
          strategy,
        );
    }
  }

  Future<T> _retryWithBackoff<T>(
    Future<T> Function() operation,
    String operationType,
  ) async {
    final config = _recoveryConfigs[operationType]!;
    final failureCount = _failureCount[operationType] ?? 0;
    
    final delay = Duration(
      milliseconds: config.baseRetryDelay.inMilliseconds * (1 << failureCount),
    );
    
    await Future.delayed(delay);
    return await operation();
  }

  Future<void> _attemptSelfHeal(String operationType) async {
    _isInSelfHealMode = true;
    try {
      // Implement self-healing logic here
      // For example: clear caches, reset connections, etc.
      await Future.delayed(const Duration(seconds: 2));
    } finally {
      _isInSelfHealMode = false;
    }
  }

  Future<void> _resetService(String operationType) async {
    // Implement service reset logic
    notifyListeners();
  }

  void _notifyManualInterventionRequired(String operationType) {
    // Notify the UI that manual intervention is required
    notifyListeners();
  }

  void _updateFailureMetrics(String operationType) {
    _failureCount[operationType] = (_failureCount[operationType] ?? 0) + 1;
    _lastFailure[operationType] = DateTime.now();
  }

  void _resetFailureMetrics(String operationType) {
    _failureCount.remove(operationType);
    _lastFailure.remove(operationType);
  }

  void resetAllMetrics() {
    _failureCount.clear();
    _lastFailure.clear();
    _recoveryInProgress.clear();
    _isInSelfHealMode = false;
    notifyListeners();
  }
}

class RecoveryConfig {
  final int maxRetries;
  final Duration baseRetryDelay;
  final Duration cooldownPeriod;
  final bool fallbackAvailable;

  const RecoveryConfig({
    this.maxRetries = 3,
    this.baseRetryDelay = const Duration(seconds: 1),
    this.cooldownPeriod = const Duration(minutes: 5),
    this.fallbackAvailable = false,
  });
}

class OperationException implements Exception {
  final String message;
  final String operationType;
  final RecoveryStrategy attemptedStrategy;

  OperationException(this.message, this.operationType, this.attemptedStrategy);

  @override
  String toString() => 
    'OperationException: $message (Operation: $operationType, Strategy: $attemptedStrategy)';
} 