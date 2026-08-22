-- 003: AI Guardrails Schema
-- Tables for usage tracking, billing, and abuse prevention

-- ============ AI USAGE TABLE ============
-- Records AI usage metadata for billing, analytics, and abuse investigation.
-- Does NOT store copies of user prompts (separate usage metadata from conversation content).

CREATE TABLE IF NOT EXISTS ai_usage (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT NOT NULL,
  model_id TEXT NOT NULL,
  provider TEXT NOT NULL,
  request_id TEXT NOT NULL UNIQUE,
  input_tokens INTEGER NOT NULL DEFAULT 0,
  output_tokens INTEGER NOT NULL DEFAULT 0,
  total_tokens INTEGER NOT NULL DEFAULT 0,
  credits_consumed INTEGER NOT NULL DEFAULT 0,
  latency_ms INTEGER NOT NULL DEFAULT 0,
  success BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ai_usage_user_id ON ai_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_usage_created_at ON ai_usage(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_usage_user_date ON ai_usage(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_usage_provider ON ai_usage(provider);
CREATE INDEX IF NOT EXISTS idx_ai_usage_model ON ai_usage(model_id);

-- ============ USER QUOTA TABLE ============
-- Persistent quota tracking (Redis/KV store used for daily counters,
-- this table for monthly aggregates and billing records).

CREATE TABLE IF NOT EXISTS user_quota (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT NOT NULL UNIQUE,
  tier TEXT NOT NULL DEFAULT 'free',
  total_tokens_used BIGINT NOT NULL DEFAULT 0,
  total_credits_used BIGINT NOT NULL DEFAULT 0,
  monthly_tokens_used BIGINT NOT NULL DEFAULT 0,
  monthly_credits_used BIGINT NOT NULL DEFAULT 0,
  last_reset_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_quota_tier ON user_quota(tier);

-- ============ DOCUMENT STORAGE TABLE ============
-- Tracks document storage per user for quota enforcement.

CREATE TABLE IF NOT EXISTS user_documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT NOT NULL,
  document_id TEXT NOT NULL,
  title TEXT NOT NULL,
  file_size_bytes BIGINT NOT NULL DEFAULT 0,
  page_count INTEGER NOT NULL DEFAULT 0,
  extracted_text_chars INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_documents_user_id ON user_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_user_documents_created_at ON user_documents(created_at DESC);

-- ============ ABUSE INCIDENTS TABLE ============
-- Records abuse incidents for manual review and progressive enforcement.

CREATE TABLE IF NOT EXISTS abuse_incidents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT NOT NULL,
  incident_type TEXT NOT NULL,
  threat_level TEXT NOT NULL,
  score INTEGER NOT NULL DEFAULT 0,
  signals JSONB,
  ip_address TEXT,
  device_id TEXT,
  action_taken TEXT,
  resolved BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_abuse_incidents_user_id ON abuse_incidents(user_id);
CREATE INDEX IF NOT EXISTS idx_abuse_incidents_created_at ON abuse_incidents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_abuse_incidents_resolved ON abuse_incidents(resolved);

-- ============ SPENDING LOG TABLE ============
-- Tracks cloud spending for the global kill switch.

CREATE TABLE IF NOT EXISTS spending_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_credits BIGINT NOT NULL DEFAULT 0,
  estimated_cost_usd DECIMAL(10, 4) NOT NULL DEFAULT 0,
  provider TEXT,
  model_id TEXT,
  request_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_spending_log_date ON spending_log(date DESC);
CREATE INDEX IF NOT EXISTS idx_spending_log_provider ON spending_log(provider);

-- ============ IDEMPOTENCY TABLE (PostgreSQL fallback) ============
-- If Redis is not available, store idempotency keys in PostgreSQL.

CREATE TABLE IF NOT EXISTS idempotency_keys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT NOT NULL,
  request_id TEXT NOT NULL,
  response_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_idempotency_user_request ON idempotency_keys(user_id, request_id);
CREATE INDEX IF NOT EXISTS idx_idempotency_expires ON idempotency_keys(expires_at);
