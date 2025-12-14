@echo off
REM Auto-increment version and build release APK for Windows

echo 🚀 Starting release build with auto-version increment...

REM Increment version
dart run scripts/increment_version.dart
if %errorlevel% neq 0 (
    echo ❌ Failed to increment version
    exit /b 1
)

REM Build release APK
echo 📦 Building release APK...
flutter build apk --release --split-per-abi
if %errorlevel% neq 0 (
    echo ❌ Build failed
    exit /b 1
)

echo ✅ Build complete!


