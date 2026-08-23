import { NextRequest, NextResponse } from 'next/server';
import { verifyToken } from '@/lib/auth';
import { getSupabase, isSupabaseConfigured } from '@/lib/supabase';

export const dynamic = 'force-dynamic';

export async function PUT(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  const user = verifyToken(req.headers.get('authorization'));
  if (!user) {
    return NextResponse.json({ error: 'Admin access required' }, { status: 403 });
  }

  if (!isSupabaseConfigured()) {
    return NextResponse.json({ error: 'Supabase not configured' }, { status: 503 });
  }

  try {
    const { featured } = await req.json();
    if (typeof featured !== 'boolean') {
      return NextResponse.json({ error: 'Featured must be a boolean' }, { status: 400 });
    }

    const supabase = getSupabase()!;
    const { error } = await supabase.from('materials').update({ featured }).eq('id', params.id);

    if (error) throw error;

    return NextResponse.json({ success: true, message: `Material ${featured ? 'featured' : 'unfeatured'}` });
  } catch (error) {
    console.error('Error setting material featured:', error);
    return NextResponse.json({ error: 'Failed to update material' }, { status: 500 });
  }
}

export async function DELETE(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  const user = verifyToken(req.headers.get('authorization'));
  if (!user) {
    return NextResponse.json({ error: 'Admin access required' }, { status: 403 });
  }

  if (!isSupabaseConfigured()) {
    return NextResponse.json({ error: 'Supabase not configured' }, { status: 503 });
  }

  try {
    const supabase = getSupabase()!;
    const { error } = await supabase.from('materials').delete().eq('id', params.id);

    if (error) throw error;

    return NextResponse.json({ success: true, message: 'Material deleted' });
  } catch (error) {
    console.error('Error deleting material:', error);
    return NextResponse.json({ error: 'Failed to delete material' }, { status: 500 });
  }
}
