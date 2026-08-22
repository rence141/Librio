import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { logger } from '../utils/logger';

/**
 * Supabase service for backend database operations
 */
export class SupabaseService {
  private client: SupabaseClient;

  constructor() {
    const url = process.env.SUPABASE_URL;
    const serviceKey = process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_KEY;

    if (!url || !serviceKey) {
      throw new Error('Missing Supabase credentials. Please set SUPABASE_URL and SUPABASE_SECRET_KEY');
    }

    this.client = createClient(url, serviceKey);
  }

  /**
   * Add document with embedding
   */
  async addDocument(
    userId: string,
    title: string,
    content: string,
    embedding: number[],
    source: string,
    category: string,
    metadata?: Record<string, any>,
  ) {
    try {
      const { data, error } = await this.client.from('documents').insert({
        user_id: userId,
        title,
        content,
        embedding,
        source,
        category,
        metadata: metadata || {},
      });

      if (error) throw error;

      logger.info(`Document added: ${title} (user: ${userId})`);
      return data;
    } catch (error) {
      logger.error('Error adding document:', error);
      throw error;
    }
  }

  /**
   * Search documents by embedding similarity
   */
  async searchDocuments(
    userId: string,
    queryEmbedding: number[],
    limit: number = 5,
    category?: string,
    threshold: number = 0.5,
  ) {
    try {
      const { data, error } = await this.client.rpc('search_documents', {
        query_embedding: queryEmbedding,
        match_count: limit,
        filter_category: category,
        similarity_threshold: threshold,
        user_id: userId,
      });

      if (error) throw error;

      logger.info(`Documents searched: ${data?.length || 0} results`);
      return data || [];
    } catch (error) {
      logger.error('Error searching documents:', error);
      throw error;
    }
  }

  /**
   * Get documents by category
   */
  async getDocumentsByCategory(userId: string, category: string) {
    try {
      const { data, error } = await this.client
        .from('documents')
        .select()
        .eq('user_id', userId)
        .eq('category', category)
        .order('created_at', { ascending: false });

      if (error) throw error;

      return data || [];
    } catch (error) {
      logger.error('Error getting documents by category:', error);
      throw error;
    }
  }

  /**
   * Get all documents for user
   */
  async getAllDocuments(userId: string) {
    try {
      const { data, error } = await this.client
        .from('documents')
        .select()
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      if (error) throw error;

      return data || [];
    } catch (error) {
      logger.error('Error getting all documents:', error);
      throw error;
    }
  }

  /**
   * Delete document
   */
  async deleteDocument(userId: string, documentId: string) {
    try {
      const { error } = await this.client
        .from('documents')
        .delete()
        .eq('id', documentId)
        .eq('user_id', userId);

      if (error) throw error;

      logger.info(`Document deleted: ${documentId}`);
    } catch (error) {
      logger.error('Error deleting document:', error);
      throw error;
    }
  }

  /**
   * Save benchmark result
   */
  async saveBenchmark(
    userId: string,
    deviceName: string,
    modelId: string,
    metrics: {
      loadTimeMs: number;
      ttftMs: number;
      decodeSpeed: number;
      peakRamMb: number;
      batteryDrainPercentPerHour?: number;
      totalInferenceTimeMs?: number;
    },
    metadata?: Record<string, any>,
  ) {
    try {
      const { data, error } = await this.client.from('benchmarks').insert({
        user_id: userId,
        device_name: deviceName,
        model_id: modelId,
        load_time_ms: metrics.loadTimeMs,
        ttft_ms: metrics.ttftMs,
        decode_speed_tokens_per_sec: metrics.decodeSpeed,
        peak_ram_mb: metrics.peakRamMb,
        battery_drain_percent_per_hour: metrics.batteryDrainPercentPerHour,
        total_inference_time_ms: metrics.totalInferenceTimeMs,
        metadata: metadata || {},
      });

      if (error) throw error;

      logger.info(`Benchmark saved: ${deviceName} - ${modelId}`);
      return data;
    } catch (error) {
      logger.error('Error saving benchmark:', error);
      throw error;
    }
  }

  /**
   * Get benchmarks for device
   */
  async getBenchmarksForDevice(userId: string, deviceName: string) {
    try {
      const { data, error } = await this.client
        .from('benchmarks')
        .select()
        .eq('user_id', userId)
        .eq('device_name', deviceName)
        .order('created_at', { ascending: false });

      if (error) throw error;

      return data || [];
    } catch (error) {
      logger.error('Error getting benchmarks:', error);
      throw error;
    }
  }

  /**
   * Create session
   */
  async createSession(
    userId: string,
    title: string,
    context?: Record<string, any>,
  ) {
    try {
      const { data, error } = await this.client
        .from('sessions')
        .insert({
          user_id: userId,
          title,
          context: context || {},
        })
        .select();

      if (error) throw error;

      logger.info(`Session created: ${title}`);
      return data?.[0];
    } catch (error) {
      logger.error('Error creating session:', error);
      throw error;
    }
  }

  /**
   * Get session
   */
  async getSession(userId: string, sessionId: string) {
    try {
      const { data, error } = await this.client
        .from('sessions')
        .select()
        .eq('id', sessionId)
        .eq('user_id', userId)
        .maybeSingle();

      if (error) throw error;

      return data;
    } catch (error) {
      logger.error('Error getting session:', error);
      throw error;
    }
  }

  /**
   * Add message to session
   */
  async addMessage(
    userId: string,
    sessionId: string,
    role: 'user' | 'assistant',
    content: string,
    metadata?: Record<string, any>,
  ) {
    try {
      const { data, error } = await this.client.from('messages').insert({
        session_id: sessionId,
        user_id: userId,
        role,
        content,
        metadata: metadata || {},
      });

      if (error) throw error;

      return data;
    } catch (error) {
      logger.error('Error adding message:', error);
      throw error;
    }
  }

  /**
   * Get messages for session
   */
  async getSessionMessages(userId: string, sessionId: string) {
    try {
      const { data, error } = await this.client
        .from('messages')
        .select()
        .eq('session_id', sessionId)
        .eq('user_id', userId)
        .order('created_at', { ascending: true });

      if (error) throw error;

      return data || [];
    } catch (error) {
      logger.error('Error getting messages:', error);
      throw error;
    }
  }

  /**
   * Get user profile
   */
  async getUserProfile(userId: string) {
    try {
      const { data, error } = await this.client
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

      if (error) throw error;

      return data;
    } catch (error) {
      logger.error('Error getting user profile:', error);
      throw error;
    }
  }

  /**
   * Update user profile
   */
  async updateUserProfile(
    userId: string,
    updates: Record<string, any>,
  ) {
    try {
      const { data, error } = await this.client
        .from('user_profiles')
        .update(updates)
        .eq('id', userId)
        .select();

      if (error) throw error;

      logger.info(`User profile updated: ${userId}`);
      return data;
    } catch (error) {
      logger.error('Error updating user profile:', error);
      throw error;
    }
  }

  /**
   * Get database statistics
   */
  async getDatabaseStats(userId: string) {
    try {
      const [documents, sessions, benchmarks] = await Promise.all([
        this.client
          .from('documents')
          .select('id', { count: 'exact' })
          .eq('user_id', userId),
        this.client
          .from('sessions')
          .select('id', { count: 'exact' })
          .eq('user_id', userId),
        this.client
          .from('benchmarks')
          .select('id', { count: 'exact' })
          .eq('user_id', userId),
      ]);

      return {
        documents: documents.count || 0,
        sessions: sessions.count || 0,
        benchmarks: benchmarks.count || 0,
      };
    } catch (error) {
      logger.error('Error getting database stats:', error);
      throw error;
    }
  }
}

// Lazy singleton instance
let instance: SupabaseService | null = null;

export function getSupabaseService(): SupabaseService {
  if (!instance) {
    instance = new SupabaseService();
  }
  return instance;
}

// Export singleton (lazy initialized)
export const supabaseService = getSupabaseService();
