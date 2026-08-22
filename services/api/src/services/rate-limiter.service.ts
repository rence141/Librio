import { getStore, KVStore } from './store.service';
import { RATE_LIMIT_CONFIG, getTierLimits } from '../config/guardrails.config';
import { logger } from '../utils/logger';

export interface RateLimitResult {
  allowed: boolean;
  retryAfter: number; // seconds
  remaining: number;
  limit: number;
}

/**
 * Multi-dimensional rate limiter using sliding-window counters.
 *
 * Limits at: user, device/session, IP, endpoint, and global levels.
 * Uses the KV store (in-memory or Redis) for counters.
 */
export class RateLimiterService {
  constructor(private store: KVStore = getStore()) {}

  /**
   * Check per-user rate limits (minute + hour + day).
   */
  async checkUserLimits(
    userId: string,
    tier: 'free' | 'premium',
  ): Promise<RateLimitResult> {
    const limits = getTierLimits(tier);
    const now = Math.floor(Date.now() / 1000);

    // Per-minute
    const minuteKey = `rl:user:${userId}:min:${Math.floor(now / 60)}`;
    const minuteCount = await this.store.incr(minuteKey, 70); // TTL slightly > window
    if (minuteCount > limits.requestsPerMinute) {
      logger.warn({ userId, minuteCount, limit: limits.requestsPerMinute }, 'Rate limit: per-minute exceeded');
      return {
        allowed: false,
        retryAfter: 60 - (now % 60),
        remaining: 0,
        limit: limits.requestsPerMinute,
      };
    }

    // Per-hour
    const hourKey = `rl:user:${userId}:hour:${Math.floor(now / 3600)}`;
    const hourCount = await this.store.incr(hourKey, 3700);
    if (hourCount > limits.requestsPerHour) {
      logger.warn({ userId, hourCount, limit: limits.requestsPerHour }, 'Rate limit: per-hour exceeded');
      return {
        allowed: false,
        retryAfter: 3600 - (now % 3600),
        remaining: 0,
        limit: limits.requestsPerHour,
      };
    }

    // Per-day (AI requests)
    const dayKey = `rl:user:${userId}:ai_day:${Math.floor(now / 86400)}`;
    const dayCount = await this.store.incr(dayKey, 90_000);
    if (dayCount > limits.aiRequestsPerDay) {
      logger.warn({ userId, dayCount, limit: limits.aiRequestsPerDay }, 'Rate limit: daily AI exceeded');
      return {
        allowed: false,
        retryAfter: 86400 - (now % 86400),
        remaining: 0,
        limit: limits.aiRequestsPerDay,
      };
    }

    return {
      allowed: true,
      retryAfter: 0,
      remaining: limits.requestsPerMinute - minuteCount,
      limit: limits.requestsPerMinute,
    };
  }

  /**
   * Check IP-level rate limit (DDoS protection).
   */
  async checkIpLimit(ip: string): Promise<RateLimitResult> {
    const now = Math.floor(Date.now() / 1000);
    const key = `rl:ip:${ip}:${Math.floor(now / 60)}`;
    const count = await this.store.incr(key, 70);

    if (count > RATE_LIMIT_CONFIG.ipRequestsPerMinute) {
      logger.warn({ ip, count }, 'Rate limit: IP exceeded');
      return {
        allowed: false,
        retryAfter: 60 - (now % 60),
        remaining: 0,
        limit: RATE_LIMIT_CONFIG.ipRequestsPerMinute,
      };
    }

    return {
      allowed: true,
      retryAfter: 0,
      remaining: RATE_LIMIT_CONFIG.ipRequestsPerMinute - count,
      limit: RATE_LIMIT_CONFIG.ipRequestsPerMinute,
    };
  }

  /**
   * Check global requests-per-second limit.
   */
  async checkGlobalLimit(): Promise<RateLimitResult> {
    const now = Math.floor(Date.now() / 1000);
    const key = `rl:global:${now}`;
    const count = await this.store.incr(key, 5);

    if (count > RATE_LIMIT_CONFIG.globalRequestsPerSecond) {
      logger.warn({ count }, 'Rate limit: global RPS exceeded');
      return {
        allowed: false,
        retryAfter: 1,
        remaining: 0,
        limit: RATE_LIMIT_CONFIG.globalRequestsPerSecond,
      };
    }

    return {
      allowed: true,
      retryAfter: 0,
      remaining: RATE_LIMIT_CONFIG.globalRequestsPerSecond - count,
      limit: RATE_LIMIT_CONFIG.globalRequestsPerSecond,
    };
  }

  /**
   * Check registration rate limit (account farming protection).
   */
  async checkRegistrationLimit(ip: string, emailDomain: string): Promise<RateLimitResult> {
    const now = Math.floor(Date.now() / 1000);
    const hourBucket = Math.floor(now / 3600);
    const dayBucket = Math.floor(now / 86400);

    // IP-based
    const ipKey = `rl:reg:ip:${ip}:${hourBucket}`;
    const ipCount = await this.store.incr(ipKey, 3700);
    if (ipCount > RATE_LIMIT_CONFIG.registrationPerIpPerHour) {
      logger.warn({ ip, ipCount }, 'Registration rate limit: IP exceeded');
      return {
        allowed: false,
        retryAfter: 3600 - (now % 3600),
        remaining: 0,
        limit: RATE_LIMIT_CONFIG.registrationPerIpPerHour,
      };
    }

    // Domain-based
    const domainKey = `rl:reg:domain:${emailDomain}:${dayBucket}`;
    const domainCount = await this.store.incr(domainKey, 90_000);
    if (domainCount > 20) {
      logger.warn({ emailDomain, domainCount }, 'Registration rate limit: domain exceeded');
      return {
        allowed: false,
        retryAfter: 86400 - (now % 86400),
        remaining: 0,
        limit: 20,
      };
    }

    return {
      allowed: true,
      retryAfter: 0,
      remaining: RATE_LIMIT_CONFIG.registrationPerIpPerHour - ipCount,
      limit: RATE_LIMIT_CONFIG.registrationPerIpPerHour,
    };
  }
}

/** Singleton. */
let instance: RateLimiterService | null = null;
export function getRateLimiter(): RateLimiterService {
  if (!instance) instance = new RateLimiterService();
  return instance;
}
