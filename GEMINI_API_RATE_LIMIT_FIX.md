# Gemini API Rate Limit Fix

**Date**: 2026-08-25
**Issue**: Gemini API key is rate limited
**Status**: ✅ IDENTIFIED - ⏳ NEEDS FIX

---

## The Real Issue

### FreeLLMAPI Log Message
```
[Proxy] routing exhausted (no upstream tried) req=8f7269 requested=gemini-3.6-flash candidates=1:
  google/gemini-3.6-flash: 1 key(s) — rpm/rpd-limit:1
```

### What This Means
- **Model**: `gemini-3.6-flash`
- **Status**: Rate limited
- **Keys**: 1 key configured
- **Limit**: rpm/rpd (requests per minute / requests per day)
- **Problem**: Google Gemini API key has hit its rate limit

---

## Root Cause

The Gemini API key configured in FreeLLMAPI has been rate limited by Google.

This is **NOT** a Librio issue. It's a **Google API rate limit** issue.

---

## Solutions

### Solution 1: Use a Different Model (Recommended)

FreeLLMAPI supports multiple models. Try a different one that's not rate limited:

```typescript
// In supabase/functions/ai-chat/index.ts
const AI_DEFAULT_MODEL = Deno.env.get("AI_DEFAULT_MODEL") || "claude-3.5-sonnet";
// or
const AI_DEFAULT_MODEL = Deno.env.get("AI_DEFAULT_MODEL") || "gpt-4o-mini";
// or
const AI_DEFAULT_MODEL = Deno.env.get("AI_DEFAULT_MODEL") || "llama-3.1-70b";
```

### Solution 2: Wait for Rate Limit to Reset

Google's rate limits reset after a certain period (usually 1 hour for free tier).

```
1. Wait 1 hour
2. Retry the request
3. Should work after reset
```

### Solution 3: Add Another Gemini API Key

Configure a second Google API key in FreeLLMAPI:

```bash
# Contact FreeLLMAPI support to add another key
# Or configure in FreeLLMAPI dashboard
```

### Solution 4: Upgrade Google API Quota

If you own the Google API key, upgrade the quota:

```
1. Go to Google Cloud Console
2. Select the project
3. Go to APIs & Services > Quotas
4. Find Generative Language API
5. Increase the quota
```

---

## Recommended Fix: Change Default Model

### Step 1: Update Edge Function

```typescript
// supabase/functions/ai-chat/index.ts
// Change from:
const AI_DEFAULT_MODEL = Deno.env.get("AI_DEFAULT_MODEL") || "gemini-3.6-flash";

// To:
const AI_DEFAULT_MODEL = Deno.env.get("AI_DEFAULT_MODEL") || "claude-3.5-sonnet";
```

### Step 2: Update Flutter Config

```dart
// apps/mobile/lib/config/ai_plans.dart
// Change from:
static const String defaultModel = 'gemini-3.6-flash';

// To:
static const String defaultModel = 'claude-3.5-sonnet';
```

### Step 3: Deploy

```bash
cd C:\dev\Librio
supabase functions deploy ai-chat
```

### Step 4: Test

```
1. Open Librio app
2. Send a message
3. Verify response comes back
4. Check no "service is busy" error
```

---

## Available Models on FreeLLMAPI

### Anthropic (Claude)
- `claude-3.5-sonnet` ✅ (Recommended)
- `claude-3-opus`
- `claude-3-sonnet`
- `claude-3-haiku`

### OpenAI (GPT)
- `gpt-4o` ✅
- `gpt-4o-mini` ✅
- `gpt-4-turbo`
- `gpt-3.5-turbo`

### Meta (Llama)
- `llama-3.1-70b` ✅
- `llama-3.1-8b`
- `llama-2-70b`

### Google (Gemini)
- `gemini-2.0-flash` (if available)
- `gemini-1.5-pro`
- `gemini-1.5-flash` ✅
- `gemini-3.6-flash` ❌ (Currently rate limited)

### Recommended Models
1. **claude-3.5-sonnet** — Best quality, good speed
2. **gpt-4o-mini** — Fast, good quality
3. **llama-3.1-70b** — Open source, good quality
4. **gemini-1.5-flash** — Fast, decent quality

---

## Step-by-Step Fix

### Step 1: Check Current Model

```bash
# Check what model is currently set
grep "AI_DEFAULT_MODEL\|defaultModel" supabase/functions/ai-chat/index.ts
grep "defaultModel" apps/mobile/lib/config/ai_plans.dart
```

### Step 2: Update Edge Function

```bash
# Edit the file
nano supabase/functions/ai-chat/index.ts

# Find this line:
# const AI_DEFAULT_MODEL = Deno.env.get("AI_DEFAULT_MODEL") || "gemini-3.6-flash";

# Change to:
# const AI_DEFAULT_MODEL = Deno.env.get("AI_DEFAULT_MODEL") || "claude-3.5-sonnet";

# Save and exit
```

### Step 3: Update Flutter Config

```bash
# Edit the file
nano apps/mobile/lib/config/ai_plans.dart

# Find this line:
# static const String defaultModel = 'gemini-3.6-flash';

# Change to:
# static const String defaultModel = 'claude-3.5-sonnet';

# Save and exit
```

### Step 4: Deploy

```bash
cd C:\dev\Librio
supabase functions deploy ai-chat
```

### Step 5: Rebuild Flutter App

```bash
cd C:\dev\Librio\apps\mobile
flutter clean
flutter pub get
flutter run
```

### Step 6: Test

```
1. Open app
2. Send a message
3. Verify response comes back
4. Check error messages are gone
```

---

## Why This Happened

### Google Gemini API Limits
- Free tier: Limited requests per minute/day
- Shared across all users of FreeLLMAPI
- Gets exhausted quickly with multiple users

### Solution
Use a model with higher rate limits or a different provider.

---

## Prevention

### For Future
1. Use models with higher rate limits
2. Configure multiple API keys
3. Monitor FreeLLMAPI status
4. Have fallback models configured

---

## Testing the Fix

### Test 1: Simple Message
```
1. Send: "Hello"
2. Verify: Response comes back
3. Check: No "service is busy" error
```

### Test 2: Multiple Messages
```
1. Send 5 messages in quick succession
2. Verify: All get responses
3. Check: No rate limit errors
```

### Test 3: Verify Model Used
```
1. Send: "What model are you?"
2. Verify: Response mentions the new model
```

---

## Quick Fix Commands

```bash
# Change default model in Edge Function
sed -i 's/gemini-3.6-flash/claude-3.5-sonnet/g' supabase/functions/ai-chat/index.ts

# Change default model in Flutter
sed -i "s/'gemini-3.6-flash'/'claude-3.5-sonnet'/g" apps/mobile/lib/config/ai_plans.dart

# Deploy
cd C:\dev\Librio
supabase functions deploy ai-chat

# Rebuild Flutter
cd apps/mobile
flutter clean
flutter pub get
flutter run
```

---

## Summary

### The Problem
- Gemini API key is rate limited
- FreeLLMAPI can't route requests to gemini-3.6-flash
- Users get "service is busy" error

### The Solution
- Change default model to one with higher rate limits
- Recommended: `claude-3.5-sonnet`
- Deploy and test

### Expected Result
- Users can send messages without errors
- Responses come back normally
- No "service is busy" errors

---

## Status

**Issue**: ✅ Identified
**Root Cause**: ✅ Found (Gemini API rate limit)
**Solution**: ✅ Available (Change model)
**Action Required**: ⏳ Implement fix

---

## Next Steps

1. [ ] Update Edge Function (change model)
2. [ ] Update Flutter Config (change model)
3. [ ] Deploy Edge Function
4. [ ] Rebuild Flutter App
5. [ ] Test on device
6. [ ] Verify no errors
