import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/debug_logger.dart';

/// Authentication service for user login, signup, and password reset
class AuthService extends ChangeNotifier {
  static const String _tag = 'AuthService';

  bool _isAuthenticated = false;
  String? _currentUserId;
  String? _currentUserEmail;
  String? _currentUserName;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserName;

  AuthService() {
    _checkAuthStatus();
  }

  /// Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAuthenticated = prefs.getBool('auth_token') != null;
      _currentUserId = prefs.getString('user_id');
      _currentUserEmail = prefs.getString('user_email');
      _currentUserName = prefs.getString('user_name');
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

      // TODO: Call backend API to create user account
      // For now, simulate with local storage
      final prefs = await SharedPreferences.getInstance();
      final userId = DateTime.now().millisecondsSinceEpoch.toString();

      // Store user data
      await prefs.setString('user_id', userId);
      await prefs.setString('user_email', email);
      await prefs.setString('user_name', name);
      await prefs.setBool('auth_token', true);

      _currentUserId = userId;
      _currentUserEmail = email;
      _currentUserName = name;
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

      // TODO: Call backend API to authenticate
      // For now, simulate with local storage
      final prefs = await SharedPreferences.getInstance();

      // Verify credentials (in real app, call backend)
      final storedEmail = prefs.getString('user_email');
      if (storedEmail != email) {
        throw 'Email or password incorrect';
      }

      // Set authenticated state
      await prefs.setBool('auth_token', true);
      _isAuthenticated = true;
      _currentUserEmail = email;
      _currentUserId = prefs.getString('user_id');
      _currentUserName = prefs.getString('user_name');

      DebugLogger.success(_tag, 'User signed in: $email');
      notifyListeners();
      return true;
    } catch (e, st) {
      DebugLogger.error(_tag, 'Sign in failed', e, st);
      rethrow;
    }
  }

  /// Google Sign In
  Future<bool> signInWithGoogle() async {
    try {
      // TODO: Implement Google Sign-In using google_sign_in package
      // For now, simulate
      final prefs = await SharedPreferences.getInstance();
      final userId = DateTime.now().millisecondsSinceEpoch.toString();

      // Simulate Google user data
      final googleEmail = 'user@gmail.com';
      final googleName = 'Google User';

      await prefs.setString('user_id', userId);
      await prefs.setString('user_email', googleEmail);
      await prefs.setString('user_name', googleName);
      await prefs.setString('auth_provider', 'google');
      await prefs.setBool('auth_token', true);

      _currentUserId = userId;
      _currentUserEmail = googleEmail;
      _currentUserName = googleName;
      _isAuthenticated = true;

      DebugLogger.success(_tag, 'User signed in with Google: $googleEmail');
      notifyListeners();
      return true;
    } catch (e, st) {
      DebugLogger.error(_tag, 'Google sign in failed', e, st);
      rethrow;
    }
  }

  /// Request password reset email
  Future<bool> requestPasswordReset(String email) async {
    try {
      if (!_isValidEmail(email)) {
        throw 'Invalid email format';
      }

      // TODO: Call backend API to send password reset email
      // For now, simulate
      DebugLogger.success(_tag, 'Password reset email sent to: $email');
      return true;
    } catch (e, st) {
      DebugLogger.error(_tag, 'Password reset request failed', e, st);
      rethrow;
    }
  }

  /// Reset password with token
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      if (newPassword.length < 8) {
        throw 'Password must be at least 8 characters';
      }

      // TODO: Call backend API to reset password
      DebugLogger.success(_tag, 'Password reset successful');
      return true;
    } catch (e, st) {
      DebugLogger.error(_tag, 'Password reset failed', e, st);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('auth_provider');

      _isAuthenticated = false;
      _currentUserId = null;
      _currentUserEmail = null;
      _currentUserName = null;

      DebugLogger.success(_tag, 'User signed out');
      notifyListeners();
    } catch (e, st) {
      DebugLogger.error(_tag, 'Sign out failed', e, st);
      rethrow;
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }
}
