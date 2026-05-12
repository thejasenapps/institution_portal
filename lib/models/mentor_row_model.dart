// lib/models/mentor_row_model.dart

class MentorRowModel {
  final String expertId;
  final String mentorName;
  final String topicName;
  final String topicId;
  final String institutionId;
  final String sessionId;
  final String price; // "Unknown" if session skipped/failed
  final String duration; // "Unknown" if session skipped/failed
  final String sessionType; // "Unknown" if session skipped/failed
  // Optional — fetched lazily for DetailPanel
  final String? bio;
  final String? profileImageUrl;

  const MentorRowModel({
    required this.expertId,
    required this.mentorName,
    required this.topicName,
    required this.topicId,
    required this.institutionId,
    required this.sessionId,
    required this.price,
    required this.duration,
    required this.sessionType,
    this.bio,
    this.profileImageUrl,
  });
}
