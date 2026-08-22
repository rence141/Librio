import 'package:flutter/foundation.dart';
import 'dart:async';
import 'performance_monitor.dart';

/// Benchmark result
class BenchmarkResult {
  final String name;
  final DateTime timestamp;
  final Duration duration;
  final double cpuUsage;
  final double memoryUsageMb;
  final double batteryDrain;
  final int frameRate;
  final bool success;
  final String? error;

  BenchmarkResult({
    required this.name,
    required this.timestamp,
    required this.duration,
    required this.cpuUsage,
    required this.memoryUsageMb,
    required this.batteryDrain,
    required this.frameRate,
    required this.success,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'timestamp': timestamp.toIso8601String(),
    'duration': duration.inMilliseconds,
    'cpuUsage': cpuUsage,
    'memoryUsageMb': memoryUsageMb,
    'batteryDrain': batteryDrain,
    'frameRate': frameRate,
    'success': success,
    'error': error,
  };

  @override
  String toString() => 'BenchmarkResult(name: $name, duration: ${duration.inMilliseconds}ms)';
}

/// Performance benchmarker
class PerformanceBenchmarker {
  static final PerformanceBenchmarker _instance = PerformanceBenchmarker._internal();

  factory PerformanceBenchmarker() {
    return _instance;
  }

  PerformanceBenchmarker._internal();

  final List<BenchmarkResult> _results = [];
  late PerformanceMonitor _monitor;

  /// Initialize benchmarker
  void initialize() {
    _monitor = PerformanceMonitor();
    _monitor.startMonitoring();

    if (kDebugMode) {
      print('📊 Performance benchmarker initialized');
    }
  }

  /// Run benchmark
  Future<BenchmarkResult> runBenchmark(
    String name,
    Future<void> Function() operation, {
    int iterations = 1,
  }) async {
    try {
      _monitor.startTimer(name);

      for (int i = 0; i < iterations; i++) {
        await operation();
      }

      final duration = _monitor.stopTimer(name);
      final metrics = _monitor.getAverageMetrics();

      final result = BenchmarkResult(
        name: name,
        timestamp: DateTime.now(),
        duration: duration,
        cpuUsage: metrics?.cpuUsage ?? 0.0,
        memoryUsageMb: metrics?.memoryUsageMb ?? 0.0,
        batteryDrain: metrics?.batteryDrainPercentPerHour ?? 0.0,
        frameRate: metrics?.frameRate ?? 0,
        success: true,
      );

      _results.add(result);

      if (kDebugMode) {
        print('✅ Benchmark "$name" completed: ${result.duration.inMilliseconds}ms');
      }

      return result;
    } catch (e) {
      final result = BenchmarkResult(
        name: name,
        timestamp: DateTime.now(),
        duration: Duration.zero,
        cpuUsage: 0.0,
        memoryUsageMb: 0.0,
        batteryDrain: 0.0,
        frameRate: 0,
        success: false,
        error: e.toString(),
      );

      _results.add(result);

      if (kDebugMode) {
        print('❌ Benchmark "$name" failed: $e');
      }

      return result;
    }
  }

  /// Get all results
  List<BenchmarkResult> getAllResults() => List.unmodifiable(_results);

  /// Get results by name
  List<BenchmarkResult> getResultsByName(String name) {
    return _results.where((r) => r.name == name).toList();
  }

  /// Get average duration
  Duration getAverageDuration(String name) {
    final results = getResultsByName(name);
    if (results.isEmpty) return Duration.zero;

    final totalMs = results.fold<int>(
      0,
      (sum, result) => sum + result.duration.inMilliseconds,
    );

    return Duration(milliseconds: totalMs ~/ results.length);
  }

  /// Get fastest duration
  Duration? getFastestDuration(String name) {
    final results = getResultsByName(name);
    if (results.isEmpty) return null;

    return results.reduce((a, b) => a.duration.compareTo(b.duration) < 0 ? a : b).duration;
  }

  /// Get slowest duration
  Duration? getSlowestDuration(String name) {
    final results = getResultsByName(name);
    if (results.isEmpty) return null;

    return results.reduce((a, b) => a.duration.compareTo(b.duration) > 0 ? a : b).duration;
  }

  /// Get success rate
  double getSuccessRate(String name) {
    final results = getResultsByName(name);
    if (results.isEmpty) return 0.0;

    final successful = results.where((r) => r.success).length;
    return (successful / results.length) * 100;
  }

  /// Get benchmark report
  Map<String, dynamic> getBenchmarkReport(String name) {
    final results = getResultsByName(name);
    if (results.isEmpty) {
      return {'name': name, 'results': 0};
    }

    return {
      'name': name,
      'results': results.length,
      'averageDuration': getAverageDuration(name).inMilliseconds,
      'fastestDuration': getFastestDuration(name)?.inMilliseconds,
      'slowestDuration': getSlowestDuration(name)?.inMilliseconds,
      'successRate': getSuccessRate(name),
      'averageCpu': results.fold<double>(0, (sum, r) => sum + r.cpuUsage) / results.length,
      'averageMemory': results.fold<double>(0, (sum, r) => sum + r.memoryUsageMb) / results.length,
      'averageBattery': results.fold<double>(0, (sum, r) => sum + r.batteryDrain) / results.length,
    };
  }

  /// Get all reports
  Map<String, dynamic> getAllReports() {
    final names = _results.map((r) => r.name).toSet();
    final reports = <String, dynamic>{};

    for (final name in names) {
      reports[name] = getBenchmarkReport(name);
    }

    return reports;
  }

  /// Clear results
  void clearResults() {
    _results.clear();

    if (kDebugMode) {
      print('🧹 Benchmark results cleared');
    }
  }

  /// Export results as JSON
  List<Map<String, dynamic>> exportAsJson() {
    return _results.map((r) => r.toJson()).toList();
  }
}
