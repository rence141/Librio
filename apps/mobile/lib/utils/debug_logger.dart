import 'package:flutter/foundation.dart';

/// Centralized debug logger for Librio
/// Logs all errors and important events with context
class DebugLogger {
  static const String _prefix = '🔍 [LIBRIO]';

  /// Log an error with full context
  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('$_prefix ERROR [$timestamp] [$tag] $message');
    if (error != null) {
      debugPrint('$_prefix ERROR [$tag] Exception: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('$_prefix ERROR [$tag] StackTrace: $stackTrace');
    }
  }

  /// Log a warning
  static void warning(String tag, String message) {
    debugPrint('$_prefix WARN [$tag] $message');
  }

  /// Log info
  static void info(String tag, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix INFO [$tag] $message');
    }
  }

  /// Log a success
  static void success(String tag, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix ✅ [$tag] $message');
    }
  }

  /// Log debug info
  static void debug(String tag, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix DEBUG [$tag] $message');
    }
  }

  /// Wrap an async operation with error logging
  static Future<T?> guard<T>(
    String tag,
    String operation,
    Future<T> Function() task, {
    T? defaultValue,
  }) async {
    try {
      debug(tag, 'Starting: $operation');
      final result = await task();
      success(tag, 'Completed: $operation');
      return result;
    } catch (e, st) {
      error(tag, 'Failed: $operation', e, st);
      return defaultValue;
    }
  }
}
