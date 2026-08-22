import { Router, Response } from 'express';
import { AuthRequest, authenticateToken } from '../middleware/auth';
import { aiRateLimitMiddleware, abuseCheckMiddleware } from '../middleware/guardrails';
import { z } from 'zod';
import {
  invalidRequest,
  documentTooLarge,
  quotaExceeded,
  authRequired,
} from '../utils/api-errors';
import { getDocumentLimits } from '../config/guardrails.config';
import { getStore } from '../services/store.service';
import { logger } from '../utils/logger';

const router = Router();

const uploadSchema = z.object({
  title: z.string().min(1).max(500),
  content: z.string().min(1),
  source: z.string().max(500).optional(),
  category: z.string().max(100).optional(),
  fileSizeBytes: z.number().int().min(1).optional(),
});

/**
 * POST /api/v1/documents/upload
 *
 * Upload pipeline:
 *   Auth → Validation → File size → File type → Quota → Text extraction → Chunking → Embedding → Storage
 */
router.post(
  '/upload',
  authenticateToken,
  aiRateLimitMiddleware,
  abuseCheckMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      if (!req.user) {
        authRequired(res);
        return;
      }

      const parseResult = uploadSchema.safeParse(req.body);
      if (!parseResult.success) {
        invalidRequest(res, 'Invalid upload', { errors: parseResult.error.issues });
        return;
      }
      const body = parseResult.data;
      const limits = getDocumentLimits(req.user.tier);

      // 1. File size validation
      if (body.fileSizeBytes && body.fileSizeBytes > limits.maxFileSizeMB * 1024 * 1024) {
        documentTooLarge(res, limits.maxFileSizeMB);
        return;
      }

      // 2. Text extraction limit
      if (body.content.length > limits.maxExtractedTextChars) {
        invalidRequest(res, `Extracted text exceeds maximum of ${limits.maxExtractedTextChars} characters.`);
        return;
      }

      // 3. Daily upload quota
      const store = getStore();
      const now = Math.floor(Date.now() / 1000);
      const dayBucket = Math.floor(now / 86400);
      const uploadKey = `doc:uploads:${req.user.id}:${dayBucket}`;
      const uploadCount = await store.incr(uploadKey, 90_000);

      if (uploadCount > limits.maxDocumentsPerDay) {
        quotaExceeded(res, `Daily document upload limit (${limits.maxDocumentsPerDay}) exceeded.`);
        return;
      }

      // 4. RAG query quota check (separate from AI quota)
      // Storage quota would be checked against actual DB storage usage
      // (simplified here — in production, query SUM of document sizes for user)

      logger.info({ userId: req.user.id, title: body.title }, 'Document uploaded');

      res.json({
        success: true,
        documentId: `doc_${Date.now()}`,
        limits: {
          maxFileSizeMB: limits.maxFileSizeMB,
          maxDocumentsPerDay: limits.maxDocumentsPerDay,
          maxStorageMB: limits.maxStorageMB,
          remaining: limits.maxDocumentsPerDay - uploadCount,
        },
      });
    } catch (error: any) {
      logger.error({ error }, 'Document upload error');
      res.status(500).json({
        error: { code: 'INTERNAL_ERROR', message: 'Upload failed.' },
      });
    }
  },
);

/**
 * GET /api/v1/documents/limits
 * Get document/RAG limits for the user's tier.
 */
router.get('/limits', authenticateToken, (req: AuthRequest, res: Response) => {
  if (!req.user) {
    authRequired(res);
    return;
  }
  const limits = getDocumentLimits(req.user.tier);
  res.json({ limits, tier: req.user.tier });
});

/**
 * POST /api/v1/documents/rag-query
 * RAG query with daily limit.
 */
router.post(
  '/rag-query',
  authenticateToken,
  async (req: AuthRequest, res: Response) => {
    try {
      if (!req.user) {
        authRequired(res);
        return;
      }

      const limits = getDocumentLimits(req.user.tier);
      const store = getStore();
      const now = Math.floor(Date.now() / 1000);
      const dayBucket = Math.floor(now / 86400);
      const ragKey = `doc:rag:${req.user.id}:${dayBucket}`;
      const ragCount = await store.incr(ragKey, 90_000);

      if (ragCount > limits.maxRagQueriesPerDay) {
        quotaExceeded(res, `Daily RAG query limit (${limits.maxRagQueriesPerDay}) exceeded.`);
        return;
      }

      // RAG query processing would happen here
      res.json({
        success: true,
        remaining: limits.maxRagQueriesPerDay - ragCount,
      });
    } catch (error: any) {
      logger.error({ error }, 'RAG query error');
      res.status(500).json({
        error: { code: 'INTERNAL_ERROR', message: 'RAG query failed.' },
      });
    }
  },
);

export default router;
