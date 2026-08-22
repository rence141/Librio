import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'token_manager.dart';

/// Authentication result
class AuthResult {
  final bool success;
  final String? token;
  final String? refreshToken;
  final String? userId;
  final String? userEmail;
  final String? error;
  
  AuthResult({
    required this.success,
    this.token,
    this.refreshToken,
    this.userId,
    this.userEmail,
    this.error,
  });
}

/// Authentication Service
class AuthService {
  static final AuthService _instance = AuthService._internal();
  
  factory AuthService() {
    return _instance;
  }
  
  AuthService._internal();
  
  late ApiService _apiService;
  late TokenManager _tokenManager;
  
  /// Initialize auth service
  Future<void> initialize(ApiService apiService, TokenManager tokenManager) async {
    _apiService = apiService;
    _tokenManager = tokenManager;
    
    if (kDebugMode) {
      print('✅ Auth service initialized');
    }
  }
  
  /// Login with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('🔐 Attempting login for: $email');
      }
      
      final response = await _apiService.post<Map<String, dynamic>>(
        endpoint: '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );
      
      if (response.success && response.data != null) {
        var data = response.data!;
        
        // Handle response wrapped in 'data' field
        if (data['data'] is Map) {
          data = data['data'] as Map<String, dynamic>;
        }
        
        // Handle both old and new response formats
        final accessToken = data['accessToken'] as String? ?? data['token'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        
        // Extract user data from nested 'user' object or top level
        String? userId;
        if (data['user'] is Map) {
          userId = (data['user'] as Map)['id'] as String?;
        } else {
          userId = data['userId'] as String?;
        }
        
        if (kDebugMode) {
          print('📦 Response data: $data');
          print('🔑 accessToken: $accessToken');
          print('🔑 refreshToken: $refreshToken');
          print('👤 userId: $userId');
        }
        
        if (accessToken != null && refreshToken != null && userId != null) {
          // Save tokens
          await _tokenManager.saveTokens(
            token: accessToken,
            refreshToken: refreshToken,
            userId: userId,
            userEmail: email,
          );
          
          if (kDebugMode) {
            print('✅ Login successful for: $email');
          }
          
          return AuthResult(
            success: true,
            token: accessToken,
            refreshToken: refreshToken,
            userId: userId,
            userEmail: email,
          );
        }
      }
      
      if (kDebugMode) {
        print('❌ Login failed: ${response.error}');
        print('📦 Response data: ${response.data}');
      }
      
      return AuthResult(
        success: false,
        error: response.error ?? 'Login failed',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Login error: $e');
      }
      
      return AuthResult(
        success: false,
        error: 'Login error: $e',
      );
    }
  }
  
  /// Signup with email and password
  Future<AuthResult> signup({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('📝 Attempting signup for: $email');
      }
      
      final response = await _apiService.post<Map<String, dynamic>>(
        endpoint: '/auth/signup',
        body: {
          'email': email,
          'password': password,
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );
      
      if (response.success && response.data != null) {
        var data = response.data!;
        
        // Handle response wrapped in 'data' field
        if (data['data'] is Map) {
          data = data['data'] as Map<String, dynamic>;
        }
        
        // Handle both old and new response formats
        final accessToken = data['accessToken'] as String? ?? data['token'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        
        // Extract user data from nested 'user' object or top level
        String? userId;
        if (data['user'] is Map) {
          userId = (data['user'] as Map)['id'] as String?;
        } else {
          userId = data['userId'] as String?;
        }
        
        if (kDebugMode) {
          print('📦 Response data: $data');
          print('🔑 accessToken: $accessToken');
          print('🔑 refreshToken: $refreshToken');
          print('👤 userId: $userId');
        }
        
        if (accessToken != null && refreshToken != null && userId != null) {
          // Save tokens
          await _tokenManager.saveTokens(
            token: accessToken,
            refreshToken: refreshToken,
            userId: userId,
            userEmail: email,
          );
          
          if (kDebugMode) {
            print('✅ Signup successful for: $email');
          }
          
          return AuthResult(
            success: true,
            token: accessToken,
            refreshToken: refreshToken,
            userId: userId,
            userEmail: email,
          );
        }
      }
      
      if (kDebugMode) {
        print('❌ Signup failed: ${response.error}');
        print('📦 Response data: ${response.data}');
      }
      
      return AuthResult(
        success: false,
        error: response.error ?? 'Signup failed',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Signup error: $e');
      }
      
      return AuthResult(
        success: false,
        error: 'Signup error: $e',
      );
    }
  }
  
  /// Refresh token
  Future<AuthResult> refreshToken() async {
    try {
      if (kDebugMode) {
        print('🔄 Refreshing token');
      }
      
      final refreshToken = await _tokenManager.getRefreshToken();
      if (refreshToken == null) {
        return AuthResult(
          success: false,
          error: 'No refresh token available',
        );
      }
      
      final response = await _apiService.post<Map<String, dynamic>>(
        endpoint: '/auth/refresh',
        body: {
          'refreshToken': refreshToken,
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );
      
      if (response.success && response.data != null) {
        final data = response.data!;
        final newToken = data['token'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;
        
        if (newToken != null && newRefreshToken != null) {
          final userId = await _tokenManager.getUserId();
          final userEmail = await _tokenManager.getUserEmail();
          
          await _tokenManager.saveTokens(
            token: newToken,
            refreshToken: newRefreshToken,
            userId: userId ?? 'unknown',
            userEmail: userEmail ?? 'unknown',
          );
          
          if (kDebugMode) {
            print('✅ Token refreshed');
          }
          
          return AuthResult(
            success: true,
            token: newToken,
            refreshToken: newRefreshToken,
          );
        }
      }
      
      if (kDebugMode) {
        print('❌ Token refresh failed: ${response.error}');
      }
      
      return AuthResult(
        success: false,
        error: response.error ?? 'Token refresh failed',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Token refresh error: $e');
      }
      
      return AuthResult(
        success: false,
        error: 'Token refresh error: $e',
      );
    }
  }
  
  /// Logout
  Future<void> logout() async {
    try {
      if (kDebugMode) {
        print('🚪 Logging out');
      }
      
      // Call logout endpoint
      await _apiService.post(
        endpoint: '/auth/logout',
        body: {},
      );
      
      // Clear tokens
      await _tokenManager.clearTokens();
      
      if (kDebugMode) {
        print('✅ Logout successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Logout error: $e');
      }
      
      // Clear tokens anyway
      await _tokenManager.clearTokens();
    }
  }
  
  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _tokenManager.isLoggedIn();
  }
}
