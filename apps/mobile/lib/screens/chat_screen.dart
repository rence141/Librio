import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/llm_service.dart';
import '../services/model_loader.dart';
import '../services/database_service.dart';
import '../services/rag_service.dart';
import '../services/embeddings_service.dart';
import '../services/document_upload_service.dart';
import '../services/flashcard_generator.dart';
import '../models/conversation.dart';
import '../models/document.dart';
import '../utils/debug_logger.dart';
import '../widgets/crystal_loader.dart';
import '../widgets/llm_markdown.dart';
import 'documents_screen.dart';
import 'flashcard_review_screen.dart';

/// Chat screen — ChatGPT-inspired mobile UX for Librio
///
/// Design principles:
/// - Conversation is the product
/// - Minimal, clean, spacious, academic
/// - AI responses: open document-like layout (no bubbles)
/// - User messages: subtle background container
/// - Streaming with stop button
/// - Contextual study actions after AI responses
/// - Source/RAG display when materials are used
/// - Offline indicator (subtle, not an error)
class ChatScreen extends StatefulWidget {
  final LlmService llmService;

  const ChatScreen({super.key, required this.llmService});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final List<Conversation> _conversations = [];
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  bool _isGenerating = false;
  bool _isSearchingMaterials = false;
  bool _canStop = false;
  bool _isInitialized = false;
  bool _isOffline = true; // Default to offline (local model)

  // Generated flashcards from chat (pending save)
  List<ParsedFlashcard> _pendingFlashcards = [];
  bool _showFlashcardSavePrompt = false;

  late DatabaseService _databaseService;
  late RagService _ragService;
  late EmbeddingsService _embeddingsService;
  late DocumentUploadService _uploadService;
  late Conversation _currentConversation;

  // Model info
  String _currentModelName = 'Loading...';
  String _currentModelId = '';
  Map<String, bool> _installedModels = {};

  // Colors — used sparingly for accents only
  static const Color _deepPurple = Color(0xFF7B2CBF);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _surfaceColor = Color(0xFFF7F7F8);
  static const Color _userBubbleColor = Color(0xFFF0F0F3);

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    _messageController.addListener(() => setState(() {}));
  }

  Future<void> _initializeDatabase() async {
    const tag = 'ChatScreen';
    try {
      _databaseService = DatabaseService();
      await _databaseService.initialize();

      _embeddingsService = EmbeddingsService();
      _ragService = RagService();
      await _ragService.initialize(_databaseService, _embeddingsService);

      _uploadService = DocumentUploadService();
      await _uploadService.initialize(_ragService);

      await _loadConversations();

      if (_conversations.isEmpty) {
        _currentConversation = await _databaseService.createConversation('New Chat');
      } else {
        _currentConversation = _conversations.first;
        await _loadConversationHistory();
      }

      // Check model status
      _isOffline = !widget.llmService.isInitialized;

      // Load model info for selector
      final modelLoader = ModelLoader();
      _installedModels = await modelLoader.getAvailableModels();
      final info = await modelLoader.getModelInfo();
      _currentModelName = info['displayName'] as String? ?? 'Unknown';
      _currentModelId = modelLoader.selectedModel?.id ?? '';

      setState(() => _isInitialized = true);
    } catch (e, st) {
      DebugLogger.error(tag, 'Initialization failed', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setup error: $e')),
        );
      }
    }
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await _databaseService.getConversations();
      setState(() {
        _conversations.clear();
        _conversations.addAll(conversations);
      });
    } catch (e, st) {
      DebugLogger.error('ChatScreen', 'Failed to load conversations', e, st);
    }
  }

  Future<void> _loadConversationHistory() async {
    try {
      final messages = await _databaseService.getMessages(_currentConversation.id);
      setState(() {
        _messages.clear();
        for (final msg in messages) {
          _messages.add(ChatMessage(
            text: msg.content,
            isUser: msg.isUser,
            timestamp: msg.createdAt,
          ));
        }
      });
      _scrollToBottom();
    } catch (e, st) {
      DebugLogger.error('ChatScreen', 'Failed to load history', e, st);
    }
  }

  // ============ Message Sending (with streaming) ============

  Future<void> _sendMessage() async {
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty || _isGenerating) return;

    _messageController.clear();

    final userChatMessage = ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userChatMessage);
      _isGenerating = true;
      _canStop = true;
    });

    await _databaseService.addMessage(_currentConversation.id, userMessage, true);
    _scrollToBottom();

    try {
      // Search materials (RAG)
      setState(() => _isSearchingMaterials = true);
      final documents = await _ragService.retrieveContext(userMessage);
      setState(() {
        _isSearchingMaterials = false;
      });

      String prompt = userMessage;
      if (documents.isNotEmpty) {
        prompt = _ragService.buildPromptWithContext(userMessage, documents);
      }

      // Create a placeholder AI message (empty — not shown until complete)
      final aiChatMessage = ChatMessage(
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
        sources: documents,
      );
      setState(() => _messages.add(aiChatMessage));
      _scrollToBottom();

      // Buffer the full response — do NOT update UI during generation.
      // Streaming is kept internally for cancellation and progress, but
      // the user only sees "Librio is thinking..." until complete.
      final responseBuffer = StringBuffer();
      await for (final chunk in widget.llmService.streamResponse(prompt)) {
        if (!_isGenerating) break; // User pressed stop
        responseBuffer.write(chunk);
        // No setState here — no partial text display
      }

      // Generation complete (or cancelled)
      if (_isGenerating) {
        // Completed normally — show the full response
        final response = responseBuffer.toString();
        setState(() {
          _messages.last.text = response;
          _messages.last.isStreaming = false;
          _isGenerating = false;
          _canStop = false;
        });
        await _databaseService.addMessage(_currentConversation.id, response, false);
        _scrollToBottom();
      } else {
        // Cancelled — discard partial response, remove empty placeholder
        setState(() {
          if (_messages.isNotEmpty && !_messages.last.isUser) {
            _messages.removeLast();
          }
          _canStop = false;
        });
      }
    } catch (e, st) {
      DebugLogger.error('ChatScreen', 'Generation failed', e, st);
      setState(() {
        if (_messages.isNotEmpty && !_messages.last.isUser) {
          _messages.last.text = 'Librio couldn\'t generate a response.\n\nPlease try again or check your model settings.';
          _messages.last.isStreaming = false;
        }
        _isGenerating = false;
        _canStop = false;
        _isSearchingMaterials = false;
      });
    }
  }

  void _stopGeneration() {
    // Just flip the flag — _sendMessage handles cleanup
    setState(() {
      _isGenerating = false;
    });
  }

  // ============ Navigation ============

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

  void _openFlashcardReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardReviewScreen(databaseService: _databaseService),
      ),
    );
  }

  Future<void> _startNewConversation() async {
    try {
      final newConversation = await _databaseService.createConversation('New Chat');
      setState(() {
        _currentConversation = newConversation;
        _messages.clear();
      });
      await _loadConversations();
      if (mounted) Navigator.pop(context);
    } catch (e, st) {
      DebugLogger.error('ChatScreen', 'Failed to create conversation', e, st);
    }
  }

  Future<void> _selectConversation(Conversation conversation) async {
    setState(() {
      _currentConversation = conversation;
      _messages.clear();
    });
    await _loadConversationHistory();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    try {
      await _databaseService.deleteConversation(conversation.id);
      await _loadConversations();
      if (conversation.id == _currentConversation.id) {
        if (_conversations.isEmpty) {
          _currentConversation = await _databaseService.createConversation('New Chat');
          setState(() => _messages.clear());
        } else {
          _currentConversation = _conversations.first;
          await _loadConversationHistory();
        }
      }
    } catch (e, st) {
      DebugLogger.error('ChatScreen', 'Failed to delete', e, st);
    }
  }

  Future<void> _clearConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Conversation'),
        content: const Text('Remove all messages in this conversation?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed == true) {
      await _databaseService.deleteMessages(_currentConversation.id);
      setState(() {
        _messages.clear();
      });
    }
  }

  // ============ Study Actions ============

  void _sendStudyAction(String action) {
    final lastAiMessage = _messages.lastWhere((m) => !m.isUser);
    final prompt = '$action\n\n${lastAiMessage.text}';
    _messageController.text = prompt;
    _sendMessage();
  }

  /// Generate flashcards from the last AI response.
  /// Asks the AI to create flashcards, then parses and offers to save.
  Future<void> _generateFlashcards() async {
    if (_isGenerating) return;

    final lastAiMessage = _messages.lastWhere((m) => !m.isUser);
    final prompt = FlashcardGenerator.buildPrompt(lastAiMessage.text);

    // Send as a user message and generate
    _messageController.text = 'Make flashcards from this';
    final userMessage = _messageController.text.trim();
    _messageController.clear();

    final userChatMessage = ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userChatMessage);
      _isGenerating = true;
      _canStop = true;
      _pendingFlashcards = [];
      _showFlashcardSavePrompt = false;
    });

    await _databaseService.addMessage(_currentConversation.id, userMessage, true);
    _scrollToBottom();

    try {
      // Build prompt with RAG context
      final documents = await _ragService.retrieveContext(prompt);
      String fullPrompt = prompt;
      if (documents.isNotEmpty) {
        fullPrompt = _ragService.buildPromptWithContext(prompt, documents);
      }

      // Create placeholder AI message
      final aiChatMessage = ChatMessage(
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
        sources: documents,
      );
      setState(() => _messages.add(aiChatMessage));
      _scrollToBottom();

      // Buffer the response (no partial display)
      final responseBuffer = StringBuffer();
      await for (final chunk in widget.llmService.streamResponse(fullPrompt)) {
        if (!_isGenerating) break;
        responseBuffer.write(chunk);
      }

      if (_isGenerating) {
        final response = responseBuffer.toString();
        // Parse flashcards from the AI response
        final parsed = FlashcardGenerator.parse(response);

        setState(() {
          _messages.last.text = response;
          _messages.last.isStreaming = false;
          _isGenerating = false;
          _canStop = false;
          _pendingFlashcards = parsed;
          _showFlashcardSavePrompt = parsed.isNotEmpty;
        });
        await _databaseService.addMessage(_currentConversation.id, response, false);
        _scrollToBottom();
      } else {
        // Cancelled
        setState(() {
          if (_messages.isNotEmpty && !_messages.last.isUser) {
            _messages.removeLast();
          }
          _canStop = false;
        });
      }
    } catch (e, st) {
      DebugLogger.error('ChatScreen', 'Flashcard generation failed', e, st);
      setState(() {
        _isGenerating = false;
        _canStop = false;
      });
    }
  }

  /// Save all pending flashcards to the database.
  Future<void> _savePendingFlashcards() async {
    if (_pendingFlashcards.isEmpty) return;

    try {
      for (final parsed in _pendingFlashcards) {
        final card = parsed.toFlashcard(deck: _currentConversation.title);
        await _databaseService.addFlashcard(card);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_pendingFlashcards.length} flashcards saved to review!'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Review',
              onPressed: _openFlashcardReview,
            ),
          ),
        );
      }

      setState(() {
        _showFlashcardSavePrompt = false;
        _pendingFlashcards = [];
      });
    } catch (e, st) {
      DebugLogger.error('ChatScreen', 'Failed to save flashcards', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  /// Discard pending flashcards.
  void _discardPendingFlashcards() {
    setState(() {
      _showFlashcardSavePrompt = false;
      _pendingFlashcards = [];
    });
  }

  // ============ Scroll ============

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  // ============ Build ============

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _buildDrawer(),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Offline indicator (subtle)
          if (_isOffline) _buildOfflineIndicator(),
          // Conversation
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : _buildConversationList(),
          ),
          // Composer
          _buildComposer(),
        ],
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  // ============ Loading Screen ============

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogoMark(48),
            const SizedBox(height: 24),
            const Text(
              'Loading Librio...',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preparing your offline AI',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: _deepPurple),
            ),
          ],
        ),
      ),
    );
  }

  // ============ App Bar (minimal) ============

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
          tooltip: 'Menu',
        ),
      ),
      title: Row(
        children: [
          _buildLogoMark(24),
          const SizedBox(width: 8),
          const Text(
            'Librio',
            style: TextStyle(
              fontFamily: 'Fredoka',
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        // Model selector (subtle)
        TextButton.icon(
          onPressed: _showModelSelector,
          icon: Icon(Icons.expand_more, size: 18, color: Colors.grey[600]),
          label: Text(
            _currentModelName,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
        // Overflow menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onSelected: (value) {
            switch (value) {
              case 'clear':
                _clearConversation();
                break;
              case 'documents':
                _openDocumentsScreen();
                break;
              case 'flashcards':
                _openFlashcardReview();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'flashcards', child: Text('Flashcard Review')),
            const PopupMenuItem(value: 'documents', child: Text('Knowledge Base')),
            const PopupMenuItem(value: 'clear', child: Text('Clear Conversation')),
          ],
        ),
      ],
    );
  }

  // ============ Offline Indicator ============

  Widget _buildOfflineIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFFFF8E1),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 14, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline mode — Your local AI is still available',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 12,
                color: Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ Conversation List ============

  Widget _buildConversationList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessage(message, index);
      },
    );
  }

  // ============ Message Widget ============

  Widget _buildMessage(ChatMessage message, int index) {
    if (message.isUser) {
      return _buildUserMessage(message);
    }
    return _buildAiMessage(message, index);
  }

  // User message: subtle background, right-aligned, no heavy bubble
  Widget _buildUserMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _userBubbleColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  color: Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // AI message: open document-like layout, no bubble
  Widget _buildAiMessage(ChatMessage message, int index) {
    final isLast = index == _messages.length - 1;
    final showActions = !message.isStreaming && isLast && !_isGenerating;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          const Text(
            'Librio',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          // Content — crystal loader while generating, formatted text when complete
          if (message.isStreaming && message.text.isEmpty)
            Row(
              children: [
                CrystalLoader(size: 100),
                const SizedBox(width: 12),
                if (_isSearchingMaterials)
                  const Text(
                    'Searching your materials...',
                    style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, color: Colors.grey),
                  ),
              ],
            )
          else if (message.text.isNotEmpty)
            LlmMarkdown(
              data: message.text,
              selectable: true,
              styleSheet: _markdownStyle(),
            ),
          // Sources (RAG)
          if (message.sources.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSources(message.sources),
          ],
          // Actions
          if (showActions) ...[
            const SizedBox(height: 12),
            _buildAiActions(message),
            const SizedBox(height: 12),
            _buildStudyActions(),
          ],
          // Flashcard save prompt (after AI generates flashcards)
          if (_showFlashcardSavePrompt && isLast && !_isGenerating) ...[
            const SizedBox(height: 12),
            _buildFlashcardSavePrompt(),
          ],
        ],
      ),
    );
  }

  // ============ Markdown Style ============

  MarkdownStyleSheet _markdownStyle() {
    return MarkdownStyleSheet(
      p: const TextStyle(
        fontFamily: 'Fredoka',
        color: Colors.black87,
        fontSize: 15,
        height: 1.6,
      ),
      strong: const TextStyle(
        fontFamily: 'Fredoka',
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        fontSize: 15,
      ),
      em: const TextStyle(
        fontFamily: 'Fredoka',
        fontStyle: FontStyle.italic,
        color: Colors.black87,
        fontSize: 15,
      ),
      code: TextStyle(
        fontFamily: 'monospace',
        backgroundColor: Colors.grey[100],
        color: _deepPurple,
        fontSize: 14,
      ),
      h1: const TextStyle(
        fontFamily: 'Fredoka',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      h2: const TextStyle(
        fontFamily: 'Fredoka',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      h3: const TextStyle(
        fontFamily: 'Fredoka',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      listBullet: TextStyle(
        fontFamily: 'Fredoka',
        color: Colors.grey[700],
        fontSize: 15,
      ),
      blockquote: const TextStyle(
        fontFamily: 'Fredoka',
        color: Colors.black54,
        fontSize: 15,
        fontStyle: FontStyle.italic,
      ),
      tableHead: const TextStyle(
        fontFamily: 'Fredoka',
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      tableBody: const TextStyle(
        fontFamily: 'Fredoka',
        fontSize: 14,
      ),
    );
  }

  // ============ Sources (RAG) ============

  Widget _buildSources(List<Document> sources) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              'Sources',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...sources.map((doc) => _buildSourceCard(doc)),
      ],
    );
  }

  Widget _buildSourceCard(Document doc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.description, size: 18, color: Colors.grey[400]),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (doc.category.isNotEmpty)
                    Text(
                      doc.category,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ Flashcard Save Prompt ============

  Widget _buildFlashcardSavePrompt() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _deepPurple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _deepPurple.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.style, size: 18, color: _deepPurple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_pendingFlashcards.length} flashcards generated',
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _deepPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Preview first 2 flashcards
          ..._pendingFlashcards.take(2).map((card) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 6, color: _deepPurple.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Q: ${card.question}',
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'A: ${card.answer}',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
          if (_pendingFlashcards.length > 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '+ ${_pendingFlashcards.length - 2} more...',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ),
          const SizedBox(height: 8),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _savePendingFlashcards,
                  icon: const Icon(Icons.bookmark_add, size: 16),
                  label: const Text(
                    'Save to Review',
                    style: TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _discardPendingFlashcards,
                child: const Text(
                  'Discard',
                  style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Manual creation option
          Center(
            child: TextButton.icon(
              onPressed: () {
                _discardPendingFlashcards();
                _openFlashcardReview();
              },
              icon: Icon(Icons.edit, size: 14, color: Colors.grey[500]),
              label: Text(
                'Or make your own manually',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ AI Actions (subtle) ============

  Widget _buildAiActions(ChatMessage message) {
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: [
        _actionChip(
          icon: Icons.copy_outlined,
          label: 'Copy',
          onTap: () {
            Clipboard.setData(ClipboardData(text: message.text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
            );
          },
        ),
        _actionChip(
          icon: Icons.refresh,
          label: 'Regenerate',
          onTap: _retryLastMessage,
        ),
        _actionChip(
          icon: Icons.thumb_up_outlined,
          label: 'Good',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thanks!'), duration: Duration(seconds: 1)),
          ),
        ),
        _actionChip(
          icon: Icons.thumb_down_outlined,
          label: 'Bad',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thanks for the feedback'), duration: Duration(seconds: 1)),
          ),
        ),
        _actionChip(
          icon: Icons.volume_up_outlined,
          label: 'Read aloud',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Text-to-speech coming soon'), duration: Duration(seconds: 1)),
          ),
        ),
      ],
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ Study Actions (academic differentiation) ============

  Widget _buildStudyActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Need help studying this?',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _studyChip('Summarize', Icons.summarize_outlined, () => _sendStudyAction('Summarize this:')),
            _studyChip('Quiz Me', Icons.quiz_outlined, () => _sendStudyAction('Create a quiz about:')),
            _studyChip('Make Flashcards', Icons.style_outlined, _generateFlashcards),
            _studyChip('Explain Simply', Icons.lightbulb_outline, () => _sendStudyAction('Explain simply:')),
          ],
        ),
      ],
    );
  }

  Widget _studyChip(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _deepPurple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _deepPurple.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _deepPurple),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 13,
                color: _deepPurple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ Composer ============

  Widget _buildComposer() {
    final hasText = _messageController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // + button (attachments)
            IconButton(
              onPressed: _showAttachmentMenu,
              icon: Icon(Icons.add, color: Colors.grey[600]),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _inputFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Ask Librio anything...',
                    hintStyle: TextStyle(
                      fontFamily: 'Fredoka',
                      color: Colors.grey[400],
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send / Stop button
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasText || _canStop ? _deepPurple : Colors.grey[300],
                borderRadius: BorderRadius.circular(22),
              ),
              child: IconButton(
                icon: _canStop
                    ? const Icon(Icons.stop, color: Colors.white, size: 20)
                    : const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                onPressed: _canStop ? _stopGeneration : (hasText ? _sendMessage : null),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ Attachment Menu ============

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.upload_file, color: _deepPurple),
              title: const Text('Upload file', style: TextStyle(fontFamily: 'Fredoka')),
              subtitle: const Text('PDF, DOCX, TXT', style: TextStyle(fontFamily: 'Fredoka', fontSize: 12)),
              onTap: () { Navigator.pop(context); _openDocumentsScreen(); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _deepPurple),
              title: const Text('Photo', style: TextStyle(fontFamily: 'Fredoka')),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _deepPurple),
              title: const Text('Camera', style: TextStyle(fontFamily: 'Fredoka')),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined, color: _deepPurple),
              title: const Text('Choose material', style: TextStyle(fontFamily: 'Fredoka')),
              onTap: () { Navigator.pop(context); _openDocumentsScreen(); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ============ Model Selector ============

  void _showModelSelector() {
    final modelLoader = ModelLoader();
    final models = ModelLoader.availableModels;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Choose AI Model',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...models.map((model) {
                final isInstalled = _installedModels[model.id] ?? false;
                final isSelected = model.id == _currentModelId;
                return _modelOption(
                  name: model.name,
                  subtitle: '${model.description} • ${model.sizeLabel}${isInstalled ? "" : " (not installed)"}',
                  isSelected: isSelected,
                  isInstalled: isInstalled,
                  icon: isInstalled
                      ? (isSelected ? Icons.check_circle : Icons.cloud_done)
                      : Icons.cloud_download,
                  onTap: () async {
                    if (!isInstalled) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${model.name} is not installed. Download ${model.fileName} and place in models folder.'),
                          duration: const Duration(seconds: 4),
                          action: SnackBarAction(
                            label: 'Copy URL',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: model.url));
                            },
                          ),
                        ),
                      );
                      return;
                    }
                    if (isSelected) {
                      Navigator.pop(context);
                      return;
                    }
                    // Switch model
                    await modelLoader.setSelectedModel(model.id);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Switched to ${model.name}. Restart app to apply.'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    setState(() {
                      _currentModelId = model.id;
                      _currentModelName = model.name;
                    });
                  },
                );
              }),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.grey),
                title: const Text('Models run fully offline on your device', style: TextStyle(fontFamily: 'Fredoka', fontSize: 13)),
                subtitle: Text(
                  'To install: download GGUF file and place in app models folder',
                  style: TextStyle(fontFamily: 'Fredoka', fontSize: 11, color: Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modelOption({
    required String name,
    required String subtitle,
    required bool isSelected,
    required bool isInstalled,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? _deepPurple : (isInstalled ? Colors.green : Colors.grey),
        size: 22,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? _deepPurple : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: _deepPurple)
          : null,
      onTap: onTap,
    );
  }

  // ============ Empty State ============

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogoMark(56),
            const SizedBox(height: 24),
            const Text(
              'What are you studying?',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            // Suggestion chips
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _suggestionChip('Explain a concept', Icons.lightbulb_outline),
                _suggestionChip('Quiz me', Icons.quiz_outlined),
                _suggestionChip('Study', Icons.menu_book_outlined),
              ],
            ),
            const SizedBox(height: 24),
            // Use materials link
            TextButton.icon(
              onPressed: _openDocumentsScreen,
              icon: Icon(Icons.folder_outlined, size: 18, color: Colors.grey[500]),
              label: Text(
                'Use my materials',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(String label, IconData icon) {
    return InkWell(
      onTap: () {
        _messageController.text = label;
        _inputFocusNode.requestFocus();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ Drawer ============

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildLogoMark(32),
                    const SizedBox(width: 10),
                    const Text(
                      'Librio',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // New Chat
          ListTile(
            leading: const Icon(Icons.add_circle, color: _deepPurple),
            title: const Text('New Chat', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600)),
            onTap: _startNewConversation,
          ),
          // Flashcard Review
          ListTile(
            leading: Icon(Icons.style_outlined, color: Colors.grey[600]),
            title: const Text('Flashcard Review', style: TextStyle(fontFamily: 'Fredoka')),
            onTap: () { Navigator.pop(context); _openFlashcardReview(); },
          ),
          // Materials
          ListTile(
            leading: Icon(Icons.folder_outlined, color: Colors.grey[600]),
            title: const Text('Materials', style: TextStyle(fontFamily: 'Fredoka')),
            onTap: () { Navigator.pop(context); _openDocumentsScreen(); },
          ),
          const Divider(),
          // Recent conversations
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ),
          Expanded(
            child: _conversations.isEmpty
                ? Center(
                    child: Text(
                      'No conversations yet',
                      style: TextStyle(fontFamily: 'Fredoka', color: Colors.grey[400], fontSize: 14),
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
                          title: Text(
                            conv.title,
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive ? _deepPurple : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            _formatConversationDate(conv.updatedAt),
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          onTap: () => _selectConversation(conv),
                        ),
                      );
                    },
                  ),
          ),
          // Settings at bottom
          const Divider(),
          ListTile(
            leading: Icon(Icons.settings_outlined, color: Colors.grey[600]),
            title: const Text('Settings', style: TextStyle(fontFamily: 'Fredoka')),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ============ Helpers ============

  String _formatConversationDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  Widget _buildLogoMark(double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.25),
      child: Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
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
                fontSize: size * 0.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============ Retry ============

  Future<void> _retryLastMessage() async {
    String? lastUserMessage;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) {
        lastUserMessage = _messages[i].text;
        break;
      }
    }
    if (lastUserMessage == null) return;

    if (_messages.isNotEmpty && !_messages.last.isUser) {
      setState(() => _messages.removeLast());
    }

    setState(() {
      _isGenerating = true;
      _canStop = true;
    });
    _scrollToBottom();

    try {
      final documents = await _ragService.retrieveContext(lastUserMessage);
      String prompt = lastUserMessage;
      if (documents.isNotEmpty) {
        prompt = _ragService.buildPromptWithContext(lastUserMessage, documents);
      }

      final aiChatMessage = ChatMessage(
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
        sources: documents,
      );
      setState(() => _messages.add(aiChatMessage));
      _scrollToBottom();

      // Buffer — no partial UI updates
      final responseBuffer = StringBuffer();
      await for (final chunk in widget.llmService.streamResponse(prompt)) {
        if (!_isGenerating) break;
        responseBuffer.write(chunk);
      }

      if (_isGenerating) {
        final response = responseBuffer.toString();
        setState(() {
          _messages.last.text = response;
          _messages.last.isStreaming = false;
          _isGenerating = false;
          _canStop = false;
        });
        await _databaseService.addMessage(_currentConversation.id, response, false);
        _scrollToBottom();
      } else {
        // Cancelled — remove placeholder
        setState(() {
          if (_messages.isNotEmpty && !_messages.last.isUser) {
            _messages.removeLast();
          }
          _canStop = false;
        });
      }
    } catch (e, st) {
      DebugLogger.error('ChatScreen', 'Retry failed', e, st);
      setState(() {
        _isGenerating = false;
        _canStop = false;
      });
    }
  }
}
