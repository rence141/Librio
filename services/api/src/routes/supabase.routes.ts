import express, { Request, Response } from 'express';
import { supabaseService } from '../services/supabase.service';
import { authenticateToken } from '../middleware/auth';
import { logger } from '../utils/logger';

const router = express.Router();

/**
 * Middleware to extract user ID from JWT
 */
const getUserId = (req: Request): string => {
  const userId = (req as any).user?.sub;
  if (!userId) {
    throw new Error('User not authenticated');
  }
  return userId;
};

// ============ DOCUMENTS ============

/**
 * POST /api/documents
 * Add a new document with embedding
 */
router.post('/documents', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = getUserId(req);
    const { title, content, embedding, source, category, metadata } = req.body;

    if (!title || !content || !embedding || !source || !category) {
      return res.status(400).json({
        error: 'Missing required fields: title, content, embedding, source, category',
      });
    }

    const result = await supabaseService.addDocument(
      userId,
      title,
      content,
      embedding,
      source,
      category,
      metadata,
    );

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    logger.error('Error adding document:', error);
    res.status(500).json({ error: 'Failed to add document' });
  }
});

/**
 * POST /api/documents/search
 * Search documents by embedding similarity
 */
router.post('/documents/search', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = getUserId(req);
    const { embedding, limit = 5, category, threshold = 0.5 } = req.body;

    if (!embedding || !Array.isArray(embedding)) {
      return res.status(400).json({
        error: 'Missing or invalid embedding',
      });
    }

    const results = await supabaseService.searchDocuments(
      userId,
      embedding,
      limit,
      category,
      threshold,
    );

    res.json({
      success: true,
      data: results,
      count: results.length,
    });
  } catch (error) {
    logger.error('Error searching documents:', error);
    res.status(500).json({ error: 'Failed to search documents' });
  }
});

/**
 * GET /api/documents
 * Get all documents for user
 */
router.get('/documents', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = getUserId(req);
    const category = req.query.category as string | undefined;

    let documents;
    if (category) {
      documents = await supabaseService.getDocumentsByCategory(userId, category);
    } else {
      documents = await supabaseService.getAllDocuments(userId);
    }

    res.json({
      success: true,
      data: documents,
      count: documents.length,
    });
  } catch (error) {
    logger.error('Error getting documents:', error);
    res.status(500).json({ error: 'Failed to get documents' });
  }
});

/**
 * DELETE /api/documents/:id
 * Delete a document
 */
router.delete('/documents/:id', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = getUserId(req);
    const { id } = req.params;

    await supabaseService.deleteDocument(userId, id);

    res.json({
      success: true,
      message: 'Document deleted',
    });
  } catch (error) {
    logger.error('Error deleting document:', error);
    res.status(500).json({ error: 'Failed to delete document' });
  }
});

// ============ BENCHMARKS ============

/**
 * POST /api/benchmarks
 * Save benchmark result
 */
router.post('/benchmarks', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = getUserId(req);
    const {
      deviceName,
      modelId,
      loadTimeMs,
      ttftMs,
      decodeSpeed,
      peakRamMb,
      batteryDrainPercentPerHour,
      totalInferenceTimeMs,
      metadata,
    } = req.body;

    if (!deviceName || !modelId || loadTimeMs === undefined || ttftMs === undefined) {
      return res.status(400).json({
        error: 'Missing required fields: deviceName, modelId, loadTimeMs, ttftMs',
      });
    }

    const result = await supabaseService.saveBenchmark(
      userId,
      deviceName,
      modelId,
      {
        loadTimeMs,
        ttftMs,
        decodeSpeed,
        peakRamMb,
        batteryDrainPercentPerHour,
        totalInferenceTimeMs,
      },
      metadata,
    );

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    logger.error('Error saving benchmark:', error);
    res.status(500).json({ error: 'Failed to save benchmark' });
  }
});

/**
 * GET /api/benchmarks
 * Get benchmarks
 */
router.get('/benchmarks', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = getUserId(req);
    const deviceName = req.query.device as string | undefined;

    let benchmarks;
    if (deviceName) {
      benchmarks = await supabaseService.getBenchmarksForDevice(userId, deviceName);
    } else {
      benchmarks = await supabaseService.getAllDocuments(userId); // TODO: Add getAllBenchmarks
    }

    res.json({
      success: true,
      data: benchmarks,
      count: benchmarks.length,
    });
  } catch (error) {
    logger.error('Error getting benchmarks:', error);
    res.status(500).json({ error: 'Failed to get benchmarks' });
  }
});

// ============ SESSIONS ============

/**
 * POST /api/sessions
 * Create a new session
 */
router.post('/sessions', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = getUserId(req);
    const { title, context } = req.body;

    if (!title) {
      return res.status(400).json({
        error: 'Missing required field: title',
      });
    }

    const result = await supabaseService.createSession(userId, title, context);

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    logger.error('Error creating session:', error);
    res.status(500).json({ error: 'Failed to create session' });
  }
});

/**
 * GET /api/sessions/:id
 * Get session
 */
router.get('/sessions/:id', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = getUserId(req);
    const { id } = req.params;

    const session = await supabaseService.getSession(userId, id);

    if (!session) {
      return res.status(404).json({ error: 'Session not found' });
    }

    res.json({
      success: true,
      data: session,
    });
  } catch (error) {
    logger.error('Error getting session:', error);
    res.status(500).json({ error: 'Failed to get session' });
  }
});

// ============ MESSAGES ============

/**
 * POST /api/sessions/:id/messages
 * Add message to session
 */
router.post('/sessions/:id/messages', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = getUserId(req);
    const { id } = req.params;
    const { role, content, metadata } = req.body;

    if (!role || !content) {
      return res.status(400).json({
        error: 'Missing required fields: role, content',
      });
    }

    const result = await supabaseService.addMessage(
      userId,
      id,
      role,
      content,
      metadata,
    );

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    logger.error('Error adding message:', error);
    res.status(500).json({ error: 'Failed to add message' });
  }
});

/**
 * GET /api/sessions/:id/messages
 * Get messages for session
 */
router.get('/sessions/:id/messages', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = getUserId(req);
    const { id } = req.params;

    const messages = await supabaseService.getSessionMessages(userId, id);

    res.json({
      success: true,
      data: messages,
      count: messages.length,
    });
  } catch (error) {
    logger.error('Error getting messages:', error);
    res.status(500).json({ error: 'Failed to get messages' });
  }
});

// ============ USER PROFILE ============

/**
 * GET /api/profile
 * Get user profile
 */
router.get('/profile', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = getUserId(req);
    const profile = await supabaseService.getUserProfile(userId);

    res.json({
      success: true,
      data: profile,
    });
  } catch (error) {
    logger.error('Error getting profile:', error);
    res.status(500).json({ error: 'Failed to get profile' });
  }
});

/**
 * PUT /api/profile
 * Update user profile
 */
router.put('/profile', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = getUserId(req);
    const updates = req.body;

    const result = await supabaseService.updateUserProfile(userId, updates);

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    logger.error('Error updating profile:', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

// ============ STATS ============

/**
 * GET /api/stats
 * Get database statistics
 */
router.get('/stats', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = getUserId(req);
    const stats = await supabaseService.getDatabaseStats(userId);

    res.json({
      success: true,
      data: stats,
    });
  } catch (error) {
    logger.error('Error getting stats:', error);
    res.status(500).json({ error: 'Failed to get stats' });
  }
});

export default router;
