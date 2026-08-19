import express, { Request, Response } from 'express';
import pinoHttp from 'pino-http';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

// Logging middleware
app.use(pinoHttp());

// JSON parsing
app.use(express.json());

// Health check endpoint
app.get('/health', (_req: Request, res: Response) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
  });
});

// Placeholder: API routes will be added in Phase 1
app.get('/api/v1/status', (_req: Request, res: Response) => {
  res.json({
    service: 'librio-api',
    version: '0.0.1',
    phase: 'Phase 0 - Setup',
  });
});

// 404 handler
app.use((_req: Request, res: Response) => {
  res.status(404).json({ error: 'Not found' });
});

// Start server
app.listen(port, () => {
  console.log(`Librio API listening on port ${port}`);
});
