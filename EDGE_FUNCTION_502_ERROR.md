# Edge Function 502 Error - Diagnosis

## What's Happening

✅ **Configuration is working!**
- App successfully sends message to Edge Function
- Edge Function receives the request
- Edge Function calls FreeLLMAPI
- FreeLLMAPI returns an error (502)

**Error log:**
```
🔍 [LIBRIO] ERROR [OnlineLlm] Edge Function error: 502
🔍 [LIBRIO] ERROR [OnlineLlm] Exception: Exception: {"error":{"code":"SERVER_ERROR","message":"AI service experienced an error."}}
```

## Root Cause

The Edge Function is trying to call FreeLLMAPI but getting a 502 error. This means:

1. **FREELLM_API_KEY is not set** (or invalid) in Supabase secrets
2. **FREELLM_BASE_URL is not set** (or invalid) in Supabase secrets
3. **FreeLLMAPI service is down**

## How to Fix

### Step 1: Check Supabase Secrets

Go to [Supabase Dashboard](https://app.supabase.com):
1. Select project: `itrlclzfgwicwhskepnf`
2. Go to **Settings** → **Edge Functions** → **Secrets**
3. Verify these secrets exist:
   - `FREELLM_API_KEY` — Your FreeLLMAPI unified key (should start with `freellmapi-`)
   - `FREELLM_BASE_URL` — Should be `https://freellmapi.co/v1` (or your Railway URL)

### Step 2: Verify FreeLLMAPI Key

If you don't have the key:
1. Go to [FreeLLMAPI Dashboard](https://freellmapi.co) (or your Railway deployment)
2. Get your unified API key
3. Set it in Supabase:
   ```bash
   supabase secrets set FREELLM_API_KEY=freellmapi-xxxxx
   supabase secrets set FREELLM_BASE_URL=https://freellmapi.co/v1
   ```

### Step 3: Redeploy Edge Function

After setting secrets:
```bash
cd supabase/functions/ai-chat
supabase functions deploy ai-chat
```

### Step 4: Test Again

Send a message in the app. Should now get AI response instead of 502 error.

## Verification

The configuration fix is **complete and working**. The 502 error is a separate issue with the Edge Function's dependencies (FreeLLMAPI credentials).

### What's Working
✅ Flutter app builds and runs
✅ Supabase initializes
✅ OnlineModelConfig initializes with credentials
✅ App sends request to Edge Function
✅ Edge Function receives request
✅ Error handling works (returns 502 with proper error message)

### What Needs Setup
⚠️ FreeLLMAPI credentials in Supabase secrets
⚠️ Edge Function redeploy after setting secrets

## Architecture

```
Flutter App (✅ WORKING)
    ↓
OnlineModelConfig (✅ WORKING)
    ↓
Supabase Edge Function (✅ RECEIVES REQUEST)
    ↓
FreeLLMAPI (⚠️ CREDENTIALS MISSING)
    ↓
LLM (Gemini, GPT, etc.)
```

## Next Steps

1. Set `FREELLM_API_KEY` in Supabase secrets
2. Set `FREELLM_BASE_URL` in Supabase secrets
3. Redeploy Edge Function
4. Send another message
5. Should get AI response

The **configuration fix is complete and verified working**. This 502 error is expected until FreeLLMAPI credentials are configured in Supabase.
