import 'dart:async';
import 'package:flutter/foundation.dart';

/// Performance metrics for monitoring
class PerformanceMetrics {
  final DateTime timestamp;
  final double cpuUsage; // 0-100%
  final double memoryUsageMb;
  final double batteryDrainPercentPerHour;
  final int frameRate; // FPS
  final Duration latency;

  PerformanceMetrics({
    required this.timestamp,
    required this.cpuUsage,
    required this.memoryUsageMb,
    required this.batteryDrainPercentPerHour,
    required this.frameRate,
    required this.latency,
  });

  @override
  String toString() {
    return '''PerformanceMetrics(
      timestamp: $timestamp,
      cpu: ${cpuUsage.toStringAsFixed(1)}%,
      memory: ${memoryUsageMb.toStringAsFixed(1)}MB,
      battery: ${batteryDrainPercentPerHour.toStringAsFixed(2)}%/hr,
      fps: $frameRate,
      latency: ${latency.inMilliseconds}ms
    )''';
  }
}

/// Performance monitoring service
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();

  factory PerformanceMonitor() {
    return _instance;
  }

  PerformanceMonitor._internal();

  final List<PerformanceMetrics> _metrics = [];
  final Map<String, Stopwatch> _timers = {};
  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  /// Start monitoring performance
  void startMonitoring({Duration interval = const Duration(seconds: 5)}) {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(interval, (_) {
      _collectMetrics();
    });

    if (kDebugMode) {
      print('🔍 Performance monitoring started');
    }
  }

  /// Stop monitoring performance
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;

    if (kDebugMode) {
      print('🔍 Performance monitoring stopped');
    }
  }

  /// Collect performance metrics
  void _collectMetrics() {
    final metrics = PerformanceMetrics(
      timestamp: DateTime.now(),
      cpuUsage: _estimateCpuUsage(),
      memoryUsageMb: _estimateMemoryUsage(),
      batteryDrainPercentPerHour: _estimateBatteryDrain(),
      frameRate: _estimateFrameRate(),
      latency: _estimateLatency(),
    );

    _metrics.add(metrics);

    // Keep only last 100 metrics
    if (_metrics.length > 100) {
      _metrics.removeAt(0);
    }

    if (kDebugMode) {
      print('📊 $metrics');
    }
  }

  /// Start timing an operation
  void startTimer(String label) {
    _timers[label] = Stopwatch()..start();
  }

  /// Stop timing an operation and return duration
  Duration stopTimer(String label) {
    final stopwatch = _timers.remove(label);
    if (stopwatch == null) {
      if (kDebugMode) {
        print('⚠️ Timer "$label" not found');
      }
      return Duration.zero;
    }

    stopwatch.stop();
    final duration = stopwatch.elapsed;

    if (kDebugMode) {
      print('⏱️ $label: ${duration.inMilliseconds}ms');
    }

    return duration;
  }

  /// Get average metrics
  PerformanceMetrics? getAverageMetrics() {
    if (_metrics.isEmpty) return null;

    final avgCpu = _metrics.map((m) => m.cpuUsage).reduce((a, b) => a + b) / _metrics.length;
    final avgMemory = _metrics.map((m) => m.memoryUsageMb).reduce((a, b) => a + b) / _metrics.length;
    final avgBattery = _metrics.map((m) => m.batteryDrainPercentPerHour).reduce((a, b) => a + b) / _metrics.length;
    final avgFps = (_metrics.map((m) => m.frameRate).reduce((a, b) => a + b) / _metrics.length).toInt();
    final avgLatency = Duration(
      milliseconds: (_metrics.map((m) => m.latency.inMilliseconds).reduce((a, b) => a + b) / _metrics.length).toInt(),
    );

    return PerformanceMetrics(
      timestamp: DateTime.now(),
      cpuUsage: avgCpu,
      memoryUsageMb: avgMemory,
      batteryDrainPercentPerHour: avgBattery,
      frameRate: avgFps,
      latency: avgLatency,
    );
  }

  /// Get peak metrics
  PerformanceMetrics? getPeakMetrics() {
    if (_metrics.isEmpty) return null;

    var peakMetric = _metrics.first;
    for (final metric in _metrics) {
      if (metric.memoryUsageMb > peakMetric.memoryUsageMb) {
        peakMetric = metric;
      }
    }

    return peakMetric;
  }

  /// Get all metrics
  List<PerformanceMetrics> getAllMetrics() => List.unmodifiable(_metrics);

  /// Clear metrics
  void clearMetrics() {
    _metrics.clear();
  }

  /// Estimate CPU usage (placeholder)
  double _estimateCpuUsage() {
    // In production, use platform channels to get actual CPU usage
    return 25.0 + (DateTime.now().millisecond % 20).toDouble();
  }

  /// Estimate memory usage (placeholder)
  double _estimateMemoryUsage() {
    // In production, use platform channels to get actual memory usage
    return 400.0 + (DateTime.now().millisecond % 100).toDouble();
  }

  /// Estimate battery drain (placeholder)
  double _estimateBatteryDrain() {
    // In production, use platform channels to get actual battery drain
    return 5.0 + (DateTime.now().millisecond % 5).toDouble();
  }

  /// Estimate frame rate (placeholder)
  int _estimateFrameRate() {
    // In production, use platform channels to get actual frame rate
    return 55 + (DateTime.now().millisecond % 5);
  }

  /// Estimate latency (placeholder)
  Duration _estimateLatency() {
    // In production, measure actual API latency
    return Duration(milliseconds: 50 + (DateTime.now().millisecond % 50));
  }
}
