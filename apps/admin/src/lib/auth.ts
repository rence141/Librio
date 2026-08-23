import jwt from 'jsonwebtoken';

export type SubscriptionTier = 'free' | 'premium' | 'enterprise';

export interface AuthUser {
  id: string;
  email: string;
  tier: SubscriptionTier;
  isNewAccount: boolean;
}

/**
 * Verify JWT token from Authorization header.
 * Returns the user or null if invalid/missing.
 */
export function verifyToken(authHeader: string | null): AuthUser | null {
  if (!authHeader) return null;
  const token = authHeader.split(' ')[1];
  if (!token) return null;

  try {
    const secret = process.env.JWT_SECRET || 'dev-secret';
    const decoded = jwt.verify(token, secret) as any;
    return {
      id: decoded.sub,
      email: decoded.email,
      tier: (decoded.tier as SubscriptionTier) || 'free',
      isNewAccount: decoded.isNewAccount ?? false,
    };
  } catch {
    return null;
  }
}

/**
 * Generate a JWT access token
 */
export function generateAccessToken(user: { id: string; email: string; tier: SubscriptionTier; isNewAccount?: boolean }): string {
  const secret = process.env.JWT_SECRET || 'dev-secret';
  return jwt.sign(
    { sub: user.id, email: user.email, tier: user.tier, isNewAccount: user.isNewAccount ?? false },
    secret,
    { expiresIn: '15m' }
  );
}

/**
 * Generate a JWT refresh token
 */
export function generateRefreshToken(user: { id: string; email: string }): string {
  const refreshSecret = process.env.JWT_REFRESH_SECRET || 'dev-refresh-secret';
  return jwt.sign(
    { sub: user.id, email: user.email },
    refreshSecret,
    { expiresIn: '7d' }
  );
}

/**
 * Verify a refresh token
 */
export function verifyRefreshToken(token: string): { id: string; email: string } | null {
  try {
    const refreshSecret = process.env.JWT_REFRESH_SECRET || 'dev-refresh-secret';
    const decoded = jwt.verify(token, refreshSecret) as any;
    return { id: decoded.sub, email: decoded.email };
  } catch {
    return null;
  }
}
