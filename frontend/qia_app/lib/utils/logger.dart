import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class Logger {
  static const String _logFileName = 'qia_app.log';
  static File? _logFile;
  static bool _initialized = false;

  static Future<void> _initialize() async {
    if (_initialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/$_logFileName');
      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize logger: $e');
    }
  }

  static Future<void> _writeLog(
    String level,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) async {
    await _initialize();

    final timestamp = DateTime.now().toIso8601String();
    final logEntry = {
      'timestamp': timestamp,
      'level': level,
      'message': message,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };

    try {
      final logLine = json.encode(logEntry);
      
      // Write to file
      if (_logFile != null) {
        await _logFile!.writeAsString('$logLine\n', mode: FileMode.append);
      }

      // Print to console in debug mode
      if (kDebugMode) {
        debugPrint('[$level] $message');
        if (error != null) debugPrint('Error: $error');
        if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
      }
    } catch (e) {
      debugPrint('Failed to write log: $e');
    }
  }

  static Future<void> info(String message) async {
    await _writeLog('INFO', message);
  }

  static Future<void> warning(String message, {dynamic error}) async {
    await _writeLog('WARNING', message, error: error);
  }

  static Future<void> error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) async {
    await _writeLog('ERROR', message, error: error, stackTrace: stackTrace);
  }

  static Future<List<String>> getLogs() async {
    await _initialize();
    if (_logFile == null || !await _logFile!.exists()) {
      return [];
    }
    return await _logFile!.readAsLines();
  }

  static Future<void> clearLogs() async {
    await _initialize();
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.delete();
    }
  }
} 