/**
 * Custom error classes for Librio API
 * Provides structured error handling and user-friendly messages
 */

export class AppError extends Error {
  constructor(
    public statusCode: number,
    public message: string,
    public code: string,
    public details?: Record<string, any>
  ) {
    super(message);
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

/**
 * Authentication errors (400-401)
 */
export class AuthenticationError extends AppError {
  constructor(message: string, code: string = 'AUTH_ERROR', details?: Record<string, any>) {
    super(401, message, code, details);
    Object.setPrototypeOf(this, AuthenticationError.prototype);
  }
}

export class InvalidCredentialsError extends AppError {
  constructor(message: string = 'Invalid email or password') {
    super(401, message, 'INVALID_CREDENTIALS', undefined);
    Object.setPrototypeOf(this, InvalidCredentialsError.prototype);
  }
}

export class TokenExpiredError extends AppError {
  constructor(message: string = 'Token has expired') {
    super(401, message, 'TOKEN_EXPIRED', undefined);
    Object.setPrototypeOf(this, TokenExpiredError.prototype);
  }
}

export class InvalidTokenError extends AppError {
  constructor(message: string = 'Invalid token') {
    super(401, message, 'INVALID_TOKEN', undefined);
    Object.setPrototypeOf(this, InvalidTokenError.prototype);
  }
}

/**
 * Validation errors (400)
 */
export class ValidationError extends AppError {
  constructor(message: string, details?: Record<string, any>) {
    super(400, message, 'VALIDATION_ERROR', details);
    Object.setPrototypeOf(this, ValidationError.prototype);
  }
}

export class InvalidEmailError extends AppError {
  constructor(message: string = 'Invalid email format') {
    super(400, message, 'INVALID_EMAIL', undefined);
    Object.setPrototypeOf(this, InvalidEmailError.prototype);
  }
}

export class WeakPasswordError extends AppError {
  constructor(message: string = 'Password must be at least 8 characters') {
    super(400, message, 'WEAK_PASSWORD', undefined);
    Object.setPrototypeOf(this, WeakPasswordError.prototype);
  }
}

export class MissingFieldError extends AppError {
  constructor(field: string) {
    super(400, `${field} is required`, 'MISSING_FIELD', { field });
    Object.setPrototypeOf(this, MissingFieldError.prototype);
  }
}

/**
 * Conflict errors (409)
 */
export class ConflictError extends AppError {
  constructor(message: string, code: string = 'CONFLICT', details?: Record<string, any>) {
    super(409, message, code, details);
    Object.setPrototypeOf(this, ConflictError.prototype);
  }
}

export class UserAlreadyExistsError extends AppError {
  constructor(message: string = 'User already exists') {
    super(409, message, 'USER_EXISTS', undefined);
    Object.setPrototypeOf(this, UserAlreadyExistsError.prototype);
  }
}

/**
 * Not found errors (404)
 */
export class NotFoundError extends AppError {
  constructor(resource: string) {
    super(404, `${resource} not found`, 'NOT_FOUND', { resource });
    Object.setPrototypeOf(this, NotFoundError.prototype);
  }
}

/**
 * Server errors (500)
 */
export class InternalServerError extends AppError {
  constructor(message: string = 'Internal server error', details?: Record<string, any>) {
    super(500, message, 'INTERNAL_ERROR', details);
    Object.setPrototypeOf(this, InternalServerError.prototype);
  }
}

export class DatabaseError extends AppError {
  constructor(message: string = 'Database error', details?: Record<string, any>) {
    super(500, message, 'DATABASE_ERROR', details);
    Object.setPrototypeOf(this, DatabaseError.prototype);
  }
}

export class ExternalServiceError extends AppError {
  constructor(service: string, message: string = `${service} service error`) {
    super(503, message, 'EXTERNAL_SERVICE_ERROR', { service });
    Object.setPrototypeOf(this, ExternalServiceError.prototype);
  }
}

/**
 * Rate limiting errors (429)
 */
export class RateLimitError extends AppError {
  constructor(message: string = 'Too many requests', retryAfter?: number) {
    super(429, message, 'RATE_LIMIT', { retryAfter });
    Object.setPrototypeOf(this, RateLimitError.prototype);
  }
}

/**
 * Check if error is an AppError
 */
export function isAppError(error: unknown): error is AppError {
  return error instanceof AppError;
}

/**
 * Get user-friendly error message
 */
export function getUserFriendlyMessage(error: unknown): string {
  if (isAppError(error)) {
    return error.message;
  }

  if (error instanceof Error) {
    return error.message;
  }

  return 'An unexpected error occurred. Please try again.';
}

/**
 * Get error code for client
 */
export function getErrorCode(error: unknown): string {
  if (isAppError(error)) {
    return error.code;
  }

  return 'UNKNOWN_ERROR';
}

/**
 * Get HTTP status code
 */
export function getStatusCode(error: unknown): number {
  if (isAppError(error)) {
    return error.statusCode;
  }

  return 500;
}
