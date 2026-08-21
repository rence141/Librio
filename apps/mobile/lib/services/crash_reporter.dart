import 'package:flutter/foundation.dart';
import 'dart:async';

/// Crash report data
class CrashReport {
  final String id;
  final DateTime timestamp;
  final String message;
  final String stackTrace;
  final String? context;
  final Map<String, dynamic>? metadata;

  CrashReport({
    required this.id,
    required this.timestamp,
    required this.message,
    required this.stackTrace,
    this.context,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'message': message,
    'stackTrace': stackTrace,
    'context': context,
    'metadata': metadata,
  };

  @override
  String toString() => 'CrashReport(id: $id, message: $message)';
}

/// Crash reporting service
class CrashReporter {
  static final CrashReporter _instance = CrashReporter._internal();

  factory CrashReporter() {
    return _instance;
  }

  CrashReporter._internal();

  final List<CrashReport> _reports = [];
  int _crashCount = 0;

  /// Initialize crash reporting
  void initialize() {
    // Set up error handlers
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };

    if (kDebugMode) {
      print('🚨 Crash reporting initialized');
    }
  }

  /// Handle Flutter errors
  void _handleFlutterError(FlutterErrorDetails details) {
    final report = CrashReport(
      id: _generateId(),
      timestamp: DateTime.now(),
      message: details.exceptionAsString(),
      stackTrace: details.stack.toString(),
      context: details.context?.toString(),
      metadata: {
        'library': details.library,
        'informationCollector': details.informationCollector?.toString(),
      },
    );

    _recordCrash(report);
  }

  /// Handle platform errors
  void _handlePlatformError(Object error, StackTrace stack) {
    final report = CrashReport(
      id: _generateId(),
      timestamp: DateTime.now(),
      message: error.toString(),
      stackTrace: stack.toString(),
      metadata: {
        'type': 'platform_error',
      },
    );

    _recordCrash(report);
  }

  /// Record a crash
  void _recordCrash(CrashReport report) {
    _crashCount++;
    _reports.add(report);

    // Keep only last 50 reports
    if (_reports.length > 50) {
      _reports.removeAt(0);
    }

    if (kDebugMode) {
      print('💥 Crash recorded: ${report.message}');
      print('Stack trace: ${report.stackTrace}');
    }

    // In production, send to crash reporting service
    _sendCrashReport(report);
  }

  /// Send crash report to backend
  Future<void> _sendCrashReport(CrashReport report) async {
    try {
      // Send to backend
      if (kDebugMode) {
        print('📤 Sending crash report: ${report.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to send crash report: $e');
      }
    }
  }

  /// Get crash count
  int getCrashCount() => _crashCount;

  /// Get crash reports
  List<CrashReport> getCrashReports() => List.unmodifiable(_reports);

  /// Get recent crashes
  List<CrashReport> getRecentCrashes({int limit = 10}) {
    return _reports.skip((_reports.length - limit).clamp(0, _reports.length)).toList();
  }

  /// Clear crash reports
  void clearCrashReports() {
    _reports.clear();
    _crashCount = 0;

    if (kDebugMode) {
      print('🧹 Crash reports cleared');
    }
  }

  /// Get crash rate
  double getCrashRate() {
    // Crashes per hour
    if (_reports.isEmpty) return 0.0;

    final firstReport = _reports.first;
    final lastReport = _reports.last;
    final duration = lastReport.timestamp.difference(firstReport.timestamp);

    if (duration.inHours == 0) return 0.0;

    return _crashCount / duration.inHours;
  }

  /// Generate unique ID
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_crashCount}';
  }

  /// Log custom error
  void logError(String message, StackTrace stackTrace, {String? context, Map<String, dynamic>? metadata}) {
    final report = CrashReport(
      id: _generateId(),
      timestamp: DateTime.now(),
      message: message,
      stackTrace: stackTrace.toString(),
      context: context,
      metadata: metadata,
    );

    _recordCrash(report);
  }

  /// Log exception
  void logException(Object exception, StackTrace stackTrace, {String? context}) {
    logError(exception.toString(), stackTrace, context: context);
  }
}
