import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore model for sessions collection
class SessionModel {
  final String sessionId;
  final int eventId;
  final String session;
  final String sessionType;
  final int scheduleId;
  final int? groupCount;
  final int? groupSlotLeft;
  final String? link;
  final String? location;
  final List<dynamic>? timeInterval;
  final List<dynamic>? weekdays;
  final String? dateTime;
  final int? selectedHours;

  const SessionModel({
    required this.sessionId,
    required this.eventId,
    required this.session,
    required this.sessionType,
    required this.scheduleId,
    this.groupCount,
    this.groupSlotLeft,
    this.link,
    this.location,
    this.timeInterval,
    this.weekdays,
    this.dateTime,
    this.selectedHours,
  });

  /// Create model from Firestore document
  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return SessionModel(
      sessionId: (data['sessionId'] as String?) ?? doc.id,
      eventId: (data['eventId'] as num?)?.toInt() ?? 0,
      session: (data['session'] as String?) ?? '',
      sessionType: (data['sessionType'] as String?) ?? '',
      scheduleId: (data['scheduleId'] as num?)?.toInt() ?? 0,
      groupCount: (data['groupCount'] as num?)?.toInt(),
      groupSlotLeft: (data['groupSlotLeft'] as num?)?.toInt(),
      link: data['link'] as String?,
      location: data['location'] as String?,
      timeInterval: data['timeInterval'] as List<dynamic>? ?? [],
      weekdays: data['weekdays'] as List<dynamic>? ?? [],
      dateTime: data['dateTime'] as String?,
      selectedHours: (data['selectedHours'] as num?)?.toInt(),
    );
  }


  /// Convert model to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'eventId': eventId,
      'session': session,
      'sessionType': sessionType,
      'scheduleId': scheduleId,
      'groupCount': groupCount ?? 0,
      'groupSlotLeft': groupSlotLeft ?? 0,
      'link': link ?? '',
      'location': location ?? '',
      'timeInterval': timeInterval ?? [],
      'weekdays': weekdays ?? [],
      'dateTime': dateTime ?? '',
      'selectedHours': selectedHours ?? 1,
    };
  }
}