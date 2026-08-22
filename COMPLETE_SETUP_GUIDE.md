# Complete Librio Setup Guide

**Status:** Complete Setup Instructions  
**Date:** 2026-08-22  
**Version:** Phase 1 MVP

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Project Setup](#project-setup)
3. [Model Download](#model-download)
4. [Device Setup](#device-setup)
5. [Running the App](#running-the-app)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)

---

## 📦 Prerequisites

### Required Software
- **Flutter:** 3.38.9 or later
- **Dart:** 3.10.8 or later
- **Android SDK:** API 24+
- **Git:** Latest version

### Optional Tools
- **Android Studio:** For emulator
- **VS Code:** For development
- **ADB:** For device communication

### Device Requirements
- **Android Device:** 7.0+ (API 24+)
- **Storage:** 2 GB free
- **RAM:** 4 GB minimum
- **USB Cable:** For file transfer

---

## 🚀 Project Setup

### 1. Clone Repository
```bash
git clone https://github.com/your-org/Librio.git
cd Librio
```

### 2. Install Flutter Dependencies
```bash
cd apps/mobile
flutter pub get
```

### 3. Verify Installation
```bash
flutter doctor
```

Expected output:
```
✓ Flutter (Channel stable, 3.38.9)
✓ Android toolchain
✓ Android Studio
✓ VS Code
✓ Connected device
```

### 4. Check Code Quality
```bash
flutter analyze
```

Should show no errors.

---

## 🤖 Model Download

### Option A: Automatic (Recommended)
The app will download the model on first run if you have internet.

### Option B: Manual Download

#### Windows
```bash
# Run the download script
download_model.bat

# Or use PowerShell
powershell -Command "Invoke-WebRequest -Uri 'https://huggingface.co/google/gemma-3-1b-gguf/resolve/main/gemma-3-1b-q4_k_m.gguf' -OutFile 'gemma-3-1b-q4_k_m.gguf'"
```

#### Linux/Mac
```bash
# Run the download script
bash download_model.sh

# Or use wget
wget https://huggingface.co/google/gemma-3-1b-gguf/resolve/main/gemma-3-1b-q4_k_m.gguf

# Or use curl
curl -L -o gemma-3-1b-q4_k_m.gguf https://huggingface.co/google/gemma-3-1b-gguf/resolve/main/gemma-3-1b-q4_k_m.gguf
```

### Model Details
- **File:** gemma-3-1b-q4_k_m.gguf
- **Size:** ~650 MB
- **Format:** GGUF
- **Quantization:** Q4_K_M (4-bit)
- **Source:** HuggingFace (Google)

---

## 📱 Device Setup

### 1. Connect Device
```bash
# Connect Android device via USB
# Enable USB debugging on device

# Verify connection
adb devices
```

Expected output:
```
List of attached devices
XXXXXXXX device
```

### 2. Create Models Directory
```bash
adb shell mkdir -p /data/user/0/com.librio.librio/app_flutter/models
```

### 3. Transfer Model File
```bash
# Push model to device
adb push gemma-3-1b-q4_k_m.gguf /data/user/0/com.librio.librio/app_flutter/models/

# Verify transfer
adb shell ls -lh /data/user/0/com.librio.librio/app_flutter/models/
```

Expected output:
```
-rw-rw-rw- 1 root root 650M ... gemma-3-1b-q4_k_m.gguf
```

### 4. Verify Storage
```bash
# Check available storage
adb shell df /data

# Should show at least 2 GB free
```

---

## 🏃 Running the App

### 1. Build and Run
```bash
cd apps/mobile
flutter run
```

### 2. First Launch
- App will initialize database
- App will check for model
- App will launch to chat screen
- Welcome message will appear

### 3. View Logs
```bash
flutter logs
```

Look for:
```
✅ Model found at: ...
✅ Database initialized
✅ RAG service initialized
```

---

## ✅ Verification

### Chat Interface
1. ✅ App launches without crashing
2. ✅ Chat screen displays
3. ✅ Welcome message appears
4. ✅ Input field is functional

### Database
1. ✅ Type a message: "Hello"
2. ✅ Message appears in chat
3. ✅ Restart app
4. ✅ Message persists

### Knowledge Base
1. ✅ Tap knowledge base button (📚)
2. ✅ Documents screen opens
3. ✅ Upload button is visible
4. ✅ Empty state shows

### Model (If Downloaded)
1. ✅ Type a question: "What is 2+2?"
2. ✅ Wait for response
3. ✅ Response appears in chat
4. ✅ Response is reasonable

---

## 🐛 Troubleshooting

### App Won't Build
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Device Not Detected
```bash
# Restart ADB
adb kill-server
adb start-server

# Check USB debugging is enabled
# Check USB cable is working
```

### Model Not Found
```bash
# Verify file exists
adb shell ls -lh /data/user/0/com.librio.librio/app_flutter/models/

# Check file size (~650 MB)
# Re-download if corrupted
```

### Database Errors
```bash
# Clear app data
adb shell pm clear com.librio.librio

# Restart app
flutter run
```

### Slow Performance
- Close other apps
- Restart device
- Check available RAM
- Check available storage

### Out of Memory
- Close other apps
- Restart device
- Use smaller model (Phi 3 Mini)
- Optimize in Phase 3

---

## 📊 Quick Reference

### File Locations
```
Project:
  Librio/
  ├── apps/mobile/          Flutter app
  ├── services/api/         Backend (Node.js)
  └── docs/                 Documentation

Device:
  /data/user/0/com.librio.librio/
  ├── app_flutter/
  │   ├── models/           LLM models
  │   └── databases/        SQLite databases
  └── cache/                Cache files
```

### Key Commands
```bash
# Build and run
flutter run

# View logs
flutter logs

# Clean build
flutter clean

# Analyze code
flutter analyze

# Push model to device
adb push gemma-3-1b-q4_k_m.gguf /data/user/0/com.librio.librio/app_flutter/models/

# Check device storage
adb shell df /data

# Clear app data
adb shell pm clear com.librio.librio
```

### Useful URLs
- **HuggingFace:** https://huggingface.co/google/gemma-3-1b-gguf
- **Flutter Docs:** https://flutter.dev/docs
- **Android Docs:** https://developer.android.com
- **GitHub:** https://github.com/your-org/Librio

---

## 🎯 Next Steps

1. ✅ Install Flutter and dependencies
2. ✅ Clone Librio repository
3. ✅ Download LLM model
4. ✅ Connect Android device
5. ✅ Transfer model to device
6. ✅ Run app
7. ✅ Verify all features work
8. ✅ Proceed to Phase 2

---

## 💡 Tips

- **Download on WiFi:** Model is 650 MB
- **Keep backup:** Save model file locally
- **Document setup:** Note model version used
- **Test thoroughly:** Verify all features work
- **Monitor performance:** Check battery and memory usage

---

## 📞 Support

### Common Issues
1. **Build fails:** Run `flutter clean && flutter pub get`
2. **Device not found:** Check USB debugging is enabled
3. **Model not found:** Verify file transfer with `adb shell ls`
4. **App crashes:** Check logs with `flutter logs`

### Getting Help
1. Check the phase completion documents
2. Review the code comments
3. Check the git commit history
4. Run device tests to identify issues

---

## ✨ Success Indicators

You'll know everything is working when:
- ✅ App launches without crashing
- ✅ Chat screen displays
- ✅ Messages are saved and persist
- ✅ Documents can be uploaded
- ✅ Model loads successfully (if downloaded)
- ✅ Responses are generated (if model loaded)

---

Generated: 2026-08-22  
Status: Complete Setup Guide - Ready for Implementation
