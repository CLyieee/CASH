# 📱 App Update Feature Setup

## ✅ What's Been Added

1. **App Update Service** (`lib/services/app_update_service.dart`)
   - Downloads APK from MediaFire
   - Handles installation permissions
   - Shows download progress

2. **Settings UI** (`lib/pages/settings_page.dart`)
   - "App Update" card in settings
   - Update dialog with progress bar
   - Shows current app version

3. **Android Permissions** (`android/app/src/main/AndroidManifest.xml`)
   - Added `REQUEST_INSTALL_PACKAGES` permission

## 📦 Required Packages

The following packages have been added to `pubspec.yaml`:
- `http: ^1.1.0` - For downloading APK
- `package_info_plus: ^5.0.1` - To get current app version
- `open_filex: ^4.3.2` - To open/install APK file

## 🚀 Setup Steps

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Update MediaFire Link (Optional)

If you want to use a different MediaFire link or get a direct download URL:

1. Open your MediaFire file page
2. Right-click the download button
3. Copy the direct download link (looks like `https://download[number].mediafire.com/...`)
4. Update `lib/services/app_update_service.dart`:
   ```dart
   static const String _mediaFireLink = 'YOUR_DIRECT_DOWNLOAD_URL_HERE';
   ```

### 3. Test the Feature

1. Build and run your app
2. Go to Settings
3. Tap "Check for updates" in the App Update section
4. Tap "Download & Install"
5. Grant install permission when prompted
6. The APK will download and install automatically

## 🎯 How It Works

1. **User taps "Check for updates"** in Settings
2. **Dialog opens** showing current version
3. **User taps "Download & Install"**
4. **App requests install permission** (Android 8.0+)
5. **APK downloads** from MediaFire with progress bar
6. **APK installs automatically** using system installer
7. **User can restart app** to use new version

## 📝 MediaFire Link Format

Your current link:
```
https://www.mediafire.com/file/54tpdypuidawbwk/app-arm64-v8a-release.apk/file
```

The service automatically:
- Follows MediaFire redirects
- Extracts direct download URL
- Downloads the APK file

## ⚠️ Important Notes

1. **MediaFire Links**: The service handles MediaFire redirects automatically, but direct download URLs work faster

2. **Permissions**: 
   - Android 8.0+ requires `REQUEST_INSTALL_PACKAGES` permission (already added)
   - User must grant permission on first use

3. **File Location**: 
   - APK is saved to: `/storage/emulated/0/Android/data/com.example.g/files/app_update.apk`
   - File is automatically opened for installation

4. **Version Checking**: 
   - Currently shows "Check for updates" always
   - You can add server-side version checking later

## 🔧 Customization

### Change Update Link

Edit `lib/services/app_update_service.dart`:
```dart
static const String _mediaFireLink = 'YOUR_NEW_LINK_HERE';
```

### Add Version Checking

You can add a server API to check for updates:
```dart
static Future<bool> checkForUpdate() async {
  final response = await http.get(Uri.parse('YOUR_API_URL/version'));
  final serverVersion = jsonDecode(response.body)['version'];
  final currentVersion = await getCurrentVersion();
  return serverVersion != currentVersion;
}
```

## 🐛 Troubleshooting

**Download fails:**
- Check internet connection
- Verify MediaFire link is accessible
- Try using direct download URL instead

**Install fails:**
- Make sure user granted install permission
- Check if "Install from unknown sources" is enabled
- Verify APK file downloaded correctly

**Permission denied:**
- User must manually grant permission in Android settings
- Go to: Settings → Apps → Your App → Install unknown apps → Allow

## 📱 Testing

1. Build release APK: `flutter build apk --release`
2. Install on device
3. Upload new version to MediaFire
4. Test update feature in Settings
5. Verify download and installation works

---

**Note**: Make sure to run `flutter pub get` after adding the new packages!


