/**
 * Guardrails Configuration
 *
 * All AI abuse-prevention limits are configurable here.
 * Values can be overridden via environment variables.
 *
 * Principle: Client-side limits are UX features.
 *             Server-side limits are security controls.
 */

export type SubscriptionTier = 'free' | 'premium';

export interface TierLimits {
  /** Requests per minute */
  requestsPerMinute: number;
  /** Requests per hour */
  requestsPerHour: number;
  /** AI requests per day */
  aiRequestsPerDay: number;
  /** Total tokens per day (input + output) */
  tokensPerDay: number;
  /** Max input tokens per request */
  maxInputTokens: number;
  /** Max output tokens per request */
  maxOutputTokens: number;
  /** Max concurrent AI generations */
  maxConcurrency: number;
  /** AI credits per day (cost-multiplier based) */
  creditsPerDay: number;
}

export interface ModelMeta {
  id: string;
  provider: 'local' | 'openai' | 'anthropic' | 'gemini' | 'custom';
  displayName: string;
  costMultiplier: number;
  maxInputTokens: number;
  maxOutputTokens: number;
  allowedTiers: SubscriptionTier[];
}

export interface DocumentLimits {
  maxFileSizeMB: number;
  maxPages: number;
  maxDocumentsPerDay: number;
  maxStorageMB: number;
  maxRagQueriesPerDay: number;
  maxExtractedTextChars: number;
}

export interface GlobalSpendingLimits {
  /** Max daily cloud spend in USD */
  dailyBudgetUSD: number;
  /** Max monthly cloud spend in USD */
  monthlyBudgetUSD: number;
  /** Emergency kill-switch threshold in USD */
  emergencyBudgetUSD: number;
}

export interface AccountFarmingLimits {
  /** Max registrations per IP per hour */
  maxRegistrationsPerIpPerHour: number;
  /** Max registrations per email domain per day */
  maxRegistrationsPerDomainPerDay: number;
  /** Reduced quota duration for new accounts (hours) */
  newAccountCooldownHours: number;
  /** New account reduced quota multiplier (0-1) */
  newAccountQuotaMultiplier: number;
}

export interface RateLimitConfig {
  /** Global requests per second across all users */
  globalRequestsPerSecond: number;
  /** Max requests per IP per minute (DDoS protection) */
  ipRequestsPerMinute: number;
  /** Registration attempts per IP per hour */
  registrationPerIpPerHour: number;
}

const envInt = (key: string, fallback: number): number => {
  const v = process.env[key];
  return v ? parseInt(v, 10) : fallback;
};

const envFloat = (key: string, fallback: number): number => {
  const v = process.env[key];
  return v ? parseFloat(v) : fallback;
};

/** Per-tier limits. Override via env vars. */
export const TIER_LIMITS: Record<SubscriptionTier, TierLimits> = {
  free: {
    requestsPerMinute: envInt('FREE_REQ_PER_MIN', 5),
    requestsPerHour: envInt('FREE_REQ_PER_HOUR', 30),
    aiRequestsPerDay: envInt('FREE_AI_REQ_PER_DAY', 30),
    tokensPerDay: envInt('FREE_TOKENS_PER_DAY', 30_000),
    maxInputTokens: envInt('FREE_MAX_INPUT_TOKENS', 8_000),
    maxOutputTokens: envInt('FREE_MAX_OUTPUT_TOKENS', 2_048),
    maxConcurrency: envInt('FREE_MAX_CONCURRENCY', 1),
    creditsPerDay: envInt('FREE_CREDITS_PER_DAY', 100),
  },
  premium: {
    requestsPerMinute: envInt('PREMIUM_REQ_PER_MIN', 20),
    requestsPerHour: envInt('PREMIUM_REQ_PER_HOUR', 200),
    aiRequestsPerDay: envInt('PREMIUM_AI_REQ_PER_DAY', 300),
    tokensPerDay: envInt('PREMIUM_TOKENS_PER_DAY', 300_000),
    maxInputTokens: envInt('PREMIUM_MAX_INPUT_TOKENS', 16_000),
    maxOutputTokens: envInt('PREMIUM_MAX_OUTPUT_TOKENS', 8_192),
    maxConcurrency: envInt('PREMIUM_MAX_CONCURRENCY', 3),
    creditsPerDay: envInt('PREMIUM_CREDITS_PER_DAY', 1000),
  },
};

/** Model registry. The server decides which models a user can access. */
export const MODEL_REGISTRY: ModelMeta[] = [
  {
    id: 'local-gemma-3-1b',
    provider: 'local',
    displayName: 'Gemma 3 1B (On-Device)',
    costMultiplier: 0,
    maxInputTokens: 4_096,
    maxOutputTokens: 1_024,
    allowedTiers: ['free', 'premium'],
  },
  {
    id: 'cloud-fast',
    provider: 'openai',
    displayName: 'Fast Cloud Model',
    costMultiplier: 1,
    maxInputTokens: 16_000,
    maxOutputTokens: 4_096,
    allowedTiers: ['free', 'premium'],
  },
  {
    id: 'cloud-advanced',
    provider: 'openai',
    displayName: 'Advanced Cloud Model',
    costMultiplier: 5,
    maxInputTokens: 32_000,
    maxOutputTokens: 8_192,
    allowedTiers: ['premium'],
  },
  {
    id: 'cloud-premium',
    provider: 'anthropic',
    displayName: 'Premium Cloud Model',
    costMultiplier: 20,
    maxInputTokens: 100_000,
    maxOutputTokens: 8_192,
    allowedTiers: ['premium'],
  },
];

/** Document/RAG limits per tier. */
export const DOCUMENT_LIMITS: Record<SubscriptionTier, DocumentLimits> = {
  free: {
    maxFileSizeMB: envInt('FREE_DOC_MAX_SIZE_MB', 20),
    maxPages: envInt('FREE_DOC_MAX_PAGES', 100),
    maxDocumentsPerDay: envInt('FREE_DOC_MAX_PER_DAY', 10),
    maxStorageMB: envInt('FREE_DOC_MAX_STORAGE_MB', 100),
    maxRagQueriesPerDay: envInt('FREE_RAG_QUERIES_PER_DAY', 50),
    maxExtractedTextChars: envInt('FREE_DOC_MAX_TEXT_CHARS', 500_000),
  },
  premium: {
    maxFileSizeMB: envInt('PREMIUM_DOC_MAX_SIZE_MB', 50),
    maxPages: envInt('PREMIUM_DOC_MAX_PAGES', 500),
    maxDocumentsPerDay: envInt('PREMIUM_DOC_MAX_PER_DAY', 100),
    maxStorageMB: envInt('PREMIUM_DOC_MAX_STORAGE_MB', 1000),
    maxRagQueriesPerDay: envInt('PREMIUM_RAG_QUERIES_PER_DAY', 500),
    maxExtractedTextChars: envInt('PREMIUM_DOC_MAX_TEXT_CHARS', 2_000_000),
  },
};

/** Global spending protection (financial kill switch). */
export const SPENDING_LIMITS: GlobalSpendingLimits = {
  dailyBudgetUSD: envFloat('GLOBAL_DAILY_BUDGET_USD', 50),
  monthlyBudgetUSD: envFloat('GLOBAL_MONTHLY_BUDGET_USD', 1000),
  emergencyBudgetUSD: envFloat('GLOBAL_EMERGENCY_BUDGET_USD', 200),
};

/** Account farming protection. */
export const ACCOUNT_FARMING_LIMITS: AccountFarmingLimits = {
  maxRegistrationsPerIpPerHour: envInt('MAX_REG_PER_IP_HOUR', 3),
  maxRegistrationsPerDomainPerDay: envInt('MAX_REG_PER_DOMAIN_DAY', 20),
  newAccountCooldownHours: envInt('NEW_ACCOUNT_COOLDOWN_HOURS', 24),
  newAccountQuotaMultiplier: envFloat('NEW_ACCOUNT_QUOTA_MULTIPLIER', 0.5),
};

/** System-wide rate limits. */
export const RATE_LIMIT_CONFIG: RateLimitConfig = {
  globalRequestsPerSecond: envInt('GLOBAL_REQ_PER_SEC', 100),
  ipRequestsPerMinute: envInt('IP_REQ_PER_MIN', 100),
  registrationPerIpPerHour: envInt('REG_PER_IP_HOUR', 3),
};

/** Concurrency lease TTL in seconds. Abandoned requests auto-release. */
export const CONCURRENCY_LEASE_TTL_SEC = envInt('CONCURRENCY_LEASE_TTL', 120);

/** Idempotency key TTL in seconds. */
export const IDEMPOTENCY_TTL_SEC = envInt('IDEMPOTENCY_TTL', 3600);

/** Get limits for a tier. */
export function getTierLimits(tier: SubscriptionTier): TierLimits {
  return TIER_LIMITS[tier] ?? TIER_LIMITS.free;
}

/** Get document limits for a tier. */
export function getDocumentLimits(tier: SubscriptionTier): DocumentLimits {
  return DOCUMENT_LIMITS[tier] ?? DOCUMENT_LIMITS.free;
}

/** Find a model by ID. */
export function findModel(modelId: string): ModelMeta | undefined {
  return MODEL_REGISTRY.find((m) => m.id === modelId);
}

/** Get models allowed for a tier. */
export function getAllowedModels(tier: SubscriptionTier): ModelMeta[] {
  return MODEL_REGISTRY.filter((m) => m.allowedTiers.includes(tier));
}
