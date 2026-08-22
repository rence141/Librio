import { logger } from '../utils/logger';

/**
 * KV Store abstraction.
 *
 * Uses in-memory storage by default. In production, swap with Redis
 * by implementing the same interface with ioredis.
 *
 * Used for: rate-limit counters, concurrency locks, request leases,
 * temporary abuse scores, idempotency keys, cooldowns.
 */
export interface KVStore {
  /** Increment a counter by amount, returns new value. */
  incr(key: string, ttlSec: number, amount?: number): Promise<number>;

  /** Get current value. */
  get(key: string): Promise<number>;

  /** Set a string value with TTL. */
  set(key: string, value: string, ttlSec: number): Promise<void>;

  /** Get a string value. */
  getString(key: string): Promise<string | null>;

  /** Delete a key. */
  del(key: string): Promise<void>;

  /** Check if key exists. */
  exists(key: string): Promise<boolean>;

  /** Set NX (only if not exists) with TTL. Returns true if set. */
  setNx(key: string, value: string, ttlSec: number): Promise<boolean>;

  /** Get all keys matching a prefix. */
  keys(prefix: string): Promise<string[]>;
}

/** In-memory implementation with TTL support. */
class InMemoryStore implements KVStore {
  private data = new Map<string, { value: string; expiry: number }>();
  private counters = new Map<string, { value: number; expiry: number }>();

  private cleanup(): void {
    const now = Date.now();
    for (const [k, v] of this.data) {
      if (v.expiry < now) this.data.delete(k);
    }
    for (const [k, v] of this.counters) {
      if (v.expiry < now) this.counters.delete(k);
    }
  }

  async incr(key: string, ttlSec: number, amount = 1): Promise<number> {
    this.cleanup();
    const existing = this.counters.get(key);
    const now = Date.now();

    if (!existing || existing.expiry < now) {
      this.counters.set(key, { value: amount, expiry: now + ttlSec * 1000 });
      return amount;
    }

    existing.value += amount;
    return existing.value;
  }

  async get(key: string): Promise<number> {
    this.cleanup();
    return this.counters.get(key)?.value ?? 0;
  }

  async set(key: string, value: string, ttlSec: number): Promise<void> {
    this.data.set(key, { value, expiry: Date.now() + ttlSec * 1000 });
  }

  async getString(key: string): Promise<string | null> {
    this.cleanup();
    return this.data.get(key)?.value ?? null;
  }

  async del(key: string): Promise<void> {
    this.data.delete(key);
    this.counters.delete(key);
  }

  async exists(key: string): Promise<boolean> {
    this.cleanup();
    return this.data.has(key) || this.counters.has(key);
  }

  async setNx(key: string, value: string, ttlSec: number): Promise<boolean> {
    this.cleanup();
    if (this.data.has(key)) return false;
    this.data.set(key, { value, expiry: Date.now() + ttlSec * 1000 });
    return true;
  }

  async keys(prefix: string): Promise<string[]> {
    this.cleanup();
    const result: string[] = [];
    for (const k of this.data.keys()) {
      if (k.startsWith(prefix)) result.push(k);
    }
    for (const k of this.counters.keys()) {
      if (k.startsWith(prefix)) result.push(k);
    }
    return result;
  }
}

/** Singleton store instance. */
let storeInstance: KVStore | null = null;

export function getStore(): KVStore {
  if (!storeInstance) {
    // In production, check for REDIS_URL and use Redis client instead.
    const redisUrl = process.env.REDIS_URL;
    if (redisUrl) {
      logger.info('Redis URL detected. (Redis adapter not yet wired — using in-memory fallback.)');
    }
    storeInstance = new InMemoryStore();
    logger.info('KV store initialized (in-memory)');
  }
  return storeInstance;
}

/** Reset store (for testing). */
export function resetStore(): void {
  storeInstance = null;
}
