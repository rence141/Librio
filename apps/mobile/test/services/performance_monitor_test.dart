import 'package:flutter_test/flutter_test.dart';
import 'package:librio/services/performance_monitor.dart';

void main() {
  group('PerformanceMonitor', () {
    late PerformanceMonitor monitor;

    setUp(() {
      monitor = PerformanceMonitor();
    });

    test('starts monitoring', () {
      monitor.startMonitoring();
      expect(monitor, isNotNull);
    });

    test('stops monitoring', () {
      monitor.startMonitoring();
      monitor.stopMonitoring();
      expect(monitor, isNotNull);
    });

    test('records timer', () {
      monitor.startTimer('test_operation');
      Future.delayed(Duration(milliseconds: 10)).then((_) {
        final duration = monitor.stopTimer('test_operation');
        expect(duration.inMilliseconds, greaterThanOrEqualTo(10));
      });
    });

    test('returns zero duration for non-existent timer', () {
      final duration = monitor.stopTimer('non_existent');
      expect(duration, Duration.zero);
    });

    test('collects metrics', () {
      monitor.startMonitoring(interval: Duration(milliseconds: 100));
      
      Future.delayed(Duration(milliseconds: 200)).then((_) {
        final metrics = monitor.getAllMetrics();
        expect(metrics.length, greaterThan(0));
      });
    });

    test('calculates average metrics', () {
      monitor.startMonitoring(interval: Duration(milliseconds: 100));
      
      Future.delayed(Duration(milliseconds: 300)).then((_) {
        final avgMetrics = monitor.getAverageMetrics();
        expect(avgMetrics, isNotNull);
        expect(avgMetrics!.cpuUsage, greaterThan(0));
        expect(avgMetrics.memoryUsageMb, greaterThan(0));
      });
    });

    test('calculates peak metrics', () {
      monitor.startMonitoring(interval: Duration(milliseconds: 100));
      
      Future.delayed(Duration(milliseconds: 300)).then((_) {
        final peakMetrics = monitor.getPeakMetrics();
        expect(peakMetrics, isNotNull);
        expect(peakMetrics!.memoryUsageMb, greaterThan(0));
      });
    });

    test('clears metrics', () {
      monitor.startMonitoring(interval: Duration(milliseconds: 100));
      
      Future.delayed(Duration(milliseconds: 200)).then((_) {
        monitor.clearMetrics();
        final metrics = monitor.getAllMetrics();
        expect(metrics.length, 0);
      });
    });

    test('returns all metrics', () {
      monitor.startMonitoring(interval: Duration(milliseconds: 100));
      
      Future.delayed(Duration(milliseconds: 200)).then((_) {
        final metrics = monitor.getAllMetrics();
        expect(metrics, isNotEmpty);
        expect(metrics.first.cpuUsage, greaterThanOrEqualTo(0));
        expect(metrics.first.memoryUsageMb, greaterThanOrEqualTo(0));
        expect(metrics.first.frameRate, greaterThan(0));
      });
    });

    test('stops monitoring', () {
      monitor.startMonitoring();
      monitor.stopMonitoring();
      expect(monitor, isNotNull);
    });
  });
}
