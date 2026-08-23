import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET() {
  return NextResponse.json({
    service: 'librio-api',
    version: '1.0.0',
    phase: 'Phase 3 - Production Guardrails',
    environment: process.env.NODE_ENV || 'development',
    timestamp: new Date().toISOString(),
    features: {
      aiGuardrails: true,
      rateLimiting: true,
      tokenQuotas: true,
      concurrencyLimits: true,
      globalSpendingCap: true,
      abuseDetection: true,
      safetyChecks: true,
      documentLimits: true,
    },
  });
}
