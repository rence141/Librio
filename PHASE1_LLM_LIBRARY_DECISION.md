# Phase 1: LLM Library Selection Decision

**Date:** 2026-08-22  
**Decision:** `llamadart` (with fallback to `llm_llamacpp` if needed)

---

## Comparison: `llamadart` vs `llm_llamacpp`

### `llamadart` (Recommended)

**Pros:**
- ✓ **Unified API** - Single API for GGUF and LiteRT-LM models
- ✓ **Modern** - Actively maintained, latest version 0.8.19
- ✓ **Cross-platform** - Native + Web support
- ✓ **Better documentation** - Comprehensive guides and examples
- ✓ **Streaming support** - Built-in streaming for chat completions
- ✓ **Embeddings support** - Native embeddings for RAG
- ✓ **HuggingFace integration** - Direct `hf://` model loading
- ✓ **Simpler setup** - No CMake required for pre-built binaries
- ✓ **Better error handling** - Detailed diagnostics

**Cons:**
- ⚠ Newer (less battle-tested than llm_llamacpp)
- ⚠ May have fewer pre-built binaries for edge cases

**Windows Build:**
- Uses pre-built binaries from GitHub releases
- No CMake required
- Automatic download and caching

**Status:** ✓ Recommended for Phase 1

---

### `llm_llamacpp` (Fallback)

**Pros:**
- ✓ Mature, widely used
- ✓ Good documentation
- ✓ GPU support (CUDA, Metal, Vulkan)
- ✓ Vision model support

**Cons:**
- ❌ **Windows native asset building fails** - Requires CMake + unzip
- ❌ Complex setup - Multiple build steps
- ❌ CMake configuration needed
- ❌ Android NDK required
- ❌ Separate iOS/Android implementations
- ❌ No HuggingFace integration

**Windows Build Issues:**
- Requires CMake 3.20+
- Requires Android NDK
- Requires unzip utility
- Failed in Phase 0 with "unzip not found" error
- Known Windows permission issues (see GitHub discussion #3790)

**Status:** ❌ Not recommended for Phase 1 (too complex for Windows dev)

---

## Decision Rationale

### Why `llamadart`?

1. **Simplicity** - No CMake, no complex setup
2. **Modern** - Better maintained, newer features
3. **Unified API** - Single API for all model types
4. **Embeddings** - Built-in support for RAG layer
5. **HuggingFace** - Direct model loading from HF
6. **Documentation** - Better guides and examples
7. **Windows-friendly** - Pre-built binaries, no native compilation needed

### Why not `llm_llamacpp`?

1. **Windows complexity** - CMake, NDK, unzip all required
2. **Build failures** - Already failed in Phase 0
3. **Maintenance burden** - More setup and troubleshooting
4. **Separate implementations** - Different code for iOS/Android
5. **No HuggingFace integration** - Manual model management

---

## Implementation Plan

### Step 1: Add `llamadart` to `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  path_provider: ^2.1.0
  llamadart: ^0.8.19
```

### Step 2: Update `benchmark_screen.dart`

Replace simulated inference with actual model loading:

```dart
import 'package:llamadart/llamadart.dart';

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  late LlamaEngine _engine;
  
  @override
  void initState() {
    super.initState();
    _engine = LlamaEngine(LlamaBackend());
  }
  
  Future<void> _testModel(String modelId) async {
    try {
      // Load model
      final modelPath = '/path/to/$modelId.gguf';
      await _engine.loadModel(modelPath);
      
      // Run inference
      for (final prompt in _prompts) {
        final startTime = DateTime.now();
        final response = StringBuffer();
        
        await for (final chunk in _engine.create([
          LlamaChatMessage.fromText(
            role: LlamaChatRole.user,
            text: prompt,
          ),
        ])) {
          response.write(chunk.choices.first.delta.content ?? '');
        }
        
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime).inMilliseconds;
        
        // Save metrics
        _saveResult(modelId, duration, response.length);
      }
      
      // Unload model
      await _engine.unloadModel();
    } catch (e) {
      _addLog('Error: $e');
    }
  }
}
```

### Step 3: Test on Infinix-Note50

1. Run `flutter pub get` (will download llamadart)
2. Run `flutter run` on Infinix-Note50
3. Tap "Start Benchmark"
4. Measure actual inference performance

### Step 4: Implement Performance Measurement

Capture:
- Model load time
- Time to first token (TTFT)
- Decode speed (tokens/second)
- Total response time
- Peak memory usage
- CPU usage

### Step 5: Implement Embeddings (for RAG)

```dart
// Load embeddings model
await _engine.loadModel('/path/to/embeddings-model.gguf');

// Generate embeddings for documents
final embedding = await _engine.embed('Document text');

// Store in vector database
await _vectorDb.insert(embedding, documentId);
```

---

## Fallback Plan

If `llamadart` encounters issues:

1. **Investigate issue** - Check GitHub issues and discussions
2. **Try pre-built binaries** - Download from GitHub releases manually
3. **Contact maintainers** - Open issue if needed
4. **Fall back to `llm_llamacpp`** - Only if llamadart is completely broken
   - Would require setting up CMake + NDK
   - Would delay Phase 1 by 2-3 days

---

## Timeline

| Task | Estimate |
|------|----------|
| Add llamadart to pubspec.yaml | 0.5 days |
| Update benchmark_screen.dart | 1-2 days |
| Test on Infinix-Note50 | 1 day |
| Measure performance metrics | 1-2 days |
| Implement embeddings | 1-2 days |
| **Total** | **4-7 days** |

---

## Success Criteria

- ✓ `llamadart` builds without errors
- ✓ Models load successfully on Infinix-Note50
- ✓ Actual inference runs (not simulated)
- ✓ Performance metrics measured and logged
- ✓ Embeddings working for RAG layer
- ✓ No Windows-specific build issues

---

## Next Steps

1. **Immediately:** Add `llamadart` to pubspec.yaml
2. **Today:** Update benchmark_screen.dart with actual inference
3. **Tomorrow:** Test on Infinix-Note50
4. **This week:** Measure performance and implement embeddings

---

**Decision Made:** Proceed with `llamadart` as primary LLM library.

Generated: 2026-08-22
