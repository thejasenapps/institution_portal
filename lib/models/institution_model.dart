import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the subscription status of a [SubscriptionHistoryEntry].
enum SubscriptionStatus { active, expired }

/// A single subscription history entry.
class SubscriptionHistoryEntry {
  final DateTime startDate;
  final DateTime endDate;

  const SubscriptionHistoryEntry({
    required this.startDate,
    required this.endDate,
  });

  int get durationDays => endDate.difference(startDate).inDays;

  SubscriptionStatus get status {
    final now = DateTime.now().toUtc();

    if ((now.isAfter(startDate) && now.isBefore(endDate)) ||
        now.isAtSameMomentAs(startDate) ||
        now.isAtSameMomentAs(endDate)) {
      return SubscriptionStatus.active;
    }

    return SubscriptionStatus.expired;
  }

  factory SubscriptionHistoryEntry.fromMap(Map<String, dynamic> map) {
    return SubscriptionHistoryEntry(
      startDate: _parseDateTime(map['startDate']),
      endDate: _parseDateTime(map['endDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toUtc();
    }

    if (value is String) {
      return DateTime.parse(value).toUtc();
    }

    return DateTime.utc(1970);
  }
}

/// Institution model aligned with InstitutionEntity.
class InstitutionModel {
  final String id;
  final String name;
  final dynamic logo;
  final String? email;
  final bool subscriptionStatus;
  final DateTime? subscriptionStartDate;
  final String domainUrl;
  final int? trialLimit;
  final DateTime? subscriptionEndDate;
  final int? subscriptionAmount;

  /// Full structured subscription history
  final List<SubscriptionHistoryEntry>? subscriptionHistory;

  final String? origin;
  final DateTime? registeredAt;

  const InstitutionModel({
    required this.id,
    required this.name,
    required this.logo,
    required this.subscriptionStatus,
    required this.domainUrl,
    required this.email,
    this.subscriptionStartDate,
    this.trialLimit,
    this.subscriptionEndDate,
    this.subscriptionAmount,
    this.subscriptionHistory,
    this.origin,
    this.registeredAt,
  });

  // ---------------------------------------------------------------------------
  // Computed subscription helpers
  // ---------------------------------------------------------------------------

  /// Returns the end date of the most recent subscription history entry.
  /// Falls back to [subscriptionEndDate] if history is absent or empty.
  DateTime? get currentSubscriptionEndDate {
    final history = subscriptionHistory;
    if (history != null && history.isNotEmpty) {
      // Pick the entry whose endDate is the latest.
      final latest = history.reduce(
        (a, b) => a.endDate.isAfter(b.endDate) ? a : b,
      );
      return latest.endDate;
    }
    return subscriptionEndDate;
  }

  /// Returns the start date of the most recent subscription history entry.
  /// Falls back to [subscriptionStartDate] if history is absent or empty.
  DateTime? get currentSubscriptionStartDate {
    final history = subscriptionHistory;
    if (history != null && history.isNotEmpty) {
      final latest = history.reduce(
        (a, b) => a.endDate.isAfter(b.endDate) ? a : b,
      );
      return latest.startDate;
    }
    return subscriptionStartDate;
  }

  /// Whether the current subscription is active, calculated from
  /// [currentSubscriptionStartDate] and [currentSubscriptionEndDate].
  /// Does NOT rely on the stored [subscriptionStatus] bool.
  bool get isSubscriptionActive {
    final start = currentSubscriptionStartDate;
    final end = currentSubscriptionEndDate;
    if (start == null || end == null) return false;
    final now = DateTime.now().toUtc();
    return (now.isAfter(start) || now.isAtSameMomentAs(start)) &&
        (now.isBefore(end) || now.isAtSameMomentAs(end));
  }

  /// Human-readable subscription plan label derived from [subscriptionAmount].
  String get subscriptionPlan {
    if (subscriptionAmount == null) return '—';
    return '\$${subscriptionAmount!} / month';
  }

  /// Create from Firestore document
  factory InstitutionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Parse subscription history
    final rawHistory = data['subscriptionHistory'];
    List<SubscriptionHistoryEntry>? history;

    if (rawHistory is List) {
      history = rawHistory
          .whereType<Map<String, dynamic>>()
          .map((e) => SubscriptionHistoryEntry.fromMap(e))
          .toList();
    }

    return InstitutionModel(
      id: (data['id'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      logo: data['logo'],
      email: data['email'],
      subscriptionStatus:
      (data['subscriptionStatus'] as bool?) ?? false,
      domainUrl: (data['domainUrl'] as String?) ?? '',
      subscriptionStartDate:
      _parseNullableDate(data['subscriptionStartDate']),
      subscriptionEndDate:
      _parseNullableDate(data['subscriptionEndDate']),
      subscriptionAmount: data['subscriptionAmount'] as int?,
      subscriptionHistory: history,
      trialLimit: data['trialLimit'] as int?,
      origin: data['origin'] as String?,
      registeredAt: _parseNullableDate(data['registeredAt']),
    );
  }

  /// Convert model to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'email': email,
      'subscriptionStatus': subscriptionStatus,
      'domainUrl': domainUrl,

      if (subscriptionStartDate != null)
        'subscriptionStartDate':
        Timestamp.fromDate(subscriptionStartDate!),

      if (subscriptionEndDate != null)
        'subscriptionEndDate':
        Timestamp.fromDate(subscriptionEndDate!),

      if (subscriptionAmount != null)
        'subscriptionAmount': subscriptionAmount,

      if (subscriptionHistory != null)
        'subscriptionHistory':
        subscriptionHistory!.map((e) => e.toMap()).toList(),

      if (trialLimit != null)
        'trialLimit': trialLimit,

      if (origin != null)
        'origin': origin,

      if (registeredAt != null)
        'registeredAt': Timestamp.fromDate(registeredAt!),
    };
  }

  /// Empty factory
  factory InstitutionModel.empty() {
    return const InstitutionModel(
      id: '',
      name: '',
      logo: '',
      subscriptionStatus: false,
      domainUrl: '',
      email: ''
    );
  }

  static DateTime? _parseNullableDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toUtc();
    }

    if (value is String) {
      return DateTime.tryParse(value)?.toUtc();
    }

    return null;
  }
}