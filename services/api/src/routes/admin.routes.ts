import express, { Request, Response } from 'express';
import { AdminService } from '../services/admin.service';
import { supabaseService } from '../services/supabase.service';
import { authenticateToken } from '../middleware/auth';
import { logger } from '../utils/logger';

const router = express.Router();
const adminService = new AdminService(supabaseService['client']);

/**
 * Middleware to verify admin access
 */
const requireAdmin = async (req: Request, res: Response, next: Function) => {
  try {
    const userId = (req as any).user?.sub;
    if (!userId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    // Check if user is admin (placeholder - implement proper admin check)
    const profile = await supabaseService.getUserProfile(userId);
    if (!profile || profile.subscription_tier !== 'enterprise') {
      return res.status(403).json({ error: 'Admin access required' });
    }

    next();
  } catch (error) {
    logger.error('Admin verification error:', error);
    res.status(500).json({ error: 'Admin verification failed' });
  }
};

// ============ USER MANAGEMENT ============

/**
 * GET /admin/users
 * Get all users with stats
 */
router.get('/users', authenticateToken, requireAdmin, async (req: Request, res: Response) => {
  try {
    const limit = parseInt(req.query.limit as string) || 100;
    const offset = parseInt(req.query.offset as string) || 0;

    const users = await adminService.getAllUsers(limit, offset);

    res.json({
      success: true,
      data: users,
      count: users.length,
    });
  } catch (error) {
    logger.error('Error getting users:', error);
    res.status(500).json({ error: 'Failed to get users' });
  }
});

/**
 * GET /admin/users/:id
 * Get user stats
 */
router.get('/users/:id', authenticateToken, requireAdmin, async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const stats = await adminService.getUserStats(id);

    res.json({
      success: true,
      data: stats,
    });
  } catch (error) {
    logger.error('Error getting user stats:', error);
    res.status(500).json({ error: 'Failed to get user stats' });
  }
});

/**
 * PUT /admin/users/:id/subscription
 * Update user subscription tier
 */
router.put(
  '/users/:id/subscription',
  authenticateToken,
  requireAdmin,
  async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const { tier } = req.body;

      if (!['free', 'pro', 'enterprise'].includes(tier)) {
        return res.status(400).json({
          error: 'Invalid subscription tier',
        });
      }

      await adminService.updateUserSubscription(id, tier);

      res.json({
        success: true,
        message: `User subscription updated to ${tier}`,
      });
    } catch (error) {
      logger.error('Error updating user subscription:', error);
      res.status(500).json({ error: 'Failed to update subscription' });
    }
  },
);

/**
 * DELETE /admin/users/:id
 * Delete user and all data
 */
router.delete('/users/:id', authenticateToken, requireAdmin, async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    await adminService.deleteUser(id);

    res.json({
      success: true,
      message: 'User deleted',
    });
  } catch (error) {
    logger.error('Error deleting user:', error);
    res.status(500).json({ error: 'Failed to delete user' });
  }
});

// ============ CONTENT MANAGEMENT ============

/**
 * GET /admin/materials
 * Get all materials
 */
router.get('/materials', authenticateToken, requireAdmin, async (req: Request, res: Response) => {
  try {
    const limit = parseInt(req.query.limit as string) || 100;
    const offset = parseInt(req.query.offset as string) || 0;

    const materials = await adminService.getAllMaterials(limit, offset);

    res.json({
      success: true,
      data: materials,
      count: materials.length,
    });
  } catch (error) {
    logger.error('Error getting materials:', error);
    res.status(500).json({ error: 'Failed to get materials' });
  }
});

/**
 * GET /admin/materials/subject/:subject
 * Get materials by subject
 */
router.get(
  '/materials/subject/:subject',
  authenticateToken,
  requireAdmin,
  async (req: Request, res: Response) => {
    try {
      const { subject } = req.params;

      const materials = await adminService.getMaterialsBySubject(subject);

      res.json({
        success: true,
        data: materials,
        count: materials.length,
      });
    } catch (error) {
      logger.error('Error getting materials by subject:', error);
      res.status(500).json({ error: 'Failed to get materials' });
    }
  },
);

/**
 * GET /admin/materials/featured
 * Get featured materials
 */
router.get(
  '/materials/featured',
  authenticateToken,
  requireAdmin,
  async (req: Request, res: Response) => {
    try {
      const materials = await adminService.getFeaturedMaterials();

      res.json({
        success: true,
        data: materials,
        count: materials.length,
      });
    } catch (error) {
      logger.error('Error getting featured materials:', error);
      res.status(500).json({ error: 'Failed to get featured materials' });
    }
  },
);

/**
 * PUT /admin/materials/:id/featured
 * Feature/unfeature material
 */
router.put(
  '/materials/:id/featured',
  authenticateToken,
  requireAdmin,
  async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const { featured } = req.body;

      if (typeof featured !== 'boolean') {
        return res.status(400).json({
          error: 'Featured must be a boolean',
        });
      }

      await adminService.setMaterialFeatured(id, featured);

      res.json({
        success: true,
        message: `Material ${featured ? 'featured' : 'unfeatured'}`,
      });
    } catch (error) {
      logger.error('Error setting material featured:', error);
      res.status(500).json({ error: 'Failed to update material' });
    }
  },
);

/**
 * DELETE /admin/materials/:id
 * Delete material
 */
router.delete(
  '/materials/:id',
  authenticateToken,
  requireAdmin,
  async (req: Request, res: Response) => {
    try {
      const { id } = req.params;

      await adminService.deleteMaterial(id);

      res.json({
        success: true,
        message: 'Material deleted',
      });
    } catch (error) {
      logger.error('Error deleting material:', error);
      res.status(500).json({ error: 'Failed to delete material' });
    }
  },
);

// ============ ANALYTICS ============

/**
 * GET /admin/analytics
 * Get system analytics
 */
router.get('/analytics', authenticateToken, requireAdmin, async (req: Request, res: Response) => {
  try {
    const analytics = await adminService.getAnalytics();

    res.json({
      success: true,
      data: analytics,
    });
  } catch (error) {
    logger.error('Error getting analytics:', error);
    res.status(500).json({ error: 'Failed to get analytics' });
  }
});

/**
 * GET /admin/analytics/user/:id
 * Get user analytics
 */
router.get(
  '/analytics/user/:id',
  authenticateToken,
  requireAdmin,
  async (req: Request, res: Response) => {
    try {
      const { id } = req.params;

      const analytics = await adminService.getUserAnalytics(id);

      res.json({
        success: true,
        data: analytics,
      });
    } catch (error) {
      logger.error('Error getting user analytics:', error);
      res.status(500).json({ error: 'Failed to get user analytics' });
    }
  },
);

// ============ SYSTEM MONITORING ============

/**
 * GET /admin/health
 * Get system health
 */
router.get('/health', authenticateToken, requireAdmin, async (req: Request, res: Response) => {
  try {
    const health = await adminService.getSystemHealth();

    res.json({
      success: true,
      data: health,
    });
  } catch (error) {
    logger.error('Error getting system health:', error);
    res.status(500).json({ error: 'Failed to get system health' });
  }
});

/**
 * GET /admin/sync-queue
 * Get sync queue status
 */
router.get(
  '/sync-queue',
  authenticateToken,
  requireAdmin,
  async (req: Request, res: Response) => {
    try {
      const status = await adminService.getSyncQueueStatus();

      res.json({
        success: true,
        data: status,
      });
    } catch (error) {
      logger.error('Error getting sync queue status:', error);
      res.status(500).json({ error: 'Failed to get sync queue status' });
    }
  },
);

/**
 * GET /admin/sync-queue/failed
 * Get failed syncs
 */
router.get(
  '/sync-queue/failed',
  authenticateToken,
  requireAdmin,
  async (req: Request, res: Response) => {
    try {
      const limit = parseInt(req.query.limit as string) || 50;

      const failed = await adminService.getFailedSyncs(limit);

      res.json({
        success: true,
        data: failed,
        count: failed.length,
      });
    } catch (error) {
      logger.error('Error getting failed syncs:', error);
      res.status(500).json({ error: 'Failed to get failed syncs' });
    }
  },
);

/**
 * POST /admin/sync-queue/:id/retry
 * Retry failed sync
 */
router.post(
  '/sync-queue/:id/retry',
  authenticateToken,
  requireAdmin,
  async (req: Request, res: Response) => {
    try {
      const { id } = req.params;

      await adminService.retrySyncOperation(id);

      res.json({
        success: true,
        message: 'Sync operation retried',
      });
    } catch (error) {
      logger.error('Error retrying sync operation:', error);
      res.status(500).json({ error: 'Failed to retry sync operation' });
    }
  },
);

export default router;
