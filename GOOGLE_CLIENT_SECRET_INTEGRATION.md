# Google Client Secret JSON Integration

Guide to properly integrate your Google OAuth client secret JSON file.

## ⚠️ Important Security Notes

**NEVER commit the client secret JSON to git!**

The JSON file contains sensitive credentials that should be:
- Stored securely on your backend server only
- Never included in mobile app code
- Never committed to version control
- Only used for server-side token verification

---

## Step 1: Extract Client ID from JSON

Your `google-services.json` or OAuth JSON contains:

```json
{
  "type": "service_account",
  "project_id": "librio-xxxxx",
  "private_key_id": "...",
  "private_key": "...",
  "client_email": "...",
  "client_id": "YOUR_CLIENT_ID.apps.googleusercontent.com",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "..."
}
```

### Extract Your Client ID

Find the `client_id` field. It looks like:
```
YOUR_CLIENT_ID.apps.googleusercontent.com
```

---

## Step 2: Update App Configuration

### 2.1 Update google_config.dart

Edit `lib/config/google_config.dart`:

```dart
class GoogleConfig {
  /// Debug Client ID (from your JSON file)
  static const String debugClientId =
      'YOUR_CLIENT_ID.apps.googleusercontent.com';  // ← Paste here

  /// Release Client ID (for production)
  static const String releaseClientId =
      'YOUR_RELEASE_CLIENT_ID.apps.googleusercontent.com';

  /// Web Client ID (for backend verification)
  static const String webClientId =
      'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

  static const List<String> scopes = ['email', 'profile'];
  
  static const String debugSha1 =
      '42:13:1B:8F:CB:45:94:3F:B2:3E:D4:B1:39:23:2C:C3:0F:CD:65:C0';
}
```

---

## Step 3: Store Client Secret Securely (Backend Only)

### 3.1 Backend Setup

**IMPORTANT**: Only store the full JSON on your backend server.

Create `.env` file in `services/api/`:

```env
# Google OAuth (NEVER commit this!)
GOOGLE_CLIENT_SECRET_JSON=/path/to/google-services.json
GOOGLE_CLIENT_ID=YOUR_CLIENT_ID.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=YOUR_CLIENT_SECRET
```

Add to `.gitignore`:

```
.env
google-services.json
client_secret_*.json
```

### 3.2 Backend Implementation (Node.js)

```javascript
// services/api/src/auth/google.js
const fs = require('fs');
const { OAuth2Client } = require('google-auth-library');

// Load from environment variable
const clientSecretPath = process.env.GOOGLE_CLIENT_SECRET_JSON;
const clientSecret = JSON.parse(fs.readFileSync(clientSecretPath, 'utf8'));

const oauth2Client = new OAuth2Client(
  clientSecret.client_id,
  clientSecret.client_secret,
  'http://localhost:3000/auth/google/callback'
);

// Verify ID token from mobile app
async function verifyGoogleToken(idToken) {
  try {
    const ticket = await oauth2Client.verifyIdToken({
      idToken: idToken,
      audience: clientSecret.client_id,
    });
    
    const payload = ticket.getPayload();
    return {
      userId: payload.sub,
      email: payload.email,
      name: payload.name,
      picture: payload.picture,
    };
  } catch (error) {
    throw new Error('Invalid Google token');
  }
}

module.exports = { verifyGoogleToken };
```

### 3.3 Backend API Endpoint

```javascript
// services/api/src/routes/auth.js
const express = require('express');
const router = express.Router();
const { verifyGoogleToken } = require('../auth/google');
const User = require('../models/User');
const jwt = require('jsonwebtoken');

router.post('/auth/google', async (req, res) => {
  try {
    const { idToken } = req.body;
    
    // Verify token on backend (IMPORTANT!)
    const googleUser = await verifyGoogleToken(idToken);
    
    // Find or create user
    let user = await User.findOne({ email: googleUser.email });
    if (!user) {
      user = await User.create({
        email: googleUser.email,
        name: googleUser.name,
        googleId: googleUser.userId,
        picture: googleUser.picture,
        provider: 'google',
      });
    }
    
    // Create JWT token
    const token = jwt.sign(
      { userId: user._id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );
    
    res.json({
      token,
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        picture: user.picture,
      },
    });
  } catch (error) {
    res.status(401).json({ error: error.message });
  }
});

module.exports = router;
```

---

## Step 4: Update Mobile App to Send ID Token

### 4.1 Update AuthService

Edit `lib/services/auth_service.dart`:

```dart
Future<bool> signInWithGoogle() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: GoogleConfig.debugClientId,
      scopes: GoogleConfig.scopes,
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw 'Google sign-in cancelled';
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw 'Failed to get ID token';
    }

    // Send ID token to backend for verification
    final response = await http.post(
      Uri.parse('https://your-api.com/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Store JWT token from backend
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token']);
      await prefs.setString('user_id', data['user']['id']);
      await prefs.setString('user_email', data['user']['email']);
      await prefs.setString('user_name', data['user']['name']);
      await prefs.setString('auth_provider', 'google');

      _currentUserId = data['user']['id'];
      _currentUserEmail = data['user']['email'];
      _currentUserName = data['user']['name'];
      _isAuthenticated = true;

      DebugLogger.success(_tag, 'Google sign in: ${data['user']['email']}');
      notifyListeners();
      return true;
    } else {
      throw 'Backend authentication failed';
    }
  } catch (e, st) {
    DebugLogger.error(_tag, 'Google sign in failed', e, st);
    rethrow;
  }
}
```

---

## Step 5: Security Checklist

### Mobile App (lib/config/google_config.dart)
- ✅ Only contains Client ID (public)
- ✅ No private keys
- ✅ No client secrets
- ✅ Safe to commit to git

### Backend Server (services/api/.env)
- ✅ Contains full JSON file
- ✅ Added to .gitignore
- ✅ Never committed to git
- ✅ Stored securely on server
- ✅ Used only for token verification

### API Communication
- ✅ Mobile sends ID token to backend
- ✅ Backend verifies token
- ✅ Backend returns JWT token
- ✅ Mobile stores JWT for future requests
- ✅ All requests use HTTPS

---

## Step 6: Test Integration

### 6.1 Start Backend Server

```bash
cd C:\dev\Librio\services\api
npm install
npm run dev
```

### 6.2 Update API URL

Edit `lib/config/google_config.dart`:

```dart
class GoogleConfig {
  static const String apiBaseUrl = 'http://localhost:3000';  // Dev
  // static const String apiBaseUrl = 'https://api.librio.app';  // Prod
}
```

### 6.3 Test Google Sign-In

```bash
cd C:\dev\Librio\apps\mobile
flutter run
```

1. Tap "Continue with Google"
2. Select account
3. Verify sign-in succeeds
4. Check backend logs for token verification

---

## File Structure

```
Librio/
├── apps/mobile/
│   └── lib/
│       └── config/
│           └── google_config.dart          # Public config only
│
├── services/api/
│   ├── .env                                # NEVER commit!
│   ├── .gitignore                          # Includes .env
│   ├── src/
│   │   ├── auth/
│   │   │   └── google.js                   # Token verification
│   │   └── routes/
│   │       └── auth.js                     # API endpoints
│   └── google-services.json                # NEVER commit!
│
└── .gitignore
    ├── .env
    ├── google-services.json
    └── client_secret_*.json
```

---

## Troubleshooting

### "Invalid Client ID"
- Verify Client ID matches in google_config.dart
- Check SHA-1 fingerprint matches in Google Cloud Console
- Wait 5-10 minutes for settings to propagate

### "Token verification failed"
- Verify backend has correct google-services.json
- Check JWT_SECRET is set in .env
- Verify API endpoint is correct

### "Backend authentication failed"
- Check backend server is running
- Verify API URL is correct
- Check network connectivity
- Review backend logs

---

## Production Deployment

### 1. Generate Release Keystore
```bash
keytool -genkey -v -keystore librio-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias librio-key
```

### 2. Get Release SHA-1
```bash
keytool -list -v -keystore librio-release-key.jks -alias librio-key
```

### 3. Create Release Client ID
- Go to Google Cloud Console
- Create new Android OAuth credentials
- Use release SHA-1
- Copy Client ID

### 4. Update Config
```dart
static const String releaseClientId =
    'YOUR_RELEASE_CLIENT_ID.apps.googleusercontent.com';
```

### 5. Deploy Backend
- Set environment variables on server
- Ensure google-services.json is secure
- Use HTTPS for all API calls
- Set CORS properly

---

## Resources

- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Verify ID Tokens](https://developers.google.com/identity/sign-in/web/backend-auth)
- [google_sign_in Package](https://pub.dev/packages/google_sign_in)
- [Google Cloud Console](https://console.cloud.google.com)

---

## Summary

✅ Client ID → Mobile app (public)
✅ Full JSON → Backend server only (secret)
✅ ID Token → Sent from mobile to backend
✅ JWT Token → Returned from backend to mobile
✅ All verified on backend (never trust client)

Good luck! 🚀
