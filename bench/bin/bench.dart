import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('model', abbr: 'm', help: 'Model ID to benchmark')
    ..addOption('backend', abbr: 'b', help: 'Backend: cpu, vulkan, gpu', defaultsTo: 'cpu')
    ..addOption('device', abbr: 'd', help: 'Device name', defaultsTo: 'unknown')
    ..addOption('prompt-count', abbr: 'p', help: 'Number of prompts to run', defaultsTo: '5')
    ..addFlag('help', abbr: 'h', help: 'Show help');

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      print('Librio Phase 0 LLM Benchmark');
      print('');
      print(parser.usage);
      return;
    }

    final modelId = results['model'] as String?;
    if (modelId == null) {
      print('Error: --model is required');
      print(parser.usage);
      exit(1);
    }

    final backend = results['backend'] as String;
    final device = results['device'] as String;
    final promptCount = int.parse(results['prompt-count'] as String);

    print('Librio Phase 0 Benchmark');
    print('Model: $modelId');
    print('Backend: $backend');
    print('Device: $device');
    print('Prompts: $promptCount');
    print('');
    print('Note: This is a Phase 0 placeholder.');
    print('Full benchmark harness will be implemented in Phase 1 with actual model loading.');
    print('');

    // Load prompts
    final promptsFile = File('prompts.json');
    if (!promptsFile.existsSync()) {
      print('Error: prompts.json not found');
      exit(1);
    }

    final promptsJson = jsonDecode(promptsFile.readAsStringSync()) as Map<String, dynamic>;
    final prompts = (promptsJson['prompts'] as List).cast<Map<String, dynamic>>();

    print('Loaded ${prompts.length} prompts');
    print('');

    // Load models
    final modelsFile = File('models.json');
    if (!modelsFile.existsSync()) {
      print('Error: models.json not found');
      exit(1);
    }

    final modelsJson = jsonDecode(modelsFile.readAsStringSync()) as Map<String, dynamic>;
    final models = (modelsJson['models'] as List).cast<Map<String, dynamic>>();

    final selectedModel = models.firstWhere(
      (m) => m['id'] == modelId,
      orElse: () => throw Exception('Model $modelId not found'),
    );

    print('Selected model: ${selectedModel['name']}');
    print('Size: ${selectedModel['size_mb']} MB');
    print('Min RAM: ${selectedModel['min_ram_gb']} GB');
    print('Tier: ${selectedModel['tier']}');
    print('');

    // Placeholder: In Phase 1, this will:
    // 1. Download the model (if not cached)
    // 2. Load it with llm_llamacpp
    // 3. Run prompts and measure:
    //    - Load time (ms)
    //    - TTFT (ms)
    //    - Decode tok/s
    //    - Peak RSS (MB)
    // 4. Write results to bench/results/<device>-<model>-<backend>.json

    final result = {
      'timestamp': DateTime.now().toIso8601String(),
      'model_id': modelId,
      'model_name': selectedModel['name'],
      'backend': backend,
      'device': device,
      'status': 'placeholder',
      'message': 'Full benchmark harness will be implemented in Phase 1',
    };

    final resultsDir = Directory('results');
    if (!resultsDir.existsSync()) {
      resultsDir.createSync(recursive: true);
    }

    final resultFile = File('results/$device-$modelId-$backend.json');
    resultFile.writeAsStringSync(jsonEncode(result));

    print('Result written to: ${resultFile.path}');
    print(jsonEncode(result));
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
