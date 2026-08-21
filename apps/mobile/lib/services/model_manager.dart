import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// Model metadata for HuggingFace models
class ModelMetadata {
  final String id;
  final String name;
  final String huggingFaceRepo;
  final String filename;
  final int sizeBytes;
  final String sha256;

  ModelMetadata({
    required this.id,
    required this.name,
    required this.huggingFaceRepo,
    required this.filename,
    required this.sizeBytes,
    required this.sha256,
  });

  String get downloadUrl =>
      'https://huggingface.co/$huggingFaceRepo/resolve/main/$filename';

  String get sizeMB => (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
}

/// Manages model downloading and caching
class ModelManager {
  static const List<ModelMetadata> availableModels = [
    ModelMetadata(
      id: 'gemma3-1b-q4',
      name: 'Gemma 3 1B Q4_K_M',
      huggingFaceRepo: 'google/gemma-3-1b-gguf',
      filename: 'gemma-3-1b-q4_k_m.gguf',
      sizeBytes: 600 * 1024 * 1024, // 600 MB
      sha256: 'placeholder_sha256_1',
    ),
    ModelMetadata(
      id: 'llama32-1b-q4',
      name: 'Llama 3.2 1B Q4_K_M',
      huggingFaceRepo: 'meta-llama/Llama-3.2-1B-Instruct-GGUF',
      filename: 'Llama-3.2-1B-Instruct-Q4_K_M.gguf',
      sizeBytes: 800 * 1024 * 1024, // 800 MB
      sha256: 'placeholder_sha256_2',
    ),
    ModelMetadata(
      id: 'smollm2-1.7b-q4',
      name: 'SmolLM2 1.7B Q4_K_M',
      huggingFaceRepo: 'HuggingFaceTB/SmolLM2-1.7B-Instruct-GGUF',
      filename: 'SmolLM2-1.7B-Instruct-Q4_K_M.gguf',
      sizeBytes: 1000 * 1024 * 1024, // 1000 MB
      sha256: 'placeholder_sha256_3',
    ),
  ];

  late Directory _modelsDir;
  late Directory _cacheDir;

  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _modelsDir = Directory('${appDir.path}/models');
    _cacheDir = Directory('${appDir.path}/cache');

    // Create directories if they don't exist
    if (!_modelsDir.existsSync()) {
      _modelsDir.createSync(recursive: true);
    }
    if (!_cacheDir.existsSync()) {
      _cacheDir.createSync(recursive: true);
    }
  }

  /// Get path to a model file
  String getModelPath(String modelId) {
    final model = availableModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => throw Exception('Model not found: $modelId'),
    );
    return '${_modelsDir.path}/${model.filename}';
  }

  /// Check if a model is already downloaded
  bool isModelAvailable(String modelId) {
    try {
      final path = getModelPath(modelId);
      return File(path).existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Download a model from HuggingFace
  Future<String> downloadModel(
    String modelId, {
    Function(int, int)? onProgress,
  }) async {
    final model = availableModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => throw Exception('Model not found: $modelId'),
    );

    final modelPath = getModelPath(modelId);
    final modelFile = File(modelPath);

    // Check if already downloaded
    if (modelFile.existsSync()) {
      return modelPath;
    }

    // Download from HuggingFace
    try {
      final request = http.Request('GET', Uri.parse(model.downloadUrl));
      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        throw Exception(
          'Failed to download model: ${streamedResponse.statusCode}',
        );
      }

      final contentLength = streamedResponse.contentLength ?? 0;
      int downloadedBytes = 0;

      final sink = modelFile.openWrite();

      await streamedResponse.stream.listen(
        (chunk) {
          downloadedBytes += chunk.length;
          onProgress?.call(downloadedBytes, contentLength);
          sink.add(chunk);
        },
        onDone: () async {
          await sink.close();
        },
        onError: (error) async {
          await sink.close();
          modelFile.deleteSync();
          throw error;
        },
      ).asFuture();

      return modelPath;
    } catch (e) {
      // Clean up on error
      if (modelFile.existsSync()) {
        modelFile.deleteSync();
      }
      rethrow;
    }
  }

  /// Get list of available models
  List<ModelMetadata> getAvailableModels() => availableModels;

  /// Get list of downloaded models
  List<ModelMetadata> getDownloadedModels() {
    return availableModels
        .where((model) => isModelAvailable(model.id))
        .toList();
  }

  /// Get total size of all models
  int getTotalModelSize() {
    return availableModels.fold(0, (sum, model) => sum + model.sizeBytes);
  }

  /// Get total size of downloaded models
  int getDownloadedModelSize() {
    return getDownloadedModels()
        .fold(0, (sum, model) => sum + model.sizeBytes);
  }

  /// Clear all cached models
  Future<void> clearCache() async {
    if (_cacheDir.existsSync()) {
      _cacheDir.deleteSync(recursive: true);
      _cacheDir.createSync(recursive: true);
    }
  }

  /// Get storage info
  Future<Map<String, String>> getStorageInfo() async {
    final appDir = await getApplicationDocumentsDirectory();
    final totalSize = getTotalModelSize();
    final downloadedSize = getDownloadedModelSize();

    return {
      'total_models': '${availableModels.length}',
      'downloaded_models': '${getDownloadedModels().length}',
      'total_size_mb': (totalSize / (1024 * 1024)).toStringAsFixed(1),
      'downloaded_size_mb': (downloadedSize / (1024 * 1024)).toStringAsFixed(1),
      'app_dir': appDir.path,
      'models_dir': _modelsDir.path,
    };
  }
}
