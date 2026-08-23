import { NextRequest, NextResponse } from 'next/server';
import { verifyToken } from '@/lib/auth';

export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  const user = verifyToken(req.headers.get('authorization'));
  if (!user) {
    return NextResponse.json({ error: { code: 'AUTH_REQUIRED', message: 'Access token required' } }, { status: 401 });
  }

  const maxRagQueriesPerDay = user.tier === 'free' ? 50 : 500;

  return NextResponse.json({
    success: true,
    remaining: maxRagQueriesPerDay,
  });
}
