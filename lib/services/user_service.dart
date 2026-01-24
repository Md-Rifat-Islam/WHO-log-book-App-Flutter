import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/firebase_refs.dart';
import '../models/app_user.dart';

class UserService {
  // Local cache to avoid redundant network calls during the same session
  AppUser? _cachedUser;

  Future<AppUser> fetchCurrentUserProfile({bool forceRefresh = false}) async {
    // 1. Check Auth State
    final User? authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      _cachedUser = null;
      throw StateError('User is not authenticated with Firebase.');
    }

    // 2. Return Cache if available and refresh not forced
    if (_cachedUser != null && !forceRefresh) {
      return _cachedUser!;
    }

    try {
      // 3. Fetch from Firestore
      // We use 'Source.serverAndCache' to balance speed and accuracy
      final DocumentSnapshot<Map<String, dynamic>> snap =
      await usersRef.doc(authUser.uid).get();

      if (!snap.exists || snap.data() == null) {
        throw StateError('Profile document missing in /users/${authUser.uid}');
      }

      // 4. Map to Model and Cache
      _cachedUser = AppUser.fromMap(snap.id, snap.data()!);
      return _cachedUser!;

    } on FirebaseException catch (e) {
      throw Exception('Failed to load profile: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while fetching profile.');
    }
  }

  /// Clear cache on logout
  void clearCache() {
    _cachedUser = null;
  }
}