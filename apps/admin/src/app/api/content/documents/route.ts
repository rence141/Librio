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
    return NextResponse.json({ success: true, data: [], count: 0 });
  }

  try {
    const supabase = getSupabase()!;
    const category = req.nextUrl.searchParams.get('category');

    let query = supabase.from('documents').select('*').eq('user_id', user.id);
    if (category) query = query.eq('category', category);

    const { data, error } = await query;
    if (error) throw error;

    return NextResponse.json({ success: true, data: data || [], count: data?.length || 0 });
  } catch (error) {
    console.error('Error getting documents:', error);
    return NextResponse.json({ error: 'Failed to get documents' }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  const user = verifyToken(req.headers.get('authorization'));
  if (!user) {
    return NextResponse.json({ error: 'User not authenticated' }, { status: 401 });
  }

  if (!isSupabaseConfigured()) {
    return NextResponse.json({ error: 'Supabase not configured' }, { status: 503 });
  }

  try {
    const { title, content, embedding, source, category, metadata } = await req.json();

    if (!title || !content || !embedding || !source || !category) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    const supabase = getSupabase()!;
    const { data, error } = await supabase.from('documents').insert({
      user_id: user.id,
      title,
      content,
      embedding,
      source,
      category,
      metadata,
    }).select().single();

    if (error) throw error;

    return NextResponse.json({ success: true, data }, { status: 201 });
  } catch (error) {
    console.error('Error adding document:', error);
    return NextResponse.json({ error: 'Failed to add document' }, { status: 500 });
  }
}
