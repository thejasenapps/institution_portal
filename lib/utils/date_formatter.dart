import 'package:intl/intl.dart';

/// Utility helpers for formatting dates throughout the portal.
///
/// All functions are top-level so they can be imported and called directly
/// without instantiating a class.

/// Formats a nullable [DateTime] as `dd MMM yyyy` (e.g. "31 Dec 2026").
///
/// Returns the em-dash character `"—"` when [date] is `null`, matching the
/// dashboard and profile views that display `"—"` for absent subscription
/// expiry dates (see Requirements 3.3 and 6.2).
String formatSubscriptionDate(DateTime? date) {
  if (date == null) {
    // No date available — return the em-dash placeholder used across the UI.
    return '—';
  }

  // DateFormat('dd MMM yyyy') produces zero-padded day, abbreviated month
  // name, and four-digit year, e.g. "01 Jan 2025" or "31 Dec 2026".
  return DateFormat('dd MMM yyyy').format(date);
}
