import { SupabaseClient } from '@supabase/supabase-js';
import { logger } from '../utils/logger';

export interface SyncOperation {
  operation: 'insert' | 'update' | 'delete';
  tableName: string;
  recordId?: string;
  data?: Record<string, any>;
}

export interface SyncQueueItem {
  id: string;
  userId: string;
  operation: string;
  tableName: string;
  recordId?: string;
  data?: Record<string, any>;
  status: 'pending' | 'synced' | 'failed';
  retryCount: number;
  createdAt: string;
}

export interface SyncStatus {
  totalPending: number;
  pendingCount: number;
  syncedCount: number;
  failedCount: number;
  lastSyncAttempt?: string;
}

/**
 * Sync service for bidirectional mobile ↔ server sync
 */
export class SyncService {
  constructor(private supabase: SupabaseClient) {}

  /**
   * Add operation to sync queue
   */
  async queueOperation(
    userId: string,
    operation: SyncOperation,
  ): Promise<SyncQueueItem> {
    try {
      const { data, error } = await this.supabase
        .from('sync_queue')
        .insert({
          user_id: userId,
          operation: operation.operation,
          table_name: operation.tableName,
          record_id: operation.recordId,
          data: operation.data,
          status: 'pending',
        })
        .select()
        .single();

      if (error) throw error;

      logger.info(
        `Operation queued: ${operation.operation} on ${operation.tableName}`,
      );

      return this.mapToSyncQueueItem(data);
    } catch (error) {
      logger.error('Error queuing operation:', error);
      throw error;
    }
  }

  /**
   * Get pending sync operations for user
   */
  async getPendingOperations(userId: string): Promise<SyncQueueItem[]> {
    try {
      const { data, error } = await this.supabase
        .from('sync_queue')
        .select()
        .eq('user_id', userId)
        .eq('status', 'pending')
        .order('created_at', { ascending: true });

      if (error) throw error;

      return (data || []).map((item) => this.mapToSyncQueueItem(item));
    } catch (error) {
      logger.error('Error getting pending operations:', error);
      throw error;
    }
  }

  /**
   * Process pending sync operations
   */
  async processPendingOperations(userId: string): Promise<void> {
    try {
      const operations = await this.getPendingOperations(userId);

      for (const operation of operations) {
        try {
          await this.processOperation(operation);
          await this.markAsSynced(operation.id);
        } catch (error) {
          await this.markAsFailed(operation.id, error);
        }
      }

      logger.info(`Processed ${operations.length} pending operations for user ${userId}`);
    } catch (error) {
      logger.error('Error processing pending operations:', error);
      throw error;
    }
  }

  /**
   * Process single sync operation
   */
  private async processOperation(operation: SyncQueueItem): Promise<void> {
    try {
      switch (operation.operation) {
        case 'insert':
          await this.supabase
            .from(operation.tableName)
            .insert(operation.data);
          break;

        case 'update':
          await this.supabase
            .from(operation.tableName)
            .update(operation.data)
            .eq('id', operation.recordId);
          break;

        case 'delete':
          await this.supabase
            .from(operation.tableName)
            .delete()
            .eq('id', operation.recordId);
          break;

        default:
          throw new Error(`Unknown operation: ${operation.operation}`);
      }

      logger.info(
        `Operation processed: ${operation.operation} on ${operation.tableName}`,
      );
    } catch (error) {
      logger.error('Error processing operation:', error);
      throw error;
    }
  }

  /**
   * Mark operation as synced
   */
  private async markAsSynced(operationId: string): Promise<void> {
    try {
      const { error } = await this.supabase
        .from('sync_queue')
        .update({
          status: 'synced',
          synced_at: new Date().toISOString(),
        })
        .eq('id', operationId);

      if (error) throw error;
    } catch (error) {
      logger.error('Error marking operation as synced:', error);
      throw error;
    }
  }

  /**
   * Mark operation as failed
   */
  private async markAsFailed(operationId: string, error: any): Promise<void> {
    try {
      const errorMessage = error instanceof Error ? error.message : String(error);

      const { data: operation, error: fetchError } = await this.supabase
        .from('sync_queue')
        .select('retry_count, max_retries')
        .eq('id', operationId)
        .single();

      if (fetchError) throw fetchError;

      const retryCount = (operation?.retry_count || 0) + 1;
      const maxRetries = operation?.max_retries || 3;

      const status = retryCount >= maxRetries ? 'failed' : 'pending';

      const { error: updateError } = await this.supabase
        .from('sync_queue')
        .update({
          status,
          error_message: errorMessage,
          retry_count: retryCount,
        })
        .eq('id', operationId);

      if (updateError) throw updateError;

      logger.warn(
        `Operation failed (retry ${retryCount}/${maxRetries}): ${errorMessage}`,
      );
    } catch (error) {
      logger.error('Error marking operation as failed:', error);
      throw error;
    }
  }

  /**
   * Get sync status for user
   */
  async getSyncStatus(userId: string): Promise<SyncStatus> {
    try {
      const { data, error } = await this.supabase
        .from('sync_status')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

      if (error) throw error;

      return {
        totalPending: data?.total_pending || 0,
        pendingCount: data?.pending_count || 0,
        syncedCount: data?.synced_count || 0,
        failedCount: data?.failed_count || 0,
        lastSyncAttempt: data?.last_sync_attempt,
      };
    } catch (error) {
      logger.error('Error getting sync status:', error);
      throw error;
    }
  }

  /**
   * Clear synced operations (older than 7 days)
   */
  async clearOldSyncedOperations(userId: string, daysOld: number = 7): Promise<void> {
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - daysOld);

      const { error } = await this.supabase
        .from('sync_queue')
        .delete()
        .eq('user_id', userId)
        .eq('status', 'synced')
        .lt('synced_at', cutoffDate.toISOString());

      if (error) throw error;

      logger.info(`Cleared old synced operations for user ${userId}`);
    } catch (error) {
      logger.error('Error clearing old synced operations:', error);
      throw error;
    }
  }

  /**
   * Resolve conflicts (server version wins)
   */
  async resolveConflict(
    userId: string,
    tableName: string,
    recordId: string,
    serverData: Record<string, any>,
  ): Promise<void> {
    try {
      // Update local record with server version
      const { error } = await this.supabase
        .from(tableName)
        .update(serverData)
        .eq('id', recordId)
        .eq('user_id', userId);

      if (error) throw error;

      // Remove conflicting sync operation
      await this.supabase
        .from('sync_queue')
        .delete()
        .eq('user_id', userId)
        .eq('table_name', tableName)
        .eq('record_id', recordId)
        .eq('status', 'pending');

      logger.info(`Conflict resolved for ${tableName}/${recordId}`);
    } catch (error) {
      logger.error('Error resolving conflict:', error);
      throw error;
    }
  }

  /**
   * Map database row to SyncQueueItem
   */
  private mapToSyncQueueItem(data: any): SyncQueueItem {
    return {
      id: data.id,
      userId: data.user_id,
      operation: data.operation,
      tableName: data.table_name,
      recordId: data.record_id,
      data: data.data,
      status: data.status,
      retryCount: data.retry_count,
      createdAt: data.created_at,
    };
  }
}
