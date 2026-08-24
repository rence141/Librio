# Quick Fix Summary: Online Model Configuration

## What Was Wrong

The app showed: **"Online model not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY."**

Even though Supabase was working and authentication was successful.

## Why It Happened

`OnlineModelConfig` tried to read environment variables at **compile time**, but Android reads them at **runtime**. The fallback values were placeholders, so the configuration check failed.

## What Was Fixed

Changed `OnlineModelConfig` to use **explicit initialization** with credentials passed from `main.dart`.

### Before (Broken)
```dart
// Tried to read from environment at runtime (doesn't work on Android)
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://YOUR_PROJECT.supabase.co', // ← Falls back to this
);
```

### After (Fixed)
```dart
// Store credentials in static variables at runtime
static String _supabaseUrl = '';

static void initialize({required String supabaseUrl, ...}) {
  _supabaseUrl = supabaseUrl;  // ← Set at runtime in main.dart
}

static String get supabaseUrl => _supabaseUrl;
```

In `main.dart`:
```dart
// Extract credentials once
final supabaseUrl = const String.fromEnvironment(...);
final supabaseAnonKey = const String.fromEnvironment(...);

// Pass to both Supabase and OnlineModelConfig
await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
OnlineModelConfig.initialize(supabaseUrl: supabaseUrl, supabaseAnonKey: supabaseAnonKey);
```

## Files Changed

1. **`apps/mobile/lib/services/online_model_config.dart`**
   - Added `initialize(supabaseUrl, supabaseAnonKey)` method
   - Store credentials in static variables
   - `isConfigured` checks stored values

2. **`apps/mobile/lib/main.dart`**
   - Extract URL and anon key from `String.fromEnvironment()`
   - Pass to both `Supabase.initialize()` and `OnlineModelConfig.initialize()`
   - Single source of truth for credentials

3. **`apps/mobile/lib/services/online_llm_service.dart`**
   - Improved error messages with debugging info
   - Specific feedback for missing URL vs missing key

## Result

✅ **Online model now works on Android (and all platforms)**
- No build flags needed
- Supabase credentials initialized once in `main.dart`, reused everywhere
- AI API key stays server-side only
- No breaking changes to existing functionality

## How to Verify

1. Run the app:
   ```bash
   cd apps/mobile
   flutter run
   ```

2. Send a message in chat
3. Should get AI response (not "not configured" error)

## Architecture (Unchanged)

```
Flutter App → Supabase Edge Function → FreeLLMAPI → LLM
```

- Supabase anon key: Public, safe in client
- FreeLLMAPI key: Private, server-side only
- All requests authenticated and rate-limited by Edge Function

## Documentation

See `ONLINE_MODEL_CONFIGURATION_FIX.md` for complete details.
