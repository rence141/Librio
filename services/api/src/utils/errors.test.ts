import { describe, it, expect } from 'vitest';
import {
  AppError,
  AuthenticationError,
  InvalidCredentialsError,
  ValidationError,
  InvalidEmailError,
  WeakPasswordError,
  ConflictError,
  NotFoundError,
  InternalServerError,
  isAppError,
  getUserFriendlyMessage,
  getErrorCode,
  getStatusCode,
} from './errors';

describe('Error Classes', () => {
  describe('AppError', () => {
    it('should create an AppError with correct properties', () => {
      const error = new AppError(400, 'Test error', 'TEST_ERROR', { field: 'test' });

      expect(error.statusCode).toBe(400);
      expect(error.message).toBe('Test error');
      expect(error.code).toBe('TEST_ERROR');
      expect(error.details).toEqual({ field: 'test' });
    });

    it('should be instanceof AppError', () => {
      const error = new AppError(400, 'Test', 'TEST', {});
      expect(error instanceof AppError).toBe(true);
    });
  });

  describe('AuthenticationError', () => {
    it('should create an AuthenticationError with 401 status', () => {
      const error = new AuthenticationError('Auth failed', 'AUTH_FAILED');

      expect(error.statusCode).toBe(401);
      expect(error.message).toBe('Auth failed');
      expect(error.code).toBe('AUTH_FAILED');
    });

    it('should be instanceof AppError', () => {
      const error = new AuthenticationError('Auth failed');
      expect(error instanceof AppError).toBe(true);
    });
  });

  describe('InvalidCredentialsError', () => {
    it('should create an InvalidCredentialsError with default message', () => {
      const error = new InvalidCredentialsError();

      expect(error.statusCode).toBe(401);
      expect(error.message).toBe('Invalid email or password');
      expect(error.code).toBe('INVALID_CREDENTIALS');
    });

    it('should allow custom message', () => {
      const error = new InvalidCredentialsError('Wrong password');

      expect(error.message).toBe('Wrong password');
    });
  });

  describe('ValidationError', () => {
    it('should create a ValidationError with 400 status', () => {
      const error = new ValidationError('Invalid input', { field: 'email' });

      expect(error.statusCode).toBe(400);
      expect(error.message).toBe('Invalid input');
      expect(error.code).toBe('VALIDATION_ERROR');
      expect(error.details).toEqual({ field: 'email' });
    });
  });

  describe('InvalidEmailError', () => {
    it('should create an InvalidEmailError with default message', () => {
      const error = new InvalidEmailError();

      expect(error.statusCode).toBe(400);
      expect(error.message).toBe('Invalid email format');
      expect(error.code).toBe('INVALID_EMAIL');
    });
  });

  describe('WeakPasswordError', () => {
    it('should create a WeakPasswordError with default message', () => {
      const error = new WeakPasswordError();

      expect(error.statusCode).toBe(400);
      expect(error.message).toBe('Password must be at least 8 characters');
      expect(error.code).toBe('WEAK_PASSWORD');
    });
  });

  describe('ConflictError', () => {
    it('should create a ConflictError with 409 status', () => {
      const error = new ConflictError('Resource already exists', 'EXISTS');

      expect(error.statusCode).toBe(409);
      expect(error.message).toBe('Resource already exists');
      expect(error.code).toBe('EXISTS');
    });
  });

  describe('NotFoundError', () => {
    it('should create a NotFoundError with 404 status', () => {
      const error = new NotFoundError('User');

      expect(error.statusCode).toBe(404);
      expect(error.message).toBe('User not found');
      expect(error.code).toBe('NOT_FOUND');
      expect(error.details).toEqual({ resource: 'User' });
    });
  });

  describe('InternalServerError', () => {
    it('should create an InternalServerError with 500 status', () => {
      const error = new InternalServerError('Database error');

      expect(error.statusCode).toBe(500);
      expect(error.message).toBe('Database error');
      expect(error.code).toBe('INTERNAL_ERROR');
    });
  });

  describe('isAppError', () => {
    it('should return true for AppError instances', () => {
      const error = new AppError(400, 'Test', 'TEST', {});
      expect(isAppError(error)).toBe(true);
    });

    it('should return true for subclass instances', () => {
      const error = new InvalidCredentialsError();
      expect(isAppError(error)).toBe(true);
    });

    it('should return false for regular errors', () => {
      const error = new Error('Regular error');
      expect(isAppError(error)).toBe(false);
    });

    it('should return false for non-error objects', () => {
      expect(isAppError('not an error')).toBe(false);
      expect(isAppError(null)).toBe(false);
      expect(isAppError(undefined)).toBe(false);
    });
  });

  describe('getUserFriendlyMessage', () => {
    it('should return AppError message', () => {
      const error = new InvalidCredentialsError('Wrong password');
      expect(getUserFriendlyMessage(error)).toBe('Wrong password');
    });

    it('should return Error message', () => {
      const error = new Error('Test error');
      expect(getUserFriendlyMessage(error)).toBe('Test error');
    });

    it('should return default message for non-error objects', () => {
      expect(getUserFriendlyMessage('not an error')).toBe(
        'An unexpected error occurred. Please try again.'
      );
      expect(getUserFriendlyMessage(null)).toBe(
        'An unexpected error occurred. Please try again.'
      );
    });
  });

  describe('getErrorCode', () => {
    it('should return error code for AppError', () => {
      const error = new InvalidCredentialsError();
      expect(getErrorCode(error)).toBe('INVALID_CREDENTIALS');
    });

    it('should return UNKNOWN_ERROR for non-AppError', () => {
      const error = new Error('Test');
      expect(getErrorCode(error)).toBe('UNKNOWN_ERROR');
    });

    it('should return UNKNOWN_ERROR for non-error objects', () => {
      expect(getErrorCode('not an error')).toBe('UNKNOWN_ERROR');
    });
  });

  describe('getStatusCode', () => {
    it('should return status code for AppError', () => {
      const error = new InvalidCredentialsError();
      expect(getStatusCode(error)).toBe(401);
    });

    it('should return 500 for non-AppError', () => {
      const error = new Error('Test');
      expect(getStatusCode(error)).toBe(500);
    });

    it('should return 500 for non-error objects', () => {
      expect(getStatusCode('not an error')).toBe(500);
    });
  });
});
