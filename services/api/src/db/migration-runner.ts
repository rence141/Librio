/**
 * Database Migration Runner
 * Manages schema versioning and migration execution
 */

import { Pool, PoolClient } from 'pg';
import * as fs from 'fs';
import * as path from 'path';
import { logger } from '../utils/logger';

interface Migration {
  version: string;
  name: string;
  filePath: string;
  timestamp: number;
}

interface MigrationRecord {
  id: number;
  version: string;
  name: string;
  executed_at: Date;
  duration_ms: number;
}

/**
 * Migration runner for managing database schema versions
 */
export class MigrationRunner {
  private pool: Pool;
  private migrationsDir: string;

  constructor(pool: Pool, migrationsDir: string = './src/db/migrations') {
    this.pool = pool;
    this.migrationsDir = migrationsDir;
  }

  /**
   * Initialize migrations table
   */
  async initializeMigrationsTable(): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query(`
        CREATE TABLE IF NOT EXISTS schema_migrations (
          id SERIAL PRIMARY KEY,
          version VARCHAR(50) NOT NULL UNIQUE,
          name VARCHAR(255) NOT NULL,
          executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          duration_ms INTEGER,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        CREATE INDEX IF NOT EXISTS idx_schema_migrations_version 
        ON schema_migrations(version);
      `);
      
      logger.info('Migrations table initialized');
    } finally {
      client.release();
    }
  }

  /**
   * Get all migration files
   */
  private async getMigrationFiles(): Promise<Migration[]> {
    try {
      const files = fs.readdirSync(this.migrationsDir);
      const migrations: Migration[] = [];

      for (const file of files) {
        if (!file.endsWith('.sql')) continue;

        const match = file.match(/^(\d{3})_(.+)\.sql$/);
        if (!match) continue;

        const [, version, name] = match;
        const filePath = path.join(this.migrationsDir, file);
        const stat = fs.statSync(filePath);

        migrations.push({
          version,
          name,
          filePath,
          timestamp: stat.mtimeMs,
        });
      }

      return migrations.sort((a, b) => a.version.localeCompare(b.version));
    } catch (error) {
      logger.error('Failed to read migration files', error);
      throw error;
    }
  }

  /**
   * Get executed migrations
   */
  private async getExecutedMigrations(): Promise<MigrationRecord[]> {
    const client = await this.pool.connect();
    try {
      const result = await client.query(
        'SELECT * FROM schema_migrations ORDER BY version ASC'
      );
      return result.rows;
    } finally {
      client.release();
    }
  }

  /**
   * Get pending migrations
   */
  async getPendingMigrations(): Promise<Migration[]> {
    const allMigrations = await this.getMigrationFiles();
    const executedMigrations = await this.getExecutedMigrations();
    const executedVersions = new Set(executedMigrations.map((m) => m.version));

    return allMigrations.filter((m) => !executedVersions.has(m.version));
  }

  /**
   * Run a single migration
   */
  private async runMigration(
    client: PoolClient,
    migration: Migration
  ): Promise<number> {
    const startTime = Date.now();

    try {
      const sql = fs.readFileSync(migration.filePath, 'utf-8');

      logger.info(`Running migration: ${migration.version} - ${migration.name}`);

      // Execute migration
      await client.query(sql);

      // Record migration
      const duration = Date.now() - startTime;
      await client.query(
        `INSERT INTO schema_migrations (version, name, duration_ms) 
         VALUES ($1, $2, $3)`,
        [migration.version, migration.name, duration]
      );

      logger.info(
        `Migration completed: ${migration.version} (${duration}ms)`
      );

      return duration;
    } catch (error) {
      logger.error(
        `Migration failed: ${migration.version} - ${migration.name}`,
        error
      );
      throw error;
    }
  }

  /**
   * Run all pending migrations
   */
  async runPendingMigrations(): Promise<void> {
    const pendingMigrations = await this.getPendingMigrations();

    if (pendingMigrations.length === 0) {
      logger.info('No pending migrations');
      return;
    }

    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      for (const migration of pendingMigrations) {
        await this.runMigration(client, migration);
      }

      await client.query('COMMIT');
      logger.info(
        `Successfully executed ${pendingMigrations.length} migration(s)`
      );
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Migration rollback executed', error);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Get migration status
   */
  async getStatus(): Promise<{
    executed: MigrationRecord[];
    pending: Migration[];
  }> {
    const executed = await this.getExecutedMigrations();
    const pending = await this.getPendingMigrations();

    return { executed, pending };
  }

  /**
   * Rollback last migration
   */
  async rollbackLast(): Promise<void> {
    const executed = await this.getExecutedMigrations();

    if (executed.length === 0) {
      logger.warn('No migrations to rollback');
      return;
    }

    const lastMigration = executed[executed.length - 1];
    const client = await this.pool.connect();

    try {
      await client.query('BEGIN');

      // Note: Rollback logic depends on migration content
      // For now, we just remove the migration record
      await client.query(
        'DELETE FROM schema_migrations WHERE version = $1',
        [lastMigration.version]
      );

      await client.query('COMMIT');
      logger.info(`Rolled back migration: ${lastMigration.version}`);
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Rollback failed', error);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Print migration status
   */
  async printStatus(): Promise<void> {
    const { executed, pending } = await this.getStatus();

    console.log('\n=== Database Migration Status ===\n');

    if (executed.length > 0) {
      console.log('Executed Migrations:');
      for (const migration of executed) {
        console.log(
          `  ✓ ${migration.version} - ${migration.name} (${migration.duration_ms}ms)`
        );
      }
    }

    if (pending.length > 0) {
      console.log('\nPending Migrations:');
      for (const migration of pending) {
        console.log(`  ⏳ ${migration.version} - ${migration.name}`);
      }
    }

    if (executed.length === 0 && pending.length === 0) {
      console.log('No migrations found');
    }

    console.log('\n');
  }
}

/**
 * Initialize and run migrations
 */
export async function initializeMigrations(pool: Pool): Promise<void> {
  const runner = new MigrationRunner(pool);

  try {
    await runner.initializeMigrationsTable();
    await runner.runPendingMigrations();
    await runner.printStatus();
  } catch (error) {
    logger.error('Migration initialization failed', error);
    throw error;
  }
}
