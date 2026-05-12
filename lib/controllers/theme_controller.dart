import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Controls the application theme (dark / light mode) and persists the
/// preference to [GetStorage] under the key [_themeKey].
///
/// Registered as a permanent singleton in `main.dart`:
/// ```dart
/// Get.put<ThemeController>(ThemeController(GetStorage()), permanent: true);
/// ```
class ThemeController extends GetxController {
  /// Whether dark mode is currently active.
  final RxBool isDarkMode = false.obs;

  /// The [GetStorage] instance used to persist the theme preference.
  final GetStorage _storage;

  /// The key used to store the dark-mode boolean in [GetStorage].
  static const String _themeKey = 'theme_is_dark';

  /// Creates a [ThemeController] backed by the given [GetStorage] instance.
  ThemeController(this._storage);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _loadPersistedTheme();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Toggles between dark and light mode, persists the new value, and applies
  /// the updated [ThemeData] to the running application immediately.
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _persistTheme(isDarkMode.value);
    Get.changeTheme(currentTheme);
  }

  /// Returns [ThemeData.dark()] when [isDarkMode] is `true`, otherwise
  /// [ThemeData.light()].
  ///
  /// All colour values are sourced from Flutter's built-in [ThemeData] tokens —
  /// no hardcoded [Color] literals are used here.
  ThemeData get currentTheme =>
      isDarkMode.value ? ThemeData.dark() : ThemeData.light();

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Reads the persisted theme preference from [GetStorage] and applies it.
  ///
  /// Falls back to light theme (isDarkMode = false) if the key is absent or
  /// if [GetStorage] throws any error (Requirement 8.4).
  void _loadPersistedTheme() {
    try {
      final stored = _storage.read<bool>(_themeKey);
      // stored is null when the key has never been written — default to false
      isDarkMode.value = stored ?? false;
    } catch (_) {
      // GetStorage read failure → silent fallback to light theme
      isDarkMode.value = false;
    }
    // Apply the theme before the first frame via WidgetsBinding callback so
    // that Get.changeTheme is called after the widget tree is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.changeTheme(currentTheme);
    });
  }

  /// Persists [value] to [GetStorage] under [_themeKey].
  void _persistTheme(bool value) {
    try {
      _storage.write(_themeKey, value);
    } catch (_) {
      // Persistence failure is non-fatal; in-memory state is already updated.
    }
  }
}
