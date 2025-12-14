import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class GoogleSignInService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google - shows account picker for multiple accounts
  Future<UserCredential?> signInWithGoogle(
      {bool forceAccountPicker = true}) async {
    try {
      // Sign out first to force account picker if requested
      if (forceAccountPicker) {
        await _googleSignIn.signOut();
      }

      // Trigger the authentication flow - this will show account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Save or update user data in Firestore
      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Save user data to Firestore
  Future<void> _saveUserToFirestore(User firebaseUser) async {
    try {
      // Check if user already exists
      final exists = await _firestoreService.userExists(firebaseUser.uid);

      if (exists) {
        // Update last login for existing user
        await _firestoreService.updateLastLogin(firebaseUser.uid);
      } else {
        // Create new user with default fee ranges
        final newUser = UserModel(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email,
          phoneNumber: firebaseUser.phoneNumber,
          photoUrl: firebaseUser.photoURL,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          feeRanges: [
            FeeRange(from: 1, to: 500, fee: 5),
            FeeRange(from: 501, to: 1000, fee: 10),
            FeeRange(from: 1001, to: 5000, fee: 20),
          ],
        );

        await _firestoreService.saveUser(newUser);
      }
    } catch (e) {
      print('Error saving user to Firestore: $e');
      // Don't rethrow - sign in should succeed even if Firestore save fails
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Get user display name
  String? get userDisplayName => currentUser?.displayName;

  // Get user email
  String? get userEmail => currentUser?.email;

  // Get user photo URL
  String? get userPhotoUrl => currentUser?.photoURL;
}
