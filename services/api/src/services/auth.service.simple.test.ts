import { describe, it, expect, beforeEach, vi } from 'vitest';
import { AuthService } from './auth.service';
import * as jwt from 'jsonwebtoken';

// Simple mock Supabase client
const createMockSupabaseClient = () => ({
  from: vi.fn((table: string) => ({
    insert: vi.fn().mockReturnValue({
      select: vi.fn().mockReturnValue({
        single: vi.fn().mockResolvedValue({
          data: { id: 'user_123' },
          error: null,
        }),
      }),
    }),
    select: vi.fn().mockReturnValue({
      eq: vi.fn().mockReturnValue({
        maybeSingle: vi.fn().mockResolvedValue({
          data: { id: 'user_123', password_hash: 'hashed' },
          error: null,
        }),
      }),
    }),
    update: vi.fn().mockReturnValue({
      eq: vi.fn().mockResolvedValue({ error: null }),
    }),
  })),
  auth: {
    signUp: vi.fn().mockResolvedValue({ data: { user: { id: 'user_123' } }, error: null }),
    signOut: vi.fn().mockResolvedValue({ error: null }),
    resetPasswordForEmail: vi.fn().mockResolvedValue({ error: null }),
    updateUser: vi.fn().mockResolvedValue({ error: null }),
  },
});

describe('AuthService - Simplified Tests', () => {
  let authService: AuthService;
  let mockSupabase: any;

  beforeEach(() => {
    // Set JWT secrets for testing
    process.env.JWT_SECRET = 'test_secret_key_min_32_chars_long_here';
    process.env.JWT_REFRESH_SECRET = 'test_refresh_secret_key_min_32_chars';

    // Create fresh mock
    mockSupabase = createMockSupabaseClient();

    // Create service with mock
    authService = new AuthService(mockSupabase);
  });

  describe('Validation', () => {
    it('should reject signup with missing email', async () => {
      await expect(
        authService.signUp({
          email: '',
          password: 'TestPassword123',
          fullName: 'Test User',
        })
      ).rejects.toThrow('Email and password are required');
    });

    it('should reject signup with missing password', async () => {
      await expect(
        authService.signUp({
          email: 'test@example.com',
          password: '',
          fullName: 'Test User',
        })
      ).rejects.toThrow('Email and password are required');
    });

    it('should reject signup with short password', async () => {
      await expect(
        authService.signUp({
          email: 'test@example.com',
          password: 'short',
          fullName: 'Test User',
        })
      ).rejects.toThrow('Password must be at least 8 characters');
    });

    it('should reject login with missing email', async () => {
      await expect(
        authService.login({
          email: '',
          password: 'TestPassword123',
        })
      ).rejects.toThrow('Email and password are required');
    });

    it('should reject login with missing password', async () => {
      await expect(
        authService.login({
          email: 'test@example.com',
          password: '',
        })
      ).rejects.toThrow('Email and password are required');
    });
  });

  describe('Token Operations', () => {
    it('should successfully refresh access token', async () => {
      const refreshToken = jwt.sign(
        { sub: 'user_123', email: 'test@example.com' },
        process.env.JWT_REFRESH_SECRET!,
        { expiresIn: '7d' }
      );

      const result = await authService.refreshToken(refreshToken);

      expect(result).toHaveProperty('accessToken');
      expect(result.accessToken).toBeDefined();
    });

    it('should reject invalid refresh token', async () => {
      await expect(authService.refreshToken('invalid_token')).rejects.toThrow(
        'Invalid refresh token'
      );
    });

    it('should reject expired refresh token', async () => {
      const expiredToken = jwt.sign(
        { sub: 'user_123', email: 'test@example.com' },
        process.env.JWT_REFRESH_SECRET!,
        { expiresIn: '-1h' }
      );

      await expect(authService.refreshToken(expiredToken)).rejects.toThrow(
        'Invalid refresh token'
      );
    });

    it('should successfully verify valid access token', () => {
      const token = jwt.sign(
        { sub: 'user_123', email: 'test@example.com' },
        process.env.JWT_SECRET!,
        { expiresIn: '1h' }
      );

      const decoded = authService.verifyAccessToken(token);

      expect(decoded.sub).toBe('user_123');
      expect(decoded.email).toBe('test@example.com');
    });

    it('should reject invalid access token', () => {
      expect(() => authService.verifyAccessToken('invalid_token')).toThrow(
        'Invalid access token'
      );
    });

    it('should reject expired access token', () => {
      const expiredToken = jwt.sign(
        { sub: 'user_123', email: 'test@example.com' },
        process.env.JWT_SECRET!,
        { expiresIn: '-1h' }
      );

      expect(() => authService.verifyAccessToken(expiredToken)).toThrow(
        'Invalid access token'
      );
    });
  });

  describe('Password Reset', () => {
    it('should successfully request password reset', async () => {
      await authService.requestPasswordReset('test@example.com');
      expect(mockSupabase.auth.resetPasswordForEmail).toHaveBeenCalledWith(
        'test@example.com'
      );
    });

    it('should successfully confirm password reset', async () => {
      await authService.confirmPasswordReset('reset_token', 'NewPassword123');
      expect(mockSupabase.auth.updateUser).toHaveBeenCalledWith({
        password: 'NewPassword123',
      });
    });

    it('should reject password reset with short password', async () => {
      await expect(
        authService.confirmPasswordReset('reset_token', 'short')
      ).rejects.toThrow('Password must be at least 8 characters');
    });
  });

  describe('Logout', () => {
    it('should successfully logout user', async () => {
      await authService.logout('user_123');
      expect(mockSupabase.auth.signOut).toHaveBeenCalled();
    });
  });
});
