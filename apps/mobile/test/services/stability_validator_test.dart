import 'package:flutter_test/flutter_test.dart';
import 'package:librio/services/stability_validator.dart';

void main() {
  group('StabilityValidator', () {
    late StabilityValidator validator;

    setUp(() {
      validator = StabilityValidator();
    });

    test('initializes successfully', () {
      expect(() => validator.initialize(), returnsNormally);
    });

    test('runs crash test', () async {
      validator.initialize();
      final result = await validator.runCrashTest(
        duration: Duration(milliseconds: 100),
      );

      expect(result.testName, 'Crash Test');
      expect(result.crashCount, isA<int>());
      expect(result.metrics, isNotEmpty);
    });

    test('runs offline validation test', () async {
      validator.initialize();
      final result = await validator.runOfflineValidationTest();

      expect(result.testName, 'Offline Validation Test');
      expect(result.metrics, isNotEmpty);
    });

    test('runs edge case test', () async {
      validator.initialize();
      final result = await validator.runEdgeCaseTest();

      expect(result.testName, 'Edge Case Test');
      expect(result.metrics, isNotEmpty);
    });

    test('runs device compatibility test', () async {
      validator.initialize();
      final result = await validator.runDeviceCompatibilityTest(
        deviceName: 'Test Device',
        duration: Duration(milliseconds: 100),
      );

      expect(result.testName, contains('Test Device'));
      expect(result.metrics['device'], 'Test Device');
    });

    test('returns all results', () async {
      validator.initialize();
      await validator.runCrashTest(duration: Duration(milliseconds: 100));

      final results = validator.getAllResults();
      expect(results, isNotEmpty);
    });

    test('returns results by name', () async {
      validator.initialize();
      await validator.runCrashTest(duration: Duration(milliseconds: 100));

      final results = validator.getResultsByName('Crash Test');
      expect(results, isNotEmpty);
    });

    test('calculates stability score', () async {
      validator.initialize();
      await validator.runCrashTest(duration: Duration(milliseconds: 100));

      final score = validator.getStabilityScore();
      expect(score, greaterThanOrEqualTo(0));
      expect(score, lessThanOrEqualTo(100));
    });

    test('calculates crash rate', () async {
      validator.initialize();
      await validator.runCrashTest(duration: Duration(milliseconds: 100));

      final rate = validator.getCrashRate();
      expect(rate, isA<double>());
    });

    test('generates report', () async {
      validator.initialize();
      await validator.runCrashTest(duration: Duration(milliseconds: 100));

      final report = validator.generateReport();
      expect(report, isNotEmpty);
      expect(report, contains('Stability Report'));
    });

    test('clears results', () async {
      validator.initialize();
      await validator.runCrashTest(duration: Duration(milliseconds: 100));

      validator.clearResults();

      final results = validator.getAllResults();
      expect(results.length, 0);
    });

    test('test result contains required fields', () async {
      validator.initialize();
      final result = await validator.runCrashTest(
        duration: Duration(milliseconds: 100),
      );

      expect(result.testName, isNotEmpty);
      expect(result.timestamp, isNotNull);
      expect(result.duration, isNotNull);
      expect(result.passed, isA<bool>());
      expect(result.crashCount, isA<int>());
      expect(result.errors, isA<List>());
      expect(result.metrics, isA<Map>());
    });

    test('test result converts to JSON', () async {
      validator.initialize();
      final result = await validator.runCrashTest(
        duration: Duration(milliseconds: 100),
      );

      final json = result.toJson();
      expect(json, isNotEmpty);
      expect(json['testName'], isNotEmpty);
      expect(json['passed'], isA<bool>());
    });
  });
}
