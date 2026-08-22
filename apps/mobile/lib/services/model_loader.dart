import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../utils/debug_logger.dart';

/// Model loader service for LLM initialization
class ModelLoader {
  // Qwen3-4B (Q4_K_M) — latest Qwen generation, significantly smarter than
  // Qwen2.5-3B while still mobile-friendly (~2.5 GB)
  // Has thinking mode for complex reasoning (we disable for speed)
  static const String modelFileName = 'qwen3-4b-q4_k_m.gguf';
  static const String modelUrl =
      'https://huggingface.co/Qwen/Qwen3-4B-GGUF/resolve/main/qwen3-4b-q4_k_m.gguf';

  // HuggingFace repo for automatic download
  static const String huggingFaceRepo = 'Qwen/Qwen3-4B-GGUF';
  static const String huggingFaceFile = 'qwen3-4b-q4_k_m.gguf';

  bool _modelLoaded = false;
  String? _modelPath;

  /// Check if model is loaded
  bool get isModelLoaded => _modelLoaded;

  /// Get model path
  String? get modelPath => _modelPath;

  /// Initialize and load model
  Future<bool> loadModel() async {
    const tag = 'ModelLoader';
    try {
      DebugLogger.info(tag, 'Starting model initialization...');

      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${appDir.path}/models');

      DebugLogger.info(tag, 'App documents dir: ${appDir.path}');
      DebugLogger.info(tag, 'Models dir: ${modelsDir.path}');

      // Create models directory if it doesn't exist
      if (!modelsDir.existsSync()) {
        modelsDir.createSync(recursive: true);
        DebugLogger.info(tag, 'Created models directory: ${modelsDir.path}');
      }

      _modelPath = '${modelsDir.path}/$modelFileName';

      // Check if model already exists
      final modelFile = File(_modelPath!);
      if (modelFile.existsSync()) {
        final size = await modelFile.length();
        final sizeMB = (size / 1024 / 1024).toStringAsFixed(1);
        DebugLogger.success(tag, 'Model found at: $_modelPath ($sizeMB MB)');
        _modelLoaded = true;
        return true;
      }

      // Model not found, provide download instructions
      DebugLogger.warning(tag, 'Model not found at: $_modelPath');
      DebugLogger.warning(tag, 'To download: $modelUrl');
      DebugLogger.warning(tag, 'Then place at: $_modelPath');
      DebugLogger.warning(tag, 'Model: Qwen3-4B (Q4_K_M) ~2.5 GB');

      return false;
    } catch (e, st) {
      DebugLogger.error(tag, 'Model initialization failed', e, st);
      return false;
    }
  }

  /// Check if model file exists
  Future<bool> modelExists() async {
    const tag = 'ModelLoader';
    if (_modelPath == null) {
      DebugLogger.info(tag, 'modelExists: path is null, calling loadModel()');
      await loadModel();
    }

    if (_modelPath == null) {
      DebugLogger.warning(tag, 'modelExists: path still null after loadModel()');
      return false;
    }

    final file = File(_modelPath!);
    final exists = file.existsSync();
    DebugLogger.info(tag, 'modelExists: $exists at $_modelPath');
    return exists;
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
