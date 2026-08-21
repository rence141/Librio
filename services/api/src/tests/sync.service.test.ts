import { describe, it, expect, beforeEach, vi } from 'vitest';
import { SyncService } from '../services/sync.service';

const mockSupabaseClient = {
  from: vi.fn(),
};

describe('SyncService', () => {
  let syncService: SyncService;

  beforeEach(() => {
    vi.clearAllMocks();
    syncService = new SyncService(mockSupabaseClient as any);
  });

  describe('queueOperation', () => {
    it('should queue an insert operation', async () => {
      const mockInsert = vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          single: vi.fn().mockResolvedValue({
            data: {
              id: 'op-123',
              user_id: 'user-123',
              operation: 'insert',
              table_name: 'documents',
              status: 'pending',
              retry_count: 0,
              created_at: new Date().toISOString(),
            },
            error: null,
          }),
        }),
      });

      mockSupabaseClient.from.mockReturnValue({
        insert: mockInsert,
      });

      const result = await syncService.queueOperation('user-123', {
        operation: 'insert',
        tableName: 'documents',
        data: { title: 'Test Document' },
      });

      expect(result.id).toBe('op-123');
      expect(result.operation).toBe('insert');
      expect(result.status).toBe('pending');
      expect(mockInsert).toHaveBeenCalled();
    });

    it('should queue an update operation', async () => {
      const mockInsert = vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          single: vi.fn().mockResolvedValue({
            data: {
              id: 'op-124',
              operation: 'update',
              table_name: 'documents',
              record_id: 'doc-123',
              status: 'pending',
              retry_count: 0,
              created_at: new Date().toISOString(),
            },
            error: null,
          }),
        }),
      });

      mockSupabaseClient.from.mockReturnValue({
        insert: mockInsert,
      });

      const result = await syncService.queueOperation('user-123', {
        operation: 'update',
        tableName: 'documents',
        recordId: 'doc-123',
        data: { title: 'Updated Document' },
      });

      expect(result.operation).toBe('update');
      expect(result.recordId).toBe('doc-123');
    });

    it('should queue a delete operation', async () => {
      const mockInsert = vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          single: vi.fn().mockResolvedValue({
            data: {
              id: 'op-125',
              operation: 'delete',
              table_name: 'documents',
              record_id: 'doc-123',
              status: 'pending',
              retry_count: 0,
              created_at: new Date().toISOString(),
            },
            error: null,
          }),
        }),
      });

      mockSupabaseClient.from.mockReturnValue({
        insert: mockInsert,
      });

      const result = await syncService.queueOperation('user-123', {
        operation: 'delete',
        tableName: 'documents',
        recordId: 'doc-123',
      });

      expect(result.operation).toBe('delete');
    });
  });

  describe('getPendingOperations', () => {
    it('should get pending operations for user', async () => {
      const mockSelect = vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            order: vi.fn().mockResolvedValue({
              data: [
                {
                  id: 'op-1',
                  user_id: 'user-123',
                  operation: 'insert',
                  table_name: 'documents',
                  status: 'pending',
                  retry_count: 0,
                  created_at: new Date().toISOString(),
                },
              ],
              error: null,
            }),
          }),
        }),
      });

      mockSupabaseClient.from.mockReturnValue({
        select: mockSelect,
      });

      const result = await syncService.getPendingOperations('user-123');

      expect(result).toHaveLength(1);
      expect(result[0].status).toBe('pending');
      expect(result[0].userId).toBe('user-123');
    });

    it('should return empty array when no pending operations', async () => {
      const mockSelect = vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            order: vi.fn().mockResolvedValue({
              data: [],
              error: null,
            }),
          }),
        }),
      });

      mockSupabaseClient.from.mockReturnValue({
        select: mockSelect,
      });

      const result = await syncService.getPendingOperations('user-123');

      expect(result).toHaveLength(0);
    });
  });

  describe('getSyncStatus', () => {
    it('should get sync status for user', async () => {
      const mockSelect = vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          maybeSingle: vi.fn().mockResolvedValue({
            data: {
              user_id: 'user-123',
              total_pending: 5,
              pending_count: 3,
              synced_count: 100,
              failed_count: 2,
              last_sync_attempt: new Date().toISOString(),
            },
            error: null,
          }),
        }),
      });

      mockSupabaseClient.from.mockReturnValue({
        select: mockSelect,
      });

      const result = await syncService.getSyncStatus('user-123');

      expect(result.totalPending).toBe(5);
      expect(result.pendingCount).toBe(3);
      expect(result.syncedCount).toBe(100);
      expect(result.failedCount).toBe(2);
    });
  });

  describe('clearOldSyncedOperations', () => {
    it('should clear synced operations older than 7 days', async () => {
      const mockDelete = vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            lt: vi.fn().mockResolvedValue({
              error: null,
            }),
          }),
        }),
      });

      mockSupabaseClient.from.mockReturnValue({
        delete: mockDelete,
      });

      await expect(syncService.clearOldSyncedOperations('user-123', 7)).resolves.not.toThrow();
      expect(mockDelete).toHaveBeenCalled();
    });
  });

  describe('resolveConflict', () => {
    it('should resolve conflict by using server version', async () => {
      const mockUpdate = vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          eq: vi.fn().mockResolvedValue({
            error: null,
          }),
        }),
      });

      const mockDelete = vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              eq: vi.fn().mockResolvedValue({
                error: null,
              }),
            }),
          }),
        }),
      });

      mockSupabaseClient.from.mockImplementation((table) => {
        if (table === 'documents') {
          return { update: mockUpdate };
        }
        return { delete: mockDelete };
      });

      await expect(
        syncService.resolveConflict('user-123', 'documents', 'doc-123', {
          title: 'Server Version',
        }),
      ).resolves.not.toThrow();
    });
  });
});
