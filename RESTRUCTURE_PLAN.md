# Librio Restructure: Focus on Chat LLM (Phase 1 MVP)

**Date:** 2026-08-22  
**Status:** Restructuring to match roadmap  
**Target:** Phase 1 Mobile MVP - Offline Chat + RAG

---

## 🎯 CORE VISION (From Roadmap)

**Librio = Offline-first AI academic tutor**

- ✅ Chat interface for asking questions
- ✅ Local LLM inference (on-device)
- ✅ RAG (Retrieval-Augmented Generation) for document grounding
- ✅ Conversation history
- ✅ Works offline (airplane mode)
- ❌ NO dashboard
- ❌ NO featured content
- ❌ NO topics/problems browsing
- ❌ NO content management UI

---

## 📋 CURRENT STATE vs ROADMAP

### What We Have (Wrong)
- ❌ Dashboard/home screen
- ❌ Topics screen
- ❌ Problems screen  
- ❌ Content browser
- ❌ Featured content
- ❌ Authentication (not needed for offline MVP)
- ❌ Backend API (not needed for Phase 1)

### What We Need (Phase 1)
- ✅ Chat interface (DONE - `chat_screen.dart`)
- ✅ LLM service (DONE - `llm_service.dart`)
- ✅ Message history (PARTIAL - need SQLite)
- ✅ Local model (DONE - model file ready)
- ⏳ SQLite integration (MISSING)
- ⏳ RAG system (MISSING)
- ⏳ Document upload (MISSING)
- ✅ Settings screen (PARTIAL - need to simplify)

---

## 🔄 RESTRUCTURE PLAN

### Phase 1A: Simplify Mobile App (1-2 hours)

**Remove:**
1. Delete `home_screen.dart`
2. Delete `topics_screen.dart`
3. Delete `problems_screen.dart`
4. Delete `content_service.dart`
5. Delete `content_models.dart`
6. Remove authentication from main navigation
7. Remove backend API calls (except for optional cloud fallback later)

**Keep:**
1. `chat_screen.dart` - Main interface
2. `llm_service.dart` - Local inference
3. `settings_screen.dart` - Model settings, storage
4. `splash_screen.dart` - App startup

**New:**
1. `database_service.dart` - SQLite for conversations
2. `rag_service.dart` - Document retrieval
3. `document_service.dart` - PDF/DOCX upload

### Phase 1B: Add SQLite (1-2 hours)

**Implement:**
1. SQLite schema for conversations
2. Save/load message history
3. Conversation management

### Phase 1C: Add RAG (2-3 hours)

**Implement:**
1. Document upload (PDF/DOCX)
2. Text extraction
3. Simple embedding (TF-IDF or BM25)
4. Vector search
5. Context injection into LLM prompts

### Phase 1D: Polish (1-2 hours)

**Implement:**
1. UI refinements
2. Error handling
3. Performance optimization
4. Offline validation

---

## 📊 NEW APP STRUCTURE

```
apps/mobile/lib/
├── main.dart                    # App entry point
├── screens/
│   ├── splash_screen.dart       # Startup
│   ├── chat_screen.dart         # Main chat interface
│   └── settings_screen.dart     # Settings
├── services/
│   ├── llm_service.dart         # Local LLM inference
│   ├── database_service.dart    # SQLite (conversations)
│   ├── rag_service.dart         # Document retrieval
│   └── document_service.dart    # PDF/DOCX handling
├── models/
│   ├── message.dart             # Chat message
│   └── conversation.dart        # Conversation
└── utils/
    └── logger.dart              # Logging
```

---

## 🗑️ CLEANUP TASKS

### Remove Files
- [ ] `apps/mobile/lib/screens/home_screen.dart`
- [ ] `apps/mobile/lib/screens/topics_screen.dart`
- [ ] `apps/mobile/lib/screens/problems_screen.dart`
- [ ] `apps/mobile/lib/screens/login_screen.dart`
- [ ] `apps/mobile/lib/screens/signup_screen.dart`
- [ ] `apps/mobile/lib/services/content_service.dart`
- [ ] `apps/mobile/lib/services/auth_service.dart`
- [ ] `apps/mobile/lib/services/api_service.dart`
- [ ] `apps/mobile/lib/services/token_manager.dart`
- [ ] `apps/mobile/lib/models/content_models.dart`

### Update Files
- [ ] `main.dart` - Remove navigation, use simple chat interface
- [ ] `pubspec.yaml` - Remove unnecessary dependencies
- [ ] `settings_screen.dart` - Simplify to model/storage settings

### Delete Backend
- [ ] `services/api/` - Not needed for Phase 1 offline MVP

---

## 📦 DEPENDENCIES TO ADD

```yaml
# For SQLite
sqflite: ^2.4.2+1

# For PDF handling
pdf: ^3.10.0
pdfx: ^2.5.0

# For DOCX handling
docx: ^0.2.0

# For embeddings (simple)
# (Use TF-IDF from scratch or lightweight library)
```

---

## 🎯 PHASE 1 SUCCESS CRITERIA

✅ Chat interface works  
✅ LLM loads and generates responses  
✅ Conversation history saved to SQLite  
✅ Can upload PDF/DOCX documents  
✅ RAG retrieves relevant context  
✅ Works offline (airplane mode)  
✅ No crashes in 30 minutes of use  
✅ Model inference <3 seconds per response  
✅ Battery impact acceptable  

---

## 📈 TIMELINE

| Task | Duration | Status |
|------|----------|--------|
| Remove unnecessary screens | 30 min | ⏳ |
| Remove unnecessary services | 30 min | ⏳ |
| Add SQLite integration | 1-2 hours | ⏳ |
| Add RAG system | 2-3 hours | ⏳ |
| Add document upload | 1-2 hours | ⏳ |
| Polish & test | 1-2 hours | ⏳ |
| **Total** | **6-10 hours** | **⏳** |

---

## 🚀 NEXT STEPS

1. **Immediately:**
   - Remove dashboard/topics/problems screens
   - Remove auth services
   - Update main.dart to go straight to chat

2. **Then:**
   - Add SQLite for conversation history
   - Test saving/loading messages

3. **Then:**
   - Add document upload
   - Implement RAG

4. **Finally:**
   - Polish UI
   - Performance optimization
   - Device testing

---

## ✨ RESULT

A clean, focused offline-first chat LLM app that:
- ✅ Works without internet
- ✅ Stores conversation history locally
- ✅ Can ground responses in uploaded documents
- ✅ Is ready for Phase 2 (web sync) later

---

Generated: 2026-08-22  
Status: Ready to restructure
