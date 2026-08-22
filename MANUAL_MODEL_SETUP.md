# Manual Model Setup Guide

**Date:** 2026-08-22  
**Status:** Network download having issues - Use manual setup

---

## 🔧 OPTION 1: Manual Download (Recommended)

### **Step 1: Download from Browser**

1. Visit: https://huggingface.co/google/gemma-3-1b-gguf
2. Click "Files and versions"
3. Find `gemma-3-1b-q4_k_m.gguf`
4. Click the download icon
5. Save to: `C:\dev\Librio\apps\mobile\assets\models\`

**File size:** ~2.5GB  
**Download time:** 10-20 minutes (depends on internet speed)

### **Step 2: Verify File**

```powershell
# Check file exists
Test-Path "C:\dev\Librio\apps\mobile\assets\models\gemma-3-1b-q4_k_m.gguf"

# Check file size (should be ~2.5GB)
(Get-Item "C:\dev\Librio\apps\mobile\assets\models\gemma-3-1b-q4_k_m.gguf").Length / 1GB
```

### **Step 3: Run App**

```bash
cd apps/mobile
flutter pub get
flutter run
```

---

## 🔧 OPTION 2: Use Smaller Model for Testing

If 2.5GB is too large, use a smaller quantized version:

### **Gemma 3 1B Q2_K (1.2GB)**

```powershell
# Download smaller version
Invoke-WebRequest -Uri "https://huggingface.co/google/gemma-3-1b-gguf/resolve/main/gemma-3-1b-q2_k.gguf" `
  -OutFile "C:\dev\Librio\apps\mobile\assets\models\gemma-3-1b-q2_k.gguf" `
  -UseBasicParsing
```

### **Update Configuration**

Edit `apps/mobile/pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/models/gemma-3-1b-q2_k.gguf  # Changed from q4_k_m
```

Edit `apps/mobile/lib/services/model_loader.dart`:
```dart
// Change model filename
final modelName = 'gemma-3-1b-q2_k.gguf';  // Changed from q4_k_m
```

---

## 🔧 OPTION 3: Use Mock Model for Testing

If you want to test the UI without downloading the full model:

### **Create Mock Model File**

```powershell
# Create a small test file (just for testing)
$testFile = "C:\dev\Librio\apps\mobile\assets\models\gemma-3-1b-q4_k_m.gguf"
New-Item -Path $testFile -ItemType File -Force

# Add some test data (at least 1MB so it's not empty)
$bytes = New-Object byte[] 1048576  # 1MB
[System.IO.File]::WriteAllBytes($testFile, $bytes)

# Verify
(Get-Item $testFile).Length / 1MB
```

**Note:** This won't actually work for inference, but it will test the UI and loading logic.

---

## ✅ VERIFICATION STEPS

After placing the model file:

### **Step 1: Check File**
```powershell
# File should exist
Test-Path "C:\dev\Librio\apps\mobile\assets\models\gemma-3-1b-q4_k_m.gguf"

# File should be ~2.5GB (or ~1.2GB for Q2_K)
(Get-Item "C:\dev\Librio\apps\mobile\assets\models\gemma-3-1b-q4_k_m.gguf").Length / 1GB
```

### **Step 2: Run App**
```bash
cd apps/mobile
flutter pub get
flutter run
```

### **Step 3: Check Logs**
```
Expected output:
🤖 Loading model from: ...
✅ LLM model loaded successfully
```

### **Step 4: Test Chat**
```
1. Navigate to chat screen
2. Send message: "Hello"
3. Wait for response
4. Verify streaming works
```

---

## 🎯 TROUBLESHOOTING

### **File Download Fails**
- **Cause:** Network issues or authentication required
- **Solution:** Use browser to download manually
- **Alternative:** Use smaller Q2_K model

### **File is Too Large**
- **Cause:** Not enough disk space
- **Solution:** Use Q2_K (1.2GB) instead of Q4_K_M (2.5GB)
- **Alternative:** Free up disk space

### **Model Doesn't Load**
- **Cause:** File corrupted or wrong location
- **Solution:** 
  1. Verify file exists: `Test-Path "..."`
  2. Verify file size: `(Get-Item "...").Length`
  3. Check pubspec.yaml has asset entry
  4. Run: `flutter clean && flutter pub get`

### **Inference is Slow**
- **Cause:** Device performance or model size
- **Solution:**
  1. Use Q2_K model (faster, lower quality)
  2. Reduce context size in llm_service.dart
  3. Profile with: `flutter run --profile`

---

## 📊 MODEL COMPARISON

| Model | Size | Speed | Quality | Download Time |
|-------|------|-------|---------|----------------|
| **Q2_K** | 1.2GB | Slow | Fair | 5-10 min |
| **Q3_K_M** | 1.8GB | Medium | Good | 8-15 min |
| **Q4_K_M** | 2.5GB | Fast | Excellent | 10-20 min |
| **Q5_K_M** | 3.2GB | Very Fast | Excellent | 15-30 min |

**Recommendation:** Start with Q4_K_M (2.5GB) for best balance

---

## 🚀 NEXT STEPS

1. **Download model** using Option 1 (manual browser download)
2. **Verify file** exists and is correct size
3. **Run app** with `flutter run`
4. **Test model loading** (should take <5 seconds)
5. **Test inference** (send a message)
6. **Device testing** (test on Infinix-Note50)

---

## 📞 SUPPORT

If you encounter issues:

1. Check the troubleshooting section above
2. Verify file exists: `Test-Path "..."`
3. Check file size: `(Get-Item "...").Length / 1GB`
4. Check pubspec.yaml: Asset should be listed
5. Run `flutter clean && flutter pub get`
6. Try `flutter run --no-cache`

---

Generated: 2026-08-22  
Status: Ready for manual setup
