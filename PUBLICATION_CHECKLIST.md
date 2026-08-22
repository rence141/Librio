# Librio Google Play Publication Checklist

## Pre-Publication (This Week)

### 1. Developer Account
- [ ] Create Google Play Developer Account
- [ ] Pay $25 registration fee
- [ ] Accept all agreements

### 2. Signing Key
- [ ] Generate keystore file (`librio-release-key.jks`)
- [ ] Save keystore password securely
- [ ] Save key password securely
- [ ] Back up keystore file to secure location

### 3. Update Build Configuration
- [ ] Update `android/app/build.gradle.kts` with signing config
- [ ] Verify `pubspec.yaml` version is `1.0.0+1`
- [ ] Test release build locally:
  ```bash
  flutter build appbundle --release
  ```

### 4. App Content
- [ ] Verify app icon (512x512 PNG) exists
- [ ] Create 2-4 screenshots (1080x1920 PNG):
  - [ ] Chat screen
  - [ ] Flashcard review
  - [ ] Model selection
  - [ ] Conversation history
- [ ] Create feature graphic (1024x500 PNG)
- [ ] Write app description (4000 chars max)
- [ ] Write short description (80 chars max)

### 5. Legal & Privacy
- [ ] Create privacy policy (host on website)
- [ ] Create terms of service (optional but recommended)
- [ ] Document permissions usage:
  - [ ] CAMERA: Photo capture for study materials
  - [ ] READ_MEDIA_IMAGES: Access photo library
  - [ ] READ_MEDIA_VIDEO: Access video library
  - [ ] INTERNET: Optional online LLM API

### 6. Content Rating
- [ ] Complete IARC questionnaire
- [ ] Get content rating certificate
- [ ] Verify rating is appropriate

---

## Publication Day

### 1. Final Testing
- [ ] Test app on Android device
- [ ] Verify all features work
- [ ] Check permissions are requested correctly
- [ ] Test offline functionality
- [ ] Test online LLM (if applicable)

### 2. Build Release
```bash
cd C:\dev\Librio\apps\mobile
flutter clean
flutter pub get
flutter build appbundle --release
```

### 3. Google Play Console Setup
- [ ] Create new app in Play Console
- [ ] Set app name: "Librio"
- [ ] Set package name: "com.librio.librio"
- [ ] Select category: Education
- [ ] Select content rating: [Your rating]

### 4. Store Listing
- [ ] Add app title
- [ ] Add short description
- [ ] Add full description
- [ ] Upload app icon
- [ ] Upload feature graphic
- [ ] Upload screenshots (min 2)
- [ ] Add contact email
- [ ] Add website (optional)
- [ ] Add privacy policy URL

### 5. Upload & Review
- [ ] Go to Release → Production
- [ ] Click "Create new release"
- [ ] Upload `app-release.aab`
- [ ] Add release notes:
  ```
  Version 1.0.0 - Initial Release
  
  - Offline AI chat with local LLM models
  - Flashcard creation and review
  - Spaced repetition learning
  - Multiple model support
  - Privacy-first design
  ```
- [ ] Review all details
- [ ] Click "Submit release"

### 6. Monitor Approval
- [ ] Wait for review (2-4 hours typically)
- [ ] Check email for approval/rejection
- [ ] If rejected, fix issues and resubmit

---

## Post-Publication

### 1. Launch
- [ ] App appears on Google Play Store
- [ ] Share link with users
- [ ] Announce on social media

### 2. Monitor
- [ ] Check reviews daily
- [ ] Monitor crash reports
- [ ] Track download numbers
- [ ] Respond to user feedback

### 3. Future Updates
- [ ] Increment version in `pubspec.yaml`
- [ ] Build new release bundle
- [ ] Upload to Play Console
- [ ] Submit new release

---

## Important Files

- **Keystore**: `android/app/librio-release-key.jks` (KEEP SAFE!)
- **Build output**: `build/app/outputs/bundle/release/app-release.aab`
- **Privacy policy**: Host on your website
- **Screenshots**: Store in `assets/play-store/` or similar

---

## Estimated Timeline

| Task | Time |
|------|------|
| Account setup | 1 day |
| Signing key generation | 30 min |
| Build configuration | 30 min |
| Content preparation | 2-3 days |
| Store listing | 1-2 days |
| Build release | 15 min |
| Upload & submit | 30 min |
| Review & approval | 2-4 hours |
| **Total** | **4-7 days** |

---

## Support

For help:
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Flutter Deployment Guide](https://flutter.dev/docs/deployment/android)
- Check `GOOGLE_PLAY_PUBLICATION_GUIDE.md` for detailed instructions

---

## Version History Template

For future releases, use this format:

```
Version 1.0.1 - Bug Fixes
- Fixed flashcard review infinite loop
- Improved UI consistency
- Better error handling

Version 1.0.2 - New Features
- Added group review for multiple decks
- Improved flashcard creation UI
- Better offline support
```

---

Good luck! 🚀 Your app will be live soon!
