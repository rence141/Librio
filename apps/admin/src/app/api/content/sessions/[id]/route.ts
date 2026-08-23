import { NextRequest, NextResponse } from 'next/server';
import { verifyToken } from '@/lib/auth';
import { getSupabase, isSupabaseConfigured } from '@/lib/supabase';

export const dynamic = 'force-dynamic';

export async function GET(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  const user = verifyToken(req.headers.get('authorization'));
  if (!user) {
    return NextResponse.json({ error: 'User not authenticated' }, { status: 401 });
  }

  if (!isSupabaseConfigured()) {
    return NextResponse.json({ error: 'Session not found' }, { status: 404 });
  }

  try {
    const supabase = getSupabase()!;
    const { data, error } = await supabase.from('sessions').select('*').eq('id', params.id).eq('user_id', user.id).single();

    if (error || !data) {
      return NextResponse.json({ error: 'Session not found' }, { status: 404 });
    }

    return NextResponse.json({ success: true, data });
  } catch (error) {
    console.error('Error getting session:', error);
    return NextResponse.json({ error: 'Failed to get session' }, { status: 500 });
  }
}
