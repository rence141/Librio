# Librio Icon & Logo Replacement Guide

**Date**: August 23, 2026  
**Status**: Ready for Implementation

---

## Current Icon Assets

### Mobile App (Flutter)
- **Assets Logo**: `apps/mobile/assets/logo.png` (512x512)
- **iOS Icons**: `apps/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Android Icons**: `apps/mobile/android/app/src/main/res/mipmap-*/ic_launcher.png`
- **Web Icons**: `apps/mobile/web/icons/`

### Web Application (Next.js)
- **Favicon**: `apps/admin/public/favicon.ico`
- **Logo**: Used in landing page and admin dashboard

---

## Icon Sizes Required

### iOS (Apple App Store)
```
Icon-App-20x20@1x.png      (20x20)
Icon-App-20x20@2x.png      (40x40)
Icon-App-20x20@3x.png      (60x60)
Icon-App-29x29@1x.png      (29x29)
Icon-App-29x29@2x.png      (58x58)
Icon-App-29x29@3x.png      (87x87)
Icon-App-40x40@1x.png      (40x40)
Icon-App-40x40@2x.png      (80x80)
Icon-App-40x40@3x.png      (120x120)
Icon-App-60x60@2x.png      (120x120)
Icon-App-60x60@3x.png      (180x180)
Icon-App-76x76@1x.png      (76x76)
Icon-App-76x76@2x.png      (152x152)
Icon-App-83.5x83.5@2x.png  (167x167)
Icon-App-1024x1024@1x.png  (1024x1024)
```

### Android (Google Play Store)
```
mipmap-mdpi/ic_launcher.png     (48x48)
mipmap-hdpi/ic_launcher.png     (72x72)
mipmap-xhdpi/ic_launcher.png    (96x96)
mipmap-xxhdpi/ic_launcher.png   (144x144)
mipmap-xxxhdpi/ic_launcher.png  (192x192)
```

### Web
```
favicon.ico                 (32x32 or 64x64)
Icon-192.png               (192x192)
Icon-512.png               (512x512)
Icon-maskable-192.png      (192x192, with safe zone)
Icon-maskable-512.png      (512x512, with safe zone)
```

---

## Steps to Replace Icons

### Option 1: Using Flutter Icon Generator

**Tool**: `flutter_launcher_icons` package

1. **Add dependency** to `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_launcher_icons: "^0.13.0"
```

2. **Configure** `pubspec.yaml`:
```yaml
flutter_icons:
  image_path: "assets/logo.png"
  image_path_ios: "assets/logo.png"
  image_path_android: "assets/logo.png"
  android: true
  ios: true
  web:
    generate: true
    image_path: "assets/logo.png"
    background_color: "#ffffff"
    theme_color: "#3B82F6"
```

3. **Generate icons**:
```bash
cd apps/mobile
flutter pub get
flutter pub run flutter_launcher_icons
```

### Option 2: Manual Replacement

**For iOS**:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Navigate to `Assets.xcassets/AppIcon.appiconset`
3. Replace each icon file with your new logo
4. Ensure all sizes are correct

**For Android**:
1. Replace files in `android/app/src/main/res/mipmap-*/ic_launcher.png`
2. Ensure correct DPI for each folder:
   - mdpi: 48x48
   - hdpi: 72x72
   - xhdpi: 96x96
   - xxhdpi: 144x144
   - xxxhdpi: 192x192

**For Web**:
1. Replace `web/icons/Icon-192.png` (192x192)
2. Replace `web/icons/Icon-512.png` (512x512)
3. Replace `web/favicon.png` (32x32 or 64x64)

### Option 3: Using Online Tools

**Services**:
- [AppIcon.co](https://appicon.co) - Generate all sizes from one image
- [Favicon Generator](https://favicon-generator.org) - Generate favicons
- [Flutter Icon Generator](https://fluttericon.com) - Flutter-specific icons

**Steps**:
1. Upload your logo (1024x1024 or larger)
2. Select platforms (iOS, Android, Web)
3. Download generated icons
4. Replace files in respective directories

---

## Logo Design Recommendations

### Branding Guidelines
- **Color Palette**: 
  - Primary: #3B82F6 (Blue)
  - Secondary: #8B5CF6 (Purple)
  - Accent: #10B981 (Green)

- **Style**: Modern, clean, minimalist
- **Shape**: Preferably square or circular
- **Safe Zone**: Leave 10% padding around logo

### File Format
- **Source**: SVG (scalable vector)
- **Export**: PNG (raster for app stores)
- **Background**: Transparent or white

### Naming Convention
```
logo-official.png          (Master logo)
logo-icon.png              (Icon version)
logo-icon-rounded.png      (Rounded version)
logo-icon-maskable.png     (Android adaptive icon)
```

---

## Implementation Checklist

### Before Replacement
- [ ] Obtain official Librio logo in high resolution (1024x1024+)
- [ ] Ensure logo is in PNG or SVG format
- [ ] Verify brand guidelines
- [ ] Test logo at small sizes (32x32, 48x48)
- [ ] Backup current icons

### iOS Replacement
- [ ] Replace all Icon-App-*.png files
- [ ] Verify in Xcode Asset Catalog
- [ ] Test on iOS simulator
- [ ] Test on actual iOS device
- [ ] Verify in App Store preview

### Android Replacement
- [ ] Replace all mipmap-*/ic_launcher.png files
- [ ] Verify correct DPI for each folder
- [ ] Test on Android emulator
- [ ] Test on actual Android device
- [ ] Verify in Google Play preview

### Web Replacement
- [ ] Replace favicon.png
- [ ] Replace Icon-192.png
- [ ] Replace Icon-512.png
- [ ] Update manifest.json if needed
- [ ] Test in browser

### After Replacement
- [ ] Test app launch
- [ ] Verify icon displays correctly
- [ ] Check icon in app switcher
- [ ] Verify on home screen
- [ ] Test on multiple devices
- [ ] Update version number
- [ ] Commit changes to git

---

## Quick Commands

### Generate All Icons (Using flutter_launcher_icons)
```bash
cd apps/mobile
flutter pub run flutter_launcher_icons
```

### View Current Icons
```bash
# iOS
open ios/Runner.xcworkspace

# Android
open android/app/src/main/res

# Web
ls -la web/icons/
```

### Verify Icon Sizes
```bash
# macOS/Linux
identify apps/mobile/assets/logo.png
identify apps/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png

# Windows
Get-Item apps/mobile/assets/logo.png | Select-Object Length
```

---

## Troubleshooting

### Icon Not Updating
- Clear build cache: `flutter clean`
- Rebuild app: `flutter pub get && flutter run`
- Clear iOS build: `rm -rf ios/Pods ios/Podfile.lock`
- Clear Android build: `rm -rf android/build`

### Icon Looks Blurry
- Ensure source image is high resolution (1024x1024+)
- Use PNG format (not JPEG)
- Avoid scaling up small images

### Icon Not Showing on App Store
- Verify all required sizes are present
- Check file naming conventions
- Ensure correct color space (sRGB)
- Verify no transparency issues

### Different Icons on Different Devices
- Ensure all size variants are correct
- Check DPI folders for Android
- Verify scale factors for iOS (@1x, @2x, @3x)

---

## Resources

### Tools
- [Flutter Launcher Icons](https://pub.dev/packages/flutter_launcher_icons)
- [AppIcon.co](https://appicon.co)
- [Favicon Generator](https://favicon-generator.org)
- [ImageMagick](https://imagemagick.org) (CLI tool)

### Documentation
- [iOS App Icon Requirements](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Android App Icon Requirements](https://developer.android.com/guide/practices/ui_guidelines/icon_design_launcher)
- [Web Favicon Guide](https://web.dev/favicon-best-practices/)

### Design Tools
- [Figma](https://figma.com) - Design and export
- [Adobe XD](https://www.adobe.com/products/xd.html) - Design
- [Sketch](https://www.sketch.com) - Design (macOS)

---

## Next Steps

1. **Obtain Official Logo**
   - Get high-resolution logo file (1024x1024+)
   - Ensure PNG or SVG format
   - Verify brand guidelines

2. **Prepare Assets**
   - Save as `assets/logo-official.png`
   - Create icon version if needed
   - Test at small sizes

3. **Generate Icons**
   - Use flutter_launcher_icons or manual method
   - Generate all required sizes
   - Verify quality

4. **Replace Icons**
   - Update iOS icons
   - Update Android icons
   - Update web icons

5. **Test & Deploy**
   - Test on all platforms
   - Verify in app stores
   - Deploy to production

---

## Support

For icon design assistance, contact: design@librio.com

For technical issues, contact: support@librio.com

---

*Generated: August 23, 2026*  
*Status: Ready for Implementation*
