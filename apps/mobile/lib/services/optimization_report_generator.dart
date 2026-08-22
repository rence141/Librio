import 'package:flutter/foundation.dart';
import 'optimization_manager.dart';
import 'performance_benchmarker.dart';
import 'performance_monitor.dart';

/// Optimization report
class OptimizationReport {
  final DateTime timestamp;
  final String title;
  final Map<String, dynamic> metrics;
  final Map<String, dynamic> recommendations;
  final Map<String, dynamic> benchmarks;
  final String summary;

  OptimizationReport({
    required this.timestamp,
    required this.title,
    required this.metrics,
    required this.recommendations,
    required this.benchmarks,
    required this.summary,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'title': title,
    'metrics': metrics,
    'recommendations': recommendations,
    'benchmarks': benchmarks,
    'summary': summary,
  };

  @override
  String toString() => 'OptimizationReport(title: $title, timestamp: $timestamp)';
}

/// Optimization report generator
class OptimizationReportGenerator {
  static final OptimizationReportGenerator _instance = OptimizationReportGenerator._internal();

  factory OptimizationReportGenerator() {
    return _instance;
  }

  OptimizationReportGenerator._internal();

  late OptimizationManager _optimizationManager;
  late PerformanceBenchmarker _benchmarker;
  late PerformanceMonitor _monitor;

  /// Initialize report generator
  void initialize() {
    _optimizationManager = OptimizationManager();
    _benchmarker = PerformanceBenchmarker();
    _monitor = PerformanceMonitor();

    if (kDebugMode) {
      print('📋 Optimization report generator initialized');
    }
  }

  /// Generate optimization report
  Future<OptimizationReport> generateReport({
    required String title,
    required OptimizationMode mode,
  }) async {
    try {
      _optimizationManager.setOptimizationMode(mode);

      final metrics = _getMetrics();
      final recommendations = _getRecommendations(metrics);
      final benchmarks = _benchmarker.getAllReports();
      final summary = _generateSummary(metrics, recommendations);

      final report = OptimizationReport(
        timestamp: DateTime.now(),
        title: title,
        metrics: metrics,
        recommendations: recommendations,
        benchmarks: benchmarks,
        summary: summary,
      );

      if (kDebugMode) {
        print('📋 Report generated: $title');
      }

      return report;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Report generation failed: $e');
      }

      rethrow;
    }
  }

  /// Get metrics
  Map<String, dynamic> _getMetrics() {
    final status = _optimizationManager.getOptimizationStatus();
    final performance = _optimizationManager.getPerformanceReport();

    return {
      'optimization': status,
      'performance': performance,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get recommendations
  Map<String, dynamic> _getRecommendations(Map<String, dynamic> metrics) {
    final recommendations = <String, dynamic>{};

    // Battery recommendations
    if (metrics['performance']?['average']?['battery'] != null) {
      final batteryDrain = metrics['performance']['average']['battery'] as double;
      if (batteryDrain > 10) {
        recommendations['battery'] = [
          'Enable battery optimization mode',
          'Reduce background sync frequency',
          'Disable real-time updates',
          'Use aggressive mode on low battery',
        ];
      }
    }

    // Memory recommendations
    if (metrics['performance']?['peak']?['memory'] != null) {
      final peakMemory = metrics['performance']['peak']['memory'] as double;
      if (peakMemory > 1500) {
        recommendations['memory'] = [
          'Enable memory optimization mode',
          'Reduce cache size',
          'Clear image cache',
          'Optimize data structures',
        ];
      }
    }

    // Load time recommendations
    if (metrics['performance']?['average']?['latency'] != null) {
      final latency = metrics['performance']['average']['latency'] as int;
      if (latency > 2000) {
        recommendations['loadTime'] = [
          'Enable load time optimization',
          'Implement lazy loading',
          'Enable caching',
          'Optimize model loading',
        ];
      }
    }

    // Inference recommendations
    if (metrics['performance']?['average']?['latency'] != null) {
      final latency = metrics['performance']['average']['latency'] as int;
      if (latency > 3000) {
        recommendations['inference'] = [
          'Enable inference optimization',
          'Reduce max tokens',
          'Reduce batch size',
          'Enable token streaming',
        ];
      }
    }

    return recommendations;
  }

  /// Generate summary
  String _generateSummary(
    Map<String, dynamic> metrics,
    Map<String, dynamic> recommendations,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('=== Optimization Report Summary ===\n');

    // Performance summary
    buffer.writeln('Performance Metrics:');
    if (metrics['performance']?['average'] != null) {
      final avg = metrics['performance']['average'] as Map<String, dynamic>;
      buffer.writeln('  Average CPU: ${avg['cpu']?.toStringAsFixed(1)}%');
      buffer.writeln('  Average Memory: ${avg['memory']?.toStringAsFixed(1)}MB');
      buffer.writeln('  Average Battery: ${avg['battery']?.toStringAsFixed(2)}%/hr');
      buffer.writeln('  Average FPS: ${avg['fps']}');
      buffer.writeln('  Average Latency: ${avg['latency']}ms');
    }

    buffer.writeln('\nOptimization Status:');
    if (metrics['optimization'] != null) {
      final opt = metrics['optimization'] as Map<String, dynamic>;
      buffer.writeln('  Mode: ${opt['mode']}');
      buffer.writeln('  Battery Optimized: ${opt['battery']}');
      buffer.writeln('  Memory Optimized: ${opt['memory']}');
      buffer.writeln('  Load Time Optimized: ${opt['loadTime']}');
      buffer.writeln('  Inference Optimized: ${opt['inference']}');
    }

    buffer.writeln('\nRecommendations:');
    if (recommendations.isEmpty) {
      buffer.writeln('  No recommendations at this time.');
    } else {
      recommendations.forEach((key, value) {
        buffer.writeln('  $key:');
        for (final rec in value as List) {
          buffer.writeln('    - $rec');
        }
      });
    }

    buffer.writeln('\n=== End of Report ===');

    return buffer.toString();
  }

  /// Export report as JSON
  String exportReportAsJson(OptimizationReport report) {
    return report.toJson().toString();
  }

  /// Export report as text
  String exportReportAsText(OptimizationReport report) {
    final buffer = StringBuffer();

    buffer.writeln('=== ${report.title} ===');
    buffer.writeln('Generated: ${report.timestamp}');
    buffer.writeln();
    buffer.writeln(report.summary);

    return buffer.toString();
  }
}
