import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/debug_logger.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;
  bool _isSignUpMode = false;
  final _usernameController = TextEditingController();

  static const Color _deepPurple = Color(0xFF7B2CBF);
  static const Color _cyan = Color(0xFF06B6D4);
  static const String _tag = 'LoginScreen';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    setState(() => _errorMessage = null);

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    if (_isSignUpMode && _usernameController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter a username');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final username = _usernameController.text.trim();

      DebugLogger.info(_tag, 'Starting ${_isSignUpMode ? 'sign up' : 'sign in'} for $email');

      if (_isSignUpMode) {
        await authService.signUp(
          email: email,
          password: password,
          name: username,
        );
        DebugLogger.success(_tag, 'Sign up successful for $email');
      } else {
        await authService.signIn(
          email: email,
          password: password,
        );
        DebugLogger.success(_tag, 'Sign in successful for $email');
      }

      if (mounted) {
        widget.onLoginSuccess();
      }
    } on AuthRetryableFetchException catch (e) {
      DebugLogger.error(_tag, 'Network error during auth', e);
      setState(() => _errorMessage = 'Network error. Please check your connection and try again.');
    } on AuthException catch (e) {
      DebugLogger.error(_tag, 'Supabase auth error: ${e.message}', e);
      setState(() => _errorMessage = _formatAuthError(e.message));
    } catch (e) {
      DebugLogger.error(_tag, 'Unexpected error during auth', e);
      setState(() => _errorMessage = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Format Supabase auth error messages for user display
  String _formatAuthError(String message) {
    DebugLogger.info(_tag, 'Formatting error: $message');
    
    if (message.contains('Email not confirmed')) {
      return 'Please confirm your email before signing in. Check your inbox for a confirmation link.';
    }
    if (message.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    }
    if (message.contains('User already registered')) {
      return 'This email is already registered';
    }
    if (message.contains('Password should be at least')) {
      return 'Password must be at least 8 characters';
    }
    if (message.contains('invalid email')) {
      return 'Please enter a valid email address';
    }
    if (message.contains('Unable to validate email address')) {
      return 'Please enter a valid email address';
    }
    // Return the original message if no specific match
    return message;
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _errorMessage = null);
    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      DebugLogger.info(_tag, 'Starting Google Sign-In');
      await authService.signInWithGoogle();
      DebugLogger.success(_tag, 'Google Sign-In successful');

      if (mounted) {
        widget.onLoginSuccess();
      }
    } on AuthRetryableFetchException catch (e) {
      DebugLogger.error(_tag, 'Network error during Google Sign-In', e);
      setState(() => _errorMessage = 'Network error. Please check your connection and try again.');
    } on AuthException catch (e) {
      DebugLogger.error(_tag, 'Google Sign-In auth error: ${e.message}', e);
      setState(() => _errorMessage = _formatAuthError(e.message));
    } catch (e) {
      DebugLogger.error(_tag, 'Google Sign-In failed', e);
      setState(() => _errorMessage = 'Google Sign-In failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password',
            style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: TextStyle(fontFamily: 'Fredoka', fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontFamily: 'Fredoka'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Fredoka')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your email')),
                );
                return;
              }

              try {
                final authService = context.read<AuthService>();
                await authService.requestPasswordReset(emailController.text.trim());

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent! Check your inbox.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Reset Link',
                style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              // Logo/Title
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Libro',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _deepPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUpMode ? 'Create Account' : 'Welcome Back',
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Username field (sign up only)
              if (_isSignUpMode) ...[
                const Text('Username',
                    style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: 'Choose a username',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: const TextStyle(fontFamily: 'Fredoka'),
                ),
                const SizedBox(height: 16),
              ],

              // Email field
              const Text('Email',
                  style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: const TextStyle(fontFamily: 'Fredoka'),
              ),
              const SizedBox(height: 16),

              // Password field
              const Text('Password',
                  style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
                style: const TextStyle(fontFamily: 'Fredoka'),
              ),
              const SizedBox(height: 8),
              if (!_isSignUpMode)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        color: _deepPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Sign In/Up button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleEmailAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isSignUpMode ? 'Create Account' : 'Sign In',
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),

              const SizedBox(height: 20),

              // Google Sign In button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: const Icon(Icons.g_mobiledata, size: 20),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Toggle sign up/sign in
              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontFamily: 'Fredoka', fontSize: 14),
                    children: [
                      TextSpan(
                        text: _isSignUpMode
                            ? 'Already have an account? '
                            : 'Don\'t have an account? ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextSpan(
                        text: _isSignUpMode ? 'Sign In' : 'Sign Up',
                        style: const TextStyle(
                          color: _deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            setState(() {
                              _isSignUpMode = !_isSignUpMode;
                              _errorMessage = null;
                              _emailController.clear();
                              _passwordController.clear();
                              _usernameController.clear();
                            });
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
