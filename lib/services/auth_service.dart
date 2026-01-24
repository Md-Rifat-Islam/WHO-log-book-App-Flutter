import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../stores/session_store.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Kept your original function name exactly as it was
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Firebase Auth Sign In
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 2. Fetch the AppUser profile from Firestore
      final appUser = await _userService.fetchCurrentUserProfile();

      // 3. Save to global session store
      SessionStore.instance.setUser(appUser);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An unexpected error occurred.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    SessionStore.instance.clear(); // Clear local session data on logout
  }

  User? get currentUser => _auth.currentUser;

  // Helper to keep the main function clean
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'No user found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'network-request-failed': return 'Please check your internet connection.';
      default: return e.message ?? 'Authentication failed.';
    }
  }
}