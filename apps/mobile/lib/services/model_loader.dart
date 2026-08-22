import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../utils/debug_logger.dart';

/// Available AI models for on-device inference.
class AiModel {
  final String id;
  final String name;
  final String fileName;
  final String url;
  final String description;
  final String sizeLabel;
  final bool isOnline;

  const AiModel({
    required this.id,
    required this.name,
    required this.fileName,
    required this.url,
    required this.description,
    required this.sizeLabel,
    this.isOnline = false,
  });
}

/// Model loader service for LLM initialization.
/// Supports multiple models with switching via shared_preferences.
class ModelLoader {
  // Available models — user can switch between these
  static const List<AiModel> availableModels = [
    // --- Local (offline) models ---
    AiModel(
      id: 'qwen2.5-coder-3b',
      name: 'Qwen2.5 Coder 3B',
      fileName: 'qwen2.5-coder-3b-instruct-q4_k_m.gguf',
      url: 'https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/qwen2.5-coder-3b-instruct-q4_k_m.gguf',
      description: 'Offline. Coding-tuned, stronger reasoning.',
      sizeLabel: '~2.0 GB',
    ),
    AiModel(
      id: 'gemma-3-1b',
      name: 'Gemma 3 1B',
      fileName: 'gemma-3-1b-thinking-v2-q4_k_m.gguf',
      url: 'https://huggingface.co/vinhnx90/gemma-3-1b-thinking-v2-Q4_K_M-GGUF/resolve/main/gemma-3-1b-thinking-v2-q4_k_m.gguf',
      description: 'Offline. Fastest, lightweight.',
      sizeLabel: '~806 MB',
    ),
    // --- Online (cloud via FreeLLMAPI proxy) ---
    AiModel(
      id: 'gemini-2.0-flash',
      name: 'Gemini 2.0 Flash',
      fileName: '',
      url: '',
      description: 'Online. Fast, smart, free tier.',
      sizeLabel: 'Cloud',
      isOnline: true,
    ),
    AiModel(
      id: 'gemini-2.5-flash',
      name: 'Gemini 2.5 Flash',
      fileName: '',
      url: '',
      description: 'Online. Latest, better reasoning.',
      sizeLabel: 'Cloud',
      isOnline: true,
    ),
    AiModel(
      id: 'gemini-2.5-pro',
      name: 'Gemini 2.5 Pro',
      fileName: '',
      url: '',
      description: 'Online. Most capable Gemini.',
      sizeLabel: 'Cloud',
      isOnline: true,
    ),
    AiModel(
      id: 'llama-3.3-70b',
      name: 'Llama 3.3 70B',
      fileName: '',
      url: '',
      description: 'Online. Meta\'s largest open model.',
      sizeLabel: 'Cloud',
      isOnline: true,
    ),
    AiModel(
      id: 'deepseek-r1',
      name: 'DeepSeek R1',
      fileName: '',
      url: '',
      description: 'Online. Strong reasoning model.',
      sizeLabel: 'Cloud',
      isOnline: true,
    ),
    AiModel(
      id: 'qwen3-32b',
      name: 'Qwen3 32B',
      fileName: '',
      url: '',
      description: 'Online. Latest Qwen, thinking mode.',
      sizeLabel: 'Cloud',
      isOnline: true,
    ),
  ];

  static const String _prefKey = 'selected_model_id';

  bool _modelLoaded = false;
  String? _modelPath;
  AiModel? _selectedModel;

  /// Check if model is loaded
  bool get isModelLoaded => _modelLoaded;

  /// Get model path
  String? get modelPath => _modelPath;

  /// Get the currently selected model
  AiModel? get selectedModel => _selectedModel;

  /// Get the selected model ID from preferences, or default to first.
  Future<String> _getSelectedModelId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) ?? availableModels.first.id;
  }

  /// Set the selected model ID in preferences.
  Future<void> setSelectedModel(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, modelId);
  }

  /// Get the model by ID, or null if not found.
  AiModel? getModelById(String id) {
    try {
      return availableModels.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Check which models are present on disk (or available online).
  Future<Map<String, bool>> getAvailableModels() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/models');
    final result = <String, bool>{};

    for (final model in availableModels) {
      if (model.isOnline) {
        // Online models are always "available" if configured
        result[model.id] = true;
      } else {
        final file = File('${modelsDir.path}/${model.fileName}');
        result[model.id] = file.existsSync();
      }
    }

    return result;
  }

  /// Initialize and load the selected model
  Future<bool> loadModel() async {
    const tag = 'ModelLoader';
    try {
      DebugLogger.info(tag, 'Starting model initialization...');

      // Get selected model
      final modelId = await _getSelectedModelId();
      _selectedModel = getModelById(modelId);

      if (_selectedModel == null) {
        DebugLogger.warning(tag, 'Selected model not found: $modelId, using default');
        _selectedModel = availableModels.first;
      }

      DebugLogger.info(tag, 'Selected model: ${_selectedModel!.name}');

      // Online models don't need a file on disk
      if (_selectedModel!.isOnline) {
        DebugLogger.info(tag, 'Online model — no local file needed');
        _modelPath = null;
        _modelLoaded = true;
        return true;
      }

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

      _modelPath = '${modelsDir.path}/${_selectedModel!.fileName}';

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
      DebugLogger.warning(tag, 'To download: ${_selectedModel!.url}');
      DebugLogger.warning(tag, 'Then place at: $_modelPath');
      DebugLogger.warning(tag, 'Model: ${_selectedModel!.name} (${_selectedModel!.sizeLabel})');

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
      'name': _selectedModel?.fileName ?? 'unknown',
      'displayName': _selectedModel?.name ?? 'Unknown',
      'path': _modelPath,
      'exists': exists,
      'size': size,
      'sizeInMB': (size / (1024 * 1024)).toStringAsFixed(2),
      'loaded': _modelLoaded,
    };
  }
}
