# Phase 1: RAG Layer Design & Implementation

**Status:** Design Phase  
**Date:** 2026-08-22

---

## Overview

The RAG (Retrieval-Augmented Generation) layer enables the LLM to provide grounded, factual responses by retrieving relevant context from a knowledge base before generating answers.

### Architecture

```
User Query
    ↓
[Embeddings Engine] → Generate query embedding (384-dim)
    ↓
[Vector Database] → Retrieve top-K similar documents
    ↓
[Context Builder] → Format retrieved docs as context
    ↓
[Prompt Template] → Build system + context + query
    ↓
[LLM] → Generate grounded response
    ↓
Response
```

---

## 1. Embeddings Model

### Selection: `all-MiniLM-L6-v2`

**Why this model?**
- ✓ Small (22 MB) - fits on mobile
- ✓ Fast inference (~10ms on CPU)
- ✓ Good quality (384-dimensional embeddings)
- ✓ Widely used and tested
- ✓ Available in GGUF format

**Specifications:**
- Model size: 22 MB
- Embedding dimension: 384
- Inference time: ~10-20ms per document
- Quantization: Q4_K_M (4-bit)

**Implementation Options:**

**Option A: Dart/Flutter (Recommended)**
- Use `sentence_transformers` Dart package (if available)
- Or embed Python service in app
- Pros: Single app, no external service
- Cons: Larger app size, more complex

**Option B: Python Service**
- Run embeddings service on backend
- Flutter app calls API
- Pros: Simpler, better performance
- Cons: Requires backend service

**Decision:** Option A (embedded in app) for Phase 1

---

## 2. Vector Database

### Selection: SQLite with Vector Extension

**Why SQLite?**
- ✓ No external dependencies
- ✓ Built-in to Android
- ✓ Fast for small-to-medium datasets
- ✓ Easy to backup and sync
- ✓ Supports vector similarity search

**Schema:**

```sql
CREATE TABLE documents (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  embedding BLOB NOT NULL,  -- 384-dim float32 (1536 bytes)
  source TEXT,              -- e.g., "wikipedia", "textbook"
  category TEXT,            -- e.g., "math", "science"
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_category ON documents(category);
CREATE INDEX idx_source ON documents(source);

-- Vector similarity search (using sqlite-vec extension)
CREATE VIRTUAL TABLE documents_vec USING vec0(
  embedding(384)
);
```

**Dart Implementation:**

```dart
import 'package:sqlite3/sqlite3.dart';

class VectorDatabase {
  late Database _db;
  
  Future<void> init() async {
    final dbPath = '${appDir.path}/librio.db';
    _db = sqlite3.open(dbPath);
    _createTables();
  }
  
  Future<void> addDocument(
    String title,
    String content,
    List<double> embedding,
    String source,
    String category,
  ) async {
    _db.execute(
      'INSERT INTO documents (title, content, embedding, source, category) '
      'VALUES (?, ?, ?, ?, ?)',
      [title, content, _embeddingToBlob(embedding), source, category],
    );
  }
  
  Future<List<Document>> search(
    List<double> queryEmbedding,
    int topK = 5,
    String? category,
  ) async {
    // Cosine similarity search
    final query = '''
      SELECT id, title, content, source, category,
             1 - (dot_product(embedding, ?) / (norm(embedding) * norm(?))) as distance
      FROM documents
      ${category != null ? 'WHERE category = ?' : ''}
      ORDER BY distance ASC
      LIMIT ?
    ''';
    
    final params = [
      _embeddingToBlob(queryEmbedding),
      _embeddingToBlob(queryEmbedding),
      if (category != null) category,
      topK,
    ];
    
    final results = _db.select(query, params);
    return results.map((row) => Document.fromRow(row)).toList();
  }
}
```

---

## 3. Retrieval Strategy

### Top-K Retrieval

**Parameters:**
- K = 3-5 documents
- Similarity threshold: 0.5 (cosine similarity)
- Filtering: By category if specified

**Ranking:**
1. Cosine similarity to query
2. Recency (prefer recent documents)
3. Source credibility (prefer textbooks over forums)

**Implementation:**

```dart
Future<List<Document>> retrieveContext(
  String query,
  {int topK = 5, String? category}
) async {
  // Generate query embedding
  final queryEmbedding = await _embeddingsEngine.embed(query);
  
  // Search vector database
  final documents = await _vectorDb.search(
    queryEmbedding,
    topK: topK,
    category: category,
  );
  
  // Filter by similarity threshold
  final filtered = documents
      .where((doc) => doc.similarity > 0.5)
      .toList();
  
  return filtered.isNotEmpty ? filtered : documents.take(topK).toList();
}
```

---

## 4. Context Building

### Prompt Template

```
System: You are an academic tutor. Use the provided context to answer questions accurately and helpfully.

Context:
[Document 1 - Title]
[Document 1 - Content excerpt]

[Document 2 - Title]
[Document 2 - Content excerpt]

[Document 3 - Title]
[Document 3 - Content excerpt]

User: [Query]