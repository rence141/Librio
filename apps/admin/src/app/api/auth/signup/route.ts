import { NextRequest, NextResponse } from 'next/server';
import { getSupabase, isSupabaseConfigured } from '@/lib/supabase';
import { generateAccessToken, generateRefreshToken } from '@/lib/auth';

export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  try {
    const { email, password, fullName } = await req.json();

    if (!email || !password) {
      return NextResponse.json({ error: 'Email and password are required' }, { status: 400 });
    }

    if (!isSupabaseConfigured()) {
      return NextResponse.json({ error: 'Supabase not configured' }, { status: 503 });
    }

    const supabase = getSupabase()!;
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { full_name: fullName } },
    });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    const user = data.user;
    if (!user) {
      return NextResponse.json({ error: 'Sign up failed' }, { status: 400 });
    }

    const accessToken = generateAccessToken({ id: user.id, email: user.email || email, tier: 'free', isNewAccount: true });
    const refreshToken = generateRefreshToken({ id: user.id, email: user.email || email });

    return NextResponse.json({
      success: true,
      data: { user, accessToken, refreshToken },
    }, { status: 201 });
  } catch (error) {
    console.error('Sign up error:', error);
    const message = error instanceof Error ? error.message : 'Sign up failed';
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
