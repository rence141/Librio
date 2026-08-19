# Phase 0: Model Acquisition Guide

This document explains how to download the candidate GGUF models for Phase 0 benchmarking.

## Quick Start

### Option 1: Using huggingface-cli (Recommended)

Install huggingface-cli if you don't have it:
```bash
pip install huggingface-hub
```

Then download models:
```bash
# 4GB tier (fastest)
huggingface-cli download bartowski/google_gemma-3-1b-it-GGUF --include "gemma-3-1b-it-Q4_K_M.gguf" --local-dir ./bench/models/

huggingface-cli download bartowski/Llama-3.2-1B-Instruct-GGUF --include "Llama-3.2-1B-Instruct-Q4_K_M.gguf" --local-dir ./bench/models/

huggingface-cli download bartowski/SmolLM3-1.7B-Instruct-GGUF --include "SmolLM3-1.7B-Instruct-Q4_K_M.gguf" --local-dir ./bench/models/

# 8GB tier (optional)
huggingface-cli download bartowski/google_gemma-3-4b-it-GGUF --include "gemma-3-4b-it-Q4_K_M.gguf" --local-dir ./bench/models/

huggingface-cli download bartowski/Qwen2.5-3B-Instruct-GGUF --include "Qwen2.5-3B-Instruct-Q4_K_M.gguf" --local-dir ./bench/models/
```

### Option 2: Manual Download

Visit these HuggingFace repositories and download the Q4_K_M quantized files:

**4GB Tier (Minimum):**
1. **Gemma 3 1B** (~0.8 GB)
   - Repo: https://huggingface.co/bartowski/google_gemma-3-1b-it-GGUF
   - File: `gemma-3-1b-it-Q4_K_M.gguf`
   - Note: Requires accepting Gemma license on HuggingFace

2. **Llama 3.2 1B** (~0.8 GB)
   - Repo: https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF
   - File: `Llama-3.2-1B-Instruct-Q4_K_M.gguf`

3. **SmolLM3 1.7B** (~1 GB)
   - Repo: https://huggingface.co/bartowski/SmolLM3-1.7B-Instruct-GGUF
   - File: `SmolLM3-1.7B-Instruct-Q4_K_M.gguf`

**8GB Tier (Optional):**
4. **Gemma 3 4B** (~2.3 GB)
   - Repo: https://huggingface.co/bartowski/google_gemma-3-4b-it-GGUF
   - File: `gemma-3-4b-it-Q4_K_M.gguf`

5. **Qwen 3 3B** (~2 GB)
   - Repo: https://huggingface.co/bartowski/Qwen2.5-3B-Instruct-GGUF
   - File: `Qwen2.5-3B-Instruct-Q4_K_M.gguf`

Save all files to: `bench/models/`

## Model Mapping

After downloading, rename files to match the benchmark harness expectations:

```
bench/models/
├── gemma3-1b-q4.gguf          (from gemma-3-1b-it-Q4_K_M.gguf)
├── llama32-1b-q4.gguf         (from Llama-3.2-1B-Instruct-Q4_K_M.gguf)
├── smollm3-1.7b-q4.gguf       (from SmolLM3-1.7B-Instruct-Q4_K_M.gguf)
├── gemma3-4b-q4.gguf          (from gemma-3-4b-it-Q4_K_M.gguf)
└── qwen3-3b-q4.gguf           (from Qwen2.5-3B-Instruct-Q4_K_M.gguf)
```

## Verify Downloads

After downloading, verify file sizes:

```bash
ls -lh bench/models/
```

Expected sizes (approximate):
- `gemma3-1b-q4.gguf`: 0.8 GB
- `llama32-1b-q4.gguf`: 0.8 GB
- `smollm3-1.7b-q4.gguf`: 1.0 GB
- `gemma3-4b-q4.gguf`: 2.3 GB
- `qwen3-3b-q4.gguf`: 2.0 GB

## Licensing

All models are open-source with permissive licenses:

- **Gemma 3**: Google's Gemma License (acceptable for educational use)
- **Llama 3.2**: Meta's Llama 2 Community License (acceptable for educational use)
- **SmolLM3**: Apache 2.0 (fully open)
- **Qwen 3**: Qwen License (acceptable for educational use)

See `docs/phase0-model-selection.md` for full license compliance notes.

## Next Steps

Once models are downloaded:

1. Run the benchmark harness on your device(s):
   ```bash
   cd bench
   dart run bin/bench.dart --model gemma3-1b-q4 --backend cpu --device <device-name>
   ```

2. Populate `docs/phase0-model-selection.md` with results

3. Select the best model based on Phase 0 KPIs:
   - TTFT <3s
   - Battery <10%/hr
   - No OOM on Tier A (4GB)
   - Acceptable quality

## Troubleshooting

**HuggingFace License Error:**
- Visit the model repo on HuggingFace
- Click "Agree and access repository"
- Then retry the download

**Network Issues:**
- Use a VPN if HuggingFace is blocked in your region
- Try downloading during off-peak hours
- Use `aria2c` for resumable downloads: `aria2c -x 16 <url>`

**Disk Space:**
- Ensure you have at least 10 GB free (all 5 models)
- Or download only the 4GB tier first (~3 GB)
