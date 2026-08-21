# Phase 1 Testing Guide

**Date:** 2026-08-22  
**Status:** Ready for Testing  
**Device:** Infinix-Note50 (4GB RAM, Android 16)

---

## Overview

This guide walks you through testing Phase 1's actual GGUF model loading and inference on your Infinix-Note50.

### What You'll Test

- ✓ Actual GGUF model loading (vs. Phase 0's simulated loading)
- ✓ Real inference with streaming tokens
- ✓ Performance measurement (TTFT, decode speed, load time)
- ✓ Error handling and recovery
- ✓ Model management (download, cache, storage)

### Expected Outcomes

| Metric | Phase 0 | Phase 1 Target | Notes |
|--------|---------|-----------------|-------|
| Model Load | 500ms | <2s | Real loading time |
| TTFT | ~50ms | <500ms | Time to first token |
| Decode Speed | ~100 tok/s | >20 tok/s | Tokens per second |
| Peak RAM | ~850MB | <1.5GB | Memory usage |
| Battery Drain | N/A | <10%/hr | To be measured |

---

## Option A: Automatic Model Transfer (Recommended)

### Step 1: Prepare Models

Models are already downloaded in `bench/models/`:
- `gemma-3-1b-q4_k_m.gguf` (600 MB)
- `llama-3.2-1b-q4_k_m.gguf` (800 MB)
- `smollm2-1.7b-q4_k_m.gguf` (1000 MB)

### Step 2: Run Transfer Script

**On Windows (PowerShell):**

```powershell
cd C:\dev\Librio\bench
.\transfer_models.ps1
```

**Expected output:**
```
=== Librio Model Transfer Script ===
Device: adb-138097055K002303-DxquAm._adb-tls-connect._tcp
Local models: C:\dev\Librio\bench\models
Device target: /data/user/0/com.librio.librio/app_flutter/models

Checking device connection...
✓ Device connected

Found 3 model(s):
  - gemma-3-1b-q4_k_m.gguf (600.00 MB)
  - llama-3.2-1b-q4_k_m.gguf (800.00 MB)
  - smollm2-1.7b-q4_k_m.gguf (1000.00 MB)

Creating device directory...
✓ Directory created

Transferring: gemma-3-1b-q4_k_m.gguf (600.00 MB)
✓ Transferred: gemma-3-1b-q4_k_m.gguf (15.50 MB/s)

Transferring: llama-3.2-1b-q4_k_m.gguf (800.00 MB)
✓ Transferred: llama-3.2-1b-q4_k_m.gguf (16.20 MB/s)

Transferring: smollm2-1.7b-q4_k_m.gguf (1000.00 MB)
✓ Transferred: smollm2-1.7b-q4_k_m.gguf (15.80 MB/s)

=== Transfer Complete ===
Total transferred: 2400.00 MB

Next steps:
1. Open the Librio app on your phone
2. Go to the Benchmark screen
3. Tap 'Start Benchmark'
4. Watch the logs as it loads and runs inference on the models
```

**Time estimate:** ~2.5-3 hours (2400 MB at ~15 MB/s)

### Step 3: Run Benchmark on Phone

1. **Open Librio app** on Infinix-Note50
2. **Navigate to Benchmark screen** (should already be there)
3. **Tap "Start Benchmark"** button
4. **Watch the logs** in real-time:
   - Model loading progress
   - TTFT measurement
   - Decode speed
   - Inference results

### Step 4: Collect Results

Results are saved to:
```
/data/user/0/com.librio.librio/app_flutter/benchmark_results/
```

Files created:
- `Infinix-Note50-gemma3-1b-q4-phase1-*.json`
- `Infinix-Note50-llama32-1b-q4-phase1-*.json`
- `Infinix-Note50-smollm2-1.7b-q4-phase1-*.json`

---

## Option B: In-App Download (Future)

### Coming Soon

The app will support automatic HuggingFace downloads:

```dart
// In the app (not yet implemented)
final modelManager = ModelManager();
await modelManager.init();

// Download model
await modelManager.downloadModel(
  'gemma3-1b-q4',
  onProgress: (downloaded, total) {
    print('Downloaded: $downloaded / $total bytes');
  },
);

// Use model
final modelPath = modelManager.getModelPath('gemma3-1b-q4');
```

**Status:** Code skeleton created in `lib/services/model_manager.dart`

---

## Expected Logs

### Successful Benchmark Run

```
=== Librio Phase 1 Benchmark (Actual Inference) ===
Device: Infinix-Note50
Dart SDK: 3.10.8 (stable) on "android_arm64"

Device Info: Infinix-Note50 (Android)

Memory: RAM: ~4GB available

Testing model: gemma3-1b-q4
  [*] Model file: /data/user/0/com.librio.librio/app_flutter/models/gemma-3-1b-q4_k_m.gguf
  [*] Loading model: gemma3-1b-q4
  [✓] Model loaded in 1250ms
  [*] Prompt 1/5: "What is photosynthesis?"
      Time: 2450ms | Tokens: 45 | Speed: 18.4 tok/s
  [*] Prompt 2/5: "Solve: 2x + 5 = 13"
      Time: 2380ms | Tokens: 42 | Speed: 17.6 tok/s
  [*] Prompt 3/5: "Explain Newton's first law of motion."
      Time: 2510ms | Tokens: 48 | Speed: 19.1 tok/s
  [*] Prompt 4/5: "What is the capital of France?"
      Time: 2290ms | Tokens: 38 | Speed: 16.6 tok/s
  [*] Prompt 5/5: "How do plants absorb water?"
      Time: 2420ms | Tokens: 44 | Speed: 18.2 tok/s
  [Summary]
    Load time: 1250ms
    TTFT: 85ms
    Avg inference: 2412ms
    Avg speed: 18.2 tok/s
  [✓] Result saved to: /data/user/0/com.librio.librio/app_flutter/benchmark_results/Infinix-Note50-gemma3-1b-q4-phase1-1787345044359.json
  [✓] Model unloaded

Testing model: llama32-1b-q4
  [*] Model file: /data/user/0/com.librio.librio/app_flutter/models/llama-3.2-1b-q4_k_m.gguf
  [*] Loading model: llama32-1b-q4
  [✓] Model loaded in 1380ms
  [*] Prompt 1/5: "What is photosynthesis?"
      Time: 2680ms | Tokens: 48 | Speed: 17.9 tok/s
  ...
  [✓] Model unloaded

Testing model: smollm2-1.7b-q4
  [*] Model file: /data/user/0/com.librio.librio/app_flutter/models/smollm2-1.7b-q4_k_m.gguf
  [*] Loading model: smollm2-1.7b-q4
  [✓] Model loaded in 1520ms
  [*] Prompt 1/5: "What is photosynthesis?"
      Time: 2890ms | Tokens: 51 | Speed: 17.6 tok/s
  ...
  [✓] Model unloaded

=== Benchmark finished ===
```

### Error Handling

**Missing Model File:**
```
[*] Model file: /data/user/0/com.librio.librio/app_flutter/models/gemma-3-1b-q4_k_m.gguf
[ERROR] Model file not found: /data/user/0/com.librio.librio/app_flutter/models/gemma-3-1b-q4_k_m.gguf
[INFO] Phase 1 requires actual GGUF files in bench/models/
```

**Model Load Failure:**
```
[*] Loading model: gemma3-1b-q4
[ERROR] Failed to load model: Native asset not available
[INFO] This may be due to missing native assets or incompatible model format
```

---

## Troubleshooting

### Issue: "Model file not found"

**Solution:** Run the transfer script to copy models to device

```powershell
.\transfer_models.ps1
```

### Issue: "Failed to load model: Native asset not available"

**Possible causes:**
1. llamadart native assets not properly built
2. Model file corrupted during transfer
3. Insufficient memory on device

**Solutions:**
1. Rebuild app: `flutter clean && flutter run`
2. Re-transfer models: `.\transfer_models.ps1`
3. Close other apps to free memory

### Issue: Slow inference (>5s per prompt)

**Possible causes:**
1. Device thermal throttling
2. Other apps using CPU
3. Model too large for device

**Solutions:**
1. Let device cool down
2. Close background apps
3. Use smaller model (SmolLM2 1.7B instead of larger models)

### Issue: App crashes during inference

**Possible causes:**
1. Out of memory (OOM)
2. Model file corrupted
3. llamadart bug

**Solutions:**
1. Close other apps
2. Re-transfer models
3. Check device logs: `adb logcat | grep flutter`

---

## Performance Analysis

### Metrics to Collect

For each model, record:
- **Load Time:** Time to load model into memory
- **TTFT:** Time to first token (ms)
- **Decode Speed:** Tokens per second (tok/s)
- **Total Time:** Time for all 5 prompts
- **Peak RAM:** Maximum memory used (from Android Profiler)
- **CPU Usage:** Average CPU usage (from Android Profiler)

### Expected Performance

**Gemma 3 1B Q4_K_M:**
- Load: 1-2s
- TTFT: 50-150ms
- Speed: 15-25 tok/s
- RAM: 800-1000 MB

**Llama 3.2 1B Q4_K_M:**
- Load: 1-2s
- TTFT: 60-180ms
- Speed: 12-20 tok/s
- RAM: 900-1100 MB

**SmolLM2 1.7B Q4_K_M:**
- Load: 1.5-2.5s
- TTFT: 70-200ms
- Speed: 10-18 tok/s
- RAM: 1000-1300 MB

### Comparison with Phase 0

| Metric | Phase 0 | Phase 1 | Difference |
|--------|---------|---------|-----------|
| Load Time | 500ms | 1-2s | +100-300% (real loading) |
| TTFT | ~50ms | 50-200ms | +0-300% (real inference) |
| Decode Speed | ~100 tok/s | 10-25 tok/s | -75-90% (real inference) |
| Peak RAM | ~850MB | 800-1300MB | Similar |

---

## Next Steps After Testing

### 1. Analyze Results
- Compare Phase 0 vs Phase 1
- Identify bottlenecks
- Plan optimizations

### 2. Implement RAG Layer
- Embeddings model integration
- Vector database setup
- Retrieval implementation

### 3. Quality Validation
- Run 25-prompt test suite
- Score responses (1-5 scale)
- Gather user feedback

### 4. Optimize Performance
- Profile inference bottlenecks
- Optimize quantization
- Reduce memory footprint
- Minimize battery drain

### 5. Document Results
- Create Phase 1 report
- Compare with Phase 0
- Recommendations for Phase 2

---

## Timeline

| Step | Time | Status |
|------|------|--------|
| Model transfer | 2.5-3h | Ready |
| Benchmark run | 15-20 min | Ready |
| Result analysis | 1-2h | Ready |
| RAG implementation | 3-5 days | Planned |
| Quality validation | 2-3 days | Planned |
| Optimization | 2-3 days | Planned |
| Documentation | 1-2 days | Planned |

---

## Success Criteria

- ✓ Models load successfully on device
- ✓ Actual inference runs (not simulated)
- ✓ Performance metrics measured
- ✓ Results saved as JSON
- ✓ No crashes or errors
- ✓ Phase 0 vs Phase 1 comparison complete

---

## Support

If you encounter issues:

1. **Check logs:** `adb logcat | grep flutter`
2. **Verify device:** `adb devices`
3. **Check storage:** `adb shell df /data`
4. **Restart app:** Kill and relaunch
5. **Rebuild app:** `flutter clean && flutter run`

---

**Ready to test? Start with Option A (Automatic Model Transfer)!** 🚀

Generated: 2026-08-22
