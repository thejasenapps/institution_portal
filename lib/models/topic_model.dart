import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore model for topics collection
class TopicModel {
  final String? expertId;
  final String name;
  final String topicId;
  final String? expertName;
  final String description;
  final int topicRate;
  final String sessionId;
  final String session;
  final String sessionType;
  final List<String>? expertise;
  final double? rating;
  final String? location;
  final int? count;
  final String? status;
  final String? skillType;
  final String? imageUrl;
  final dynamic audio;
  final String? audioId;
  final List<String>? languages;
  final String? currencySymbol;
  final List<String>? momentsIds;
  final bool availability;
  final String? keywordId;
  final String? meetingUrl;
  final String? badgeId;
  final DateTime? timestamp;
  final String? institutionId;

  const TopicModel({
    this.expertId,
    required this.name,
    required this.topicId,
    this.expertName,
    required this.description,
    required this.topicRate,
    required this.sessionId,
    required this.session,
    required this.sessionType,
    this.expertise,
    this.rating,
    this.location,
    this.count,
    this.status,
    this.skillType,
    this.imageUrl,
    this.audio,
    this.audioId,
    this.languages,
    this.currencySymbol,
    this.momentsIds,
    required this.availability,
    this.keywordId,
    this.meetingUrl,
    this.badgeId,
    this.timestamp,
    this.institutionId,
  });

  /// Create model from Firestore document
  factory TopicModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return TopicModel(
      expertId: data['expertId'] as String?,
      name: (data['name'] as String?) ?? '',
      topicId: (data['topicId'] as String?) ?? doc.id,
      expertName: data['expertName'] as String?,
      description: (data['description'] as String?) ?? '',
      topicRate: (data['topicRate'] as num?)?.toInt() ?? 0,
      sessionId: (data['sessionId'] as String?) ?? '',
      session: (data['session'] as String?) ?? '',
      sessionType: (data['sessionType'] as String?) ?? '',
      expertise:
          (data['expertise'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      rating: (data['rating'] as num?)?.toDouble(),
      location: data['location'] as String?,
      count: (data['count'] as num?)?.toInt(),
      status: data['status'] as String?,
      skillType: data['skillType'] as String?,
      imageUrl: data['imageUrl'] as String?,
      audio: data['audio'],
      audioId: data['audioId'] as String?,
      languages:
          (data['languages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      currencySymbol: data['currencySymbol'] as String? ?? '₹',
      momentsIds:
          (data['momentsIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      availability: (data['availability'] as bool?) ?? false,
      keywordId: data['keywordId'] as String?,
      meetingUrl: data['meetingUrl'] as String?,
      badgeId: data['badgeId'] as String?,
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : null,
      institutionId: data['institutionId'] as String?,
    );
  }

  /// Convert model to JSON / Firestore map
  Map<String, dynamic> toMap() {
    return {
      'expertId': expertId,
      'name': name,
      'topicId': topicId,
      'expertName': expertName,
      'description': description,
      'topicRate': topicRate,
      'sessionId': sessionId,
      'session': session,
      'sessionType': sessionType,
      'expertise': expertise ?? [],
      'rating': rating,
      'location': location,
      'count': count,
      'status': status,
      'skillType': skillType,
      'imageUrl': imageUrl,
      'audio': audio,
      'audioId': audioId,
      'languages': languages ?? [],
      'currencySymbol': currencySymbol ?? '₹',
      'momentsIds': momentsIds ?? [],
      'availability': availability,
      'keywordId': keywordId,
      'meetingUrl': meetingUrl,
      'badgeId': badgeId,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
      'institutionId': institutionId,
    };
  }
}
