# Usage Not Updating - Diagnostic & Fix

**Issue**: Usage display shows 0 even after making multiple requests
**Status**: Investigating
**Priority**: CRITICAL

---

## Root Cause Analysis

### Possible Causes

1. **RLS Policies Blocking Insert**
   - Edge Function uses service role key (should bypass RLS)
   - But if RLS is misconfigured, insert might fail silently
   - Status: ⚠️ Needs verification

2. **User ID Mismatch**
   - JWT user_id doesn't match auth.uid()
   - Usage recorded with wrong user_id
   - Status: ⚠️ Needs verification

3. **Client-Side Cache Issue**
   - Usage is recorded but client doesn't refresh
   - Cache is stale or not invalidating
   - Status: ⚠️ Likely cause

4. **RLS Policy Missing SELECT Permission**
   - User can't read their own usage records
   - Service records data but client can't fetch it
   - Status: ⚠️ Likely cause

---

## Diagnostic Steps

### Step 1: Check if Usage is Being Recorded

```sql
-- Run in Supabase SQL Editor
-- Replace [USER_ID] with actual user ID from auth.users

SELECT * FROM public.ai_usage 
WHERE user_id = '[USER_ID]'
ORDER BY created_at DESC
LIMIT 10;
```

**Expected**: Should see records from your requests
**If empty**: Usage is not being recorded (Edge Function issue)
**If has data**: Usage is recorded but client can't fetch it (RLS issue)

### Step 2: Check RLS Policies

```sql
-- Check if SELECT policy exists and is correct
SELECT * FROM pg_policies 
WHERE tablename = 'ai_usage';

-- Expected output should include:
-- "Users can view own AI usage" policy
-- with: auth.uid() = user_id
```

### Step 3: Check User ID in JWT

```dart
// In Flutter, add this to check JWT user ID
final user = _supabase.auth.currentUser;
print('User ID: ${user?.id}');
print('User Email: ${user?.email}');

// This should match the user_id in ai_usage table
```

### Step 4: Force Refresh Usage Cache

```dart
// In ai_usage_service.dart, add this method
void clearCache() {
  _cachedUsage = null;
  _cacheTime = null;
}

// Call this after sending a message
await _usageService.clearCache();
```

---

## The Fix

### Fix 1: Clear Cache After Request (IMMEDIATE)

The most likely issue is that the client-side cache is stale. Let me add cache invalidation:

**File**: `apps/mobile/lib/services/ai_usage_service.dart`

```dart
// Add this method to the AiUsageService class
void clearCache() {
  _cachedUsage = null;
  _cacheTime = null;
  DebugLogger.info('AiUsageService', 'Cache cleared');
}
```

**File**: `apps/mobile/lib/screens/chat_screen.dart`

After sending a message and getting a response, clear the cache:

```dart
// After getting response from OnlineLlmService
final response = await _onlineLlmService.generateResponseWithUsage(...);

// Clear usage cache so next fetch gets fresh data
_usageService.clearCache();

// Trigger usage panel refresh
setState(() {});
```

### Fix 2: Verify RLS Policies (IF NEEDED)

If usage data exists in database but client can't fetch it:

```sql
-- Run in Supabase SQL Editor
-- This creates the correct RLS policy if missing

CREATE POLICY "Users can view own AI usage"
  ON public.ai_usage
  FOR SELECT
  USING (auth.uid() = user_id);
```

### Fix 3: Check Edge Function Logs (IF NEEDED)

If usage data doesn't exist in database:

```bash
# Check Edge Function logs
supabase functions logs ai-chat

# Look for errors like:
# - "Failed to record usage"
# - "RLS policy violation"
# - "user_id mismatch"
```

---

## Implementation

### Step 1: Add Cache Clear Method

Edit `apps/mobile/lib/services/ai_usage_service.dart`:

```dart
// Add this method to AiUsageService class (around line 170)
void clearCache() {
  _cachedUsage = null;
  _cacheTime = null;
  DebugLogger.info('AiUsageService', 'Usage cache cleared');
}
```

### Step 2: Call Cache Clear After Message

Edit `apps/mobile/lib/screens/chat_screen.dart`:

Find where you send the message and get the response. After getting the response:

```dart
// After: final response = await _onlineLlmService.generateResponseWithUsage(...)
// Add:
_usageService.clearCache(); // Clear cache so next fetch gets fresh data
```

### Step 3: Verify RLS Policy

Run in Supabase SQL Editor:

```sql
-- Check if policy exists
SELECT * FROM pg_policies 
WHERE tablename = 'ai_usage' 
AND policyname = 'Users can view own AI usage';

-- If empty, create it:
CREATE POLICY "Users can view own AI usage"
  ON public.ai_usage
  FOR SELECT
  USING (auth.uid() = user_id);
```

---

## Testing

### Test 1: Manual Database Check

1. Send a message in the app
2. Go to Supabase Dashboard
3. Check `ai_usage` table
4. Look for new records with your user_id

**Expected**: New record appears
**If not**: Edge Function not recording (check logs)

### Test 2: Usage Panel Refresh

1. Send a message
2. Wait 2 seconds
3. Open usage panel
4. Check if numbers updated

**Expected**: Numbers increase
**If not**: Cache not clearing (implement fix)

### Test 3: Force Refresh

1. Close and reopen app
2. Open usage panel
3. Check if numbers show

**Expected**: Numbers show (cache was stale)
**If not**: RLS policy issue (check policies)

---

## Expected Behavior After Fix

### Before Fix
```
Send message → Usage shows 0 → No update
```

### After Fix
```
Send message → Cache clears → Usage panel refreshes → Shows correct count
```

---

## Summary

| Issue | Cause | Fix | Priority |
|-------|-------|-----|----------|
| Usage shows 0 | Stale cache | Clear cache after request | HIGH |
| Usage not updating | Cache not invalidating | Add cache clear method | HIGH |
| Usage data missing | RLS policy | Verify/create policy | MEDIUM |
| Edge Function error | Logging issue | Check logs | MEDIUM |

---

## Quick Implementation

### 1. Add to `ai_usage_service.dart` (line 170):
```dart
void clearCache() {
  _cachedUsage = null;
  _cacheTime = null;
  DebugLogger.info('AiUsageService', 'Usage cache cleared');
}
```

### 2. Add to `chat_screen.dart` (after getting response):
```dart
_usageService.clearCache();
```

### 3. Verify in Supabase:
```sql
SELECT * FROM public.ai_usage 
WHERE user_id = auth.uid()
ORDER BY created_at DESC
LIMIT 10;
```

---

**Status**: Ready to implement
**Estimated time**: 10-15 minutes
**Expected result**: Usage updates correctly after each message
