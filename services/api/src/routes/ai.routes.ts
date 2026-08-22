import { Router, Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { z } from 'zod';
import crypto from 'crypto';
import {
  authenticateToken,
} from '../middleware/auth';
import {
  aiRateLimitMiddleware,
  abuseCheckMiddleware,
  concurrencyMiddleware,
  inputSafetyMiddleware,
} from '../middleware/guardrails';
import { getModelRouter } from '../services/model-router.service';
import { getProviderService } from '../services/provider.service';
import { getQuotaService } from '../services/quota.service';
import { getAbuseDetectionService } from '../services/abuse-detection.service';
import { getSafetyService } from '../services/safety.service';
import { getBillingService } from '../services/billing.service';
import { getStore } from '../services/store.service';
import { UsageService } from '../services/usage.service';
import {
  invalidRequest,
  quotaExceeded,
  tokenLimitExceeded,
  insufficientCredits,
  globalLimitReached,
  contentRestricted,
  authRequired,
} from '../utils/api-errors';
import { getTierLimits, IDEMPOTENCY_TTL_SEC } from '../config/guardrails.config';
import { logger } from '../utils/logger';
import { getDbPool } from '../db/pool';

const router = Router();

// Request validation schema
const generateSchema = z.object({
  prompt: z.string().min(1).max(100_000),
  capability: z.enum(['fast', 'advanced', 'premium', 'local']).optional(),
  maxOutputTokens: z.number().int().min(1).max(32_000).optional(),
  temperature: z.number().min(0).max(2).optional(),
  systemPrompt: z.string().max(10_000).optional(),
  requestId: z.string().max(100).optional(), // For idempotency
});

/**
 * POST /api/v1/ai/generate
 *
 * Full request pipeline:
 *   Auth → Validation → Safety → RateLimit → Quota → Concurrency → ModelRouter → Provider → OutputSafety → UsageRecord → Response
 */
router.post(
  '/generate',
  authenticateToken,
  inputSafetyMiddleware,
  aiRateLimitMiddleware,
  abuseCheckMiddleware,
  concurrencyMiddleware,
  async (req: AuthRequest, res: Response, _next: NextFunction) => {
    const releaseConcurrency = (res as any).releaseConcurrency;

    try {
      if (!req.user) {
        authRequired(res);
        return;
      }

      // 1. Validate request
      const parseResult = generateSchema.safeParse(req.body);
      if (!parseResult.success) {
        invalidRequest(res, 'Invalid request', { errors: parseResult.error.issues });
        return;
      }
      const body = parseResult.data;

      // 2. Idempotency check — prevent duplicate charges
      if (body.requestId) {
        const store = getStore();
        const idempotencyKey = `idem:${req.user.id}:${body.requestId}`;
        const existing = await store.getString(idempotencyKey);
        if (existing) {
          logger.info({ userId: req.user.id, requestId: body.requestId }, 'Idempotency: returning cached result');
          res.json({ text: existing, cached: true });
          return;
        }
      }

      // 3. Model routing (server decides)
      const modelRouter = getModelRouter();
      const routerDecision = modelRouter.selectModel({
        prompt: body.prompt,
        capability: body.capability,
        maxOutputTokens: body.maxOutputTokens,
        temperature: body.temperature,
        systemPrompt: body.systemPrompt,
        userId: req.user.id,
        tier: req.user.tier,
      });

      const model = routerDecision.model;

      // 4. Local model — no cloud quotas, no spending checks
      if (model.provider === 'local') {
        // Local inference is unrestricted (runs on device)
        // The backend simply tells the client to use local model
        res.json({
          text: '',
          model: model.id,
          provider: 'local',
          useLocalModel: true,
          message: 'Use local model for this request.',
        });
        releaseConcurrency?.();
        return;
      }

      // 5. Cloud model — full guardrail pipeline

      // 5a. Global spending check (kill switch)
      const billingService = getBillingService(getDbPool());
      const spendingStatus = await billingService.checkCloudAvailable();
      if (!spendingStatus.cloudEnabled) {
        globalLimitReached(res);
        releaseConcurrency?.();
        return;
      }

      // 5b. Estimate input tokens (rough: 1 token ≈ 4 chars)
      const estimatedInputTokens = Math.ceil(body.prompt.length / 4);
      const tierLimits = getTierLimits(req.user.tier);

      if (estimatedInputTokens > tierLimits.maxInputTokens) {
        tokenLimitExceeded(res, `Input exceeds maximum of ${tierLimits.maxInputTokens} tokens for your plan.`);
        releaseConcurrency?.();
        return;
      }

      // 5c. Check token budget
      const quotaService = getQuotaService();
      const quotaStatus = await quotaService.checkTokenBudget(
        req.user.id,
        req.user.tier,
        estimatedInputTokens,
        routerDecision.maxOutputTokens,
        req.user.isNewAccount,
      );

      if (!quotaStatus.allowed) {
        quotaExceeded(res, `Daily token limit exceeded. You have ${quotaStatus.remainingTokens} tokens remaining.`, quotaStatus.retryAfter);
        releaseConcurrency?.();
        return;
      }

      // 5d. Check credits (cost-multiplier based)
      const creditStatus = await quotaService.checkCredits(
        req.user.id,
        req.user.tier,
        model.costMultiplier,
        req.user.isNewAccount,
      );

      if (!creditStatus.allowed) {
        insufficientCredits(res);
        releaseConcurrency?.();
        return;
      }

      // 6. Call provider
      const providerService = getProviderService();
      const providerResponse = await providerService.call(model, {
        prompt: body.prompt,
        maxTokens: routerDecision.maxOutputTokens,
        temperature: body.temperature,
        systemPrompt: body.systemPrompt,
      });

      // 7. Output safety check
      const safetyService = getSafetyService();
      const outputSafety = safetyService.checkOutput(providerResponse.text);
      if (!outputSafety.safe) {
        contentRestricted(res, outputSafety.reason ?? 'Output filtered');
        releaseConcurrency?.();
        return;
      }

      // 8. Consume quota
      await quotaService.consumeTokens(
        req.user.id,
        providerResponse.inputTokens,
        providerResponse.outputTokens,
        model.costMultiplier,
      );

      // 9. Track for abuse detection
      const abuseService = getAbuseDetectionService();
      const promptHash = crypto.createHash('sha256').update(body.prompt).digest('hex').slice(0, 16);
      await abuseService.trackRequest(req.user.id, req.ip || 'unknown', promptHash, providerResponse.inputTokens + providerResponse.outputTokens);

      // 10. Record usage in PostgreSQL
      const requestId = body.requestId || `req_${Date.now()}_${Math.random().toString(36).slice(2, 11)}`;
      const usageService = new UsageService(getDbPool());
      await usageService.recordUsage({
        userId: req.user.id,
        modelId: model.id,
        provider: model.provider,
        requestId,
        inputTokens: providerResponse.inputTokens,
        outputTokens: providerResponse.outputTokens,
        totalTokens: providerResponse.inputTokens + providerResponse.outputTokens,
        creditsConsumed: model.costMultiplier,
        latencyMs: 0, // TODO: measure
        success: true,
        timestamp: new Date(),
      });

      // 11. Store idempotency result
      if (body.requestId) {
        const store = getStore();
        await store.set(`idem:${req.user.id}:${body.requestId}`, providerResponse.text, IDEMPOTENCY_TTL_SEC);
      }

      // 12. Release concurrency
      releaseConcurrency?.();

      // 13. Response
      res.json({
        text: providerResponse.text,
        model: model.id,
        provider: model.provider,
        usage: {
          inputTokens: providerResponse.inputTokens,
          outputTokens: providerResponse.outputTokens,
          totalTokens: providerResponse.inputTokens + providerResponse.outputTokens,
          creditsConsumed: model.costMultiplier,
        },
        requestId,
      });
    } catch (error: any) {
      logger.error({ error }, 'AI generate error');
      releaseConcurrency?.();
      res.status(500).json({
        error: { code: 'INTERNAL_ERROR', message: 'An error occurred during generation.' },
      });
    }
  },
);

/**
 * GET /api/v1/ai/models
 * List available models for the user's tier (for client UX).
 */
router.get('/models', authenticateToken, (req: AuthRequest, res: Response) => {
  if (!req.user) {
    authRequired(res);
    return;
  }
  const modelRouter = getModelRouter();
  const models = modelRouter.listAvailableModels(req.user.tier);
  res.json({ models });
});

/**
 * GET /api/v1/ai/usage
 * Get current usage for the authenticated user.
 */
router.get('/usage', authenticateToken, async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    authRequired(res);
    return;
  }
  const quotaService = getQuotaService();
  const usage = await quotaService.getUsage(req.user.id);
  const tierLimits = getTierLimits(req.user.tier);
  res.json({
    usage,
    limits: tierLimits,
    tier: req.user.tier,
  });
});

/**
 * GET /api/v1/ai/status
 * Cloud AI availability status (for client to show offline/online).
 */
router.get('/status', authenticateToken, async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    authRequired(res);
    return;
  }
  const billingService = getBillingService(getDbPool());
  const spendingStatus = await billingService.checkCloudAvailable();
  res.json({
    cloudEnabled: spendingStatus.cloudEnabled,
    reason: spendingStatus.reason,
    localAvailable: true, // Local AI is always available
  });
});

export default router;
