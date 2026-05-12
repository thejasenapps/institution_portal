import 'package:firebase_auth/firebase_auth.dart';

/// Ensures the app always has a valid Firebase Auth token by signing in
/// anonymously on first use.
///
/// This does NOT replace the custom institution login — it runs silently in
/// the background so that Firestore security rules can verify
/// `request.auth != null` on every read/write.
class AnonymousAuthService {
  final FirebaseAuth _auth;

  AnonymousAuthService(this._auth);

  /// Returns the current [User] if already signed in, otherwise signs in
  /// anonymously and returns the resulting [User].
  ///
  /// Throws [FirebaseAuthException] if the sign-in fails (e.g. Anonymous
  /// provider is disabled in the Firebase console).
  Future<User> ensureSignedIn() async {
    final current = _auth.currentUser;
    if (current != null) return current;

    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  /// The currently signed-in [User], or `null` if not yet authenticated.
  User? get currentUser => _auth.currentUser;

  /// Whether the app currently holds a valid anonymous session.
  bool get isSignedIn => _auth.currentUser != null;
}
