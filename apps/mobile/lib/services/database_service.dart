import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/conversation.dart';

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
      
      if (kDebugMode) {
        print('📦 Initializing database at: $path');
      }
      
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ Database initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Database initialization failed: $e');
      }
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
      
      if (kDebugMode) {
        print('✅ Database tables created');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to create tables: $e');
      }
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
      
      if (kDebugMode) {
        print('✅ Conversation created: $id');
      }
      
      return conversation;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to create conversation: $e');
      }
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
      if (kDebugMode) {
        print('❌ Failed to get conversations: $e');
      }
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
      if (kDebugMode) {
        print('❌ Failed to get conversation: $e');
      }
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
      
      if (kDebugMode) {
        print('✅ Conversation updated: ${conversation.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update conversation: $e');
      }
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
      
      if (kDebugMode) {
        print('✅ Conversation deleted: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to delete conversation: $e');
      }
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
      
      if (kDebugMode) {
        print('✅ Message added: $id');
      }
      
      return message;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to add message: $e');
      }
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
      if (kDebugMode) {
        print('❌ Failed to get messages: $e');
      }
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
      
      if (kDebugMode) {
        print('✅ Messages deleted for conversation: $conversationId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to delete messages: $e');
      }
      rethrow;
    }
  }
  
  /// Close database
  Future<void> close() async {
    try {
      await _database.close();
      _isInitialized = false;
      
      if (kDebugMode) {
        print('✅ Database closed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to close database: $e');
      }
      rethrow;
    }
  }
}
