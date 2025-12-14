#!/bin/bash

# Auto-increment version and build release APK
echo "🚀 Starting release build with auto-version increment..."

# Increment version
dart run scripts/increment_version.dart

# Build release APK
echo "📦 Building release APK..."
flutter build apk --release --split-per-abi

echo "✅ Build complete!"


