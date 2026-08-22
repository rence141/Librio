import { getStore, KVStore } from './store.service';
import { logger } from '../utils/logger';

export type ThreatLevel = 'normal' | 'warning' | 'cooldown' | 'restricted' | 'manual_review';

export interface AbuseScore {
  level: ThreatLevel;
  score: number; // 0-100
  signals: string[];
  cooldownSeconds?: number;
}

/**
 * Abuse and anomaly detection service.
 *
 * Uses progressive responses:
 *   Normal → Warning → Cooldown → Reduced quota → Temporary restriction → Manual review
 *
 * Never permanently bans based on a single weak signal.
 * Uses multiple signals: request patterns, token usage, IP/device changes, etc.
 */
export class AbuseDetectionService {
  constructor(private store: KVStore = getStore()) {}

  /**
   * Evaluate a user's behavior and return a threat assessment.
   */
  async evaluate(userId: string, _ip: string, _deviceId?: string): Promise<AbuseScore> {
    const now = Math.floor(Date.now() / 1000);
    const signals: string[] = [];
    let score = 0;

    // Signal 1: High request velocity (100+ in 2 minutes)
    const fastKey = `abuse:fast:${userId}:${Math.floor(now / 120)}`;
    const fastCount = await this.store.get(fastKey);
    if (fastCount > 100) {
      score += 30;
      signals.push('high_request_velocity');
    }

    // Signal 2: Repeated identical prompts
    const repeatKey = `abuse:repeat:${userId}`;
    const repeatCount = await this.store.get(repeatKey);
    if (repeatCount > 10) {
      score += 15;
      signals.push('repeated_identical_prompts');
    }

    // Signal 3: Multiple IP changes in short window
    const ipKey = `abuse:ips:${userId}`;
    const ipList = await this.store.getString(ipKey);
    if (ipList) {
      const ips = ipList.split(',').filter(Boolean);
      const uniqueIps = new Set(ips).size;
      if (uniqueIps > 5) {
        score += 20;
        signals.push('multiple_ip_changes');
      }
    }

    // Signal 4: Large token usage spike
    const tokenKey = `abuse:tokens:${userId}:${Math.floor(now / 3600)}`;
    const tokenUsage = await this.store.get(tokenKey);
    if (tokenUsage > 50_000) {
      score += 15;
      signals.push('large_token_spike');
    }

    // Signal 5: Existing cooldown
    const cooldownKey = `abuse:cooldown:${userId}`;
    const cooldownExists = await this.store.exists(cooldownKey);
    if (cooldownExists) {
      score += 40;
      signals.push('active_cooldown');
    }

    // Determine threat level
    let level: ThreatLevel = 'normal';
    let cooldownSeconds: number | undefined;

    if (score >= 70) {
      level = 'restricted';
      cooldownSeconds = 3600; // 1 hour
      await this.store.set(cooldownKey, '1', cooldownSeconds);
      logger.warn({ userId, score, signals }, 'Abuse: user restricted');
    } else if (score >= 50) {
      level = 'cooldown';
      cooldownSeconds = 600; // 10 minutes
      await this.store.set(cooldownKey, '1', cooldownSeconds);
      logger.warn({ userId, score, signals }, 'Abuse: user in cooldown');
    } else if (score >= 30) {
      level = 'warning';
      logger.info({ userId, score, signals }, 'Abuse: warning');
    } else if (score >= 15) {
      level = 'warning';
    }

    return { level, score, signals, cooldownSeconds };
  }

  /**
   * Track a request for anomaly detection.
   */
  async trackRequest(userId: string, ip: string, promptHash: string, tokenCount: number): Promise<void> {
    const now = Math.floor(Date.now() / 1000);

    // Fast request counter
    await this.store.incr(`abuse:fast:${userId}:${Math.floor(now / 120)}`, 130);

    // Token usage per hour
    await this.store.incr(`abuse:tokens:${userId}:${Math.floor(now / 3600)}`, 3700, tokenCount);

    // Track IPs (keep last 10)
    const ipKey = `abuse:ips:${userId}`;
    const existing = await this.store.getString(ipKey);
    const ips = (existing ?? '').split(',').filter(Boolean).slice(-9);
    if (!ips.includes(ip)) ips.push(ip);
    await this.store.set(ipKey, ips.join(','), 86400);

    // Track repeated prompts
    const promptKey = `abuse:prompt:${userId}:${promptHash}`;
    const promptCount = await this.store.incr(promptKey, 3600);
    if (promptCount > 1) {
      await this.store.incr(`abuse:repeat:${userId}`, 86400);
    }
  }

  /**
   * Check if user is currently in cooldown/restriction.
   */
  async isRestricted(userId: string): Promise<boolean> {
    return this.store.exists(`abuse:cooldown:${userId}`);
  }
}

/** Singleton. */
let instance: AbuseDetectionService | null = null;
export function getAbuseDetectionService(): AbuseDetectionService {
  if (!instance) instance = new AbuseDetectionService();
  return instance;
}
