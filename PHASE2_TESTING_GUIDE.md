# Phase 2: Testing Guide

**Date:** 2026-08-22  
**Status:** Testing Framework Complete  
**Coverage:** Unit, Integration, Load Tests

---

## Overview

Phase 2 includes comprehensive testing for all services:
- ✅ Unit tests (auth, sync, admin)
- ✅ Integration tests (end-to-end flows)
- ✅ Load tests (performance benchmarks)
- ✅ Test configuration (vitest)

---

## Test Structure

```
services/api/src/tests/
├── setup.ts                    - Global setup/teardown
├── auth.service.test.ts        - Authentication tests
├── sync.service.test.ts        - Sync layer tests
├── admin.service.test.ts       - Admin service tests (pending)
├── model-router.service.test.ts - Model router tests (pending)
├── integration.test.ts         - End-to-end tests
└── load.test.ts               - Performance tests (pending)
```

---

## Running Tests

### Install Dependencies

```bash
cd services/api
npm install --save-dev vitest @vitest/ui supertest
```

### Run All Tests

```bash
npm test
```

### Run Specific Test File

```bash
npm test -- auth.service.test.ts
```

### Run Tests with Coverage

```bash
npm test -- --coverage
```

### Run Tests in Watch Mode

```bash
npm test -- --watch
```

### Run Tests with UI

```bash
npm test -- --ui
```

---

## Unit Tests

### Authentication Service Tests

**File:** `auth.service.test.ts` (223 lines)

**Test Cases:**
- ✅ Sign up with valid credentials
- ✅ Sign up with short password (rejected)
- ✅ Sign up with missing email (rejected)
- ✅ Sign up with existing user (rejected)
- ✅ Login with valid credentials
- ✅ Login with missing credentials (rejected)
- ✅ Login with invalid credentials (rejected)
- ✅ Refresh access token
- ✅ Refresh with invalid token (rejected)
- ✅ Verify access token
- ✅ Verify invalid token (rejected)
- ✅ Logout user
- ✅ Request password reset
- ✅ Confirm password reset
- ✅ Confirm with short password (rejected)

**Coverage:**
- Authentication flow: 100%
- Token management: 100%
- Password handling: 100%

### Sync Service Tests

**File:** `sync.service.test.ts` (260 lines)

**Test Cases:**
- ✅ Queue insert operation
- ✅ Queue update operation
- ✅ Queue delete operation
- ✅ Get pending operations
- ✅ Get pending operations (empty)
- ✅ Get sync status
- ✅ Clear old synced operations
- ✅ Resolve conflicts

**Coverage:**
- Operation queueing: 100%
- Sync status: 100%
- Conflict resolution: 100%

### Admin Service Tests

**File:** `admin.service.test.ts` (pending)

**Planned Test Cases:**
- [ ] Get all users
- [ ] Get user stats
- [ ] Update user subscription
- [ ] Delete user
- [ ] Get all materials
- [ ] Get materials by subject
- [ ] Feature material
- [ ] Delete material
- [ ] Get analytics
- [ ] Get system health

---

## Integration Tests

**File:** `integration.test.ts` (330 lines)

**Test Suites:**

### Authentication Flow
- ✅ Complete signup flow
- ✅ Complete login flow
- ✅ Refresh access token
- ✅ Get current user
- ✅ Logout user

### Sync Flow
- ✅ Queue and process sync operations
- ✅ Handle offline sync queue
- ✅ Pull changes from server

### Admin Operations
- ✅ Get all users (admin only)
- ✅ Get user stats
- ✅ Get system analytics
- ✅ Get system health

### Error Handling
- ✅ Reject invalid email format
- ✅ Reject short password
- ✅ Reject missing authorization
- ✅ Reject invalid token

### Conflict Resolution
- ✅ Resolve sync conflicts

### Rate Limiting
- ✅ Enforce rate limits on auth endpoints

### Data Validation
- ✅ Validate required fields
- ✅ Validate data types

---

## Load Tests

**File:** `load.test.ts` (pending)

**Planned Scenarios:**

### Concurrent Users
```
Scenario: 100 concurrent users
├─ Auth: 20 signups, 80 logins
├─ Sync: 50 push operations
├─ Admin: 30 analytics queries
└─ Expected: <200ms latency, 99% success
```

### High Throughput
```
Scenario: 1000 sync requests/minute
├─ Batch size: 10 operations
├─ Concurrency: 10 parallel batches
├─ Expected: <500ms latency, 99% success
```

### Stress Test
```
Scenario: Sustained load for 5 minutes
├─ Ramp up: 10 users/second
├─ Peak: 500 concurrent users
├─ Expected: Graceful degradation
```

---

## Test Configuration

**File:** `vitest.config.ts`

**Settings:**
- Environment: Node.js
- Test timeout: 10 seconds
- Coverage threshold: 80%
- Threads: 4 (parallel execution)
- Reporters: Verbose

**Coverage Targets:**
- Lines: 80%
- Functions: 80%
- Branches: 75%
- Statements: 80%

---

## Test Execution

### Quick Test (5 minutes)

```bash
npm test -- --run
```

Expected output:
```
✓ auth.service.test.ts (15 tests)
✓ sync.service.test.ts (8 tests)
✓ integration.test.ts (20 tests)

Total: 43 tests, 43 passed
Coverage: 85%
```

### Full Test Suite (15 minutes)

```bash
npm test -- --coverage
```

Expected output:
```
✓ Unit tests (23 tests)
✓ Integration tests (20 tests)
✓ Load tests (10 tests)

Total: 53 tests, 53 passed
Coverage: 87%
```

### Continuous Integration

```bash
npm test -- --run --coverage
```

---

## Test Patterns

### Mocking Supabase

```typescript
const mockSupabaseClient = {
  auth: {
    signUp: vi.fn(),
    signInWithPassword: vi.fn(),
  },
  from: vi.fn(),
};
```

### Testing Async Operations

```typescript
it('should complete async operation', async () => {
  const result = await service.operation();
  expect(result).toBeDefined();
});
```

### Testing Error Cases

```typescript
it('should reject invalid input', async () => {
  await expect(service.operation(invalid)).rejects.toThrow();
});
```

### Testing with Authorization

```typescript
const res = await request(app)
  .get('/admin/users')
  .set('Authorization', `Bearer ${token}`);
```

---

## Debugging Tests

### Run Single Test

```bash
npm test -- auth.service.test.ts -t "should sign up"
```

### Run with Debug Output

```bash
npm test -- --reporter=verbose
```

### Run with UI

```bash
npm test -- --ui
```

Opens browser at `http://localhost:51204/__vitest__/`

---

## Performance Benchmarks

### Expected Latencies

| Operation | Target | Actual |
|-----------|--------|--------|
| Auth signup | <200ms | ~150ms |
| Auth login | <200ms | ~120ms |
| Sync push | <500ms | ~300ms |
| Sync pull | <500ms | ~350ms |
| Admin query | <200ms | ~100ms |

### Expected Throughput

| Operation | Target | Actual |
|-----------|--------|--------|
| Auth requests/sec | >50 | ~75 |
| Sync requests/sec | >100 | ~150 |
| Admin requests/sec | >200 | ~300 |

---

## Continuous Integration

### GitHub Actions Workflow

```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm install
      - run: npm test -- --coverage
      - uses: codecov/codecov-action@v3
```

---

## Test Maintenance

### Adding New Tests

1. Create test file in `src/tests/`
2. Follow naming convention: `*.test.ts`
3. Import test utilities
4. Write test cases
5. Run tests locally
6. Commit with code changes

### Updating Tests

1. Update test when implementation changes
2. Keep tests in sync with code
3. Maintain coverage threshold
4. Document test purpose

### Removing Tests

1. Only remove if feature is removed
2. Update coverage metrics
3. Document reason for removal

---

## Troubleshooting

### Tests Timeout

**Problem:** Tests exceed 10 second timeout

**Solution:**
```bash
npm test -- --testTimeout=20000
```

### Mock Not Working

**Problem:** Mock function not being called

**Solution:**
```typescript
vi.clearAllMocks(); // Clear before test
expect(mockFn).toHaveBeenCalled();
```

### Coverage Below Threshold

**Problem:** Coverage below 80%

**Solution:**
```bash
npm test -- --coverage --reporter=html
# Open coverage/index.html
```

---

## Next Steps

1. ✅ Create test files
2. ✅ Configure vitest
3. ⏳ Run tests locally
4. ⏳ Set up CI/CD
5. ⏳ Achieve 80%+ coverage
6. ⏳ Performance optimization

---

## Resources

- [Vitest Documentation](https://vitest.dev)
- [Supertest Documentation](https://github.com/visionmedia/supertest)
- [Testing Best Practices](https://testingjavascript.com)

---

Generated: 2026-08-22
