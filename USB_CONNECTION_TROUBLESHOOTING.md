# USB Connection Troubleshooting for Infinix-Note50

Your phone is not currently detected by ADB. Follow these steps to fix it.

## Step 1: Enable USB Debugging on Infinix-Note50

1. **Open Settings** on your phone
2. **Scroll to "About Phone"**
3. **Tap "Build Number"** 7 times rapidly
   - You should see: "You are now a developer!"
4. **Go back** to Settings
5. **Find "Developer Options"** (should now be visible)
6. **Enable "USB Debugging"**
   - A dialog may appear asking to allow debugging - tap **Allow**

## Step 2: Connect Phone via USB

1. **Connect your Infinix-Note50** to your Windows machine with a USB cable
2. **On your phone**, you may see a prompt:
   - "Allow USB debugging?" → Tap **Allow**
   - "Allow access to device data?" → Tap **Allow**

## Step 3: Verify Connection

Run this in PowerShell:

```powershell
# Check if phone is detected
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
```

**Expected output:**
```
List of devices attached
<device-id>    device
```

If you see `<device-id>    device`, you're connected! ✓

## Step 4: If Still Not Detected

Try these troubleshooting steps:

### A. Restart ADB Server

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" kill-server
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" start-server
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
```

### B. Check USB Cable

- Try a different USB cable (some cables are charge-only)
- Try a different USB port on your computer
- Try a different computer if possible

### C. Update USB Drivers

1. **On your phone:** Settings → Developer Options → USB Configuration
   - Try changing from "Charging" to "File Transfer" or "MTP"
2. **On Windows:** Device Manager → Android devices
   - Right-click → Update driver

### D. Disable USB Debugging & Re-enable

1. Settings → Developer Options → USB Debugging → **Off**
2. Wait 10 seconds
3. Settings → Developer Options → USB Debugging → **On**
4. Reconnect phone

### E. Check for Unauthorized Device

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
```

If you see `<device-id>    unauthorized`, the phone hasn't authorized your computer yet:
- On your phone, look for a prompt to authorize debugging
- Tap **Allow**

## Step 5: Once Connected, Test with Flutter

```powershell
# Verify Flutter sees the device
flutter devices

# Should show something like:
# Infinix-Note50 (mobile) • emulator-5554 • android-arm64 • Android 13 (API 33)

# Build and run the app
cd apps/mobile
flutter run
```

## Common Issues

| Issue | Solution |
|-------|----------|
| "adb: command not found" | Use full path: `& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"` |
| "unauthorized" | Tap "Allow" on phone when prompted |
| "offline" | Restart ADB server or reconnect phone |
| "device not found" | Check USB cable, try different port, update drivers |
| "connection refused" | Restart ADB: `adb kill-server && adb start-server` |

## Quick Reference

```powershell
# Add ADB to PATH (permanent solution)
$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools"
$env:Path += ";$adbPath"

# Now you can use adb directly
adb devices
adb logcat
adb pull /path/to/file ./local/path
```

## Still Having Issues?

1. Check Android Studio's Device Manager for more info
2. Run `flutter doctor -v` to see detailed diagnostics
3. Visit https://developer.android.com/studio/run/device for official guide

---

Once your phone is detected, you can proceed with:

```powershell
cd apps/mobile
flutter run
```

This will build and deploy the Librio benchmark app to your Infinix-Note50.
