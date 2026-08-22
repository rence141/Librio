import { logger } from '../utils/logger';
import {
  ModelMeta,
  SubscriptionTier,
  findModel,
  getAllowedModels,
  getTierLimits,
} from '../config/guardrails.config';

export interface RouterRequest {
  prompt: string;
  /** Client requests a capability, NOT a specific model */
  capability?: 'fast' | 'advanced' | 'premium' | 'local';
  maxOutputTokens?: number;
  temperature?: number;
  systemPrompt?: string;
  userId: string;
  tier: SubscriptionTier;
}

export interface RouterDecision {
  model: ModelMeta;
  maxInputTokens: number;
  maxOutputTokens: number;
  reason: string;
}

/**
 * Server-controlled model router.
 *
 * The client requests a CAPABILITY (fast, advanced, etc.), not a specific model.
 * The backend validates entitlement and determines which model the user can access.
 *
 * The client must NOT be able to bypass restrictions by directly specifying
 * an unrestricted provider/model.
 */
export class ModelRouterService {
  /**
   * Select the appropriate model for a request.
   * The server decides — never the client.
   */
  selectModel(request: RouterRequest): RouterDecision {
    const tierLimits = getTierLimits(request.tier);
    const allowedModels = getAllowedModels(request.tier);

    if (allowedModels.length === 0) {
      throw new Error('No models available for this tier');
    }

    // Map capability to model
    let targetModel: ModelMeta | undefined;

    switch (request.capability) {
      case 'local':
        targetModel = allowedModels.find((m) => m.provider === 'local');
        break;
      case 'fast':
        targetModel = allowedModels.find((m) => m.costMultiplier === 1);
        break;
      case 'advanced':
        targetModel = allowedModels.find((m) => m.costMultiplier === 5);
        break;
      case 'premium':
        targetModel = allowedModels.find((m) => m.costMultiplier === 20);
        break;
      default:
        // Default: cheapest available cloud model
        targetModel = allowedModels
          .filter((m) => m.provider !== 'local')
          .sort((a, b) => a.costMultiplier - b.costMultiplier)[0];
    }

    if (!targetModel) {
      // Fallback to local or cheapest allowed
      targetModel = allowedModels[0];
      logger.warn({ requested: request.capability, fallback: targetModel.id }, 'Model router: requested capability unavailable, falling back');
    }

    // Clamp max output tokens to tier and model limits
    const maxOutputTokens = Math.min(
      request.maxOutputTokens ?? tierLimits.maxOutputTokens,
      targetModel.maxOutputTokens,
      tierLimits.maxOutputTokens,
    );

    const maxInputTokens = Math.min(
      targetModel.maxInputTokens,
      tierLimits.maxInputTokens,
    );

    return {
      model: targetModel,
      maxInputTokens,
      maxOutputTokens,
      reason: `Selected ${targetModel.displayName} for ${request.tier} tier`,
    };
  }

  /**
   * Validate that a specific model ID is allowed for a user.
   */
  validateModelAccess(modelId: string, tier: SubscriptionTier): { allowed: boolean; model?: ModelMeta } {
    const model = findModel(modelId);
    if (!model) {
      return { allowed: false };
    }
    if (!model.allowedTiers.includes(tier)) {
      return { allowed: false };
    }
    return { allowed: true, model };
  }

  /**
   * List models available for a tier (for client UX display).
   */
  listAvailableModels(tier: SubscriptionTier): ModelMeta[] {
    return getAllowedModels(tier);
  }
}

/** Singleton. */
let instance: ModelRouterService | null = null;
export function getModelRouter(): ModelRouterService {
  if (!instance) instance = new ModelRouterService();
  return instance;
}
