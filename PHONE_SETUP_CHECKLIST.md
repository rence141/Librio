# Infinix-Note50 Setup Checklist

## Before Testing the Benchmark App

### On Your Infinix-Note50 Phone

- [ ] **Enable Developer Mode**
  - Settings → About Phone → tap "Build Number" 7 times
  - You should see "You are now a developer!"

- [ ] **Enable USB Debugging**
  - Settings → Developer Options → USB Debugging → **ON**

- [ ] **Allow USB Debugging Authorization**
  - Connect phone to computer via USB
  - Look for prompt on phone: "Allow USB debugging from this computer?"
  - Tap **Allow** (or check "Always allow from this computer")

- [ ] **Set USB Configuration to File Transfer**
  - Settings → Developer Options → USB Configuration
  - Select "File Transfer" or "MTP" (not "Charging only")

### On Your Windows Machine

- [ ] **Verify ADB Connection**
  ```powershell
  & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
  ```
  Should show: `<device-id>    device`

- [ ] **Verify Flutter Sees Device**
  ```powershell
  flutter devices
  ```
  Should show your Infinix-Note50

- [ ] **Check Phone Has Enough Space**
  - At least 500 MB free space for app + models

- [ ] **Check Phone Has Enough RAM**
  - At least 4 GB available (check Settings → About Phone → RAM)

### Ready to Test?

Once all checkboxes are done, run:

```powershell
cd apps/mobile
flutter run
```

This will:
1. Build the Librio benchmark app
2. Install it on your phone
3. Launch it automatically
4. Show live logs in your terminal

### On Your Phone During Testing

- [ ] **Tap "Start Benchmark"** button
- [ ] **Watch the logs** as it tests the 3 models
- [ ] **Wait for completion** (should take ~1-2 minutes)
- [ ] **Check phone storage** for results:
  - Files → Documents → benchmark_results/
  - Or: Settings → Apps → Librio → Storage → Documents

### After Testing

- [ ] **Pull results to your computer**
  ```powershell
  adb pull /data/data/com.librio.librio/app_flutter/benchmark_results/ ./bench/results/
  ```

- [ ] **View results**
  ```powershell
  Get-ChildItem bench/results/
  cat bench/results/Infinix-Note50-gemma3-1b-q4-cpu.json
  ```

---

## Troubleshooting

If you get stuck:
1. See `USB_CONNECTION_TROUBLESHOOTING.md` for connection issues
2. See `PHONE_TESTING_GUIDE.md` for app-specific issues
3. Run `flutter doctor -v` for detailed diagnostics

---

## Next Steps After Testing

1. Collect results from all 3 models
2. Fill in `docs/phase0-model-selection.md` with results
3. Select the best model based on:
   - Load time
   - Inference speed
   - RAM usage
   - Battery drain
4. Document rationale in Phase 0 report

Good luck! 🚀
