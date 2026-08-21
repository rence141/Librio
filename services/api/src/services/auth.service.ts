import { SupabaseClient } from '@supabase/supabase-js';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';
import { logger } from '../utils/logger';

export interface SignUpRequest {
  email: string;
  password: string;
  fullName?: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  user: {
    id: string;
    email: string;
    fullName?: string;
  };
}

export interface TokenPayload {
  sub: string;
  email: string;
  iat: number;
  exp: number;
}

/**
 * Authentication service for user signup, login, and token management
 */
export class AuthService {
  private jwtSecret: string;
  private jwtRefreshSecret: string;
  private accessTokenExpiry: string = '1h';
  private refreshTokenExpiry: string = '7d';

  constructor(private supabase: SupabaseClient) {
    this.jwtSecret = process.env.JWT_SECRET || 'your-secret-key';
    this.jwtRefreshSecret = process.env.JWT_REFRESH_SECRET || 'your-refresh-secret';

    if (!process.env.JWT_SECRET || !process.env.JWT_REFRESH_SECRET) {
      logger.warn('JWT secrets not configured. Using defaults (NOT SECURE)');
    }
  }

  /**
   * Sign up a new user
   */
  async signUp(request: SignUpRequest): Promise<AuthResponse> {
    try {
      const { email, password, fullName } = request;

      // Validate input
      if (!email || !password) {
        throw new Error('Email and password are required');
      }

      if (password.length < 8) {
        throw new Error('Password must be at least 8 characters');
      }

      // Check if user already exists
      const existingUser = await this.supabase
        .from('user_profiles')
        .select('id')
        .eq('email', email)
        .maybeSingle();

      if (existingUser.data) {
        throw new Error('User already exists');
      }

      // Create user in Supabase Auth
      const { data: authData, error: authError } = await this.supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            full_name: fullName,
          },
        },
      });

      if (authError) throw authError;
      if (!authData.user) throw new Error('Failed to create user');

      // Create user profile
      const { error: profileError } = await this.supabase
        .from('user_profiles')
        .insert({
          id: authData.user.id,
          email,
          full_name: fullName,
          subscription_tier: 'free',
          storage_limit_mb: 1000,
        });

      if (profileError) throw profileError;

      // Generate tokens
      const accessToken = this.generateAccessToken(authData.user.id, email);
      const refreshToken = this.generateRefreshToken(authData.user.id, email);

      logger.info(`User signed up: ${email}`);

      return {
        accessToken,
        refreshToken,
        user: {
          id: authData.user.id,
          email,
          fullName,
        },
      };
    } catch (error) {
      logger.error('Sign up error:', error);
      throw error;
    }
  }

  /**
   * Login user
   */
  async login(request: LoginRequest): Promise<AuthResponse> {
    try {
      const { email, password } = request;

      // Validate input
      if (!email || !password) {
        throw new Error('Email and password are required');
      }

      // Authenticate with Supabase
      const { data: authData, error: authError } = await this.supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (authError) throw authError;
      if (!authData.user) throw new Error('Authentication failed');

      // Get user profile
      const { data: profile, error: profileError } = await this.supabase
        .from('user_profiles')
        .select('full_name')
        .eq('id', authData.user.id)
        .maybeSingle();

      if (profileError) throw profileError;

      // Generate tokens
      const accessToken = this.generateAccessToken(authData.user.id, email);
      const refreshToken = this.generateRefreshToken(authData.user.id, email);

      logger.info(`User logged in: ${email}`);

      return {
        accessToken,
        refreshToken,
        user: {
          id: authData.user.id,
          email,
          fullName: profile?.full_name,
        },
      };
    } catch (error) {
      logger.error('Login error:', error);
      throw error;
    }
  }

  /**
   * Refresh access token
   */
  async refreshToken(refreshToken: string): Promise<{ accessToken: string }> {
    try {
      // Verify refresh token
      const decoded = jwt.verify(refreshToken, this.jwtRefreshSecret) as TokenPayload;

      // Generate new access token
      const accessToken = this.generateAccessToken(decoded.sub, decoded.email);

      logger.info(`Token refreshed for user: ${decoded.email}`);

      return { accessToken };
    } catch (error) {
      logger.error('Token refresh error:', error);
      throw new Error('Invalid refresh token');
    }
  }

  /**
   * Verify access token
   */
  verifyAccessToken(token: string): TokenPayload {
    try {
      return jwt.verify(token, this.jwtSecret) as TokenPayload;
    } catch (error) {
      logger.error('Token verification error:', error);
      throw new Error('Invalid access token');
    }
  }

  /**
   * Generate access token
   */
  private generateAccessToken(userId: string, email: string): string {
    return jwt.sign(
      {
        sub: userId,
        email,
      },
      this.jwtSecret,
      {
        expiresIn: this.accessTokenExpiry,
        issuer: 'librio',
        audience: 'librio-api',
      },
    );
  }

  /**
   * Generate refresh token
   */
  private generateRefreshToken(userId: string, email: string): string {
    return jwt.sign(
      {
        sub: userId,
        email,
      },
      this.jwtRefreshSecret,
      {
        expiresIn: this.refreshTokenExpiry,
        issuer: 'librio',
        audience: 'librio-api',
      },
    );
  }

  /**
   * Logout user
   */
  async logout(userId: string): Promise<void> {
    try {
      await this.supabase.auth.signOut();
      logger.info(`User logged out: ${userId}`);
    } catch (error) {
      logger.error('Logout error:', error);
      throw error;
    }
  }

  /**
   * Request password reset
   */
  async requestPasswordReset(email: string): Promise<void> {
    try {
      const { error } = await this.supabase.auth.resetPasswordForEmail(email);

      if (error) throw error;

      logger.info(`Password reset requested for: ${email}`);
    } catch (error) {
      logger.error('Password reset request error:', error);
      throw error;
    }
  }

  /**
   * Confirm password reset
   */
  async confirmPasswordReset(token: string, newPassword: string): Promise<void> {
    try {
      if (newPassword.length < 8) {
        throw new Error('Password must be at least 8 characters');
      }

      const { error } = await this.supabase.auth.updateUser({
        password: newPassword,
      });

      if (error) throw error;

      logger.info('Password reset confirmed');
    } catch (error) {
      logger.error('Password reset confirmation error:', error);
      throw error;
    }
  }
}
