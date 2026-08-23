# Google Sign-In Network Error — Troubleshooting

## Error Message
"Network error. Please check your connection and try again."

## Common Causes & Solutions

### 1. **Device Internet Connection**

**Check:**
- Is WiFi connected and working?
- Can you open a web browser and access websites?
- Try opening Google.com in the browser

**If no internet:**
- Connect to WiFi
- Check WiFi password
- Restart WiFi router
- Try mobile data instead

---

### 2. **Google Play Services Not Installed**

**This is the most common cause on Android devices.**

**Check:**
1. Go to **Settings** → **Apps**
2. Search for **"Google Play Services"**
3. If not found or outdated, update it:
   - Open **Google Play Store**
   - Search for **"Google Play Services"**
   - Click **Update** (if available)
   - Wait for update to complete

**If still not working:**
- Restart your device
- Clear cache: Settings → Apps → Google Play Services → Storage → Clear Cache
- Try Google Sign-In again

---

### 3. **Google Account Not Configured on Device**

**Check:**
1. Go to **Settings** → **Accounts**
2. Look for a **Google account**
3. If none exists, add one:
   - Tap **Add account**
   - Select **Google**
   - Sign in with your Google account
   - Accept permissions

---

### 4. **Firewall or Network Blocking**

**If on corporate/school WiFi:**
- The network may block Google authentication
- Try using mobile data instead
- Ask your network administrator to allow Google authentication

**If using VPN:**
- Disable VPN temporarily
- Try Google Sign-In again
- Some VPNs block authentication services

---

### 5. **Supabase Not Configured**

**This is likely the issue if you haven't added the Web Client Secret yet.**

**Check:**
1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select project: `itrlclzfgwicwhskepnf`
3. Go to **Authentication** → **Providers**
4. Click **Google** to expand
5. Verify:
   - ✅ **Enable Sign in with Google** is toggled ON
   - ✅ **Client IDs** field is filled
   - ✅ **Client Secret** field is filled

**If Client Secret is missing:**
- See `GOOGLE_OAUTH_CONFIGURATION.md` for instructions
- Add your Web Client Secret from Google Cloud Console
- Click **Save**

---

### 6. **Google Cloud Project Issues**

**Check:**
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project
3. Go to **APIs & Services** → **Library**
4. Search for **"Google+ API"**
5. Verify it's **Enabled** (should show a blue checkmark)

**If not enabled:**
- Click on **Google+ API**
- Click **Enable**
- Wait for it to enable

---

### 7. **Client ID Mismatch**

**Verify the Android Client ID is correct:**

1. In Flutter app: `apps/mobile/lib/config/google_config.dart`
   - Should be: `123074140690-s3ernbne0bfeffprnokhmbnn6o8jkr25.apps.googleusercontent.com`

2. In Google Cloud Console:
   - Go to **APIs & Services** → **Credentials**
   - Find your **Android** OAuth client
   - Copy the **Client ID**
   - Compare with the one in `google_config.dart`

**If different:**
- Update `google_config.dart` with the correct Client ID
- Rebuild the app: `flutter clean && flutter pub get && flutter run`

---

## Quick Fix Checklist

- [ ] Device has internet connection (WiFi or mobile data)
- [ ] Google Play Services is installed and up-to-date
- [ ] Google account is added to device (Settings → Accounts)
- [ ] Supabase Google provider is enabled
- [ ] Supabase has Web Client Secret filled in
- [ ] Google+ API is enabled in Google Cloud Console
- [ ] Android Client ID in `google_config.dart` matches Google Cloud
- [ ] Not using VPN or corporate firewall that blocks Google

---

## Testing Steps

1. **Verify internet:**
   ```bash
   # On device, open browser and go to google.com
   # Should load successfully
   ```

2. **Check Google Play Services:**
   - Settings → Apps → Google Play Services → Check version

3. **Update Supabase:**
   - Add Web Client Secret if missing
   - Wait 30 seconds for changes to propagate

4. **Rebuild app:**
   ```bash
   cd apps/mobile
   flutter clean
   flutter pub get
   flutter run
   ```

5. **Test Google Sign-In:**
   - Tap "Sign in with Google" button
   - Check console logs for errors

---

## Console Logs

When you run the app, check for these logs:

**Success:**
```
🔍 [LIBRIO] INFO [AuthService] Starting Google Sign-In with client ID: ...
🔍 [LIBRIO] ✅ [AuthService] Google sign in successful
```

**Network Error:**
```
🔍 [LIBRIO] ERROR [AuthService] Network error during Google sign-in
```

**Auth Error:**
```
🔍 [LIBRIO] ERROR [AuthService] Supabase Google sign-in error: ...
```

---

## If Still Not Working

1. **Check device logs:**
   ```bash
   flutter logs
   ```
   Look for any error messages

2. **Try on different network:**
   - Switch from WiFi to mobile data (or vice versa)
   - Try on a different WiFi network

3. **Restart everything:**
   - Restart device
   - Restart WiFi router
   - Rebuild app

4. **Verify Supabase is working:**
   - Try email/password sign-up first
   - If that works, Supabase is fine
   - If that fails, Supabase might be down

---

## Most Likely Cause

**99% of the time, the issue is:**
1. **Web Client Secret not added to Supabase** (most common)
2. **Google Play Services not installed/updated**
3. **Device not connected to internet**

Start with these three! 🎯
