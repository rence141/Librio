# Phase 2: Web Backend & Sync

**Status:** Planning  
**Duration:** ~5 weeks (Weeks 8–12 of roadmap)  
**Parallel with:** Phase 1 final testing

---

## Overview

Phase 2 focuses on building the Node.js backend and cloud sync infrastructure. This enables:
- ✅ User authentication (JWT)
- ✅ Cloud data persistence (PostgreSQL)
- ✅ Mobile ↔ Server sync
- ✅ Cloud model fallback (when online)
- ✅ Multi-device access

---

## Current State (End of Phase 1)

✅ **Completed:**
- LLM integration (llamadart)
- Model management (transfer + download)
- RAG system (embeddings + vector DB)
- Supabase backend (PostgreSQL + pgvector)
- REST API skeleton (routes defined)
- Flutter Supabase client
- Node.js Supabase service

⏳ **Pending:**
- Device testing with actual models
- Performance measurement
- Quality validation

---

## Phase 2 Objectives

### Primary Objectives

1. **User Authentication**
   - Email/password signup
   - JWT token management
   - Session persistence
   - Password reset

2. **Cloud Sync**
   - Bidirectional sync (mobile ↔ server)
   - Conflict resolution
   - Offline queue
   - Sync status tracking

3. **Model Router**
   - Detect online/offline
   - Route to local or cloud model
   - Fallback logic
   - Cost optimization

4. **Admin Panel**
   - User management
   - Content management
   - Analytics dashboard
   - System monitoring

---

## Work Streams

### 2a: Node.js API Enhancement

**Current State:**
- ✅ Express server running
- ✅ Supabase routes defined
- ✅ JWT middleware ready

**Phase 2 Work:**
- [ ] Authentication endpoints
  - POST /auth/signup
  - POST /auth/login
  - POST /auth/logout
  - POST /auth/refresh
  - POST /auth/reset-password

- [ ] User profile endpoints
  - GET /users/me
  - PUT /users/me
  - GET /users/:id/progress

- [ ] Content endpoints
  - GET /content/subjects
  - GET /content/materials
  - POST /content/materials (admin)

- [ ] Sync endpoints
  - POST /sync/pull
  - POST /sync/push
  - GET /sync/status

**Estimated Effort:** 2 weeks

### 2b: Database Schema Enhancement

**Current State:**
- ✅ Core tables created (documents, sessions, messages)
- ✅ RLS policies enabled

**Phase 2 Work:**
- [ ] Add tables:
  - `user_progress` (learning history)
  - `materials` (curated content)
  - `sync_queue` (offline changes)
  - `analytics` (usage tracking)

- [ ] Add indexes for performance
- [ ] Add audit trails
- [ ] Add soft deletes

**Estimated Effort:** 1 week

### 2c: Sync Layer

**Current State:**
- ✅ Real-time WebSocket ready
- ✅ Offline-first architecture designed

**Phase 2 Work:**
- [ ] Implement sync protocol
  - Version tracking
  - Change detection
  - Conflict resolution
  - Batch operations

- [ ] Offline queue
  - Store pending changes
  - Retry logic
  - Exponential backoff

- [ ] Sync status
  - Track sync state
  - Show user feedback
  - Handle errors

**Estimated Effort:** 2 weeks

### 2d: Model Router

**Current State:**
- ✅ Local model (llamadart)
- ✅ Supabase backend ready

**Phase 2 Work:**
- [ ] Detect connectivity
  - Network status
  - API health check
  - Fallback detection

- [ ] Route selection
  - Local model (offline)
  - Cloud model (online)
  - Hybrid (best quality)

- [ ] Cost optimization
  - Cache responses
  - Batch requests
  - Rate limiting

**Estimated Effort:** 1 week

### 2e: Admin Panel

**Current State:**
- ✅ API endpoints ready
- ✅ Database schema ready

**Phase 2 Work:**
- [ ] User management
  - List users
  - View profiles
  - Manage permissions
  - View analytics

- [ ] Content management
  - Upload materials
  - Organize subjects
  - Manage access

- [ ] Analytics
  - Usage statistics
  - Learning progress
  - System health

**Estimated Effort:** 2 weeks

---

## Technical Details

### Authentication Flow

```
User Input
  ↓
POST /auth/signup
  ↓
Hash Password (bcrypt)
  ↓
Create User (Supabase Auth)
  ↓
Create Profile (user_profiles)
  ↓
Return JWT Token
  ↓
Store Token (localStorage)
  ↓
Authenticated Requests
```

### Sync Protocol

```
Local Change
  ↓
Add to Sync Queue
  ↓
When Online:
  ├─ Get Server Version
  ├─ Detect Conflicts
  ├─ Merge Changes
  ├─ Push to Server
  └─ Update Local Version
  ↓
Sync Complete
```

### Model Router

```
User Query
  ↓
Check Connectivity
  ↓
If Online:
  ├─ Check Cache
  ├─ Use Cloud Model (better quality)
  └─ Cache Response
  ↓
If Offline:
  ├─ Use Local Model
  └─ Queue for Sync
  ↓
Return Response
```

---

## API Endpoints

### Authentication

```
POST   /auth/signup              - Register new user
POST   /auth/login               - Login with email/password
POST   /auth/logout              - Logout and invalidate token
POST   /auth/refresh             - Refresh JWT token
POST   /auth/reset-password      - Request password reset
POST   /auth/reset-password/:token - Confirm password reset
```

### User Profile

```
GET    /users/me                 - Get current user
PUT    /users/me                 - Update profile
GET    /users/:id/progress       - Get learning progress
```

### Content

```
GET    /content/subjects         - List subjects
GET    /content/materials        - List materials
GET    /content/materials/:id    - Get material details
POST   /content/materials        - Upload material (admin)
DELETE /content/materials/:id    - Delete material (admin)
```

### Sync

```
POST   /sync/pull                - Pull changes from server
POST   /sync/push                - Push changes to server
GET    /sync/status              - Get sync status
```

### Analytics

```
GET    /analytics/usage          - Usage statistics
GET    /analytics/progress       - Learning progress
GET    /analytics/health         - System health
```

---

## Database Schema Additions

### user_progress Table

```sql
CREATE TABLE user_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  subject TEXT NOT NULL,
  topic TEXT,
  questions_answered INTEGER DEFAULT 0,
  correct_answers INTEGER DEFAULT 0,
  time_spent_minutes INTEGER DEFAULT 0,
  last_accessed TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### materials Table

```sql
CREATE TABLE materials (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  subject TEXT NOT NULL,
  content TEXT NOT NULL,
  source TEXT,
  created_by UUID REFERENCES auth.users(id),
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### sync_queue Table

```sql
CREATE TABLE sync_queue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  operation TEXT NOT NULL,  -- 'insert', 'update', 'delete'
  table_name TEXT NOT NULL,
  record_id UUID,
  data JSONB,
  status TEXT DEFAULT 'pending',  -- 'pending', 'synced', 'failed'
  retry_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  synced_at TIMESTAMP WITH TIME ZONE
);
```

---

## Testing Strategy

### Unit Tests
- [ ] Auth service
- [ ] Sync service
- [ ] Model router
- [ ] Database queries

### Integration Tests
- [ ] End-to-end sync
- [ ] Cloud fallback
- [ ] Conflict resolution
- [ ] Auth flow

### Load Tests
- [ ] 100 concurrent users
- [ ] 1000 sync requests/minute
- [ ] API response time <200ms

### Device Tests
- [ ] Sync on Infinix-Note50
- [ ] Offline mode
- [ ] Network switching
- [ ] Battery impact

---

## Success Criteria

- ✅ Sync works end-to-end
- ✅ Cloud fallback functional
- ✅ API latency <200ms
- ✅ Auth flow secure
- ✅ Conflict resolution working
- ✅ Admin panel functional
- ✅ All tests passing
- ✅ Documentation complete

---

## Timeline

| Week | Focus | Deliverable |
|------|-------|-------------|
| 8 | Auth + DB schema | Login/signup working |
| 9 | Sync layer | Bidirectional sync |
| 10 | Model router | Online/offline routing |
| 11 | Admin panel | Content management |
| 12 | Testing + Polish | Release candidate |

---

## Dependencies

### From Phase 1
- ✅ Supabase backend
- ✅ Flutter client
- ✅ REST API skeleton
- ✅ Database schema

### External
- Node.js 18+
- PostgreSQL 14+
- Supabase CLI
- Jest (testing)

---

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Sync bugs block release | Start early, test extensively |
| Cloud costs spiral | Implement rate limiting, caching |
| Performance issues | Load test early, optimize queries |
| Auth vulnerabilities | Use proven libraries, security audit |

---

## Next Steps

1. **Week 8:** Start Phase 2 work streams
2. **Week 9:** Complete sync implementation
3. **Week 10:** Implement model router
4. **Week 11:** Build admin panel
5. **Week 12:** Testing and polish

---

## Deliverables

- ✅ Node.js API with auth
- ✅ Sync layer implementation
- ✅ Model router
- ✅ Admin panel
- ✅ Database schema
- ✅ API documentation
- ✅ Testing suite
- ✅ Deployment guide

---

Generated: 2026-08-22
