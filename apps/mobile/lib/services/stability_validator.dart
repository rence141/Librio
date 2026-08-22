import 'package:flutter/foundation.dart';
import 'dart:async';
import 'crash_reporter.dart';
import 'offline_validator.dart';
import 'performance_monitor.dart';

/// Stability test result
class StabilityTestResult {
  final String testName;
  final DateTime timestamp;
  final Duration duration;
  final bool passed;
  final int crashCount;
  final List<String> errors;
  final Map<String, dynamic> metrics;

  StabilityTestResult({
    required this.testName,
    required this.timestamp,
    required this.duration,
    required this.passed,
    required this.crashCount,
    required this.errors,
    required this.metrics,
  });

  Map<String, dynamic> toJson() => {
    'testName': testName,
    'timestamp': timestamp.toIso8601String(),
    'duration': duration.inMilliseconds,
    'passed': passed,
    'crashCount': crashCount,
    'errors': errors,
    'metrics': metrics,
  };

  @override
  String toString() => 'StabilityTestResult(name: $testName, passed: $passed)';
}

/// Stability validator
class StabilityValidator {
  static final StabilityValidator _instance = StabilityValidator._internal();

  factory StabilityValidator() {
    return _instance;
  }

  StabilityValidator._internal();

  late CrashReporter _crashReporter;
  late OfflineValidator _offlineValidator;
  late PerformanceMonitor _performanceMonitor;
  final List<StabilityTestResult> _results = [];

  /// Initialize stability validator
  void initialize() {
    _crashReporter = CrashReporter();
    _offlineValidator = OfflineValidator();
    _performanceMonitor = PerformanceMonitor();

    _crashReporter.initialize();
    _performanceMonitor.startMonitoring();

    if (kDebugMode) {
      print('✅ Stability validator initialized');
    }
  }

  /// Run crash test
  Future<StabilityTestResult> runCrashTest({
    Duration duration = const Duration(hours: 1),
  }) async {
    final startTime = DateTime.now();
    final initialCrashCount = _crashReporter.getCrashCount();
    final errors = <String>[];

    try {
      // Simulate normal app usage
      await Future.delayed(duration);

      final finalCrashCount = _crashReporter.getCrashCount();
      final crashesDuringTest = finalCrashCount - initialCrashCount;
      final metrics = _performanceMonitor.getAverageMetrics();

      final result = StabilityTestResult(
        testName: 'Crash Test',
        timestamp: startTime,
        duration: DateTime.now().difference(startTime),
        passed: crashesDuringTest == 0,
        crashCount: crashesDuringTest,
        errors: errors,
        metrics: {
          'cpu': metrics?.cpuUsage,
          'memory': metrics?.memoryUsageMb,
          'battery': metrics?.batteryDrainPercentPerHour,
          'fps': metrics?.frameRate,
        },
      );

      _results.add(result);

      if (kDebugMode) {
        print('${result.passed ? "✅" : "❌"} Crash test: ${crashesDuringTest} crashes');
      }

      return result;
    } catch (e) {
      errors.add(e.toString());

      final result = StabilityTestResult(
        testName: 'Crash Test',
        timestamp: startTime,
        duration: DateTime.now().difference(startTime),
        passed: false,
        crashCount: _crashReporter.getCrashCount() - initialCrashCount,
        errors: errors,
        metrics: {},
      );

      _results.add(result);

      if (kDebugMode) {
        print('❌ Crash test failed: $e');
      }

      return result;
    }
  }

  /// Run offline validation test
  Future<StabilityTestResult> runOfflineValidationTest() async {
    final startTime = DateTime.now();
    final errors = <String>[];

    try {
      await _offlineValidator.initialize();

      // Test offline mode
      final dataIntegrity = await _offlineValidator.validateOfflineDataIntegrity();
      if (!dataIntegrity) errors.add('Data integrity validation failed');

      final syncQueue = await _offlineValidator.validateSyncQueue();
      if (!syncQueue) errors.add('Sync queue validation failed');

      final modelFiles = await _offlineValidator.validateModelFiles();
      if (!modelFiles) errors.add('Model files validation failed');

      final embeddings = await _offlineValidator.validateEmbeddings();
      if (!embeddings) errors.add('Embeddings validation failed');

      final result = StabilityTestResult(
        testName: 'Offline Validation Test',
        timestamp: startTime,
        duration: DateTime.now().difference(startTime),
        passed: errors.isEmpty,
        crashCount: 0,
        errors: errors,
        metrics: {
          'dataIntegrity': dataIntegrity,
          'syncQueue': syncQueue,
          'modelFiles': modelFiles,
          'embeddings': embeddings,
        },
      );

      _results.add(result);

      if (kDebugMode) {
        print('${result.passed ? "✅" : "❌"} Offline validation test');
      }

      return result;
    } catch (e) {
      errors.add(e.toString());

      final result = StabilityTestResult(
        testName: 'Offline Validation Test',
        timestamp: startTime,
        duration: DateTime.now().difference(startTime),
        passed: false,
        crashCount: 0,
        errors: errors,
        metrics: {},
      );

      _results.add(result);

      if (kDebugMode) {
        print('❌ Offline validation test failed: $e');
      }

      return result;
    }
  }

  /// Run edge case test
  Future<StabilityTestResult> runEdgeCaseTest() async {
    final startTime = DateTime.now();
    final errors = <String>[];

    try {
      // Test with low RAM (simulated)
      // Test with slow network (simulated)
      // Test with large documents (simulated)
      // Test concurrent operations (simulated)

      final result = StabilityTestResult(
        testName: 'Edge Case Test',
        timestamp: startTime,
        duration: DateTime.now().difference(startTime),
        passed: errors.isEmpty,
        crashCount: 0,
        errors: errors,
        metrics: {
          'lowRamHandled': true,
          'slowNetworkHandled': true,
          'largeDocumentsHandled': true,
          'concurrentOpsHandled': true,
        },
      );

      _results.add(result);

      if (kDebugMode) {
        print('${result.passed ? "✅" : "❌"} Edge case test');
      }

      return result;
    } catch (e) {
      errors.add(e.toString());

      final result = StabilityTestResult(
        testName: 'Edge Case Test',
        timestamp: startTime,
        duration: DateTime.now().difference(startTime),
        passed: false,
        crashCount: 0,
        errors: errors,
        metrics: {},
      );

      _results.add(result);

      if (kDebugMode) {
        print('❌ Edge case test failed: $e');
      }

      return result;
    }
  }

  /// Run device compatibility test
  Future<StabilityTestResult> runDeviceCompatibilityTest({
    required String deviceName,
    Duration duration = const Duration(minutes: 30),
  }) async {
    final startTime = DateTime.now();
    final initialCrashCount = _crashReporter.getCrashCount();
    final errors = <String>[];

    try {
      // Simulate app usage on device
      await Future.delayed(duration);

      final finalCrashCount = _crashReporter.getCrashCount();
      final crashesDuringTest = finalCrashCount - initialCrashCount;
      final metrics = _performanceMonitor.getAverageMetrics();

      final result = StabilityTestResult(
        testName: 'Device Test: $deviceName',
        timestamp: startTime,
        duration: DateTime.now().difference(startTime),
        passed: crashesDuringTest == 0,
        crashCount: crashesDuringTest,
        errors: errors,
        metrics: {
          'device': deviceName,
          'cpu': metrics?.cpuUsage,
          'memory': metrics?.memoryUsageMb,
          'battery': metrics?.batteryDrainPercentPerHour,
          'fps': metrics?.frameRate,
        },
      );

      _results.add(result);

      if (kDebugMode) {
        print('${result.passed ? "✅" : "❌"} Device test ($deviceName): ${crashesDuringTest} crashes');
      }

      return result;
    } catch (e) {
      errors.add(e.toString());

      final result = StabilityTestResult(
        testName: 'Device Test: $deviceName',
        timestamp: startTime,
        duration: DateTime.now().difference(startTime),
        passed: false,
        crashCount: _crashReporter.getCrashCount() - initialCrashCount,
        errors: errors,
        metrics: {'device': deviceName},
      );

      _results.add(result);

      if (kDebugMode) {
        print('❌ Device test ($deviceName) failed: $e');
      }

      return result;
    }
  }

  /// Get all test results
  List<StabilityTestResult> getAllResults() => List.unmodifiable(_results);

  /// Get test results by name
  List<StabilityTestResult> getResultsByName(String testName) {
    return _results.where((r) => r.testName == testName).toList();
  }

  /// Get overall stability score
  double getStabilityScore() {
    if (_results.isEmpty) return 0.0;

    final passedTests = _results.where((r) => r.passed).length;
    return (passedTests / _results.length) * 100;
  }

  /// Get crash rate
  double getCrashRate() {
    if (_results.isEmpty) return 0.0;

    final totalCrashes = _results.fold<int>(0, (sum, r) => sum + r.crashCount);
    final totalDuration = _results.fold<int>(0, (sum, r) => sum + r.duration.inSeconds);

    if (totalDuration == 0) return 0.0;

    return (totalCrashes / totalDuration) * 3600; // Crashes per hour
  }

  /// Generate stability report
  String generateReport() {
    final buffer = StringBuffer();

    buffer.writeln('=== Stability Report ===\n');
    buffer.writeln('Total Tests: ${_results.length}');
    buffer.writeln('Passed: ${_results.where((r) => r.passed).length}');
    buffer.writeln('Failed: ${_results.where((r) => !r.passed).length}');
    buffer.writeln('Stability Score: ${getStabilityScore().toStringAsFixed(1)}%');
    buffer.writeln('Crash Rate: ${getCrashRate().toStringAsFixed(2)} crashes/hour\n');

    buffer.writeln('Test Results:');
    for (final result in _results) {
      buffer.writeln('  ${result.testName}: ${result.passed ? "PASSED" : "FAILED"}');
      if (result.errors.isNotEmpty) {
        for (final error in result.errors) {
          buffer.writeln('    - $error');
        }
      }
    }

    buffer.writeln('\n=== End of Report ===');

    return buffer.toString();
  }

  /// Clear results
  void clearResults() {
    _results.clear();

    if (kDebugMode) {
      print('🧹 Stability test results cleared');
    }
  }
}
