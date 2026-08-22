import { SupabaseClient } from '@supabase/supabase-js';
import { logger } from '../utils/logger';

export interface UserStats {
  id: string;
  email: string;
  fullName?: string;
  subscriptionTier: string;
  createdAt: string;
  lastActive?: string;
  documentsCount: number;
  sessionsCount: number;
  benchmarksCount: number;
  storageUsedMb: number;
  storageLimit: number;
}

export interface MaterialStats {
  id: string;
  title: string;
  subject: string;
  topic?: string;
  createdBy: string;
  isPublic: boolean;
  isFeatured: boolean;
  downloadCount: number;
  rating?: number;
  createdAt: string;
}

export interface AnalyticsData {
  totalUsers: number;
  activeUsers: number;
  totalDocuments: number;
  totalSessions: number;
  totalBenchmarks: number;
  averageSessionDuration: number;
  topSubjects: Array<{ subject: string; count: number }>;
  eventDistribution: Record<string, number>;
}

export interface SystemHealth {
  databaseStatus: 'healthy' | 'degraded' | 'down';
  apiStatus: 'healthy' | 'degraded' | 'down';
  syncQueueSize: number;
  failedSyncs: number;
  cacheHitRate: number;
  averageLatency: number;
}

/**
 * Admin service for user management, content management, and analytics
 */
export class AdminService {
  constructor(private supabase: SupabaseClient) {}

  // ============ USER MANAGEMENT ============

  /**
   * Get all users with stats
   */
  async getAllUsers(limit: number = 100, offset: number = 0): Promise<UserStats[]> {
    try {
      const { data: users, error } = await this.supabase
        .from('user_profiles')
        .select()
        .range(offset, offset + limit - 1)
        .order('created_at', { ascending: false });

      if (error) throw error;

      // Enrich with stats
      const enriched = await Promise.all(
        (users || []).map((user) => this.getUserStats(user.id)),
      );

      return enriched;
    } catch (error) {
      logger.error('Error getting all users:', error);
      throw error;
    }
  }

  /**
   * Get user stats
   */
  async getUserStats(userId: string): Promise<UserStats> {
    try {
      const [profile, docs, sessions, benchmarks] = await Promise.all([
        this.supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle(),
        this.supabase
          .from('documents')
          .select('id', { count: 'exact' })
          .eq('user_id', userId),
        this.supabase
          .from('sessions')
          .select('id', { count: 'exact' })
          .eq('user_id', userId),
        this.supabase
          .from('benchmarks')
          .select('id', { count: 'exact' })
          .eq('user_id', userId),
      ]);

      if (profile.error) throw profile.error;

      const user = profile.data;

      return {
        id: user.id,
        email: user.email,
        fullName: user.full_name,
        subscriptionTier: user.subscription_tier,
        createdAt: user.created_at,
        lastActive: user.updated_at,
        documentsCount: docs.count || 0,
        sessionsCount: sessions.count || 0,
        benchmarksCount: benchmarks.count || 0,
        storageUsedMb: user.storage_used_mb || 0,
        storageLimit: user.storage_limit_mb || 1000,
      };
    } catch (error) {
      logger.error('Error getting user stats:', error);
      throw error;
    }
  }

  /**
   * Update user subscription tier
   */
  async updateUserSubscription(userId: string, tier: 'free' | 'pro' | 'enterprise'): Promise<void> {
    try {
      const limits: Record<string, number> = {
        free: 1000,
        pro: 10000,
        enterprise: 100000,
      };

      const { error } = await this.supabase
        .from('user_profiles')
        .update({
          subscription_tier: tier,
          storage_limit_mb: limits[tier],
        })
        .eq('id', userId);

      if (error) throw error;

      logger.info(`User ${userId} subscription updated to ${tier}`);
    } catch (error) {
      logger.error('Error updating user subscription:', error);
      throw error;
    }
  }

  /**
   * Delete user and all data
   */
  async deleteUser(userId: string): Promise<void> {
    try {
      // Delete all user data
      await Promise.all([
        this.supabase.from('documents').delete().eq('user_id', userId),
        this.supabase.from('sessions').delete().eq('user_id', userId),
        this.supabase.from('benchmarks').delete().eq('user_id', userId),
        this.supabase.from('user_progress').delete().eq('user_id', userId),
        this.supabase.from('sync_queue').delete().eq('user_id', userId),
        this.supabase.from('analytics').delete().eq('user_id', userId),
      ]);

      // Delete user profile
      const { error } = await this.supabase
        .from('user_profiles')
        .delete()
        .eq('id', userId);

      if (error) throw error;

      logger.info(`User ${userId} deleted`);
    } catch (error) {
      logger.error('Error deleting user:', error);
      throw error;
    }
  }

  // ============ CONTENT MANAGEMENT ============

  /**
   * Get all materials
   */
  async getAllMaterials(limit: number = 100, offset: number = 0): Promise<MaterialStats[]> {
    try {
      const { data, error } = await this.supabase
        .from('materials')
        .select()
        .range(offset, offset + limit - 1)
        .order('created_at', { ascending: false });

      if (error) throw error;

      return (data || []).map((m) => ({
        id: m.id,
        title: m.title,
        subject: m.subject,
        topic: m.topic,
        createdBy: m.created_by,
        isPublic: m.is_public,
        isFeatured: m.is_featured,
        downloadCount: m.download_count,
        rating: m.rating,
        createdAt: m.created_at,
      }));
    } catch (error) {
      logger.error('Error getting all materials:', error);
      throw error;
    }
  }

  /**
   * Get materials by subject
   */
  async getMaterialsBySubject(subject: string): Promise<MaterialStats[]> {
    try {
      const { data, error } = await this.supabase
        .from('materials')
        .select()
        .eq('subject', subject)
        .order('download_count', { ascending: false });

      if (error) throw error;

      return (data || []).map((m) => ({
        id: m.id,
        title: m.title,
        subject: m.subject,
        topic: m.topic,
        createdBy: m.created_by,
        isPublic: m.is_public,
        isFeatured: m.is_featured,
        downloadCount: m.download_count,
        rating: m.rating,
        createdAt: m.created_at,
      }));
    } catch (error) {
      logger.error('Error getting materials by subject:', error);
      throw error;
    }
  }

  /**
   * Feature/unfeature material
   */
  async setMaterialFeatured(materialId: string, featured: boolean): Promise<void> {
    try {
      const { error } = await this.supabase
        .from('materials')
        .update({ is_featured: featured })
        .eq('id', materialId);

      if (error) throw error;

      logger.info(`Material ${materialId} featured: ${featured}`);
    } catch (error) {
      logger.error('Error setting material featured:', error);
      throw error;
    }
  }

  /**
   * Delete material
   */
  async deleteMaterial(materialId: string): Promise<void> {
    try {
      const { error } = await this.supabase
        .from('materials')
        .delete()
        .eq('id', materialId);

      if (error) throw error;

      logger.info(`Material ${materialId} deleted`);
    } catch (error) {
      logger.error('Error deleting material:', error);
      throw error;
    }
  }

  /**
   * Get featured materials
   */
  async getFeaturedMaterials(): Promise<MaterialStats[]> {
    try {
      const { data, error } = await this.supabase
        .from('materials')
        .select()
        .eq('is_featured', true)
        .eq('is_public', true)
        .order('download_count', { ascending: false });

      if (error) throw error;

      return (data || []).map((m) => ({
        id: m.id,
        title: m.title,
        subject: m.subject,
        topic: m.topic,
        createdBy: m.created_by,
        isPublic: m.is_public,
        isFeatured: m.is_featured,
        downloadCount: m.download_count,
        rating: m.rating,
        createdAt: m.created_at,
      }));
    } catch (error) {
      logger.error('Error getting featured materials:', error);
      throw error;
    }
  }

  // ============ ANALYTICS ============

  /**
   * Get analytics data
   */
  async getAnalytics(): Promise<AnalyticsData> {
    try {
      const [
        usersResult,
        docsResult,
        sessionsResult,
        benchmarksResult,
        eventsResult,
        progressResult,
      ] = await Promise.all([
        this.supabase.from('user_profiles').select('id', { count: 'exact' }),
        this.supabase.from('documents').select('id', { count: 'exact' }),
        this.supabase.from('sessions').select('id', { count: 'exact' }),
        this.supabase.from('benchmarks').select('id', { count: 'exact' }),
        this.supabase.from('analytics').select('event_type'),
        this.supabase.from('user_progress').select('time_spent_minutes'),
      ]);

      // Count active users (last 7 days)
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

      const { count: activeUsersCount } = await this.supabase
        .from('user_profiles')
        .select('id', { count: 'exact' })
        .gte('updated_at', sevenDaysAgo.toISOString());

      // Get top subjects
      const { data: topSubjectsData } = await this.supabase
        .from('user_progress')
        .select('subject')
        .order('subject');

      const subjectCounts: Record<string, number> = {};
      (topSubjectsData || []).forEach((item) => {
        subjectCounts[item.subject] = (subjectCounts[item.subject] || 0) + 1;
      });

      const topSubjects = Object.entries(subjectCounts)
        .map(([subject, count]) => ({ subject, count }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 5);

      // Get event distribution
      const eventDistribution: Record<string, number> = {};
      (eventsResult.data || []).forEach((item) => {
        eventDistribution[item.event_type] = (eventDistribution[item.event_type] || 0) + 1;
      });

      // Calculate average session duration
      const totalMinutes = (progressResult.data || []).reduce(
        (sum, item) => sum + (item.time_spent_minutes || 0),
        0,
      );
      const sessionCount = sessionsResult.count || 1;
      const averageSessionDuration = Math.round(totalMinutes / sessionCount);

      return {
        totalUsers: usersResult.count || 0,
        activeUsers: activeUsersCount || 0,
        totalDocuments: docsResult.count || 0,
        totalSessions: sessionsResult.count || 0,
        totalBenchmarks: benchmarksResult.count || 0,
        averageSessionDuration,
        topSubjects,
        eventDistribution,
      };
    } catch (error) {
      logger.error('Error getting analytics:', error);
      throw error;
    }
  }

  /**
   * Get user analytics
   */
  async getUserAnalytics(userId: string): Promise<Record<string, any>> {
    try {
      const [progress, events] = await Promise.all([
        this.supabase
          .from('user_progress')
          .select()
          .eq('user_id', userId)
          .order('created_at', { ascending: false }),
        this.supabase
          .from('analytics')
          .select()
          .eq('user_id', userId)
          .order('created_at', { ascending: false })
          .limit(100),
      ]);

      if (progress.error) throw progress.error;
      if (events.error) throw events.error;

      return {
        progress: progress.data,
        events: events.data,
      };
    } catch (error) {
      logger.error('Error getting user analytics:', error);
      throw error;
    }
  }

  // ============ SYSTEM MONITORING ============

  /**
   * Get system health
   */
  async getSystemHealth(): Promise<SystemHealth> {
    try {
      const [syncQueue, failedSyncs] = await Promise.all([
        this.supabase
          .from('sync_queue')
          .select('id', { count: 'exact' })
          .eq('status', 'pending'),
        this.supabase
          .from('sync_queue')
          .select('id', { count: 'exact' })
          .eq('status', 'failed'),
      ]);

      return {
        databaseStatus: 'healthy',
        apiStatus: 'healthy',
        syncQueueSize: syncQueue.count || 0,
        failedSyncs: failedSyncs.count || 0,
        cacheHitRate: 85, // Placeholder
        averageLatency: 150, // Placeholder
      };
    } catch (error) {
      logger.error('Error getting system health:', error);
      return {
        databaseStatus: 'degraded',
        apiStatus: 'degraded',
        syncQueueSize: 0,
        failedSyncs: 0,
        cacheHitRate: 0,
        averageLatency: 0,
      };
    }
  }

  /**
   * Get sync queue status
   */
  async getSyncQueueStatus(): Promise<Record<string, any>> {
    try {
      const { data, error } = await this.supabase
        .from('sync_queue')
        .select('status');

      if (error) throw error;

      // Count statuses manually
      const statusCounts = {
        pending: 0,
        synced: 0,
        failed: 0,
      };

      (data || []).forEach((item: any) => {
        if (item.status in statusCounts) {
          statusCounts[item.status as keyof typeof statusCounts]++;
        }
      });

      return statusCounts;
    } catch (error) {
      logger.error('Error getting sync queue status:', error);
      throw error;
    }
  }

  /**
   * Get failed syncs
   */
  async getFailedSyncs(limit: number = 50): Promise<Record<string, any>[]> {
    try {
      const { data, error } = await this.supabase
        .from('sync_queue')
        .select()
        .eq('status', 'failed')
        .order('created_at', { ascending: false })
        .limit(limit);

      if (error) throw error;

      return data || [];
    } catch (error) {
      logger.error('Error getting failed syncs:', error);
      throw error;
    }
  }

  /**
   * Retry failed sync
   */
  async retrySyncOperation(operationId: string): Promise<void> {
    try {
      const { error } = await this.supabase
        .from('sync_queue')
        .update({
          status: 'pending',
          retry_count: 0,
          error_message: null,
        })
        .eq('id', operationId);

      if (error) throw error;

      logger.info(`Sync operation ${operationId} retried`);
    } catch (error) {
      logger.error('Error retrying sync operation:', error);
      throw error;
    }
  }
}
