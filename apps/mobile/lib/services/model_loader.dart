import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Model loader service for LLM initialization
class ModelLoader {
  static const String modelFileName = 'gemma-3-1b-thinking-v2-q4_k_m.gguf';
  static const String modelUrl = 'https://huggingface.co/vinhnx90/gemma-3-1b-thinking-v2-Q4_K_M-GGUF/resolve/main/gemma-3-1b-thinking-v2-q4_k_m.gguf';
  
  // HuggingFace repo for automatic download
  static const String huggingFaceRepo = 'vinhnx90/gemma-3-1b-thinking-v2-Q4_K_M-GGUF';
  static const String huggingFaceFile = 'gemma-3-1b-thinking-v2-q4_k_m.gguf';
  
  bool _modelLoaded = false;
  String? _modelPath;
  
  /// Check if model is loaded
  bool get isModelLoaded => _modelLoaded;
  
  /// Get model path
  String? get modelPath => _modelPath;
  
  /// Initialize and load model
  Future<bool> loadModel() async {
    try {
      if (kDebugMode) {
        print('🤖 Starting model initialization...');
      }
      
      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${appDir.path}/models');
      
      // Create models directory if it doesn't exist
      if (!modelsDir.existsSync()) {
        modelsDir.createSync(recursive: true);
        if (kDebugMode) {
          print('📁 Created models directory: ${modelsDir.path}');
        }
      }
      
      _modelPath = '${modelsDir.path}/$modelFileName';
      
      // Check if model already exists
      final modelFile = File(_modelPath!);
      if (modelFile.existsSync()) {
        if (kDebugMode) {
          print('✅ Model found at: $_modelPath');
        }
        _modelLoaded = true;
        return true;
      }
      
      // Model not found, provide download instructions
      if (kDebugMode) {
        print('⚠️ Model not found at: $_modelPath');
        print('📥 To download the model:');
        print('   Option 1: Automatic download on first app run (requires internet)');
        print('   Option 2: Manual download from:');
        print('   $modelUrl');
        print('   Then place at: $_modelPath');
        print('');
        print('Model: Gemma 3 1B Thinking (Q4_K_M)');
        print('Size: ~806 MB');
        print('Source: vinhnx90/gemma-3-1b-thinking-v2-Q4_K_M-GGUF');
      }
      
      // Return false - model needs to be downloaded
      // App will show helpful message to user
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Model initialization failed: $e');
      }
      return false;
    }
  }
  
  /// Check if model file exists
  Future<bool> modelExists() async {
    if (_modelPath == null) {
      await loadModel();
    }
    
    if (_modelPath == null) return false;
    
    final file = File(_modelPath!);
    return file.existsSync();
  }
  
  /// Get model file size
  Future<int> getModelFileSize() async {
    if (_modelPath == null) return 0;
    
    final file = File(_modelPath!);
    if (!file.existsSync()) return 0;
    
    return file.lengthSync();
  }
  
  /// Get model info
  Future<Map<String, dynamic>> getModelInfo() async {
    final exists = await modelExists();
    final size = await getModelFileSize();
    
    return {
      'name': modelFileName,
      'path': _modelPath,
      'exists': exists,
      'size': size,
      'sizeInMB': (size / (1024 * 1024)).toStringAsFixed(2),
      'loaded': _modelLoaded,
    };
  }
}
