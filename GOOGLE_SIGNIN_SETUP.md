# Google Sign In Setup Guide

## ✅ Completed Steps

1. **Firebase packages installed**
   - `firebase_core: ^4.2.1`
   - `firebase_auth: ^6.1.2`
   - `google_sign_in: ^6.2.2`

2. **Firebase initialized in main.dart**
   - Added Firebase initialization before app runs
   - Configured with `firebase_options.dart`

3. **Created GoogleSignInService**
   - Location: `lib/services/google_sign_in_service.dart`
   - Methods available:
     - `signInWithGoogle()` - Sign in with Google account
     - `signOut()` - Sign out from both Firebase and Google
     - `currentUser` - Get current Firebase user
     - `authStateChanges` - Stream of authentication changes
     - `userDisplayName`, `userEmail`, `userPhotoUrl` - User info getters

4. **Updated LoginSelectionPage**
   - Google Sign In button now functional
   - Shows loading indicator during sign in
   - Navigates to Dashboard on success
   - Shows error messages if sign in fails

## 🔧 Required: Firebase Console Configuration

To make Google Sign In work, you need to enable it in Firebase Console:

### Step 1: Enable Google Sign-In in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **cashg-2b54c**
3. Click on **Authentication** in the left sidebar
4. Click on **Sign-in method** tab
5. Click on **Google** provider
6. Click **Enable** toggle
7. Select a support email (your email)
8. Click **Save**

### Step 2: Configure Android App (for Google Sign In)

#### Get SHA-1 Certificate Fingerprint

Run this command in your project directory:

```powershell
cd android
./gradlew signingReport
```

Or on Windows:
```powershell
cd android
gradlew.bat signingReport
```

This will output your SHA-1 fingerprint. Look for something like:
```
SHA1: 12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78
```

#### Add SHA-1 to Firebase Console

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll down to **Your apps** section
3. Find your Android app (com.example.g)
4. Click **Add fingerprint**
5. Paste your SHA-1 fingerprint
6. Click **Save**

### Step 3: Download Updated google-services.json

1. In Firebase Console, go to **Project Settings**
2. Scroll down to **Your apps**
3. Click on your Android app
4. Click **Download google-services.json**
5. Replace the file at: `android/app/google-services.json`

## 📱 Testing Google Sign In

### Run the app:
```powershell
flutter run
```

### Test Flow:
1. Launch the app
2. Click "Get Started" on Landing Page
3. On Login Selection Page, click **Google** option
4. Select your Google account
5. You should be redirected to Dashboard with your Google name

## 🔍 Troubleshooting

### Error: "PlatformException(sign_in_failed)"
- **Cause**: SHA-1 certificate not added to Firebase Console
- **Fix**: Follow Step 2 above to add SHA-1 fingerprint

### Error: "API_NOT_CONNECTED"
- **Cause**: Google Sign-In not enabled in Firebase Console
- **Fix**: Follow Step 1 to enable Google provider

### Error: "DEVELOPER_ERROR"
- **Cause**: OAuth client ID mismatch
- **Fix**: 
  1. Make sure SHA-1 is added correctly
  2. Download fresh google-services.json
  3. Run `flutter clean && flutter pub get`

### Package not found errors in IDE
- **Fix**: Run `flutter pub get` and restart your IDE
- The errors will disappear once packages are properly indexed

## 🎨 Features Implemented

### User Experience
- Loading indicator during sign in
- Success message with user name
- Error handling with user-friendly messages
- Smooth navigation transitions

### Security
- Secure OAuth 2.0 authentication
- Firebase Authentication backend
- Automatic token management

## 🚀 Next Steps (Optional Enhancements)

1. **Add Sign Out Functionality**
   - Add a sign-out button in Dashboard
   - Clear user session on sign out

2. **Persist User Session**
   - Use `authStateChanges` stream in main.dart
   - Automatically navigate logged-in users to Dashboard

3. **User Profile Page**
   - Display user photo, name, and email
   - Allow updating user profile

4. **Handle Sign-In Errors Better**
   - Network errors
   - User cancellation
   - Account conflicts

## 📝 Code Locations

- **Main App**: `lib/main.dart`
- **Google Sign In Service**: `lib/services/google_sign_in_service.dart`
- **Login Selection Page**: `lib/pages/login_selection_page.dart`
- **App Controller**: `lib/controllers/app_controller.dart`
- **Firebase Options**: `lib/firebase_options.dart`
- **Android Config**: `android/app/build.gradle`
- **Google Services**: `android/app/google-services.json`

## ✨ Ready to Use!

Once you complete the Firebase Console configuration (Steps 1-3 above), your Google Sign In will be fully functional!
