/// Responsive breakpoint constants for the Institution Management Portal.
///
/// Usage pattern:
/// ```dart
/// final isMobile  = width < Breakpoints.mobile;
/// final isTablet  = width >= Breakpoints.mobile && width < Breakpoints.tablet;
/// final isDesktop = width >= Breakpoints.tablet;
/// ```
abstract class Breakpoints {
  /// Viewports narrower than this value are treated as mobile (< 768 px).
  static const double mobile = 768.0;

  /// Viewports from [mobile] up to (but not including) this value are tablet
  /// (768–1023 px).
  static const double tablet = 1024.0;

  /// Viewports at or above this value are treated as full desktop (≥ 1280 px).
  static const double desktop = 1280.0;
}
