# Prototype to Production Roadmap

**Current Status**: Prototype Stage
**Target**: Production-ready for thousands of users
**Timeline**: 4-6 weeks

---

## Phase 1: Stabilize Prototype (Week 1-2)

### Current Issues to Fix
- ✅ AI model rate limiting (DONE - changed to Claude)
- ✅ Usage info error handling (DONE - graceful fallback)
- ⏳ User profile creation on signup
- ⏳ Database RLS policies verification

### Tasks

#### 1.1 Fix User Profile Creation
```dart
// apps/mobile/lib/services/auth_service.dart
// Ensure user_profiles record is created when user signs up
Future<void> signUp(String email, String password) async {
  final response = await _supabase.auth.signUp(
    email: email,
    password: password,
  );
  
  // Trigger user profile creation via Edge Function
  // or ensure trigger is working in Supabase
}
```

#### 1.2 Verify Database Setup
```bash
# Check if tables exist
supabase db list

# Check RLS policies
supabase db policies list

# Verify triggers
supabase db triggers list
```

#### 1.3 Test Core Flows
- [ ] Sign up → user_profiles created
- [ ] Send message → ai_usage recorded
- [ ] View usage panel → shows correct data
- [ ] Rate limit hit → shows reset time
- [ ] Multiple messages → no errors

### Success Criteria
- ✅ No database errors
- ✅ Usage tracking works
- ✅ Rate limits enforced
- ✅ Error messages helpful

---

## Phase 2: Scale for Growth (Week 2-3)

### Problem
Single API key = single rate limit = bottleneck

### Solution: Multiple API Keys + Load Balancing

#### 2.1 Configure Multiple API Keys in FreeLLMAPI
```
1. Get 5-10 API keys from different providers:
   - Claude (Anthropic)
   - GPT (OpenAI)
   - Llama (Meta)
   - Gemini (Google - if quota available)

2. Configure in FreeLLMAPI dashboard:
   - Add each key
   - Set priority/weight
   - Enable load balancing
```

#### 2.2 Implement Model Fallback Chain
```typescript
// supabase/functions/ai-chat/index.ts
const FALLBACK_MODELS = [
  "claude-3.5-sonnet",      // Primary
  "gpt-4o-mini",            // Fallback 1
  "llama-3.1-70b",          // Fallback 2
  "gemini-1.5-flash",       // Fallback 3
];

async function callAiWithFallback(messages, primaryModel) {
  for (const model of FALLBACK_MODELS) {
    try {
      return await callFreeLLMAPI(messages, model);
    } catch (error) {
      if (error.status === 429) {
        console.log(`Model ${model} rate limited, trying next...`);
        continue;
      }
      throw error;
    }
  }
  throw new Error("All models exhausted");
}
```

#### 2.3 Implement Request Queuing
```typescript
// supabase/functions/ai-chat/index.ts
async function handleRequest(prompt, userId) {
  // Check if rate limited
  const rateLimit = await checkRateLimit(userId);
  
  if (!rateLimit.allowed) {
    // Queue the request instead of rejecting
    await queueRequest(userId, prompt);
    return {
      status: 202, // Accepted
      message: "Your request is queued. We'll process it when capacity is available.",
    };
  }
  
  // Process immediately
  return await callAiWithFallback(messages);
}

// Process queued requests when rate limits reset
async function processQueue() {
  const queued = await getQueuedRequests();
  for (const request of queued) {
    try {
      const response = await callAiWithFallback(request.messages);
      await saveResponse(request.userId, response);
    } catch (error) {
      await markQueuedRequestFailed(request.id, error);
    }
  }
}
```

#### 2.4 Implement Response Caching
```typescript
// supabase/functions/ai-chat/index.ts
async function callAiWithCache(messages, model) {
  // Generate cache key from prompt
  const cacheKey = hash(JSON.stringify(messages) + model);
  
  // Check cache
  const cached = await getCache(cacheKey);
  if (cached && cached.age < 24 * 60 * 60 * 1000) {
    return cached.response;
  }
  
  // Call API
  const response = await callFreeLLMAPI(messages, model);
  
  // Cache for 24 hours
  await setCache(cacheKey, response, 24 * 60 * 60);
  
  return response;
}
```

### Success Criteria
- ✅ Multiple API keys configured
- ✅ Fallback chain working
- ✅ Request queuing implemented
- ✅ Caching reduces API calls by 50%+
- ✅ Can handle 10x more concurrent users

---

## Phase 3: Monetization & Premium Tier (Week 3-4)

### Problem
Free tier doesn't scale indefinitely

### Solution: Tiered Pricing

#### 3.1 Create Premium Tier
```dart
// apps/mobile/lib/config/ai_plans.dart
enum AiPlan {
  free,
  premium,
  pro,
}

class AiPlanLimits {
  // Free: 5 req/min, 30 req/hour, 100 req/day
  // Premium: 15 req/min, 100 req/hour, 500 req/day
  // Pro: 30 req/min, 300 req/hour, 2000 req/day
}
```

#### 3.2 Implement Subscription System
```dart
// apps/mobile/lib/services/subscription_service.dart
class SubscriptionService {
  // Integrate with payment provider (Stripe, RevenueCat, etc.)
  Future<void> upgradeToPremium() async {
    // Show payment UI
    // Process payment
    // Update user_profiles.subscription_tier
    // Update rate limits
  }
}
```

#### 3.3 Dedicated API Keys for Premium
```typescript
// supabase/functions/ai-chat/index.ts
async function getApiKeyForUser(userId) {
  const user = await getUser(userId);
  
  if (user.subscription_tier === 'premium') {
    // Use dedicated premium API key
    return PREMIUM_API_KEYS[Math.random() % PREMIUM_API_KEYS.length];
  }
  
  if (user.subscription_tier === 'pro') {
    // Use dedicated pro API key
    return PRO_API_KEYS[Math.random() % PRO_API_KEYS.length];
  }
  
  // Use shared free tier key
  return FREE_API_KEYS[Math.random() % FREE_API_KEYS.length];
}
```

#### 3.4 Revenue Model
```
Free Plan:
- 100 messages/day
- Cost: $0
- Revenue: $0

Premium Plan:
- 500 messages/day
- Cost: $4.99/month
- Revenue: $4.99 × 1000 users = $4,990/month

Pro Plan:
- 2000 messages/day
- Cost: $9.99/month
- Revenue: $9.99 × 500 users = $4,995/month

Total Monthly Revenue: ~$10,000 (at 1500 users)
```

### Success Criteria
- ✅ Payment system integrated
- ✅ Subscription tiers working
- ✅ Premium users get dedicated keys
- ✅ Revenue tracking implemented

---

## Phase 4: Monitoring & Reliability (Week 4-5)

### Problem
Can't operate what you can't see

### Solution: Comprehensive Monitoring

#### 4.1 Metrics to Track
```typescript
// supabase/functions/ai-chat/index.ts
async function recordMetrics(request, response, duration) {
  await supabase.from('metrics').insert({
    user_id: request.userId,
    model: request.model,
    status: response.status,
    duration_ms: duration,
    tokens_input: response.input_tokens,
    tokens_output: response.output_tokens,
    cost: calculateCost(response),
    created_at: new Date(),
  });
}
```

#### 4.2 Dashboards
```
Key Metrics:
- Requests per minute
- Average latency
- Error rate
- Model distribution
- Cost per request
- Revenue per user
- Subscription conversion rate
- Churn rate
```

#### 4.3 Alerts
```
Alert on:
- Error rate > 5%
- Latency > 5 seconds
- Rate limit exhaustion
- API key quota exceeded
- Database connection issues
- Payment processing failures
```

#### 4.4 Health Checks
```bash
# Endpoint health
GET /health

# Database health
SELECT 1 FROM ai_usage LIMIT 1;

# API key health
POST /v1/chat/completions (test request)

# Cache health
GET /cache/health
```

### Success Criteria
- ✅ Metrics collected
- ✅ Dashboards visible
- ✅ Alerts configured
- ✅ Health checks passing

---

## Phase 5: Production Hardening (Week 5-6)

### Problem
Prototype code ≠ production code

### Solution: Hardening Checklist

#### 5.1 Error Handling
- [ ] All errors caught and logged
- [ ] User-friendly error messages
- [ ] No stack traces exposed
- [ ] Graceful degradation
- [ ] Retry logic with exponential backoff
- [ ] Circuit breakers for external APIs

#### 5.2 Security
- [ ] API key rotation mechanism
- [ ] Rate limiting per user
- [ ] Input validation
- [ ] SQL injection prevention
- [ ] XSS prevention
- [ ] CSRF protection
- [ ] Secrets in environment variables
- [ ] HTTPS enforced
- [ ] CORS configured correctly

#### 5.3 Database
- [ ] Backups automated
- [ ] Restore tested
- [ ] Indexes optimized
- [ ] Queries optimized
- [ ] Connection pooling
- [ ] Transaction boundaries correct
- [ ] Data retention policies

#### 5.4 Deployment
- [ ] CI/CD pipeline
- [ ] Automated tests
- [ ] Staging environment
- [ ] Blue-green deployment
- [ ] Rollback procedure
- [ ] Deployment documentation

#### 5.5 Documentation
- [ ] API documentation
- [ ] Deployment guide
- [ ] Runbook for common issues
- [ ] Architecture diagram
- [ ] Database schema documented
- [ ] Configuration documented

### Success Criteria
- ✅ All checklist items completed
- ✅ Security audit passed
- ✅ Load testing passed
- ✅ Disaster recovery tested
- ✅ Ready for production

---

## Implementation Priority

### Must Have (Before Launch)
1. ✅ Fix user profile creation
2. ✅ Fix database errors
3. ✅ Multiple API keys + fallback
4. ✅ Request queuing
5. ✅ Rate limiting enforcement
6. ✅ Error handling
7. ✅ Monitoring
8. ✅ Backups

### Should Have (First Month)
1. Premium tier
2. Payment system
3. Advanced monitoring
4. Load testing
5. Security audit

### Nice to Have (Later)
1. Response caching optimization
2. Advanced analytics
3. User feedback system
4. A/B testing
5. Custom models

---

## Resource Requirements

### Infrastructure
- Supabase PostgreSQL (current)
- Supabase Edge Functions (current)
- Redis for caching (~$10-20/month)
- Monitoring service (~$50-100/month)
- Payment processor (Stripe: 2.9% + $0.30)

### API Costs
- Claude API: $0.003 per 1K input tokens, $0.015 per 1K output tokens
- GPT-4o mini: $0.15 per 1M input tokens, $0.60 per 1M output tokens
- Llama 3.1: Free via FreeLLMAPI
- Gemini: Free tier (limited)

### Estimated Monthly Cost (at 1000 users)
```
Infrastructure:     $100-200
API costs:          $500-1000 (depends on usage)
Payment processing: $1000-2000 (2.9% of revenue)
Total:              $1600-3200/month

Revenue (Premium):  $5000-10000/month
Profit:             $1800-8400/month
```

---

## Timeline & Milestones

### Week 1-2: Stabilize
- Fix user profile creation
- Fix database errors
- Verify core flows
- **Milestone**: Prototype stable

### Week 2-3: Scale
- Add multiple API keys
- Implement fallback chain
- Implement queuing
- **Milestone**: Can handle 10x users

### Week 3-4: Monetize
- Create premium tier
- Integrate payment
- Dedicated API keys
- **Milestone**: Revenue-generating

### Week 4-5: Monitor
- Implement metrics
- Create dashboards
- Configure alerts
- **Milestone**: Observable system

### Week 5-6: Harden
- Security audit
- Load testing
- Disaster recovery
- **Milestone**: Production-ready

---

## Success Metrics

### Technical
- ✅ 99.9% uptime
- ✅ <2s average latency
- ✅ <1% error rate
- ✅ Can handle 1000+ concurrent users

### Business
- ✅ 1000+ users
- ✅ 10% conversion to premium
- ✅ $5000+/month revenue
- ✅ <5% churn rate

### User Experience
- ✅ 4.5+ star rating
- ✅ <2% support tickets
- ✅ 80%+ daily active users
- ✅ <5% bounce rate

---

## Current Status

### Completed ✅
- Basic prototype working
- AI model changed to Claude
- Error handling improved
- Database schema created
- Rate limiting system

### In Progress ⏳
- User profile creation
- Database error fixes
- Testing on device

### Next Steps
1. Fix remaining database issues
2. Test all core flows
3. Plan Phase 2 implementation
4. Set up monitoring
5. Begin Phase 2 (multiple API keys)

---

## Questions to Answer

Before moving to Phase 2:

1. **Target Users**: How many users in first month? First year?
2. **Revenue Model**: Premium pricing confirmed?
3. **Support**: How will you handle support tickets?
4. **Marketing**: How will you acquire users?
5. **Compliance**: Any regulatory requirements (GDPR, CCPA)?
6. **Data**: How long to retain user data?
7. **Moderation**: Content moderation needed?
8. **Localization**: Multiple languages needed?

---

## Summary

**Current Phase**: Prototype Stabilization
**Goal**: Production-ready in 4-6 weeks
**Path**: Stabilize → Scale → Monetize → Monitor → Harden

This roadmap balances:
- ✅ Speed to market
- ✅ Scalability
- ✅ Reliability
- ✅ Revenue generation
- ✅ User experience

**Next Action**: Complete Phase 1 (stabilization) this week.
