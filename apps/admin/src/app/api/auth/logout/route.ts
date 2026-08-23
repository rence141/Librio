import { NextRequest, NextResponse } from 'next/server';
import { verifyToken } from '@/lib/auth';

export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  const user = verifyToken(req.headers.get('authorization'));
  if (!user) {
    return NextResponse.json({ error: 'User not authenticated' }, { status: 401 });
  }

  return NextResponse.json({
    success: true,
    message: 'Logged out successfully',
  });
}
