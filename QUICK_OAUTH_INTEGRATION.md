# Quick Google OAuth Integration Checklist

Fast checklist to integrate your Google client secret JSON.

## ✅ Step 1: Extract Client ID from JSON

Your JSON file contains:
```json
{
  "client_id": "XXXXXXXXX.apps.googleusercontent.com",
  ...
}
```

Copy the `client_id` value.

---

## ✅ Step 2: Update Mobile App Config

Edit `lib/config/google_config.dart`:

```dart
static const String debugClientId =
    'PASTE_YOUR_CLIENT_ID_HERE.apps.googleusercontent.com';
```

---

## ✅ Step 3: Secure the JSON File

### Option A: Store on Backend Only (Recommended)

1. Move JSON to `services/api/`
2. Add to `.env`:
   ```env
   GOOGLE_CLIENT_SECRET_JSON=/path/to/google-services.json
   ```
3. Add to `.gitignore` (already done):
   ```
   google-services.json
   client_secret_*.json
   ```

### Option B: Store in Environment Variable

1. Copy entire JSON content
2. Create `.env` file in `services/api/`:
   ```env
   GOOGLE_CLIENT_SECRET='{"type":"service_account",...}'
   ```
3. Never commit `.env`

---

## ✅ Step 4: Verify .gitignore

Check `.gitignore` includes:
```
google-services.json
client_secret_*.json
*.jks
*.keystore
.env
```

---

## ✅ Step 5: Test

### Run Mobile App
```bash
cd apps/mobile
flutter pub get
flutter run
```

### Test Google Sign-In
1. Tap "Continue with Google"
2. Select your Google account
3. Verify sign-in succeeds

---

## ⚠️ Security Reminders

- ✅ Never commit JSON file to git
- ✅ Never commit .env to git
- ✅ Never commit keystores (.jks) to git
- ✅ Only store Client ID in mobile app
- ✅ Store full JSON only on backend
- ✅ Verify tokens on backend, not client

---

## 📋 Files to Check

- [ ] `lib/config/google_config.dart` — Client ID updated
- [ ] `.gitignore` — Includes google-services.json
- [ ] `services/api/.env` — Has JSON path or content
- [ ] `services/api/.env` — NOT committed to git
- [ ] `lib/services/auth_service.dart` — Uses google_sign_in

---

## 🚀 Next Steps

1. ✅ Extract Client ID from JSON
2. ✅ Update google_config.dart
3. ✅ Secure JSON file
4. ✅ Test Google Sign-In
5. ✅ Implement backend verification (see GOOGLE_CLIENT_SECRET_INTEGRATION.md)
6. ✅ Deploy to production

---

## Need Help?

See detailed guide: `GOOGLE_CLIENT_SECRET_INTEGRATION.md`
