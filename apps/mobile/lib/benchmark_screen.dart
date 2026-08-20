import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({super.key});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  String _status = 'Ready to benchmark';
  final List<String> _logs = [];
  bool _isRunning = false;

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
      _addLog('=== Librio Phase 0 Benchmark ===');
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
      // This is a placeholder - actual device info would come from device_info_plus
      return 'Infinix-Note50 (Android)';
    } catch (e) {
      return 'Unknown device';
    }
  }

  Future<String> _getMemoryInfo() async {
    try {
      // Placeholder - actual memory info would come from system calls
      return 'RAM: ~4GB available';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _testModel(String modelId) async {
    try {
      final startTime = DateTime.now();
      _addLog('  [*] Loading model: $modelId');

      // Simulate model loading (Phase 0 placeholder)
      // In Phase 1, this will actually load the GGUF model with llm_llamacpp
      await Future.delayed(const Duration(milliseconds: 500));

      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      _addLog('  [✓] Model loaded in ${loadTime}ms');

      // Test inference on sample prompts
      int totalTokens = 0;
      int totalTime = 0;

      for (int i = 0; i < _prompts.length; i++) {
        final prompt = _prompts[i];
        _addLog('  [*] Prompt ${i + 1}/${_prompts.length}: "$prompt"');

        final inferenceStart = DateTime.now();

        // Simulate inference (Phase 0 placeholder)
        // In Phase 1, this will actually run inference with llm_llamacpp
        await Future.delayed(const Duration(milliseconds: 300));

        final inferenceTime =
            DateTime.now().difference(inferenceStart).inMilliseconds;
        final estimatedTokens = 30; // Placeholder

        totalTokens += estimatedTokens;
        totalTime += inferenceTime;

        final tokensPerSec =
            inferenceTime > 0 ? (estimatedTokens * 1000 / inferenceTime) : 0;
        _addLog(
            '      Time: ${inferenceTime}ms | Tokens: $estimatedTokens | Speed: ${tokensPerSec.toStringAsFixed(1)} tok/s');
      }

      final avgTime = totalTime ~/ _prompts.length;
      final avgSpeed =
          totalTime > 0 ? (totalTokens * 1000.0 / totalTime) : 0.0;

      _addLog('  [Summary] Avg: ${avgTime}ms | Speed: ${avgSpeed.toStringAsFixed(1)} tok/s');

      // Save result
      await _saveResult(modelId, loadTime, avgTime, avgSpeed);
    } catch (e) {
      _addLog('  [ERROR] Failed to test $modelId: $e');
    }
  }

  Future<void> _saveResult(
    String modelId,
    int loadTime,
    int avgInferenceTime,
    double tokensPerSec,
  ) async {
    try {
      final result = {
        'timestamp': DateTime.now().toIso8601String(),
        'device': 'Infinix-Note50',
        'model_id': modelId,
        'load_time_ms': loadTime,
        'avg_inference_time_ms': avgInferenceTime,
        'tokens_per_sec': tokensPerSec,
        'status': 'Phase 0 placeholder - actual inference not yet implemented',
      };

      final appDir = await getApplicationDocumentsDirectory();
      final resultsDir = Directory('${appDir.path}/benchmark_results');
      if (!resultsDir.existsSync()) {
        resultsDir.createSync(recursive: true);
      }

      final file = File(
          '${resultsDir.path}/Infinix-Note50-$modelId-cpu.json');
      await file.writeAsString(jsonEncode(result));

      _addLog('  [✓] Result saved to: ${file.path}');
    } catch (e) {
      _addLog('  [ERROR] Failed to save result: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Librio Phase 0 Benchmark'),
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
