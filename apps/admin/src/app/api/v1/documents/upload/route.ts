import { NextRequest, NextResponse } from 'next/server';
import { verifyToken } from '@/lib/auth';
import { z } from 'zod';

export const dynamic = 'force-dynamic';

const uploadSchema = z.object({
  title: z.string().min(1).max(500),
  content: z.string().min(1),
  source: z.string().max(500).optional(),
  category: z.string().max(100).optional(),
  fileSizeBytes: z.number().int().min(1).optional(),
});

export async function POST(req: NextRequest) {
  const user = verifyToken(req.headers.get('authorization'));
  if (!user) {
    return NextResponse.json({ error: { code: 'AUTH_REQUIRED', message: 'Access token required' } }, { status: 401 });
  }

  try {
    const body = await req.json();
    const parseResult = uploadSchema.safeParse(body);
    if (!parseResult.success) {
      return NextResponse.json({ error: 'Invalid upload', details: parseResult.error.issues }, { status: 400 });
    }

    const limits = {
      maxFileSizeMB: user.tier === 'free' ? 10 : 50,
      maxDocumentsPerDay: user.tier === 'free' ? 20 : 100,
      maxStorageMB: user.tier === 'free' ? 100 : 1000,
    };

    if (parseResult.data.fileSizeBytes && parseResult.data.fileSizeBytes > limits.maxFileSizeMB * 1024 * 1024) {
      return NextResponse.json({ error: `File exceeds maximum of ${limits.maxFileSizeMB}MB` }, { status: 413 });
    }

    return NextResponse.json({
      success: true,
      documentId: `doc_${Date.now()}`,
      limits,
    });
  } catch (error) {
    console.error('Document upload error:', error);
    return NextResponse.json({ error: { code: 'INTERNAL_ERROR', message: 'Upload failed.' } }, { status: 500 });
  }
}
