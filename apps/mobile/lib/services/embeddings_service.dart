import 'package:flutter/foundation.dart';
import 'dart:math';

/// Simple TF-IDF based embeddings service for lightweight RAG
class EmbeddingsService {
  static final EmbeddingsService _instance = EmbeddingsService._internal();
  
  factory EmbeddingsService() {
    return _instance;
  }
  
  EmbeddingsService._internal();
  
  late Map<String, int> _vocabulary;
  late List<String> _vocabularyList;
  bool _isInitialized = false;
  
  /// Initialize embeddings service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _vocabulary = {};
      _vocabularyList = [];
      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ Embeddings service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize embeddings: $e');
      }
      rethrow;
    }
  }
  
  /// Add text to vocabulary (call when documents are added)
  void updateVocabulary(String text) {
    final tokens = _tokenize(text);
    for (final token in tokens) {
      if (!_vocabulary.containsKey(token)) {
        _vocabulary[token] = _vocabularyList.length;
        _vocabularyList.add(token);
      }
    }
  }
  
  /// Generate embedding for text (TF-IDF based)
  List<double> embed(String text) {
    if (!_isInitialized) {
      throw Exception('Embeddings service not initialized');
    }
    
    final tokens = _tokenize(text);
    final embedding = List<double>.filled(_vocabularyList.length, 0.0);
    
    // Calculate TF (term frequency)
    final termFrequency = <String, int>{};
    for (final token in tokens) {
      termFrequency[token] = (termFrequency[token] ?? 0) + 1;
    }
    
    // Convert to embedding
    for (final entry in termFrequency.entries) {
      final token = entry.key;
      final frequency = entry.value;
      
      if (_vocabulary.containsKey(token)) {
        final index = _vocabulary[token]!;
        embedding[index] = frequency / tokens.length;
      }
    }
    
    // Normalize
    return _normalize(embedding);
  }
  
  /// Calculate cosine similarity between two embeddings.
  /// Handles different lengths by padding the shorter with zeros
  /// (missing dimensions are effectively 0 for the shorter embedding).
  double cosineSimilarity(List<double> a, List<double> b) {
    final maxLen = a.length > b.length ? a.length : b.length;

    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < maxLen; i++) {
      final va = i < a.length ? a[i] : 0.0;
      final vb = i < b.length ? b[i] : 0.0;
      dotProduct += va * vb;
      normA += va * va;
      normB += vb * vb;
    }

    normA = sqrt(normA);
    normB = sqrt(normB);

    if (normA == 0 || normB == 0) return 0;

    return dotProduct / (normA * normB);
  }
  
  /// Tokenize text into words
  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty && token.length > 2)
        .toList();
  }
  
  /// Normalize vector
  List<double> _normalize(List<double> vector) {
    double norm = 0;
    for (final value in vector) {
      norm += value * value;
    }
    norm = sqrt(norm);
    
    if (norm == 0) return vector;
    
    return vector.map((v) => v / norm).toList();
  }
  
  /// Get vocabulary size
  int get vocabularySize => _vocabularyList.length;
}
