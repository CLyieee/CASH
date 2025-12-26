# Background Image Setup

## 📌 Important: Save the Background Image

I've updated your login page and reset password page to use the beautiful space-themed background you provided!

### Steps to Complete Setup:

1. **Save the image you attached** (the blue/purple space background with stars and waves)

2. **Rename it to:** `space_background.jpg`

3. **Save it to this location:**
   ```
   C:\Users\ramil\OneDrive\Documents\Desktop\g\CASH\assets\images\space_background.jpg
   ```

### What's Been Updated:

✅ **Login Page** ([login_page.dart](lib/pages/login_page.dart))
- Added background image as full-screen backdrop
- Updated colors to semi-transparent white for better visibility on the background
- Text and buttons now have glass-morphism effect

✅ **Forgot PIN / Reset Password Page** ([forgot_pin_page.dart](lib/pages/forgot_pin_page.dart))
- Added same background image for consistency
- Updated color palette to match the space theme
- All UI elements are now semi-transparent for a modern look

✅ **Assets Configuration** ([pubspec.yaml](pubspec.yaml))
- Added `assets/images/` to asset paths

### Design Features:

🎨 **Glass-morphism Effect:**
- Semi-transparent cards with `Colors.white.withOpacity(0.15)`
- White text with subtle transparency
- Accent colors pop beautifully against the space background

🌌 **Space Theme:**
- Deep blue and purple gradient background
- Stars and cosmic waves create depth
- Professional and modern aesthetic

### Next Steps:

1. Save the image as instructed above
2. Run `flutter pub get` to ensure assets are recognized
3. Run your app to see the beautiful new background!

### If You Need to Change the Image:

- Replace `space_background.jpg` in `assets/images/` with any other image
- Or update the file name in both:
  - `lib/pages/login_page.dart` (line ~351)
  - `lib/pages/forgot_pin_page.dart` (line ~279)

---

**Note:** The image format can be JPG, PNG, or WebP. Just make sure the filename matches what's in the code!
