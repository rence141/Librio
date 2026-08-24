# Libro AI Usage System

Comprehensive Free vs Paid AI rate-limit and usage tracking system for Libro.

## Overview

The AI usage system protects Libro from AI-cost abuse while providing generous limits for legitimate student usage.

**Architecture:**
```
Flutter App
    ↓
Supabase Edge Function (ai-chat)
    ↓
Rate limit check (server-side, authoritative)
    ↓
FreeLLMAPI
    ↓
LLM (Gemini, GPT, etc.)
```

**Key principle:** Server-side enforcement is mandatory. Client-side checks are for UX only.

## Plans and Limits

### FREE Plan

- **5** requests per minute
- **30** requests per hour
- **100** messages per day
- **16K** input tokens max
- **2K** output tokens max
- **1** concurrent AI request
- **5** image analyses per day
- **3** document analyses per day

### PAID Plan

- **15** requests per minute
- **100** requests per hour
- **500** messages per day
- **32K** input tokens max
- **4K** output tokens max
- **3** concurrent AI requests
- **30** image analyses per day
- **20** document analyses per day

## Configuration

All limits are centralized in `apps/mobile/lib/config/ai_plans.dart`:

```dart
class AiPlans {
  static const AiPlanLimits free = AiPlanLimits(
    plan: AiPlan.free,
    requestsPerMinute: 5,
    requestsPerHour: 30,
    messagesPerDay: 100,
    maxInputTokens: 16000,
    maxOutputTokens: 2000,
    maxConcurrentRequests: 1,
    imageAnalysisPerDay: 5,
    documentAnalysisPerDay: 3,
  );

  static const AiPlanLimits paid = AiPlanLimits(
    plan: AiPlan.paid,
    requestsPerMinute: 15,
    requestsPerHour: 100,
    messagesPerDay: 500,
    maxInputTokens: 32000,
    maxOutputTokens: 4000,
    maxConcurrentRequests: 3,
    imageAnalysisPerDay: 30,
    documentAnalysisPerDay: 20,
  );
}
```

To change limits, update this file and redeploy both the Flutter app and Edge Function.

## Server-Side Enforcement

The Edge Function (`supabase/functions/ai-chat/index.ts`) enforces all rate limits:

```typescript
// Check per-minute limit
if ((minuteCount || 0) >= planLimits.requestsPerMinute) {
  return errorResponse(429, "RATE_LIMIT_EXCEEDED", 
    "You've reached your AI limit for this minute.\nPlease wait a moment and try again.");
}

// Check per-hour limit
if ((hourlyCount || 0) >= planLimits.requestsPerHour) {
  return errorResponse(429, "RATE_LIMIT_EXCEEDED",
    "You've reached your AI limit for this hour.\nPlease wait a moment and try again.");
}

// Check daily limit
if ((dailyCount || 0) >= planLimits.messagesPerDay) {
  return errorResponse(429, "RATE_LIMIT_EXCEEDED",
    "You've reached today's AI usage limit.\nYour limit will reset tomorrow.");
}
```

### Request Flow

1. **Authentication**: Verify user is authenticated
2. **Plan determination**: Get user's plan from `user_profiles.subscription_tier`
3. **Rate limit checks**: Check all applicable limits
4. **Token validation**: Verify input doesn't exceed max tokens
5. **Concurrent check**: Verify concurrent request count
6. **AI call**: If all checks pass, call FreeLLMAPI
7. **Usage recording**: Record usage in `ai_usage` table

### Error Messages

User-friendly error messages (no technical jargon):

```
"You've reached your AI limit for this minute.
Please wait a moment and try again."

"You've reached your AI limit for this hour.
Please wait a moment and try again."

"You've reached today's AI usage limit.
Your limit will reset tomorrow."

"You have too many AI requests running.
Please wait for one to finish."

"This conversation is getting too long.
Try starting a new chat or reducing the amount of content."

"You've reached the Free plan's usage limit.
Upgrade to continue with higher AI limits."
```

## Client-Side Usage Tracking

The `AiUsageService` (`apps/mobile/lib/services/ai_usage_service.dart`) provides client-side usage tracking for UX:

```dart
final usageService = AiUsageService();

// Get current usage
final usage = await usageService.getCurrentUsage();

// Check if user can make a request
final canMake = await usageService.canMakeRequest();

// Get blocking reason
final reason = await usageService.getBlockReason();

// Get context usage percentage
final percent = await usageService.getContextUsagePercent();
```

### Usage Snapshot

```dart
class AiUsageSnapshot {
  final AiPlan currentPlan;
  final int requestsThisMinute;
  final int requestsThisHour;
  final int messagesThisDay;
  final int concurrentRequests;
  final int imageAnalysisThisDay;
  final int documentAnalysisThisDay;
  final int totalInputTokensThisDay;
  final int totalOutputTokensThisDay;
  final DateTime lastResetTime;
}
```

### Caching

Usage data is cached for 30 seconds to reduce database queries:

```dart
// Returns cached data if available and fresh
final usage = await usageService.getCurrentUsage();

// Invalidate cache after making a request
usageService.invalidateCache();
```

## Database Schema

The `ai_usage` table tracks all AI requests:

```sql
CREATE TABLE ai_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  model_id TEXT NOT NULL,
  provider TEXT NOT NULL,
  input_tokens INTEGER DEFAULT 0,
  output_tokens INTEGER DEFAULT 0,
  total_tokens INTEGER DEFAULT 0,
  success BOOLEAN DEFAULT true,
  latency_ms INTEGER,
  request_type TEXT, -- 'message', 'image_analysis', 'document_analysis'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_ai_usage_user_id ON ai_usage(user_id);
CREATE INDEX idx_ai_usage_created_at ON ai_usage(created_at);
```

## UI Integration

### Context Meter

The rounded-square context meter in the chat input bar shows context usage:

```
╭──────╮
│      │
│ 72%  │
│      │
╰──────╯
```

- Border represents context usage (0-100%)
- Progress flows clockwise
- Gradient colors (purple → cyan)
- Tap to see full usage details

### Usage Panel

Tap the context meter to open the AI usage panel:

```
AI Usage

Context
11.5K / 16K

Messages
42 / 100 today

Requests
2 / 5 this minute

Plan
Free
```

Shows:
- Current context usage (tokens)
- Messages used today
- Requests this minute
- Current plan
- Upgrade hint for free users

## Reset Behavior

### Per-Minute Window
- Resets every 60 seconds
- Rolling window (not fixed times)
- Checked server-side

### Per-Hour Window
- Resets every 3600 seconds
- Rolling window (not fixed times)
- Checked server-side

### Daily Window
- Resets at UTC 00:00
- All daily limits reset together
- Server-side time is authoritative

## Abuse Protection

The system protects against:

- ✅ Rapid repeated requests (per-minute limit)
- ✅ Multiple simultaneous requests (concurrent limit)
- ✅ Extremely large prompts (token limit)
- ✅ Extremely large documents (token limit)
- ✅ Repeated failed requests (tracked in ai_usage)
- ✅ Direct unauthorized calls (Edge Function only)
- ✅ Client-side limit bypass (server-side enforcement)
- ✅ Device clock manipulation (server-side time)

## Testing Scenarios

Test all important scenarios:

```
✓ Free user under limit
✓ Free user reaches minute limit
✓ Free user reaches hourly limit
✓ Free user reaches daily limit
✓ Paid user under limit
✓ Paid user reaches limit
✓ Context reaches 80%
✓ Context reaches 90%
✓ Context reaches 100%
✓ Multiple simultaneous requests
✓ Request timeout
✓ AI provider failure
✓ User cancellation
✓ Image limit reached
✓ Document limit reached
✓ Unauthenticated request
✓ Expired authentication
✓ Attempt to manipulate client-side limits
```

## Implementation Files

### Configuration
- `apps/mobile/lib/config/ai_plans.dart` — Plan definitions and limits
- `supabase/functions/ai-chat/index.ts` — Server-side enforcement

### Services
- `apps/mobile/lib/services/ai_usage_service.dart` — Client-side usage tracking

### UI
- `apps/mobile/lib/widgets/context_meter.dart` — Rounded-square progress indicator
- `apps/mobile/lib/widgets/ai_usage_panel.dart` — Usage details panel
- `apps/mobile/lib/screens/chat_screen.dart` — Integration point

### Database
- `supabase/migrations/001_ai_usage.sql` — ai_usage table schema

## Deployment Checklist

- [ ] Update `AiPlans` in `config/ai_plans.dart`
- [ ] Update `AI_PLANS` in `supabase/functions/ai-chat/index.ts`
- [ ] Verify `user_profiles.subscription_tier` exists
- [ ] Verify `ai_usage` table exists
- [ ] Deploy Edge Function: `supabase functions deploy ai-chat`
- [ ] Rebuild Flutter app: `flutter run`
- [ ] Test all rate limit scenarios
- [ ] Monitor Edge Function logs
- [ ] Monitor ai_usage table growth

## Monitoring

### Edge Function Logs

Check Supabase dashboard for rate limit errors:

```
[FreeLLMAPI] Calling https://...
[FreeLLMAPI] Success: 200
[FreeLLMAPI] Error 429: Rate limit reached
```

### Database Queries

Monitor usage growth:

```sql
-- Daily usage by plan
SELECT 
  up.subscription_tier,
  COUNT(*) as requests,
  SUM(au.input_tokens) as input_tokens,
  SUM(au.output_tokens) as output_tokens
FROM ai_usage au
JOIN user_profiles up ON au.user_id = up.id
WHERE au.created_at > NOW() - INTERVAL '1 day'
GROUP BY up.subscription_tier;

-- Top users by usage
SELECT 
  user_id,
  COUNT(*) as requests,
  SUM(input_tokens) as input_tokens,
  SUM(output_tokens) as output_tokens
FROM ai_usage
WHERE created_at > NOW() - INTERVAL '1 day'
GROUP BY user_id
ORDER BY requests DESC
LIMIT 10;
```

## Future Enhancements

- [ ] Implement concurrent request tracking (currently server-side only)
- [ ] Add usage analytics dashboard
- [ ] Implement tiered pricing (more plans)
- [ ] Add usage alerts/notifications
- [ ] Implement usage-based billing
- [ ] Add usage export (CSV/JSON)
- [ ] Implement trial period for paid plan
- [ ] Add usage forecasting

## Security Notes

- ✅ API keys never exposed to client
- ✅ Rate limits enforced server-side
- ✅ User plan from database (not client)
- ✅ Usage tracked in database (not client)
- ✅ Device clock not trusted
- ✅ All timestamps in UTC
- ✅ Requests authenticated via JWT
- ✅ Row-level security on ai_usage table

## References

- `AiPlans` configuration: `apps/mobile/lib/config/ai_plans.dart`
- `AiUsageService`: `apps/mobile/lib/services/ai_usage_service.dart`
- Edge Function: `supabase/functions/ai-chat/index.ts`
- Context Meter: `apps/mobile/lib/widgets/context_meter.dart`
- Usage Panel: `apps/mobile/lib/widgets/ai_usage_panel.dart`
