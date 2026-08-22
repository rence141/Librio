import '../utils/debug_logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/conversation.dart';
import '../models/document.dart';

/// Database service for managing conversations and messages
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  
  factory DatabaseService() {
    return _instance;
  }
  
  DatabaseService._internal();
  
  late Database _database;
  bool _isInitialized = false;
  
  /// Initialize the database
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'librio.db');
      
      DebugLogger.info("DatabaseService", "Initializing database at: $path");
      
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
      
      _isInitialized = true;
      
      DebugLogger.success("DatabaseService", "Database initialized successfully");
    } catch (e) {
      DebugLogger.error("DatabaseService", "Database initialization failed: $e");
      rethrow;
    }
  }
  
  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    try {
      // Create conversations table
      await db.execute('''
        CREATE TABLE conversations (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      
      // Create messages table
      await db.execute('''
        CREATE TABLE messages (
          id TEXT PRIMARY KEY,
          conversation_id TEXT NOT NULL,
          content TEXT NOT NULL,
          is_user INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY(conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
        )
      ''');
      
      // Create index for faster queries
      await db.execute('''
        CREATE INDEX idx_messages_conversation_id 
        ON messages(conversation_id)
      ''');
      
      // Create documents table for RAG
      await db.execute('''
        CREATE TABLE documents (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          embedding TEXT NOT NULL,
          source TEXT NOT NULL,
          category TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      
      // Create indexes for documents
      await db.execute('''
        CREATE INDEX idx_documents_category 
        ON documents(category)
      ''');
      
      await db.execute('''
        CREATE INDEX idx_documents_source 
        ON documents(source)
      ''');
      
      DebugLogger.success("DatabaseService", "Database tables created");
    } catch (e) {
      DebugLogger.error("DatabaseService", "Failed to create tables: $e");
      rethrow;
    }
  }
  
  /// Create a new conversation
  Future<Conversation> createConversation(String title) async {
    try {
      final now = DateTime.now();
      final id = 'conv_${now.millisecondsSinceEpoch}';
      
      final conversation = Conversation(
        id: id,
        title: title,
        createdAt: now,
        updatedAt: now,
      );
      
      await _database.insert(
        'conversations',
        conversation.toJson(),
      );
      
      DebugLogger.success("DatabaseService", "Conversation created: $id");
      
      return conversation;
    } catch (e) {
      DebugLogger.error("DatabaseService", "Failed to create conversation: $e");
      rethrow;
    }
  }
  
  /// Get all conversations
  Future<List<Conversation>> getConversations() async {
    try {
      final results = await _database.query(
        'conversations',
        orderBy: 'updated_at DESC',
      );
      
      return results.map((row) => Conversation.fromJson(row)).toList();
    } catch (e) {
      DebugLogger.error("DatabaseService", "Failed to get conversations: $e");
      rethrow;
    }
  }
  
  /// Get a specific conversation
  Future<Conversation?> getConversation(String id) async {
    try {
      final results = await _database.query(
        'conversations',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (results.isEmpty) return null;
      
      return Conversation.fromJson(results.first);
    } catch (e) {
      DebugLogger.error("DatabaseService", "Failed to get conversation: $e");
      rethrow;
    }
  }
  
  /// Update conversation
  Future<void> updateConversation(Conversation conversation) async {
    try {
      await _database.update(
        'conversations',
        conversation.copyWith(updatedAt: DateTime.now()).toJson(),
        where: 'id = ?',
        whereArgs: [conversation.id],
      );
      
      DebugLogger.success("DatabaseService", "Conversation updated: ${conversation.id}");
    } catch (e) {
      DebugLogger.error("DatabaseService", "Failed to update conversation: $e");
      rethrow;
    }
  }
  
  /// Delete conversation
  Future<void> deleteConversation(String id) async {
    try {
      await _database.delete(
        'conversations',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      DebugLogger.success("DatabaseService", "Conversation deleted: $id");
    } catch (e) {
      DebugLogger.error("DatabaseService", "Failed to delete conversation: $e");
      rethrow;
    }
  }
  
  /// Add a message to a conversation
  Future<Message> addMessage(
    String conversationId,
    String content,
    bool isUser,
  ) async {
    try {
      final now = DateTime.now();
      final id = 'msg_${now.millisecondsSinceEpoch}';
      
      final message = Message(
        id: id,
        conversationId: conversationId,
        content: content,
        isUser: isUser,
        createdAt: now,
      );
      
      await _database.insert(
        'messages',
        message.toJson(),
      );
      
      // Update conversation's updated_at timestamp
      await _database.update(
        'conversations',
        {'updated_at': now.toIso8601String()},
        where: 'id = ?',
        whereArgs: [conversationId],
      );
      
      DebugLogger.success("DatabaseService", "Message added: $id");
      
      return message;
    } catch (e) {
      DebugLogger.error("DatabaseService", "Failed to add message: $e");
      rethrow;
    }
  }
  
  /// Get messages for a conversation
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final results = await _database.query(
        'messages',
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
        orderBy: 'created_at ASC',
      );
      
      return results.map((row) => Message.fromJson(row)).toList();
    } catch (e) {
      DebugLogger.error("DatabaseService", "Failed to get messages: $e");
      rethrow;
    }
  }
  
  /// Delete all messages in a conversation
  Future<void> deleteMessages(String conversationId) async {
    try {
      await _database.delete(
        'messages',
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
      );
      
      DebugLogger.success("DatabaseService", "Messages deleted for conversation: $conversationId");
    } catch (e) {
      DebugLogger.error("DatabaseService", "Failed to delete messages: $e");
      rethrow;
    }
  }
  
  /// Add a document to the knowledge base
  Future<void> addDocument(Document document) async {
    try {
      await _database.insert(
        'documents',
        document.toJson(),
      );
      
      DebugLogger.success("DatabaseService", "Document added: ${document.id}");
    } catch (e) {
      DebugLogger.error("DatabaseService", "Failed to add document: $e");
      rethrow;
    }
  }
  
  /// Get documents from knowledge base
  Future<List<Document>> getDocuments({String? category}) async {
    try {
      List<Map<String, dynamic>> results;
      
      if (category != null) {
        results = await _database.query(
          'documents',
          where: 'category = ?',
          whereArgs: [category],
          orderBy: 'created_at DESC',
        );
      } else {
        results = await _database.query(
          'documents',
          orderBy: 'created_at DESC',
        );
      }
      
      return results.map((row) => Document.fromJson(row)).toList();
    } catch (e) {
      DebugLogger.error("DatabaseService", "Failed to get documents: $e");
      rethrow;
    }
  }
  
  /// Get a specific document
  Future<Document?> getDocument(String id) async {
    try {
      final results = await _database.query(
        'documents',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (results.isEmpty) return null;
      
      return Document.fromJson(results.first);
    } catch (e) {
      DebugLogger.error("DatabaseService", "Failed to get document: $e");
      rethrow;
    }
  }
  
  /// Delete a document
  Future<void> deleteDocument(String id) async {
    try {
      await _database.delete(
        'documents',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      DebugLogger.success("DatabaseService", "Document deleted: $id");
    } catch (e) {
      DebugLogger.error("DatabaseService", "Failed to delete document: $e");
      rethrow;
    }
  }
  
  /// Clear all documents
  Future<void> clearDocuments() async {
    try {
      await _database.delete('documents');
      
      DebugLogger.success("DatabaseService", "All documents cleared");
    } catch (e) {
      DebugLogger.error("DatabaseService", "Failed to clear documents: $e");
      rethrow;
    }
  }
  
  /// Close database
  Future<void> close() async {
    try {
      await _database.close();
      _isInitialized = false;
      
      DebugLogger.success("DatabaseService", "Database closed");
    } catch (e) {
      DebugLogger.error("DatabaseService", "Failed to close database: $e");
      rethrow;
    }
  }
}