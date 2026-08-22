import 'package:flutter_test/flutter_test.dart';
import 'package:librio/services/crash_reporter.dart';

void main() {
  group('CrashReporter', () {
    late CrashReporter reporter;

    setUp(() {
      reporter = CrashReporter();
    });

    test('initializes successfully', () {
      expect(() => reporter.initialize(), returnsNormally);
    });

    test('logs custom error', () {
      reporter.initialize();
      final stackTrace = StackTrace.current;
      
      expect(
        () => reporter.logError('Test error', stackTrace),
        returnsNormally,
      );
    });

    test('logs exception', () {
      reporter.initialize();
      final stackTrace = StackTrace.current;
      
      expect(
        () => reporter.logException(Exception('Test exception'), stackTrace),
        returnsNormally,
      );
    });

    test('tracks crash count', () {
      reporter.initialize();
      final initialCount = reporter.getCrashCount();
      
      reporter.logError('Test error', StackTrace.current);
      final newCount = reporter.getCrashCount();
      
      expect(newCount, greaterThan(initialCount));
    });

    test('returns crash reports', () {
      reporter.initialize();
      reporter.logError('Test error', StackTrace.current);
      
      final reports = reporter.getCrashReports();
      expect(reports, isNotEmpty);
    });

    test('returns recent crashes', () {
      reporter.initialize();
      reporter.logError('Error 1', StackTrace.current);
      reporter.logError('Error 2', StackTrace.current);
      reporter.logError('Error 3', StackTrace.current);
      
      final recent = reporter.getRecentCrashes(limit: 2);
      expect(recent.length, lessThanOrEqualTo(2));
    });

    test('clears crash reports', () {
      reporter.initialize();
      reporter.logError('Test error', StackTrace.current);
      
      reporter.clearCrashReports();
      
      expect(reporter.getCrashCount(), 0);
      expect(reporter.getCrashReports().length, 0);
    });

    test('calculates crash rate', () {
      reporter.initialize();
      reporter.logError('Error 1', StackTrace.current);
      reporter.logError('Error 2', StackTrace.current);
      
      final rate = reporter.getCrashRate();
      expect(rate, isA<double>());
    });

    test('crash report contains required fields', () {
      reporter.initialize();
      reporter.logError('Test error', StackTrace.current, context: 'test_context');
      
      final reports = reporter.getCrashReports();
      expect(reports.isNotEmpty, true);
      
      final report = reports.first;
      expect(report.id, isNotEmpty);
      expect(report.message, isNotEmpty);
      expect(report.stackTrace, isNotEmpty);
      expect(report.timestamp, isNotNull);
    });

    test('crash report includes metadata', () {
      reporter.initialize();
      final metadata = {'key': 'value'};
      
      reporter.logError(
        'Test error',
        StackTrace.current,
        context: 'test',
        metadata: metadata,
      );
      
      final reports = reporter.getCrashReports();
      expect(reports.first.metadata, isNotNull);
    });
  });
}
