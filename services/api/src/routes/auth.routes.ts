import express, { Request, Response } from 'express';
import { AuthService } from '../services/auth.service';
import { supabaseService } from '../services/supabase.service';
import { authenticateToken } from '../middleware/auth';
import { logger } from '../utils/logger';

const router = express.Router();
const authService = new AuthService(supabaseService['client']);

/**
 * POST /auth/signup
 * Register a new user
 */
router.post('/signup', async (req: Request, res: Response) => {
  try {
    const { email, password, fullName } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        error: 'Email and password are required',
      });
    }

    const result = await authService.signUp({
      email,
      password,
      fullName,
    });

    res.status(201).json({
      success: true,
      data: result,
    });
  } catch (error) {
    logger.error('Sign up error:', error);
    const message = error instanceof Error ? error.message : 'Sign up failed';
    res.status(400).json({ error: message });
  }
});

/**
 * POST /auth/login
 * Login user
 */
router.post('/login', async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        error: 'Email and password are required',
      });
    }

    const result = await authService.login({
      email,
      password,
    });

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    logger.error('Login error:', error);
    const message = error instanceof Error ? error.message : 'Login failed';
    res.status(401).json({ error: message });
  }
});

/**
 * POST /auth/refresh
 * Refresh access token
 */
router.post('/refresh', async (req: Request, res: Response) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        error: 'Refresh token is required',
      });
    }

    const result = await authService.refreshToken(refreshToken);

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    logger.error('Token refresh error:', error);
    res.status(401).json({ error: 'Invalid refresh token' });
  }
});

/**
 * POST /auth/logout
 * Logout user
 */
router.post('/logout', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.sub;

    if (!userId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    await authService.logout(userId);

    res.json({
      success: true,
      message: 'Logged out successfully',
    });
  } catch (error) {
    logger.error('Logout error:', error);
    res.status(500).json({ error: 'Logout failed' });
  }
});

/**
 * POST /auth/request-password-reset
 * Request password reset
 */
router.post('/request-password-reset', async (req: Request, res: Response) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        error: 'Email is required',
      });
    }

    await authService.requestPasswordReset(email);

    res.json({
      success: true,
      message: 'Password reset email sent',
    });
  } catch (error) {
    logger.error('Password reset request error:', error);
    res.status(500).json({ error: 'Failed to request password reset' });
  }
});

/**
 * POST /auth/confirm-password-reset
 * Confirm password reset
 */
router.post('/confirm-password-reset', async (req: Request, res: Response) => {
  try {
    const { token, newPassword } = req.body;

    if (!token || !newPassword) {
      return res.status(400).json({
        error: 'Token and new password are required',
      });
    }

    await authService.confirmPasswordReset(token, newPassword);

    res.json({
      success: true,
      message: 'Password reset successfully',
    });
  } catch (error) {
    logger.error('Password reset confirmation error:', error);
    const message = error instanceof Error ? error.message : 'Password reset failed';
    res.status(400).json({ error: message });
  }
});

/**
 * GET /auth/me
 * Get current user
 */
router.get('/me', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.sub;

    if (!userId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    const profile = await supabaseService.getUserProfile(userId);

    res.json({
      success: true,
      data: profile,
    });
  } catch (error) {
    logger.error('Get user error:', error);
    res.status(500).json({ error: 'Failed to get user' });
  }
});

export default router;
