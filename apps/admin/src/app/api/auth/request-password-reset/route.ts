import { NextRequest, NextResponse } from 'next/server';
import { getSupabase, isSupabaseConfigured } from '@/lib/supabase';

export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  try {
    const { email } = await req.json();

    if (!email) {
      return NextResponse.json({ error: 'Email is required' }, { status: 400 });
    }

    if (!isSupabaseConfigured()) {
      return NextResponse.json({ error: 'Supabase not configured' }, { status: 503 });
    }

    const supabase = getSupabase()!;
    const { error } = await supabase.auth.resetPasswordForEmail(email);

    if (error) {
      return NextResponse.json({ error: 'Failed to request password reset' }, { status: 500 });
    }

    return NextResponse.json({ success: true, message: 'Password reset email sent' });
  } catch (error) {
    console.error('Password reset request error:', error);
    return NextResponse.json({ error: 'Failed to request password reset' }, { status: 500 });
  }
}
