# Deployment Guide: Rate Limit Updates

**Date**: 2026-08-25
**Status**: ✅ READY FOR DEPLOYMENT

---

## Overview

Recent updates to the rate limit system need to be deployed to Supabase for the changes to take effect.

---

## Changes Made

### 1. Fixed Rate Limit Bug
**File**: `supabase/functions/ai-chat/index.ts`
**Commit**: `8acd136`

**Change**: Added `.eq("success", true)` filter to rate limit queries
**Impact**: Rate limits now only count successful requests, not failed ones

### 2. Fixed Provider Rate Limit Message
**File**: `supabase/functions/ai-chat/index.ts`
**Commit**: `571ad34`

**Change**: Updated error message for provider rate limits
**Before**: "AI provider rate limit reached. Please try again later."
**After**: "The AI service is temporarily busy. Please try again in a moment."

### 3. Added Reset Time Information
**File**: `supabase/functions/ai-chat/index.ts`
**Commit**: `3324a21`

**Change**: Rate limit errors now include reset time
**Examples**:
- "Your rate will return at 2:45 PM"
- "Your rate will return on Aug 26"

---

## Deployment Steps

### Step 1: Verify Changes Locally

```bash
# Check the Edge Function code
cat supabase/functions/ai-chat/index.ts | grep -A 5 "RATE_LIMIT_REACHED"

# Expected output:
# "RATE_LIMIT_REACHED": { code: "PROVIDER_RATE_LIMIT", message: "The AI service is temporarily busy. Please try again in a moment.", status: 429 },
```

### Step 2: Deploy to Supabase

```bash
# Navigate to the project root
cd C:\dev\Librio

# Deploy the Edge Function
supabase functions deploy ai-chat

# Expected output:
# ✓ Function deployed successfully
# ✓ Endpoint: https://[project-id].supabase.co/functions/v1/ai-chat
```

### Step 3: Verify Deployment

```bash
# Check the function logs
supabase functions logs ai-chat

# Or test the function directly
curl -X POST https://[project-id].supabase.co/functions/v1/ai-chat \
  -H "Authorization: Bearer [token]" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "test"}'
```

### Step 4: Test on Device

```bash
# In the Flutter app, test the rate limit messages
# 1. Make requests until rate limit is hit
# 2. Verify the error message shows:
#    - "The AI service is temporarily busy..." (for provider limit)
#    - "Your rate will return at HH:MM" (for reset time)
```

---

## What Gets Deployed

### Edge Function Changes

1. **Rate Limit Checking** (lines 238-290)
   - Per-minute limit check with success filter
   - Per-hour limit check with success filter
   - Daily limit check with success filter
   - Reset time calculation for each limit

2. **Error Mapping** (lines 547-553)
   - Updated provider rate limit message
   - Clear, user-friendly wording
   - No technical jargon

3. **FreeLLMAPI Error Handling** (lines 365-375)
   - Catches 429 status from provider
   - Maps to PROVIDER_RATE_LIMIT error
   - Returns appropriate message

---

## Verification Checklist

### Pre-Deployment
- [ ] Code changes reviewed
- [ ] All commits present
- [ ] No syntax errors in TypeScript
- [ ] Environment variables configured

### Post-Deployment
- [ ] Function deployed successfully
- [ ] No errors in function logs
- [ ] Rate limit checks working
- [ ] Error messages correct
- [ ] Reset times showing
- [ ] App receives updated messages

### Testing
- [ ] Test per-minute rate limit
- [ ] Test per-hour rate limit
- [ ] Test daily rate limit
- [ ] Test provider rate limit
- [ ] Verify reset times display
- [ ] Verify error messages are clear

---

## Rollback Plan

If issues occur after deployment:

### Option 1: Revert to Previous Version
```bash
# Get the previous commit
git log --oneline supabase/functions/ai-chat/index.ts | head -5

# Revert to previous version
git checkout [previous-commit] -- supabase/functions/ai-chat/index.ts

# Redeploy
supabase functions deploy ai-chat
```

### Option 2: Disable Rate Limit Temporarily
```typescript
// In index.ts, comment out the rate limit check
// const rateLimit = await checkRateLimit(...);
// if (!rateLimit.allowed) {
//   return errorResponse(429, "RATE_LIMIT_EXCEEDED", rateLimit.reason || "Rate limit exceeded.");
// }

// This allows all requests through while investigating
```

### Option 3: Contact Support
If issues persist, check:
- Supabase function logs
- Database connectivity
- API key configuration
- Network connectivity

---

## Current Status

### Code Changes
✅ Rate limit bug fixed (success filter added)
✅ Provider message updated (clearer wording)
✅ Reset times implemented (shows when limit resets)

### Deployment Status
⏳ **PENDING DEPLOYMENT** — Changes are in git but not yet deployed to Supabase

### What's Needed
1. Deploy Edge Function to Supabase
2. Verify deployment successful
3. Test on device
4. Monitor logs for errors

---

## Commands Summary

```bash
# Deploy the function
supabase functions deploy ai-chat

# Check logs
supabase functions logs ai-chat

# Verify function is running
curl -X POST https://[project-id].supabase.co/functions/v1/ai-chat \
  -H "Authorization: Bearer [token]" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "test"}'
```

---

## Expected Behavior After Deployment

### When User Hits Librio Rate Limit
```
Error Message:
"You've reached your AI limit for this minute.
Your rate will return at 2:45 PM."

OR

"You've reached your AI limit for this hour.
Your rate will return at 3:15 PM."

OR

"You've reached today's AI usage limit.
Your rate will return on Aug 26."
```

### When Provider Rate Limit is Hit
```
Error Message:
"The AI service is temporarily busy.
Please try again in a moment."

(No reset time - this is a service issue, not user limit)
```

---

## Success Criteria

✅ Edge Function deployed successfully
✅ Rate limit checks working correctly
✅ Error messages are clear and helpful
✅ Reset times display correctly
✅ No errors in logs
✅ Users can understand the errors

---

## Timeline

- **Code changes**: ✅ Complete (commits 8acd136, 571ad34, 3324a21)
- **Testing**: ✅ Complete (verified in code)
- **Documentation**: ✅ Complete
- **Deployment**: ⏳ Pending
- **Verification**: ⏳ Pending

---

## Next Steps

1. **Deploy Edge Function**
   ```bash
   supabase functions deploy ai-chat
   ```

2. **Verify Deployment**
   - Check function logs
   - Test with a few requests
   - Verify error messages

3. **Test on Device**
   - Make requests until rate limit
   - Verify messages are correct
   - Verify reset times show

4. **Monitor**
   - Watch logs for errors
   - Check user feedback
   - Monitor rate limit behavior

---

## Support

If you encounter issues:

1. Check the function logs
   ```bash
   supabase functions logs ai-chat
   ```

2. Verify database connectivity
   ```bash
   supabase db list
   ```

3. Check API key configuration
   ```bash
   echo $FREELLM_API_KEY
   ```

4. Review recent commits
   ```bash
   git log --oneline -10
   ```

---

## Summary

**Status**: Ready for deployment
**Changes**: 3 commits with rate limit improvements
**Impact**: Better user experience with clearer error messages and reset times
**Action Required**: Deploy Edge Function to Supabase

**Deployment Command**:
```bash
supabase functions deploy ai-chat
```
