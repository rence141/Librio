import { logger } from '../utils/logger';

export type ModelType = 'local' | 'cloud' | 'hybrid';

export interface ModelRouterConfig {
  localModel: {
    name: string;
    maxTokens: number;
    timeout: number; // ms
  };
  cloudModel: {
    provider: 'openai' | 'anthropic' | 'custom';
    apiKey: string;
    model: string;
    maxTokens: number;
  };
  fallbackStrategy: 'local' | 'cloud' | 'hybrid';
  cacheEnabled: boolean;
  cacheTTL: number; // seconds
}

export interface InferenceRequest {
  prompt: string;
  maxTokens?: number;
  temperature?: number;
  userId?: string;
}

export interface InferenceResponse {
  text: string;
  model: ModelType;
  tokensUsed: number;
  latency: number; // ms
  cached: boolean;
}

/**
 * Model router for intelligent local/cloud model selection
 */
export class ModelRouterService {
  private isOnline: boolean = true;
  private responseCache: Map<string, { response: InferenceResponse; expiry: number }> =
    new Map();
  private lastHealthCheck: number = 0;
  private healthCheckInterval: number = 30000; // 30 seconds

  constructor(private config: ModelRouterConfig) {
    this.startHealthCheck();
  }

  /**
   * Route inference request to appropriate model
   */
  async route(request: InferenceRequest): Promise<InferenceResponse> {
    try {
      // Check cache
      if (this.config.cacheEnabled) {
        const cached = this.getFromCache(request.prompt);
        if (cached) {
          logger.info('Cache hit for prompt');
          return { ...cached, cached: true };
        }
      }

      // Determine model type
      const modelType = this.selectModel();

      // Route to appropriate model
      let response: InferenceResponse;

      switch (modelType) {
        case 'local':
          response = await this.inferenceLocal(request);
          break;

        case 'cloud':
          response = await this.inferenceCloud(request);
          break;

        case 'hybrid':
          response = await this.inferenceHybrid(request);
          break;

        default:
          throw new Error(`Unknown model type: ${modelType}`);
      }

      // Cache response
      if (this.config.cacheEnabled) {
        this.setInCache(request.prompt, response);
      }

      return response;
    } catch (error) {
      logger.error('Error routing inference:', error);
      throw error;
    }
  }

  /**
   * Select model based on connectivity and config
   */
  private selectModel(): ModelType {
    if (!this.isOnline) {
      logger.info('Offline: using local model');
      return 'local';
    }

    return this.config.fallbackStrategy;
  }

  /**
   * Inference with local model
   */
  private async inferenceLocal(request: InferenceRequest): Promise<InferenceResponse> {
    try {
      const startTime = Date.now();

      // Simulate local inference
      // In production, this would call the actual local LLM
      const response = await this.simulateLocalInference(request);

      const latency = Date.now() - startTime;

      logger.info(`Local inference completed in ${latency}ms`);

      return {
        text: response,
        model: 'local',
        tokensUsed: Math.ceil(response.length / 4), // Rough estimate
        latency,
        cached: false,
      };
    } catch (error) {
      logger.error('Local inference error:', error);
      throw error;
    }
  }

  /**
   * Inference with cloud model
   */
  private async inferenceCloud(request: InferenceRequest): Promise<InferenceResponse> {
    try {
      const startTime = Date.now();

      // Call cloud model API
      const response = await this.callCloudModel(request);

      const latency = Date.now() - startTime;

      logger.info(`Cloud inference completed in ${latency}ms`);

      return {
        text: response.text,
        model: 'cloud',
        tokensUsed: response.tokensUsed,
        latency,
        cached: false,
      };
    } catch (error) {
      logger.error('Cloud inference error:', error);

      // Fallback to local model
      logger.warn('Falling back to local model');
      return this.inferenceLocal(request);
    }
  }

  /**
   * Hybrid inference (local first, cloud for quality)
   */
  private async inferenceHybrid(request: InferenceRequest): Promise<InferenceResponse> {
    try {
      // Get local response quickly
      const localResponse = await this.inferenceLocal(request);

      // If online and time permits, also get cloud response
      if (this.isOnline && localResponse.latency < 1000) {
        try {
          const cloudResponse = await this.inferenceCloud(request);

          // Return cloud response (better quality)
          logger.info('Hybrid: using cloud response');
          return cloudResponse;
        } catch (error) {
          // Fall back to local response
          logger.warn('Hybrid: cloud failed, using local response');
          return localResponse;
        }
      }

      return localResponse;
    } catch (error) {
      logger.error('Hybrid inference error:', error);
      throw error;
    }
  }

  /**
   * Simulate local inference (placeholder)
   */
  private async simulateLocalInference(request: InferenceRequest): Promise<string> {
    // In production, this would call the actual local LLM via llamadart
    return `[Local Response] ${request.prompt.substring(0, 50)}...`;
  }

  /**
   * Call cloud model API
   */
  private async callCloudModel(
    request: InferenceRequest,
  ): Promise<{ text: string; tokensUsed: number }> {
    // In production, this would call OpenAI, Anthropic, or custom API
    return {
      text: `[Cloud Response] ${request.prompt.substring(0, 50)}...`,
      tokensUsed: 100,
    };
  }

  /**
   * Check connectivity
   */
  async checkConnectivity(): Promise<boolean> {
    try {
      // In production, this would check actual API connectivity
      const isOnline = Math.random() > 0.1; // 90% online for testing
      this.isOnline = isOnline;
      return isOnline;
    } catch (error) {
      logger.error('Connectivity check error:', error);
      this.isOnline = false;
      return false;
    }
  }

  /**
   * Start periodic health check
   */
  private startHealthCheck(): void {
    setInterval(async () => {
      try {
        await this.checkConnectivity();
        logger.debug(`Health check: ${this.isOnline ? 'online' : 'offline'}`);
      } catch (error) {
        logger.error('Health check error:', error);
      }
    }, this.healthCheckInterval);
  }

  /**
   * Get response from cache
   */
  private getFromCache(prompt: string): InferenceResponse | null {
    const key = this.hashPrompt(prompt);
    const cached = this.responseCache.get(key);

    if (!cached) return null;

    if (cached.expiry < Date.now()) {
      this.responseCache.delete(key);
      return null;
    }

    return cached.response;
  }

  /**
   * Set response in cache
   */
  private setInCache(prompt: string, response: InferenceResponse): void {
    const key = this.hashPrompt(prompt);
    const expiry = Date.now() + this.config.cacheTTL * 1000;

    this.responseCache.set(key, { response, expiry });

    // Cleanup old entries
    if (this.responseCache.size > 1000) {
      const now = Date.now();
      for (const [key, value] of this.responseCache.entries()) {
        if (value.expiry < now) {
          this.responseCache.delete(key);
        }
      }
    }
  }

  /**
   * Hash prompt for cache key
   */
  private hashPrompt(prompt: string): string {
    // Simple hash function (in production, use crypto.createHash)
    let hash = 0;
    for (let i = 0; i < prompt.length; i++) {
      const char = prompt.charCodeAt(i);
      hash = (hash << 5) - hash + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.toString();
  }

  /**
   * Get router status
   */
  getStatus(): {
    isOnline: boolean;
    cacheSize: number;
    fallbackStrategy: string;
  } {
    return {
      isOnline: this.isOnline,
      cacheSize: this.responseCache.size,
      fallbackStrategy: this.config.fallbackStrategy,
    };
  }

  /**
   * Clear cache
   */
  clearCache(): void {
    this.responseCache.clear();
    logger.info('Model router cache cleared');
  }
}
