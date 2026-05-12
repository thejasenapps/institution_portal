import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the subscription status of a [SubscriptionHistoryEntry].
enum SubscriptionStatus { active, expired }

/// A single entry in an institution's subscription history.
class SubscriptionHistoryEntry {
  /// The UTC start date of this subscription period.
  final DateTime startDate;

  /// The UTC end date of this subscription period.
  final DateTime endDate;

  const SubscriptionHistoryEntry({
    required this.startDate,
    required this.endDate,
  });

  /// Returns the duration of this subscription period in whole days.
  int get durationDays => endDate.difference(startDate).inDays;

  /// Returns [SubscriptionStatus.active] if the current UTC time falls within
  /// [startDate, endDate] (inclusive on both ends), otherwise [SubscriptionStatus.expired].
  SubscriptionStatus get status {
    final now = DateTime.now().toUtc();
    if ((now.isAfter(startDate) && now.isBefore(endDate)) ||
        now.isAtSameMomentAs(startDate) ||
        now.isAtSameMomentAs(endDate)) {
      return SubscriptionStatus.active;
    }
    return SubscriptionStatus.expired;
  }

  /// Creates a [SubscriptionHistoryEntry] from a Firestore map.
  /// Handles both [Timestamp] and [String] date representations.
  factory SubscriptionHistoryEntry.fromMap(Map<String, dynamic> map) {
    return SubscriptionHistoryEntry(
      startDate: _parseDateTime(map['startDate']),
      endDate: _parseDateTime(map['endDate']),
    );
  }

  /// Converts this entry to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
    };
  }

  /// Parses a [Timestamp] or ISO-8601 [String] into a UTC [DateTime].
  /// Returns [DateTime.utc(1970)] as a safe fallback for null/unknown values.
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toUtc();
    }
    if (value is String) {
      return DateTime.parse(value).toUtc();
    }
    // Fallback: epoch UTC
    return DateTime.utc(1970);
  }
}

/// Represents an institution document from the Firestore `institutions` collection.
class InstitutionModel {
  /// The institution's unique identifier (value of the `id` field, not the Firestore doc ID).
  final String id;

  /// The institution's email address.
  final String email;

  /// The institution's display name.
  final String name;

  /// Optional URL for the institution's logo image.
  final String? logoUrl;

  /// Optional UTC date/time when the current subscription expires.
  final DateTime? subscriptionExpiry;

  /// Optional name of the current subscription plan.
  final String? plan;

  /// Ordered list of past and current subscription periods.
  final List<SubscriptionHistoryEntry> subscriptionHistory;

  const InstitutionModel({
    required this.id,
    required this.email,
    required this.name,
    this.logoUrl,
    this.subscriptionExpiry,
    this.plan,
    this.subscriptionHistory = const [],
  });

  /// Creates an [InstitutionModel] from a Firestore [DocumentSnapshot].
  ///
  /// Handles:
  /// - Missing or null fields gracefully (nullable fields default to null,
  ///   required string fields default to empty string).
  /// - Firestore [Timestamp] → [DateTime] conversion for date fields.
  /// - Parsing the `subscriptionHistory` array of maps.
  factory InstitutionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Parse subscriptionHistory array
    final rawHistory = data['subscriptionHistory'];
    final List<SubscriptionHistoryEntry> history = [];
    if (rawHistory is List) {
      for (final entry in rawHistory) {
        if (entry is Map<String, dynamic>) {
          try {
            history.add(SubscriptionHistoryEntry.fromMap(entry));
          } catch (_) {
            // Skip malformed entries rather than crashing
          }
        }
      }
    }

    // Parse optional subscriptionExpiry timestamp
    DateTime? subscriptionExpiry;
    final rawExpiry = data['subscriptionExpiry'];
    if (rawExpiry is Timestamp) {
      subscriptionExpiry = rawExpiry.toDate().toUtc();
    } else if (rawExpiry is String) {
      subscriptionExpiry = DateTime.tryParse(rawExpiry)?.toUtc();
    }

    return InstitutionModel(
      id: (data['id'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      logoUrl: data['logoUrl'] as String?,
      subscriptionExpiry: subscriptionExpiry,
      plan: data['plan'] as String?,
      subscriptionHistory: history,
    );
  }

  /// Converts this model to a Firestore-compatible map.
  ///
  /// Suitable for use in Firestore write operations.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (subscriptionExpiry != null)
        'subscriptionExpiry': Timestamp.fromDate(subscriptionExpiry!),
      if (plan != null) 'plan': plan,
      'subscriptionHistory':
          subscriptionHistory.map((e) => e.toMap()).toList(),
    };
  }
}
