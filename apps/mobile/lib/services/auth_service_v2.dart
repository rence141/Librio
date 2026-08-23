import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/google_config.dart';
import '../utils/debug_logger.dart';
import 'secure_storage_service.dart';

/// Authentication service for user login, signup, and password reset
/// Uses secure storage for tokens and calls backend API for authentication
class AuthServiceV2 extends ChangeNotifier {
  static const String _tag = 'AuthService';
  static const String _apiBaseUrl = 'http://localhost:3000'; // Change to production URL

  bool _isAuthenticated = false;
  String? _currentUserId;
  String? _currentUserEmail;
  String? _currentUserName;
  String? _accessToken;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserName;
  String? get accessToken => _accessToken;

  final SecureStorageService _secureStorage;
  late GoogleSignIn _googleSignIn;

  AuthServiceV2({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService() {
    _initializeGoogleSignIn();
    _checkAuthStatus();
  }

  /// Initialize Google Sign-In
  void _initializeGoogleSignIn() {
    _googleSignIn = GoogleSignIn(
      clientId: GoogleConfig.debugClientId,
      scopes: [
        'email',
        'profile',
      ],
    );
  }

  /// Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        _accessToken = token;
        _currentUserId = await _secureStorage.getUserId();
        _currentUserEmail = await _secureStorage.getUserEmail();
        _currentUserName = await _secureStorage.getUserName();
        _isAuthenticated = true;
        DebugLogger.success(_tag, 'User authenticated from storage');
      }
      notifyListeners();
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to check auth status', e);
    }
  }

  /// Email/Password Sign Up
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Validate inputs
      if (!_isValidEmail(email)) {
        throw 'Invalid email format';
      }
      if (password.length < 8) {
        throw 'Password must be at least 8 characters';
      }
      if (name.trim().isEmpty) {
        throw 'Name cannot be empty';
      }

      // Call backend API to create user account
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullName': name,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw error['error'] ?? 'Sign up failed';
      }

      final data = jsonDecode(response.body);
      final authData = data['data'];

      // Save tokens and user data securely
      await _secureStorage.saveAuthData(
        accessToken: authData['accessToken'],
        refreshToken: authData['refreshToken'],
        userId: authData['user']['id'],
        email: authData['user']['email'],
        name: authData['user']['fullName'],
      );

      // Update state
      _accessToken = authData['accessToken'];
      _currentUserId = authData['user']['id'];
      _currentUserEmail = authData['user']['email'];
      _currentUserName = authData['user']['fullName'];
      _isAuthenticated = true;

      DebugLogger.success(_tag, 'User signed up: $email');
      notifyListeners();
      return true;
    } catch (e, st) {
      DebugLogger.error(_tag, 'Sign up failed', e, st);
      rethrow;
    }
  }

  /// Email/Password Sign In
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      if (!_isValidEmail(email)) {
        throw 'Invalid email format';
      }
      if (password.isEmpty) {
        throw 'Password cannot be empty';
      }

      // Call backend API to authenticate
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw error['error'] ?? 'Login failed';
      }

      final data = jsonDecode(response.body);
      final authData = data['data'];

      // Save tokens and user data securely
      await _secureStorage.saveAuthData(
        accessToken: authData['accessToken'],
        refreshToken: authData['refreshToken'],
        userId: authData['user']['id'],
        email: authData['user']['email'],
        name: authData['user']['fullName'],
      );

      // Update state
      _accessToken = authData['accessToken'];
      _currentUserId = authData['user']['id'];
      _currentUserEmail = authData['user']['email'];
      _currentUserName = authData['user']['fullName'];
      _isAuthenticated = true;

      DebugLogger.success(_tag, 'User logged in: $email');
      notifyListeners();
      return true;
    } catch (e, st) {
      DebugLogger.error(_tag, 'Login failed', e, st);
      rethrow;
    }
  }

  /// Google Sign-In
  Future<bool> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Google sign-in cancelled';
      }

      // Get the ID token
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'Failed to get Google ID token';
      }

      // Save the ID token for verification
      await _secureStorage.saveGoogleIdToken(idToken);

      // Call backend API to verify Google token and create/update user
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw error['error'] ?? 'Google sign-in failed';
      }

      final data = jsonDecode(response.body);
      final authData = data['data'];

      // Save tokens and user data securely
      await _secureStorage.saveAuthData(
        accessToken: authData['accessToken'],
        refreshToken: authData['refreshToken'],
        userId: authData['user']['id'],
        email: authData['user']['email'],
        name: authData['user']['fullName'],
      );

      // Update state
      _accessToken = authData['accessToken'];
      _currentUserId = authData['user']['id'];
      _currentUserEmail = authData['user']['email'];
      _currentUserName = authData['user']['fullName'];
      _isAuthenticated = true;

      DebugLogger.success(_tag, 'User signed in with Google: ${googleUser.email}');
      notifyListeners();
      return true;
    } catch (e, st) {
      DebugLogger.error(_tag, 'Google sign-in failed', e, st);
      rethrow;
    }
  }

  /// Refresh access token
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        throw 'No refresh token available';
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        // Refresh token expired, need to re-authenticate
        await logout();
        throw 'Session expired. Please login again.';
      }

      final data = jsonDecode(response.body);
      final newAccessToken = data['data']['accessToken'];

      // Save new access token
      await _secureStorage.saveAccessToken(newAccessToken);
      _accessToken = newAccessToken;

      DebugLogger.success(_tag, 'Access token refreshed');
      notifyListeners();
      return true;
    } catch (e, st) {
      DebugLogger.error(_tag, 'Token refresh failed', e, st);
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Call backend API to logout
      if (_accessToken != null) {
        await http.post(
          Uri.parse('$_apiBaseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_accessToken',
          },
        ).timeout(const Duration(seconds: 10));
      }

      // Sign out from Google if signed in
      await _googleSignIn.signOut();

      // Clear all stored data
      await _secureStorage.clearAuthData();

      // Update state
      _isAuthenticated = false;
      _currentUserId = null;
      _currentUserEmail = null;
      _currentUserName = null;
      _accessToken = null;

      DebugLogger.success(_tag, 'User logged out');
      notifyListeners();
    } catch (e, st) {
      DebugLogger.error(_tag, 'Logout failed', e, st);
      // Clear local data even if backend logout fails
      await _secureStorage.clearAuthData();
      _isAuthenticated = false;
      _currentUserId = null;
      _currentUserEmail = null;
      _currentUserName = null;
      _accessToken = null;
      notifyListeners();
    }
  }

  /// Request password reset
  Future<void> requestPasswordReset(String email) async {
    try {
      if (!_isValidEmail(email)) {
        throw 'Invalid email format';
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/request-password-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw error['error'] ?? 'Failed to request password reset';
      }

      DebugLogger.success(_tag, 'Password reset email sent to: $email');
    } catch (e, st) {
      DebugLogger.error(_tag, 'Password reset request failed', e, st);
      rethrow;
    }
  }

  /// Confirm password reset
  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    try {
      if (newPassword.length < 8) {
        throw 'Password must be at least 8 characters';
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/confirm-password-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw error['error'] ?? 'Failed to reset password';
      }

      DebugLogger.success(_tag, 'Password reset successfully');
    } catch (e, st) {
      DebugLogger.error(_tag, 'Password reset failed', e, st);
      rethrow;
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }
}
