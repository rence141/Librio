import { NextRequest, NextResponse } from 'next/server';
import { verifyToken } from '@/lib/auth';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  const user = verifyToken(req.headers.get('authorization'));
  if (!user) {
    return NextResponse.json({ error: { code: 'AUTH_REQUIRED', message: 'Access token required' } }, { status: 401 });
  }

  return NextResponse.json({
    usage: {
      inputTokens: 0,
      outputTokens: 0,
      totalTokens: 0,
      remainingTokens: 100_000,
    },
    limits: {
      maxInputTokens: 8000,
      maxOutputTokens: 4000,
      dailyTokenLimit: 100_000,
      maxConcurrentRequests: 3,
    },
    tier: user.tier,
  });
}
