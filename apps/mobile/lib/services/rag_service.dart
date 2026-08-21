import 'dart:typed_data';
import 'package:sqlite3/sqlite3.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Document in the knowledge base
class Document {
  final int? id;
  final String title;
  final String content;
  final List<double> embedding;
  final String source;
  final String category;
  final DateTime createdAt;

  Document({
    this.id,
    required this.title,
    required this.content,
    required this.embedding,
    required this.source,
    required this.category,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Calculate cosine similarity with another embedding
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Embeddings must have same dimension');
    }

    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    normA = normA > 0 ? normA.sqrt() : 1;
    normB = normB > 0 ? normB.sqrt() : 1;

    return dotProduct / (normA * normB);
  }
}

/// RAG Service for retrieval-augmented generation
class RAGService {
  late Database _db;
  late Directory _dbDir;
  static const String _dbName = 'librio_rag.db';
  static const int _embeddingDim = 384; // all-MiniLM-L6-v2 dimension

  /// Initialize RAG service
  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _dbDir = Directory('${appDir.path}/rag');

    if (!_dbDir.existsSync()) {
      _dbDir.createSync(recursive: true);
    }

    final dbPath = '${_dbDir.path}/$_dbName';
    _db = sqlite3.open(dbPath);

    _createTables();
  }

  /// Create database tables
  void _createTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        embedding BLOB NOT NULL,
        source TEXT NOT NULL,
        category TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_category ON documents(category)
    ''');

    _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_source ON documents(source)
    ''');

    _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_created_at ON documents(created_at)
    ''');
  }

  /// Add a document to the knowledge base
  Future<int> addDocument(Document doc) async {
    final stmt = _db.prepare('''
      INSERT INTO documents (title, content, embedding, source, category)
      VALUES (?, ?, ?, ?, ?)
    ''');

    try {
      stmt.bind([
        doc.title,
        doc.content,
        _embeddingToBlob(doc.embedding),
        doc.source,
        doc.category,
      ]);

      stmt.step();
      final id = _db.lastInsertRowid;
      return id.toInt();
    } finally {
      stmt.dispose();
    }
  }

  /// Search for similar documents
  Future<List<Document>> search(
    List<double> queryEmbedding, {
    int topK = 5,
    String? category,
    double similarityThreshold = 0.5,
  }) async {
    final query = category != null
        ? 'SELECT * FROM documents WHERE category = ? ORDER BY created_at DESC'
        : 'SELECT * FROM documents ORDER BY created_at DESC';

    final stmt = _db.prepare(query);
    try {
      if (category != null) {
        stmt.bind([category]);
      }

      final results = <Document>[];
      final similarities = <double>[];

      while (stmt.step()) {
        final row = stmt.getRow();
        final embedding = _blobToEmbedding(row['embedding'] as Uint8List);
        final similarity = Document.cosineSimilarity(queryEmbedding, embedding);

        if (similarity >= similarityThreshold) {
          results.add(Document(
            id: row['id'] as int,
            title: row['title'] as String,
            content: row['content'] as String,
            embedding: embedding,
            source: row['source'] as String,
            category: row['category'] as String,
            createdAt: DateTime.parse(row['created_at'] as String),
          ));
          similarities.add(similarity);
        }
      }

      // Sort by similarity (descending) and return top K
      final indexed = List.generate(results.length, (i) => i);
      indexed.sort((a, b) => similarities[b].compareTo(similarities[a]));

      return indexed.take(topK).map((i) => results[i]).toList();
    } finally {
      stmt.dispose();
    }
  }

  /// Get all documents in a category
  Future<List<Document>> getDocumentsByCategory(String category) async {
    final stmt = _db.prepare(
      'SELECT * FROM documents WHERE category = ? ORDER BY created_at DESC',
    );

    try {
      stmt.bind([category]);

      final results = <Document>[];
      while (stmt.step()) {
        final row = stmt.getRow();
        results.add(Document(
          id: row['id'] as int,
          title: row['title'] as String,
          content: row['content'] as String,
          embedding: _blobToEmbedding(row['embedding'] as Uint8List),
          source: row['source'] as String,
          category: row['category'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
        ));
      }

      return results;
    } finally {
      stmt.dispose();
    }
  }

  /// Get document count
  Future<int> getDocumentCount() async {
    final result = _db.select('SELECT COUNT(*) as count FROM documents');
    return result.first['count'] as int;
  }

  /// Get document count by category
  Future<Map<String, int>> getDocumentCountByCategory() async {
    final result = _db.select(
      'SELECT category, COUNT(*) as count FROM documents GROUP BY category',
    );

    final counts = <String, int>{};
    for (final row in result) {
      counts[row['category'] as String] = row['count'] as int;
    }

    return counts;
  }

  /// Delete a document
  Future<void> deleteDocument(int id) async {
    _db.execute('DELETE FROM documents WHERE id = ?', [id]);
  }

  /// Clear all documents
  Future<void> clearAll() async {
    _db.execute('DELETE FROM documents');
  }

  /// Build RAG prompt with retrieved context
  String buildRAGPrompt(
    String query,
    List<Document> contextDocs,
  ) {
    final contextStr = contextDocs
        .asMap()
        .entries
        .map((e) => '''
[Document ${e.key + 1}]
Title: ${e.value.title}
Source: ${e.value.source}
Content: ${e.value.content}
''')
        .join('\n');

    return '''You are an academic tutor. Use the provided context to answer questions accurately and helpfully. If the context doesn't contain relevant information, say so.

Context:
$contextStr

User: $query''';
  }

  /// Convert embedding to blob for storage
  Uint8List _embeddingToBlob(List<double> embedding) {
    if (embedding.length != _embeddingDim) {
      throw ArgumentError(
        'Embedding must have $_embeddingDim dimensions, got ${embedding.length}',
      );
    }

    final buffer = ByteData(_embeddingDim * 8); // 8 bytes per double
    for (int i = 0; i < embedding.length; i++) {
      buffer.setFloat64(i * 8, embedding[i], Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  /// Convert blob back to embedding
  List<double> _blobToEmbedding(Uint8List blob) {
    if (blob.length != _embeddingDim * 8) {
      throw ArgumentError(
        'Blob must have ${_embeddingDim * 8} bytes, got ${blob.length}',
      );
    }

    final buffer = ByteData.view(blob.buffer);
    final embedding = <double>[];

    for (int i = 0; i < _embeddingDim; i++) {
      embedding.add(buffer.getFloat64(i * 8, Endian.little));
    }

    return embedding;
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getStats() async {
    final docCount = await getDocumentCount();
    final countByCategory = await getDocumentCountByCategory();

    return {
      'total_documents': docCount,
      'documents_by_category': countByCategory,
      'embedding_dimension': _embeddingDim,
      'database_path': '${_dbDir.path}/$_dbName',
    };
  }

  /// Close database
  void close() {
    _db.dispose();
  }
}
