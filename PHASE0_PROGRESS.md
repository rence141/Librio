# Phase 0 Progress Report

**Status:** Infrastructure complete, models acquired, ready for benchmarking

**Last updated:** 2026-08-20

---

## ✅ Completed

### Infrastructure (100%)
- [x] Monorepo scaffolding (Flutter + Node.js + benchmark harness)
- [x] Flutter app with llm_llamacpp dependency
- [x] Node.js API with Express, TypeScript, ESLint
- [x] PostgreSQL docker-compose setup
- [x] GitHub Actions CI (Flutter, Node, benchmark)
- [x] Benchmark harness CLI framework
- [x] AI report guardrails template
- [x] Phase 0 documentation templates

### Model Acquisition (100%)
- [x] Download script (Python + PowerShell + Bash)
- [x] Gemma 3 1B Q4_K_M (769 MB) ✓
- [x] Llama 3.2 1B Q4_K_M (770 MB) ✓
- [x] SmolLM2 1.7B Q4_K_M (1007 MB) ✓

**Total downloaded:** 2.5 GB (4GB tier models)

---

## ⏳ Remaining (Phase 0 Execution)

### On-Device Benchmarking
To complete Phase 0, you need to:

1. **Run benchmark harness on physical Android device(s):**
   ```bash
   cd bench
   dart run bin/bench.dart --model gemma3-1b-q4 --backend cpu --device <device-name>
   ```
   
   Measure for each model:
   - Load time (ms)
   - Time-to-first-token (TTFT, ms)
   - Decode speed (tokens/sec)
   - Peak RAM (MB)
   - Battery drain (%/hr)

2. **Quality evaluation:**
   - Run 20 academic prompts on each model
   - Score 1–5 on: summarization, reasoning, factual accuracy
   - Blind evaluation recommended

3. **Populate documentation:**
   - `docs/phase0-model-selection.md` — benchmark results + recommendation
   - `docs/phase0-device-compatibility.md` — confirmed devices + known issues

### Phase 0 Success Criteria

**Model selection (choose 1):**
- [ ] TTFT <3s (TTFT + ~30 tokens at decode speed)
- [ ] Battery drain <10%/hr
- [ ] No OOM on 4GB RAM device
- [ ] Acceptable quality (subjective, 3+ rating)

**Device compatibility:**
- [ ] Confirmed on ≥1 Tier A device (4GB RAM, Android 11+)
- [ ] No crashes in airplane mode
- [ ] Documented in compatibility report

**Documentation:**
- [ ] `phase0-model-selection.md` filled with measured numbers
- [ ] `phase0-device-compatibility.md` lists confirmed devices
- [ ] All claims have confidence levels (✓ High / ≈ Medium / ⚠ Low)

---

## Models Available

### 4GB Tier (Downloaded ✓)

| Model | Size | Location | Status |
|-------|------|----------|--------|
| Gemma 3 1B Q4_K_M | 769 MB | `bench/models/google_gemma-3-1b-it-Q4_K_M.gguf` | ✓ Ready |
| Llama 3.2 1B Q4_K_M | 770 MB | `bench/models/Llama-3.2-1B-Instruct-Q4_K_M.gguf` | ✓ Ready |
| SmolLM2 1.7B Q4_K_M | 1007 MB | `bench/models/SmolLM2-1.7B-Instruct-Q4_K_M.gguf` | ✓ Ready |

### 8GB Tier (Optional, not downloaded)

To download 8GB tier models:
```bash
cd bench
python download_models.py gemma3-4b-q4
python download_models.py qwen3-3b-q4
```

---

## Next Steps

### Immediate (Required for Phase 0 completion)
1. Obtain an Android device (4GB+ RAM, Android 11+)
2. Transfer one GGUF model to the device
3. Run benchmark harness and measure performance
4. Fill in `docs/phase0-model-selection.md` with results
5. Select the best model based on Phase 0 KPIs

### If you don't have a device
- Phase 0 infrastructure is complete
- Mark Phase 0 as "Infrastructure Ready, Benchmarking Deferred"
- Proceed to Phase 1 planning with placeholder model selection
- Actual benchmarking can happen in Phase 1 with real devices

### Phase 1 (After Phase 0)
- Integrate selected model into Flutter app
- Implement local LLM inference
- Build lightweight RAG layer
- Implement mobile ↔ server sync API

---

## File Structure

```
librio/
├── bench/
│   ├── models/                      # Downloaded GGUF files
│   │   ├── google_gemma-3-1b-it-Q4_K_M.gguf
│   │   ├── Llama-3.2-1B-Instruct-Q4_K_M.gguf
│   │   └── SmolLM2-1.7B-Instruct-Q4_K_M.gguf
│   ├── download_models.py           # Python downloader
│   ├── download_models.sh           # Bash downloader
│   ├── download_models.ps1          # PowerShell downloader
│   ├── MODELS_DOWNLOAD.md           # Download guide
│   ├── models.json                  # Model metadata
│   ├── prompts.json                 # 20 benchmark prompts
│   └── bin/bench.dart               # Benchmark CLI
├── docs/
│   ├── AI_REPORT_TEMPLATE.md        # Guardrails for AI reports
│   ├── phase0-model-selection.md    # [TO BE FILLED]
│   └── phase0-device-compatibility.md # [TO BE FILLED]
├── PHASE0_PROGRESS.md               # This file
└── ...
```

---

## Licensing

All downloaded models are open-source with permissive licenses:

- **Gemma 3 1B:** Google Gemma License (acceptable for educational use)
- **Llama 3.2 1B:** Meta Llama 2 Community License (acceptable for educational use)
- **SmolLM2 1.7B:** Apache 2.0 (fully open)

See `bench/MODELS_DOWNLOAD.md` for full details.

---

## Troubleshooting

**Models not downloading?**
- Check internet connection
- Try `python bench/download_models.py --list` to verify repo names
- Use VPN if HuggingFace is blocked in your region

**Benchmark harness not running?**
- Ensure Dart SDK is installed: `dart --version`
- Run `cd bench && dart pub get` to fetch dependencies
- Check that model file exists in `bench/models/`

**Device issues?**
- Ensure Android 11+ and ≥4GB RAM
- Enable USB debugging for adb access
- Test with simple app first (e.g., llama.cpp Android example)

---

## Questions?

Refer to:
- `AGENTS.md` — build/test commands
- `bench/MODELS_DOWNLOAD.md` — model acquisition guide
- `docs/AI_REPORT_TEMPLATE.md` — report guardrails
- `Librio_Feasible_Roadmap_Flutter_NodeJS.md` — original roadmap
