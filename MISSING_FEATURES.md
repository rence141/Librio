# Missing Features for Production

**Date**: 2026-08-25
**Status**: Comprehensive feature gap analysis
**Scope**: Excluding web chat interface

---

## Overview

Based on the prototype-to-production roadmap, here are all features needed to reach each phase.

---

## Phase 1: Stabilize (Week 1-2) - CRITICAL

### 1.1 Database & User Management
- [ ] **User Profile Creation on Signup**
  - Status: Partially implemented (trigger exists but may not be firing)
  - Issue: User profiles not created automatically
  - Fix: Verify trigger or create via Edge Function
  - Priority: CRITICAL

- [ ] **User Profile Verification**
  - Status: Not verified
  - Need: Check if `user_profiles` table has all required fields
  - Fields needed: `id`, `email`, `subscription_tier`, `created_at`, `updated_at`
  - Priority: CRITICAL

- [ ] **RLS Policy Verification**
  - Status: Policies exist but not tested
  - Need: Verify users can read their own data
  - Test: Query `ai_usage` and `user_profiles` as authenticated user
  - Priority: CRITICAL

### 1.2 AI Usage Tracking
- [ ] **Usage Recording Verification**
  - Status: Edge Function records usage, but not verified on device
  - Need: Test that `ai_usage` records are created
  - Test: Send message, check database
  - Priority: CRITICAL

- [ ] **Usage Data Retrieval**
  - Status: Service returns default on error
  - Need: Verify actual usage data is fetched correctly
  - Test: Check usage panel shows correct data
  - Priority: CRITICAL

### 1.3 Rate Limiting
- [ ] **Rate Limit Enforcement**
  - Status: Implemented but not tested
  - Need: Test hitting rate limits
  - Test: Make 5 requests, verify 6th is blocked
  - Priority: CRITICAL

- [ ] **Reset Time Display**
  - Status: Implemented but not tested
  - Need: Verify reset times show correctly
  - Test: Hit limit, check message shows reset time
  - Priority: CRITICAL

### 1.4 Error Handling
- [ ] **Graceful Degradation**
  - Status: Implemented (returns default plan on error)
  - Need: Test that app works when usage fetch fails
  - Test: Disconnect database, verify app still works
  - Priority: HIGH

- [ ] **Error Logging**
  - Status: Implemented
  - Need: Verify errors are logged with full context
  - Test: Check logs for detailed error messages
  - Priority: MEDIUM

### 1.5 Testing & Documentation
- [ ] **Core Flow Testing**
  - Status: Not done
  - Need: Test all critical user flows
  - Flows: Sign up → Chat → View usage → Hit limit
  - Priority: CRITICAL

- [ ] **Bug Documentation**
  - Status: Not done
  - Need: Document any issues found during testing
  - Priority: HIGH

---

## Phase 2: Scale (Week 2-3) - HIGH PRIORITY

### 2.1 Multiple API Keys
- [ ] **API Key Configuration**
  - Status: Not implemented
  - Need: Configure 5-10 API keys in FreeLLMAPI
  - Keys: Claude, GPT-4o mini, Llama 3.1, Gemini 1.5
  - Priority: HIGH

- [ ] **Load Balancing**
  - Status: Not implemented
  - Need: Distribute requests across keys
  - Implementation: Round-robin or weighted distribution
  - Priority: HIGH

### 2.2 Model Fallback Chain
- [ ] **Fallback Implementation**
  - Status: Not implemented
  - Need: Try next model if current is rate limited
  - Chain: Claude → GPT → Llama → Gemini
  - Location: `supabase/functions/ai-chat/index.ts`
  - Priority: HIGH

- [ ] **Fallback Testing**
  - Status: Not done
  - Need: Test fallback when primary model fails
  - Test: Simulate rate limit, verify fallback works
  - Priority: HIGH

### 2.3 Request Queuing
- [ ] **Queue Table Creation**
  - Status: Not implemented
  - Need: Create `request_queue` table in Supabase
  - Fields: `id`, `user_id`, `prompt`, `status`, `created_at`
  - Priority: HIGH

- [ ] **Queue Logic Implementation**
  - Status: Not implemented
  - Need: Queue requests when rate limited
  - Location: `supabase/functions/ai-chat/index.ts`
  - Priority: HIGH

- [ ] **Queue Processing**
  - Status: Not implemented
  - Need: Background job to process queued requests
  - Trigger: When rate limits reset
  - Priority: HIGH

- [ ] **Queue Testing**
  - Status: Not done
  - Need: Test queuing and processing
  - Test: Queue 10 requests, verify all process
  - Priority: HIGH

### 2.4 Response Caching
- [ ] **Cache Implementation**
  - Status: Not implemented
  - Need: Cache responses for 24 hours
  - Storage: Redis or Supabase
  - Priority: MEDIUM

- [ ] **Cache Key Generation**
  - Status: Not implemented
  - Need: Generate cache key from prompt + model
  - Implementation: Hash function
  - Priority: MEDIUM

- [ ] **Cache Testing**
  - Status: Not done
  - Need: Test cache hit/miss rates
  - Test: Send same prompt twice, verify cache hit
  - Priority: MEDIUM

### 2.5 Load Testing
- [ ] **Load Test Setup**
  - Status: Not done
  - Need: Set up load testing infrastructure
  - Tool: k6, JMeter, or similar
  - Priority: HIGH

- [ ] **Concurrent User Testing**
  - Status: Not done
  - Need: Test with 100+ concurrent users
  - Target: <2s latency, <1% error rate
  - Priority: HIGH

- [ ] **Load Test Results**
  - Status: Not done
  - Need: Document findings and bottlenecks
  - Priority: HIGH

---

## Phase 3: Monetize (Week 3-4) - MEDIUM PRIORITY

### 3.1 Premium Tier
- [ ] **Tier Definition**
  - Status: Defined in code but not enforced
  - Need: Implement tier enforcement
  - Tiers: Free (5 req/min), Premium (15 req/min), Pro (30 req/min)
  - Priority: MEDIUM

- [ ] **Tier Storage**
  - Status: `subscription_tier` field exists
  - Need: Verify field is populated correctly
  - Test: Check user_profiles.subscription_tier
  - Priority: MEDIUM

### 3.2 Payment System
- [ ] **Payment Provider Integration**
  - Status: Not implemented
  - Need: Choose payment provider (Stripe, RevenueCat, etc.)
  - Priority: MEDIUM

- [ ] **Payment UI**
  - Status: Not implemented
  - Need: Create upgrade UI in Flutter app
  - Location: `apps/mobile/lib/screens/settings_screen.dart`
  - Priority: MEDIUM

- [ ] **Payment Processing**
  - Status: Not implemented
  - Need: Process payments and update subscription
  - Location: Backend API endpoint
  - Priority: MEDIUM

- [ ] **Payment Testing**
  - Status: Not done
  - Need: Test payment flow end-to-end
  - Test: Upgrade to premium, verify tier changes
  - Priority: MEDIUM

### 3.3 Dedicated API Keys for Premium
- [ ] **Premium Key Configuration**
  - Status: Not implemented
  - Need: Configure separate keys for premium users
  - Priority: MEDIUM

- [ ] **Key Selection Logic**
  - Status: Not implemented
  - Need: Select key based on subscription tier
  - Location: `supabase/functions/ai-chat/index.ts`
  - Priority: MEDIUM

### 3.4 Revenue Tracking
- [ ] **Revenue Table**
  - Status: Not implemented
  - Need: Create `revenue` table to track payments
  - Fields: `id`, `user_id`, `amount`, `plan`, `created_at`
  - Priority: MEDIUM

- [ ] **Revenue Dashboard**
  - Status: Not implemented
  - Need: Create admin dashboard to view revenue
  - Location: Web admin panel
  - Priority: LOW

---

## Phase 4: Monitor (Week 4-5) - MEDIUM PRIORITY

### 4.1 Metrics Collection
- [ ] **Metrics Table**
  - Status: Not implemented
  - Need: Create `metrics` table
  - Fields: `id`, `user_id`, `model`, `status`, `duration_ms`, `tokens_input`, `tokens_output`, `cost`, `created_at`
  - Priority: MEDIUM

- [ ] **Metrics Recording**
  - Status: Partially implemented (latency_ms is TODO)
  - Need: Record all metrics for each request
  - Location: `supabase/functions/ai-chat/index.ts`
  - Priority: MEDIUM

- [ ] **Metrics Aggregation**
  - Status: Not implemented
  - Need: Aggregate metrics by hour/day
  - Priority: MEDIUM

### 4.2 Dashboards
- [ ] **Admin Dashboard**
  - Status: Not implemented
  - Need: Create web dashboard to view metrics
  - Metrics: Requests/min, latency, error rate, cost
  - Priority: MEDIUM

- [ ] **User Dashboard**
  - Status: Partially implemented (usage panel exists)
  - Need: Expand to show historical usage
  - Priority: LOW

### 4.3 Alerts
- [ ] **Alert System**
  - Status: Not implemented
  - Need: Set up alerting for critical issues
  - Alerts: Error rate > 5%, latency > 5s, quota exceeded
  - Priority: MEDIUM

- [ ] **Alert Notifications**
  - Status: Not implemented
  - Need: Send alerts via email/Slack
  - Priority: MEDIUM

### 4.4 Health Checks
- [ ] **Health Check Endpoint**
  - Status: Partially implemented
  - Need: Create comprehensive health check
  - Checks: Database, API keys, cache, rate limits
  - Priority: MEDIUM

- [ ] **Health Monitoring**
  - Status: Not implemented
  - Need: Monitor health checks continuously
  - Tool: Uptime monitoring service
  - Priority: MEDIUM

---

## Phase 5: Harden (Week 5-6) - HIGH PRIORITY

### 5.1 Security
- [ ] **API Key Rotation**
  - Status: Not implemented
  - Need: Implement key rotation mechanism
  - Frequency: Every 90 days
  - Priority: HIGH

- [ ] **Input Validation**
  - Status: Basic validation exists
  - Need: Comprehensive input validation
  - Location: All API endpoints
  - Priority: HIGH

- [ ] **SQL Injection Prevention**
  - Status: Using parameterized queries
  - Need: Verify all queries are safe
  - Priority: HIGH

- [ ] **XSS Prevention**
  - Status: Flutter app (not applicable)
  - Need: Verify API responses are safe
  - Priority: MEDIUM

- [ ] **Rate Limiting per User**
  - Status: Implemented
  - Need: Verify limits are enforced correctly
  - Priority: HIGH

- [ ] **Secrets Management**
  - Status: Using environment variables
  - Need: Verify secrets are not logged
  - Priority: HIGH

### 5.2 Database
- [ ] **Automated Backups**
  - Status: Supabase provides backups
  - Need: Verify backup schedule
  - Frequency: Daily
  - Priority: HIGH

- [ ] **Backup Testing**
  - Status: Not done
  - Need: Test restore procedure
  - Priority: HIGH

- [ ] **Index Optimization**
  - Status: Indexes exist
  - Need: Verify indexes are optimal
  - Priority: MEDIUM

- [ ] **Query Optimization**
  - Status: Not done
  - Need: Optimize slow queries
  - Priority: MEDIUM

### 5.3 Deployment
- [ ] **CI/CD Pipeline**
  - Status: Not implemented
  - Need: Set up GitHub Actions or similar
  - Steps: Test → Build → Deploy
  - Priority: HIGH

- [ ] **Automated Testing**
  - Status: Not implemented
  - Need: Set up unit and integration tests
  - Priority: HIGH

- [ ] **Staging Environment**
  - Status: Not implemented
  - Need: Create staging environment for testing
  - Priority: HIGH

- [ ] **Blue-Green Deployment**
  - Status: Not implemented
  - Need: Implement zero-downtime deployments
  - Priority: MEDIUM

- [ ] **Rollback Procedure**
  - Status: Not documented
  - Need: Document rollback steps
  - Priority: HIGH

### 5.4 Documentation
- [ ] **API Documentation**
  - Status: Not done
  - Need: Document all API endpoints
  - Tool: Swagger/OpenAPI
  - Priority: MEDIUM

- [ ] **Deployment Guide**
  - Status: Not done
  - Need: Document deployment steps
  - Priority: HIGH

- [ ] **Runbook**
  - Status: Not done
  - Need: Document common issues and fixes
  - Priority: MEDIUM

- [ ] **Architecture Diagram**
  - Status: Not done
  - Need: Create architecture diagram
  - Priority: MEDIUM

### 5.5 Performance
- [ ] **Latency Optimization**
  - Status: Not done
  - Need: Optimize for <2s latency
  - Areas: Database queries, API calls, caching
  - Priority: MEDIUM

- [ ] **Memory Optimization**
  - Status: Not done
  - Need: Optimize memory usage
  - Priority: MEDIUM

- [ ] **Bundle Size Optimization**
  - Status: Not done
  - Need: Reduce Flutter app bundle size
  - Priority: LOW

---

## Optional Features (Nice to Have)

### Analytics
- [ ] **User Analytics**
  - Track user behavior
  - Identify usage patterns
  - Priority: LOW

- [ ] **Funnel Analysis**
  - Track conversion funnel
  - Identify drop-off points
  - Priority: LOW

### Content Moderation
- [ ] **Content Filter**
  - Filter inappropriate content
  - Priority: LOW

- [ ] **Abuse Detection**
  - Detect and prevent abuse
  - Priority: LOW

### Localization
- [ ] **Multi-language Support**
  - Support multiple languages
  - Priority: LOW

- [ ] **Regional Pricing**
  - Different pricing by region
  - Priority: LOW

### Advanced Features
- [ ] **Conversation History**
  - Save and restore conversations
  - Status: Partially implemented
  - Priority: MEDIUM

- [ ] **Export Conversations**
  - Export as PDF/text
  - Priority: LOW

- [ ] **Sharing**
  - Share conversations with others
  - Priority: LOW

---

## Summary by Priority

### CRITICAL (Must do before Phase 1 complete)
1. User profile creation verification
2. RLS policy verification
3. Usage tracking verification
4. Rate limit enforcement testing
5. Reset time display testing
6. Core flow testing

### HIGH (Must do for production)
1. Multiple API keys
2. Model fallback chain
3. Request queuing
4. Load testing
5. Security audit
6. Automated backups
7. CI/CD pipeline
8. Deployment guide

### MEDIUM (Should do before launch)
1. Response caching
2. Premium tier implementation
3. Payment system
4. Metrics collection
5. Dashboards
6. Alerts
7. Health checks
8. Database optimization

### LOW (Nice to have)
1. Analytics
2. Content moderation
3. Localization
4. Advanced features
5. Admin dashboard

---

## Implementation Order

### Week 1-2 (Phase 1)
1. User profile creation
2. RLS verification
3. Usage tracking
4. Rate limit testing
5. Core flow testing

### Week 2-3 (Phase 2)
1. Multiple API keys
2. Fallback chain
3. Request queuing
4. Load testing

### Week 3-4 (Phase 3)
1. Premium tier
2. Payment system
3. Revenue tracking

### Week 4-5 (Phase 4)
1. Metrics collection
2. Dashboards
3. Alerts
4. Health checks

### Week 5-6 (Phase 5)
1. Security audit
2. Automated backups
3. CI/CD pipeline
4. Deployment guide

---

## Effort Estimation

| Feature | Effort | Timeline |
|---------|--------|----------|
| User profile fix | 1-2 hours | Day 1 |
| RLS verification | 1-2 hours | Day 1 |
| Usage tracking test | 2-3 hours | Day 2 |
| Rate limit testing | 2-3 hours | Day 2 |
| Multiple API keys | 4-6 hours | Day 3-4 |
| Fallback chain | 4-6 hours | Day 4-5 |
| Request queuing | 6-8 hours | Day 5-6 |
| Load testing | 4-6 hours | Day 6-7 |
| Premium tier | 8-10 hours | Day 8-10 |
| Payment system | 12-16 hours | Day 10-14 |
| Metrics collection | 6-8 hours | Day 15-16 |
| Dashboards | 8-10 hours | Day 16-18 |
| Security audit | 8-10 hours | Day 19-20 |
| CI/CD pipeline | 6-8 hours | Day 20-21 |

**Total**: ~100-130 hours (3-4 weeks)

---

## Success Metrics

### Phase 1
- ✅ All core flows working
- ✅ No database errors
- ✅ Rate limits enforced
- ✅ Error messages helpful

### Phase 2
- ✅ Handle 1000+ concurrent users
- ✅ <2s average latency
- ✅ <1% error rate
- ✅ Multiple API keys working

### Phase 3
- ✅ 10% premium conversion
- ✅ $5000+/month revenue
- ✅ Payment system working

### Phase 4
- ✅ 99.9% uptime
- ✅ Metrics visible
- ✅ Alerts working

### Phase 5
- ✅ Production-ready
- ✅ Security audit passed
- ✅ Load testing passed
- ✅ Disaster recovery tested

---

**Status**: Feature gap analysis complete
**Next**: Execute Phase 1 (stabilization)
**Timeline**: 4-6 weeks to production-ready
