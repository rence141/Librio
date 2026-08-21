# Phase 1: Actual Model Integration & Inference

**Status:** In Progress  
**Start Date:** 2026-08-22  
**Target Completion:** TBD

---

## Overview

Phase 1 focuses on replacing Phase 0's simulated inference with actual GGUF model loading, measuring real performance, and implementing the RAG layer for grounded tutoring.

### Key Objectives

1. ✓ Choose LLM integration library
2. ✓ Set up native build environment
3. ✓ Integrate GGUF model loading
4. ✓ Test actual inference on device
5. ✓ Measure real performance metrics
6. ✓ Implement RAG layer
7. ✓ Validate quality
8. ✓ Optimize for production

---

## 1. LLM Integration Library Selection

### Option A: `llamadart` (Recommended)
**Pros:**
- Unified GGUF + LiteRT-LM support
- Modern, actively maintained
- Better long-term compatibility
- Single API for iOS/Android

**Cons:**
- Newer (less battle-tested)
- May have fewer pre-built binaries

**Status:** Investigating

### Option B: `llm_llamacpp` (Current)
**Pros:**
- Mature, widely used
- Good documentation
- Pre-built binaries available

**Cons:**
- Native asset building fails on Windows
- Requires CMake + platform toolchains
- Separate iOS/Android implementations

**Status:** Failed on Windows; may work with proper setup

### Decision Criteria
- [ ] Can build on Windows dev machine
- [ ] Can build on CI/CD (GitHub Actions)
- [ ] Supports both iOS and Android
- [ ] Good performance on 4GB devices
- [ ] Active maintenance

**Recommendation:** Try `llamadart` first; fall back to `llm_llamacpp` with proper CMake setup if needed.

---

## 2. Native Build Environment Setup

### Windows Development Machine

**Required:**
- [ ] CMake 3.20+ (for llm_llamacpp)
- [ ] Android NDK (for native compilation)
- [ ] Clang/LLVM toolchain
- [ ] unzip utility (for Windows)

**Steps:**
1. Install CMake from cmake.org
2. Install Android NDK from Google
3. Configure Flutter to use NDK
4. Test native asset building

**Verification:**
```bash
flutter doctor -v
cmake --version
ndk-build --version
```

### CI/CD (GitHub Actions)

**Required:**
- [ ] Android NDK in CI environment
- [ ] CMake in CI environment
- [ ] Proper caching for build artifacts

**Status:** TBD (after local setup works)

---

## 3. GGUF Model Loading Integration

### Current State
- Phase 0: Simulated inference (300ms per prompt)
- Models: Downloaded but not loaded

### Phase 1 Changes

**Flutter App Changes:**
1. Add LLM library to `pubspec.yaml`
2. Update `benchmark_screen.dart` to load actual GGUF models
3. Implement real inference loop
4. Capture actual TTFT and decode speed
5. Handle model loading errors gracefully

**Model Files:**
- `bench/models/gemma-3-1b-q4_k_m.gguf` (600 MB)
- `bench/models/llama-3.2-1b-q4_k_m.gguf` (800 MB)
- `bench/models/smollm2-1.7b-q4_k_m.gguf` (1000 MB)

**Expected Changes:**
- Longer load time (first-time model loading)
- Real TTFT measurement
- Real decode speed
- Actual token generation

---

## 4. Performance Measurement

### Metrics to Capture

**Inference Performance:**
- [ ] Model load time (first load vs. cached)
- [ ] Time to first token (TTFT)
- [ ] Decode speed (tokens/second)
- [ ] Total response time for 30 tokens
- [ ] Inference latency distribution (min/max/p50/p95/p99)

**Resource Usage:**
- [ ] Peak RAM during inference
- [ ] CPU usage (%)
- [ ] GPU usage (if applicable)
- [ ] Thermal throttling events

**Battery:**
- [ ] Battery drain during inference (mAh/min)
- [ ] Battery drain at idle (mAh/min)
- [ ] Estimated battery life with continuous inference
- [ ] Temperature during inference

**Data Collection:**
```dart
// Pseudo-code for measurement
final startTime = DateTime.now();
final firstTokenTime = DateTime.now();
final tokens = await model.generate(prompt);
final endTime = DateTime.now();

final ttft = firstTokenTime.difference(startTime).inMilliseconds;
final totalTime = endTime.difference(startTime).inMilliseconds;
final decodeSpeed = (tokens.length - 1) * 1000 / (totalTime - ttft);
```

### Tools
- [ ] Android Profiler (CPU, Memory, Battery)
- [ ] Logcat (for timing logs)
- [ ] Custom instrumentation in app
- [ ] Battery Historian (for battery analysis)

---

## 5. RAG Layer Implementation

### Architecture

```
User Query
    ↓
[Embeddings] → Query embedding (all-MiniLM-L6-v2)
    ↓
[Vector DB] → Retrieve top-K relevant documents
    ↓
[Context] → Build prompt with retrieved context
    ↓
[LLM] → Generate grounded response
    ↓
Response
```

### Components

**A. Embeddings Model**
- Model: `all-MiniLM-L6-v2` (22 MB, 384-dim)
- Library: `sentence_transformers` (Python) or `flutter_tflite` (Dart)
- Storage: Quantized to int8 for mobile

**B. Vector Storage**
- Database: SQLite with `sqlite3_dart`
- Vector Extension: `sqlite-vec` or similar
- Schema:
  ```sql
  CREATE TABLE documents (
    id INTEGER PRIMARY KEY,
    content TEXT,
    embedding BLOB,  -- 384-dim float32
    source TEXT,
    created_at TIMESTAMP
  );
  ```

**C. Retrieval**
- Top-K retrieval (k=3-5)
- Similarity metric: Cosine distance
- Filtering: By source, date, etc.

**D. Prompt Grounding**
```
System: You are an academic tutor. Use the provided context to answer questions.

Context:
[Retrieved document 1]
[Retrieved document 2]
[Retrieved document 3]

User: [Query]
```

### Data Sources (Phase 1)
- [ ] Academic textbooks (math, physics, chemistry, biology)
- [ ] Wikipedia articles (science, history, geography)
- [ ] Khan Academy transcripts (if available)
- [ ] Custom academic content

**Status:** TBD (licensing and availability)

---

## 6. Academic Prompt Test Suite

### Test Categories

**Mathematics (5 prompts)**
- Algebra (linear equations, polynomials)
- Geometry (shapes, proofs)
- Calculus (derivatives, integrals)
- Statistics (probability, distributions)
- Number theory (primes, modular arithmetic)

**Science (5 prompts)**
- Physics (mechanics, thermodynamics, electromagnetism)
- Chemistry (reactions, bonding, periodic table)
- Biology (cells, evolution, genetics)
- Earth Science (geology, weather, climate)

**Humanities (5 prompts)**
- History (major events, civilizations)
- Geography (capitals, regions, climate zones)
- English (literature, grammar, writing)
- Economics (supply/demand, markets)
- Psychology (cognition, behavior, development)

**Reasoning (5 prompts)**
- Logic puzzles
- Multi-step problems
- Comparative analysis
- Cause-and-effect reasoning
- Critical thinking

### Evaluation Criteria

**Quality Metrics:**
- [ ] Factual accuracy (0-5)
- [ ] Completeness (0-5)
- [ ] Clarity (0-5)
- [ ] Relevance to query (0-5)
- [ ] Pedagogical value (0-5)

**Scoring:**
- 5: Excellent, ready for production
- 4: Good, minor issues
- 3: Acceptable, some issues
- 2: Poor, significant issues
- 1: Unacceptable, major errors

**Pass Criteria:**
- Average score ≥ 3.5 across all prompts
- No scores < 2 on any prompt
- Factual accuracy ≥ 4.0 average

---

## 7. Quality Validation

### User Testing
- [ ] Recruit 5-10 student users
- [ ] Have them use app for tutoring
- [ ] Collect feedback on:
  - Response quality
  - Relevance
  - Helpfulness
  - Accuracy
  - Speed

### Automated Testing
- [ ] Unit tests for embeddings
- [ ] Integration tests for RAG retrieval
- [ ] Performance benchmarks
- [ ] Regression tests for model outputs

### Documentation
- [ ] Benchmark results
- [ ] Quality scores
- [ ] User feedback summary
- [ ] Known limitations

---

## 8. Performance Optimization

### Battery Optimization
- [ ] Profile inference power consumption
- [ ] Optimize model quantization
- [ ] Implement inference batching
- [ ] Use lower precision (int8) where possible
- [ ] Reduce model size if needed

### Speed Optimization
- [ ] Profile inference bottlenecks
- [ ] Optimize embeddings computation
- [ ] Cache embeddings for common queries
- [ ] Implement parallel retrieval
- [ ] Consider model pruning

### Memory Optimization
- [ ] Profile peak memory usage
- [ ] Implement model streaming (if needed)
- [ ] Optimize vector storage
- [ ] Reduce context window if needed

---

## 9. Documentation & Reporting

### Phase 1 Report
- [ ] Actual performance metrics (vs. Phase 0 estimates)
- [ ] Quality evaluation results
- [ ] User feedback summary
- [ ] Known limitations and workarounds
- [ ] Recommendations for Phase 2

### Technical Documentation
- [ ] LLM integration guide
- [ ] RAG architecture documentation
- [ ] API documentation
- [ ] Deployment guide

### Code Documentation
- [ ] Inline code comments
- [ ] Function documentation
- [ ] Architecture diagrams
- [ ] Data flow diagrams

---

## Timeline Estimate

| Task | Estimate | Status |
|------|----------|--------|
| Library selection | 1-2 days | In Progress |
| Native build setup | 2-3 days | Pending |
| Model loading integration | 2-3 days | Pending |
| Performance measurement | 2-3 days | Pending |
| RAG implementation | 3-5 days | Pending |
| Test suite creation | 1-2 days | Pending |
| Quality validation | 2-3 days | Pending |
| Optimization | 2-3 days | Pending |
| Documentation | 1-2 days | Pending |
| **Total** | **16-26 days** | **In Progress** |

---

## Success Criteria

- ✓ Actual GGUF model loads and runs on Infinix-Note50
- ✓ Real inference metrics measured and documented
- ✓ RAG layer implemented and tested
- ✓ Academic prompt test suite passes (avg score ≥ 3.5)
- ✓ Battery drain < 10%/hr during inference
- ✓ Response time < 3 seconds for 30 tokens
- ✓ User feedback positive (avg rating ≥ 4/5)
- ✓ All code committed and documented

---

## Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Native build fails on Windows | High | High | Use pre-built binaries or Docker |
| Model too slow on 4GB device | Medium | High | Optimize quantization or use smaller model |
| RAG retrieval too slow | Medium | Medium | Implement caching and indexing |
| Quality not acceptable | Low | High | Improve prompt engineering or model |
| Battery drain too high | Medium | Medium | Optimize inference and reduce frequency |

---

## Next Steps

1. **Investigate `llamadart`** - Check compatibility and features
2. **Set up CMake** - Prepare Windows build environment
3. **Test model loading** - Get first actual inference working
4. **Measure performance** - Baseline real metrics
5. **Implement RAG** - Build vector storage and retrieval
6. **Create test suite** - Prepare quality evaluation
7. **Validate quality** - Run tests and gather feedback
8. **Optimize** - Improve battery and speed
9. **Document** - Write Phase 1 report

---

Generated: 2026-08-22  
Status: In Progress
