import { getStore, KVStore } from './store.service';
import { getTierLimits, ACCOUNT_FARMING_LIMITS } from '../config/guardrails.config';
import { logger } from '../utils/logger';

export interface QuotaStatus {
  allowed: boolean;
  remainingTokens: number;
  remainingCredits: number;
  requestedTokens: number;
  limit: number;
  retryAfter?: number;
}

/**
 * Token-based usage quota service.
 *
 * Tracks per-user daily token usage and AI credits.
 * A user could send 1 request with 20,000 tokens vs 20 requests with 20 tokens —
 * both count as 1 request but have radically different costs.
 * So we track tokens, not just request counts.
 */
export class QuotaService {
  constructor(private store: KVStore = getStore()) {}

  private dayBucket(): number {
    return Math.floor(Date.now() / 1000 / 86400);
  }

  /**
   * Check if user has enough token budget for a request.
   * Does NOT consume — call consumeTokens() after generation.
   */
  async checkTokenBudget(
    userId: string,
    tier: 'free' | 'premium',
    estimatedInputTokens: number,
    estimatedOutputTokens: number,
    isNewAccount: boolean,
  ): Promise<QuotaStatus> {
    const limits = getTierLimits(tier);
    const dayBucket = this.dayBucket();
    const requestedTotal = estimatedInputTokens + estimatedOutputTokens;

    // Apply new-account reduced quota
    let effectiveLimit = limits.tokensPerDay;
    if (isNewAccount) {
      effectiveLimit = Math.floor(limits.tokensPerDay * ACCOUNT_FARMING_LIMITS.newAccountQuotaMultiplier);
    }

    const tokensKey = `quota:tokens:${userId}:${dayBucket}`;
    const usedTokens = await this.store.get(tokensKey);
    const remainingTokens = effectiveLimit - usedTokens;

    if (requestedTotal > remainingTokens) {
      logger.warn({ userId, usedTokens, requestedTotal, remainingTokens }, 'Quota: token budget exceeded');
      return {
        allowed: false,
        remainingTokens: Math.max(0, remainingTokens),
        remainingCredits: 0,
        requestedTokens: requestedTotal,
        limit: effectiveLimit,
        retryAfter: 86400 - (Math.floor(Date.now() / 1000) % 86400),
      };
    }

    // Check credits
    const creditsKey = `quota:credits:${userId}:${dayBucket}`;
    const usedCredits = await this.store.get(creditsKey);
    const remainingCredits = limits.creditsPerDay - usedCredits;

    return {
      allowed: true,
      remainingTokens: Math.max(0, remainingTokens),
      remainingCredits: Math.max(0, remainingCredits),
      requestedTokens: requestedTotal,
      limit: effectiveLimit,
    };
  }

  /**
   * Consume tokens and credits after a generation.
   */
  async consumeTokens(
    userId: string,
    inputTokens: number,
    outputTokens: number,
    creditsConsumed: number,
  ): Promise<void> {
    const dayBucket = this.dayBucket();
    const totalTokens = inputTokens + outputTokens;

    await this.store.incr(`quota:tokens:${userId}:${dayBucket}`, 90_000, totalTokens);
    await this.store.incr(`quota:credits:${userId}:${dayBucket}`, 90_000, creditsConsumed);

    logger.info({ userId, inputTokens, outputTokens, creditsConsumed }, 'Quota consumed');
  }

  /**
   * Check credits for a specific model (cost-multiplier based).
   */
  async checkCredits(
    userId: string,
    tier: 'free' | 'premium',
    modelCostMultiplier: number,
    isNewAccount: boolean,
  ): Promise<{ allowed: boolean; remaining: number; required: number }> {
    const limits = getTierLimits(tier);
    const dayBucket = this.dayBucket();

    let effectiveCredits = limits.creditsPerDay;
    if (isNewAccount) {
      effectiveCredits = Math.floor(limits.creditsPerDay * ACCOUNT_FARMING_LIMITS.newAccountQuotaMultiplier);
    }

    const creditsKey = `quota:credits:${userId}:${dayBucket}`;
    const usedCredits = await this.store.get(creditsKey);
    const remaining = effectiveCredits - usedCredits;

    if (modelCostMultiplier > remaining) {
      return { allowed: false, remaining: Math.max(0, remaining), required: modelCostMultiplier };
    }

    return { allowed: true, remaining, required: modelCostMultiplier };
  }

  /**
   * Get current usage for a user (for display/UX).
   */
  async getUsage(userId: string): Promise<{
    tokensUsedToday: number;
    creditsUsedToday: number;
  }> {
    const dayBucket = this.dayBucket();
    const tokensUsed = await this.store.get(`quota:tokens:${userId}:${dayBucket}`);
    const creditsUsed = await this.store.get(`quota:credits:${userId}:${dayBucket}`);
    return { tokensUsedToday: tokensUsed, creditsUsedToday: creditsUsed };
  }
}

/** Singleton. */
let instance: QuotaService | null = null;
export function getQuotaService(): QuotaService {
  if (!instance) instance = new QuotaService();
  return instance;
}
