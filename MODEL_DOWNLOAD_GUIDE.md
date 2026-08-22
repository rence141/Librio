# LLM Model Download Guide

**Date:** 2026-08-22  
**Status:** Download Instructions & Alternatives

---

## 📥 PRIMARY DOWNLOAD SOURCES

### **Option 1: HuggingFace (Recommended)**

```bash
cd apps/mobile/assets/models

# Download Gemma 3 1B Q4_K_M quantized model
wget -O gemma-3-1b-q4_k_m.gguf \
  https://huggingface.co/google/gemma-3-1b-gguf/resolve/main/gemma-3-1b-q4_k_m.gguf

# Or with curl
curl -L -o gemma-3-1b-q4_k_m.gguf \
  https://huggingface.co/google/gemma-3-1b-gguf/resolve/main/gemma-3-1b-q4_k_m.gguf
```

**Note:** HuggingFace may require authentication. If you get "Invalid username or password", use Option 2.

---

### **Option 2: GGML Repository**

```bash
cd apps/mobile/assets/models

# Download from GGML mirror
curl -L -o gemma-3-1b-q4_k_m.gguf \
  https://ggml.ggmlcode.com/gemma-3-1b-q4_k_m.gguf
```

---

### **Option 3: Ollama (Easiest)**

If you have Ollama installed locally:

```bash
# Pull the model
ollama pull gemma:3-1b-q4_k_m

# Find the model location
# macOS/Linux: ~/.ollama/models/blobs/
# Windows: %USERPROFILE%\.ollama\models\blobs\

# Copy to your project
cp ~/.ollama/models/blobs/gemma-3-1b-q4_k_m.gguf \
  apps/mobile/assets/models/
```

---

### **Option 4: Manual Download**

1. Visit: https://huggingface.co/google/gemma-3-1b-gguf
2. Click "Files and versions"
3. Find `gemma-3-1b-q4_k_m.gguf`
4. Click download
5. Save to `apps/mobile/assets/models/`

---

## ✅ VERIFICATION

After download, verify the file:

```bash
# Check file exists
ls -lh apps/mobile/assets/models/gemma-3-1b-q4_k_m.gguf

# Expected output:
# -rw-r--r-- ... 2.5G ... gemma-3-1b-q4_k_m.gguf

# Verify file size (should be ~2.5GB)
du -h apps/mobile/assets/models/gemma-3-1b-q4_k_m.gguf

# Verify file integrity (optional)
# Calculate SHA256 hash
sha256sum apps/mobile/assets/models/gemma-3-1b-q4_k_m.gguf
```

---

## 🚀 AFTER DOWNLOAD

Once the file is in place:

```bash
# 1. Update pubspec.yaml (already done)
# ✅ Already configured

# 2. Get dependencies
cd apps/mobile
flutter pub get

# 3. Run on emulator
flutter run

# 4. Test model loading
# Open chat screen and send a message
```

---

## 🔧 ALTERNATIVE: USE SMALLER MODEL FOR TESTING

If the 2.5GB download is too large, you can use a smaller model for initial testing:

### **Gemma 3 1B Q2_K (Smaller)**
- Size: ~1.2GB
- Speed: Slower but still usable
- Quality: Reduced but acceptable

```bash
# Download smaller version
curl -L -o gemma-3-1b-q2_k.gguf \
  https://huggingface.co/google/gemma-3-1b-gguf/resolve/main/gemma-3-1b-q2_k.gguf

# Update pubspec.yaml
# Change: assets/models/gemma-3-1b-q4_k_m.gguf
# To: assets/models/gemma-3-1b-q2_k.gguf

# Update llm_service.dart
# Change: 'gemma-3-1b-q4_k_m.gguf'
# To: 'gemma-3-1b-q2_k.gguf'
```

---

## ⚠️ TROUBLESHOOTING

### **Download Fails with "Invalid username or password"**
- Solution: Use Option 2 (GGML) or Option 4 (Manual)
- Or: Create HuggingFace account and use token

### **Download is Too Slow**
- Solution: Use smaller model (Q2_K instead of Q4_K_M)
- Or: Try different source
- Or: Download during off-peak hours

### **File is Corrupted**
- Solution: Delete and re-download
- Or: Verify SHA256 hash
- Or: Try different source

### **Not Enough Disk Space**
- Solution: Use smaller model (Q2_K)
- Or: Free up disk space
- Or: Use external storage

---

## 📊 MODEL OPTIONS

| Model | Size | Speed | Quality | Use Case |
|-------|------|-------|---------|----------|
| **Q2_K** | 1.2GB | Slow | Fair | Testing |
| **Q3_K_M** | 1.8GB | Medium | Good | Mobile |
| **Q4_K_M** | 2.5GB | Fast | Excellent | Recommended |
| **Q5_K_M** | 3.2GB | Very Fast | Excellent | High-end |

**Recommendation:** Use Q4_K_M (2.5GB) for best balance

---

## 🎯 NEXT STEPS

1. **Download the model** using one of the options above
2. **Verify file** exists and is ~2.5GB
3. **Run app** on emulator
4. **Test model loading** (should take <5 seconds)
5. **Test inference** (send a message)
6. **Device testing** (test on physical device)

---

## 📞 SUPPORT

If you encounter issues:

1. Check the troubleshooting section above
2. Verify file exists: `ls -lh apps/mobile/assets/models/`
3. Check file size: Should be ~2.5GB
4. Check pubspec.yaml: Asset should be listed
5. Run `flutter clean && flutter pub get`
6. Try `flutter run --no-cache`

---

Generated: 2026-08-22  
Status: Ready for manual download
