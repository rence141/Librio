import { NextRequest, NextResponse } from 'next/server';
import { verifyToken } from '@/lib/auth';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  const user = verifyToken(req.headers.get('authorization'));
  if (!user) {
    return NextResponse.json({ error: 'Admin access required' }, { status: 403 });
  }

  const memoryUsage = process.memoryUsage();

  return NextResponse.json({
    success: true,
    data: {
      status: 'healthy',
      uptime: process.uptime(),
      memory: {
        heapUsed: `${(memoryUsage.heapUsed / 1024 / 1024).toFixed(2)}MB`,
        heapTotal: `${(memoryUsage.heapTotal / 1024 / 1024).toFixed(2)}MB`,
        external: `${(memoryUsage.external / 1024 / 1024).toFixed(2)}MB`,
        rss: `${(memoryUsage.rss / 1024 / 1024).toFixed(2)}MB`,
      },
      timestamp: new Date().toISOString(),
    },
  });
}
