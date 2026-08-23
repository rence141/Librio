import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/google_config.dart';
import '../utils/debug_logger.dart';
import '../utils/error_handler.dart';
import 'secure_storage_service.dart';

/// Enhanced authentication service with error handling and retry logic
/// Uses secure storage for tokens and calls backend API for authentication
class AuthServiceV3 extends ChangeNotifier {
  static const String _tag = 'AuthService';
  static const String _apiBaseUrl = 'http://localhost:3000'; // Change to production URL
  static const int _maxRetries = 3;
  static const Duration _requestTimeout = Duration(seconds: 10);

  bool _isAuthenticated = false;
  String? _currentUserId;
  String? _currentUserEmail;
  String? _currentUserName;
  String? _accessToken;
  bool _isLoading = false;
  String? _lastError;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserName;
  String? get accessToken => _accessToken;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  final SecureStorageService _secureStorage;
  late GoogleSignIn _googleSignIn;

  AuthServiceV3({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService() {
    _initializeGoogleSignIn();
    _checkAuthStatus();
  }

  /// Initialize Google Sign-In
  void _initializeGoogleSignIn() {
    _googleSignIn = GoogleSignIn(
      clientId: GoogleConfig.debugClientId,
      scopes: ['email', 'profile'],
    );
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error
  void _setError(String? error) {
    _lastError = error;
    notifyListeners();
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
      _setError(ErrorHandler.getUserMessage(e));
    }
  }

  /// Email/Password Sign Up with error handling
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      // Validate inputs
      if (!_isValidEmail(email)) {
        throw InvalidEmailException();
      }
      if (password.length < 8) {
        throw WeakPasswordException();
      }
      if (name.trim().isEmpty) {
        throw ValidationException(message: 'Name cannot be empty');
      }

      // Call backend API with retry logic
      final response = await RetryHelper.retryWithBackoff(
        () => http.post(
          Uri.parse('$_apiBaseUrl/auth/signup'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'fullName': name,
          }),
        ).timeout(_requestTimeout),
        maxRetries: _maxRetries,
      );

      if (response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] ?? 'Sign up failed',
        );
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
      _setLoading(false);
      return true;
    } on AppException catch (e) {
      ErrorHandler.logError(e, tag: _tag);
      _setError(e.message);
      _setLoading(false);
      rethrow;
    } catch (e) {
      final message = ErrorHandler.getUserMessage(e);
      ErrorHandler.logError(e, tag: _tag);
      _setError(message);
      _setLoading(false);
      rethrow;
    }
  }

  /// Email/Password Sign In with error handling
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      if (!_isValidEmail(email)) {
        throw InvalidEmailException();
      }
      if (password.isEmpty) {
        throw ValidationException(message: 'Password cannot be empty');
      }

      // Call backend API with retry logic
      final response = await RetryHelper.retryWithBackoff(
        () => http.post(
          Uri.parse('$_apiBaseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        ).timeout(_requestTimeout),
        maxRetries: _maxRetries,
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          throw InvalidCredentialsException();
        }
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] ?? 'Login failed',
        );
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
      _setLoading(false);
      return true;
    } on AppException catch (e) {
      ErrorHandler.logError(e, tag: _tag);
      _setError(e.message);
      _setLoading(false);
      rethrow;
    } catch (e) {
      final message = ErrorHandler.getUserMessage(e);
      ErrorHandler.logError(e, tag: _tag);
      _setError(message);
      _setLoading(false);
      rethrow;
    }
  }

  /// Google Sign-In with error handling
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthenticationException(
          message: 'Google sign-in cancelled',
        );
      }

      // Get the ID token
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw AuthenticationException(
          message: 'Failed to get Google ID token',
        );
      }

      // Save the ID token for verification
      await _secureStorage.saveGoogleIdToken(idToken);

      // Call backend API with retry logic
      final response = await RetryHelper.retryWithBackoff(
        () => http.post(
          Uri.parse('$_apiBaseUrl/auth/google'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'idToken': idToken}),
        ).timeout(_requestTimeout),
        maxRetries: _maxRetries,
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] ?? 'Google sign-in failed',
        );
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
      _setLoading(false);
      return true;
    } on AppException catch (e) {
      ErrorHandler.logError(e, tag: _tag);
      _setError(e.message);
      _setLoading(false);
      rethrow;
    } catch (e) {
      final message = ErrorHandler.getUserMessage(e);
      ErrorHandler.logError(e, tag: _tag);
      _setError(message);
      _setLoading(false);
      rethrow;
    }
  }

  /// Refresh access token with error handling
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        throw TokenExpiredException();
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        // Refresh token expired, need to re-authenticate
        await logout();
        throw TokenExpiredException();
      }

      final data = jsonDecode(response.body);
      final newAccessToken = data['data']['accessToken'];

      // Save new access token
      await _secureStorage.saveAccessToken(newAccessToken);
      _accessToken = newAccessToken;

      DebugLogger.success(_tag, 'Access token refreshed');
      notifyListeners();
      return true;
    } catch (e) {
      ErrorHandler.logError(e, tag: _tag);
      _setError(ErrorHandler.getUserMessage(e));
      return false;
    }
  }

  /// Logout user with error handling
  Future<void> logout() async {
    try {
      _setLoading(true);
      _setError(null);

      // Call backend API to logout
      if (_accessToken != null) {
        await http.post(
          Uri.parse('$_apiBaseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_accessToken',
          },
        ).timeout(_requestTimeout);
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
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      ErrorHandler.logError(e, tag: _tag);
      // Clear local data even if backend logout fails
      await _secureStorage.clearAuthData();
      _isAuthenticated = false;
      _currentUserId = null;
      _currentUserEmail = null;
      _currentUserName = null;
      _accessToken = null;
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Request password reset with error handling
  Future<void> requestPasswordReset(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      if (!_isValidEmail(email)) {
        throw InvalidEmailException();
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/request-password-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] ?? 'Failed to request password reset',
        );
      }

      DebugLogger.success(_tag, 'Password reset email sent to: $email');
      _setLoading(false);
    } catch (e) {
      ErrorHandler.logError(e, tag: _tag);
      _setError(ErrorHandler.getUserMessage(e));
      _setLoading(false);
      rethrow;
    }
  }

  /// Confirm password reset with error handling
  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      if (newPassword.length < 8) {
        throw WeakPasswordException();
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/confirm-password-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'newPassword': newPassword,
        }),
      ).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] ?? 'Failed to reset password',
        );
      }

      DebugLogger.success(_tag, 'Password reset successfully');
      _setLoading(false);
    } catch (e) {
      ErrorHandler.logError(e, tag: _tag);
      _setError(ErrorHandler.getUserMessage(e));
      _setLoading(false);
      rethrow;
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }
}
