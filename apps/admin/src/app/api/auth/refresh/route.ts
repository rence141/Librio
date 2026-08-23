import { NextRequest, NextResponse } from 'next/server';
import { verifyRefreshToken, generateAccessToken, generateRefreshToken } from '@/lib/auth';

export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  try {
    const { refreshToken } = await req.json();

    if (!refreshToken) {
      return NextResponse.json({ error: 'Refresh token is required' }, { status: 400 });
    }

    const decoded = verifyRefreshToken(refreshToken);
    if (!decoded) {
      return NextResponse.json({ error: 'Invalid refresh token' }, { status: 401 });
    }

    const accessToken = generateAccessToken({ id: decoded.id, email: decoded.email, tier: 'free' });
    const newRefreshToken = generateRefreshToken({ id: decoded.id, email: decoded.email });

    return NextResponse.json({
      success: true,
      data: { accessToken, refreshToken: newRefreshToken },
    });
  } catch (error) {
    console.error('Token refresh error:', error);
    return NextResponse.json({ error: 'Invalid refresh token' }, { status: 401 });
  }
}
