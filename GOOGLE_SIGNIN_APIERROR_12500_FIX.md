# Google Sign-In Error: ApiException 12500 — Fix Guide

## Error Message
```
com.google.android.gms.common.api.ApiException: 12500
```

## What This Means
Error 12500 is a **configuration mismatch** between:
- Your app's package name and SHA-1 fingerprint
- Google Cloud Console OAuth credentials
- Supabase configuration

## Root Causes

### 1. **SHA-1 Fingerprint Mismatch** (Most Common)

The SHA-1 fingerprint in Google Cloud Console doesn't match your actual app's fingerprint.

**Fix:**

1. Get your actual SHA-1 fingerprint:
   ```bash
   cd apps/mobile/android
   ./gradlew signingReport
   ```

2. Look for the SHA1 under `debug` or `debugAndroidTest`:
   ```
   SHA1: 42:13:1B:8F:CB:45:94:3F:B2:3E:D4:B1:39:23:2C:C3:0F:CD:65:C0
   ```

3. Go to [Google Cloud Console](https://console.cloud.google.com)
4. Select your project
5. Go to **APIs & Services** → **Credentials**
6. Click your **Android** OAuth client
7. Update the **SHA-1 certificate fingerprint** to match
8. Click **Save**

### 2. **Package Name Mismatch**

The package name in Google Cloud doesn't match your app.

**Fix:**

1. Your app's package name is: `com.librio.librio`
2. In Google Cloud Console:
   - Go to **Credentials** → **Android** OAuth client
   - Verify **Package name** is exactly: `com.librio.librio`
   - If different, create a new credential with the correct package name

### 3. **Web Client Secret Not in Supabase**

Google Sign-In requires Supabase to be configured with your Web Client Secret.

**Fix:**

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select project: `itrlclzfgwicwhskepnf`
3. Go to **Authentication** → **Providers** → **Google**
4. Verify:
   - ✅ **Enable Sign in with Google** is ON
   - ✅ **Client IDs** field has your Web Client ID
   - ✅ **Client Secret** field has your Web Client Secret
5. Click **Save**

### 4. **Google Play Services Outdated**

Old version of Google Play Services can cause compatibility issues.

**Fix:**

1. On your device, go to **Settings** → **Apps**
2. Search for **"Google Play Services"**
3. Tap **Update** (if available)
4. Wait for update to complete
5. Restart device

## Quick Checklist

- [ ] SHA-1 fingerprint in Google Cloud matches `./gradlew signingReport` output
- [ ] Package name in Google Cloud is `com.librio.librio`
- [ ] Android Client ID in `google_config.dart` is correct
- [ ] Web Client Secret is in Supabase
- [ ] Google Play Services is up-to-date on device
- [ ] Device has internet connection

## Testing

After fixing:

1. Rebuild the app:
   ```bash
   cd apps/mobile
   flutter clean
   flutter pub get
   flutter run
   ```

2. Tap "Sign in with Google"

3. Check console logs:
   ```
   🔍 [LIBRIO] ✅ [AuthService] Google sign in successful
   ```

## If Still Not Working

1. **Try on different device** — Some devices have Google Play Services issues
2. **Check Google Cloud Console** — Verify all credentials are correct
3. **Clear app data:**
   ```bash
   adb shell pm clear com.librio.librio
   ```
4. **Restart device** — Sometimes helps with Google Play Services

## Email Confirmation Issue

You may also see: **"Email not confirmed"**

This is normal! Supabase requires email confirmation before sign-in.

**Fix:**
1. Check your email inbox for a confirmation link from Supabase
2. Click the link to confirm your email
3. Then sign in again

---

**Most likely cause: SHA-1 fingerprint mismatch. Check that first!** 🎯
