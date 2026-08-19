# Librio

Offline-first AI academic tutor. Mobile-first (Flutter) with a Node.js web backend for sync and online features.

> Status: **Phase 0 — Setup & Model Selection** (in progress)

See the roadmap: [`Librio_Feasible_Roadmap_Flutter_NodeJS.md`](./Librio_Feasible_Roadmap_Flutter_NodeJS.md)
See the Phase 0 plan: `~/.devin/plans/plan-85570bbdb476cab4.md`

## Repository layout

```
apps/mobile/      Flutter app (iOS/Android, offline-first LLM + RAG)
services/api/     Node.js + Express + TypeScript backend (auth, sync, model router)
packages/         Shared types / contracts (mobile <-> API)
bench/            On-device LLM benchmark harness (Phase 0)
docs/             Project documentation (model selection, device compatibility)
.github/workflows CI
```

## Tech stack (Phase 0, 2026)

- **Mobile:** Flutter 3.38+ / Dart 3.10+
- **On-device LLM:** `llamadart` routing GGUF -> llama.cpp and `.litertlm` -> LiteRT-LM
- **Backend:** Node.js 24, Express, TypeScript, PostgreSQL 16
- **Models under evaluation:** Gemma 3 1B, Llama 3.2 1B, SmolLM3 1.7B (4GB tier);
  Gemma 3 4B, Gemma 3n E4B, Qwen3 3B (8GB tier)

## Quick start

See [`AGENTS.md`](./AGENTS.md) for build, test, and verification commands.
