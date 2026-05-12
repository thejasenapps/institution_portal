import 'package:cloud_firestore/cloud_firestore.dart';

class ExpertModel {
  String uniqueId;
  String name;
  String location;
  int experience;
  int minutes;
  List<dynamic>? topics;
  String intro;
  double? rating;
  String? review;
  int? count;
  String? status;
  List<String> languages;
  String imageFile;
  String? imageId;
  bool? isExpert;
  List<String> achievements;
  String? badgeId;
  DateTime? timestamp;

  ExpertModel({
    required this.uniqueId,
    required this.name,
    required this.minutes,
    required this.topics,
    required this.intro,
    required this.location,
    required this.experience,
    this.rating,
    this.review,
    this.count,
    this.status,
    required this.languages,
    required this.imageFile,
    this.imageId,
    this.isExpert,
    required this.achievements,
    this.badgeId,
    this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'uniqueId': uniqueId,
    'name': name,
    'minutes': minutes,
    'experience': experience,
    'location': location,
    'topics': topics,
    'intro': intro,
    'status': status ?? "offline",
    'languages': languages,
    'imageFile': imageFile,
    'imageId': imageId ?? '',
    'isExpert': isExpert ?? false,
    'achievements': achievements ,
    'badgeId': badgeId ?? '',
    'timestamp': timestamp,
  };

  factory ExpertModel.fromFirestore(Map<String, dynamic> json) => ExpertModel(
      uniqueId: json["uniqueId"] ?? '',
      name: json["name"] ?? '',
      minutes: json["minutes"] ?? 60,
      experience: json["experience"] ?? 0,
      location: json["location"] ?? "unknown",
      topics: json["topics"] ?? [],
      intro: json["intro"] ?? '',
      rating: (json['rating'] ?? 0 as num?)?.toDouble(),
      review: json['review'] ?? '',
      count: json["count"] ?? 0,
      status: json["status"] ?? "online",
      languages: json["languages"] != null ? List<String>.from(json["languages"]) : [],
      imageFile: json["imageFile"] ?? '',
      imageId: json["imageId"] ?? '',
      achievements: json["achievements"] != null ? List<String>.from(json["achievements"]) : [],
      isExpert: json["isExpert"] ?? true,
      badgeId: json["badgeId"] ?? '',
      timestamp: json["timestamp"] != null ? (json["timestamp"] as Timestamp).toDate() : null,
  );
}
