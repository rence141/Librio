import 'package:flutter_test/flutter_test.dart';
import 'package:librio/services/optimization_manager.dart';

void main() {
  group('OptimizationManager', () => {
    late OptimizationManager manager;

    setUp(() {
      manager = OptimizationManager();
    });

    test('initializes successfully', () async {
      await manager.initialize();
      expect(manager.currentMode, OptimizationMode.normal);
    });

    test('switches to balanced mode', () async {
      await manager.initialize();
      manager.setOptimizationMode(OptimizationMode.balanced);
      expect(manager.currentMode, OptimizationMode.balanced);
    });

    test('switches to aggressive mode', () async {
      await manager.initialize();
      manager.setOptimizationMode(OptimizationMode.aggressive);
      expect(manager.currentMode, OptimizationMode.aggressive);
    });

    test('returns optimization status', () async {
      await manager.initialize();
      manager.setOptimizationMode(OptimizationMode.balanced);
      
      final status = manager.getOptimizationStatus();
      
      expect(status['mode'], 'balanced');
      expect(status['battery'], true);
      expect(status['memory'], true);
      expect(status['loadTime'], false);
      expect(status['inference'], false);
    });

    test('returns performance report', () async {
      await manager.initialize();
      manager.setOptimizationMode(OptimizationMode.balanced);
      
      final report = manager.getPerformanceReport();
      
      expect(report.containsKey('average'), true);
      expect(report.containsKey('peak'), true);
      expect(report.containsKey('optimization'), true);
    });

    test('estimates battery savings in balanced mode', () async {
      await manager.initialize();
      manager.setOptimizationMode(OptimizationMode.balanced);
      
      final status = manager.getOptimizationStatus();
      expect(status['batterySavings'], greaterThan(0));
    });

    test('estimates memory savings in balanced mode', () async {
      await manager.initialize();
      manager.setOptimizationMode(OptimizationMode.balanced);
      
      final status = manager.getOptimizationStatus();
      expect(status['memorySavings'], greaterThan(0));
    });

    test('estimates all savings in aggressive mode', () async {
      await manager.initialize();
      manager.setOptimizationMode(OptimizationMode.aggressive);
      
      final status = manager.getOptimizationStatus();
      expect(status['batterySavings'], greaterThan(0));
      expect(status['memorySavings'], greaterThan(0));
      expect(status['loadTimeSavings'], greaterThan(0));
      expect(status['inferenceSpeedImprovement'], greaterThan(0));
    });

    test('disables all optimizations in normal mode', () async {
      await manager.initialize();
      manager.setOptimizationMode(OptimizationMode.aggressive);
      manager.setOptimizationMode(OptimizationMode.normal);
      
      final status = manager.getOptimizationStatus();
      expect(status['battery'], false);
      expect(status['memory'], false);
      expect(status['loadTime'], false);
      expect(status['inference'], false);
    });

    test('disposes successfully', () async {
      await manager.initialize();
      expect(() => manager.dispose(), returnsNormally);
    });
  });
}
