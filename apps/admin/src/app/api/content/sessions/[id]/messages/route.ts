import { NextRequest, NextResponse } from 'next/server';
import { verifyToken } from '@/lib/auth';
import { getSupabase, isSupabaseConfigured } from '@/lib/supabase';

export const dynamic = 'force-dynamic';

export async function POST(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  const user = verifyToken(req.headers.get('authorization'));
  if (!user) {
    return NextResponse.json({ error: 'User not authenticated' }, { status: 401 });
  }

  if (!isSupabaseConfigured()) {
    return NextResponse.json({ error: 'Supabase not configured' }, { status: 503 });
  }

  try {
    const { role, content, metadata } = await req.json();
    if (!role || !content) {
      return NextResponse.json({ error: 'Missing required fields: role, content' }, { status: 400 });
    }

    const supabase = getSupabase()!;
    const { data, error } = await supabase.from('messages').insert({
      session_id: params.id,
      user_id: user.id,
      role,
      content,
      metadata,
    }).select().single();

    if (error) throw error;

    return NextResponse.json({ success: true, data }, { status: 201 });
  } catch (error) {
    console.error('Error adding message:', error);
    return NextResponse.json({ error: 'Failed to add message' }, { status: 500 });
  }
}

export async function GET(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  const user = verifyToken(req.headers.get('authorization'));
  if (!user) {
    return NextResponse.json({ error: 'User not authenticated' }, { status: 401 });
  }

  if (!isSupabaseConfigured()) {
    return NextResponse.json({ success: true, data: [], count: 0 });
  }

  try {
    const supabase = getSupabase()!;
    const { data, error } = await supabase.from('messages').select('*').eq('session_id', params.id).eq('user_id', user.id).order('created_at', { ascending: true });

    if (error) throw error;

    return NextResponse.json({ success: true, data: data || [], count: data?.length || 0 });
  } catch (error) {
    console.error('Error getting messages:', error);
    return NextResponse.json({ error: 'Failed to get messages' }, { status: 500 });
  }
}
