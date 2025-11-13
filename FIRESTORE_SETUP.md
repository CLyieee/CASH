# Firebase Firestore User Storage Setup

## ✅ What's Been Implemented

### 1. User Data Model (`lib/models/user_model.dart`)
Complete user data structure with:
- `uid` - User ID (from Firebase Auth)
- `name` - User's display name
- `email` - User's email
- `phoneNumber` - User's phone number
- `photoUrl` - Profile photo URL
- `pin` - Security PIN
- `createdAt` - Account creation timestamp
- `lastLogin` - Last login timestamp
- `feeRanges` - Custom fee structure list

### 2. Firestore Service (`lib/services/firestore_service.dart`)
Complete CRUD operations:
- ✅ `saveUser()` - Create/update user
- ✅ `getUser()` - Get user by UID
- ✅ `userExists()` - Check if user exists
- ✅ `updateUserName()` - Update name
- ✅ `updateUserPhone()` - Update phone
- ✅ `updateUserPin()` - Update PIN
- ✅ `updateFeeRanges()` - Update fee structure
- ✅ `updateLastLogin()` - Update login timestamp
- ✅ `deleteUser()` - Delete user data
- ✅ `streamUser()` - Real-time user data updates
- ✅ `searchUsersByName()` - Search functionality
- ✅ `getAllUsers()` - Get all users (admin)

### 3. Google Sign In Integration
- ✅ Automatically creates user in Firestore on first sign in
- ✅ Updates last login timestamp on subsequent sign ins
- ✅ Loads user data from Firestore after authentication
- ✅ Syncs with AppController state

### 4. AppController Updates
- ✅ `loadUserData()` - Load from Firestore
- ✅ `saveUserData()` - Save to Firestore
- ✅ Auto-sync: All setters now update Firestore automatically
- ✅ Tracks current user ID

## 📊 Firestore Database Structure

```
users (collection)
  └── {uid} (document)
      ├── uid: string
      ├── name: string
      ├── email: string | null
      ├── phoneNumber: string | null
      ├── photoUrl: string | null
      ├── pin: string | null
      ├── createdAt: timestamp
      ├── lastLogin: timestamp
      └── feeRanges: array
          └── [0]
              ├── from: number
              ├── to: number
              └── fee: number
```

## 🔧 Firebase Console Setup

### Step 1: Enable Firestore Database

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **cashg-2b54c**
3. Click **Firestore Database** in left sidebar
4. Click **Create database**
5. Choose **Start in test mode** (for development)
6. Select your preferred region
7. Click **Enable**
    
### Step 2: Security Rules (For Testing)

In Firestore → Rules tab, use these test rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write for authenticated users
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**For Production**, use stricter rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Users can only read/write their own data
      allow read: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId;
      allow delete: if false; // Prevent deletion
    }
  }
}
```

## 💻 Usage Examples

### Example 1: Google Sign In (Already Implemented)
User data is automatically saved when signing in with Google.

### Example 2: Manual User Creation
```dart
final firestoreService = FirestoreService();

// Create new user
final newUser = UserModel(
  uid: 'user123',
  name: 'John Doe',
  email: 'john@example.com',
  phoneNumber: '+1234567890',
  createdAt: DateTime.now(),
  lastLogin: DateTime.now(),
  feeRanges: [
    FeeRange(from: 1, to: 500, fee: 5),
    FeeRange(from: 501, to: 1000, fee: 10),
  ],
);

await firestoreService.saveUser(newUser);
```

### Example 3: Load User Data
```dart
final controller = Get.find<AppController>();
await controller.loadUserData('user123');

// Access loaded data
print(controller.userName.value);
print(controller.phoneNumber.value);
print(controller.feeRanges);
```

### Example 4: Update User Data
```dart
final controller = Get.find<AppController>();

// These automatically sync to Firestore
controller.setUserName('Jane Doe');
controller.setPhoneNumber('+9876543210');
controller.setPin('1234');
```

### Example 5: Update Fee Ranges
```dart
final controller = Get.find<AppController>();

// Add new fee range
controller.addFeeRange(FeeRange(from: 5001, to: 10000, fee: 50));

// Update existing range
controller.updateFeeRange(0, FeeRange(from: 1, to: 500, fee: 10));

// Remove range
controller.removeFeeRange(2);
```

### Example 6: Real-time User Updates
```dart
final firestoreService = FirestoreService();

// Listen to real-time changes
firestoreService.streamUser('user123').listen((user) {
  if (user != null) {
    print('User updated: ${user.name}');
    // Update UI automatically
  }
});
```

### Example 7: Search Users
```dart
final firestoreService = FirestoreService();

// Search by name
final users = await firestoreService.searchUsersByName('John');
for (var user in users) {
  print('Found: ${user.name} - ${user.email}');
}
```

## 🔄 Data Flow

1. **Sign In** → User authenticates with Google
2. **Check Firestore** → Service checks if user exists
3. **Create/Update** → New user created OR last login updated
4. **Load Data** → AppController loads user data
5. **Sync Changes** → All updates automatically sync to Firestore

## 🎯 Key Features

### Automatic Sync
- All AppController setters update Firestore automatically
- No manual save calls needed for most operations

### Error Handling
- All Firestore operations have try-catch blocks
- Errors are logged but don't crash the app
- Sign-in succeeds even if Firestore save fails

### Performance
- Data is cached locally by Firestore SDK
- Real-time updates use efficient listeners
- Batch operations available for bulk updates

### Security
- User can only access their own data
- Firebase Security Rules enforce access control
- No sensitive data exposed

## 📱 Testing

### Test User Creation
```dart
// Sign in with Google → User automatically created

// Check in Firebase Console:
// Firestore → users collection → [user_uid] document
```

### Test Data Updates
```dart
final controller = Get.find<AppController>();
controller.setUserName('Test User');

// Check Firebase Console → users → [uid] → name field
```

### Test Fee Ranges
```dart
controller.addFeeRange(FeeRange(from: 10001, to: 20000, fee: 100));

// Check Firebase Console → users → [uid] → feeRanges array
```

## 🚀 Next Steps

1. **Enable Firestore** in Firebase Console (Step 1 above)
2. **Set Security Rules** (Step 2 above)
3. **Run the app** and sign in with Google
4. **Check Firestore** in Firebase Console to see your user data

## 📝 Files Created/Modified

### New Files
- ✅ `lib/models/user_model.dart` - User data model
- ✅ `lib/services/firestore_service.dart` - Firestore operations
- ✅ `FIRESTORE_SETUP.md` - This documentation

### Modified Files
- ✅ `lib/services/google_sign_in_service.dart` - Auto-save on sign in
- ✅ `lib/controllers/app_controller.dart` - Firestore integration
- ✅ `lib/pages/login_selection_page.dart` - Load data after sign in

## 🎉 Ready to Use!

Your app now has complete user data storage with:
- ✅ Automatic user creation on Google Sign In
- ✅ Real-time data synchronization
- ✅ Persistent storage in Firestore
- ✅ Automatic updates on all data changes
- ✅ Secure user data access

Just enable Firestore in Firebase Console and you're all set!
