# Immediate Next Steps (This Week)

**Current Status**: Prototype with AI rate limit fixed
**Goal**: Stabilize and test core flows
**Timeline**: 2-3 days

---

## What's Done ✅

1. ✅ Changed AI model to Claude 3.5 Sonnet
2. ✅ Improved error handling
3. ✅ Better error messages
4. ✅ Edge Function deployed

---

## What Needs Testing ⏳

### 1. User Profile Creation
**Issue**: User profiles might not be created on signup

**Test**:
```bash
1. Sign up with new email
2. Check Supabase: user_profiles table
3. Verify record exists with subscription_tier = 'free'
```

**If Broken**:
- Check if trigger is working: `supabase db triggers list`
- Manually create profile in Supabase dashboard
- Or create via Edge Function on signup

### 2. AI Usage Tracking
**Issue**: Usage data might not be recorded

**Test**:
```bash
1. Send a message
2. Check Supabase: ai_usage table
3. Verify record exists with user_id and success=true
```

**If Broken**:
- Check Edge Function logs
- Verify user is authenticated
- Check RLS policies on ai_usage table

### 3. Usage Panel Display
**Issue**: "Unable to load usage info" error

**Test**:
```bash
1. Open app
2. Tap context meter (top right)
3. Should show usage info or helpful message
```

**If Broken**:
- Check Flutter logs for PostgrestException
- Verify user_profiles record exists
- Verify RLS policies allow SELECT

### 4. Rate Limit Messages
**Issue**: Reset times might not show

**Test**:
```bash
1. Make 5 requests quickly (free plan limit)
2. Try 6th request
3. Should show: "Your rate will return at HH:MM"
```

**If Broken**:
- Check Edge Function code
- Verify rate limit calculation
- Check error message format

---

## Quick Fixes (If Needed)

### Fix 1: User Profile Creation
```sql
-- Run in Supabase SQL Editor
-- Manually create missing profile
INSERT INTO public.user_profiles (id, email, subscription_tier)
VALUES ('[user-id]', '[email]', 'free')
ON CONFLICT (id) DO NOTHING;
```

### Fix 2: Check RLS Policies
```sql
-- Run in Supabase SQL Editor
-- Verify user can read their own usage
SELECT * FROM public.ai_usage WHERE user_id = auth.uid() LIMIT 1;

-- Verify user can read their own profile
SELECT * FROM public.user_profiles WHERE id = auth.uid() LIMIT 1;
```

### Fix 3: Verify Triggers
```sql
-- Check if trigger exists
SELECT * FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- If missing, create it
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

---

## Testing Checklist

- [ ] Sign up with new account
- [ ] Verify user_profiles record created
- [ ] Send a message
- [ ] Verify ai_usage record created
- [ ] Open usage panel
- [ ] Verify usage info displays
- [ ] Make 5 requests quickly
- [ ] Try 6th request
- [ ] Verify rate limit message with reset time
- [ ] Wait for reset time
- [ ] Verify can send again
- [ ] Check no error messages in logs

---

## Debugging Commands

### Check Database
```bash
# List all tables
supabase db list

# Check user_profiles
supabase db query "SELECT * FROM user_profiles LIMIT 5"

# Check ai_usage
supabase db query "SELECT * FROM ai_usage LIMIT 5"
```

### Check Logs
```bash
# Flutter logs (on device)
flutter logs

# Edge Function logs
supabase functions logs ai-chat
```

### Check RLS
```bash
# List all policies
supabase db policies list

# Check specific table
supabase db policies list --table ai_usage
```

---

## If Everything Works ✅

1. Commit your testing results
2. Document what works
3. Move to Phase 2 (scaling)

---

## If Something Breaks 🔧

1. Check the logs
2. Identify the error
3. Use quick fixes above
4. Test again
5. Document the issue
6. Create a bug report

---

## Success Criteria

✅ **All tests pass**:
- User profiles created
- Usage tracked
- Usage panel displays
- Rate limits enforced
- Reset times shown
- No error messages

✅ **Ready for Phase 2**:
- Core flows stable
- Database working
- Error handling good
- Ready to scale

---

## Time Estimate

- Testing: 1-2 hours
- Debugging: 1-2 hours (if needed)
- Documentation: 30 minutes

**Total**: 2-4 hours

---

## Next Phase (After Stabilization)

Once everything is working:

1. **Multiple API Keys** (2-3 hours)
   - Add 5-10 API keys
   - Implement fallback chain
   - Test with load

2. **Request Queuing** (2-3 hours)
   - Queue when rate limited
   - Process queue later
   - Test with high load

3. **Response Caching** (1-2 hours)
   - Cache responses
   - Reduce API calls
   - Test cache hit rate

---

## Questions?

If you get stuck:

1. Check the logs
2. Check the database
3. Check the RLS policies
4. Check the Edge Function code
5. Ask for help

---

**Status**: Ready to test
**Next**: Run tests and report results
**Timeline**: Complete by end of day
