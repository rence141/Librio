# Google Sign-In Troubleshooting Guide

## Overview

Google Sign-In in Librio uses:
- **google_sign_in** (^6.2.0) — Flutter plugin for Google authentication
- **Supabase Auth** — Backend authentication with `signInWithIdToken`
- **Google Cloud Console** — OAuth 2.0 credentials

## Common Issues & Solutions

### 1. **"Google sign-in cancelled" Error**

**Cause:** User cancelled the Google sign-in dialog.

**Solution:** This is normal behavior. The app logs it and returns to login screen.

---

### 2. **"Failed to get Google ID token" Error**

**Cause:** Google authentication succeeded but ID token wasn't generated.

**Possible fixes:**
- Ensure Google Sign-In scopes include `email` and `profile`
- Check that `google_sign_in` package is properly initialized
- Verify Google Cloud Console OAuth 2.0 credentials

**Check in code:**
```dart
// apps/mobile/lib/config/google_config.dart
static const List<String> scopes = [
  'email',
  'profile',
];
```

---

### 3. **"Supabase Google sign-in failed" Error**

**Cause:** Supabase rejected the Google ID token.

**Possible causes:**
- Google Client ID mismatch
- Supabase not configured for Google OAuth
- ID token expired or invalid

**Solutions:**

#### A. Verify Supabase Google OAuth Setup

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project: `itrlclzfgwicwhskepnf`
3. Navigate to **Authentication** → **Providers**
4. Enable **Google** provider
5. Add your Google OAuth credentials:
   - **Client ID**: From Google Cloud Console
   - **Client Secret**: From Google Cloud Console

#### B. Get Google OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project (or create one)
3. Enable **Google+ API**
4. Go to **Credentials** → **Create Credentials** → **OAuth 2.0 Client ID**
5. Select **Android** (for mobile testing)
6. Add your app's package name: `com.librio.librio`
7. Add your **SHA-1 fingerprint** (see below)
8. Create the credential and copy the **Client ID**

#### C. Get Your Android SHA-1 Fingerprint

**For debug builds:**
```bash
cd apps/mobile/android
./gradlew signingReport
```

Look for `SHA1` under `debugAndroidTest` or `debug`.

**For release builds:**
```bash
keytool -list -v -keystore path/to/librio-release-key.jks
```

#### D. Update google_config.dart

```dart
// apps/mobile/lib/config/google_config.dart
class GoogleConfig {
  static const String debugClientId = 'YOUR_DEBUG_CLIENT_ID.apps.googleusercontent.com';
  static const String webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
  // ...
}
```

---

### 4. **Network Error During Google Sign-In**

**Error:** "Network error. Please check your connection and try again."

**Cause:** No internet connection or network timeout.

**Solutions:**
- Check device internet connection
- Try again with stable WiFi
- Check if Google services are accessible in your region

---

### 5. **Google Sign-In Button Not Responding**

**Cause:** Multiple possible issues.

**Debug steps:**
1. Check console logs for errors:
   ```
   🔍 [LIBRIO] INFO [LoginScreen] Starting Google Sign-In
   ```

2. If no logs appear, check if `google_sign_in` is properly initialized

3. Verify permissions in `AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
   ```

---

## Debug Logging

The app now logs detailed information about Google Sign-In. Check the console for:

```
🔍 [LIBRIO] INFO [AuthService] Starting Google Sign-In with client ID: ...
🔍 [LIBRIO] INFO [AuthService] Requesting Google sign-in...
🔍 [LIBRIO] INFO [AuthService] Google user signed in: user@gmail.com
🔍 [LIBRIO] INFO [AuthService] Retrieved Google authentication tokens
🔍 [LIBRIO] INFO [AuthService] Signing in to Supabase with Google ID token...
🔍 [LIBRIO] ✅ [AuthService] Google sign in successful: user@gmail.com
```

If you see errors, they will be logged with full context.

---

## Testing Checklist

- [ ] Internet connection is active
- [ ] Google Client ID is correct in `google_config.dart`
- [ ] SHA-1 fingerprint matches Google Cloud Console
- [ ] Supabase Google provider is enabled
- [ ] Google OAuth credentials are in Supabase
- [ ] Device has Google Play Services installed
- [ ] App has `INTERNET` permission in `AndroidManifest.xml`

---

## Quick Reset

If Google Sign-In is stuck:

1. **Clear app data:**
   ```bash
   adb shell pm clear com.librio.librio
   ```

2. **Rebuild and reinstall:**
   ```bash
   cd apps/mobile
   flutter clean
   flutter pub get
   flutter run
   ```

3. **Check logs:**
   ```bash
   flutter logs
   ```

---

## Contacts & Resources

- **Google Cloud Console:** https://console.cloud.google.com
- **Supabase Dashboard:** https://app.supabase.com
- **Flutter google_sign_in:** https://pub.dev/packages/google_sign_in
- **Supabase Auth Docs:** https://supabase.com/docs/guides/auth

---

## Recent Changes

**Improved error handling:**
- Added specific handling for `AuthRetryableFetchException` (network errors)
- Better error messages for users
- Detailed debug logging at each step
- Fallback to username if displayName unavailable

**Files modified:**
- `lib/services/auth_service.dart` — Enhanced `signInWithGoogle()` with logging
- `lib/screens/login_screen.dart` — Better error display and handling
