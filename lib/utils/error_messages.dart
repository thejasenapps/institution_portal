/// User-facing error messages and success messages for the Institution Portal.
///
/// All strings displayed to users should be defined here as constants
/// to ensure consistency and ease of maintenance.
library;

/// Authentication error messages
abstract class AuthErrors {
  /// Displayed when email field validation fails (Requirement 1.2)
  static const String invalidEmail = 'Please enter a valid email address';

  /// Displayed when Institution ID field is empty (Requirement 1.3)
  static const String emptyInstitutionId = 'Institution ID cannot be empty';

  /// Displayed when credentials don't match any institution (Requirement 1.6)
  static const String invalidCredentials =
      'Invalid credentials. Please try again.';
}

/// Mentor data loading error messages
abstract class MentorErrors {
  /// Displayed when some mentor data fails to load (Requirement 4.5)
  static const String partialLoadFailure =
      'Some mentor data could not be loaded.';

  /// Displayed when no mentors are linked to the institution (Requirement 4.7)
  static const String noMentors = 'No mentors are linked to your institution.';
}

/// Profile and media upload error messages
abstract class ProfileErrors {
  /// Displayed when uploaded image exceeds size limit (Requirement 6.9)
  static const String imageTooLarge = 'Image must be 10 MB or smaller.';

  /// Placeholder text for missing bio field (Requirement 5.4)
  static const String missingBio = '—';
}

/// Subscription history messages
abstract class SubscriptionMessages {
  /// Displayed when subscription history is empty (Requirement 7.6)
  static const String noSubscriptionHistory =
      'No previous subscription history.';

  /// Supporting line beneath [noSubscriptionHistory] (empty-state designs).
  static const String noSubscriptionHistoryHint =
      'Your account records will appear here.';

  /// Placeholder for missing subscription expiry (Requirement 3.3)
  static const String noExpiryDate = '—';
}

/// Success messages
abstract class SuccessMessages {
  /// Displayed when institution name is successfully updated (Requirement 6.6)
  static const String nameUpdated = 'Institution name updated.';
}

/// Session data placeholder values
abstract class SessionPlaceholders {
  /// Used when session data is unavailable (Requirement 4.3)
  static const String unknown = 'Unknown';
}

/// Status badge labels
abstract class StatusLabels {
  /// Active subscription status (Requirement 7.4)
  static const String active = 'Active';

  /// Expired subscription status (Requirement 7.5)
  static const String expired = 'Expired';
}

/// Accessibility labels for icon-only buttons (Requirement 11.2)
abstract class AccessibilityLabels {
  /// Label for hamburger menu button
  static const String openNavigationMenu = 'Open navigation menu';

  /// Label for reload button
  static const String reloadMentorData = 'Reload mentor data';

  /// Label for close button
  static const String close = 'Close';
}
