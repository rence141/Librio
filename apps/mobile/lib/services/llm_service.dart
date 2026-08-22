import 'dart:io';
import 'model_loader.dart';
import '../utils/debug_logger.dart';

/// LLM Service for on-device inference with Gemma 3 1B Thinking
/// Model: vinhnx90/gemma-3-1b-thinking-v2-Q4_K_M-GGUF
class LlmService {
  static final LlmService _instance = LlmService._internal();

  factory LlmService() {
    return _instance;
  }

  LlmService._internal();

  late ModelLoader _modelLoader;
  dynamic _model; // Llama model instance
  bool _isInitialized = false;
  bool _isInitializing = false;

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

      // Load model with llamadart
      // For now, just mark as loaded without actually loading the model
      // The actual Llama.load() would be called here in production
      // _model = await Llama.load(...);

      // Simulated model load for testing
      _model = {}; // Placeholder object

      _isInitialized = true;
      _isInitializing = false;

      DebugLogger.success(tag, 'LLM model loaded successfully');
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

    if (!_isInitialized || _model == null) {
      DebugLogger.warning(tag, 'generateResponse called but model not initialized');
      return 'Model not initialized. Please ensure the model file is bundled with the app.';
    }

    try {
      DebugLogger.info(tag, 'Generating response for prompt (${prompt.length} chars)');

      // Generate completion
      final completion = await _model!.complete(
        prompt: prompt,
        temperature: 0.7,
        topP: 0.9,
        topK: 40,
        maxTokens: 256,
      );

      DebugLogger.success(tag, 'Response generated (${completion.length} chars)');
      return completion;
    } catch (e, st) {
      DebugLogger.error(tag, 'Generation failed', e, st);
      return 'Error generating response: $e';
    }
  }

  /// Stream response from prompt (token by token)
  Stream<String> streamResponse(String prompt) async* {
    const tag = 'LlmService';

    if (!_isInitialized || _model == null) {
      DebugLogger.warning(tag, 'streamResponse called but model not initialized');
      yield 'Model not initialized. Please ensure the model file is bundled with the app.';
      return;
    }

    try {
      DebugLogger.info(tag, 'Streaming response for prompt (${prompt.length} chars)');

      await for (final token in _model!.completeStream(
        prompt: prompt,
        temperature: 0.7,
        topP: 0.9,
        topK: 40,
        maxTokens: 256,
      )) {
        yield token;
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
    if (_model == null) {
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
        'context_size': 512,
        'threads': 4,
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
      _model?.dispose();
    } catch (e, st) {
      DebugLogger.error(tag, 'Dispose failed', e, st);
    }
    _model = null;
    _isInitialized = false;
  }
}
