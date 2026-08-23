# Google OAuth Configuration — Librio

## Current Status

✅ **Android Client ID configured in Flutter app**
- File: `apps/mobile/lib/config/google_config.dart`
- Client ID: `123074140690-s3ernbne0bfeffprnokhmbnn6o8jkr25.apps.googleusercontent.com`

⏳ **Pending: Add Client Secret to Supabase**

---

## Next Step: Configure Supabase

You need to add your **Web Client Secret** to Supabase.

### Where to Get It

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Navigate to **APIs & Services** → **Credentials**
3. Find your **Web application** OAuth client (the one you created for Supabase)
4. Click on it to view details
5. Copy the **Client Secret** (looks like: `GOCSPX-...`)

### Where to Add It in Supabase

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select project: `itrlclzfgwicwhskepnf`
3. Navigate to **Authentication** → **Providers**
4. Click on **Google** to expand
5. Fill in:
   - **Client IDs**: Your Web Client ID (from Google Cloud)
   - **Client Secret**: Your Web Client Secret (from Google Cloud)
6. Click **Save**

---

## Configuration Summary

| Component | Value | Status |
|-----------|-------|--------|
| **Flutter App** | Android Client ID | ✅ Configured |
| **Supabase** | Web Client ID | ⏳ Needs setup |
| **Supabase** | Web Client Secret | ⏳ Needs setup |
| **Google Cloud** | Google+ API | ✅ Should be enabled |

---

## Testing

Once Supabase is configured:

1. Rebuild the app:
   ```bash
   cd apps/mobile
   flutter clean
   flutter pub get
   flutter run
   ```

2. On login screen, tap **Sign in with Google**

3. Check console for success:
   ```
   🔍 [LIBRIO] ✅ [AuthService] Google sign in successful
   ```

---

## Security Notes

⚠️ **IMPORTANT:**
- ✅ Android Client ID is safe in Flutter code (it's public)
- ✅ Web Client Secret is safe in Supabase (it's private backend)
- ❌ Never commit Client Secret to git
- ❌ Never put Client Secret in Flutter code
- ❌ Never expose Client Secret in logs

---

## Files Modified

- `apps/mobile/lib/config/google_config.dart` — Updated with Android Client ID

---

## Next Actions

1. **Add Web Client Secret to Supabase** (see instructions above)
2. **Test Google Sign-In** on your device
3. **Check logs** for any errors
4. **Verify** that sign-in creates a user in Supabase

---

## Troubleshooting

If Google Sign-In still doesn't work after Supabase setup:

1. Check console logs:
   ```bash
   flutter logs
   ```

2. Look for errors like:
   - "Supabase Google sign-in failed" → Client Secret issue
   - "Failed to get Google ID token" → Android Client ID issue
   - "Network error" → Connection issue

3. See `GOOGLE_SIGNIN_TROUBLESHOOTING.md` for detailed debugging

---

**Status: Ready for Supabase configuration!** 🚀
