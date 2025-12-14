# 🚀 Auto-Version Build Scripts

These scripts automatically increment your app version before building a release.

## 📋 How It Works

The version format in `pubspec.yaml` is: `MAJOR.MINOR.PATCH+BUILD`

Example: `2.0.0+1`
- `2.0.0` = Version name (shown to users)
- `1` = Build number (auto-incremented)

Every time you build a release, the **build number** (+1, +2, +3...) automatically increments!

## 🎯 Usage

### Windows (PowerShell/CMD)

**Build APK:**
```bash
scripts\build_release.bat
```

**Build App Bundle (for Play Store):**
```bash
scripts\build_appbundle.bat
```

### Linux/Mac

**Build APK:**
```bash
chmod +x scripts/build_release.sh
./scripts/build_release.sh
```

**Build App Bundle:**
```bash
chmod +x scripts/build_appbundle.sh
./scripts/build_appbundle.sh
```

### Manual Version Increment Only

If you just want to increment the version without building:
```bash
dart run scripts/increment_version.dart
```

## 📝 Version Format

- **MAJOR** - Increment for major changes (breaking changes)
- **MINOR** - Increment for new features (backward compatible)
- **PATCH** - Increment for bug fixes
- **BUILD** - Auto-incremented on every release build

### Example Version Progression:
```
2.0.0+1  → First release
2.0.0+2  → Second build (same version, different build)
2.0.1+3  → Bug fix release
2.1.0+4  → New feature release
3.0.0+5  → Major update
```

## 🔧 Manual Version Update

To manually update the version (e.g., for a new feature), edit `pubspec.yaml`:

```yaml
version: 2.1.0+0  # Change to 2.1.0, build number will auto-increment to +1 on next build
```

## ⚠️ Important Notes

1. **Build number always increments** - Even if you manually change the version name
2. **Version is updated in pubspec.yaml** - Make sure to commit this change
3. **Works with Git** - The version change is saved to your file

## 🎨 Example Workflow

```bash
# 1. Make your code changes
# 2. Update version name if needed (e.g., 2.0.0 → 2.1.0)
# 3. Run build script
scripts\build_release.bat

# Output:
# ✅ Version updated: 2.0.0+5 → 2.0.0+6
# 📦 Building release APK...
# ✅ Build complete!
```


