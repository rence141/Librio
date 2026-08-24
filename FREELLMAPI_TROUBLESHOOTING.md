# FreeLLMAPI Troubleshooting Guide

**Date**: 2026-08-25
**Issue**: "The AI service is temporarily busy" error

---

## Understanding the Error

### What This Message Means
```
"The AI service is temporarily busy. Please try again in a moment."
```

This error comes from **FreeLLMAPI**, not Librio's rate limit system.

### Two Possible Causes

1. **FreeLLMAPI is overloaded** (service issue)
   - Too many requests to FreeLLMAPI
   - Service is temporarily unavailable
   - Retry in a few moments

2. **FreeLLMAPI is not configured** (configuration issue)
   - API key is missing or invalid
   - Base URL is incorrect
   - Service is not running

---

## Diagnostic Steps

### Step 1: Check Supabase Secrets

Verify that FreeLLMAPI credentials are configured:

```bash
# List all secrets
supabase secrets list

# Expected output should include:
# FREELLM_API_KEY
# FREELLM_BASE_URL (optional, defaults to https://freellmapi.co/v1)
```

### Step 2: Verify API Key

Check if the API key is valid:

```bash
# Get the API key (if you have access)
supabase secrets list | grep FREELLM_API_KEY

# The key should start with: freellmapi-
```

### Step 3: Test FreeLLMAPI Directly

Test if FreeLLMAPI is accessible:

```bash
# Test the API endpoint
curl -X POST https://freellmapi.co/v1/chat/completions \
  -H "Authorization: Bearer [YOUR_API_KEY]" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini-2.0-flash",
    "messages": [{"role": "user", "content": "Hello"}],
    "temperature": 0.3,
    "top_p": 0.85,
    "max_tokens": 100
  }'

# Expected response:
# - 200: Success
# - 401: Invalid API key
# - 429: Rate limited
# - 503: Service unavailable
```

### Step 4: Check Edge Function Logs

```bash
supabase functions logs ai-chat

# Look for errors like:
# [FreeLLMAPI] Error 429: Rate limit reached
# [FreeLLMAPI] Error 401: Invalid API key
# [FreeLLMAPI] Error 503: Service unavailable
```

---

## Common Issues & Solutions

### Issue 1: API Key Missing or Invalid

**Symptoms**:
- Error: "AI service is not properly configured"
- Logs show: "Error 401: Unauthorized"

**Solution**:
```bash
# Set the API key
supabase secrets set FREELLM_API_KEY=freellmapi-your-key-here

# Redeploy the function
supabase functions deploy ai-chat

# Verify
supabase secrets list
```

### Issue 2: FreeLLMAPI is Rate Limited

**Symptoms**:
- Error: "The AI service is temporarily busy"
- Logs show: "Error 429: Rate limit reached"

**Solution**:
```
1. Wait a few moments (usually 60 seconds)
2. Retry the request
3. If persistent, check FreeLLMAPI status page
4. Consider upgrading FreeLLMAPI plan
```

### Issue 3: FreeLLMAPI Service is Down

**Symptoms**:
- Error: "AI service is temporarily unavailable"
- Logs show: "Error 503: Service unavailable"

**Solution**:
```
1. Check FreeLLMAPI status: https://freellmapi.co/status
2. Wait for service to recover
3. Retry after a few minutes
4. Contact FreeLLMAPI support if persistent
```

### Issue 4: Wrong Base URL

**Symptoms**:
- Error: "Failed to reach AI service"
- Logs show: "Connection refused" or "DNS resolution failed"

**Solution**:
```bash
# Check current base URL
supabase secrets list | grep FREELLM_BASE_URL

# If not set, it defaults to: https://freellmapi.co/v1

# If you need to change it:
supabase secrets set FREELLM_BASE_URL=https://your-custom-url/v1

# Redeploy
supabase functions deploy ai-chat
```

---

## Configuration Checklist

### Required Secrets
- [ ] `FREELLM_API_KEY` is set
- [ ] API key starts with `freellmapi-`
- [ ] API key is valid and active

### Optional Secrets
- [ ] `FREELLM_BASE_URL` is set (defaults to https://freellmapi.co/v1)
- [ ] Base URL is correct
- [ ] Base URL is accessible

### Function Configuration
- [ ] Edge Function is deployed
- [ ] Function status is ACTIVE
- [ ] Function version is up to date

---

## Testing the Fix

### Test 1: Simple Request
```
1. Open Librio app
2. Send a simple message: "Hello"
3. Verify response comes back
4. Check for error messages
```

### Test 2: Multiple Requests
```
1. Send 5 requests in quick succession
2. Verify all get responses (or rate limit error)
3. Check error messages are clear
```

### Test 3: Rate Limit Reset Time
```
1. Hit the rate limit
2. Verify message shows reset time
3. Wait for reset time
4. Verify you can send again
```

---

## Monitoring

### Check Function Logs
```bash
supabase functions logs ai-chat --follow
```

### Check for Errors
```bash
supabase functions logs ai-chat | grep -i error
```

### Check Rate Limit Errors
```bash
supabase functions logs ai-chat | grep -i "429\|rate"
```

---

## FreeLLMAPI Status

### Check Service Status
- Website: https://freellmapi.co
- Status Page: https://freellmapi.co/status
- Documentation: https://freellmapi.co/docs

### Contact Support
- Email: support@freellmapi.co
- Discord: https://discord.gg/freellmapi
- GitHub: https://github.com/freellmapi

---

## Current Configuration

### Edge Function Settings
```typescript
FREELLM_BASE_URL = "https://freellmapi.co/v1" (default)
FREELLM_API_KEY = [configured in Supabase secrets]
AI_DEFAULT_MODEL = "gemini-3.6-flash" (default)
```

### Rate Limits (Librio)
```
Free Plan:
- Per-minute: 5 requests
- Per-hour: 30 requests
- Per-day: 100 requests

Paid Plan:
- Per-minute: 15 requests
- Per-hour: 100 requests
- Per-day: 500 requests
```

---

## Quick Fixes

### If You're Getting "Service is Busy"

1. **Wait a moment** (60 seconds)
   - FreeLLMAPI might be temporarily overloaded
   - Retry after waiting

2. **Check your API key**
   ```bash
   supabase secrets list | grep FREELLM_API_KEY
   ```

3. **Check FreeLLMAPI status**
   - Visit: https://freellmapi.co/status
   - Check if service is operational

4. **Check function logs**
   ```bash
   supabase functions logs ai-chat
   ```

5. **Redeploy the function**
   ```bash
   supabase functions deploy ai-chat
   ```

---

## Summary

### The Error
"The AI service is temporarily busy" = FreeLLMAPI returned 429 (rate limited)

### Possible Causes
1. FreeLLMAPI is overloaded (wait and retry)
2. API key is invalid (check configuration)
3. Service is down (check status page)
4. Network issue (check connectivity)

### Solution
1. Wait a moment and retry
2. Check Supabase secrets
3. Check FreeLLMAPI status
4. Check function logs
5. Redeploy if needed

### Next Steps
- [ ] Verify API key is configured
- [ ] Check FreeLLMAPI status
- [ ] Wait and retry
- [ ] Check function logs
- [ ] Contact support if persistent
