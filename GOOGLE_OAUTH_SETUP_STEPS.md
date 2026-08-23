# Google OAuth Setup for Supabase — Step by Step

## Your Supabase Project
- **Project ID:** `itrlclzfgwicwhskepnf`
- **Callback URL:** `https://itrlclzfgwicwhskepnf.supabase.co/auth/v1/callback`

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Click **Select a Project** → **New Project**
3. Name: `Librio` (or similar)
4. Click **Create**
5. Wait for project to be created

## Step 2: Enable Google+ API

1. In Google Cloud Console, go to **APIs & Services** → **Library**
2. Search for `Google+ API`
3. Click on it
4. Click **Enable**
5. Wait for it to enable

## Step 3: Create OAuth 2.0 Credentials

### For Web (Supabase callback)

1. Go to **APIs & Services** → **Credentials**
2. Click **+ Create Credentials** → **OAuth client ID**
3. If prompted, click **Configure Consent Screen** first:
   - User Type: **External**
   - Fill in app name: `Librio`
   - Add your email
   - Add scopes: `email`, `profile`, `openid`
   - Save and continue
4. Back to **Create OAuth client ID**:
   - Application type: **Web application**
   - Name: `Librio Web`
   - **Authorized redirect URIs** → Add:
     ```
     https://itrlclzfgwicwhskepnf.supabase.co/auth/v1/callback
     ```
   - Click **Create**
5. **Copy the Client ID and Client Secret** — you'll need these for Supabase

### For Android (Flutter app)

1. Go to **APIs & Services** → **Credentials**
2. Click **+ Create Credentials** → **OAuth client ID**
3. Application type: **Android**
4. Name: `Librio Android`
5. Package name: `com.librio.librio`
6. **SHA-1 certificate fingerprint**: Get this from:
   ```bash
   cd apps/mobile/android
   ./gradlew signingReport
   ```
   Look for the SHA1 under `debug` or `debugAndroidTest`
7. Click **Create**
8. **Copy the Client ID** — you'll need this for `google_config.dart`

## Step 4: Add Credentials to Supabase

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select project: `itrlclzfgwicwhskepnf`
3. Go to **Authentication** → **Providers**
4. Find **Google** and click to expand
5. Toggle **Enable Sign in with Google** to ON
6. Fill in:
   - **Client IDs**: Paste your Web Client ID (from Step 3)
   - **Client Secret**: Paste your Web Client Secret (from Step 3)
7. Click **Save**

## Step 5: Update Flutter App

1. Open `apps/mobile/lib/config/google_config.dart`
2. Update:
   ```dart
   static const String debugClientId = 'YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com';
   ```
   Replace with your Android Client ID from Step 3

3. Save the file

## Step 6: Test

1. Rebuild the app:
   ```bash
   cd apps/mobile
   flutter clean
   flutter pub get
   flutter run
   ```

2. On the login screen, click **Sign in with Google**

3. Check console logs:
   ```
   🔍 [LIBRIO] INFO [AuthService] Starting Google Sign-In with client ID: ...
   🔍 [LIBRIO] ✅ [AuthService] Google sign in successful
   ```

## Troubleshooting

### "Supabase Google sign-in failed"
- Check that Web Client ID is in Supabase (not Android Client ID)
- Verify Client Secret is correct
- Make sure Google+ API is enabled

### "Failed to get Google ID token"
- Check that Android Client ID is in `google_config.dart`
- Verify SHA-1 fingerprint matches Google Cloud Console
- Make sure package name is `com.librio.librio`

### "Network error"
- Check internet connection
- Verify callback URL is correct in Supabase
- Check if Google services are accessible in your region

## Summary

| Where | What | From |
|-------|------|------|
| Supabase Google Provider | Client IDs | Google Cloud (Web) |
| Supabase Google Provider | Client Secret | Google Cloud (Web) |
| `google_config.dart` | debugClientId | Google Cloud (Android) |
| Google Cloud | SHA-1 fingerprint | `./gradlew signingReport` |
| Google Cloud | Package name | `com.librio.librio` |

---

**Once you complete these steps, Google Sign-In will work! 🎉**
