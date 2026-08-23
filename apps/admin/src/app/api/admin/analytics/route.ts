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
    return NextResponse.json({
      success: true,
      data: {
        totalUsers: 0,
        activeUsers: 0,
        totalDocuments: 0,
        totalSessions: 0,
        tierDistribution: { free: 0, pro: 0, enterprise: 0 },
      },
    });
  }

  try {
    const supabase = getSupabase()!;
    const [users, documents, sessions] = await Promise.all([
      supabase.from('user_profiles').select('subscription_tier'),
      supabase.from('documents').select('id', { count: 'exact' }),
      supabase.from('sessions').select('id', { count: 'exact' }),
    ]);

    const tierDistribution = { free: 0, pro: 0, enterprise: 0 };
    (users.data || []).forEach((u: any) => {
      const tier = u.subscription_tier as keyof typeof tierDistribution;
      if (tier in tierDistribution) tierDistribution[tier]++;
    });

    return NextResponse.json({
      success: true,
      data: {
        totalUsers: users.data?.length || 0,
        activeUsers: users.data?.length || 0,
        totalDocuments: documents.count || 0,
        totalSessions: sessions.count || 0,
        tierDistribution,
      },
    });
  } catch (error) {
    console.error('Error getting analytics:', error);
    return NextResponse.json({ error: 'Failed to get analytics' }, { status: 500 });
  }
}
