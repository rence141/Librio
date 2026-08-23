// Load environment variables FIRST before any other imports
import dotenv from 'dotenv';
dotenv.config();

import express, { Request, Response, NextFunction } from 'express';
import pinoHttp from 'pino-http';
import cors from 'cors';

// Import routes (after dotenv.config())
import authRoutes from './routes/auth.routes';
import supabaseRoutes from './routes/supabase.routes';
import adminRoutes from './routes/admin.routes';
import aiRoutes from './routes/ai.routes';
import documentRoutes from './routes/documents.routes';

const app = express();
const port = process.env.PORT || 3000;
const nodeEnv = process.env.NODE_ENV || 'development';

// Logging middleware
app.use(pinoHttp());

// CORS middleware - support Railway and custom origins via env
const corsOrigins = process.env.CORS_ORIGINS
  ? process.env.CORS_ORIGINS.split(',').map((o) => o.trim())
  : [
      'http://localhost:3000',
      'http://localhost:8080',
      'http://localhost:8081',
      'http://127.0.0.1:3000',
      'http://127.0.0.1:8080',
      'http://127.0.0.1:8081',
    ];
app.use(cors({
  origin: corsOrigins,
  credentials: true,
}));

// JSON parsing — limit body size to prevent abuse
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging middleware
app.use((req: Request, res: Response, next: NextFunction) => {
  console.log(`${req.method} ${req.path}`);
  next();
});

// Health check endpoint
app.get('/health', (_req: Request, res: Response) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    environment: nodeEnv,
    version: '1.0.0',
  });
});

// API status endpoint
app.get('/api/v1/status', (_req: Request, res: Response) => {
  res.json({
    service: 'librio-api',
    version: '1.0.0',
    phase: 'Phase 3 - Production Guardrails',
    environment: nodeEnv,
    timestamp: new Date().toISOString(),
    features: {
      aiGuardrails: true,
      rateLimiting: true,
      tokenQuotas: true,
      concurrencyLimits: true,
      globalSpendingCap: true,
      abuseDetection: true,
      safetyChecks: true,
      documentLimits: true,
    },
  });
});

// API Routes
app.use('/auth', authRoutes);
app.use('/content', supabaseRoutes);
app.use('/admin', adminRoutes);
app.use('/api/v1/ai', aiRoutes);
app.use('/api/v1/documents', documentRoutes);

// Root endpoint
app.get('/', (_req: Request, res: Response) => {
  res.json({
    message: 'Librio API',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      status: '/api/v1/status',
      auth: '/auth',
      content: '/content',
      admin: '/admin',
      ai: '/api/v1/ai',
      documents: '/api/v1/documents',
    },
  });
});

// 404 handler
app.use((_req: Request, res: Response) => {
  res.status(404).json({
    error: 'Not found',
    path: _req.path,
    method: _req.method,
  });
});

// Error handler — never expose stack traces in production
app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: err.message || 'Internal server error',
      ...(nodeEnv === 'development' && { stack: err.stack }),
    },
  });
});

// Start server
const server = app.listen(port, () => {
  console.log(`✅ Librio API listening on port ${port}`);
  console.log(`📍 Environment: ${nodeEnv}`);
  console.log(`🔗 Health check: http://localhost:${port}/health`);
  console.log(`📚 API docs: http://localhost:${port}/`);
  console.log(`🛡️  AI Guardrails: enabled`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully...');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

export default app;
