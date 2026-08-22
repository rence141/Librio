/// Document model for RAG knowledge base
class Document {
  final String id;
  final String title;
  final String content;
  final List<double> embedding;
  final String source;
  final String category;
  final DateTime createdAt;
  double similarity;

  Document({
    required this.id,
    required this.title,
    required this.content,
    required this.embedding,
    required this.source,
    required this.category,
    required this.createdAt,
    this.similarity = 0.0,
  });

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'embedding': _embeddingToString(embedding),
      'source': source,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON from database
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      embedding: _stringToEmbedding(json['embedding'] as String),
      source: json['source'] as String,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      similarity: (json['similarity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Create a copy with optional field updates
  Document copyWith({
    String? id,
    String? title,
    String? content,
    List<double>? embedding,
    String? source,
    String? category,
    DateTime? createdAt,
    double? similarity,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      embedding: embedding ?? this.embedding,
      source: source ?? this.source,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      similarity: similarity ?? this.similarity,
    );
  }

  /// Get a preview of the content (first 200 chars)
  String get preview {
    if (content.length > 200) {
      return '${content.substring(0, 200)}...';
    }
    return content;
  }

  /// Convert embedding to string for storage
  static String _embeddingToString(List<double> embedding) {
    return embedding.join(',');
  }

  /// Convert string back to embedding
  static List<double> _stringToEmbedding(String embeddingStr) {
    return embeddingStr.split(',').map((e) => double.parse(e)).toList();
  }
}
