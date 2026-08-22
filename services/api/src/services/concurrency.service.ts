import { getStore, KVStore } from './store.service';
import { CONCURRENCY_LEASE_TTL_SEC } from '../config/guardrails.config';
import { logger } from '../utils/logger';

export interface ConcurrencyStatus {
  allowed: boolean;
  activeCount: number;
  limit: number;
}

/**
 * Concurrency limiter using TTL-based leases.
 *
 * Prevents users from creating many simultaneous AI generations.
 * Leases auto-expire so abandoned requests (disconnects, crashes)
 * don't permanently consume concurrency slots.
 */
export class ConcurrencyService {
  constructor(private store: KVStore = getStore()) {}

  private prefix(userId: string): string {
    return `conc:${userId}`;
  }

  /**
   * Acquire a concurrency slot.
   * Returns a lease ID that must be released after generation.
   */
  async acquire(userId: string, maxConcurrency: number): Promise<{ allowed: boolean; leaseId: string | null }> {
    const prefix = this.prefix(userId);
    const activeKeys = await this.store.keys(prefix);

    if (activeKeys.length >= maxConcurrency) {
      logger.warn({ userId, active: activeKeys.length, max: maxConcurrency }, 'Concurrency: limit exceeded');
      return { allowed: false, leaseId: null };
    }

    const leaseId = `lease_${Date.now()}_${Math.random().toString(36).slice(2, 11)}`;
    const key = `${prefix}:${leaseId}`;
    await this.store.set(key, '1', CONCURRENCY_LEASE_TTL_SEC);

    logger.info({ userId, leaseId, active: activeKeys.length + 1 }, 'Concurrency: lease acquired');
    return { allowed: true, leaseId };
  }

  /**
   * Release a concurrency slot.
   */
  async release(userId: string, leaseId: string): Promise<void> {
    if (!leaseId) return;
    const key = `${this.prefix(userId)}:${leaseId}`;
    await this.store.del(key);
    logger.info({ userId, leaseId }, 'Concurrency: lease released');
  }

  /**
   * Get active count for a user.
   */
  async getActiveCount(userId: string): Promise<number> {
    const keys = await this.store.keys(this.prefix(userId));
    return keys.length;
  }
}

/** Singleton. */
let instance: ConcurrencyService | null = null;
export function getConcurrencyService(): ConcurrencyService {
  if (!instance) instance = new ConcurrencyService();
  return instance;
}
