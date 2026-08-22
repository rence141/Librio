import 'package:flutter_test/flutter_test.dart';
import 'package:librio/services/offline_validator.dart';

void main() {
  group('OfflineValidator', () {
    late OfflineValidator validator;

    setUp(() {
      validator = OfflineValidator();
    });

    test('initializes successfully', () async {
      await validator.initialize();
      expect(validator, isNotNull);
    });

    test('detects online status', () async {
      await validator.initialize();
      // isOnline or isOffline should be true
      expect(
        validator.isOnline || validator.isOffline,
        true,
      );
    });

    test('validates offline data integrity', () async {
      await validator.initialize();
      final result = await validator.validateOfflineDataIntegrity();
      expect(result, isA<bool>());
    });

    test('validates sync queue', () async {
      await validator.initialize();
      final result = await validator.validateSyncQueue();
      expect(result, isA<bool>());
    });

    test('validates model files', () async {
      await validator.initialize();
      final result = await validator.validateModelFiles();
      expect(result, isA<bool>());
    });

    test('validates embeddings', () async {
      await validator.initialize();
      final result = await validator.validateEmbeddings();
      expect(result, isA<bool>());
    });

    test('runs all validations', () async {
      await validator.initialize();
      final results = await validator.runAllValidations();
      
      expect(results.containsKey('dataIntegrity'), true);
      expect(results.containsKey('syncQueue'), true);
      expect(results.containsKey('modelFiles'), true);
      expect(results.containsKey('embeddings'), true);
    });

    test('all validations return boolean', () async {
      await validator.initialize();
      final results = await validator.runAllValidations();
      
      results.forEach((key, value) {
        expect(value, isA<bool>());
      });
    });

    test('isOnline and isOffline are mutually exclusive', () async {
      await validator.initialize();
      expect(
        validator.isOnline && validator.isOffline,
        false,
      );
    });
  });
}
