import { Pool } from 'pg';
import { logger } from '../utils/logger';

export interface UsageRecord {
  userId: string;
  modelId: string;
  provider: string;
  requestId: string;
  inputTokens: number;
  outputTokens: number;
  totalTokens: number;
  creditsConsumed: number;
  latencyMs: number;
  success: boolean;
  timestamp: Date;
}

/**
 * Usage recording service.
 *
 * Records AI usage metadata in PostgreSQL for billing, analytics,
 * and abuse investigation. Does NOT store copies of user prompts
 * (separate usage metadata from conversation content).
 */
export class UsageService {
  constructor(private pool: Pool) {}

  /**
   * Record a single AI usage event.
   */
  async recordUsage(record: UsageRecord): Promise<void> {
    try {
      await this.pool.query(
        `INSERT INTO ai_usage
          (user_id, model_id, provider, request_id, input_tokens, output_tokens,
           total_tokens, credits_consumed, latency_ms, success, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
         ON CONFLICT (request_id) DO NOTHING`,
        [
          record.userId,
          record.modelId,
          record.provider,
          record.requestId,
          record.inputTokens,
          record.outputTokens,
          record.totalTokens,
          record.creditsConsumed,
          record.latencyMs,
          record.success,
          record.timestamp,
        ],
      );
    } catch (error) {
      // Usage recording should never break the request flow
      logger.error({ error }, 'Usage recording failed (non-fatal)');
    }
  }

  /**
   * Get daily token usage for a user.
   */
  async getDailyUsage(userId: string, date: Date): Promise<{
    inputTokens: number;
    outputTokens: number;
    totalTokens: number;
    creditsConsumed: number;
    requestCount: number;
  }> {
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    const result = await this.pool.query(
      `SELECT
        COALESCE(SUM(input_tokens), 0) as input_tokens,
        COALESCE(SUM(output_tokens), 0) as output_tokens,
        COALESCE(SUM(total_tokens), 0) as total_tokens,
        COALESCE(SUM(credits_consumed), 0) as credits_consumed,
        COUNT(*) as request_count
       FROM ai_usage
       WHERE user_id = $1 AND created_at BETWEEN $2 AND $3 AND success = true`,
      [userId, startOfDay, endOfDay],
    );

    const row = result.rows[0];
    return {
      inputTokens: parseInt(row.input_tokens, 10),
      outputTokens: parseInt(row.output_tokens, 10),
      totalTokens: parseInt(row.total_tokens, 10),
      creditsConsumed: parseInt(row.credits_consumed, 10),
      requestCount: parseInt(row.request_count, 10),
    };
  }

  /**
   * Get global daily spend (for billing/kill-switch).
   */
  async getDailySpend(date: Date): Promise<{ totalCredits: number; estimatedCostUSD: number }> {
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    const result = await this.pool.query(
      `SELECT
        COALESCE(SUM(credits_consumed), 0) as total_credits,
        COUNT(*) as request_count
       FROM ai_usage
       WHERE created_at BETWEEN $1 AND $2 AND success = true
       AND provider != 'local'`,
      [startOfDay, endOfDay],
    );

    const row = result.rows[0];
    const totalCredits = parseInt(row.total_credits, 10);
    // Rough cost estimate: 1 credit ≈ $0.001 (configurable in production)
    const estimatedCostUSD = totalCredits * 0.001;

    return { totalCredits, estimatedCostUSD };
  }

  /**
   * Get monthly spend.
   */
  async getMonthlySpend(date: Date): Promise<{ totalCredits: number; estimatedCostUSD: number }> {
    const startOfMonth = new Date(date.getFullYear(), date.getMonth(), 1);
    const endOfMonth = new Date(date.getFullYear(), date.getMonth() + 1, 0, 23, 59, 59, 999);

    const result = await this.pool.query(
      `SELECT COALESCE(SUM(credits_consumed), 0) as total_credits
       FROM ai_usage
       WHERE created_at BETWEEN $1 AND $2 AND success = true
       AND provider != 'local'`,
      [startOfMonth, endOfMonth],
    );

    const totalCredits = parseInt(result.rows[0].total_credits, 10);
    return { totalCredits, estimatedCostUSD: totalCredits * 0.001 };
  }
}
