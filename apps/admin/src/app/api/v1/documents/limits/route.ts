import { NextRequest, NextResponse } from 'next/server';
import { verifyToken } from '@/lib/auth';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  const user = verifyToken(req.headers.get('authorization'));
  if (!user) {
    return NextResponse.json({ error: { code: 'AUTH_REQUIRED', message: 'Access token required' } }, { status: 401 });
  }

  const limits = {
    maxFileSizeMB: user.tier === 'free' ? 10 : 50,
    maxDocumentsPerDay: user.tier === 'free' ? 20 : 100,
    maxStorageMB: user.tier === 'free' ? 100 : 1000,
    maxRagQueriesPerDay: user.tier === 'free' ? 50 : 500,
  };

  return NextResponse.json({ limits, tier: user.tier });
}
