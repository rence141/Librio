import { describe, it, expect, beforeEach, vi } from 'vitest';
import { AuthService } from '../services/auth.service';

// Mock Supabase client
const mockSupabaseClient = {
  auth: {
    signUp: vi.fn(),
    signInWithPassword: vi.fn(),
    signOut: vi.fn(),
    resetPasswordForEmail: vi.fn(),
    updateUser: vi.fn(),
  },
  from: vi.fn(),
};

describe('AuthService', () => {
  let authService: AuthService;

  beforeEach(() => {
    vi.clearAllMocks();
    authService = new AuthService(mockSupabaseClient as any);
  });

  describe('signUp', () => {
    it('should successfully sign up a new user', async () => {
      const mockUser = {
        id: 'user-123',
        email: 'test@example.com',
      };

      mockSupabaseClient.auth.signUp.mockResolvedValue({
        data: { user: mockUser },
        error: null,
      });

      mockSupabaseClient.from.mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            maybeSingle: vi.fn().mockResolvedValue({ data: null, error: null }),
          }),
        }),
        insert: vi.fn().mockResolvedValue({ data: {}, error: null }),
      });

      const result = await authService.signUp({
        email: 'test@example.com',
        password: 'password123',
        fullName: 'Test User',
      });

      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result.user.email).toBe('test@example.com');
      expect(result.user.fullName).toBe('Test User');
    });

    it('should reject password shorter than 8 characters', async () => {
      await expect(
        authService.signUp({
          email: 'test@example.com',
          password: 'short',
        }),
      ).rejects.toThrow('Password must be at least 8 characters');
    });

    it('should reject missing email', async () => {
      await expect(
        authService.signUp({
          email: '',
          password: 'password123',
        }),
      ).rejects.toThrow('Email and password are required');
    });

    it('should reject existing user', async () => {
      mockSupabaseClient.from.mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            maybeSingle: vi.fn().mockResolvedValue({
              data: { id: 'existing-user' },
              error: null,
            }),
          }),
        }),
      });

      await expect(
        authService.signUp({
          email: 'existing@example.com',
          password: 'password123',
        }),
      ).rejects.toThrow('User already exists');
    });
  });

  describe('login', () => {
    it('should successfully login a user', async () => {
      const mockUser = {
        id: 'user-123',
        email: 'test@example.com',
      };

      mockSupabaseClient.auth.signInWithPassword.mockResolvedValue({
        data: { user: mockUser },
        error: null,
      });

      mockSupabaseClient.from.mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            maybeSingle: vi.fn().mockResolvedValue({
              data: { full_name: 'Test User' },
              error: null,
            }),
          }),
        }),
      });

      const result = await authService.login({
        email: 'test@example.com',
        password: 'password123',
      });

      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result.user.email).toBe('test@example.com');
    });

    it('should reject missing credentials', async () => {
      await expect(
        authService.login({
          email: '',
          password: 'password123',
        }),
      ).rejects.toThrow('Email and password are required');
    });

    it('should handle authentication error', async () => {
      mockSupabaseClient.auth.signInWithPassword.mockResolvedValue({
        data: { user: null },
        error: new Error('Invalid credentials'),
      });

      await expect(
        authService.login({
          email: 'test@example.com',
          password: 'wrongpassword',
        }),
      ).rejects.toThrow();
    });
  });

  describe('refreshToken', () => {
    it('should successfully refresh access token', async () => {
      const refreshToken = authService['generateRefreshToken']('user-123', 'test@example.com');

      const result = await authService.refreshToken(refreshToken);

      expect(result).toHaveProperty('accessToken');
      expect(result.accessToken).toBeTruthy();
    });

    it('should reject invalid refresh token', async () => {
      await expect(authService.refreshToken('invalid-token')).rejects.toThrow(
        'Invalid refresh token',
      );
    });
  });

  describe('verifyAccessToken', () => {
    it('should verify valid access token', () => {
      const accessToken = authService['generateAccessToken']('user-123', 'test@example.com');

      const payload = authService.verifyAccessToken(accessToken);

      expect(payload.sub).toBe('user-123');
      expect(payload.email).toBe('test@example.com');
    });

    it('should reject invalid access token', () => {
      expect(() => authService.verifyAccessToken('invalid-token')).toThrow(
        'Invalid access token',
      );
    });
  });

  describe('logout', () => {
    it('should successfully logout user', async () => {
      mockSupabaseClient.auth.signOut.mockResolvedValue({ error: null });

      await expect(authService.logout('user-123')).resolves.not.toThrow();
      expect(mockSupabaseClient.auth.signOut).toHaveBeenCalled();
    });
  });

  describe('requestPasswordReset', () => {
    it('should request password reset', async () => {
      mockSupabaseClient.auth.resetPasswordForEmail.mockResolvedValue({ error: null });

      await expect(authService.requestPasswordReset('test@example.com')).resolves.not.toThrow();
      expect(mockSupabaseClient.auth.resetPasswordForEmail).toHaveBeenCalledWith(
        'test@example.com',
      );
    });
  });

  describe('confirmPasswordReset', () => {
    it('should reject password shorter than 8 characters', async () => {
      await expect(authService.confirmPasswordReset('token', 'short')).rejects.toThrow(
        'Password must be at least 8 characters',
      );
    });

    it('should confirm password reset', async () => {
      mockSupabaseClient.auth.updateUser.mockResolvedValue({ error: null });

      await expect(authService.confirmPasswordReset('token', 'newpassword123')).resolves.not.toThrow();
      expect(mockSupabaseClient.auth.updateUser).toHaveBeenCalledWith({
        password: 'newpassword123',
      });
    });
  });
});
