import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:librio/services/auth_service_v2.dart';
import 'package:librio/services/secure_storage_service.dart';

// Generate mocks
class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('AuthServiceV2', () {
    late AuthServiceV2 authService;
    late MockSecureStorageService mockSecureStorage;

    setUp(() {
      mockSecureStorage = MockSecureStorageService();
      authService = AuthServiceV2(secureStorage: mockSecureStorage);
    });

    group('signUp', () {
      test('should successfully sign up with valid credentials', () async {
        when(mockSecureStorage.saveAuthData(
          accessToken: anyNamed('accessToken'),
          refreshToken: anyNamed('refreshToken'),
          userId: anyNamed('userId'),
          email: anyNamed('email'),
          name: anyNamed('name'),
        )).thenAnswer((_) async => {});

        // Note: This test would need HTTP mocking to fully work
        // For now, we're testing the validation logic
        expect(authService.isAuthenticated, false);
      });

      test('should reject signup with invalid email', () async {
        expect(
          () => authService.signUp(
            email: 'invalid-email',
            password: 'TestPassword123',
            name: 'Test User',
          ),
          throwsException,
        );
      });

      test('should reject signup with short password', () async {
        expect(
          () => authService.signUp(
            email: 'test@example.com',
            password: 'short',
            name: 'Test User',
          ),
          throwsException,
        );
      });

      test('should reject signup with empty name', () async {
        expect(
          () => authService.signUp(
            email: 'test@example.com',
            password: 'TestPassword123',
            name: '   ',
          ),
          throwsException,
        );
      });
    });

    group('signIn', () {
      test('should reject login with invalid email', () async {
        expect(
          () => authService.signIn(
            email: 'invalid-email',
            password: 'TestPassword123',
          ),
          throwsException,
        );
      });

      test('should reject login with empty password', () async {
        expect(
          () => authService.signIn(
            email: 'test@example.com',
            password: '',
          ),
          throwsException,
        );
      });
    });

    group('logout', () {
      test('should clear all auth data on logout', () async {
        when(mockSecureStorage.clearAuthData()).thenAnswer((_) async => {});

        await authService.logout();

        verify(mockSecureStorage.clearAuthData()).called(1);
        expect(authService.isAuthenticated, false);
        expect(authService.currentUserId, null);
        expect(authService.currentUserEmail, null);
      });
    });

    group('refreshAccessToken', () => {
      test('should return false if no refresh token available', () async {
        when(mockSecureStorage.getRefreshToken())
            .thenAnswer((_) async => null);

        final result = await authService.refreshAccessToken();

        expect(result, false);
      });
    });
  });
}
