# Testing Guide - Librio

**Version**: 1.0  
**Last Updated**: August 23, 2026  
**Status**: Phase 2 - Testing & CI/CD

---

## Table of Contents

1. [Overview](#overview)
2. [Backend Testing](#backend-testing)
3. [Mobile Testing](#mobile-testing)
4. [Running Tests](#running-tests)
5. [Test Coverage](#test-coverage)
6. [CI/CD Pipeline](#cicd-pipeline)
7. [Best Practices](#best-practices)

---

## Overview

Librio uses a comprehensive testing strategy across all components:

| Component | Framework | Coverage Target | Status |
|-----------|-----------|-----------------|--------|
| Backend API | Vitest + Supertest | 70%+ | ✅ Implemented |
| Mobile App | Flutter Test | 70%+ | ✅ Implemented |
| CI/CD | GitHub Actions | All checks | ✅ Configured |

---

## Backend Testing

### Unit Tests

**Location**: `services/api/src/**/*.test.ts`

**Test Files**:
- `auth.service.test.ts` - Authentication service tests
- `auth.routes.test.ts` - API endpoint tests

**What's Tested**:

#### AuthService Tests
- ✅ User signup with validation
- ✅ User login with password verification
- ✅ Token refresh mechanism
- ✅ Token verification
- ✅ Google token verification
- ✅ Password reset flow
- ✅ Logout functionality

#### Auth Routes Tests
- ✅ POST /auth/signup
- ✅ POST /auth/login
- ✅ POST /auth/refresh
- ✅ POST /auth/google
- ✅ POST /auth/request-password-reset
- ✅ POST /auth/confirm-password-reset
- ✅ Error handling and validation

### Running Backend Tests

```bash
cd services/api

# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with UI
npm run test:ui

# Run tests with coverage
npm run test:coverage
```

### Test Examples

**Example 1: Testing signup validation**
```typescript
it('should reject signup with short password', async () => {
  await expect(
    authService.signUp({
      email: 'test@example.com',
      password: 'short',
      fullName: 'Test User',
    })
  ).rejects.toThrow('Password must be at least 8 characters');
});
```

**Example 2: Testing login with correct credentials**
```typescript
it('should successfully login with correct credentials', async () => {
  const hashedPassword = await bcrypt.hash('TestPassword123', 10);
  
  // Mock database response
  mockSupabaseClient.from.mockReturnValue({
    select: mockSelect,
  });

  const result = await authService.login({
    email: 'test@example.com',
    password: 'TestPassword123',
  });

  expect(result).toHaveProperty('accessToken');
  expect(result).toHaveProperty('refreshToken');
});
```

---

## Mobile Testing

### Unit Tests

**Location**: `apps/mobile/test/**/*.dart`

**Test Files**:
- `services/auth_service_v2_test.dart` - Auth service tests

**What's Tested**:
- ✅ Email validation
- ✅ Password validation
- ✅ Sign up validation
- ✅ Login validation
- ✅ Logout functionality
- ✅ Token refresh logic

### Widget Tests

**Location**: `apps/mobile/test/widgets/**/*.dart`

**Planned Tests**:
- Login screen UI
- Signup screen UI
- Google Sign-In button
- Error dialogs
- Loading states

### Running Mobile Tests

```bash
cd apps/mobile

# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/services/auth_service_v2_test.dart

# Run tests with verbose output
flutter test -v
```

### Test Example

```dart
test('should reject signup with invalid email', () async {
  expect(
    () => authService.signUp(
      email: 'invalid-email',
      password: 'TestPassword123',
      name: 'Test User',
    ),
    throwsException,
  );
});
```

---

## Running Tests

### All Tests

```bash
# Run all tests (backend + mobile)
./scripts/run-all-tests.sh
```

### Backend Only

```bash
cd services/api
npm test
```

### Mobile Only

```bash
cd apps/mobile
flutter test
```

### Specific Test

```bash
# Backend
cd services/api
npm test -- auth.service.test.ts

# Mobile
cd apps/mobile
flutter test test/services/auth_service_v2_test.dart
```

---

## Test Coverage

### Coverage Targets

| Component | Target | Current | Status |
|-----------|--------|---------|--------|
| Backend | 70%+ | TBD | ⏳ In Progress |
| Mobile | 70%+ | TBD | ⏳ In Progress |

### Generating Coverage Reports

**Backend**:
```bash
cd services/api
npm run test:coverage

# View HTML report
open coverage/index.html
```

**Mobile**:
```bash
cd apps/mobile
flutter test --coverage

# View HTML report
open coverage/index.html
```

### Coverage Thresholds

```typescript
// vitest.config.ts
coverage: {
  lines: 70,
  functions: 70,
  branches: 70,
  statements: 70,
}
```

---

## CI/CD Pipeline

### GitHub Actions Workflow

**File**: `.github/workflows/ci.yml`

**Jobs**:

1. **Flutter Lint & Test**
   - Runs on every push and PR
   - Lints Flutter code
   - Runs Flutter tests
   - Checks code formatting

2. **Node.js Lint & Test**
   - Runs on every push and PR
   - Lints TypeScript code
   - Builds TypeScript
   - Runs Vitest tests

3. **Security Checks**
   - Detects secrets in code
   - Checks for .env files
   - Runs on every push and PR

4. **Build Artifacts**
   - Builds APK for Android
   - Builds Docker image
   - Runs on main branch only

### Pipeline Status

View pipeline status:
```bash
# Check GitHub Actions
gh run list

# View specific run
gh run view <run-id>

# View logs
gh run view <run-id> --log
```

### Triggering Pipeline

Pipeline automatically runs on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

Manual trigger:
```bash
gh workflow run ci.yml
```

---

## Pre-Commit Hooks

### Setup

```bash
# Install husky
npm install husky --save-dev

# Install pre-commit hook
npx husky install

# Add pre-commit hook
npx husky add .husky/pre-commit 'npm run lint && flutter analyze'
```

### What Runs

Before each commit:
1. ✅ Check for .env files
2. ✅ Check for secrets
3. ✅ Lint backend code
4. ✅ Analyze mobile code

### Bypassing Hooks

```bash
# Skip pre-commit hooks (not recommended)
git commit --no-verify
```

---

## Best Practices

### Writing Tests

1. **Use Descriptive Names**
   ```typescript
   // ✅ Good
   it('should reject signup with short password', async () => {});
   
   // ❌ Bad
   it('should fail', async () => {});
   ```

2. **Test One Thing**
   ```typescript
   // ✅ Good - Tests one behavior
   it('should hash password before storing', async () => {});
   
   // ❌ Bad - Tests multiple things
   it('should signup and hash password and verify email', async () => {});
   ```

3. **Use Arrange-Act-Assert**
   ```typescript
   // Arrange
   const mockData = { email: 'test@example.com' };
   
   // Act
   const result = await authService.signUp(mockData);
   
   // Assert
   expect(result).toHaveProperty('accessToken');
   ```

4. **Mock External Dependencies**
   ```typescript
   // Mock Supabase
   mockSupabaseClient.from.mockReturnValue({
     insert: mockInsert,
   });
   ```

5. **Test Error Cases**
   ```typescript
   // Test success
   it('should successfully login', async () => {});
   
   // Test error
   it('should reject login with invalid password', async () => {});
   ```

### Test Organization

```
services/api/src/
├── services/
│   ├── auth.service.ts
│   └── auth.service.test.ts
├── routes/
│   ├── auth.routes.ts
│   └── auth.routes.test.ts

apps/mobile/test/
├── services/
│   └── auth_service_v2_test.dart
├── widgets/
│   ├── login_screen_test.dart
│   └── signup_screen_test.dart
```

### Naming Conventions

**Test Files**:
- Backend: `*.test.ts` or `*.spec.ts`
- Mobile: `*_test.dart`

**Test Groups**:
```typescript
describe('AuthService', () => {
  describe('signUp', () => {
    it('should...', () => {});
  });
});
```

---

## Troubleshooting

### Backend Tests Failing

```bash
# Clear cache
rm -rf node_modules/.vite

# Reinstall dependencies
npm ci

# Run tests with verbose output
npm test -- --reporter=verbose
```

### Mobile Tests Failing

```bash
# Clear Flutter cache
flutter clean

# Get dependencies
flutter pub get

# Run tests with verbose output
flutter test -v
```

### Coverage Not Generated

**Backend**:
```bash
# Install coverage provider
npm install --save-dev @vitest/coverage-v8

# Generate coverage
npm run test:coverage
```

**Mobile**:
```bash
# Generate coverage
flutter test --coverage

# Install lcov (macOS)
brew install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html
```

---

## Test Metrics

### Current Status

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Unit Tests | 50+ | 30+ | ⏳ In Progress |
| Integration Tests | 20+ | 10+ | ⏳ In Progress |
| Code Coverage | 70%+ | TBD | ⏳ In Progress |
| Test Pass Rate | 100% | TBD | ⏳ In Progress |

### Tracking Progress

```bash
# Backend test count
cd services/api
grep -r "it(" src/**/*.test.ts | wc -l

# Mobile test count
cd apps/mobile
grep -r "test(" test/**/*.dart | wc -l
```

---

## Continuous Improvement

### Adding New Tests

1. Write test first (TDD)
2. Run test (should fail)
3. Implement feature
4. Run test (should pass)
5. Refactor if needed
6. Commit with test

### Test Review Checklist

- [ ] Test name is descriptive
- [ ] Test covers one behavior
- [ ] Test has proper assertions
- [ ] Test handles error cases
- [ ] Test doesn't depend on other tests
- [ ] Test runs in isolation
- [ ] Test is fast (< 1 second)

---

## Resources

### Documentation
- [Vitest Documentation](https://vitest.dev/)
- [Supertest Documentation](https://github.com/visionmedia/supertest)
- [Flutter Testing Guide](https://flutter.dev/docs/testing)

### Tools
- [GitHub Actions](https://github.com/features/actions)
- [Husky](https://typicode.github.io/husky/)
- [Coverage.py](https://coverage.readthedocs.io/)

---

## Next Steps

### Phase 2 Completion
- [ ] Achieve 70%+ code coverage
- [ ] All tests passing
- [ ] CI/CD pipeline verified
- [ ] Pre-commit hooks working

### Phase 3 (Error Handling)
- [ ] Add error handling tests
- [ ] Test error dialogs
- [ ] Test retry logic
- [ ] Test timeout handling

---

*Generated: August 23, 2026*  
*Status: Phase 2 - Testing Implementation*  
*Next: Test Coverage & CI/CD Verification*
