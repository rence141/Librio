# Provider Rate Limit Clarification

**Date**: 2026-08-25
**Status**: ✅ FIXED

---

## Issue Report

### Problem
When the user chats and the AI provider (FreeLLMAPI) is rate limited, the error message says "rate limit exceeded" even though the user's Librio rate limit shows 0%.

### User Confusion
```
User sees:
- Librio rate limit: 0% (plenty of usage left)
- Error message: "rate limit exceeded"
- Thinks: "Why am I rate limited when I'm at 0%?"
```

### Root Cause
The error message didn't distinguish between:
1. **Librio rate limit** (user's personal limit)
2. **Provider rate limit** (FreeLLMAPI's service limit)

---

## How Rate Limiting Works

### Two Types of Rate Limits

#### 1. Librio Rate Limit (User's Limit)
```
Checked FIRST in Edge Function
├─ Per-minute: 5 (free) / 15 (paid)
├─ Per-hour: 30 (free) / 100 (paid)
└─ Per-day: 100 (free) / 500 (paid)

If exceeded:
└─ Returns 429 with message: "You've reached your AI limit for this minute/hour/day"
```

#### 2. Provider Rate Limit (FreeLLMAPI's Limit)
```
Checked SECOND when calling FreeLLMAPI
├─ FreeLLMAPI has its own rate limits
├─ Shared across all users
└─ Can be exceeded even if user's Librio limit is 0%

If exceeded:
└─ FreeLLMAPI returns 429
└─ Edge Function catches and returns 429 with message
```

### Request Flow

```
User sends message
    ↓
Edge Function receives request
    ↓
Check Librio rate limit (user's personal limit)
├─ If exceeded: Return 429 "You've reached your AI limit..."
└─ If allowed: Continue
    ↓
Call FreeLLMAPI
├─ If provider rate limited: Returns 429
└─ If successful: Get response
    ↓
Return response to user
```

---

## The Confusion

### Before Fix
```
Scenario: FreeLLMAPI is rate limited (busy)

User's Librio rate limit: 0% (plenty of usage)
Error message: "AI provider rate limit reached. Please try again later."

User thinks:
"But I'm at 0%! Why am I rate limited?"
```

### After Fix
```
Scenario: FreeLLMAPI is rate limited (busy)

User's Librio rate limit: 0% (plenty of usage)
Error message: "The AI service is temporarily busy. Please try again in a moment."

User understands:
"Oh, the AI service is busy, not my rate limit."
```

---

## Error Messages Explained

### Librio Rate Limit Exceeded
```
Message: "You've reached your AI limit for this minute."
         "You've reached your AI limit for this hour."
         "You've reached today's AI usage limit."

Meaning: User has exceeded their personal Librio rate limit
Action: Wait for the time window to reset
```

### Provider Rate Limit Exceeded
```
Message: "The AI service is temporarily busy. Please try again in a moment."

Meaning: FreeLLMAPI (the AI provider) is overloaded
Action: Wait a moment and retry
Note: User's Librio rate limit is NOT exceeded
```

---

## Code Changes

### File
`supabase/functions/ai-chat/index.ts`

### Before
```typescript
"RATE_LIMIT_REACHED": { 
  code: "PROVIDER_RATE_LIMIT", 
  message: "AI provider rate limit reached. Please try again later.",  // ❌ Confusing
  status: 429 
}
```

### After
```typescript
"RATE_LIMIT_REACHED": { 
  code: "PROVIDER_RATE_LIMIT", 
  message: "The AI service is temporarily busy. Please try again in a moment.",  // ✅ Clear
  status: 429 
}
```

---

## Key Differences

| Aspect | Librio Rate Limit | Provider Rate Limit |
|--------|------------------|-------------------|
| **What** | User's personal limit | FreeLLMAPI's service limit |
| **Checked** | First (before calling provider) | Second (when calling provider) |
| **User's control** | Yes (can upgrade plan) | No (service issue) |
| **Affects** | Only this user | All users of FreeLLMAPI |
| **Message** | "You've reached your AI limit..." | "The AI service is temporarily busy..." |
| **Action** | Wait or upgrade plan | Wait and retry |

---

## Examples

### Example 1: Librio Rate Limit Exceeded
```
User has made 5 requests in the last minute (free plan limit)
Tries to make 6th request
    ↓
Edge Function checks Librio rate limit
    ↓
Finds 5 successful requests in last minute
    ↓
Returns 429: "You've reached your AI limit for this minute."
    ↓
User must wait ~60 seconds for oldest request to age out
```

### Example 2: Provider Rate Limit Exceeded
```
User has made 1 request in the last minute (0% of limit)
Tries to make 2nd request
    ↓
Edge Function checks Librio rate limit
    ↓
Finds 1 successful request (5 allowed) - OK!
    ↓
Calls FreeLLMAPI
    ↓
FreeLLMAPI returns 429 (their service is overloaded)
    ↓
Returns 429: "The AI service is temporarily busy. Please try again in a moment."
    ↓
User's Librio limit is NOT exceeded
    ↓
User can retry in a few seconds
```

---

## Testing

### Test Case 1: Verify Librio Limit Works
```
Setup:
- Free user (5 requests/minute limit)
- Make 5 successful requests
- Try to make 6th request

Expected: "You've reached your AI limit for this minute."
Result: ✅ Correct message
```

### Test Case 2: Verify Provider Error is Clear
```
Setup:
- User at 0% Librio limit
- FreeLLMAPI is overloaded
- User sends message

Expected: "The AI service is temporarily busy. Please try again in a moment."
Result: ✅ Clear that it's a service issue, not user limit
```

---

## User Experience Impact

### Before
```
User sees "rate limit exceeded" at 0% usage
User is confused and frustrated
User might think the app is broken
```

### After
```
User sees "AI service is temporarily busy"
User understands it's a service issue
User knows to retry in a moment
User has better experience
```

---

## Summary

### The Issue
- Two different rate limits: Librio (user) and Provider (service)
- Error message was confusing when provider was rate limited
- User thought their Librio limit was exceeded when it wasn't

### The Fix
- Changed error message to be clearer
- Now says "AI service is temporarily busy" instead of "rate limit reached"
- Users understand it's a service issue, not their limit

### Result
✅ Clearer error messages
✅ Better user understanding
✅ Reduced confusion
✅ Improved UX

---

## Git Commit

```
571ad34 — Fix confusing provider rate limit error message
```

---

## Related Documentation

- `RATE_LIMIT_BUG_FIX.md` — Librio rate limit bug fix
- `AI_USAGE_SYSTEM.md` — Rate limit system overview
- `DEPLOYMENT_CHECKLIST.md` — Rate limit testing procedures
