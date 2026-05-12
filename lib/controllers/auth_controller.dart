import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/firebase_service.dart';

/// Controls authentication state for the Institution Management Portal.
///
/// Stores the authenticated institution's ID in memory (as an [RxString]) and
/// persists it to [SharedPreferences] under the key [_sessionKey] so that
/// sessions survive page reloads.
///
/// Registered via [AuthBinding] when the `/login` route is accessed.
class AuthController extends GetxController {
  // ---------------------------------------------------------------------------
  // Observables
  // ---------------------------------------------------------------------------

  /// The authenticated institution's ID (value of the `id` field from Firestore).
  /// Empty string when not authenticated.
  final RxString institutionId = ''.obs;

  /// Whether an async authentication operation is in progress.
  final RxBool isLoading = false.obs;

  /// The most recent error message from a failed login attempt, or `null` when
  /// no error is present.
  final RxnString errorMessage = RxnString();

  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  /// The [FirebaseService] used to query Firestore for institution documents.
  final FirebaseService _firebaseService;

  /// The [SharedPreferences] instance used to persist the session.
  final SharedPreferences _prefs;

  /// The key under which the institution ID is stored in [SharedPreferences].
  static const String _sessionKey = 'session_institution_id';

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  /// Creates an [AuthController] with the given dependencies.
  AuthController({
    required FirebaseService firebaseService,
    required SharedPreferences prefs,
  }) : _firebaseService = firebaseService,
       _prefs = prefs;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    restoreSession();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Attempts to authenticate the user with the given [email] and
  /// [institutionIdInput].
  ///
  /// **Validation**:
  /// - [email] must pass [isValidEmail] (format + length ≤ 254).
  /// - [institutionIdInput] must pass [isValidInstitutionId] (non-empty trimmed + length ≤ 128).
  ///
  /// **Firestore query**:
  /// - Queries `institutions` collection for a document where `email` matches (case-insensitive).
  /// - Checks that the document's `id` field equals [institutionIdInput] (exact match).
  ///
  /// **On success**:
  /// - Stores [institutionIdInput] in [institutionId] observable.
  /// - Persists to [SharedPreferences] under [_sessionKey].
  /// - Navigates to `/shell`.
  ///
  /// **On failure**:
  /// - Sets [errorMessage] with a user-friendly description.
  /// - Does NOT navigate.
  ///
  /// All async errors are caught and surfaced via [errorMessage].
  Future<void> login(String email, String institutionIdInput) async {
    // Clear any previous error
    errorMessage.value = null;

    // Client-side validation
    if (!isValidEmail(email)) {
      errorMessage.value = 'Please enter a valid email address';
      return;
    }

    if (!isValidInstitutionId(institutionIdInput)) {
      errorMessage.value = 'Institution ID cannot be empty';
      return;
    }

    // Start loading
    isLoading.value = true;

    try {
      // Query Firestore for institution by email
      final institution = await _firebaseService.findInstitutionByEmail(email);

      if (institution == null) {
        errorMessage.value = 'Invalid credentials. Please try again.';
        return;
      }

      // Check that the institution's id field matches the entered ID
      if (institution.id != institutionIdInput.trim()) {
        errorMessage.value = 'Invalid credentials. Please try again.';
        return;
      }

      // Success: store in memory and persist to SharedPreferences
      institutionId.value = institution.id;
      await _prefs.setString(_sessionKey, institution.id);

      // Navigate to the main shell
      Get.offAllNamed('/shell');
    } on FirebaseServiceException catch (e) {
      // Firestore query failed
      errorMessage.value =
          'Authentication failed. Please check your connection and try again.';
      // Log the underlying error for debugging (not shown to user)
      // ignore: avoid_print
      print('FirebaseServiceException during login: $e');
    } catch (e) {
      // Unexpected error
      errorMessage.value = 'An unexpected error occurred. Please try again.';
      // ignore: avoid_print
      print('Unexpected error during login: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Clears the authenticated [institutionId] from memory and removes the
  /// [_sessionKey] from [SharedPreferences], then navigates to the login screen.
  Future<void> logout() async {
    institutionId.value = '';
    await _prefs.remove(_sessionKey);
    Get.offAllNamed('/login');
  }

  /// Reads the [_sessionKey] from [SharedPreferences] on controller
  /// initialisation and restores [institutionId] if a non-empty value is found.
  ///
  /// Called automatically from [onInit].
  Future<void> restoreSession() async {
    try {
      final storedId = _prefs.getString(_sessionKey);
      if (storedId != null && storedId.isNotEmpty) {
        institutionId.value = storedId;
      }
    } catch (e) {
      // Session restore failure is non-fatal; user will see login screen.
      // ignore: avoid_print
      print('Failed to restore session: $e');
    }
  }

  /// Returns `true` when [institutionId] is non-empty, indicating the user is
  /// authenticated.
  bool get isAuthenticated => institutionId.value.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Validation (pure functions — testable)
  // ---------------------------------------------------------------------------

  /// Returns `true` if [email] matches the pattern `[chars]@[domain].[tld]`
  /// AND has a total length of 254 characters or fewer.
  ///
  /// Returns `false` for:
  /// - Empty strings
  /// - Whitespace-only strings
  /// - Strings missing `@`
  /// - Strings missing a TLD (e.g. "user@domain")
  /// - Strings exceeding 254 characters
  ///
  /// **Validates: Requirements 1.2, 1.12**
  static bool isValidEmail(String email) {
    if (email.isEmpty || email.trim().isEmpty) return false;
    if (email.length > 254) return false;

    // Basic pattern: at least one char before @, at least one char after @,
    // and at least one dot after @
    final atIndex = email.indexOf('@');
    if (atIndex <= 0) return false; // no @ or @ is first char

    final afterAt = email.substring(atIndex + 1);
    if (afterAt.isEmpty) return false;

    final dotIndex = afterAt.indexOf('.');
    if (dotIndex <= 0) return false; // no dot or dot is first char after @
    if (dotIndex == afterAt.length - 1) return false; // dot is last char

    return true;
  }

  /// Returns `true` if [id] is non-empty after trimming AND has a length of
  /// 128 characters or fewer.
  ///
  /// Returns `false` for:
  /// - Empty strings
  /// - Whitespace-only strings
  /// - Strings exceeding 128 characters
  ///
  /// **Validates: Requirements 1.3, 1.12**
  static bool isValidInstitutionId(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length > 128) return false;
    return true;
  }
}
