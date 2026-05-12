import 'package:get/get.dart';

/// Controls the active navigation section in the [MainShell].
///
/// The [activeIndex] observable drives which content view is displayed in the
/// shell's content area. Registered via [MainBinding] when the `/shell` route
/// is accessed.
///
/// ### Index Mapping
/// | Index | Section   |
/// |-------|-----------|
/// | 0     | Dashboard |
/// | 1     | Mentors   |
/// | 2     | Profile   |
/// | 3     | Settings  |
class NavigationController extends GetxController {
  /// The index of the currently active navigation section.
  ///
  /// Initialised to `0` (Dashboard).
  final RxInt activeIndex = 0.obs;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Sets [activeIndex] to [index], making the corresponding section active.
  ///
  /// Calling this method with the same [index] that is already active is
  /// idempotent — [activeIndex] remains unchanged.
  ///
  /// Valid values: `0` (Dashboard), `1` (Mentors), `2` (Profile), `3` (Settings).
  void navigateTo(int index) {
    activeIndex.value = index;
  }
}
