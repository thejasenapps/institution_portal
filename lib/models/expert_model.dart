import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an expert document from the Firestore `experts` collection.
class ExpertModel {
  /// The expert's unique Firestore document ID.
  final String expertId;

  /// The expert's display name.
  final String name;

  /// Optional biography text for the expert.
  final String? bio;

  /// Optional URL for the expert's profile image.
  final String? profileImageUrl;

  const ExpertModel({
    required this.expertId,
    required this.name,
    this.bio,
    this.profileImageUrl,
  });

  /// Converts this model to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'expertId': expertId,
      'name': name,
      if (bio != null) 'bio': bio,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    };
  }

  /// Creates an [ExpertModel] from a Firestore [DocumentSnapshot].
  ///
  /// Handles:
  /// - Missing or null required string fields — default to empty string `''`.
  /// - Missing or null optional fields (`bio`, `profileImageUrl`) — default to `null`.
  factory ExpertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ExpertModel(
      expertId: (data['expertId'] as String?) ?? doc.id,
      name: (data['name'] as String?) ?? '',
      bio: data['bio'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
    );
  }
}
