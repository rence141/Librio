import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/llm_service.dart';
import '../services/database_service.dart';
import '../services/rag_service.dart';
import '../services/embeddings_service.dart';
import '../services/document_upload_service.dart';
import '../models/conversation.dart';
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
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  late DatabaseService _databaseService;
  late RagService _ragService;
  late EmbeddingsService _embeddingsService;
  late DocumentUploadService _uploadService;
  late Conversation _currentConversation;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      _databaseService = DatabaseService();
      await _databaseService.initialize();
      
      // Initialize embeddings and RAG
      _embeddingsService = EmbeddingsService();
      _ragService = RagService();
      await _ragService.initialize(_databaseService, _embeddingsService);
      
      // Initialize document upload service
      _uploadService = DocumentUploadService();
      await _uploadService.initialize(_ragService);
      
      // Create or get the current conversation
      final conversations = await _databaseService.getConversations();
      
      if (conversations.isEmpty) {
        // Create a new conversation
        _currentConversation = await _databaseService.createConversation('Chat');
        _addWelcomeMessage();
      } else {
        // Use the most recent conversation
        _currentConversation = conversations.first;
        await _loadConversationHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database error: $e')),
        );
      }
    }
  }

  Future<void> _loadConversationHistory() async {
    try {
      final messages = await _databaseService.getMessages(_currentConversation.id);
      
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: $e')),
        );
      }
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      text: 'Hello! I\'m Librio, your AI academic tutor. Ask me anything about math, science, or other subjects.',
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(welcomeMessage);
    });
    
    // Save welcome message to database
    _databaseService.addMessage(
      _currentConversation.id,
      welcomeMessage.text,
      false,
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text;
    _messageController.clear();

    final userChatMessage = ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Add user message
    setState(() {
      _messages.add(userChatMessage);
      _isLoading = true;
    });

    // Save user message to database
    await _databaseService.addMessage(
      _currentConversation.id,
      userMessage,
      true,
    );

    _scrollToBottom();

    try {
      // Retrieve context from knowledge base
      final documents = await _ragService.retrieveContext(userMessage);
      
      // Build prompt with context
      String prompt = userMessage;
      if (documents.isNotEmpty) {
        prompt = _ragService.buildPromptWithContext(userMessage, documents);
      }
      
      // Get response from LLM
      final response = await widget.llmService.generateResponse(prompt);

      final aiChatMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      // Add AI response
      setState(() {
        _messages.add(aiChatMessage);
        _isLoading = false;
      });

      // Save AI response to database
      await _databaseService.addMessage(
        _currentConversation.id,
        response,
        false,
      );

      _scrollToBottom();
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'Sorry, I encountered an error: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
      });

      // Save error message to database
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
      try {
        await _databaseService.deleteMessages(_currentConversation.id);
        setState(() {
          _messages.clear();
        });
        _addWelcomeMessage();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to clear: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF7B2CBF), // Deep Purple
                Color(0xFF4F46E5), // Indigo
                Color(0xFF3B82F6), // Bright Blue
                Color(0xFF06B6D4), // Cyan
              ],
              stops: [0.0, 0.33, 0.66, 1.0],
            ),
          ),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                // Fallback: Gradient circle with "L"
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF7B2CBF),
                        Color(0xFF06B6D4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'L',
                      style: GoogleFonts.fredoka(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              'Librio',
              style: GoogleFonts.fredoka(
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
            icon: const Icon(Icons.library_books, color: Colors.black87),
            onPressed: _openDocumentsScreen,
            tooltip: 'Knowledge base',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.black87),
            onPressed: _clearConversation,
            tooltip: 'Clear conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
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
          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue[600]!,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Librio is thinking...',
                    style: GoogleFonts.fredoka(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything...',
                        hintStyle: GoogleFonts.fredoka(color: Colors.grey[500]),
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
                      colors: [
                        Color(0xFF7B2CBF), // Deep Purple
                        Color(0xFF06B6D4), // Cyan
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B2CBF).withValues(alpha: 0.3),
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
          colors: [
            Color(0xFFF8FAFC), // Soft White
            Color(0xFFFFFFFF), // White
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                // Fallback: Gradient circle with "L"
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF7B2CBF),
                        Color(0xFF06B6D4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'L',
                      style: GoogleFonts.fredoka(
                        color: Colors.white,
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF7B2CBF),
                  Color(0xFF06B6D4),
                ],
              ).createShader(bounds),
              child: Text(
                'Welcome to Librio',
                style: GoogleFonts.fredoka(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your AI academic tutor',
              style: GoogleFonts.fredoka(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Ask me anything about:',
              style: GoogleFonts.fredoka(
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
    );
  }

  Widget _buildSuggestionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF7B2CBF), // Deep Purple
            Color(0xFF06B6D4), // Cyan
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B2CBF).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.fredoka(
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
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Image.asset(
                  'assets/logo.png',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.blue[600] : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: GoogleFonts.fredoka(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: GoogleFonts.fredoka(
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}

/// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
