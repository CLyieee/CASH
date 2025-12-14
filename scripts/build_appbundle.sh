#!/bin/bash

# Auto-increment version and build App Bundle
echo "🚀 Starting App Bundle build with auto-version increment..."

# Increment version
dart run scripts/increment_version.dart

# Build App Bundle
echo "📦 Building App Bundle..."
flutter build appbundle --release

echo "✅ Build complete!"


