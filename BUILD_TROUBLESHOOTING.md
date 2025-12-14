# 🔧 Build Troubleshooting Guide

## File Lock Error (Windows)

If you get this error:
```
The process cannot access the file because it is being used by another process
```

### Quick Fixes:

1. **Close all processes:**
   - Close Android Studio
   - Close VS Code
   - Close any file explorers with the build folder open
   - Close any running Flutter/Dart processes

2. **Restart your computer** (if above doesn't work)

3. **Kill Java processes:**
   ```powershell
   taskkill /F /IM java.exe
   ```

4. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release --split-per-abi
   ```

5. **Temporarily disable minification** (if urgent):
   - Edit `android/app/build.gradle`
   - Set `minifyEnabled false` and `shrinkResources false`
   - Build will be larger but will work

### Prevention:

- Always close Android Studio before building from command line
- Don't have the build folder open in file explorer
- Wait for previous builds to complete before starting new ones

---

## Build Size

**Current build (without minification):**
- arm64-v8a: ~37MB
- armeabi-v7a: ~28MB
- x86_64: ~36MB

**With minification enabled:**
- Should be ~30-40% smaller
- arm64-v8a: ~25-30MB
- armeabi-v7a: ~20-25MB

---

## Re-enabling Minification

After fixing the file lock issue:

1. Make sure all processes are closed
2. Run `flutter clean`
3. Build again with minification enabled

The build.gradle is already configured correctly - just need to resolve the file lock!


