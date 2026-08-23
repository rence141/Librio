# Supabase Credentials Setup for Librio

## Issue
The app is trying to connect to `your_project.supabase.co` instead of your actual Supabase project.

## Solution: Add Your Supabase Credentials

### Step 1: Get Your Supabase URL and Anon Key

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project: `itrlclzfgwicwhskepnf`
3. Go to **Project Settings** (gear icon, bottom left)
4. Click **API** tab
5. You'll see:
   - **Project URL**: `https://itrlclzfgwicwhskepnf.supabase.co`
   - **Anon public key**: (long string starting with `eyJ...`)

### Step 2: Update Flutter App

Open `apps/mobile/lib/main.dart` and find this section:

```dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://itrlclzfgwicwhskepnf.supabase.co'),
  publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'YOUR_ANON_KEY_HERE'),
  debug: kDebugMode,
);
```

Replace `YOUR_ANON_KEY_HERE` with your actual Anon public key from Supabase.

**Example:**
```dart
publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0cmxjbHpmemd3aWN3aHNrZXBuZiIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzIzMDI2NTc4LCJleHAiOjE4ODA3OTM1Nzh9.abc123xyz'),
```

### Step 3: Rebuild App

```bash
cd apps/mobile
flutter clean
flutter pub get
flutter run
```

---

## Current Status

✅ **Supabase URL:** `https://itrlclzfgwicwhskepnf.supabase.co` (already set)

⏳ **Anon Key:** Needs to be added from your Supabase dashboard

---

## Where to Find Credentials

| Item | Location |
|------|----------|
| **Project URL** | Supabase Dashboard → Project Settings → API |
| **Anon Key** | Supabase Dashboard → Project Settings → API |
| **Project ID** | `itrlclzfgwicwhskepnf` |

---

## Security Note

⚠️ The Anon Key is **public** and safe to include in the Flutter app code. It's designed to be exposed in client applications.

The Anon Key only allows:
- User authentication
- Public database access (based on RLS policies)

It **cannot**:
- Access admin functions
- Bypass Row Level Security
- Modify database schema

---

## Testing

After adding the credentials:

1. Rebuild the app
2. Try signing up with email/password
3. Check console logs:
   ```
   🔍 [LIBRIO] ✅ [AuthService] User signed up: your@email.com
   ```

4. If you see this, Supabase is working! ✅

---

## Troubleshooting

**Still getting "Failed host lookup"?**
- Double-check the Anon Key is correct
- Make sure there are no extra spaces
- Rebuild the app: `flutter clean && flutter pub get && flutter run`

**Getting "Invalid API key"?**
- The Anon Key format is wrong
- Copy it again from Supabase dashboard
- Make sure it starts with `eyJ...`

---

## Next Steps

1. ✅ Add Anon Key to `main.dart`
2. ✅ Rebuild and test email/password sign-up
3. ✅ Test Google Sign-In (if Supabase Web Client Secret is added)
4. ✅ Test context window tracking

---

**Once this is done, all authentication will work!** 🎉
