import 'package:flutter/foundation.dart';
import 'battery_optimizer.dart';
import 'memory_optimizer.dart';
import 'load_time_optimizer.dart';
import 'inference_optimizer.dart';
import 'performance_monitor.dart';

/// Optimization mode
enum OptimizationMode {
  normal,
  balanced,
  aggressive,
}

/// Optimization manager
class OptimizationManager {
  static final OptimizationManager _instance = OptimizationManager._internal();

  factory OptimizationManager() {
    return _instance;
  }

  OptimizationManager._internal();

  late BatteryOptimizer _batteryOptimizer;
  late MemoryOptimizer _memoryOptimizer;
  late LoadTimeOptimizer _loadTimeOptimizer;
  late InferenceOptimizer _inferenceOptimizer;
  late PerformanceMonitor _performanceMonitor;

  OptimizationMode _currentMode = OptimizationMode.normal;
  bool _isInitialized = false;

  /// Initialize optimization manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    _batteryOptimizer = BatteryOptimizer();
    _memoryOptimizer = MemoryOptimizer();
    _loadTimeOptimizer = LoadTimeOptimizer();
    _inferenceOptimizer = InferenceOptimizer();
    _performanceMonitor = PerformanceMonitor();

    _batteryOptimizer.initialize();
    _memoryOptimizer.initialize();
    _loadTimeOptimizer.initialize();
    _inferenceOptimizer.initialize();
    _performanceMonitor.startMonitoring();

    _isInitialized = true;

    if (kDebugMode) {
      print('⚙️ Optimization manager initialized');
    }
  }

  /// Set optimization mode
  void setOptimizationMode(OptimizationMode mode) {
    _currentMode = mode;

    switch (mode) {
      case OptimizationMode.normal:
        _disableAllOptimizations();
        break;
      case OptimizationMode.balanced:
        _enableBalancedOptimization();
        break;
      case OptimizationMode.aggressive:
        _enableAggressiveOptimization();
        break;
    }

    if (kDebugMode) {
      print('⚙️ Optimization mode set to ${mode.name}');
    }
  }

  /// Disable all optimizations
  void _disableAllOptimizations() {
    _batteryOptimizer.disableOptimization();
    _memoryOptimizer.disableOptimization();
    _loadTimeOptimizer.disableOptimization();
    _inferenceOptimizer.disableOptimization();

    if (kDebugMode) {
      print('  ✓ All optimizations disabled');
    }
  }

  /// Enable balanced optimization
  void _enableBalancedOptimization() {
    _batteryOptimizer.enableOptimization();
    _memoryOptimizer.enableOptimization();
    _loadTimeOptimizer.disableOptimization();
    _inferenceOptimizer.disableOptimization();

    if (kDebugMode) {
      print('  ✓ Balanced optimization enabled');
    }
  }

  /// Enable aggressive optimization
  void _enableAggressiveOptimization() {
    _batteryOptimizer.enableOptimization();
    _memoryOptimizer.enableOptimization();
    _loadTimeOptimizer.enableOptimization();
    _inferenceOptimizer.enableOptimization();

    if (kDebugMode) {
      print('  ✓ Aggressive optimization enabled');
    }
  }

  /// Get current optimization mode
  OptimizationMode get currentMode => _currentMode;

  /// Get optimization status
  Map<String, dynamic> getOptimizationStatus() {
    return {
      'mode': _currentMode.name,
      'battery': _batteryOptimizer.isOptimizationEnabled,
      'memory': _memoryOptimizer.isOptimizationEnabled,
      'loadTime': _loadTimeOptimizer.isOptimizationEnabled,
      'inference': _inferenceOptimizer.isOptimizationEnabled,
      'batterySavings': _batteryOptimizer.estimateBatterySavings(),
      'memorySavings': _memoryOptimizer.estimateMemorySavings(),
      'loadTimeSavings': _loadTimeOptimizer.estimateLoadTimeSavings(),
      'inferenceSpeedImprovement': _inferenceOptimizer.estimateSpeedImprovement(),
    };
  }

  /// Get performance report
  Map<String, dynamic> getPerformanceReport() {
    final avgMetrics = _performanceMonitor.getAverageMetrics();
    final peakMetrics = _performanceMonitor.getPeakMetrics();

    return {
      'average': {
        'cpu': avgMetrics?.cpuUsage,
        'memory': avgMetrics?.memoryUsageMb,
        'battery': avgMetrics?.batteryDrainPercentPerHour,
        'fps': avgMetrics?.frameRate,
        'latency': avgMetrics?.latency.inMilliseconds,
      },
      'peak': {
        'cpu': peakMetrics?.cpuUsage,
        'memory': peakMetrics?.memoryUsageMb,
        'battery': peakMetrics?.batteryDrainPercentPerHour,
        'fps': peakMetrics?.frameRate,
        'latency': peakMetrics?.latency.inMilliseconds,
      },
      'optimization': getOptimizationStatus(),
    };
  }

  /// Get battery optimizer
  BatteryOptimizer get batteryOptimizer => _batteryOptimizer;

  /// Get memory optimizer
  MemoryOptimizer get memoryOptimizer => _memoryOptimizer;

  /// Get load time optimizer
  LoadTimeOptimizer get loadTimeOptimizer => _loadTimeOptimizer;

  /// Get inference optimizer
  InferenceOptimizer get inferenceOptimizer => _inferenceOptimizer;

  /// Get performance monitor
  PerformanceMonitor get performanceMonitor => _performanceMonitor;

  /// Cleanup
  void dispose() {
    _performanceMonitor.stopMonitoring();
    _disableAllOptimizations();

    if (kDebugMode) {
      print('⚙️ Optimization manager disposed');
    }
  }
}
