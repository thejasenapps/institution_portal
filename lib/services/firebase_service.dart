import 'package:cloud_firestore/cloud_firestore.dart';

import 'anonymous_auth_service.dart';
import '../models/expert_model.dart';
import '../models/institution_model.dart';
import '../models/session_model.dart';
import '../models/topic_model.dart';

/// Typed exception thrown by [FirebaseService] when a Firestore operation fails.
class FirebaseServiceException implements Exception {
  /// A human-readable description of what went wrong.
  final String message;

  /// The underlying cause, if available.
  final Object? cause;

  const FirebaseServiceException(this.message, {this.cause});

  @override
  String toString() =>
      'FirebaseServiceException: $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// Encapsulates all Firestore read and write operations for the Institution
/// Management Portal.
///
/// **Write constraint**: exactly two write methods exist on this class —
/// [updateInstitutionName] and [updateInstitutionLogoUrl]. No other write,
/// set, update, or delete method is exposed.
///
/// All methods apply a 2-second timeout and rethrow failures as
/// [FirebaseServiceException].
class FirebaseService {
  final FirebaseFirestore _firestore;
  final AnonymousAuthService? _anonymousAuthService;

  /// The timeout applied to every Firestore operation.
  static const Duration _timeout = Duration(seconds: 2);

  /// Creates a [FirebaseService] backed by the given [FirebaseFirestore]
  /// instance.
  FirebaseService(this._firestore, {AnonymousAuthService? anonymousAuthService})
    : _anonymousAuthService = anonymousAuthService;

  Future<void> _ensureAuthenticatedWrite() async {
    if (_anonymousAuthService == null) return;
    try {
      await _anonymousAuthService.ensureAuthenticated();
    } catch (e) {
      throw FirebaseServiceException(
        'Authentication is required before writing institution updates.',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // READ METHODS
  // ---------------------------------------------------------------------------

  /// Queries the `institutions` collection for a document whose `email` field
  /// matches [email] (case-insensitive).
  ///
  /// Emails are stored and queried in lowercase to achieve case-insensitive
  /// matching. Returns `null` when no matching document is found.
  ///
  /// Throws [FirebaseServiceException] on any Firestore or timeout error.
  Future<InstitutionModel?> findInstitutionByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('institutions')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get()
          .timeout(_timeout);

      if (snapshot.docs.isEmpty) return null;
      return InstitutionModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      throw FirebaseServiceException(
        'Failed to find institution by email.',
        cause: e,
      );
    }
  }

  /// Reads a single institution document by matching the `id` field value
  /// (not the Firestore document ID) against [institutionId].
  ///
  /// Returns `null` when no matching document is found.
  ///
  /// Throws [FirebaseServiceException] on any Firestore or timeout error.
  Future<InstitutionModel?> getInstitution(String institutionId) async {
    try {
      final snapshot = await _firestore
          .collection('institutions')
          .where('id', isEqualTo: institutionId)
          .limit(1)
          .get()
          .timeout(_timeout);

      if (snapshot.docs.isEmpty) return null;
      return InstitutionModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      throw FirebaseServiceException('Failed to get institution.', cause: e);
    }
  }

  /// Queries the `topics` collection for all documents where the
  /// `institutionId` field equals [institutionId].
  ///
  /// Returns an empty list when no matching documents are found.
  ///
  /// Throws [FirebaseServiceException] on any Firestore or timeout error.
  Future<List<TopicModel>> getTopicsForInstitution(String institutionId) async {
    try {
      final snapshot = await _firestore
          .collection('topics')
          .where('institutionId', isEqualTo: institutionId)
          .get()
          .timeout(_timeout);

      return snapshot.docs.map((doc) => TopicModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw FirebaseServiceException(
        'Failed to get topics for institution.',
        cause: e,
      );
    }
  }

  /// Reads the `experts/{expertId}` document.
  ///
  /// Returns `null` when the document does not exist.
  ///
  /// Throws [FirebaseServiceException] on any Firestore or timeout error.
  Future<ExpertModel?> getExpert(String expertId) async {
    try {
      final doc = await _firestore
          .collection('experts')
          .doc(expertId)
          .get()
          .timeout(_timeout);

      if (!doc.exists) return null;
      return ExpertModel.fromFirestore(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw FirebaseServiceException('Failed to get expert.', cause: e);
    }
  }

  /// Reads the `sessions/{sessionId}` document.
  ///
  /// Returns `null` when the document does not exist.
  ///
  /// Throws [FirebaseServiceException] on any Firestore or timeout error.
  Future<SessionModel?> getSession(String sessionId) async {
    try {
      final doc = await _firestore
          .collection('sessions')
          .doc(sessionId)
          .get()
          .timeout(_timeout);

      if (!doc.exists) return null;
      return SessionModel.fromFirestore(doc);
    } catch (e) {
      throw FirebaseServiceException('Failed to get session.', cause: e);
    }
  }

  // ---------------------------------------------------------------------------
  // WRITE METHODS (exactly 2)
  // ---------------------------------------------------------------------------

  /// Updates the `name` field on the institution document identified by
  /// [institutionId] (matched via the `id` field, not the Firestore doc ID).
  ///
  /// Throws [FirebaseServiceException] when the institution document cannot be
  /// found or when the Firestore update fails.
  Future<void> updateInstitutionName(String institutionId, String name) async {
    try {
      await _ensureAuthenticatedWrite();

      final snapshot = await _firestore
          .collection('institutions')
          .where('id', isEqualTo: institutionId)
          .limit(1)
          .get()
          .timeout(_timeout);

      if (snapshot.docs.isEmpty) {
        throw FirebaseServiceException(
          'Institution document not found for id: $institutionId',
        );
      }

      await snapshot.docs.first.reference
          .update({'name': name})
          .timeout(_timeout);
    } on FirebaseServiceException {
      rethrow;
    } catch (e) {
      throw FirebaseServiceException(
        'Failed to update institution name.',
        cause: e,
      );
    }
  }

  /// Updates the `logoUrl` field on the institution document identified by
  /// [institutionId] (matched via the `id` field, not the Firestore doc ID).
  ///
  /// Throws [FirebaseServiceException] when the institution document cannot be
  /// found or when the Firestore update fails.
  Future<void> updateInstitutionLogoUrl(
    String institutionId,
    String logoUrl,
  ) async {
    try {
      await _ensureAuthenticatedWrite();

      final snapshot = await _firestore
          .collection('institutions')
          .where('id', isEqualTo: institutionId)
          .limit(1)
          .get()
          .timeout(_timeout);

      if (snapshot.docs.isEmpty) {
        throw FirebaseServiceException(
          'Institution document not found for id: $institutionId',
        );
      }

      await snapshot.docs.first.reference
          .update({'logo': logoUrl, 'logoUrl': logoUrl})
          .timeout(_timeout);
    } on FirebaseServiceException {
      rethrow;
    } catch (e) {
      throw FirebaseServiceException(
        'Failed to update institution logo URL.',
        cause: e,
      );
    }
  }
}
