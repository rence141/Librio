# AGENTS.md

Engineering conventions and verification commands for Librio.

## Toolchain (verified on dev machine)

- Flutter 3.38.9 stable, Dart 3.10.8
- Node.js v24.13.0, npm 11.6.2
- git 2.52
- Docker (for local PostgreSQL)

## Repository layout

- `apps/mobile/` — Flutter app
- `services/api/` — Node.js + Express + TypeScript API
- `packages/` — Shared types/contracts
- `bench/` — On-device LLM benchmark harness (Dart)
- `docs/` — Project documentation

## Commands

### Flutter (apps/mobile)

```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

### Node.js API (services/api)

```bash
cd services/api
npm install
npm run dev          # tsx watch mode
npm run build        # tsc -> dist/
npm run lint
npm test
```

### PostgreSQL (local)

```bash
cd services/api
docker compose up -d postgres
# verify: GET http://localhost:3000/health
```

### Benchmark harness (bench)

```bash
cd bench
dart pub get
dart run bin/bench.dart --model <id> --backend <cpu|vulkan|gpu> --device <name>
```

## Verification gates (Phase 0)

- `flutter doctor` clean
- `flutter analyze` clean on `apps/mobile`
- `npm run build` + `npm run lint` clean on `services/api`
- `docker compose up postgres` starts; `GET /health` returns 200
- Benchmark harness produces a JSON result on at least one Tier A device
- Selected model loads and generates in airplane mode without crashing

## Conventions

- TypeScript strict mode; zod for runtime validation
- pino for logging; never log secrets or PII
- Parameterized queries only (pg) — no string-interpolated SQL
- JWT for auth; secrets via `.env` (never committed)
- LLM weights are NEVER committed to git (see `.gitignore`)

## Roadmap drift (2026)

The roadmap MD (`Librio_Feasible_Roadmap_Flutter_NodeJS.md`) predates the 2026
runtime/model landscape. Phase 0 execution uses the modern stack
(LiteRT-LM + llama.cpp via `llamadart`; Gemma 3 / Llama 3.2 / SmolLM3 class
models). The roadmap MD itself is updated only with explicit approval.
