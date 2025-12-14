@echo off
REM Auto-increment version and build App Bundle for Windows

echo 🚀 Starting App Bundle build with auto-version increment...

REM Increment version
dart run scripts/increment_version.dart
if %errorlevel% neq 0 (
    echo ❌ Failed to increment version
    exit /b 1
)

REM Build App Bundle
echo 📦 Building App Bundle...
flutter build appbundle --release
if %errorlevel% neq 0 (
    echo ❌ Build failed
    exit /b 1
)

echo ✅ Build complete!


