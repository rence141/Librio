# Phase 0: Device Compatibility Report

**Status:** Placeholder (to be populated during Phase 0 execution)

**Date:** TBD  
**Tested by:** TBD

---

## Executive Summary

This document records the confirmed device compatibility matrix for Librio's selected on-device LLM. The goal is to establish:

- Minimum supported device specifications
- Known OOM / thermal failures
- Platform-specific backend recommendations
- Verified device list for Phase 1 QA

---

## Device Matrix

### Tier A: Minimum Target (4GB RAM, Android 11+)

| Device | OS | RAM | SoC | Model Status | Notes |
|--------|----|----|-----|--------------|-------|
| [Device 1] | Android 11 | 4GB | [SoC] | TBD | TBD |
| [Device 2] | Android 12 | 4GB | [SoC] | TBD | TBD |

**Tier A Success Criteria:**
- [ ] Selected 1B model loads without OOM
- [ ] Inference <3s per response (TTFT + 30 tokens)
- [ ] No crashes in airplane mode
- [ ] Battery drain <10%/hr

### Tier B: Secondary Target (8GB RAM, Android 12+)

| Device | OS | RAM | SoC | Model Status | Notes |
|--------|----|----|-----|--------------|-------|
| [Device 1] | Android 12 | 8GB | [SoC] | TBD | TBD |
| [Device 2] | Android 13 | 8GB | [SoC] | TBD | TBD |

**Tier B Success Criteria:**
- [ ] Selected 4B model loads without OOM
- [ ] Inference <2s per response (TTFT + 30 tokens)
- [ ] GPU backend (Vulkan / LiteRT-LM) functional
- [ ] Battery drain <8%/hr

### Tier C: iOS (Deferred to Phase 1)

| Device | OS | RAM | SoC | Model Status | Notes |
|--------|----|----|-----|--------------|-------|
| iPhone 13+ | iOS 16+ | 4GB+ | A15+ | Deferred | Requires macOS/Xcode |

---

## Backend Compatibility

### Android

| Backend | Devices | Performance | Notes |
|---------|---------|-------------|-------|
| CPU | All | Baseline | Slowest but most compatible |
| Vulkan | Modern (Snapdragon 8 Gen 1+) | Variable | Highly device/driver-dependent |
| LiteRT-LM GPU | Modern (Snapdragon 8 Gen 2+) | Best | Requires LiteRT-LM runtime |

**Recommendation:** Default to CPU for Phase 0 / Phase 1 MVP. Optimize GPU paths in Phase 2.

### iOS

| Backend | Devices | Performance | Notes |
|---------|---------|-------------|-------|
| CPU | All | Baseline | Slowest but most compatible |
| Metal | All | Good | Apple's GPU framework, well-optimized |

**Recommendation:** Defer iOS to Phase 1. Metal will be primary GPU path.

---

## Known Issues

### OOM Failures

| Device | Model | Quantization | Issue | Workaround |
|--------|-------|--------------|-------|-----------|
| TBD | TBD | TBD | TBD | TBD |

### Thermal Throttling

| Device | Model | Sustained Load | Issue | Workaround |
|--------|-------|----------------|-------|-----------|
| TBD | TBD | TBD | TBD | TBD |

### Driver / Compatibility Issues

| Device | Backend | Issue | Workaround |
|--------|---------|-------|-----------|
| TBD | TBD | TBD | TBD |

---

## Minimum Device Specifications (Final)

Based on Phase 0 testing:

### Tier A (Minimum)

- **OS:** Android 11+
- **RAM:** 4GB (minimum)
- **Storage:** 1GB free (for model + app)
- **SoC:** Any (CPU-only inference)

### Tier B (Recommended)

- **OS:** Android 12+
- **RAM:** 8GB
- **Storage:** 2GB free
- **SoC:** Snapdragon 8 Gen 2 or equivalent (for GPU acceleration)

### iOS (Phase 1+)

- **OS:** iOS 16+
- **Device:** iPhone 13 or newer
- **RAM:** 4GB+
- **SoC:** A15 Bionic or newer

---

## Verified Device List

### Approved for Phase 1 QA

- [ ] [Device 1 — Tier A]
- [ ] [Device 2 — Tier A]
- [ ] [Device 3 — Tier B]
- [ ] [Device 4 — Tier B]

### Known Unsupported

- Android 10 and below (too old)
- Devices with <4GB RAM (OOM risk)
- Devices with Snapdragon 7 Gen 1 and older (Vulkan performance too low)

---

## Next Steps

1. Finalize device list by [date]
2. Procure reference devices for Phase 1 QA if needed
3. Set up device lab / CI integration for automated testing
4. Document device-specific workarounds in Phase 1 release notes
