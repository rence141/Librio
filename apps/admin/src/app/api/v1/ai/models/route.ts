import { NextRequest, NextResponse } from 'next/server';
import { verifyToken } from '@/lib/auth';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  const user = verifyToken(req.headers.get('authorization'));
  if (!user) {
    return NextResponse.json({ error: { code: 'AUTH_REQUIRED', message: 'Access token required' } }, { status: 401 });
  }

  return NextResponse.json({
    models: [
      { id: 'local-small', name: 'Local Small (On-Device)', provider: 'local', tier: 'free' },
      { id: 'local-medium', name: 'Local Medium (On-Device)', provider: 'local', tier: 'free' },
      { id: 'cloud-fast', name: 'Cloud Fast', provider: 'cloud', tier: 'premium' },
      { id: 'cloud-advanced', name: 'Cloud Advanced', provider: 'cloud', tier: 'premium' },
    ],
  });
}
