-- Phase 2: Database Schema Enhancements
-- Adds user progress tracking, materials management, and sync queue

-- ============ USER PROGRESS TABLE ============

CREATE TABLE IF NOT EXISTS user_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subject TEXT NOT NULL,
  topic TEXT,
  questions_answered INTEGER DEFAULT 0,
  correct_answers INTEGER DEFAULT 0,
  time_spent_minutes INTEGER DEFAULT 0,
  last_accessed TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for user_progress
CREATE INDEX IF NOT EXISTS idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_subject ON user_progress(subject);
CREATE INDEX IF NOT EXISTS idx_user_progress_user_subject ON user_progress(user_id, subject);

-- ============ MATERIALS TABLE ============

CREATE TABLE IF NOT EXISTS materials (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  subject TEXT NOT NULL,
  topic TEXT,
  content TEXT NOT NULL,
  source TEXT,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  is_public BOOLEAN DEFAULT false,
  is_featured BOOLEAN DEFAULT false,
  download_count INTEGER DEFAULT 0,
  rating DECIMAL(3, 2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for materials
CREATE INDEX IF NOT EXISTS idx_materials_subject ON materials(subject);
CREATE INDEX IF NOT EXISTS idx_materials_topic ON materials(topic);
CREATE INDEX IF NOT EXISTS idx_materials_is_public ON materials(is_public);
CREATE INDEX IF NOT EXISTS idx_materials_is_featured ON materials(is_featured);
CREATE INDEX IF NOT EXISTS idx_materials_created_by ON materials(created_by);

-- Full-text search on materials
CREATE INDEX IF NOT EXISTS idx_materials_search ON materials USING GIN (
  to_tsvector('english', title || ' ' || subject || ' ' || content)
);

-- ============ SYNC QUEUE TABLE ============

CREATE TABLE IF NOT EXISTS sync_queue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  operation TEXT NOT NULL,  -- 'insert', 'update', 'delete'
  table_name TEXT NOT NULL,
  record_id UUID,
  data JSONB,
  status TEXT DEFAULT 'pending',  -- 'pending', 'synced', 'failed'
  error_message TEXT,
  retry_count INTEGER DEFAULT 0,
  max_retries INTEGER DEFAULT 3,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  synced_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for sync_queue
CREATE INDEX IF NOT EXISTS idx_sync_queue_user_id ON sync_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue(status);
CREATE INDEX IF NOT EXISTS idx_sync_queue_user_status ON sync_queue(user_id, status);
CREATE INDEX IF NOT EXISTS idx_sync_queue_created_at ON sync_queue(created_at DESC);

-- ============ ANALYTICS TABLE ============

CREATE TABLE IF NOT EXISTS analytics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,  -- 'chat', 'document_view', 'material_download', etc.
  event_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for analytics
CREATE INDEX IF NOT EXISTS idx_analytics_user_id ON analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_event_type ON analytics(event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_created_at ON analytics(created_at DESC);

-- ============ AUDIT LOG TABLE ============

CREATE TABLE IF NOT EXISTS audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  table_name TEXT,
  record_id UUID,
  old_data JSONB,
  new_data JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for audit_log
CREATE INDEX IF NOT EXISTS idx_audit_log_user_id ON audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON audit_log(created_at DESC);

-- ============ ROW LEVEL SECURITY ============

-- Enable RLS on new tables
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics ENABLE ROW LEVEL SECURITY;

-- user_progress: Users can only see their own progress
CREATE POLICY "Users can view own progress"
  ON user_progress FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress"
  ON user_progress FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own progress"
  ON user_progress FOR UPDATE
  USING (auth.uid() = user_id);

-- materials: Public materials visible to all, private only to owner
CREATE POLICY "Users can view public materials"
  ON materials FOR SELECT
  USING (is_public = true OR auth.uid() = created_by);

CREATE POLICY "Users can insert materials"
  ON materials FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own materials"
  ON materials FOR UPDATE
  USING (auth.uid() = created_by);

CREATE POLICY "Users can delete own materials"
  ON materials FOR DELETE
  USING (auth.uid() = created_by);

-- sync_queue: Users can only see their own queue
CREATE POLICY "Users can view own sync queue"
  ON sync_queue FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sync queue"
  ON sync_queue FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- analytics: Users can only see their own analytics
CREATE POLICY "Users can view own analytics"
  ON analytics FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own analytics"
  ON analytics FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============ FUNCTIONS ============

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for user_progress
CREATE TRIGGER update_user_progress_updated_at
  BEFORE UPDATE ON user_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for materials
CREATE TRIGGER update_materials_updated_at
  BEFORE UPDATE ON materials
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for sync_queue
CREATE TRIGGER update_sync_queue_updated_at
  BEFORE UPDATE ON sync_queue
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============ VIEWS ============

-- View for user statistics
CREATE OR REPLACE VIEW user_statistics AS
SELECT
  up.user_id,
  COUNT(DISTINCT up.subject) as subjects_studied,
  SUM(up.questions_answered) as total_questions,
  SUM(up.correct_answers) as total_correct,
  SUM(up.time_spent_minutes) as total_time_minutes,
  MAX(up.last_accessed) as last_accessed
FROM user_progress up
GROUP BY up.user_id;

-- View for sync status
CREATE OR REPLACE VIEW sync_status AS
SELECT
  user_id,
  COUNT(*) as total_pending,
  COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_count,
  COUNT(CASE WHEN status = 'synced' THEN 1 END) as synced_count,
  COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_count,
  MAX(created_at) as last_sync_attempt
FROM sync_queue
GROUP BY user_id;
