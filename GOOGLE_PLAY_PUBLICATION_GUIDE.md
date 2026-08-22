# Google Play Publication Guide for Librio

Complete step-by-step guide to publish Librio to Google Play Store.

## Prerequisites

- Google Play Developer Account ($25 one-time fee)
- Android keystore file (signing key)
- App icon (512x512 PNG)
- Screenshots (2-8 per language)
- App description, privacy policy, etc.

---

## Step 1: Create Signing Key

### Generate a keystore file (one-time)

```bash
cd C:\dev\Librio\apps\mobile\android\app

# Generate keystore (replace with your details)
keytool -genkey -v -keystore librio-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias librio-key \
  -storepass YOUR_STORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD
```

**Important:** Save the keystore file and passwords securely. You'll need them for future updates.

### Reference the keystore in build.gradle.kts

Edit `android/app/build.gradle.kts`:

```kotlin
android {
    ...
    signingConfigs {
        release {
            keyAlias = "librio-key"
            keyPassword = "YOUR_KEY_PASSWORD"
            storeFile = file("librio-release-key.jks")
            storePassword = "YOUR_STORE_PASSWORD"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

---

## Step 2: Update App Configuration

### Update pubspec.yaml

```yaml
version: 1.0.0+1  # Format: version+buildNumber
```

- **version**: User-facing version (1.0.0, 1.0.1, etc.)
- **buildNumber**: Internal build counter (1, 2, 3, etc.)

For updates:
```yaml
version: 1.0.1+2  # New version, new build number
```

### Update AndroidManifest.xml

Check `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.librio.librio">

    <!-- Required permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    
    <application
        android:label="Librio"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher_round">
        ...
    </application>
</manifest>
```

---

## Step 3: Build Release APK/AAB

### Build App Bundle (recommended for Play Store)

```bash
cd C:\dev\Librio\apps\mobile

# Clean build
flutter clean
flutter pub get

# Build App Bundle
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Or build APK (if you prefer)

```bash
flutter build apk --release
```

Output: `build/app/outputs/apk/release/app-release.apk`

---

## Step 4: Set Up Google Play Console

### Create Google Play Developer Account

1. Go to [Google Play Console](https://play.google.com/console)
2. Sign in with your Google account
3. Pay $25 developer fee
4. Accept agreements

### Create New App

1. Click "Create app"
2. App name: "Librio"
3. Default language: English
4. App type: Application
5. Category: Education
6. Content rating: Fill out questionnaire
7. Target audience: Students, educators

---

## Step 5: Fill Out Store Listing

### App Details

- **Title**: Librio (50 chars max)
- **Short description**: "Offline-first AI tutor for studying" (80 chars max)
- **Full description**: 
  ```
  Librio is an offline-first AI academic tutor that helps students study 
  more effectively. Create flashcards, review them with spaced repetition, 
  and chat with an AI tutor powered by on-device LLM models.
  
  Features:
  - Offline-first: Works without internet
  - AI Chat: Ask questions, get explanations
  - Flashcards: Create, edit, review with spaced repetition
  - Multiple LLM Models: Choose from various AI models
  - Privacy-first: Your data stays on your device
  ```

### Graphics

- **Icon** (512x512 PNG): `assets/logo.png`
- **Feature graphic** (1024x500 PNG): Create banner image
- **Screenshots** (1080x1920 PNG, min 2):
  1. Chat screen with AI
  2. Flashcard review
  3. Model selection
  4. Conversation history

### Content Rating

1. Fill out IARC questionnaire
2. Select appropriate ratings
3. Get rating certificate

### Privacy Policy

Create and host a privacy policy. Example:

```
Librio Privacy Policy

1. Data Collection
- Librio processes all data locally on your device
- No data is sent to external servers
- Conversations and flashcards are stored locally

2. Permissions
- Camera: For taking photos of study materials
- Storage: For saving flashcards and conversations

3. Third-party Services
- Optional: Online LLM API (if user enables)
- User controls which services to use

4. Contact
- Email: support@librio.app
```

Host on your website or use a service like:
- GitHub Pages
- Vercel
- Netlify

---

## Step 6: Upload App Bundle

### In Google Play Console

1. Go to "Release" → "Production"
2. Click "Create new release"
3. Upload `app-release.aab`
4. Add release notes:
   ```
   Version 1.0.0 - Initial Release
   
   - Offline AI chat with local LLM models
   - Flashcard creation and review
   - Spaced repetition learning
   - Multiple model support
   - Privacy-first design
   ```
5. Review content rating
6. Review app details
7. Click "Review release"

---

## Step 7: Submit for Review

1. Verify all store listing details
2. Confirm content rating
3. Accept policies
4. Click "Submit release"

**Review time**: 2-4 hours (usually faster)

---

## Step 8: Monitor and Update

### After Approval

- App appears on Google Play Store
- Users can download and install
- Monitor reviews and ratings
- Fix bugs and release updates

### Publishing Updates

For each update:

1. Increment version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2
   ```

2. Rebuild:
   ```bash
   flutter build appbundle --release
   ```

3. Upload to Play Console:
   - Go to "Release" → "Production"
   - Create new release
   - Upload new AAB
   - Add release notes
   - Submit

---

## Troubleshooting

### Build Fails

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build appbundle --release -v
```

### Signing Issues

```bash
# Verify keystore
keytool -list -v -keystore librio-release-key.jks
```

### App Not Appearing

- Check content rating is complete
- Verify all store listing fields are filled
- Ensure app icon is correct format
- Check minimum SDK version (should be ≥21)

---

## Security Checklist

- [ ] Keystore file backed up securely
- [ ] Passwords stored in password manager
- [ ] No secrets in code
- [ ] Privacy policy published
- [ ] Permissions justified in description
- [ ] Content rating completed
- [ ] App tested on multiple devices

---

## Resources

- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Flutter Release Guide](https://flutter.dev/docs/deployment/android)
- [App Bundle Format](https://developer.android.com/guide/app-bundle)
- [Content Rating Guidelines](https://support.google.com/googleplay/android-developer/answer/188189)

---

## Next Steps

1. ✅ Generate signing key
2. ✅ Update build configuration
3. ✅ Build release bundle
4. ✅ Create Play Console account
5. ✅ Fill store listing
6. ✅ Upload and submit
7. ✅ Monitor approval
8. ✅ Launch!

Good luck! 🚀
