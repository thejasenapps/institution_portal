import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a session document from the Firestore `sessions` collection.
class SessionModel {
  /// The session's unique Firestore document ID.
  final String sessionId;

  /// The session price, stored as a string.
  ///
  /// Firestore may store this as a number or a string — both are handled
  /// by calling `.toString()` on the raw value.
  final String price;

  /// The session duration, stored as a string.
  ///
  /// Firestore may store this as a number or a string — both are handled
  /// by calling `.toString()` on the raw value.
  final String duration;

  /// The session type (e.g. "online", "in-person"), stored as a string.
  ///
  /// Firestore may store this as a number or a string — both are handled
  /// by calling `.toString()` on the raw value.
  final String sessionType;

  const SessionModel({
    required this.sessionId,
    required this.price,
    required this.duration,
    required this.sessionType,
  });

  /// Converts this model to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'price': price,
      'duration': duration,
      'sessionType': sessionType,
    };
  }

  /// Creates a [SessionModel] from a Firestore [DocumentSnapshot].
  ///
  /// Handles:
  /// - Fields stored as numbers or strings — `.toString()` normalises both.
  /// - Missing or null fields — default to empty string `''`.
  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return SessionModel(
      sessionId: (data['sessionId'] as String?) ?? doc.id,
      price: data['price'] != null ? data['price'].toString() : '',
      duration: data['duration'] != null ? data['duration'].toString() : '',
      sessionType:
          data['sessionType'] != null ? data['sessionType'].toString() : '',
    );
  }
}
