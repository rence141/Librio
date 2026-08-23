import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/debug_logger.dart';

/// Secure storage service for sensitive data (tokens, credentials)
/// Uses platform-specific secure storage:
/// - iOS: Keychain
/// - Android: Keystore
/// - Web: localStorage (with encryption if available)
class SecureStorageService {
  static const String _tag = 'SecureStorageService';
  
  // Storage keys
  static const String _accessTokenKey = 'librio_access_token';
  static const String _refreshTokenKey = 'librio_refresh_token';
  static const String _userIdKey = 'librio_user_id';
  static const String _userEmailKey = 'librio_user_email';
  static const String _userNameKey = 'librio_user_name';
  static const String _googleIdTokenKey = 'librio_google_id_token';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
      DebugLogger.success(_tag, 'Access token saved securely');
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to save access token', e);
      rethrow;
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to read access token', e);
      return null;
    }
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
      DebugLogger.success(_tag, 'Refresh token saved securely');
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to save refresh token', e);
      rethrow;
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to read refresh token', e);
      return null;
    }
  }

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to save user ID', e);
      rethrow;
    }
  }

  /// Get user ID
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to read user ID', e);
      return null;
    }
  }

  /// Save user email
  Future<void> saveUserEmail(String email) async {
    try {
      await _storage.write(key: _userEmailKey, value: email);
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to save user email', e);
      rethrow;
    }
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    try {
      return await _storage.read(key: _userEmailKey);
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to read user email', e);
      return null;
    }
  }

  /// Save user name
  Future<void> saveUserName(String name) async {
    try {
      await _storage.write(key: _userNameKey, value: name);
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to save user name', e);
      rethrow;
    }
  }

  /// Get user name
  Future<String?> getUserName() async {
    try {
      return await _storage.read(key: _userNameKey);
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to read user name', e);
      return null;
    }
  }

  /// Save Google ID token (for verification)
  Future<void> saveGoogleIdToken(String token) async {
    try {
      await _storage.write(key: _googleIdTokenKey, value: token);
      DebugLogger.success(_tag, 'Google ID token saved securely');
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to save Google ID token', e);
      rethrow;
    }
  }

  /// Get Google ID token
  Future<String?> getGoogleIdToken() async {
    try {
      return await _storage.read(key: _googleIdTokenKey);
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to read Google ID token', e);
      return null;
    }
  }

  /// Save all auth data at once
  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
    String? name,
  }) async {
    try {
      await Future.wait([
        saveAccessToken(accessToken),
        saveRefreshToken(refreshToken),
        saveUserId(userId),
        saveUserEmail(email),
        if (name != null) saveUserName(name),
      ]);
      DebugLogger.success(_tag, 'All auth data saved securely');
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to save auth data', e);
      rethrow;
    }
  }

  /// Clear all auth data (logout)
  Future<void> clearAuthData() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _userEmailKey),
        _storage.delete(key: _userNameKey),
        _storage.delete(key: _googleIdTokenKey),
      ]);
      DebugLogger.success(_tag, 'All auth data cleared');
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to clear auth data', e);
      rethrow;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final token = await getAccessToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to check authentication status', e);
      return false;
    }
  }
}
