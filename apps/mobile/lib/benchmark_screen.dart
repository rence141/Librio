import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:llamadart/llamadart.dart';

class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({super.key});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  String _status = 'Ready to benchmark';
  final List<String> _logs = [];
  bool _isRunning = false;
  late LlamaEngine _engine;

  final List<String> _models = [
    'gemma3-1b-q4',
    'llama32-1b-q4',
    'smollm2-1.7b-q4',
  ];

  final List<String> _prompts = [
    'What is photosynthesis?',
    'Solve: 2x + 5 = 13',
    'Explain Newton\'s first law of motion.',
    'What is the capital of France?',
    'How do plants absorb water?',
  ];

  @override
  void initState() {
    super.initState();
    _initializeEngine();
  }

  void _initializeEngine() {
    try {
      _engine = LlamaEngine(LlamaBackend());
      _addLog('LlamaEngine initialized successfully');
    } catch (e) {
      _addLog('ERROR: Failed to initialize LlamaEngine: $e');
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toIso8601String()}] $message');
      if (_logs.length > 100) _logs.removeAt(0); // Keep last 100 logs
    });
    // ignore: avoid_print
    print(message);
  }

  Future<void> _runBenchmark() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _logs.clear();
      _status = 'Starting benchmark...';
    });

    try {
      _addLog('=== Librio Phase 1 Benchmark (Actual Inference) ===');
      _addLog('Device: Infinix-Note50');
      _addLog('Dart SDK: ${Platform.version}');
      _addLog('');

      // Get device info
      final deviceInfo = await _getDeviceInfo();
      _addLog('Device Info: $deviceInfo');
      _addLog('');

      // Get available memory
      final memInfo = await _getMemoryInfo();
      _addLog('Memory: $memInfo');
      _addLog('');

      // Test each model
      for (final modelId in _models) {
        _addLog('Testing model: $modelId');
        await _testModel(modelId);
        _addLog('');
      }

      setState(() {
        _status = 'Benchmark complete!';
        _isRunning = false;
      });
      _addLog('=== Benchmark finished ===');
    } catch (e) {
      _addLog('ERROR: $e');
      setState(() {
        _status = 'Error: $e';
        _isRunning = false;
      });
    }
  }

  Future<String> _getDeviceInfo() async {
    try {
      return 'Infinix-Note50 (Android)';
    } catch (e) {
      return 'Unknown device';
    }
  }

  Future<String> _getMemoryInfo() async {
    try {
      return 'RAM: ~4GB available';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _testModel(String modelId) async {
    try {
      // Map model ID to file path
      final modelPath = _getModelPath(modelId);
      _addLog('  [*] Model file: $modelPath');

      // Check if model file exists
      final modelFile = File(modelPath);
      if (!modelFile.existsSync()) {
        _addLog('  [ERROR] Model file not found: $modelPath');
        _addLog('  [INFO] Phase 1 requires actual GGUF files in bench/models/');
        return;
      }

      final startTime = DateTime.now();
      _addLog('  [*] Loading model: $modelId');

      // Load model
      try {
        await _engine.loadModel(modelPath);
      } catch (e) {
        _addLog('  [ERROR] Failed to load model: $e');
        _addLog('  [INFO] This may be due to missing native assets or incompatible model format');
        return;
      }

      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      _addLog('  [✓] Model loaded in ${loadTime}ms');

      // Test inference on sample prompts
      int totalTokens = 0;
      int totalTime = 0;
      DateTime? firstTokenTime;

      for (int i = 0; i < _prompts.length; i++) {
        final prompt = _prompts[i];
        _addLog('  [*] Prompt ${i + 1}/${_prompts.length}: "$prompt"');

        final inferenceStart = DateTime.now();
        final response = StringBuffer();
        int promptTokens = 0;

        try {
          await for (final chunk in _engine.create(
            [
              LlamaChatMessage.fromText(
                role: LlamaChatRole.user,
                text: prompt,
              ),
            ],
            params: const GenerationParams(maxTokens: 50),
          )) {
            final text = chunk.choices.first.delta.content;
            if (text != null) {
              response.write(text);
              promptTokens++;
              
              // Record first token time
              if (firstTokenTime == null) {
                firstTokenTime = DateTime.now();
              }
            }
          }
        } catch (e) {
          _addLog('  [ERROR] Inference failed: $e');
          continue;
        }

        final inferenceTime =
            DateTime.now().difference(inferenceStart).inMilliseconds;

        totalTokens += promptTokens;
        totalTime += inferenceTime;

        final tokensPerSec =
            inferenceTime > 0 ? (promptTokens * 1000.0 / inferenceTime) : 0;
        _addLog(
            '      Time: ${inferenceTime}ms | Tokens: $promptTokens | Speed: ${tokensPerSec.toStringAsFixed(1)} tok/s');
      }

      final avgTime = totalTime ~/ _prompts.length;
      final avgSpeed =
          totalTime > 0 ? (totalTokens * 1000.0 / totalTime) : 0.0;
      final ttft = firstTokenTime != null
          ? firstTokenTime!.difference(startTime).inMilliseconds
          : 0;

      _addLog('  [Summary]');
      _addLog('    Load time: ${loadTime}ms');
      _addLog('    TTFT: ${ttft}ms');
      _addLog('    Avg inference: ${avgTime}ms');
      _addLog('    Avg speed: ${avgSpeed.toStringAsFixed(1)} tok/s');

      // Save result
      await _saveResult(modelId, loadTime, ttft, avgTime, avgSpeed);

      // Unload model
      try {
        await _engine.unloadModel();
        _addLog('  [✓] Model unloaded');
      } catch (e) {
        _addLog('  [WARNING] Failed to unload model: $e');
      }
    } catch (e) {
      _addLog('  [ERROR] Failed to test $modelId: $e');
    }
  }

  String _getModelPath(String modelId) {
    // In Phase 1, models should be in bench/models/ directory
    // For now, return the expected path
    final filename = _modelIdToFilename(modelId);
    return '/data/user/0/com.librio.librio/app_flutter/models/$filename';
  }

  String _modelIdToFilename(String modelId) {
    switch (modelId) {
      case 'gemma3-1b-q4':
        return 'gemma-3-1b-q4_k_m.gguf';
      case 'llama32-1b-q4':
        return 'llama-3.2-1b-q4_k_m.gguf';
      case 'smollm2-1.7b-q4':
        return 'smollm2-1.7b-q4_k_m.gguf';
      default:
        return '$modelId.gguf';
    }
  }

  Future<void> _saveResult(
    String modelId,
    int loadTime,
    int ttft,
    int avgInferenceTime,
    double tokensPerSec,
  ) async {
    try {
      final result = {
        'timestamp': DateTime.now().toIso8601String(),
        'device': 'Infinix-Note50',
        'model_id': modelId,
        'phase': 'Phase 1 - Actual Inference',
        'load_time_ms': loadTime,
        'ttft_ms': ttft,
        'avg_inference_time_ms': avgInferenceTime,
        'tokens_per_sec': tokensPerSec,
        'status': 'Phase 1 actual inference results',
      };

      final appDir = await getApplicationDocumentsDirectory();
      final resultsDir = Directory('${appDir.path}/benchmark_results');
      if (!resultsDir.existsSync()) {
        resultsDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File(
          '${resultsDir.path}/Infinix-Note50-$modelId-phase1-$timestamp.json');
      await file.writeAsString(jsonEncode(result));

      _addLog('  [✓] Result saved to: ${file.path}');
    } catch (e) {
      _addLog('  [ERROR] Failed to save result: $e');
    }
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Librio Phase 1 Benchmark'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: $_status',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Device: Infinix-Note50 | Models: ${_models.length} | Prompts: ${_prompts.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Phase: 1 (Actual Inference with GGUF models)',
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ],
            ),
          ),
          // Logs
          Expanded(
            child: Container(
              color: Colors.black87,
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        color: Colors.greenAccent,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Control buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _runBenchmark,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Benchmark'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _logs.clear());
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Clear Logs'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
