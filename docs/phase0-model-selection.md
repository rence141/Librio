# Phase 0: Model Selection Report

**Status:** Placeholder (to be populated during Phase 0 execution)

**Date:** TBD  
**Devices tested:** TBD  
**Backends tested:** TBD

---

## Executive Summary

This document records the on-device LLM model selection for Librio Phase 0. The goal is to identify a small, quantized model that:

- Runs on devices with ≥4GB RAM (minimum target)
- Generates responses in <3 seconds (TTFT + ~30 tokens)
- Consumes <10% battery per hour
- Does not crash in airplane mode
- Provides acceptable quality for academic tutoring with RAG grounding

---

## Candidate Models

### 4GB Tier (Minimum Target)

| Model | Size (MB) | Peak RAM (GB) | Tok/s (est.) | Notes |
|-------|-----------|---------------|--------------|-------|
| Gemma 3 1B Q4_K_M | 600 | 0.8 | ~26 | Google's latest 1B, excellent quality |
| Llama 3.2 1B Q4_K_M | 800 | 0.9 | ~20 | Meta's 1B, broad compatibility |
| SmolLM3 1.7B Q4_K_M | 1000 | 1.2 | ~18 | HuggingFace's efficient 1.7B |

### 8GB Tier (Secondary Target)

| Model | Size (MB) | Peak RAM (GB) | Tok/s (est.) | Notes |
|-------|-----------|---------------|--------------|-------|
| Gemma 3 4B Q4_K_M | 2300 | 2.8 | ~11 | Larger, better reasoning |
| Gemma 3n E4B Q4_K_M | 2000 | 2.5 | ~14 | Nested, efficient 4B |
| Qwen3 3B Q4_K_M | 2000 | 2.5 | ~12 | Multilingual, code-capable |

---

## Benchmark Results

### Tier A Devices (4GB RAM)

**Device 1:** [Device name / specs]  
**Device 2:** [Device name / specs]

| Model | Backend | Load (ms) | TTFT (ms) | Decode (tok/s) | Peak RSS (MB) | Battery (%/hr) | Status |
|-------|---------|-----------|-----------|----------------|---------------|----------------|--------|
| Gemma 3 1B | CPU | TBD | TBD | TBD | TBD | TBD | Pending |
| Llama 3.2 1B | CPU | TBD | TBD | TBD | TBD | TBD | Pending |
| SmolLM3 1.7B | CPU | TBD | TBD | TBD | TBD | TBD | Pending |

### Tier B Devices (8GB RAM)

**Device 1:** [Device name / specs]  
**Device 2:** [Device name / specs]

| Model | Backend | Load (ms) | TTFT (ms) | Decode (tok/s) | Peak RSS (MB) | Battery (%/hr) | Status |
|-------|---------|-----------|-----------|----------------|---------------|----------------|--------|
| Gemma 3 4B | CPU | TBD | TBD | TBD | TBD | TBD | Pending |
| Gemma 3 4B | Vulkan | TBD | TBD | TBD | TBD | TBD | Pending |
| Gemma 3 4B | LiteRT-LM GPU | TBD | TBD | TBD | TBD | TBD | Pending |

---

## Quality Evaluation

Blind evaluation of model outputs on 20 academic prompts (math, physics, biology, chemistry, history, English, geography, economics, psychology, reasoning).

| Model | Summarization (1–5) | Reasoning (1–5) | Factual Accuracy (1–5) | Avg |
|-------|---------------------|-----------------|------------------------|-----|
| Gemma 3 1B | TBD | TBD | TBD | TBD |
| Llama 3.2 1B | TBD | TBD | TBD | TBD |
| SmolLM3 1.7B | TBD | TBD | TBD | TBD |

---

## Recommendation

**Selected Model:** [Model ID]  
**Quantization:** [Q4_K_M / Q8_0]  
**Tier:** [4GB / 8GB]  
**Backend (Android):** [CPU / Vulkan / LiteRT-LM GPU]  
**Backend (iOS):** [CPU / Metal]

**Rationale:**

- [Meets TTFT requirement]
- [Acceptable battery drain]
- [Quality sufficient for RAG-grounded tutoring]
- [Fits within target device RAM]

---

## Known Limitations

- iOS benchmarks deferred to Phase 1 (no macOS/Xcode on dev machine)
- Battery measurements are approximate (manual measurement, ±2%)
- Quality evaluation is subjective; blind scoring by [N] evaluators recommended for production

---

## Next Steps

1. Finalize model selection by [date]
2. Integrate selected model into Flutter app (Phase 1)
3. Implement RAG layer with lightweight embeddings (Phase 1)
4. Test on App Store / Play Store compliance (Phase 3)
