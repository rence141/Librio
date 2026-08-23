import { NextRequest, NextResponse } from 'next/server';
import { getSupabase, isSupabaseConfigured } from '@/lib/supabase';
import { generateAccessToken, generateRefreshToken } from '@/lib/auth';

export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  try {
    const { idToken } = await req.json();

    if (!idToken) {
      return NextResponse.json({ error: 'Google ID token is required' }, { status: 400 });
    }

    if (!isSupabaseConfigured()) {
      return NextResponse.json({ error: 'Supabase not configured' }, { status: 503 });
    }

    const supabase = getSupabase()!;
    const { data, error } = await supabase.auth.signInWithIdToken({
      provider: 'google',
      token: idToken,
    });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 401 });
    }

    const user = data.user;
    if (!user) {
      return NextResponse.json({ error: 'Google sign-in failed' }, { status: 401 });
    }

    const accessToken = generateAccessToken({ id: user.id, email: user.email || '', tier: 'free' });
    const refreshToken = generateRefreshToken({ id: user.id, email: user.email || '' });

    return NextResponse.json({
      success: true,
      data: { user, accessToken, refreshToken },
    });
  } catch (error) {
    console.error('Google sign-in error:', error);
    const message = error instanceof Error ? error.message : 'Google sign-in failed';
    return NextResponse.json({ error: message }, { status: 401 });
  }
}
