# Supabase Setup Guide

**Date:** 2026-08-22  
**Status:** Ready for Setup  
**Duration:** ~30 minutes

---

## Quick Start

### Step 1: Create Supabase Project (5 minutes)

1. Go to https://supabase.com
2. Click "Sign Up" or "Sign In"
3. Create new project:
   - **Project name:** `librio`
   - **Database password:** Generate strong password (save it!)
   - **Region:** Choose closest to your users (e.g., `us-east-1`)
4. Wait for project to initialize (~2 minutes)

### Step 2: Get Connection Details (2 minutes)

From Supabase dashboard:

1. Go to **Settings** → **API**
2. Copy these values:
   - **Project URL:** `https://xxxxx.supabase.co`
   - **Anon Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - **Service Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

3. Save to `.env` file:
```bash
# services/api/.env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Step 3: Enable Extensions (3 minutes)

1. Go to **SQL Editor**
2. Click **New Query**
3. Paste and run:

```sql
-- Enable pgvector for embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable full-text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

### Step 4: Create Database Schema (10 minutes)

1. Go to **SQL Editor**
2. Click **New Query**
3. Copy entire schema from `SUPABASE_INTEGRATION.md` (Section 2)
4. Paste and run all SQL

**Expected result:** All tables created successfully

### Step 5: Set Up Row-Level Security (5 minutes)

1. Go to **SQL Editor**
2. Click **New Query**
3. Copy RLS policies from `SUPABASE_INTEGRATION.md` (Section 3)
4. Paste and run all SQL

**Expected result:** All policies created successfully

### Step 6: Update Flutter App (3 minutes)

1. Open `apps/mobile/pubspec.yaml`
2. Add dependency:
```yaml
dependencies:
  supabase_flutter: ^1.10.0
```

3. Run `flutter pub get`

4. Update `apps/mobile/lib/main.dart`:
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

### Step 7: Update Node.js API (2 minutes)

1. Open `services/api/package.json`
2. Add dependency:
```json
{
  "dependencies": {
    "@supabase/supabase-js": "^2.38.0"
  }
}
```

3. Run `npm install`

4. Update `services/api/src/index.ts`:
```typescript
import supabaseRoutes from './routes/supabase.routes';

app.use('/api', supabaseRoutes);
```

---

## Verification

### Test Supabase Connection

**Flutter:**
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void testConnection() async {
  final client = Supabase.instance.client;
  
  try {
    final response = await client.from('documents').select().limit(1);
    print('✓ Connected to Supabase');
  } catch (e) {
    print('✗ Connection failed: $e');
  }
}
```

**Node.js:**
```bash
curl -X GET http://localhost:3000/api/stats \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Expected Response

```json
{
  "success": true,
  "data": {
    "documents": 0,
    "sessions": 0,
    "benchmarks": 0
  }
}
```

---

## Database Schema Overview

### Tables Created

| Table | Purpose | Rows |
|-------|---------|------|
| `documents` | RAG knowledge base | ~1000 |
| `user_profiles` | User information | ~100 |
| `benchmarks` | Performance metrics | ~500 |
| `sessions` | RAG conversations | ~1000 |
| `messages` | Chat history | ~10000 |

### Indexes Created

- `idx_documents_user_id` - Fast user document lookup
- `idx_documents_category` - Fast category filtering
- `idx_documents_embedding` - Fast similarity search
- `idx_documents_search` - Full-text search
- Similar indexes on other tables

---

## Security Setup

### Row-Level Security (RLS)

All tables have RLS enabled:
- Users can only see their own data
- No cross-user data leakage
- Enforced at database level

### Authentication

- JWT tokens from Supabase Auth
- Verified on every API request
- Service key for server-side operations

### Environment Variables

```bash
# Never commit these!
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_KEY=...
```

---

## Common Tasks

### Add a Document

**Flutter:**
```dart
await SupabaseService.addDocument(
  title: 'Photosynthesis',
  content: 'Process by which plants...',
  embedding: [...],  // 384-dim vector
  source: 'wikipedia',
  category: 'biology',
);
```

**Node.js:**
```bash
curl -X POST http://localhost:3000/api/documents \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "title": "Photosynthesis",
    "content": "Process by which plants...",
    "embedding": [...],
    "source": "wikipedia",
    "category": "biology"
  }'
```

### Search Documents

**Flutter:**
```dart
final results = await SupabaseService.searchDocuments(
  embedding: queryEmbedding,
  limit: 5,
  category: 'biology',
);
```

**Node.js:**
```bash
curl -X POST http://localhost:3000/api/documents/search \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "embedding": [...],
    "limit": 5,
    "category": "biology"
  }'
```

### Save Benchmark

**Flutter:**
```dart
await SupabaseService.saveBenchmark(
  deviceName: 'Infinix-Note50',
  modelId: 'gemma3-1b-q4',
  loadTimeMs: 1250,
  ttftMs: 85,
  decodeSpeed: 18.2,
  peakRamMb: 850,
);
```

---

## Troubleshooting

### Issue: "Extension not found"

**Solution:** Make sure you're running SQL in the correct database:
1. Go to **SQL Editor**
2. Select `postgres` database (top dropdown)
3. Run extension commands

### Issue: "RLS policy violation"

**Cause:** User trying to access data they don't own

**Solution:** Check RLS policies are correct:
```sql
SELECT * FROM pg_policies WHERE tablename = 'documents';
```

### Issue: "JWT token invalid"

**Cause:** Token expired or incorrect format

**Solution:** Generate new token:
```dart
final session = Supabase.instance.client.auth.currentSession;
final token = session?.accessToken;
```

### Issue: "Connection refused"

**Cause:** Supabase URL or key incorrect

**Solution:** Verify in `.env`:
```bash
echo $SUPABASE_URL
echo $SUPABASE_ANON_KEY
```

---

## Next Steps

1. **Complete Setup** - Follow steps 1-7 above
2. **Verify Connection** - Run verification tests
3. **Test Operations** - Add documents, search, save benchmarks
4. **Deploy to Device** - Test with Flutter app on Infinix-Note50
5. **Monitor Usage** - Check Supabase dashboard for stats

---

## Useful Links

- **Supabase Dashboard:** https://app.supabase.com
- **Supabase Docs:** https://supabase.com/docs
- **pgvector Docs:** https://github.com/pgvector/pgvector
- **Supabase Flutter:** https://supabase.com/docs/reference/flutter/introduction

---

## Cost Estimation

### Free Tier (Recommended for Phase 1)

- **Database:** 500 MB
- **Storage:** 1 GB
- **Bandwidth:** 2 GB/month
- **Requests:** 50,000/month
- **Cost:** $0

### Pro Tier (For Phase 2+)

- **Database:** 8 GB
- **Storage:** 100 GB
- **Bandwidth:** Unlimited
- **Requests:** Unlimited
- **Cost:** $25/month

---

## Support

If you encounter issues:

1. Check Supabase dashboard for errors
2. Review SQL Editor logs
3. Check `.env` file for correct credentials
4. Verify RLS policies are enabled
5. Check Flutter/Node.js logs for API errors

---

**Ready to set up? Start with Step 1!** 🚀

Generated: 2026-08-22
