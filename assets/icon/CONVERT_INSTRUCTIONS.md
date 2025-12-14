# 🎨 How to Convert SVG to PNG

## Method 1: Using the HTML Converter (Easiest!)

1. **Open the converter:**
   - Navigate to `assets/icon/` folder
   - Double-click `convert_svg_to_png.html`
   - It will open in your web browser

2. **Convert:**
   - Select "Simple Logo (Recommended)" from dropdown
   - Choose size: **1024x1024** (for app icons)
   - Click "Convert to PNG"
   - Click "Download PNG"

3. **Save the file:**
   - Save as `app_icon.png` in the `assets/icon/` folder
   - Replace the existing `app_icon.jpg` if needed

## Method 2: Online Converter

1. Go to https://cloudconvert.com/svg-to-png
2. Upload `app_logo_simple.svg`
3. Set output size to **1024x1024**
4. Convert and download
5. Save as `app_icon.png`

## Method 3: Command Line (if you have ImageMagick)

```bash
cd assets/icon
magick convert app_logo_simple.svg -resize 1024x1024 app_icon.png
```

## Method 4: Using Inkscape (Free Software)

1. Download Inkscape: https://inkscape.org/
2. Open `app_logo_simple.svg`
3. File → Export PNG Image
4. Set size to 1024x1024
5. Export as `app_icon.png`

---

## After Converting

1. Update `pubspec.yaml`:
   ```yaml
   image_path: "assets/icon/app_icon.png"  # Change from .jpg
   adaptive_icon_background: "#4CAF50"     # Match logo green
   ```

2. Regenerate app icons:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

3. Rebuild your app!


