# Librio Authentication Setup Guide

Complete guide to set up email/password and Google Sign-In authentication.

## Overview

Librio now includes:
- ✅ Email/Password Sign Up
- ✅ Email/Password Sign In
- ✅ Forgot Password (email reset)
- ✅ Google Sign-In
- ✅ Sign Out

---

## Step 1: Install Dependencies

```bash
cd C:\dev\Librio\apps\mobile
flutter pub get
```

New dependencies added:
- `provider: ^6.4.0` — State management
- `google_sign_in: ^6.2.0` — Google authentication

---

## Step 2: Set Up Google Sign-In

### Android Configuration

Edit `android/app/build.gradle.kts`:

```kotlin
dependencies {
    // Add Google Play Services
    implementation("com.google.android.gms:play-services-auth:21.0.0")
}
```

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.librio.librio">

    <!-- Add Google Sign-In permission -->
    <uses-permission android:name="android.permission.INTERNET" />
    
    <application>
        ...
    </application>
</manifest>
```

### Get Google OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project: "Librio"
3. Enable Google+ API
4. Create OAuth 2.0 credentials:
   - Type: Android
   - Package name: `com.librio.librio`
   - SHA-1 fingerprint: Get from:
     ```bash
     cd C:\dev\Librio\apps\mobile
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey
     ```
   - Copy the SHA-1 value
5. Create credentials and get Client ID

### Configure google_sign_in

Create `lib/config/google_config.dart`:

```dart
class GoogleConfig {
  static const String clientId = 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com';
  static const String webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
}
```

---

## Step 3: Update Main App

Update `lib/main.dart` to use AuthService with Provider:

```dart
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ... other initialization ...
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Librio',
        theme: LibrioTheme.lightTheme,
        home: Consumer<AuthService>(
          builder: (context, authService, _) {
            if (authService.isAuthenticated) {
              return const ChatScreen();
            } else {
              return LoginScreen(
                onLoginSuccess: () {
                  // Navigate to chat screen
                  Navigator.of(context).pushReplacementNamed('/chat');
                },
              );
            }
          },
        ),
      ),
    );
  }
}
```

---

## Step 4: Implement Backend Integration

### Current State

The `AuthService` uses local storage (SharedPreferences) for demo purposes.

### For Production

Replace the TODO sections in `lib/services/auth_service.dart`:

#### Sign Up
```dart
Future<bool> signUp({...}) async {
  // Call backend API
  final response = await http.post(
    Uri.parse('https://your-api.com/auth/signup'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
      'name': name,
    }),
  );
  
  if (response.statusCode == 201) {
    final data = jsonDecode(response.body);
    await _saveAuthToken(data['token']);
    return true;
  }
  throw 'Sign up failed';
}
```

#### Sign In
```dart
Future<bool> signIn({...}) async {
  final response = await http.post(
    Uri.parse('https://your-api.com/auth/signin'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    await _saveAuthToken(data['token']);
    return true;
  }
  throw 'Sign in failed';
}
```

#### Google Sign In
```dart
Future<bool> signInWithGoogle() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    
    if (googleUser == null) return false;
    
    final GoogleSignInAuthentication googleAuth = 
        await googleUser.authentication;
    
    // Send to backend
    final response = await http.post(
      Uri.parse('https://your-api.com/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': googleAuth.idToken,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveAuthToken(data['token']);
      return true;
    }
  } catch (e) {
    rethrow;
  }
}
```

#### Password Reset
```dart
Future<bool> requestPasswordReset(String email) async {
  final response = await http.post(
    Uri.parse('https://your-api.com/auth/forgot-password'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email}),
  );
  
  if (response.statusCode == 200) {
    return true;
  }
  throw 'Password reset request failed';
}
```

---

## Step 5: Test Authentication

### Test Email/Password

1. Run the app:
   ```bash
   flutter run
   ```

2. Sign up with test email
3. Sign in with same credentials
4. Test forgot password flow
5. Test sign out

### Test Google Sign-In

1. Ensure Google credentials are configured
2. Tap "Continue with Google"
3. Select Google account
4. Verify sign-in succeeds

---

## File Structure

```
lib/
├── services/
│   └── auth_service.dart          # Authentication logic
├── screens/
│   ├── login_screen.dart          # Login/Sign up UI
│   └── chat_screen.dart           # Main app (after auth)
├── config/
│   └── google_config.dart         # Google OAuth config
└── main.dart                      # App entry with Provider
```

---

## Security Best Practices

### For Development

- ✅ Use debug keystore for testing
- ✅ Store test credentials securely
- ✅ Use local storage for demo

### For Production

- ✅ Use release keystore (keep safe!)
- ✅ Implement HTTPS for all API calls
- ✅ Use JWT tokens with expiration
- ✅ Hash passwords on backend
- ✅ Implement rate limiting
- ✅ Use secure password reset tokens
- ✅ Implement 2FA (optional)
- ✅ Never log sensitive data
- ✅ Use environment variables for secrets

---

## Environment Variables

Create `.env` file in `services/api/`:

```env
# Google OAuth
GOOGLE_CLIENT_ID=your_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_client_secret

# JWT
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRATION=24h

# Email Service (for password reset)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASSWORD=your_app_password
```

---

## Backend API Endpoints (Required)

Implement these endpoints in your Node.js API:

### POST `/auth/signup`
```json
Request:
{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe"
}

Response:
{
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "name": "John Doe"
  }
}
```

### POST `/auth/signin`
```json
Request:
{
  "email": "user@example.com",
  "password": "password123"
}

Response:
{
  "token": "jwt_token_here",
  "user": { ... }
}
```

### POST `/auth/google`
```json
Request:
{
  "idToken": "google_id_token"
}

Response:
{
  "token": "jwt_token_here",
  "user": { ... }
}
```

### POST `/auth/forgot-password`
```json
Request:
{
  "email": "user@example.com"
}

Response:
{
  "message": "Password reset email sent"
}
```

### POST `/auth/reset-password`
```json
Request:
{
  "token": "reset_token",
  "newPassword": "new_password123"
}

Response:
{
  "message": "Password reset successful"
}
```

---

## Testing Checklist

- [ ] Email sign up works
- [ ] Email sign in works
- [ ] Password validation works (min 8 chars)
- [ ] Email validation works
- [ ] Forgot password email sent
- [ ] Google sign-in works
- [ ] Sign out clears auth state
- [ ] User data persists after sign in
- [ ] User data cleared after sign out
- [ ] Error messages display correctly
- [ ] Loading states show during auth

---

## Troubleshooting

### Google Sign-In Not Working

1. Verify SHA-1 fingerprint matches
2. Check Google Cloud Console credentials
3. Ensure internet permission in manifest
4. Test on physical device (emulator may have issues)

### Password Reset Not Sending

1. Verify email service is configured
2. Check SMTP credentials
3. Test email delivery separately
4. Check spam folder

### Sign In Fails with Valid Credentials

1. Verify backend API is running
2. Check network connectivity
3. Verify JWT token is valid
4. Check token expiration

---

## Next Steps

1. ✅ Set up Google OAuth credentials
2. ✅ Configure Android manifest
3. ✅ Implement backend API endpoints
4. ✅ Test authentication flows
5. ✅ Deploy to production
6. ✅ Monitor auth errors

---

## Resources

- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Provider State Management](https://pub.dev/packages/provider)
- [Firebase Authentication](https://firebase.google.com/docs/auth) (alternative)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)

Good luck! 🚀
