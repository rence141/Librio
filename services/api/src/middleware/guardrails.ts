import { Response, NextFunction } from 'express';
import { AuthRequest } from './auth';
import { getRateLimiter } from '../services/rate-limiter.service';
import { getConcurrencyService } from '../services/concurrency.service';
import { getAbuseDetectionService } from '../services/abuse-detection.service';
import { getSafetyService } from '../services/safety.service';
import { getTierLimits } from '../config/guardrails.config';
import {
  rateLimitExceeded,
  concurrencyLimitExceeded,
  contentRestricted,
  forbidden,
} from '../utils/api-errors';

/**
 * Rate-limiting middleware for AI endpoints.
 * Checks: global RPS → IP limit → user limits.
 */
export async function aiRateLimitMiddleware(
  req: AuthRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  if (!req.user) {
    next();
    return;
  }

  const rateLimiter = getRateLimiter();
  const ip = req.ip || req.socket.remoteAddress || 'unknown';

  // 1. Global RPS
  const globalResult = await rateLimiter.checkGlobalLimit();
  if (!globalResult.allowed) {
    rateLimitExceeded(res, globalResult.retryAfter);
    return;
  }

  // 2. IP limit
  const ipResult = await rateLimiter.checkIpLimit(ip);
  if (!ipResult.allowed) {
    rateLimitExceeded(res, ipResult.retryAfter);
    return;
  }

  // 3. User limits
  const userResult = await rateLimiter.checkUserLimits(req.user.id, req.user.tier);
  if (!userResult.allowed) {
    rateLimitExceeded(res, userResult.retryAfter);
    return;
  }

  // Set rate-limit headers
  res.setHeader('X-RateLimit-Limit', userResult.limit);
  res.setHeader('X-RateLimit-Remaining', Math.max(0, userResult.remaining));

  next();
}

/**
 * Abuse detection middleware.
 * Checks if user is in cooldown/restricted state.
 */
export async function abuseCheckMiddleware(
  req: AuthRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  if (!req.user) {
    next();
    return;
  }

  const abuseService = getAbuseDetectionService();
  const isRestricted = await abuseService.isRestricted(req.user.id);

  if (isRestricted) {
    forbidden(res, 'Account is temporarily restricted due to suspicious activity. Please try again later.');
    return;
  }

  next();
}

/**
 * Concurrency middleware.
 * Acquires a lease and attaches the release function to the response.
 */
export async function concurrencyMiddleware(
  req: AuthRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  if (!req.user) {
    next();
    return;
  }

  const concurrencyService = getConcurrencyService();
  const limits = getTierLimits(req.user.tier);

  const result = await concurrencyService.acquire(req.user.id, limits.maxConcurrency);

  if (!result.allowed) {
    concurrencyLimitExceeded(res);
    return;
  }

  // Attach lease release to response locals
  (res as any).concurrencyLeaseId = result.leaseId;
  (res as any).releaseConcurrency = () => {
    if (result.leaseId) {
      concurrencyService.release(req.user!.id, result.leaseId);
    }
  };

  // Auto-release on response close (covers disconnects)
  res.on('close', () => {
    if (result.leaseId) {
      concurrencyService.release(req.user!.id, result.leaseId);
    }
  });

  next();
}

/**
 * Input safety middleware.
 */
export function inputSafetyMiddleware(
  req: AuthRequest,
  res: Response,
  next: NextFunction,
): void {
  const safetyService = getSafetyService();
  const prompt = req.body?.prompt ?? '';

  if (!prompt) {
    next();
    return;
  }

  const result = safetyService.checkInput(prompt);
  if (!result.safe) {
    contentRestricted(res, result.reason ?? 'Content not allowed');
    return;
  }

  next();
}
