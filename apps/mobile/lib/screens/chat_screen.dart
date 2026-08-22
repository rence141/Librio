import 'package:flutter/material.dart';
import '../services/llm_service.dart';
import '../services/database_service.dart';
import '../services/rag_service.dart';
import '../services/embeddings_service.dart';
import '../services/document_upload_service.dart';
import '../models/conversation.dart';
import '../utils/debug_logger.dart';
import 'documents_screen.dart';

/// Chat screen - Main interface for Librio
class ChatScreen extends StatefulWidget {
  final LlmService llmService;

  const ChatScreen({
    super.key,
    required this.llmService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final List<Conversation> _conversations = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  late DatabaseService _databaseService;
  late RagService _ragService;
  late EmbeddingsService _embeddingsService;
  late DocumentUploadService _uploadService;
  late Conversation _currentConversation;
  bool _isInitialized = false;

  // Official Librio colors
  static const Color _deepPurple = Color(0xFF7B2CBF);
  static const Color _indigo = Color(0xFF4F46E5);
  static const Color _brightBlue = Color(0xFF3B82F6);
  static const Color _cyan = Color(0xFF06B6D4);

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    const tag = 'ChatScreen';
    try {
      DebugLogger.info(tag, 'Initializing database...');
      _databaseService = DatabaseService();
      await _databaseService.initialize();

      DebugLogger.info(tag, 'Initializing embeddings and RAG...');
      _embeddingsService = EmbeddingsService();
      _ragService = RagService();
      await _ragService.initialize(_databaseService, _embeddingsService);

      DebugLogger.info(tag, 'Initializing document upload service...');
      _uploadService = DocumentUploadService();
      await _uploadService.initialize(_ragService);

      DebugLogger.info(tag, 'Loading conversations...');
      await _loadConversations();

      if (_conversations.isEmpty) {
        DebugLogger.info(tag, 'No conversations found, creating new one...');
        _currentConversation = await _databaseService.createConversation('New Chat');
        _addWelcomeMessage();
      } else {
        DebugLogger.info(tag, 'Found ${_conversations.length} conversations, loading most recent...');
        _currentConversation = _conversations.first;
        await _loadConversationHistory();
      }

      DebugLogger.success(tag, 'Initialization complete');
      setState(() => _isInitialized = true);
    } catch (e, st) {
      DebugLogger.error(tag, 'Initialization failed', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database error: $e')),
        );
      }
    }
  }

  Future<void> _loadConversations() async {
    const tag = 'ChatScreen';
    try {
      final conversations = await _databaseService.getConversations();
      DebugLogger.info(tag, 'Loaded ${conversations.length} conversations');
      setState(() {
        _conversations.clear();
        _conversations.addAll(conversations);
      });
    } catch (e, st) {
      DebugLogger.error(tag, 'Failed to load conversations', e, st);
    }
  }

  Future<void> _loadConversationHistory() async {
    const tag = 'ChatScreen';
    try {
      DebugLogger.info(tag, 'Loading history for conversation: ${_currentConversation.id}');
      final messages = await _databaseService.getMessages(_currentConversation.id);
      DebugLogger.info(tag, 'Loaded ${messages.length} messages');

      setState(() {
        _messages.clear();
        for (final msg in messages) {
          _messages.add(
            ChatMessage(
              text: msg.content,
              isUser: msg.isUser,
              timestamp: msg.createdAt,
            ),
          );
        }
      });

      _scrollToBottom();
    } catch (e, st) {
      DebugLogger.error(tag, 'Failed to load history', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: $e')),
        );
      }
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      text:
          'Hello! I\'m Librio, your AI academic tutor. Ask me anything about math, science, or other subjects.',
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(welcomeMessage);
    });

    _databaseService.addMessage(
      _currentConversation.id,
      welcomeMessage.text,
      false,
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    final userChatMessage = ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userChatMessage);
      _isLoading = true;
    });

    await _databaseService.addMessage(
      _currentConversation.id,
      userMessage,
      true,
    );

    _scrollToBottom();

    try {
      final documents = await _ragService.retrieveContext(userMessage);

      String prompt = userMessage;
      if (documents.isNotEmpty) {
        prompt = _ragService.buildPromptWithContext(userMessage, documents);
      }

      final response = await widget.llmService.generateResponse(prompt);

      final aiChatMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiChatMessage);
        _isLoading = false;
      });

      await _databaseService.addMessage(
        _currentConversation.id,
        response,
        false,
      );

      _scrollToBottom();
    } catch (e, st) {
      DebugLogger.error('ChatScreen', 'Failed to send message', e, st);
      final errorMessage = ChatMessage(
        text: 'Sorry, I encountered an error: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
      });

      await _databaseService.addMessage(
        _currentConversation.id,
        errorMessage.text,
        false,
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openDocumentsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentsScreen(
          ragService: _ragService,
          uploadService: _uploadService,
        ),
      ),
    );
  }

  Future<void> _startNewConversation() async {
    const tag = 'ChatScreen';
    try {
      DebugLogger.info(tag, 'Creating new conversation...');
      final newConversation = await _databaseService.createConversation('New Chat');
      DebugLogger.success(tag, 'New conversation created: ${newConversation.id}');
      setState(() {
        _currentConversation = newConversation;
        _messages.clear();
      });
      _addWelcomeMessage();
      await _loadConversations();
      if (mounted) Navigator.pop(context);
    } catch (e, st) {
      DebugLogger.error(tag, 'Failed to create conversation', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create conversation: $e')),
        );
      }
    }
  }

  Future<void> _selectConversation(Conversation conversation) async {
    setState(() {
      _currentConversation = conversation;
      _messages.clear();
    });
    await _loadConversationHistory();
    if (mounted) Navigator.pop(context); // Close drawer
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    const tag = 'ChatScreen';
    try {
      DebugLogger.info(tag, 'Deleting conversation: ${conversation.id}');
      await _databaseService.deleteConversation(conversation.id);
      await _loadConversations();

      if (conversation.id == _currentConversation.id) {
        if (_conversations.isEmpty) {
          DebugLogger.info(tag, 'No conversations left, creating new one...');
          _currentConversation = await _databaseService.createConversation('New Chat');
          setState(() => _messages.clear());
          _addWelcomeMessage();
        } else {
          _currentConversation = _conversations.first;
          await _loadConversationHistory();
        }
      }
      DebugLogger.success(tag, 'Conversation deleted');
    } catch (e, st) {
      DebugLogger.error(tag, 'Failed to delete conversation', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Future<void> _clearConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Conversation'),
        content: const Text('Are you sure you want to clear this conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      const tag = 'ChatScreen';
      try {
        DebugLogger.info(tag, 'Clearing conversation: ${_currentConversation.id}');
        await _databaseService.deleteMessages(_currentConversation.id);
        setState(() {
          _messages.clear();
        });
        _addWelcomeMessage();
        DebugLogger.success(tag, 'Conversation cleared');
      } catch (e, st) {
        DebugLogger.error(tag, 'Failed to clear conversation', e, st);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to clear: $e')),
          );
        }
      }
    }
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatConversationDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_deepPurple, _cyan],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      drawer: _buildHistoryDrawer(),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [_deepPurple, _indigo, _brightBlue, _cyan],
              stops: [0.0, 0.33, 0.66, 1.0],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Chat history',
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) => _buildLogoFallback(32),
            ),
            const SizedBox(width: 12),
            const Text(
              'Librio',
              style: TextStyle(
                fontFamily: 'Fredoka',
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.library_books, color: Colors.white),
            onPressed: _openDocumentsScreen,
            tooltip: 'Knowledge base',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _clearConversation,
            tooltip: 'Clear conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          if (_isLoading) _buildLoadingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildLogoFallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_deepPurple, _cyan],
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Center(
        child: Text(
          'L',
          style: TextStyle(
            fontFamily: 'Fredoka',
            color: Colors.white,
            fontSize: size * 0.56,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Header with gradient
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [_deepPurple, _indigo, _brightBlue, _cyan],
                stops: [0.0, 0.33, 0.66, 1.0],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      height: 36,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildLogoFallback(36),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Librio',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Conversation History',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // New chat button
          ListTile(
            leading: const Icon(Icons.add_circle, color: _deepPurple),
            title: const Text(
              'New Chat',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: _startNewConversation,
          ),
          const Divider(height: 1),
          // Conversations list
          Expanded(
            child: _conversations.isEmpty
                ? const Center(
                    child: Text(
                      'No conversations yet',
                      style: TextStyle(fontFamily: 'Fredoka', color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conv = _conversations[index];
                      final isActive = conv.id == _currentConversation.id;
                      return Dismissible(
                        key: ValueKey(conv.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteConversation(conv),
                        child: ListTile(
                          leading: Icon(
                            Icons.chat_bubble_outline,
                            color: isActive ? _deepPurple : Colors.grey[400],
                          ),
                          title: Text(
                            conv.title,
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight:
                                  isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive ? _deepPurple : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            _formatConversationDate(conv.updatedAt),
                            style: const TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 12,
                            ),
                          ),
                          trailing: isActive
                              ? const Icon(Icons.arrow_right, color: _deepPurple)
                              : null,
                          onTap: () => _selectConversation(conv),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_deepPurple, _cyan],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Librio is thinking...',
            style: TextStyle(
              fontFamily: 'Fredoka',
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ask me anything...',
                  hintStyle: TextStyle(
                    fontFamily: 'Fredoka',
                    color: Colors.grey[500],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [_deepPurple, _cyan],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _deepPurple.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send),
              color: Colors.white,
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Colors.white],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                width: 120,
                height: 120,
                errorBuilder: (context, error, stackTrace) =>
                    _buildLogoFallback(120),
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [_deepPurple, _cyan],
                ).createShader(bounds),
                child: const Text(
                  'Welcome to Librio',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your AI academic tutor',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Ask me anything about:',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildSuggestionChip('📐 Math'),
                  _buildSuggestionChip('🔬 Science'),
                  _buildSuggestionChip('📚 History'),
                  _buildSuggestionChip('🌍 Geography'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_deepPurple, _cyan],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _deepPurple.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_deepPurple, _cyan],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Image.asset(
                  'assets/logo.png',
                  width: 20,
                  height: 20,
                  errorBuilder: (context, error, stackTrace) => const Text(
                    'L',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [_deepPurple, _cyan],
                      )
                    : null,
                color: message.isUser ? null : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      color: message.isUser
                          ? Colors.white70
                          : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
