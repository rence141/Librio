# Supabase Edge Function Deployment Guide

## Architecture

```
Flutter / Android App
        │
        │ HTTPS (with auth token)
        ▼
Supabase Edge Function (/functions/v1/ai-chat)
        │
        │ Authentication (Supabase Auth)
        │ Rate Limit Check (ai_usage table)
        │ System Prompt Injection
        │ Server-side API request
        ▼
FreeLLMAPI (https://freellmapi.co/v1)
        │
        ▼
LLM Model (Gemini, Llama, etc.)
```

## Files

| File | Purpose |
|------|---------|
| `supabase/functions/ai-chat/index.ts` | Edge Function (Deno) |
| `supabase/migrations/001_ai_usage.sql` | Database migration for rate limiting |
| `apps/mobile/lib/services/online_model_config.dart` | Flutter config (Supabase URL + anon key) |
| `apps/mobile/lib/services/online_llm_service.dart` | Flutter AI service (calls Edge Function) |
| `apps/mobile/lib/config/supabase_config.dart` | Supabase config constants |

## Step 1: Install Supabase CLI

```bash
npm install -g supabase
```

## Step 2: Link to Your Supabase Project

```bash
cd C:\dev\Librio
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

Get your project ref from: Supabase Dashboard > Project Settings > General

## Step 3: Run Database Migration

```bash
supabase db push
```

This creates the `ai_usage` and `user_profiles` tables with RLS policies.

Alternatively, run the SQL manually in the Supabase SQL Editor:
- Go to Supabase Dashboard > SQL Editor
- Paste the contents of `supabase/migrations/001_ai_usage.sql`
- Click Run

## Step 4: Set Supabase Secrets

Set the FreeLLMAPI key as a server-side secret (NEVER in the client):

```bash
supabase secrets set FREELLM_API_KEY=freellmapi-3feaeb54bce5546bbf6593333e2df1f95809863a92feef77
supabase secrets set FREELLM_BASE_URL=https://freellmapi.co/v1
supabase secrets set AI_DEFAULT_MODEL=gemini-2.0-flash
```

Or set them in the Supabase Dashboard:
- Go to Project Settings > Edge Functions > Secrets
- Add each key-value pair

## Step 5: Deploy the Edge Function

```bash
supabase functions deploy ai-chat
```

## Step 6: Configure Flutter

Update `apps/mobile/lib/services/online_model_config.dart` with your Supabase URL and anon key:

```dart
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://YOUR_PROJECT.supabase.co',
);

static const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'YOUR_ANON_KEY',
);
```

Or pass them at build time:

```bash
flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```

Get your anon key from: Supabase Dashboard > Project Settings > API > anon public

## Step 7: Verify

1. Sign in to the app (Supabase Auth)
2. Send a chat message
3. The request flows: Flutter → Edge Function → FreeLLMAPI → LLM → back to Flutter
4. Check Supabase Dashboard > Logs > Edge Functions for request logs
5. Check the `ai_usage` table for usage records

## Environment Variables Reference

### Edge Function Secrets (server-side only)

| Secret | Required | Description |
|--------|----------|-------------|
| `FREELLM_API_KEY` | Yes | FreeLLMAPI unified key |
| `FREELLM_BASE_URL` | No | FreeLLMAPI base URL (default: https://freellmapi.co/v1) |
| `AI_DEFAULT_MODEL` | No | Default model (default: gemini-2.0-flash) |
| `SUPABASE_URL` | Auto | Set by Supabase automatically |
| `SUPABASE_ANON_KEY` | Auto | Set by Supabase automatically |
| `SUPABASE_SERVICE_ROLE_KEY` | Auto | Set by Supabase automatically |

### Flutter (client-side, safe to expose)

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anon/public key |

## Rate Limits

| Tier | Requests/Hour | Requests/Day |
|------|---------------|--------------|
| free | 30 | 100 |
| premium | 200 | 1,000 |
| enterprise | 1,000 | 10,000 |

Rate limits are enforced server-side in the Edge Function using the `ai_usage` table.

## Security

- The FreeLLMAPI key is **never** in the Flutter app, APK, or client-side env
- All AI requests require Supabase authentication
- Rate limits are enforced server-side (cannot be bypassed by the client)
- The Librio system prompt is injected server-side (client cannot override it)
- Row Level Security protects the `ai_usage` table

## Future Provider Fallback

The Edge Function is structured to support additional providers. To add a new provider:

1. Add a new provider function in the Edge Function
2. Add provider selection logic based on model or capability
3. Set new API keys as Supabase secrets

```typescript
// Future: provider routing
async function callAIProvider(messages, model) {
  if (model.startsWith('gemini')) {
    return callFreeLLMAPI(messages, model);
  }
  // Future: return callGeminiDirect(messages, model);
  // Future: return callOpenAI(messages, model);
  return callFreeLLMAPI(messages, model); // default
}
```
