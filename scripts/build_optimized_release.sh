#!/bin/bash
# Optimized Release Build Script for Android
# Run this script to build an optimized production APK

echo "🚀 Building optimized release APK..."
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

echo ""
echo "📦 Building optimized release APK..."
echo "   - Split per ABI (smaller APK size)"
echo "   - Code obfuscation enabled"
echo "   - Debug symbols extracted"
echo ""

# Build with all optimizations
flutter build apk \
  --release \
  --split-per-abi \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --dart-define=dart.vm.product=true \
  --tree-shake-icons

echo ""
echo "✅ Build complete!"
echo ""
echo "📊 APK Location:"
echo "   build/app/outputs/flutter-apk/"
echo ""
echo "📈 APK Sizes:"
ls -lh build/app/outputs/flutter-apk/*.apk | awk '{print "   " $9 ": " $5}'

echo ""
echo "🔍 To analyze bundle size, run:"
echo "   flutter build apk --analyze-size"
