import 'package:flutter/foundation.dart';
import '../models/document.dart';
import 'database_service.dart';
import 'embeddings_service.dart';

/// RAG (Retrieval-Augmented Generation) service for document-grounded responses
class RagService {
  static final RagService _instance = RagService._internal();
  
  factory RagService() {
    return _instance;
  }
  
  RagService._internal();
  
  late DatabaseService _databaseService;
  late EmbeddingsService _embeddingsService;
  bool _isInitialized = false;
  
  /// Initialize RAG service
  Future<void> initialize(
    DatabaseService databaseService,
    EmbeddingsService embeddingsService,
  ) async {
    if (_isInitialized) return;
    
    try {
      _databaseService = databaseService;
      _embeddingsService = embeddingsService;
      
      await _embeddingsService.initialize();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ RAG service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize RAG: $e');
      }
      rethrow;
    }
  }
  
  /// Add a document to the knowledge base
  Future<Document> addDocument({
    required String title,
    required String content,
    required String source,
    required String category,
  }) async {
    try {
      if (!_isInitialized) {
        throw Exception('RAG service not initialized');
      }
      
      // Generate embedding
      _embeddingsService.updateVocabulary(content);
      final embedding = _embeddingsService.embed(content);
      
      // Create document
      final now = DateTime.now();
      final id = 'doc_${now.millisecondsSinceEpoch}';
      
      final document = Document(
        id: id,
        title: title,
        content: content,
        embedding: embedding,
        source: source,
        category: category,
        createdAt: now,
      );
      
      // Save to database
      await _databaseService.addDocument(document);
      
      if (kDebugMode) {
        print('✅ Document added: $id');
      }
      
      return document;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to add document: $e');
      }
      rethrow;
    }
  }
  
  /// Retrieve relevant documents for a query
  Future<List<Document>> retrieveContext(
    String query, {
    int topK = 3,
    String? category,
    double similarityThreshold = 0.3,
  }) async {
    try {
      if (!_isInitialized) {
        throw Exception('RAG service not initialized');
      }
      
      // Generate query embedding
      _embeddingsService.updateVocabulary(query);
      final queryEmbedding = _embeddingsService.embed(query);
      
      // Get all documents
      final allDocuments = await _databaseService.getDocuments(category: category);
      
      if (allDocuments.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No documents found in knowledge base');
        }
        return [];
      }
      
      // Calculate similarity for each document
      for (final doc in allDocuments) {
        doc.similarity = _embeddingsService.cosineSimilarity(
          queryEmbedding,
          doc.embedding,
        );
      }
      
      // Sort by similarity (descending)
      allDocuments.sort((a, b) => b.similarity.compareTo(a.similarity));
      
      // Filter by threshold and return top-K
      final filtered = allDocuments
          .where((doc) => doc.similarity >= similarityThreshold)
          .take(topK)
          .toList();
      
      if (kDebugMode) {
        print('✅ Retrieved ${filtered.length} documents for query');
      }
      
      return filtered;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to retrieve context: $e');
      }
      rethrow;
    }
  }
  
  /// Build prompt with context
  String buildPromptWithContext(String query, List<Document> documents) {
    if (documents.isEmpty) {
      return query;
    }
    
    final contextBuilder = StringBuffer();
    contextBuilder.writeln('Based on the following information:');
    contextBuilder.writeln();
    
    for (int i = 0; i < documents.length; i++) {
      final doc = documents[i];
      contextBuilder.writeln('${i + 1}. ${doc.title}');
      contextBuilder.writeln('   ${doc.preview}');
      contextBuilder.writeln('   (Source: ${doc.source}, Similarity: ${(doc.similarity * 100).toStringAsFixed(1)}%)');
      contextBuilder.writeln();
    }
    
    contextBuilder.writeln('Question: $query');
    
    return contextBuilder.toString();
  }
  
  /// Get all documents
  Future<List<Document>> getAllDocuments({String? category}) async {
    try {
      return await _databaseService.getDocuments(category: category);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get documents: $e');
      }
      rethrow;
    }
  }
  
  /// Delete a document
  Future<void> deleteDocument(String id) async {
    try {
      await _databaseService.deleteDocument(id);
      
      if (kDebugMode) {
        print('✅ Document deleted: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to delete document: $e');
      }
      rethrow;
    }
  }
  
  /// Clear all documents
  Future<void> clearDocuments() async {
    try {
      await _databaseService.clearDocuments();
      
      if (kDebugMode) {
        print('✅ All documents cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to clear documents: $e');
      }
      rethrow;
    }
  }
  
  /// Get document count
  Future<int> getDocumentCount({String? category}) async {
    try {
      final documents = await _databaseService.getDocuments(category: category);
      return documents.length;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get document count: $e');
      }
      return 0;
    }
  }
}
