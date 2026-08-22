import 'package:flutter/material.dart';
import '../services/token_manager.dart';

/// Signup screen
class SignupScreen extends StatefulWidget {
  final TokenManager tokenManager;
  
  const SignupScreen({
    super.key,
    required this.tokenManager,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
  
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> signup() async {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      setState(() => errorMessage = 'Please fill in all fields');
      return;
    }
    
    if (passwordController.text != confirmPasswordController.text) {
      setState(() => errorMessage = 'Passwords do not match');
      return;
    }
    
    if (passwordController.text.length < 6) {
      setState(() => errorMessage = 'Password must be at least 6 characters');
      return;
    }
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      // TODO: Implement actual signup with backend
      // For now, simulate successful signup
      await Future.delayed(const Duration(seconds: 2));
      
      // Save dummy tokens
      await widget.tokenManager.saveTokens(
        token: 'dummy_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'dummy_refresh_token',
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        userEmail: emailController.text,
      );
      
      if (mounted) {
        // Navigate to home screen
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() => errorMessage = 'Signup failed: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            
            // Welcome text
            const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            const Text(
              'Join Librio today',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            // Error message
            if (errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            if (errorMessage != null) const SizedBox(height: 16),
            
            // Email field
            TextField(
              controller: emailController,
              enabled: !isLoading,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'your@email.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            
            // Password field
            TextField(
              controller: passwordController,
              enabled: !isLoading,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'At least 6 characters',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            
            // Confirm password field
            TextField(
              controller: confirmPasswordController,
              enabled: !isLoading,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Re-enter your password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            
            // Signup button
            ElevatedButton(
              onPressed: isLoading ? null : signup,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
                disabledBackgroundColor: Colors.grey,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            
            // Login link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? '),
                TextButton(
                  onPressed: isLoading ? null : () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
