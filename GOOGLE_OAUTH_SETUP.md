# Google OAuth 2.0 Setup for Librio

Complete step-by-step guide to set up Google Sign-In for Librio.

## Your Debug Keystore SHA-1 Fingerprint

```
42:13:1B:8F:CB:45:94:3F:B2:3E:D4:B1:39:23:2C:C3:0F:CD:65:C0
```

**Save this fingerprint — you'll need it in Google Cloud Console.**

---

## Step 1: Create Google Cloud Project

### 1.1 Go to Google Cloud Console

1. Visit [Google Cloud Console](https://console.cloud.google.com)
2. Sign in with your Google account
3. Click the project dropdown at the top
4. Click "NEW PROJECT"

### 1.2 Create New Project

- **Project name**: `Librio`
- **Organization**: (leave blank or select yours)
- Click "CREATE"

Wait for the project to be created (1-2 minutes).

---

## Step 2: Enable Google+ API

### 2.1 Enable the API

1. In Google Cloud Console, go to "APIs & Services" > "Library"
2. Search for "Google+ API"
3. Click on "Google+ API"
4. Click "ENABLE"

Wait for it to enable (30 seconds).

---

## Step 3: Create OAuth 2.0 Credentials

### 3.1 Create Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "CREATE CREDENTIALS"
3. Select "OAuth client ID"

### 3.2 Configure OAuth Consent Screen

If prompted, click "CONFIGURE CONSENT SCREEN":

1. **User Type**: Select "External"
2. Click "CREATE"

### 3.3 Fill OAuth Consent Screen

**App information:**
- **App name**: `Librio`
- **User support email**: Your email
- **App logo**: (optional) Upload logo.png

**Developer contact information:**
- **Email addresses**: Your email

Click "SAVE AND CONTINUE"

**Scopes:**
- Click "ADD OR REMOVE SCOPES"
- Search for and select:
  - `email`
  - `profile`
  - `openid`
- Click "UPDATE"
- Click "SAVE AND CONTINUE"

**Test users:**
- Add your test email addresses
- Click "SAVE AND CONTINUE"

Review and click "BACK TO DASHBOARD"

---

## Step 4: Create Android OAuth Credentials

### 4.1 Create Android Client ID

1. Go to "APIs & Services" > "Credentials"
2. Click "CREATE CREDENTIALS"
3. Select "OAuth client ID"
4. Choose "Android"

### 4.2 Fill in Android Details

**Application type**: Android

**Name**: `Librio Debug` (for development)

**Package name**: `com.librio.librio`

**SHA-1 certificate fingerprint**: 
```
42:13:1B:8F:CB:45:94:3F:B2:3E:D4:B1:39:23:2C:C3:0F:CD:65:C0
```

Click "CREATE"

### 4.3 Save Your Client ID

You'll see a dialog with:
- **Client ID**: `XXXXXXXXX.apps.googleusercontent.com`
- **Client Secret**: (not needed for Android)

**Copy and save your Client ID** — you'll need it in the app.

---

## Step 5: Create Production Release Credentials

### 5.1 Generate Release Keystore

When you're ready to publish to Google Play, you'll need a release keystore:

```bash
cd C:\dev\Librio\apps\mobile\android\app

keytool -genkey -v -keystore librio-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias librio-key \
  -storepass YOUR_STORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD
```

### 5.2 Get Release SHA-1

```bash
keytool -list -v -keystore librio-release-key.jks -alias librio-key
```

Copy the SHA-1 fingerprint.

### 5.3 Create Release Android Client ID

Repeat Step 4 but:
- **Name**: `Librio Release`
- **SHA-1 certificate fingerprint**: (paste the release SHA-1)

---

## Step 6: Configure Librio App

### 6.1 Create Google Config File

Create `lib/config/google_config.dart`:

```dart
class GoogleConfig {
  // Debug Client ID (from Step 4)
  static const String debugClientId = 
    'YOUR_DEBUG_CLIENT_ID.apps.googleusercontent.com';
  
  // Release Client ID (from Step 5)
  static const String releaseClientId = 
    'YOUR_RELEASE_CLIENT_ID.apps.googleusercontent.com';
  
  // Web Client ID (for backend verification)
  static const String webClientId = 
    'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
}
```

### 6.2 Update AuthService

Edit `lib/services/auth_service.dart` and update the Google Sign-In initialization:

```dart
import 'package:google_sign_in/google_sign_in.dart';
import '../config/google_config.dart';

Future<bool> signInWithGoogle() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: GoogleConfig.debugClientId,
      scopes: ['email', 'profile'],
    );
    
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return false;
    
    final GoogleSignInAuthentication googleAuth = 
        await googleUser.authentication;
    
    // TODO: Send idToken to backend for verification
    final idToken = googleAuth.idToken;
    
    // Store user data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', googleUser.id);
    await prefs.setString('user_email', googleUser.email);
    await prefs.setString('user_name', googleUser.displayName ?? '');
    await prefs.setString('auth_provider', 'google');
    await prefs.setBool('auth_token', true);
    
    _currentUserId = googleUser.id;
    _currentUserEmail = googleUser.email;
    _currentUserName = googleUser.displayName;
    _isAuthenticated = true;
    
    DebugLogger.success(_tag, 'Google sign in: ${googleUser.email}');
    notifyListeners();
    return true;
  } catch (e, st) {
    DebugLogger.error(_tag, 'Google sign in failed', e, st);
    rethrow;
  }
}
```

---

## Step 7: Test Google Sign-In

### 7.1 Run the App

```bash
cd C:\dev\Librio\apps\mobile
flutter pub get
flutter run
```

### 7.2 Test Sign-In

1. Open the app
2. Go to Login screen
3. Tap "Continue with Google"
4. Select your Google account
5. Verify sign-in succeeds

### 7.3 Troubleshooting

If Google Sign-In fails:

**Error: "10: DEVELOPER_ERROR"**
- SHA-1 fingerprint doesn't match
- Verify fingerprint in Google Cloud Console
- Regenerate debug keystore if needed

**Error: "12: NETWORK_ERROR"**
- Check internet connection
- Ensure Google+ API is enabled
- Wait a few minutes for settings to propagate

**Error: "SIGN_IN_CANCELLED"**
- User cancelled the sign-in
- This is normal, not an error

---

## Step 8: Backend Verification (Important!)

### 8.1 Verify ID Token on Backend

Never trust the client. Always verify the ID token on your backend:

```javascript
// Node.js example
const { OAuth2Client } = require('google-auth-library');

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

async function verifyGoogleToken(idToken) {
  try {
    const ticket = await client.verifyIdToken({
      idToken: idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    
    const payload = ticket.getPayload();
    return {
      userId: payload.sub,
      email: payload.email,
      name: payload.name,
      picture: payload.picture,
    };
  } catch (error) {
    throw new Error('Invalid token');
  }
}
```

### 8.2 Create Backend Endpoint

```javascript
app.post('/auth/google', async (req, res) => {
  try {
    const { idToken } = req.body;
    const user = await verifyGoogleToken(idToken);
    
    // Find or create user in database
    let dbUser = await User.findOne({ email: user.email });
    if (!dbUser) {
      dbUser = await User.create({
        email: user.email,
        name: user.name,
        googleId: user.userId,
        picture: user.picture,
      });
    }
    
    // Create JWT token
    const token = jwt.sign(
      { userId: dbUser._id, email: dbUser.email },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );
    
    res.json({ token, user: dbUser });
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
});
```

---

## Checklist

- [ ] Created Google Cloud Project
- [ ] Enabled Google+ API
- [ ] Created OAuth consent screen
- [ ] Created Android Client ID (debug)
- [ ] Saved debug Client ID
- [ ] Created `lib/config/google_config.dart`
- [ ] Updated `lib/services/auth_service.dart`
- [ ] Tested Google Sign-In on device
- [ ] Created backend verification endpoint
- [ ] Tested end-to-end sign-in flow

---

## Important Notes

### For Development
- Use debug keystore SHA-1
- Use debug Client ID
- Test on physical device (emulator may have issues)

### For Production
- Generate release keystore
- Get release SHA-1
- Create release Client ID
- Update `google_config.dart` with release Client ID
- Verify token on backend

### Security
- Never expose Client Secret in mobile app
- Always verify ID token on backend
- Use HTTPS for all API calls
- Implement token expiration
- Refresh tokens before expiration

---

## Resources

- [Google Cloud Console](https://console.cloud.google.com)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Verify ID Tokens](https://developers.google.com/identity/sign-in/web/backend-auth)

---

## Next Steps

1. ✅ Set up Google Cloud Project
2. ✅ Create OAuth credentials
3. ✅ Configure Librio app
4. ✅ Test Google Sign-In
5. ✅ Implement backend verification
6. ✅ Deploy to production

Good luck! 🚀
