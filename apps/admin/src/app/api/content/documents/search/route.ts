import { NextRequest, NextResponse } from 'next/server';
import { verifyToken } from '@/lib/auth';
import { getSupabase, isSupabaseConfigured } from '@/lib/supabase';

export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  const user = verifyToken(req.headers.get('authorization'));
  if (!user) {
    return NextResponse.json({ error: 'User not authenticated' }, { status: 401 });
  }

  if (!isSupabaseConfigured()) {
    return NextResponse.json({ error: 'Supabase not configured' }, { status: 503 });
  }

  try {
    const { embedding, limit = 5, category, threshold = 0.5 } = await req.json();

    if (!embedding || !Array.isArray(embedding)) {
      return NextResponse.json({ error: 'Missing or invalid embedding' }, { status: 400 });
    }

    const supabase = getSupabase()!;
    const { data, error } = await supabase.rpc('match_documents', {
      query_embedding: embedding,
      match_count: limit,
      filter_user_id: user.id,
      filter_category: category || null,
      match_threshold: threshold,
    });

    if (error) throw error;

    return NextResponse.json({ success: true, data: data || [], count: data?.length || 0 });
  } catch (error) {
    console.error('Error searching documents:', error);
    return NextResponse.json({ error: 'Failed to search documents' }, { status: 500 });
  }
}
