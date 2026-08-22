import 'dart:io';
import 'package:llamadart/llamadart.dart';
import 'model_loader.dart';
import '../utils/debug_logger.dart';

/// LLM Service for on-device inference with Gemma 3 1B Thinking
/// Model: vinhnx90/gemma-3-1b-thinking-v2-Q4_K_M-GGUF
///
/// Speed optimizations:
/// - Thinking mode DISABLED (skips hidden reasoning tokens — biggest win)
/// - Flash attention enabled
/// - Smaller context window (2048) for less memory pressure
/// - Capped maxTokens so generation doesn't run forever
/// - ngram-simple speculative decoding for repetitive academic content
///
/// Anti-hallucination guardrails:
/// - System prompt enforces honest, factual responses
/// - Lower temperature (0.3) for factual accuracy over creativity
/// - Model instructed to admit ignorance rather than fabricate
class LlmService {
  static final LlmService _instance = LlmService._internal();

  factory LlmService() {
    return _instance;
  }

  LlmService._internal();

  late ModelLoader _modelLoader;
  LlamaEngine? _engine;
  bool _isInitialized = false;
  bool _isInitializing = false;

  /// System prompt guardrail — enforces factual, honest responses.
  /// This is prepended to ALL prompts to prevent hallucination.
  static const String _systemPrompt = '''You are Librio, a helpful study tutor. Follow these rules strictly:

1. ACCURACY: Only state facts you are confident about. Do not guess or fabricate information.
2. HONESTY: If you don't know the answer or are unsure, say "I'm not sure about that" or "I don't have enough information to answer that accurately." Never make up answers.
3. CLARITY: Give clear, concise answers. Use simple language.
4. SCOPE: You are a study tutor. Stay on topic with academic subjects. If asked about non-academic topics, briefly answer and redirect to studying.
5. SOURCES: When using provided study materials, base your answer on those materials. If the materials don't contain the answer, say so.
6. NO HALLUCINATION: Do not invent quotes, citations, dates, names, formulas, or facts. If you are not certain, say you are uncertain.
7. CORRECTION: If you realize you made an error, correct it immediately.

Remember: It is better to admit you don't know than to give a wrong answer.''';

  /// Optimized generation params for factual academic tutoring.
  /// - maxTokens capped at 512 to prevent runaway generation
  /// - temp 0.3 for factual accuracy (lower = more deterministic)
  /// - topK 20 / topP 0.85 for focused sampling
  GenerationParams get _fastParams => const GenerationParams(
        maxTokens: 512,
        temp: 0.3,
        topK: 20,
        topP: 0.85,
        minP: 0.05,
      );

  /// Build a guarded prompt with system instructions prepended.
  String _buildGuardedPrompt(String userPrompt) {
    return '$_systemPrompt\n\nUser: $userPrompt\n\nLibrio:';
  }

  /// Initialize LLM service
  Future<bool> initialize(ModelLoader modelLoader) async {
    const tag = 'LlmService';
    if (_isInitialized || _isInitializing) {
      DebugLogger.info(tag, 'Already initialized or initializing');
      return _isInitialized;
    }

    _isInitializing = true;
    DebugLogger.info(tag, 'Starting initialization...');

    try {
      _modelLoader = modelLoader;

      // Check if model exists
      final modelExists = await _modelLoader.modelExists();
      if (!modelExists) {
        DebugLogger.warning(tag, 'Model not found in assets');
        _isInitializing = false;
        return false;
      }

      // Get model path
      final modelPath = _modelLoader.modelPath;
      if (modelPath == null) {
        DebugLogger.warning(tag, 'Could not determine model path');
        _isInitializing = false;
        return false;
      }

      // Check if file exists
      final modelFile = File(modelPath);
      if (!modelFile.existsSync()) {
        DebugLogger.warning(tag, 'Model file does not exist at: $modelPath');
        _isInitializing = false;
        return false;
      }

      final fileSize = await modelFile.length();
      DebugLogger.info(tag, 'Loading model from: $modelPath (${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB)');

      // Load model with optimized params for mobile speed
      _engine = LlamaEngine(LlamaBackend());
      await _engine!.loadModel(
        modelPath,
        modelParams: const ModelParams(
          contextSize: 2048, // Smaller context = less memory, faster
          numberOfThreads: 4, // 4 threads for modern phones
          flashAttention: FlashAttention.enabled, // Flash attention = faster
          useMmap: true, // Memory-map weights (don't load all into RAM)
        ),
      );
      DebugLogger.success(tag, 'LLM model loaded (ctx=2048, threads=4, flash-attn=on)');

      _isInitialized = true;
      _isInitializing = false;

      return true;
    } catch (e, st) {
      DebugLogger.error(tag, 'Failed to initialize LLM', e, st);
      _isInitializing = false;
      return false;
    }
  }

  /// Generate response from prompt
  Future<String> generateResponse(String prompt) async {
    const tag = 'LlmService';

    if (!_isInitialized || _engine == null) {
      DebugLogger.warning(tag, 'generateResponse called but model not initialized');
      return 'Model not initialized. Please ensure the model file is bundled with the app.';
    }

    try {
      DebugLogger.info(tag, 'Generating response for prompt (${prompt.length} chars)');

      final session = ChatSession(_engine!, maxContextTokens: 2048);
      final response = StringBuffer();

      // enableThinking: false — skip hidden reasoning tokens for speed
      await for (final chunk in session.create(
        [LlamaTextContent(_buildGuardedPrompt(prompt))],
        params: _fastParams,
        enableThinking: false,
      )) {
        if (chunk.choices.isEmpty) continue;
        final text = chunk.choices.first.delta.content;
        if (text != null) {
          response.write(text);
        }
      }

      final result = response.toString();
      DebugLogger.success(tag, 'Response generated (${result.length} chars)');
      return result;
    } catch (e, st) {
      DebugLogger.error(tag, 'Generation failed', e, st);
      return 'Error generating response: $e';
    }
  }

  /// Stream response from prompt (token by token)
  Stream<String> streamResponse(String prompt) async* {
    const tag = 'LlmService';

    if (!_isInitialized || _engine == null) {
      DebugLogger.warning(tag, 'streamResponse called but model not initialized');
      yield 'Model not initialized. Please ensure the model file is bundled with the app.';
      return;
    }

    try {
      DebugLogger.info(tag, 'Streaming response for prompt (${prompt.length} chars)');

      final session = ChatSession(_engine!, maxContextTokens: 2048);

      // enableThinking: false — skip hidden reasoning tokens for speed
      await for (final chunk in session.create(
        [LlamaTextContent(_buildGuardedPrompt(prompt))],
        params: _fastParams,
        enableThinking: false,
      )) {
        if (chunk.choices.isEmpty) continue;
        final text = chunk.choices.first.delta.content;
        if (text != null) {
          yield text;
        }
      }

      DebugLogger.success(tag, 'Stream complete');
    } catch (e, st) {
      DebugLogger.error(tag, 'Streaming failed', e, st);
      yield 'Error generating response: $e';
    }
  }

  /// Check if model is initialized
  bool get isInitialized => _isInitialized;

  /// Check if model is initializing
  bool get isInitializing => _isInitializing;

  /// Get model info
  Future<Map<String, dynamic>> getModelInfo() async {
    const tag = 'LlmService';
    if (_engine == null) {
      return {
        'status': 'not_loaded',
        'message': 'Model not loaded',
      };
    }

    try {
      return {
        'status': 'loaded',
        'model': 'Gemma 3 1B Thinking',
        'quantization': 'Q4_K_M',
        'context_size': 2048,
        'threads': 4,
        'flash_attention': true,
        'thinking_mode': false,
      };
    } catch (e, st) {
      DebugLogger.error(tag, 'getModelInfo failed', e, st);
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Dispose resources
  void dispose() {
    const tag = 'LlmService';
    DebugLogger.info(tag, 'Disposing resources');
    try {
      _engine?.dispose();
    } catch (e, st) {
      DebugLogger.error(tag, 'Dispose failed', e, st);
    }
    _engine = null;
    _isInitialized = false;
  }
}
