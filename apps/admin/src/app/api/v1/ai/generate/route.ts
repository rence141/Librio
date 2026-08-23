import { NextRequest, NextResponse } from 'next/server';
import { verifyToken } from '@/lib/auth';
import { z } from 'zod';

export const dynamic = 'force-dynamic';

const generateSchema = z.object({
  prompt: z.string().min(1).max(100_000),
  capability: z.enum(['fast', 'advanced', 'premium', 'local']).optional(),
  maxOutputTokens: z.number().int().min(1).max(32_000).optional(),
  temperature: z.number().min(0).max(2).optional(),
  systemPrompt: z.string().max(10_000).optional(),
  requestId: z.string().max(100).optional(),
});

export async function POST(req: NextRequest) {
  const user = verifyToken(req.headers.get('authorization'));
  if (!user) {
    return NextResponse.json({ error: { code: 'AUTH_REQUIRED', message: 'Access token required' } }, { status: 401 });
  }

  try {
    const body = await req.json();
    const parseResult = generateSchema.safeParse(body);
    if (!parseResult.success) {
      return NextResponse.json({ error: 'Invalid request', details: parseResult.error.issues }, { status: 400 });
    }

    const { capability } = parseResult.data;

    // For local model requests, tell client to use on-device AI
    if (capability === 'local' || !process.env.OPENAI_API_KEY) {
      return NextResponse.json({
        text: '',
        model: 'local',
        provider: 'local',
        useLocalModel: true,
        message: 'Use local model for this request.',
      });
    }

    // Cloud model - would call provider here
    // For now, return a placeholder indicating cloud AI needs provider config
    return NextResponse.json({
      text: '',
      model: 'cloud',
      provider: 'cloud',
      useLocalModel: true,
      message: 'Cloud AI not configured. Use local model.',
    });
  } catch (error) {
    console.error('AI generate error:', error);
    return NextResponse.json({ error: { code: 'INTERNAL_ERROR', message: 'An error occurred during generation.' } }, { status: 500 });
  }
}
