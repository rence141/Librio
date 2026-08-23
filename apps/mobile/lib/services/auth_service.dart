import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/google_config.dart';
import '../utils/debug_logger.dart';

/// Authentication service backed by Supabase Auth.
///
/// Replaces the previous SharedPreferences-based stub and the custom
/// Node.js backend (AuthServiceV3). All auth goes through Supabase,
/// producing JWTs that the ai-chat Edge Function can verify.
///
/// Supported methods:
///   - Email / password (sign up, sign in, password reset)
///   - Google Sign-In (via Supabase signInWithIdToken)
class AuthService extends ChangeNotifier {
  static const String _tag = 'AuthService';

  bool _isAuthenticated = false;
  String? _currentUserId;
  String? _currentUserEmail;
  String? _currentUserName;
  bool _isLoading = false;
  String? _lastError;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserName;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  /// Current Supabase access token (JWT) — null if not signed in.
  String? get accessToken => Supabase.instance.client.auth.currentSession?.accessToken;

  AuthService() {
    _checkAuthStatus();
    // Listen to Supabase auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      _onAuthStateChanged(event.event, event.session);
    });
  }

  void _onAuthStateChanged(AuthChangeEvent event, Session? session) {
    if (session != null) {
      _isAuthenticated = true;
      _currentUserId = session.user.id;
      _currentUserEmail = session.user.email;
      _currentUserName = session.user.userMetadata?['username'] as String? ??
          session.user.userMetadata?['full_name'] as String? ??
          session.user.userMetadata?['name'] as String? ??
          '';
    } else {
      _isAuthenticated = false;
      _currentUserId = null;
      _currentUserEmail = null;
      _currentUserName = null;
    }
    notifyListeners();
  }

  /// Check if user is already authenticated from persisted Supabase session
  Future<void> _checkAuthStatus() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _isAuthenticated = true;
        _currentUserId = session.user.id;
        _currentUserEmail = session.user.email;
        _currentUserName = session.user.userMetadata?['username'] as String? ??
            session.user.userMetadata?['full_name'] as String? ??
            session.user.userMetadata?['name'] as String? ??
            '';
        DebugLogger.success(_tag, 'User authenticated from Supabase session');
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
      _setLoading(true);
      _setError(null);

      if (!_isValidEmail(email)) {
        throw 'Invalid email format';
      }
      if (password.length < 8) {
        throw 'Password must be at least 8 characters';
      }
      if (name.trim().isEmpty) {
        throw 'Username cannot be empty';
      }

      DebugLogger.info(_tag, 'Signing up user: $email with username: $name');

      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'username': name, 'full_name': name},
      );

      if (response.user == null) {
        throw 'Sign up failed — no user returned';
      }

      _currentUserId = response.user!.id;
      _currentUserEmail = response.user!.email;
      _currentUserName = name;
      _isAuthenticated = true;

      DebugLogger.success(_tag, 'User signed up: $email (username: $name)');
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      DebugLogger.error(_tag, 'Supabase sign up error: ${e.message}', e);
      _setError(e.message);
      _setLoading(false);
      rethrow;
    } catch (e, st) {
      DebugLogger.error(_tag, 'Sign up failed', e, st);
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  /// Email/Password Sign In
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      if (!_isValidEmail(email)) {
        throw 'Invalid email format';
      }
      if (password.isEmpty) {
        throw 'Password cannot be empty';
      }

      DebugLogger.info(_tag, 'Signing in user: $email');

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw 'Sign in failed — no user returned';
      }

      _currentUserId = response.user!.id;
      _currentUserEmail = response.user!.email;
      _currentUserName = response.user!.userMetadata?['username'] as String? ??
          response.user!.userMetadata?['full_name'] as String? ??
          response.user!.userMetadata?['name'] as String? ??
          '';
      _isAuthenticated = true;

      DebugLogger.success(_tag, 'User signed in: $email (username: $_currentUserName)');
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      DebugLogger.error(_tag, 'Supabase sign in error: ${e.message}', e);
      // Handle email not confirmed
      if (e.message.contains('Email not confirmed')) {
        _setError('Please confirm your email before signing in. Check your inbox for a confirmation link.');
      } else {
        _setError(e.message);
      }
      _setLoading(false);
      rethrow;
    } catch (e, st) {
      DebugLogger.error(_tag, 'Sign in failed', e, st);
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  /// Google Sign In — uses GoogleSignIn to get an ID token, then
  /// signs into Supabase with signInWithIdToken.
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      DebugLogger.info(_tag, 'Starting Google Sign-In with client ID: ${GoogleConfig.debugClientId}');

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: GoogleConfig.debugClientId,
        scopes: GoogleConfig.scopes,
      );

      DebugLogger.info(_tag, 'Requesting Google sign-in...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        DebugLogger.warning(_tag, 'Google sign-in cancelled by user');
        _setLoading(false);
        throw 'Google sign-in cancelled';
      }

      DebugLogger.info(_tag, 'Google user signed in: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      DebugLogger.info(_tag, 'Retrieved Google authentication tokens');

      final idToken = googleAuth.idToken;
      if (idToken == null) {
        DebugLogger.error(_tag, 'Failed to get Google ID token', null);
        throw 'Failed to get Google ID token';
      }

      DebugLogger.info(_tag, 'Signing in to Supabase with Google ID token...');

      // Sign in to Supabase with the Google ID token
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      if (response.user == null) {
        DebugLogger.error(_tag, 'Supabase returned no user', null);
        throw 'Supabase Google sign-in failed — no user returned';
      }

      _currentUserId = response.user!.id;
      _currentUserEmail = response.user!.email;
      _currentUserName = googleUser.displayName ?? response.user!.userMetadata?['username'] ?? '';
      _isAuthenticated = true;

      DebugLogger.success(_tag, 'Google sign in successful: ${googleUser.email} (username: $_currentUserName)');
      _setLoading(false);
      return true;
    } on AuthRetryableFetchException catch (e) {
      DebugLogger.error(_tag, 'Network error during Google sign-in', e);
      _setError('Network error. Please check your connection and try again.');
      _setLoading(false);
      rethrow;
    } on AuthException catch (e) {
      DebugLogger.error(_tag, 'Supabase Google sign-in error: ${e.message}', e);
      _setError(e.message);
      _setLoading(false);
      rethrow;
    } catch (e, st) {
      DebugLogger.error(_tag, 'Google sign in failed', e, st);
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  /// Request password reset email
  Future<bool> requestPasswordReset(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      if (!_isValidEmail(email)) {
        throw 'Invalid email format';
      }

      await Supabase.instance.client.auth.resetPasswordForEmail(email);

      DebugLogger.success(_tag, 'Password reset email sent to: $email');
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      DebugLogger.error(_tag, 'Password reset error: ${e.message}', e);
      _setError(e.message);
      _setLoading(false);
      rethrow;
    } catch (e, st) {
      DebugLogger.error(_tag, 'Password reset request failed', e, st);
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  /// Reset password (user must already have a recovery session)
  Future<bool> resetPassword({
    required String newPassword,
  }) async {
    try {
      if (newPassword.length < 8) {
        throw 'Password must be at least 8 characters';
      }

      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw 'Password reset failed';
      }

      DebugLogger.success(_tag, 'Password reset successful');
      return true;
    } on AuthException catch (e) {
      DebugLogger.error(_tag, 'Password reset error: ${e.message}', e);
      _setError(e.message);
      rethrow;
    } catch (e, st) {
      DebugLogger.error(_tag, 'Password reset failed', e, st);
      _setError(e.toString());
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();

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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _lastError = error;
    notifyListeners();
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }
}
