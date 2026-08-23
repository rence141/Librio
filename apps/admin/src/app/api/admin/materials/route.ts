import { NextRequest, NextResponse } from 'next/server';
import { verifyToken } from '@/lib/auth';
import { getSupabase, isSupabaseConfigured } from '@/lib/supabase';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  const user = verifyToken(req.headers.get('authorization'));
  if (!user) {
    return NextResponse.json({ error: 'Admin access required' }, { status: 403 });
  }

  if (!isSupabaseConfigured()) {
    return NextResponse.json({ success: true, data: [], count: 0 });
  }

  try {
    const supabase = getSupabase()!;
    const limit = parseInt(req.nextUrl.searchParams.get('limit') || '100');
    const offset = parseInt(req.nextUrl.searchParams.get('offset') || '0');

    const { data, error } = await supabase.from('materials').select('*').range(offset, offset + limit - 1);

    if (error) throw error;

    return NextResponse.json({ success: true, data: data || [], count: data?.length || 0 });
  } catch (error) {
    console.error('Error getting materials:', error);
    return NextResponse.json({ error: 'Failed to get materials' }, { status: 500 });
  }
}
