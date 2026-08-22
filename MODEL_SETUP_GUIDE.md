# LLM Model Setup Guide for Librio

**Status:** Model Setup Instructions  
**Date:** 2026-08-22  
**Model:** Gemma 3 1B (Quantized)

---

## 📥 Quick Setup

### Option 1: Automatic Download (Recommended)
The app will automatically download the model on first run if you have internet.

### Option 2: Manual Download
Follow the steps below to manually download and place the model.

---

## 🤖 Model Information

### Model Details
- **Name:** Gemma 3 1B
- **Quantization:** Q4_K_M (4-bit)
- **Size:** ~650 MB
- **Format:** GGUF
- **Source:** HuggingFace (Google)
- **URL:** https://huggingface.co/google/gemma-3-1b-gguf

### Why This Model?
✅ Small size (650 MB) - fits on mobile  
✅ Fast inference (~1-2 seconds per response)  
✅ Good quality for academic tutoring  
✅ Quantized (Q4_K_M) - optimized for mobile  
✅ Open source (Apache 2.0)  

---

## 📍 Model Location

### On Device
```
/data/user/0/com.librio.librio/app_flutter/models/gemma-3-1b-q4_k_m.gguf
```

### On Development Machine
```
C:\Users\<username>\AppData\Local\com.librio.librio\models\gemma-3-1b-q4_k_m.gguf
```

---

## 🔽 Download Instructions

### Method 1: Direct Download (Fastest)

1. **Download the model:**
   - Go to: https://huggingface.co/google/gemma-3-1b-gguf
   - Click "Files and versions"
   - Find: `gemma-3-1b-q4_k_m.gguf`
   - Click download (or use wget/curl)

2. **Using wget (Linux/Mac):**
   ```bash
   wget https://huggingface.co/google/gemma-3-1b-gguf/resolve/main/gemma-3-1b-q4_k_m.gguf
   ```

3. **Using curl (Windows):**
   ```bash
   curl -L -o gemma-3-1b-q4_k_m.gguf \
     https://huggingface.co/google/gemma-3-1b-gguf/resolve/main/gemma-3-1b-q4_k_m.gguf
   ```

### Method 2: Using git-lfs (If available)

```bash
# Install git-lfs first
# Then clone the repo
git clone https://huggingface.co/google/gemma-3-1b-gguf
cd gemma-3-1b-gguf
git lfs pull
```

---

## 💾 Installation Steps

### Step 1: Download the Model
- Download `gemma-3-1b-q4_k_m.gguf` (~650 MB)
- Verify file size is correct

### Step 2: Create Models Directory
```bash
# On Android device (via adb)
adb shell mkdir -p /data/user/0/com.librio.librio/app_flutter/models

# Or let the app create it automatically
```

### Step 3: Transfer to Device
```bash
# Using adb push
adb push gemma-3-1b-q4_k_m.gguf \
  /data/user/0/com.librio.librio/app_flutter/models/

# Verify
adb shell ls -lh /data/user/0/com.librio.librio/app_flutter/models/
```

### Step 4: Verify Installation
1. Launch the app
2. Check logs for: "✅ Model found at: ..."
3. App should load model successfully

---

## 🔧 Alternative: Use Different Model

If you want to use a different model:

### 1. Update Model Loader
Edit `lib/services/model_loader.dart`:

```dart
static const String modelFileName = 'your-model-name.gguf';
static const String modelUrl = 'https://your-model-url/model.gguf';
```

### 2. Supported Models
- **Gemma 3 1B** (recommended) - 650 MB
- **Gemma 2 2B** - 1.3 GB
- **Phi 3 Mini** - 2.3 GB
- **Mistral 7B** - 4 GB (might be too large)

### 3. Download Alternative Model
- Visit: https://huggingface.co/models
- Filter by: GGUF format
- Choose quantized version (Q4_K_M or Q5_K_M)

---

## 🧪 Testing Model

### Check Model is Loaded
```bash
# View logs
flutter logs

# Look for:
# ✅ Model found at: ...
# ✅ LLM model loaded successfully
```

### Test Model Inference
1. Open app
2. Type a question: "What is 2+2?"
3. Wait for response
4. Check response quality

### Expected Performance
- **First load:** 5-10 seconds
- **Response time:** 1-3 seconds per response
- **Memory usage:** ~1-2 GB
- **Battery impact:** Moderate (optimize in Phase 3)

---

## 🐛 Troubleshooting

### Model Not Found
**Error:** "Model not found. Download from..."

**Solution:**
1. Verify file exists at correct path
2. Check file size (~650 MB)
3. Verify file is not corrupted
4. Re-download if needed

### Model Load Fails
**Error:** "Failed to load model"

**Solution:**
1. Check model format is GGUF
2. Verify quantization is Q4_K_M
3. Check device has enough storage
4. Check device has enough RAM

### Slow Inference
**Problem:** Responses take >5 seconds

**Solution:**
1. This is normal for mobile
2. Optimize in Phase 3
3. Consider smaller model if needed
4. Check device isn't running other apps

### Out of Memory
**Error:** "Out of memory"

**Solution:**
1. Close other apps
2. Use smaller model (Phi 3 Mini)
3. Reduce max_tokens in LLM service
4. Optimize in Phase 3

---

## 📊 Model Comparison

| Model | Size | Speed | Quality | Mobile |
|-------|------|-------|---------|--------|
| Gemma 3 1B | 650 MB | Fast | Good | ✅ |
| Gemma 2 2B | 1.3 GB | Medium | Better | ✅ |
| Phi 3 Mini | 2.3 GB | Medium | Good | ⚠️ |
| Mistral 7B | 4 GB | Slow | Excellent | ❌ |

---

## 🔐 Security Notes

- Model is downloaded from official HuggingFace
- Verify file hash if available
- Store locally on device (no cloud sync)
- Model is not uploaded anywhere

---

## 📱 Device Requirements

### Minimum
- **Storage:** 1 GB free
- **RAM:** 2 GB free during inference
- **CPU:** ARM64 (most modern phones)
- **OS:** Android 7.0+

### Recommended
- **Storage:** 2 GB free
- **RAM:** 4 GB free during inference
- **CPU:** ARM64 with NEON
- **OS:** Android 10+

---

## ⚡ Performance Tips

### Faster Inference
1. Close other apps
2. Use device with better CPU
3. Use smaller model
4. Reduce max_tokens

### Better Quality
1. Use larger model (Gemma 2 2B)
2. Increase max_tokens
3. Adjust temperature (0.7 default)
4. Use better prompt

### Lower Battery Usage
1. Use smaller model
2. Reduce inference frequency
3. Batch requests
4. Optimize in Phase 3

---

## 🔄 Updating Model

### To Use Different Model
1. Delete old model file
2. Update model_loader.dart
3. Download new model
4. Place in models directory
5. Restart app

### To Update to Newer Version
1. Check HuggingFace for updates
2. Download new version
3. Replace old file
4. Restart app

---

## 📚 References

- **HuggingFace:** https://huggingface.co/google/gemma-3-1b-gguf
- **Gemma Docs:** https://ai.google.dev/gemma
- **GGUF Format:** https://github.com/ggerganov/ggml
- **Llamadart:** https://pub.dev/packages/llamadart

---

## ✅ Verification Checklist

- [ ] Model file downloaded (~650 MB)
- [ ] File placed in correct directory
- [ ] App recognizes model
- [ ] Model loads successfully
- [ ] Inference works (test with simple query)
- [ ] Response quality is acceptable
- [ ] Performance is acceptable

---

## 🎯 Next Steps

1. **Download model** (650 MB)
2. **Place in models directory**
3. **Restart app**
4. **Test with simple query**
5. **Verify performance**
6. **Proceed to Phase 2**

---

## 💡 Tips

- Download on WiFi (650 MB file)
- Use fast internet (can take 10-30 minutes)
- Verify file integrity after download
- Keep backup of model file
- Document model version used

---

Generated: 2026-08-22  
Status: Model Setup Guide - Ready for Download
