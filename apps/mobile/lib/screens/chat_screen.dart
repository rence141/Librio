import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/llm_service.dart';
import '../services/online_llm_service.dart';
import '../services/online_model_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/model_loader.dart';
import '../services/database_service.dart';
import '../services/rag_service.dart';
import '../services/embeddings_service.dart';
import '../services/document_upload_service.dart';
import '../services/flashcard_generator.dart';
import '../models/conversation.dart';
import '../models/context_window.dart';
import '../utils/debug_logger.dart';
import '../widgets/crystal_loader.dart';
import '../widgets/llm_markdown.dart';
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
  bool _canStop = false;
  bool _isInitialized = false;
  final List<String> _pendingAttachments = []; // paths of images/files to send
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
  bool _currentModelIsOnline = false;
  Map<String, bool> _installedModels = {};
  final OnlineLlmService _onlineLlm = OnlineLlmService();

  // Context window tracking
  late ContextWindow _contextWindow;

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

      // If database isn't available (web without wasm), skip DB-dependent services
      if (!_databaseService.isAvailable) {
        DebugLogger.warning(tag, 'Database not available — running in limited mode');
        // Create a default in-memory conversation
        _currentConversation = Conversation(
          id: 'web-session',
          title: 'New Chat',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        // Check model status
        _isOffline = _currentModelIsOnline ? false : !widget.llmService.isInitialized;
        setState(() => _isInitialized = true);
        return;
      }

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

      // Initialize context window tracker
      _contextWindow = ContextWindow(conversationId: _currentConversation.id);

      // Check model status
      _isOffline = !widget.llmService.isInitialized;

      // Load model info for selector
      final modelLoader = ModelLoader();
      _installedModels = await modelLoader.getAvailableModels();
      final info = await modelLoader.getModelInfo();
      _currentModelName = info['displayName'] as String? ?? 'Unknown';
      _currentModelId = modelLoader.selectedModel?.id ?? '';
      _currentModelIsOnline = modelLoader.selectedModel?.isOnline ?? false;
      // If online model selected, no need for local LLM
      _isOffline = _currentModelIsOnline ? false : !widget.llmService.isInitialized;

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
    final attachments = List<String>.from(_pendingAttachments);
    if (userMessage.isEmpty && attachments.isEmpty) return;
    if (_isGenerating) return;

    // Check context limit
    if (_contextWindow.isLimitExceeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Context limit exceeded. Start a new conversation.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _messageController.clear();
    _pendingAttachments.clear();

    final userChatMessage = ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
      attachmentPaths: attachments,
    );

    setState(() {
      _messages.add(userChatMessage);
      _isGenerating = true;
      _canStop = true;
    });

    await _databaseService.addMessage(_currentConversation.id, userMessage, true);
    _scrollToBottom();

    try {
      // Create a placeholder AI message (empty — not shown until complete)
      final aiChatMessage = ChatMessage(
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      setState(() => _messages.add(aiChatMessage));
      _scrollToBottom();

      // Buffer the full response — do NOT update UI during generation.
      // Streaming is kept internally for cancellation and progress, but
      // the user only sees "Librio is thinking..." until complete.
      final responseBuffer = StringBuffer();
      await for (final chunk in _streamLlmResponse(userMessage, imagePaths: attachments)) {
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

        // Show context window status if online model
        if (_currentModelIsOnline && _contextWindow.warningLevel > 0) {
          final color = _contextWindow.warningLevel == 2 ? Colors.red : Colors.orange;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_contextWindow.statusMessage),
              backgroundColor: color,
              duration: const Duration(seconds: 4),
            ),
          );
        }

        // Auto-generate title if this is the first exchange
        if (_currentConversation.title == 'New Chat' && _databaseService.isAvailable) {
          _autoGenerateTitle(userMessage);
        }
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
      });
    }
  }

  /// Auto-generate a conversation title from the first user message.
  /// Uses online model if available, otherwise falls back to word truncation.
  Future<void> _autoGenerateTitle(String userMessage) async {
    try {
      String title;

      if (_currentModelIsOnline && OnlineModelConfig.hasKey) {
        final onlineService = OnlineLlmService();
        final authToken = Supabase.instance.client.auth.currentSession?.accessToken;
        title = await onlineService.generateTitle(userMessage, authToken: authToken);
      } else {
        title = await widget.llmService.generateTitle(userMessage);
      }

      // Update conversation in DB
      final updated = _currentConversation.copyWith(title: title);
      await _databaseService.updateConversation(updated);

      setState(() {
        _currentConversation = updated;
      });

      // Refresh conversation list in drawer
      await _loadConversations();

      DebugLogger.info('ChatScreen', 'Auto-generated title: $title');
    } catch (e, st) {
      DebugLogger.error('ChatScreen', 'Title generation failed', e, st);
    }
  }

  void _stopGeneration() {
    // Just flip the flag — _sendMessage handles cleanup
    setState(() {
      _isGenerating = false;
    });
  }

  // ============ Navigation ============

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
      // Create placeholder AI message
      final aiChatMessage = ChatMessage(
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      setState(() => _messages.add(aiChatMessage));
      _scrollToBottom();

      // Buffer the response (no partial display)
      final responseBuffer = StringBuffer();
      await for (final chunk in _streamLlmResponse(prompt)) {
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
      title: const Text(
        'Librio',
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
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
              case 'flashcards':
                _openFlashcardReview();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'flashcards', child: Text('Flashcard Review')),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Attachment thumbnails
                  if (message.attachmentPaths.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: message.attachmentPaths.map((path) {
                        final isImage = _isImagePath(path);
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: isImage
                              ? Image.file(File(path), width: 140, height: 140, fit: BoxFit.cover)
                              : Container(
                                  width: 140,
                                  height: 56,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  color: Colors.grey[200],
                                  child: Row(
                                    children: [
                                      Icon(_fileIcon(path), size: 20, color: Colors.grey[600]),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          path.split('/').last.split('\\').last,
                                          style: TextStyle(
                                            fontFamily: 'Fredoka',
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        );
                      }).toList(),
                    ),
                    if (message.text.isNotEmpty) const SizedBox(height: 10),
                  ],
                  // Message text
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        color: Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                ],
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
                const Text(
                  'Librio is thinking...',
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
    final hasAttachments = _pendingAttachments.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Attachment previews
            if (hasAttachments)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pendingAttachments.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final path = _pendingAttachments[index];
                      final isImage = _isImagePath(path);
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _removeAttachment(index),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!, width: 1),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: isImage
                                      ? Image.file(File(path), fit: BoxFit.cover)
                                      : Container(
                                          color: Colors.grey[100],
                                          child: Icon(
                                            _fileIcon(path),
                                            size: 24,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                ),
                                // Remove overlay
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(11),
                                      color: Colors.black.withValues(alpha: 0.0),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: Align(
                                        alignment: Alignment.topRight,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            // Context window status (if online model and usage > 0)
            if (_currentModelIsOnline && _contextWindow.totalTokensUsed > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: _contextWindow.warningLevel == 2
                    ? Colors.red[50]
                    : _contextWindow.warningLevel == 1
                        ? Colors.orange[50]
                        : Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _contextWindow.statusMessage,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 12,
                          color: _contextWindow.warningLevel == 2
                              ? Colors.red[700]
                              : _contextWindow.warningLevel == 1
                                  ? Colors.orange[700]
                                  : Colors.grey[600],
                        ),
                      ),
                    ),
                    if (_contextWindow.warningLevel > 0)
                      Icon(
                        _contextWindow.warningLevel == 2 ? Icons.warning : Icons.info,
                        size: 16,
                        color: _contextWindow.warningLevel == 2 ? Colors.red[700] : Colors.orange[700],
                      ),
                  ],
                ),
              ),
            // Input row
            Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // + button (attachments) — same height as send button
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: _showAttachmentMenu,
                icon: Icon(Icons.add, color: Colors.grey[600]),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ),
            const SizedBox(width: 8),
            // Text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 44,
                  maxHeight: 120,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
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
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                icon: _canStop
                    ? Icon(Icons.stop, color: hasText || hasAttachments || _canStop ? Colors.white : Colors.grey[500], size: 20)
                    : Icon(Icons.arrow_upward, color: hasText || hasAttachments || _canStop ? Colors.white : Colors.grey[500], size: 20),
                onPressed: _canStop ? _stopGeneration : ((hasText || hasAttachments) ? _sendMessage : null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                style: IconButton.styleFrom(
                  backgroundColor: hasText || hasAttachments || _canStop ? _deepPurple : Colors.grey[200],
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ], // Row children
            ), // Row
          ], // Column children
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
              onTap: () { Navigator.pop(context); _pickFile(); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _deepPurple),
              title: const Text('Photo', style: TextStyle(fontFamily: 'Fredoka')),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _deepPurple),
              title: const Text('Camera', style: TextStyle(fontFamily: 'Fredoka')),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Pick an image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: source, maxWidth: 1024, imageQuality: 85);
      if (xFile == null) return;

      setState(() {
        _pendingAttachments.add(xFile.path);
      });
      DebugLogger.info('ChatScreen', 'Image attached: ${xFile.path}');
    } catch (e, st) {
      DebugLogger.error('ChatScreen', 'Image pick failed', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  /// Pick a document file (PDF, DOCX, TXT)
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt', 'md'],
      );
      if (result == null || result.files.isEmpty) return;

      final path = result.files.first.path;
      if (path == null) return;

      setState(() {
        _pendingAttachments.add(path);
      });
      DebugLogger.info('ChatScreen', 'File attached: $path');
    } catch (e, st) {
      DebugLogger.error('ChatScreen', 'File pick failed', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  /// Remove a pending attachment
  void _removeAttachment(int index) {
    setState(() {
      _pendingAttachments.removeAt(index);
    });
  }

  /// Check if a file path is an image
  bool _isImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  /// Get the appropriate icon for a file type
  IconData _fileIcon(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (lower.endsWith('.docx') || lower.endsWith('.doc')) return Icons.description;
    if (lower.endsWith('.txt') || lower.endsWith('.md')) return Icons.article;
    return Icons.insert_drive_file;
  }

  // ============ Model Selector ============

  void _showModelSelector() {
    final modelLoader = ModelLoader();
    final models = ModelLoader.availableModels;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
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
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...models.map((model) {
                final isInstalled = model.isOnline || (_installedModels[model.id] ?? false);
                final isSelected = model.id == _currentModelId;
                return _modelOption(
                  name: model.name,
                  subtitle: '${model.description} • ${model.sizeLabel}${model.isOnline ? "" : (isInstalled ? "" : " (not installed)")}',
                  isSelected: isSelected,
                  isInstalled: isInstalled,
                  icon: model.isOnline
                      ? (isSelected ? Icons.cloud : Icons.cloud_outlined)
                      : (isInstalled
                          ? (isSelected ? Icons.check_circle : Icons.cloud_done)
                          : Icons.cloud_download),
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
                    // Switch model at runtime — no restart needed
                    await modelLoader.setSelectedModel(model.id);
                    if (!context.mounted) return;
                    Navigator.pop(context);

                    // Show loading indicator while switching
                    setState(() {
                      _isOffline = true;
                      _currentModelName = 'Switching...';
                    });

                    // Online models don't need local engine
                    if (model.isOnline) {
                      setState(() {
                        _currentModelId = model.id;
                        _currentModelName = model.name;
                        _currentModelIsOnline = true;
                        _isOffline = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched to ${model.name} (online)'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    // Reload model loader with new selection
                    final newLoader = ModelLoader();
                    final loaded = await newLoader.loadModel();
                    if (!loaded) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${model.name} could not be loaded.')),
                        );
                        setState(() {
                          _isOffline = !widget.llmService.isInitialized;
                          _currentModelName = _currentModelId.isEmpty ? 'Unknown' : ModelLoader().getModelById(_currentModelId)?.name ?? 'Unknown';
                        });
                      }
                      return;
                    }

                    // Hot-swap the model in LLM service
                    final success = await widget.llmService.switchModel(newLoader);
                    if (!mounted) return;

                    if (success) {
                      setState(() {
                        _currentModelId = model.id;
                        _currentModelName = model.name;
                        _currentModelIsOnline = false;
                        _isOffline = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched to ${model.name}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      setState(() {
                        _isOffline = !widget.llmService.isInitialized;
                        _currentModelName = 'Error';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to switch to ${model.name}.')),
                      );
                    }
                  },
                );
              }),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.phone_android, color: Colors.grey),
                title: const Text('Offline models run on your device', style: TextStyle(fontFamily: 'Fredoka', fontSize: 13)),
                subtitle: Text(
                  'Download GGUF file → place in app models folder',
                  style: TextStyle(fontFamily: 'Fredoka', fontSize: 11, color: Colors.grey[500]),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.cloud_outlined, color: Colors.grey),
                title: const Text('Online models need internet', style: TextStyle(fontFamily: 'Fredoka', fontSize: 13)),
                subtitle: Text(
                  'Faster & smarter, but requires connection',
                  style: TextStyle(fontFamily: 'Fredoka', fontSize: 11, color: Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 8),
                  ],
                ),
              ),
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

  // ============ LLM Streaming Helper ============

  /// Stream response from either local or online model based on current selection.
  /// Passes image attachments to online vision models.
  Stream<String> _streamLlmResponse(String prompt, {List<String> imagePaths = const []}) async* {
    if (_currentModelIsOnline) {
      // Use online model via Supabase Edge Function — supports vision
      // Get response with token usage data
      final authToken = Supabase.instance.client.auth.currentSession?.accessToken;
      final response = await _onlineLlm.generateResponseWithUsage(
        prompt,
        model: _currentModelId,
        imagePaths: imagePaths,
        authToken: authToken,
      );
      
      // Track token usage
      if (response.inputTokens != null && response.outputTokens != null) {
        _contextWindow.addUsage(response.inputTokens!, response.outputTokens!);
      }
      
      yield response.text;
    } else {
      // Use local on-device LLM — no vision support, just text
      // If images were attached, note that they can't be processed locally
      if (imagePaths.isNotEmpty) {
        yield* _streamLocalResponse('$prompt\n\n[Note: ${imagePaths.length} image(s) were attached but local model cannot process images. Switch to an online model for image understanding.]');
      } else {
        yield* _streamLocalResponse(prompt);
      }
    }
  }

  /// Stream from local on-device LLM
  Stream<String> _streamLocalResponse(String prompt) async* {
    yield* widget.llmService.streamResponse(prompt);
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
            // Suggestion chips
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
      final aiChatMessage = ChatMessage(
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      setState(() => _messages.add(aiChatMessage));
      _scrollToBottom();

      // Buffer — no partial UI updates
      final responseBuffer = StringBuffer();
      await for (final chunk in _streamLlmResponse(lastUserMessage)) {
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
