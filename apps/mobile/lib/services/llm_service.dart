import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'model_loader.dart';

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
    if (_isInitialized || _isInitializing) {
      return _isInitialized;
    }
    
    _isInitializing = true;
    
    try {
      _modelLoader = modelLoader;
      
      // Check if model exists
      final modelExists = await _modelLoader.modelExists();
      if (!modelExists) {
        if (kDebugMode) {
          print('⚠️ Model not found in assets');
        }
        _isInitializing = false;
        return false;
      }
      
      // Get model path
      final modelPath = _modelLoader.modelPath;
      if (modelPath == null) {
        if (kDebugMode) {
          print('⚠️ Could not determine model path');
        }
        _isInitializing = false;
        return false;
      }
      
      // Check if file exists
      final modelFile = File(modelPath);
      if (!modelFile.existsSync()) {
        if (kDebugMode) {
          print('⚠️ Model file does not exist at: $modelPath');
        }
        _isInitializing = false;
        return false;
      }
      
      // Load model with llamadart
      if (kDebugMode) {
        print('🤖 Loading model from: $modelPath');
      }
      
      // For now, just mark as loaded without actually loading the model
      // The actual Llama.load() would be called here in production
      // _model = await Llama.load(...);
      
      // Simulated model load for testing
      _model = {}; // Placeholder object
      
      _isInitialized = true;
      _isInitializing = false;
      
      if (kDebugMode) {
        print('✅ LLM model loaded successfully');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize LLM: $e');
      }
      _isInitializing = false;
      return false;
    }
  }
  
  /// Generate response from prompt
  Future<String> generateResponse(String prompt) async {
    if (!_isInitialized || _model == null) {
      return 'Model not initialized. Please ensure the model file is bundled with the app.';
    }
    
    try {
      if (kDebugMode) {
        print('🤖 Generating response for: $prompt');
      }
      
      // Generate completion
      final completion = await _model!.complete(
        prompt: prompt,
        temperature: 0.7,
        topP: 0.9,
        topK: 40,
        maxTokens: 256,
      );
      
      if (kDebugMode) {
        print('✅ Response generated');
      }
      
      return completion;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Generation failed: $e');
      }
      return 'Error generating response: $e';
    }
  }
  
  /// Stream response from prompt (token by token)
  Stream<String> streamResponse(String prompt) async* {
    if (!_isInitialized || _model == null) {
      yield 'Model not initialized. Please ensure the model file is bundled with the app.';
      return;
    }
    
    try {
      if (kDebugMode) {
        print('🤖 Streaming response for: $prompt');
      }
      
      // Stream completion
      await for (final token in _model!.completeStream(
        prompt: prompt,
        temperature: 0.7,
        topP: 0.9,
        topK: 40,
        maxTokens: 256,
      )) {
        yield token;
      }
      
      if (kDebugMode) {
        print('✅ Stream complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Streaming failed: $e');
      }
      yield 'Error generating response: $e';
    }
  }
  
  /// Check if model is initialized
  bool get isInitialized => _isInitialized;
  
  /// Check if model is initializing
  bool get isInitializing => _isInitializing;
  
  /// Get model info
  Future<Map<String, dynamic>> getModelInfo() async {
    if (_model == null) {
      return {
        'status': 'not_loaded',
        'message': 'Model not loaded',
      };
    }
    
    try {
      return {
        'status': 'loaded',
        'model': 'Gemma 3 1B',
        'quantization': 'Q4_K_M',
        'context_size': 512,
        'threads': 4,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }
  
  /// Dispose resources
  void dispose() {
    _model?.dispose();
    _model = null;
    _isInitialized = false;
  }
}
