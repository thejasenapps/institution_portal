import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a topic document from the Firestore `topics` collection.
class TopicModel {
  /// The topic's unique Firestore document ID.
  final String topicId;

  /// The display name of the topic.
  final String name;

  /// The ID of the expert associated with this topic.
  final String expertId;

  /// The ID of the session linked to this topic.
  ///
  /// May be empty when no session has been assigned yet.
  final String sessionId;

  /// The ID of the institution that owns this topic.
  final String institutionId;

  /// Optional skill type classification for the topic.
  final String? skillType;

  /// Optional status of the topic (e.g. "active", "inactive").
  final String? status;

  /// Optional URL for the topic's cover image.
  final String? imageUrl;

  /// Optional session type descriptor (e.g. "one-on-one", "group").
  final String? sessionType;

  /// Optional description of the topic.
  final String? description;

  const TopicModel({
    required this.topicId,
    required this.name,
    required this.expertId,
    required this.sessionId,
    required this.institutionId,
    this.skillType,
    this.status,
    this.imageUrl,
    this.sessionType,
    this.description,
  });

  /// Converts this model to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'topicId': topicId,
      'name': name,
      'expertId': expertId,
      'sessionId': sessionId,
      'institutionId': institutionId,
      if (skillType != null) 'skillType': skillType,
      if (status != null) 'status': status,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (sessionType != null) 'sessionType': sessionType,
      if (description != null) 'description': description,
    };
  }

  /// Creates a [TopicModel] from a Firestore [DocumentSnapshot].
  ///
  /// Handles:
  /// - Missing, null, or empty `sessionId` — defaults to empty string `''`.
  /// - Missing or null required string fields — default to empty string `''`.
  /// - Missing or null optional fields — default to `null`.
  factory TopicModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // sessionId may be absent, null, or explicitly empty — always default to ''.
    final rawSessionId = data['sessionId'];
    final String sessionId =
        (rawSessionId is String && rawSessionId.isNotEmpty)
            ? rawSessionId
            : '';

    return TopicModel(
      topicId: (data['topicId'] as String?) ?? doc.id,
      name: (data['name'] as String?) ?? '',
      expertId: (data['expertId'] as String?) ?? '',
      sessionId: sessionId,
      institutionId: (data['institutionId'] as String?) ?? '',
      skillType: data['skillType'] as String?,
      status: data['status'] as String?,
      imageUrl: data['imageUrl'] as String?,
      sessionType: data['sessionType'] as String?,
      description: data['description'] as String?,
    );
  }
}
