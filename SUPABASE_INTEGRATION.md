# Supabase Integration Plan

**Date:** 2026-08-22  
**Status:** Planning & Implementation  
**Backend:** Supabase (PostgreSQL + Auth + Storage + Realtime)

---

## Overview

Supabase provides a complete backend solution for Librio:
- **Database:** PostgreSQL with vector support (pgvector)
- **Authentication:** JWT-based auth with social providers
- **Storage:** File storage for documents and models
- **Realtime:** WebSocket-based real-time updates
- **API:** Auto-generated REST API

---

## Architecture

### Current (Local SQLite)
```
Flutter App
├── Local SQLite DB
├── Local Model Files
└── Local Embeddings
```

### Target (Supabase Backend)
```
Flutter App
├── Supabase Client (Dart)
├── Authentication
├── Real-time Sync
└── Offline Support

Supabase Backend
├── PostgreSQL Database
│   ├── documents (with pgvector)
│   ├── users
│   ├── sessions
│   └── benchmarks
├── Storage (Models & Documents)
├── Authentication (JWT)
├── Realtime (WebSocket)
└── REST API (auto-generated)

Node.js API (Optional)
├── Custom Business Logic
├── Embeddings Generation
├── Model Management
└── Analytics
```

---

## 1. Supabase Project Setup

### Step 1: Create Supabase Project

1. Go to https://supabase.com
2. Sign up or log in
3. Create new project
4. Choose region (closest to users)
5. Set strong database password
6. Wait for project to initialize

### Step 2: Get Connection Details

From Supabase dashboard:
- **Project URL:** `https://xxxxx.supabase.co`
- **Anon Key:** Public key for client
- **Service Key:** Secret key for server
- **Database URL:** PostgreSQL connection string

### Step 3: Enable Extensions

In Supabase SQL Editor:

```sql
-- Enable pgvector for embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable full-text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

---

## 2. Database Schema

### Documents Table (with Vector Support)

```sql
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  embedding vector(384),  -- all-MiniLM-L6-v2 dimension
  source TEXT NOT NULL,
  category TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for performance
CREATE INDEX idx_documents_user_id ON documents(user_id);
CREATE INDEX idx_documents_category ON documents(category);
CREATE INDEX idx_documents_source ON documents(source);
CREATE INDEX idx_documents_created_at ON documents(created_at DESC);
CREATE INDEX idx_documents_embedding ON documents USING ivfflat (embedding vector_cosine_ops);

-- Full-text search
CREATE INDEX idx_documents_search ON documents USING GIN (
  to_tsvector('english', title || ' ' || content)
);
```

### Users Table (Extended)

```sql
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  subscription_tier TEXT DEFAULT 'free',  -- free, pro, enterprise
  storage_limit_mb INTEGER DEFAULT 1000,
  storage_used_mb INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### Benchmarks Table

```sql
CREATE TABLE benchmarks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_name TEXT NOT NULL,
  model_id TEXT NOT NULL,
  load_time_ms INTEGER,
  ttft_ms INTEGER,
  decode_speed_tokens_per_sec DECIMAL(10, 2),
  peak_ram_mb INTEGER,
  battery_drain_percent_per_hour DECIMAL(5, 2),
  total_inference_time_ms INTEGER,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_benchmarks_user_id ON benchmarks(user_id);
CREATE INDEX idx_benchmarks_device ON benchmarks(device_name);
CREATE INDEX idx_benchmarks_model ON benchmarks(model_id);
```

### Sessions Table (for RAG context)

```sql
CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT,
  context JSONB DEFAULT '{}',  -- RAG context
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sessions_user_id ON sessions(user_id);
```

### Messages Table (for conversation history)

```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL,  -- 'user' or 'assistant'
  content TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_messages_session_id ON messages(session_id);
CREATE INDEX idx_messages_user_id ON messages(user_id);
```

---

## 3. Row Level Security (RLS)

```sql
-- Enable RLS on all tables
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE benchmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Documents: Users can only see their own documents
CREATE POLICY "Users can view own documents"
  ON documents FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own documents"
  ON documents FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own documents"
  ON documents FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own documents"
  ON documents FOR DELETE
  USING (auth.uid() = user_id);

-- Similar policies for other tables...
```

---

## 4. Flutter Integration

### Step 1: Add Supabase Dependency

```yaml
dependencies:
  supabase_flutter: ^1.10.0
  supabase: ^1.10.0
```

### Step 2: Initialize Supabase

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://xxxxx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  );
  
  runApp(const MyApp());
}
```

### Step 3: Create Supabase Service

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  // Authentication
  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }
  
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  // Documents (RAG)
  Future<List<Map>> searchDocuments(
    List<double> embedding, {
    int limit = 5,
    String? category,
  }) async {
    final response = await _client.rpc(
      'search_documents',
      params: {
        'query_embedding': embedding,
        'match_count': limit,
        'filter_category': category,
      },
    );
    return List<Map>.from(response);
  }
  
  Future<void> addDocument({
    required String title,
    required String content,
    required List<double> embedding,
    required String source,
    required String category,
  }) async {
    await _client.from('documents').insert({
      'title': title,
      'content': content,
      'embedding': embedding,
      'source': source,
      'category': category,
    });
  }
  
  // Benchmarks
  Future<void> saveBenchmark({
    required String deviceName,
    required String modelId,
    required int loadTimeMs,
    required int ttftMs,
    required double decodeSpeed,
    required int peakRamMb,
  }) async {
    await _client.from('benchmarks').insert({
      'device_name': deviceName,
      'model_id': modelId,
      'load_time_ms': loadTimeMs,
      'ttft_ms': ttftMs,
      'decode_speed_tokens_per_sec': decodeSpeed,
      'peak_ram_mb': peakRamMb,
    });
  }
}
```

---

## 5. Node.js API Integration

### Embeddings Service

```typescript
// services/api/src/services/embeddings.ts
import { SupabaseClient } from '@supabase/supabase-js';

export class EmbeddingsService {
  constructor(private supabase: SupabaseClient) {}

  async generateEmbedding(text: string): Promise<number[]> {
    // Use sentence-transformers or similar
    // For now, placeholder
    return new Array(384).fill(0);
  }

  async addDocumentWithEmbedding(
    userId: string,
    title: string,
    content: string,
    source: string,
    category: string,
  ) {
    const embedding = await this.generateEmbedding(content);
    
    const { data, error } = await this.supabase
      .from('documents')
      .insert({
        user_id: userId,
        title,
        content,
        embedding,
        source,
        category,
      });
    
    if (error) throw error;
    return data;
  }

  async searchDocuments(
    userId: string,
    queryText: string,
    limit: number = 5,
  ) {
    const queryEmbedding = await this.generateEmbedding(queryText);
    
    const { data, error } = await this.supabase.rpc(
      'search_documents',
      {
        query_embedding: queryEmbedding,
        match_count: limit,
        user_id: userId,
      },
    );
    
    if (error) throw error;
    return data;
  }
}
```

### API Endpoints

```typescript
// services/api/src/routes/documents.ts
import express from 'express';
import { EmbeddingsService } from '../services/embeddings';

const router = express.Router();
const embeddings = new EmbeddingsService(supabaseClient);

// Add document
router.post('/documents', async (req, res) => {
  const { title, content, source, category } = req.body;
  const userId = req.user.id;
  
  try {
    const doc = await embeddings.addDocumentWithEmbedding(
      userId,
      title,
      content,
      source,
      category,
    );
    res.json(doc);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Search documents
router.post('/documents/search', async (req, res) => {
  const { query, limit } = req.body;
  const userId = req.user.id;
  
  try {
    const results = await embeddings.searchDocuments(
      userId,
      query,
      limit || 5,
    );
    res.json(results);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
```

---

## 6. Real-time Sync

### Flutter Real-time Listener

```dart
class RealtimeDocumentListener {
  final SupabaseClient _client = Supabase.instance.client;
  
  void listenToDocuments(String userId) {
    _client
      .from('documents')
      .on(RealtimeListenTypes.all, (payload) {
        print('Document changed: ${payload.eventType}');
        print('New data: ${payload.newRecord}');
        
        // Update local state
        _handleDocumentChange(payload);
      })
      .eq('user_id', userId)
      .subscribe();
  }
  
  void _handleDocumentChange(RealtimeMessage payload) {
    // Update UI or local cache
  }
}
```

---

## 7. Offline Support

### Offline-First Strategy

```dart
class OfflineDocumentManager {
  final _localDb = RAGService();  // Local SQLite
  final _supabase = SupabaseService();
  
  Future<void> addDocumentOffline(Document doc) async {
    // Save locally first
    await _localDb.addDocument(doc);
    
    // Try to sync with Supabase
    try {
      await _supabase.addDocument(
        title: doc.title,
        content: doc.content,
        embedding: doc.embedding,
        source: doc.source,
        category: doc.category,
      );
    } catch (e) {
      // Mark as pending sync
      print('Offline: Will sync when online');
    }
  }
  
  Future<void> syncPendingChanges() async {
    // Get pending documents from local DB
    // Upload to Supabase
    // Mark as synced
  }
}
```

---

## 8. Security Considerations

### Environment Variables

```bash
# .env (never commit)
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### API Key Management

- **Anon Key:** Used in Flutter app (public)
- **Service Key:** Used in Node.js API (secret, never expose)
- **RLS Policies:** Enforce data access control

### Data Protection

- ✓ Row-level security (RLS)
- ✓ JWT authentication
- ✓ Encrypted connections (HTTPS/WSS)
- ✓ Password hashing (bcrypt)
- ✓ No sensitive data in logs

---

## 9. Migration Path

### Phase 1: Local SQLite (Current)
- ✓ App works offline
- ✓ No backend required
- ✓ Fast local queries

### Phase 2: Supabase Integration (This Week)
- Add Supabase client
- Sync documents to cloud
- Real-time updates
- Offline support

### Phase 3: Full Cloud (Future)
- Migrate all data to Supabase
- Deprecate local SQLite
- Cloud-first architecture

---

## 10. Cost Estimation

### Supabase Pricing (as of 2026)

| Tier | Cost | Included |
|------|------|----------|
| Free | $0 | 500MB DB, 1GB storage, 50K req/month |
| Pro | $25/month | 8GB DB, 100GB storage, unlimited requests |
| Enterprise | Custom | Custom limits, SLA, support |

**Librio Estimate (Phase 1):**
- Documents: ~100MB (1000 documents × 100KB)
- Storage: ~2.4GB (models)
- Requests: ~1000/month (development)
- **Recommendation:** Free tier for Phase 1, upgrade to Pro for Phase 2

---

## 11. Implementation Timeline

| Task | Duration | Status |
|------|----------|--------|
| Supabase project setup | 30 min | Ready |
| Database schema creation | 1 hour | Ready |
| Flutter integration | 2 hours | Pending |
| Node.js API integration | 2 hours | Pending |
| Real-time sync | 2 hours | Pending |
| Offline support | 2 hours | Pending |
| Testing & validation | 2 hours | Pending |
| **Total** | **~11 hours** | **In Progress** |

---

## 12. Success Criteria

- ✓ Supabase project created
- ✓ Database schema deployed
- ✓ Flutter app connects to Supabase
- ✓ Documents sync to cloud
- ✓ Real-time updates working
- ✓ Offline mode functional
- ✓ All tests passing
- ✓ No sensitive data exposed

---

## Next Steps

1. **Create Supabase Project** (30 min)
2. **Deploy Database Schema** (1 hour)
3. **Implement Flutter Integration** (2 hours)
4. **Test Sync & Offline** (2 hours)
5. **Document & Deploy** (1 hour)

---

Generated: 2026-08-22
