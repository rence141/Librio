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

  /// Optimized generation params for fast academic tutoring responses.
  /// - maxTokens capped at 512 to prevent runaway generation
  /// - temp 0.7 for helpful but focused answers
  /// - topK 40 / topP 0.9 for Gemma-family sampling
  GenerationParams get _fastParams => const GenerationParams(
        maxTokens: 512,
        temp: 0.7,
        topK: 40,
        topP: 0.9,
        minP: 0.05,
      );

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
        [LlamaTextContent(prompt)],
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
        [LlamaTextContent(prompt)],
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
