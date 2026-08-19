# LIBRIO

## Feasible Roadmap: Flutter Mobile + Node.js Web

**Offline-first AI academic tutor • Mobile-first accessibility • Privacy-conscious**

---

## Executive Summary

This roadmap condenses the original 9-stage strategy into 5 achievable phases with concurrent mobile (Flutter) and web (Node.js) development. The focus is on delivering a working offline MVP within 90 days, expanding to production features in months 4–6, and scaling sustainably after.

---

## Platform Stack

### Mobile
- Flutter (Dart) for iOS/Android with offline-first architecture
- Local SQLite for data storage, conversation history, and progress
- On-device LLM inference via TensorFlow Lite / ONNX Runtime

### Web
- Node.js + Express backend for API and cloud features
- PostgreSQL for user data, sync, and server-side state
- Optional: IndexedDB + Service Workers for progressive web offline support

### Shared
- REST API for mobile ↔ web sync and online features
- Model router (selects local vs. cloud LLM based on availability)
- Lightweight embeddings engine (ONNX) for both platforms

---

## 5-Phase Development Roadmap

### Phase 0: Setup & Model Selection (Weeks 1–2)

| | |
|---|---|
| **Objective** | Select local LLM; validate on target devices |
| **Key Work** | Benchmark 3–4 small models (Phi-3, Gemma 2B, Mistral 7B quantized)<br>Test RAM, inference speed, battery on low/mid-end Android + laptop<br>Finalize target device matrix (e.g., Android 11+, ≥4GB RAM)<br>Set up Flutter + Node.js dev environment |
| **Deliverable** | Selected model + quantized weights; device compatibility report |

### Phase 1: Mobile MVP (Weeks 3–8 / ~45 days)

| | |
|---|---|
| **Objective** | Working offline chat + RAG on Flutter |
| **Work Streams** | 1a. Flutter UI: chat interface, message history, settings<br>1b. Local inference: integrate TensorFlow Lite + selected model<br>1c. SQLite schema: conversations, messages, user data<br>1d. Document ingestion: simple PDF/DOCX upload + text extraction<br>1e. Local RAG: lightweight embedding model + vector search (SQLite FTS or simpler) |
| **Testing** | Offline chat works on 2–3 reference devices<br>Document upload and retrieval functional<br>No crashes in airplane mode |
| **Deliverable** | Android APK + iOS IPA (internal beta) |

### Phase 2: Web Backend & Sync (Weeks 8–12 / ~45 days parallel)

| | |
|---|---|
| **Objective** | Node.js backend + cloud sync for online features |
| **Work Streams** | 2a. Node.js API: Express server, auth (JWT), user management<br>2b. Database: PostgreSQL schema for users, conversations, materials<br>2c. Sync layer: mobile ↔ server sync for cross-device access<br>2d. Model router: fallback to cloud models (OpenAI / Anthropic API) when online<br>2e. Admin panel: basic material management, user analytics |
| **Testing** | Mobile-to-server sync works end-to-end<br>Online model fallback functional<br>Auth and user isolation validated |
| **Deliverable** | Staging API + mobile sync integration |

### Phase 3: Polish & Offline v1 Release (Weeks 12–16 / 30 days)

| | |
|---|---|
| **Objective** | Launch free offline v1 on App Store + Play Store |
| **Work Streams** | 3a. Performance: optimize battery, RAM, model load times<br>3b. Stability: crash fixes, edge cases, offline validation tests<br>3c. Content: curate 2–3 subject packs (e.g., Math, Physics, Biology)<br>3d. Store: app privacy, localization, marketing assets, release notes<br>3e. Docs: in-app help, offline limitations, privacy policy |
| **Testing** | App Store/Play Store compliance validation<br>Load test subject packs on low-end devices<br>Privacy & offline integrity checks |
| **Deliverable** | Librio Offline v1 on App Store + Play Store (public) |

### Phase 4: Web Release & Premium Features (Weeks 17–24 / 50 days)

| | |
|---|---|
| **Objective** | Web platform + free online tier + premium pilot |
| **Work Streams** | 4a. Web UI: React/Vue frontend for web chat + sync<br>4b. Free online: rate-limited access to cloud models for online users<br>4c. Premium: subscription tier (Stripe integration), entitlements<br>4d. Cross-device: web ↔ mobile conversation sync<br>4e. Analytics: anonymized usage, learning gains tracking |
| **Testing** | Web beta with 50–100 early users<br>Sync consistency across devices<br>Premium trial mode validated |
| **Deliverable** | Web beta + premium subscription infrastructure |

### Phase 5: Institutional & Scale (Weeks 24+ / Month 6+)

| | |
|---|---|
| **Objective** | Teacher tools, school licensing, advanced analytics |
| **Work Streams** | 5a. Teacher dashboard: class management, student progress, assignments<br>5b. School licensing: managed content deployment, bulk enrollment<br>5c. Advanced models: fine-tuned models for specific curricula<br>5d. Partnerships: content licensing, institutional integrations |
| **Deliverable** | Institutional Librio + pilot schools in month 9 |

---

## Technical Architecture Summary

### Offline Flow (Local)
```
Flutter UI → Local LLM (TFLite) → SQLite (history, progress) → Embedded vector DB (RAG)
```

### Online Flow (Connected)
```
Flutter / Web UI → Node.js API → Model Router → Cloud LLM (fallback) + PostgreSQL sync
```

### Hybrid Flow (Preferred)
Local model answers offline. When online: optionally use cloud for better quality. User data always syncs to server but local copy remains authoritative.

---

## Key Feasibility Decisions

1. **Start with one small model, not a custom one**  
   Use a proven quantized model (Phi-3, Gemma 2B) rather than training from scratch. This saves 3–6 months and is sufficient for offline tutoring with RAG grounding.

2. **Parallel mobile + web development**  
   Flutter and Node.js can progress independently. Sync API is the integration point. This shortens time-to-market for both platforms.

3. **Lightweight RAG, not semantic search**  
   Use SQLite FTS (full-text search) or simple TF-IDF before investing in large embedding models. Fast, small footprint, sufficient accuracy.

4. **MVP excludes premium features**  
   Offline v1 is free. Premium and institutional tiers come in Phase 4–5, funded by early adoption.

5. **Cloud model cost controls**  
   Rate-limit free online tier. Route simple queries to fast models. Use model caching. Premium users fund server costs.

---

## Estimated Effort & Team

| Phase | Duration | Core Team | Effort (Person-Weeks) |
|-------|----------|-----------|-----------------------|
| 0 (Setup) | 2 weeks | 1 ML + 1 Mobile | 4 |
| 1 (Mobile MVP) | 6 weeks | 1 Flutter, 1 Backend | 12 |
| 2 (Web Backend) | 5 weeks | 1 Backend, 1 DevOps | 10 |
| 3 (Polish & Release) | 4 weeks | 1 QA, 1 Content | 8 |
| 4 (Web Launch) | 8 weeks | 1 Frontend, 1 Full-Stack | 16 |
| 5 (Scale) | Ongoing | 2–3 (Product + Support) | Ongoing |

**Minimal viable team:** 3 engineers (1 Flutter, 1 Backend, 1 DevOps/Full-Stack) + 1 Product + 1 Content = 5 people for Phases 0–4. Add QA and design as you scale.

---

## Phase Success Criteria & KPIs

| Phase | Success Criteria |
|-------|------------------|
| 0 | ✓ Model selected & benchmarked on 3 devices<br>✓ Development environment stable |
| 1 | ✓ Chat works offline on 2+ devices<br>✓ No crashes in airplane mode<br>✓ Model inference <3s per response<br>✓ Battery impact acceptable (<10% per hour) |
| 2 | ✓ Sync works end-to-end<br>✓ Cloud fallback functional<br>✓ API under 200ms latency |
| 3 | ✓ Published on App Store & Play Store<br>✓ 1000+ downloads in week 1<br>✓ <1% crash rate |
| 4 | ✓ Web MVP in public beta<br>✓ 50+ users on web + mobile sync<br>✓ Premium signup flow working |

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Model too slow on phones | Benchmark early (Phase 0). Switch models if needed. Quantize aggressively. |
| Sync bugs block release | Start Phase 2 mid-Phase 1. Test sync extensively before Phase 4. |
| Hallucinations undermine trust | Invest in strong RAG (Phase 1). Show sources. Teach users limitations upfront. |
| Cloud costs spiral | Cap free tier. Rate-limit aggressively. Premium users fund cost. |
| App store rejection | Engage app stores early (Phase 3). Budget 2 weeks for compliance. Have contingency (web fallback). |

---

## Roadmap Summary

This 5-phase roadmap condenses Librio's vision into achievable milestones:

- **Phase 0–1:** Prove offline chat + RAG works (12 weeks)
- **Phase 2–3:** Launch free Librio Offline v1 (18 weeks total)
- **Phase 4–5:** Scale with web, premium, and schools (24+ weeks)

With a small core team (3–5 engineers + product/content), you can ship a viable product to users within 4 months. Parallel mobile + web development and deliberate scope management are essential.
