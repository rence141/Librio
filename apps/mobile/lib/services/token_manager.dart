import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Token manager for authentication
class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  
  late SharedPreferences _prefs;
  bool _initialized = false;
  
  /// Initialize token manager
  Future<void> initialize() async {
    if (_initialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    
    if (kDebugMode) {
      print('✅ Token manager initialized');
    }
  }
  
  /// Save tokens
  Future<void> saveTokens({
    required String token,
    required String refreshToken,
    required String userId,
    required String userEmail,
  }) async {
    await _ensureInitialized();
    
    await _prefs.setString(_tokenKey, token);
    await _prefs.setString(_refreshTokenKey, refreshToken);
    await _prefs.setString(_userIdKey, userId);
    await _prefs.setString(_userEmailKey, userEmail);
    
    if (kDebugMode) {
      print('💾 Tokens saved for user: $userEmail');
    }
  }
  
  /// Get access token
  Future<String?> getToken() async {
    await _ensureInitialized();
    return _prefs.getString(_tokenKey);
  }
  
  /// Get refresh token
  Future<String?> getRefreshToken() async {
    await _ensureInitialized();
    return _prefs.getString(_refreshTokenKey);
  }
  
  /// Get user ID
  Future<String?> getUserId() async {
    await _ensureInitialized();
    return _prefs.getString(_userIdKey);
  }
  
  /// Get user email
  Future<String?> getUserEmail() async {
    await _ensureInitialized();
    return _prefs.getString(_userEmailKey);
  }
  
  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  /// Clear all tokens (logout)
  Future<void> clearTokens() async {
    await _ensureInitialized();
    
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_userEmailKey);
    
    if (kDebugMode) {
      print('🗑️ Tokens cleared (logout)');
    }
  }
  
  /// Ensure token manager is initialized
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
}
