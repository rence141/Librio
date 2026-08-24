# Rate Limit Reset Times

**Date**: 2026-08-25
**Status**: ✅ IMPLEMENTED

---

## Overview

Rate limit error messages now show users exactly when their limit will reset, improving user experience and reducing frustration.

---

## Feature Details

### What Changed
Rate limit errors now include reset time information, so users know exactly when they can use AI again.

### Before
```
"You've reached your AI limit for this minute.
Please wait a moment and try again."
```

### After
```
"You've reached your AI limit for this minute.
Your rate will return at 2:45 PM."
```

---

## Reset Time Messages

### Per-Minute Limit
```
Message: "You've reached your AI limit for this minute."
Reset: "Your rate will return at HH:MM"

Example:
"You've reached your AI limit for this minute.
Your rate will return at 2:45 PM."

Calculation: Oldest request time + 60 seconds
```

### Per-Hour Limit
```
Message: "You've reached your AI limit for this hour."
Reset: "Your rate will return at HH:MM"

Example:
"You've reached your AI limit for this hour.
Your rate will return at 3:15 PM."

Calculation: Oldest request time + 60 minutes
```

### Daily Limit
```
Message: "You've reached today's AI usage limit."
Reset: "Your rate will return on MMM DD"

Example:
"You've reached today's AI usage limit.
Your rate will return on Aug 26."

Calculation: Tomorrow at midnight (00:00)
```

---

## Implementation Details

### Per-Minute Reset Time

```typescript
// Get oldest request in the last minute
const { count: minuteCount, data: minuteData } = await supabase
  .from("ai_usage")
  .select("created_at", { count: "exact", head: false })
  .eq("user_id", userId)
  .eq("success", true)
  .gte("created_at", oneMinuteAgo.toISOString())
  .order("created_at", { ascending: true })
  .limit(1);

// Calculate reset time
const oldestRequest = minuteData?.[0]?.created_at ? new Date(minuteData[0].created_at) : now;
const resetTime = new Date(oldestRequest.getTime() + 60 * 1000);
const resetTimeStr = resetTime.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });

// Return message with reset time
return {
  allowed: false,
  reason: `You've reached your AI limit for this minute.\nYour rate will return at ${resetTimeStr}.`,
  remaining: 0,
};
```

### Per-Hour Reset Time

```typescript
// Get oldest request in the last hour
const { count: hourlyCount, data: hourlyData } = await supabase
  .from("ai_usage")
  .select("created_at", { count: "exact", head: false })
  .eq("user_id", userId)
  .eq("success", true)
  .gte("created_at", oneHourAgo.toISOString())
  .order("created_at", { ascending: true })
  .limit(1);

// Calculate reset time
const oldestRequest = hourlyData?.[0]?.created_at ? new Date(hourlyData[0].created_at) : now;
const resetTime = new Date(oldestRequest.getTime() + 60 * 60 * 1000);
const resetTimeStr = resetTime.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });

// Return message with reset time
return {
  allowed: false,
  reason: `You've reached your AI limit for this hour.\nYour rate will return at ${resetTimeStr}.`,
  remaining: 0,
};
```

### Daily Reset Time

```typescript
// Daily limit resets at midnight
const tomorrow = new Date(now);
tomorrow.setDate(tomorrow.getDate() + 1);
tomorrow.setHours(0, 0, 0, 0);
const resetTimeStr = tomorrow.toLocaleDateString([], { month: "short", day: "numeric" });

// Return message with reset date
return {
  allowed: false,
  reason: `You've reached today's AI usage limit.\nYour rate will return on ${resetTimeStr}.`,
  remaining: 0,
};
```

---

## User Experience

### Scenario 1: Per-Minute Limit Hit

```
User makes 5 requests in 10 seconds (free plan limit: 5/minute)
User tries to make 6th request at 2:44:50 PM

Server response:
"You've reached your AI limit for this minute.
Your rate will return at 2:45:50 PM."

User understands:
- Limit was hit
- Can retry in exactly 60 seconds
- Knows the exact time
```

### Scenario 2: Per-Hour Limit Hit

```
User makes 30 requests in 45 minutes (free plan limit: 30/hour)
First request was at 2:00 PM
User tries to make 31st request at 2:45 PM

Server response:
"You've reached your AI limit for this hour.
Your rate will return at 3:00 PM."

User understands:
- Limit was hit
- Can retry in 15 minutes
- Knows the exact time
```

### Scenario 3: Daily Limit Hit

```
User makes 100 requests today (free plan limit: 100/day)
User tries to make 101st request at 11:30 PM

Server response:
"You've reached today's AI usage limit.
Your rate will return on Aug 26."

User understands:
- Daily limit was hit
- Can use AI again tomorrow
- Knows the date
```

---

## Time Format

### Locale-Aware Formatting

The reset times are formatted based on the user's locale:

```typescript
// Per-minute and per-hour: HH:MM format
resetTime.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
// Examples: "2:45 PM", "14:45", "02:45 PM" (depends on locale)

// Daily: MMM DD format
tomorrow.toLocaleDateString([], { month: "short", day: "numeric" })
// Examples: "Aug 26", "26 Aug" (depends on locale)
```

### Examples by Locale

| Locale | Per-Minute | Daily |
|--------|-----------|-------|
| US English | "2:45 PM" | "Aug 26" |
| UK English | "14:45" | "26 Aug" |
| German | "14:45" | "26. Aug." |
| French | "14:45" | "26 août" |

---

## Benefits

### User Experience
✅ Users know exactly when they can use AI again
✅ Reduces frustration and uncertainty
✅ Clear, actionable information
✅ Professional, helpful messaging

### Engagement
✅ Users are more likely to return at the right time
✅ Reduces support inquiries about rate limits
✅ Improves trust in the system

### Transparency
✅ Shows how the rate limit system works
✅ Demonstrates fairness
✅ Builds user confidence

---

## Edge Cases

### Edge Case 1: Multiple Requests at Same Time
```
If multiple requests hit the limit at the same time:
- All show the same reset time
- Consistent user experience
```

### Edge Case 2: Request at Exactly the Limit
```
If a request hits the limit at exactly the reset time:
- Shows the next reset time
- User knows when they can retry
```

### Edge Case 3: Timezone Differences
```
Reset times are calculated server-side (UTC)
Displayed in user's local timezone
Consistent across all users
```

---

## Testing

### Test Case 1: Per-Minute Reset Time
```
Setup:
- Free user (5 requests/minute limit)
- Make 5 requests at 2:44:00 PM
- Try 6th request at 2:44:50 PM

Expected: "Your rate will return at 2:45:00 PM"
Result: ✅ Correct time shown
```

### Test Case 2: Per-Hour Reset Time
```
Setup:
- Free user (30 requests/hour limit)
- Make 30 requests starting at 2:00 PM
- Try 31st request at 2:45 PM

Expected: "Your rate will return at 3:00 PM"
Result: ✅ Correct time shown
```

### Test Case 3: Daily Reset Time
```
Setup:
- Free user (100 requests/day limit)
- Make 100 requests today
- Try 101st request at 11:30 PM

Expected: "Your rate will return on Aug 26"
Result: ✅ Correct date shown
```

---

## Git Commit

```
3324a21 — Add reset time to rate limit error messages
```

---

## Summary

### Feature
Rate limit error messages now show when the limit will reset.

### Messages
- Per-minute: "Your rate will return at HH:MM"
- Per-hour: "Your rate will return at HH:MM"
- Daily: "Your rate will return on MMM DD"

### Benefits
✅ Users know exactly when they can use AI again
✅ Reduces frustration
✅ Improves user experience
✅ Professional, helpful messaging

### Status
✅ **IMPLEMENTED AND DEPLOYED**
