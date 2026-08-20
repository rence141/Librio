# Phone Testing Guide: Infinix-Note50

This guide explains how to build and deploy the Librio Phase 0 benchmark app to your Infinix-Note50 phone.

## Prerequisites

1. **Flutter & Android SDK installed** (already verified)
2. **USB cable** to connect phone to dev machine
3. **USB debugging enabled** on Infinix-Note50:
   - Settings → About Phone → tap "Build Number" 7 times
   - Settings → Developer Options → USB Debugging (enable)

## Step 1: Connect Phone via USB

```powershell
# Verify phone is connected
flutter devices
```

You should see output like:
```
Infinix-Note50 (mobile) • emulator-5554 • android-arm64 • Android 13 (API 33)
```

## Step 2: Get Dependencies

```powershell
cd apps/mobile
flutter pub get
```

## Step 3: Build & Deploy

### Option A: Debug Build (Fastest, for testing)

```powershell
cd apps/mobile
flutter run
```

This will:
- Compile the app
- Install on your phone
- Launch the app
- Show live logs in terminal

### Option B: Release Build (Optimized, slower to build)

```powershell
cd apps/mobile
flutter build apk --release
# APK will be at: build/app/outputs/flutter-app/release/app-release.apk
```

## Step 4: Run Benchmark

Once the app is running on your phone:

1. **Tap "Start Benchmark"** button
2. **Watch the logs** as it tests each model:
   - Gemma 3 1B
   - Llama 3.2 1B
   - SmolLM2 1.7B

3. **Results are saved** to:
   - Android: `/data/data/com.librio.librio/app_flutter/benchmark_results/`
   - Or: `getApplicationDocumentsDirectory()` in Flutter

## Step 5: Collect Results

After benchmark completes, pull results from phone:

```powershell
# List results on phone
adb shell ls /data/data/com.librio.librio/app_flutter/benchmark_results/

# Pull results to your machine
adb pull /data/data/com.librio.librio/app_flutter/benchmark_results/ ./bench/results/
```

Or use Android Studio's Device File Explorer:
- Device File Explorer → data → data → com.librio.librio → app_flutter → benchmark_results

## Troubleshooting

### Phone not detected
```powershell
# Restart ADB
adb kill-server
adb start-server
flutter devices
```

### Build fails
```powershell
# Clean and rebuild
flutter clean
cd apps/mobile
flutter pub get
flutter run
```

### App crashes on launch
- Check logcat: `flutter logs`
- Ensure phone has ≥500MB free space
- Try debug build first (less optimized, more stable)

### Models not loading
- Ensure GGUF files are in `bench/models/`
- Check phone has ≥4GB RAM available
- Monitor with: `adb shell dumpsys meminfo com.librio.librio`

## What the App Does (Phase 0)

The benchmark app currently:

✓ Loads model metadata from `bench/models.json`  
✓ Loads prompts from `bench/prompts.json`  
✓ Simulates inference (Phase 0 placeholder)  
✓ Saves results as JSON  

**Phase 1 will add:**
- Actual GGUF model loading with `llm_llamacpp`
- Real inference with token generation
- Actual performance measurement (load time, TTFT, decode speed)
- Battery drain monitoring
- Peak RAM measurement

## Expected Results (Phase 0 Placeholder)

Each model will show:
```
Testing model: gemma3-1b-q4
  [*] Loading model: gemma3-1b-q4
  [✓] Model loaded in 500ms
  [*] Prompt 1/5: "What is photosynthesis?"
      Time: 300ms | Tokens: 30 | Speed: 100.0 tok/s
  [*] Prompt 2/5: "Solve: 2x + 5 = 13"
      Time: 300ms | Tokens: 30 | Speed: 100.0 tok/s
  ...
  [Summary] Avg: 300ms | Speed: 100.0 tok/s
  [✓] Result saved to: ...
```

**Note:** These are placeholder numbers. Real benchmarks will be much different.

## Next Steps

1. Run the app and collect placeholder results
2. In Phase 1, integrate actual `llm_llamacpp` model loading
3. Implement real inference and measurement
4. Compare results across the 3 models
5. Select the best model for Phase 1 implementation

## Questions?

- See `AGENTS.md` for build commands
- See `PHASE0_PROGRESS.md` for overall Phase 0 status
- See `bench/MODELS_DOWNLOAD.md` for model details
