# Phase 1: LLM Model Testing Guide

**Date:** 2026-08-22  
**Status:** Model downloading (in progress)  
**Next:** Testing after download completes

---

## 📥 MODEL DOWNLOAD STATUS

**File:** `gemma-3-1b-q4_k_m.gguf`  
**Size:** ~2.5GB  
**Location:** `apps/mobile/assets/models/`  
**Status:** ⏳ Downloading...  
**ETA:** 10-20 minutes

---

## ✅ TESTING CHECKLIST

### **Phase 1A: Model Loading (5 minutes)**

After download completes:

```bash
cd apps/mobile

# 1. Verify file exists
ls -la assets/models/gemma-3-1b-q4_k_m.gguf

# 2. Get dependencies
flutter pub get

# 3. Run on emulator
flutter run

# 4. Check logs for model loading
# Expected output:
# 🤖 Loading model from: ...
# ✅ LLM model loaded successfully
```

**Success Criteria:**
- ✅ File exists and is ~2.5GB
- ✅ App starts without crashing
- ✅ Model loads in <5 seconds
- ✅ No memory errors
- ✅ No file not found errors

---

### **Phase 1B: Inference Testing (10 minutes)**

After model loads:

```dart
// Test in chat screen

// 1. Send simple message
"What is 2+2?"

// Expected response:
// ✅ Response generated
// ✅ Appears in chat
// ✅ Takes 10-30 seconds
// ✅ ~20-30 tokens/second

// 2. Send complex message
"Explain photosynthesis in simple terms"

// Expected response:
// ✅ Response generated
// ✅ Streaming works
// ✅ Takes 20-40 seconds
// ✅ Response is coherent

// 3. Send follow-up
"Can you simplify that further?"

// Expected response:
// ✅ Response generated
// ✅ Context understood
// ✅ Response is relevant
```

**Success Criteria:**
- ✅ Responses generate
- ✅ Streaming displays tokens
- ✅ Speed: 20-30 tokens/sec
- ✅ Quality: Coherent responses
- ✅ No crashes
- ✅ No memory leaks

---

### **Phase 1C: Performance Testing (15 minutes)**

**Memory Usage:**
```
Expected:
- Idle: <500MB
- During inference: <2GB
- After inference: <500MB (cleanup)

Test:
1. Open app
2. Check memory (Settings > Developer > Memory)
3. Send message
4. Monitor memory during response
5. Check memory after response
```

**Speed Testing:**
```
Expected:
- Model load: <5 seconds
- First token: <2 seconds
- Subsequent tokens: 30-50ms each
- Full response (256 tokens): 10-30 seconds

Test:
1. Time model loading
2. Time first token
3. Count tokens/second
4. Time full response
```

**Battery Usage:**
```
Expected:
- Idle: <1% per minute
- During inference: <5% per minute

Test:
1. Check battery before
2. Generate 5 responses
3. Check battery after
4. Calculate drain rate
```

---

### **Phase 1D: Stability Testing (30 minutes)**

**Crash Testing:**
```
Test:
1. Send 10 messages in sequence
2. Send very long message (500+ chars)
3. Send special characters
4. Send empty message
5. Rapid send/cancel
6. Send during app pause/resume
7. Send with low memory
8. Send with network off
```

**Expected:**
- ✅ No crashes
- ✅ Graceful error handling
- ✅ No hung processes
- ✅ Proper cleanup

---

### **Phase 1E: Device Testing (1-2 hours)**

**Emulator Testing:**
```bash
# Test on different emulator configurations

# 1. Default emulator
flutter run

# 2. Low memory emulator
# Create emulator with 512MB RAM
flutter run -d <emulator-id>

# 3. Slow network emulator
# Use Android Studio network throttling
```

**Physical Device Testing:**
```bash
# Connect Infinix-Note50
adb devices

# Install app
flutter run -d <device-id>

# Monitor performance
flutter run -d <device-id> --profile

# Check logs
adb logcat | grep flutter
```

---

## 🔍 DEBUGGING GUIDE

### **If Model Doesn't Load**

```
Error: "Model not found in assets"

Solutions:
1. Verify file exists: ls -la apps/mobile/assets/models/
2. Verify pubspec.yaml has asset entry
3. Run: flutter pub get
4. Clean build: flutter clean && flutter pub get
5. Rebuild: flutter run --no-cache
```

### **If Inference is Slow**

```
Symptoms: Takes >60 seconds for response

Solutions:
1. Check device specs (CPU, RAM)
2. Reduce context size in llm_service.dart
3. Reduce max tokens (currently 256)
4. Use fewer threads (currently 4)
5. Profile with: flutter run --profile
```

### **If Memory Usage is High**

```
Symptoms: App crashes with "Out of memory"

Solutions:
1. Reduce context size (currently 512)
2. Reduce max tokens (currently 256)
3. Add explicit garbage collection
4. Profile with: flutter run --profile
5. Check for memory leaks in llm_service.dart
```

### **If Streaming Doesn't Work**

```
Symptoms: Response appears all at once instead of streaming

Solutions:
1. Check stream implementation in llm_service.dart
2. Verify llamadart version supports streaming
3. Check for stream cancellation
4. Add debug logging to stream
5. Test with simpler prompt
```

---

## 📊 EXPECTED RESULTS

### **Successful Load**
```
✅ Model loads in <5 seconds
✅ Memory usage <2GB during inference
✅ Inference speed: 20-30 tokens/sec
✅ Response quality: Coherent, relevant
✅ No crashes in 30 minutes of testing
✅ Works on emulator and device
```

### **Performance Targets**
```
Model Load Time:    <5 seconds
First Token Time:   <2 seconds
Token Speed:        20-30 tokens/sec
Full Response:      10-30 seconds
Memory (Idle):      <500MB
Memory (Inference): <2GB
Memory (Cleanup):   <500MB
```

---

## 🚀 NEXT STEPS AFTER TESTING

### **If All Tests Pass**
1. ✅ Commit successful test results
2. ✅ Update progress documentation
3. ✅ Move to Phase 2: Chat Interface Polish
4. ✅ Schedule device testing

### **If Tests Fail**
1. ⚠️ Identify failure point
2. ⚠️ Check debugging guide
3. ⚠️ Implement fix
4. ⚠️ Re-test
5. ⚠️ Document issue and solution

---

## 📝 TEST RESULTS TEMPLATE

```markdown
# Phase 1 Test Results

**Date:** [Date]
**Device:** [Device Name]
**Model:** Gemma 3 1B Q4_K_M
**File Size:** [Size]

## Model Loading
- Load Time: [X] seconds
- Memory Used: [X] MB
- Status: ✅ Pass / ❌ Fail

## Inference Testing
- First Token: [X] seconds
- Token Speed: [X] tokens/sec
- Response Quality: [Good/Fair/Poor]
- Status: ✅ Pass / ❌ Fail

## Performance
- Idle Memory: [X] MB
- Peak Memory: [X] MB
- Battery Drain: [X]% per minute
- Status: ✅ Pass / ❌ Fail

## Stability
- Crashes: [0/X]
- Errors: [List any]
- Status: ✅ Pass / ❌ Fail

## Overall
- Status: ✅ Pass / ❌ Fail
- Issues: [List any]
- Next Steps: [Next actions]
```

---

## ⏱️ TIMELINE

| Phase | Task | Duration | Status |
|-------|------|----------|--------|
| **1A** | Model Loading | 5 min | ⏳ |
| **1B** | Inference Testing | 10 min | ⏳ |
| **1C** | Performance Testing | 15 min | ⏳ |
| **1D** | Stability Testing | 30 min | ⏳ |
| **1E** | Device Testing | 1-2 hrs | ⏳ |
| **Total** | | 2-3 hrs | ⏳ |

---

## 📞 SUPPORT

If you encounter issues:

1. Check the debugging guide above
2. Review the error messages in logs
3. Check llamadart documentation
4. Check Flutter documentation
5. Check device logs with `adb logcat`

---

Generated: 2026-08-22  
Status: Waiting for model download to complete
