import { describe, it, expect, beforeEach, vi } from 'vitest';
import { AuthService } from './auth.service';
import * as jwt from 'jsonwebtoken';
import * as bcrypt from 'bcrypt';

// Mock Supabase client
const mockSupabaseClient = {
  from: vi.fn(),
  auth: {
    signUp: vi.fn(),
    signOut: vi.fn(),
    resetPasswordForEmail: vi.fn(),
    updateUser: vi.fn(),
  },
};

describe('AuthService', () => {
  let authService: AuthService;

  beforeEach(() => {
    // Set JWT secrets for testing
    process.env.JWT_SECRET = 'test_secret_key_min_32_chars_long_here';
    process.env.JWT_REFRESH_SECRET = 'test_refresh_secret_key_min_32_chars';
    
    // Reset mocks before each test
    vi.clearAllMocks();
    
    // Create new instance with mocked Supabase
    authService = new AuthService(mockSupabaseClient as any);
  });

  describe('signUp', () => {
    it('should successfully sign up a new user', async () => {
      const mockInsert = vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          single: vi.fn().mockResolvedValue({
            data: {
              id: 'user_123',
              email: 'test@example.com',
              full_name: 'Test User',
            },
            error: null,
          }),
        }),
      });

      mockSupabaseClient.from.mockReturnValue({
        insert: mockInsert,
      });

      const result = await authService.signUp({
        email: 'test@example.com',
        password: 'TestPassword123',
        fullName: 'Test User',
      });

      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result.user.email).toBe('test@example.com');
      expect(result.user.fullName).toBe('Test User');
    });

    it('should reject signup with invalid email', async () => {
      await expect(
        authService.signUp({
          email: '',
          password: 'TestPassword123',
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

    it('should reject signup with empty name', async () => {
      await expect(
        authService.signUp({
          email: 'test@example.com',
          password: 'TestPassword123',
          fullName: '   ',
        })
      ).rejects.toThrow();
    });

    it('should hash password before storing', async () => {
      const mockInsert = vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          single: vi.fn().mockResolvedValue({
            data: { id: 'user_123' },
            error: null,
          }),
        }),
      });

      mockSupabaseClient.from.mockReturnValue({
        insert: mockInsert,
      });

      await authService.signUp({
        email: 'test@example.com',
        password: 'TestPassword123',
        fullName: 'Test User',
      });

      const insertCall = mockInsert.mock.calls[0][0];
      expect(insertCall.password_hash).toBeDefined();
      expect(insertCall.password_hash).not.toBe('TestPassword123');
    });
  });

  describe('login', () => {
    it('should successfully login with correct credentials', async () => {
      const hashedPassword = await bcrypt.hash('TestPassword123', 10);

      const mockSelect = vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          maybeSingle: vi.fn().mockResolvedValue({
            data: {
              id: 'user_123',
              password_hash: hashedPassword,
              full_name: 'Test User',
            },
            error: null,
          }),
        }),
      });

      mockSupabaseClient.from.mockReturnValue({
        select: mockSelect,
      });

      const result = await authService.login({
        email: 'test@example.com',
        password: 'TestPassword123',
      });

      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result.user.email).toBe('test@example.com');
    });

    it('should reject login with invalid email', async () => {
      await expect(
        authService.login({
          email: '',
          password: 'TestPassword123',
        })
      ).rejects.toThrow('Email and password are required');
    });

    it('should reject login with empty password', async () => {
      await expect(
        authService.login({
          email: 'test@example.com',
          password: '',
        })
      ).rejects.toThrow('Email and password are required');
    });

    it('should reject login with non-existent user', async () => {
      const mockSelect = vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          maybeSingle: vi.fn().mockResolvedValue({
            data: null,
            error: null,
          }),
        }),
      });

      mockSupabaseClient.from.mockReturnValue({
        select: mockSelect,
      });

      await expect(
        authService.login({
          email: 'nonexistent@example.com',
          password: 'TestPassword123',
        })
      ).rejects.toThrow('Invalid email or password');
    });

    it('should reject login with incorrect password', async () => {
      const hashedPassword = await bcrypt.hash('CorrectPassword123', 10);

      const mockSelect = vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          maybeSingle: vi.fn().mockResolvedValue({
            data: {
              id: 'user_123',
              password_hash: hashedPassword,
              full_name: 'Test User',
            },
            error: null,
          }),
        }),
      });

      mockSupabaseClient.from.mockReturnValue({
        select: mockSelect,
      });

      await expect(
        authService.login({
          email: 'test@example.com',
          password: 'WrongPassword123',
        })
      ).rejects.toThrow('Invalid email or password');
    });
  });

  describe('refreshToken', () => {
    it('should successfully refresh access token', async () => {
      const refreshToken = jwt.sign(
        {
          sub: 'user_123',
          email: 'test@example.com',
        },
        process.env.JWT_REFRESH_SECRET,
        { expiresIn: '7d' }
      );

      const result = await authService.refreshToken(refreshToken);

      expect(result).toHaveProperty('accessToken');
      expect(result.accessToken).toBeDefined();

      // Verify the new token is valid
      const decoded = jwt.verify(result.accessToken, process.env.JWT_SECRET) as any;
      expect(decoded.sub).toBe('user_123');
      expect(decoded.email).toBe('test@example.com');
    });

    it('should reject invalid refresh token', async () => {
      await expect(
        authService.refreshToken('invalid_token')
      ).rejects.toThrow('Invalid refresh token');
    });

    it('should reject expired refresh token', async () => {
      const expiredToken = jwt.sign(
        {
          sub: 'user_123',
          email: 'test@example.com',
        },
        process.env.JWT_REFRESH_SECRET,
        { expiresIn: '-1h' } // Expired 1 hour ago
      );

      await expect(
        authService.refreshToken(expiredToken)
      ).rejects.toThrow('Invalid refresh token');
    });
  });

  describe('verifyAccessToken', () => {
    it('should successfully verify valid access token', () => {
      const token = jwt.sign(
        {
          sub: 'user_123',
          email: 'test@example.com',
        },
        process.env.JWT_SECRET,
        { expiresIn: '1h' }
      );

      const decoded = authService.verifyAccessToken(token);

      expect(decoded.sub).toBe('user_123');
      expect(decoded.email).toBe('test@example.com');
    });

    it('should reject invalid access token', () => {
      expect(() => {
        authService.verifyAccessToken('invalid_token');
      }).toThrow('Invalid access token');
    });

    it('should reject expired access token', () => {
      const expiredToken = jwt.sign(
        {
          sub: 'user_123',
          email: 'test@example.com',
        },
        process.env.JWT_SECRET,
        { expiresIn: '-1h' } // Expired 1 hour ago
      );

      expect(() => {
        authService.verifyAccessToken(expiredToken);
      }).toThrow('Invalid access token');
    });
  });

  describe('verifyGoogleToken', () => {
    it('should successfully verify Google token and create user', async () => {
      const googleToken = jwt.sign(
        {
          sub: 'google_user_123',
          email: 'user@gmail.com',
          name: 'Google User',
          picture: 'https://example.com/photo.jpg',
        },
        'google_secret'
      );

      const mockSelect = vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          maybeSingle: vi.fn().mockResolvedValue({
            data: null, // User doesn't exist
            error: null,
          }),
        }),
      });

      const mockInsert = vi.fn().mockResolvedValue({
        error: null,
      });

      mockSupabaseClient.from.mockImplementation((table: string) => {
        if (table === 'user_profiles') {
          return {
            select: mockSelect,
            insert: mockInsert,
          };
        }
      });

      const result = await authService.verifyGoogleToken(googleToken);

      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result.user.email).toBe('user@gmail.com');
    });

    it('should reject empty ID token', async () => {
      await expect(
        authService.verifyGoogleToken('')
      ).rejects.toThrow('Google ID token is required');
    });

    it('should reject invalid ID token', async () => {
      await expect(
        authService.verifyGoogleToken('invalid_token')
      ).rejects.toThrow('Invalid Google token');
    });

    it('should update existing user on Google sign-in', async () => {
      const googleToken = jwt.sign(
        {
          sub: 'google_user_123',
          email: 'existing@gmail.com',
          name: 'Existing User',
        },
        'google_secret'
      );

      const mockSelect = vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          maybeSingle: vi.fn().mockResolvedValue({
            data: {
              id: 'user_existing_123',
              full_name: 'Existing User',
            },
            error: null,
          }),
        }),
      });

      const mockUpdate = vi.fn().mockReturnValue({
        eq: vi.fn().mockResolvedValue({
          error: null,
        }),
      });

      mockSupabaseClient.from.mockImplementation((table: string) => {
        if (table === 'user_profiles') {
          return {
            select: mockSelect,
            update: mockUpdate,
          };
        }
      });

      const result = await authService.verifyGoogleToken(googleToken);

      expect(result).toHaveProperty('accessToken');
      expect(result.user.email).toBe('existing@gmail.com');
      expect(mockUpdate).toHaveBeenCalled();
    });
  });

  describe('logout', () => {
    it('should successfully logout user', async () => {
      mockSupabaseClient.auth.signOut.mockResolvedValue({
        error: null,
      });

      await authService.logout('user_123');

      expect(mockSupabaseClient.auth.signOut).toHaveBeenCalled();
    });

    it('should handle logout errors gracefully', async () => {
      mockSupabaseClient.auth.signOut.mockRejectedValue(
        new Error('Logout failed')
      );

      await expect(
        authService.logout('user_123')
      ).rejects.toThrow('Logout failed');
    });
  });

  describe('requestPasswordReset', () => {
    it('should successfully request password reset', async () => {
      mockSupabaseClient.auth.resetPasswordForEmail.mockResolvedValue({
        error: null,
      });

      await authService.requestPasswordReset('test@example.com');

      expect(mockSupabaseClient.auth.resetPasswordForEmail).toHaveBeenCalledWith(
        'test@example.com'
      );
    });

    it('should handle password reset request errors', async () => {
      mockSupabaseClient.auth.resetPasswordForEmail.mockRejectedValue(
        new Error('Reset failed')
      );

      await expect(
        authService.requestPasswordReset('test@example.com')
      ).rejects.toThrow('Reset failed');
    });
  });

  describe('confirmPasswordReset', () => {
    it('should successfully confirm password reset', async () => {
      mockSupabaseClient.auth.updateUser.mockResolvedValue({
        error: null,
      });

      await authService.confirmPasswordReset('reset_token', 'NewPassword123');

      expect(mockSupabaseClient.auth.updateUser).toHaveBeenCalledWith({
        password: 'NewPassword123',
      });
    });

    it('should reject password reset with short password', async () => {
      await expect(
        authService.confirmPasswordReset('reset_token', 'short')
      ).rejects.toThrow('Password must be at least 8 characters');
    });

    it('should handle password reset errors', async () => {
      mockSupabaseClient.auth.updateUser.mockRejectedValue(
        new Error('Update failed')
      );

      await expect(
        authService.confirmPasswordReset('reset_token', 'NewPassword123')
      ).rejects.toThrow('Update failed');
    });
  });
});
