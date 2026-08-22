import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { SubscriptionTier } from '../config/guardrails.config';

export interface AuthUser {
  id: string;
  email: string;
  tier: SubscriptionTier;
  isNewAccount: boolean;
}

export interface AuthRequest extends Request {
  user?: AuthUser;
  deviceId?: string;
}

/**
 * Authenticate JWT token from Authorization header.
 * Derives user identity from the verified token — never from client-sent userId.
 */
export const authenticateToken = (
  req: AuthRequest,
  res: Response,
  next: NextFunction,
) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({
      error: { code: 'AUTH_REQUIRED', message: 'Access token required' },
    });
  }

  try {
    const secret = process.env.JWT_SECRET || 'dev-secret';
    const decoded = jwt.verify(token, secret) as any;
    req.user = {
      id: decoded.sub,
      email: decoded.email,
      tier: (decoded.tier as SubscriptionTier) || 'free',
      isNewAccount: decoded.isNewAccount ?? false,
    };
    req.deviceId = (req.headers['x-device-id'] as string) || 'unknown';
    next();
  } catch {
    return res.status(403).json({
      error: { code: 'AUTH_REQUIRED', message: 'Invalid or expired token' },
    });
  }
};

/**
 * Optional authentication — doesn't fail if token is missing.
 */
export const optionalAuth = (
  req: AuthRequest,
  res: Response,
  next: NextFunction,
) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (token) {
    try {
      const secret = process.env.JWT_SECRET || 'dev-secret';
      const decoded = jwt.verify(token, secret) as any;
      req.user = {
        id: decoded.sub,
        email: decoded.email,
        tier: (decoded.tier as SubscriptionTier) || 'free',
        isNewAccount: decoded.isNewAccount ?? false,
      };
    } catch {
      // Token invalid — continue without user
    }
  }

  req.deviceId = (req.headers['x-device-id'] as string) || 'unknown';
  next();
};

/**
 * Require a specific subscription tier.
 */
export const requireTier = (minTier: SubscriptionTier) => {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({
        error: { code: 'AUTH_REQUIRED', message: 'Authentication required' },
      });
    }

    const tierOrder: SubscriptionTier[] = ['free', 'premium'];
    const userLevel = tierOrder.indexOf(req.user.tier);
    const requiredLevel = tierOrder.indexOf(minTier);

    if (userLevel < requiredLevel) {
      return res.status(403).json({
        error: { code: 'FORBIDDEN', message: `${minTier} subscription required` },
      });
    }

    next();
  };
};
