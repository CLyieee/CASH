@echo off
REM Optimized Release Build Script for Android (Windows)
REM Run this script to build an optimized production APK

echo 🚀 Building optimized release APK...
echo.

REM Clean previous builds
echo 🧹 Cleaning previous builds...
call flutter clean
call flutter pub get

echo.
echo 📦 Building optimized release APK...
echo    - Split per ABI (smaller APK size)
echo    - Code obfuscation enabled
echo    - Debug symbols extracted
echo.

REM Build with all optimizations
call flutter build apk ^
  --release ^
  --split-per-abi ^
  --obfuscate ^
  --split-debug-info=build/app/outputs/symbols ^
  --dart-define=dart.vm.product=true ^
  --tree-shake-icons

echo.
echo ✅ Build complete!
echo.
echo 📊 APK Location:
echo    build\app\outputs\flutter-apk\
echo.
dir /B build\app\outputs\flutter-apk\*.apk

echo.
echo 🔍 To analyze bundle size, run:
echo    flutter build apk --analyze-size

pause
