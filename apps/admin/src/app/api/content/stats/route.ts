import { NextRequest, NextResponse } from 'next/server';
import { verifyToken } from '@/lib/auth';
import { getSupabase, isSupabaseConfigured } from '@/lib/supabase';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  const user = verifyToken(req.headers.get('authorization'));
  if (!user) {
    return NextResponse.json({ error: 'User not authenticated' }, { status: 401 });
  }

  if (!isSupabaseConfigured()) {
    return NextResponse.json({
      success: true,
      data: { documents: 0, sessions: 0, benchmarks: 0 },
    });
  }

  try {
    const supabase = getSupabase()!;
    const [documents, sessions, benchmarks] = await Promise.all([
      supabase.from('documents').select('id', { count: 'exact' }).eq('user_id', user.id),
      supabase.from('sessions').select('id', { count: 'exact' }).eq('user_id', user.id),
      supabase.from('benchmarks').select('id', { count: 'exact' }).eq('user_id', user.id),
    ]);

    return NextResponse.json({
      success: true,
      data: {
        documents: documents.count || 0,
        sessions: sessions.count || 0,
        benchmarks: benchmarks.count || 0,
      },
    });
  } catch (error) {
    console.error('Error getting stats:', error);
    return NextResponse.json({ error: 'Failed to get stats' }, { status: 500 });
  }
}
