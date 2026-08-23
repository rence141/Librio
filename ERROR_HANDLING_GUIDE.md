# Error Handling Guide - Librio

**Version**: 1.0  
**Last Updated**: August 23, 2026  
**Status**: Phase 3 - Error Handling & User Feedback

---

## Table of Contents

1. [Overview](#overview)
2. [Backend Error Handling](#backend-error-handling)
3. [Mobile Error Handling](#mobile-error-handling)
4. [Error Types](#error-types)
5. [Best Practices](#best-practices)
6. [Testing Error Scenarios](#testing-error-scenarios)

---

## Overview

Librio implements comprehensive error handling across all components:

| Component | Framework | Features |
|-----------|-----------|----------|
| Backend | Custom Error Classes | Structured errors, middleware, logging |
| Mobile | Custom Exceptions | User-friendly messages, retry logic |
| UI | Widgets | Error dialogs, snackbars, loading states |

---

## Backend Error Handling

### Custom Error Classes

**Location**: `services/api/src/utils/errors.ts`

**Hierarchy**:
```
AppError (base)
├── AuthenticationError
│   ├── InvalidCredentialsError
│   ├── TokenExpiredError
│   └── InvalidTokenError
├── ValidationError
│   ├── InvalidEmailError
│   ├── WeakPasswordError
│   └── MissingFieldError
├── ConflictError
│   └── UserAlreadyExistsError
├── NotFoundError
├── InternalServerError
│   ├── DatabaseError
│   └── ExternalServiceError
└── RateLimitError
```

### Error Middleware

**Location**: `services/api/src/middleware/errorHandler.ts`

**Features**:
- ✅ Global error handling
- ✅ Structured error responses
- ✅ Error logging
- ✅ Async error wrapping
- ✅ 404 handling

### Using Errors in Routes

```typescript
import { asyncHandler } from '../middleware/errorHandler';
import { InvalidCredentialsError, ValidationError } from '../utils/errors';

router.post('/auth/login', asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    throw new ValidationError('Email and password are required');
  }

  if (!isValidEmail(email)) {
    throw new InvalidEmailError();
  }

  // ... rest of logic
}));
```

### Error Response Format

```json
{
  "success": false,
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Invalid email or password",
    "details": {
      "field": "password"
    }
  },
  "timestamp": "2026-08-23T10:30:00.000Z",
  "path": "/auth/login"
}
```

---

## Mobile Error Handling

### Custom Exception Classes

**Location**: `apps/mobile/lib/utils/error_handler.dart`

**Exception Hierarchy**:
```
AppException (base)
├── AuthenticationException
│   ├── InvalidCredentialsException
│   └── TokenExpiredException
├── NetworkException
│   └── TimeoutException
├── ValidationException
│   ├── InvalidEmailException
│   └── WeakPasswordException
├── ServerException
└── UnknownException
```

### Error Handler Utility

**Features**:
- ✅ User-friendly messages
- ✅ Error logging
- ✅ Error dialogs
- ✅ Error snackbars
- ✅ Error classification
- ✅ Retry dialogs

### Using Error Handler

```dart
import '../utils/error_handler.dart';

try {
  await authService.signIn(email: email, password: password);
} on InvalidCredentialsException catch (e) {
  ErrorHandler.showErrorDialog(
    context,
    title: 'Login Failed',
    message: e.message,
  );
} on NetworkException catch (e) {
  final shouldRetry = await ErrorHandler.showRetryDialog(
    context,
    title: 'Network Error',
    message: e.message,
  );
  if (shouldRetry) {
    // Retry logic
  }
} catch (e) {
  ErrorHandler.logError(e);
  ErrorHandler.showErrorSnackbar(
    context,
    message: ErrorHandler.getUserMessage(e),
  );
}
```

### Retry Logic

**Simple Retry**:
```dart
try {
  return await RetryHelper.retry(
    () => authService.signIn(email: email, password: password),
    maxRetries: 3,
  );
} catch (e) {
  // Handle error after retries
}
```

**Exponential Backoff**:
```dart
try {
  return await RetryHelper.retryWithBackoff(
    () => authService.signIn(email: email, password: password),
    maxRetries: 3,
    initialDelay: Duration(milliseconds: 100),
    backoffMultiplier: 2.0,
  );
} catch (e) {
  // Handle error after retries
}
```

---

## Error Types

### Authentication Errors (401)

**Examples**:
- Invalid credentials
- Token expired
- Invalid token
- User not authenticated

**Handling**:
```dart
try {
  await authService.signIn(email: email, password: password);
} on InvalidCredentialsException {
  ErrorHandler.showErrorDialog(
    context,
    title: 'Login Failed',
    message: 'Invalid email or password',
  );
} on TokenExpiredException {
  // Redirect to login
  Navigator.of(context).pushReplacementNamed('/login');
}
```

### Validation Errors (400)

**Examples**:
- Invalid email format
- Weak password
- Missing required fields
- Invalid input

**Handling**:
```dart
try {
  await authService.signUp(
    email: email,
    password: password,
    name: name,
  );
} on InvalidEmailException {
  setState(() => emailError = 'Invalid email format');
} on WeakPasswordException {
  setState(() => passwordError = 'Password must be at least 8 characters');
}
```

### Network Errors (Network)

**Examples**:
- Connection timeout
- No internet connection
- Server unreachable
- Request timeout

**Handling**:
```dart
try {
  await authService.signIn(email: email, password: password);
} on NetworkException catch (e) {
  final shouldRetry = await ErrorHandler.showRetryDialog(
    context,
    title: 'Network Error',
    message: e.message,
  );
  if (shouldRetry) {
    // Retry the operation
  }
} on TimeoutException {
  ErrorHandler.showErrorSnackbar(
    context,
    message: 'Request timed out. Please try again.',
  );
}
```

### Server Errors (500)

**Examples**:
- Database error
- Internal server error
- External service error

**Handling**:
```dart
try {
  await authService.signIn(email: email, password: password);
} on ServerException catch (e) {
  ErrorHandler.showErrorDialog(
    context,
    title: 'Server Error',
    message: 'Something went wrong. Please try again later.',
  );
}
```

---

## Loading States

### Loading Overlay

```dart
LoadingOverlay(
  isLoading: authService.isLoading,
  message: 'Signing in...',
  child: YourWidget(),
)
```

### Loading Dialog

```dart
// Show
await LoadingDialog.show(
  context,
  message: 'Signing in...',
);

// Hide
LoadingDialog.hide(context);
```

### Loading Button

```dart
LoadingButton(
  label: 'Sign In',
  isLoading: authService.isLoading,
  onPressed: () => _handleSignIn(),
)
```

### Shimmer Loading

```dart
ShimmerLoading(
  isLoading: isLoading,
  child: YourWidget(),
)
```

---

## Best Practices

### Backend

1. **Use Specific Error Classes**
   ```typescript
   // ✅ Good
   throw new InvalidEmailError();
   
   // ❌ Bad
   throw new Error('Invalid email');
   ```

2. **Include Error Details**
   ```typescript
   // ✅ Good
   throw new ValidationError('Invalid input', { field: 'email' });
   
   // ❌ Bad
   throw new ValidationError('Invalid input');
   ```

3. **Use Async Handler**
   ```typescript
   // ✅ Good
   router.post('/auth/login', asyncHandler(async (req, res) => {
     // ...
   }));
   
   // ❌ Bad
   router.post('/auth/login', async (req, res) => {
     // ...
   });
   ```

4. **Log Errors Properly**
   ```typescript
   // ✅ Good
   logger.error('Login failed', { code, message, details });
   
   // ❌ Bad
   console.log('Error:', error);
   ```

### Mobile

1. **Classify Errors**
   ```dart
   // ✅ Good
   if (ErrorHandler.isNetworkError(error)) {
     // Handle network error
   }
   
   // ❌ Bad
   if (error.toString().contains('network')) {
     // Handle network error
   }
   ```

2. **Use Retry Logic for Network Errors**
   ```dart
   // ✅ Good
   await RetryHelper.retryWithBackoff(
     () => operation(),
     retryIf: (e) => ErrorHandler.isNetworkError(e),
   );
   
   // ❌ Bad
   try {
     await operation();
   } catch (e) {
     await operation(); // Retry without backoff
   }
   ```

3. **Show User-Friendly Messages**
   ```dart
   // ✅ Good
   ErrorHandler.showErrorDialog(
     context,
     title: 'Login Failed',
     message: 'Invalid email or password',
   );
   
   // ❌ Bad
   print(error.toString());
   ```

4. **Handle Loading States**
   ```dart
   // ✅ Good
   LoadingOverlay(
     isLoading: isLoading,
     child: YourWidget(),
   )
   
   // ❌ Bad
   if (isLoading) {
     return CircularProgressIndicator();
   }
   ```

---

## Testing Error Scenarios

### Backend Tests

```typescript
it('should throw InvalidEmailError for invalid email', async () => {
  await expect(
    authService.signUp({
      email: 'invalid-email',
      password: 'TestPassword123',
      fullName: 'Test User',
    })
  ).rejects.toThrow(InvalidEmailError);
});

it('should return 400 for validation error', async () => {
  const response = await request(app)
    .post('/auth/signup')
    .send({
      email: 'invalid-email',
      password: 'TestPassword123',
      fullName: 'Test User',
    });

  expect(response.status).toBe(400);
  expect(response.body.error.code).toBe('INVALID_EMAIL');
});
```

### Mobile Tests

```dart
test('should throw InvalidEmailException for invalid email', () async {
  expect(
    () => authService.signUp(
      email: 'invalid-email',
      password: 'TestPassword123',
      name: 'Test User',
    ),
    throwsA(isA<InvalidEmailException>()),
  );
});

test('should show error dialog on login failure', () async {
  // Mock error
  when(mockAuthService.signIn(...)).thenThrow(InvalidCredentialsException());

  // Verify dialog is shown
  expect(find.byType(AlertDialog), findsOneWidget);
});
```

---

## Error Monitoring

### Sentry Integration (Planned for Phase 4)

```typescript
// Backend
import * as Sentry from "@sentry/node";

Sentry.captureException(error);
```

```dart
// Mobile
import 'package:sentry_flutter/sentry_flutter.dart';

await Sentry.captureException(error);
```

---

## Troubleshooting

### Common Issues

**Issue**: Error dialog not showing
```dart
// ✅ Solution: Ensure context is available
ErrorHandler.showErrorDialog(
  context,  // Make sure context is passed
  title: 'Error',
  message: 'Something went wrong',
);
```

**Issue**: Retry logic not working
```dart
// ✅ Solution: Use proper retry condition
await RetryHelper.retry(
  () => operation(),
  retryIf: (e) => ErrorHandler.isNetworkError(e),  // Specify when to retry
);
```

**Issue**: Loading state stuck
```dart
// ✅ Solution: Always set loading to false
try {
  _setLoading(true);
  await operation();
} finally {
  _setLoading(false);  // Always called
}
```

---

## Summary

### Error Handling Checklist

- [ ] Use specific error classes
- [ ] Include error details
- [ ] Log errors properly
- [ ] Show user-friendly messages
- [ ] Implement retry logic for network errors
- [ ] Handle loading states
- [ ] Test error scenarios
- [ ] Monitor errors in production

---

*Generated: August 23, 2026*  
*Status: Phase 3 - Error Handling Implementation*  
*Next: Phase 4 - Observability & Monitoring*
