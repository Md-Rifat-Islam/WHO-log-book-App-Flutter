import '../models/app_user.dart';

class SessionStore {
  SessionStore._();
  static final SessionStore instance = SessionStore._();

  AppUser? currentUser;

  // Added this so AuthService can save the user
  void setUser(AppUser user) {
    currentUser = user;
  }

  // Added this so AuthService can wipe data on logout
  void clear() {
    currentUser = null;
  }
}