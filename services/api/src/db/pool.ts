import { Pool } from 'pg';
import { logger } from '../utils/logger';

let pool: Pool | null = null;

/**
 * Get the shared PostgreSQL connection pool.
 * Uses DATABASE_URL from environment.
 */
export function getDbPool(): Pool {
  if (!pool) {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) {
      logger.warn('DATABASE_URL not set. DB operations will fail.');
    }
    pool = new Pool({
      connectionString,
      max: 10,
      idleTimeoutMillis: 30_000,
      connectionTimeoutMillis: 5_000,
    });
    logger.info('Database pool initialized');
  }
  return pool;
}

/** Close the pool (for graceful shutdown). */
export async function closeDbPool(): Promise<void> {
  if (pool) {
    await pool.end();
    pool = null;
    logger.info('Database pool closed');
  }
}
