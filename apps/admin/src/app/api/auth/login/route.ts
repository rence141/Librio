import { NextRequest, NextResponse } from 'next/server';
import { getSupabase, isSupabaseConfigured } from '@/lib/supabase';
import { generateAccessToken, generateRefreshToken } from '@/lib/auth';

export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  try {
    const { email, password } = await req.json();

    if (!email || !password) {
      return NextResponse.json({ error: 'Email and password are required' }, { status: 400 });
    }

    if (!isSupabaseConfigured()) {
      return NextResponse.json({ error: 'Supabase not configured' }, { status: 503 });
    }

    const supabase = getSupabase()!;
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 401 });
    }

    const user = data.user;
    if (!user) {
      return NextResponse.json({ error: 'Login failed' }, { status: 401 });
    }

    const accessToken = generateAccessToken({ id: user.id, email: user.email || email, tier: 'free' });
    const refreshToken = generateRefreshToken({ id: user.id, email: user.email || email });

    return NextResponse.json({
      success: true,
      data: { user, accessToken, refreshToken },
    });
  } catch (error) {
    console.error('Login error:', error);
    const message = error instanceof Error ? error.message : 'Login failed';
    return NextResponse.json({ error: message }, { status: 401 });
  }
}
