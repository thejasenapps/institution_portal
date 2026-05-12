// test/unit/controllers/theme_controller_test.dart
//
// Unit tests for ThemeController.
// Tests: toggleTheme switches isDarkMode and persists to GetStorage,
//        onInit reads 'theme_is_dark' from storage, falls back to light on failure.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mocktail/mocktail.dart';

import 'package:institution_portal/controllers/theme_controller.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockGetStorage extends Mock implements GetStorage {}

void main() {
  late MockGetStorage mockStorage;

  setUp(() {
    Get.testMode = true;
    mockStorage = MockGetStorage();
  });

  tearDown(() {
    Get.reset();
  });

  // -------------------------------------------------------------------------
  // ThemeController.toggleTheme()
  // -------------------------------------------------------------------------

  group('ThemeController.toggleTheme()', () {
    test('switches isDarkMode from false to true and writes to storage',
        () async {
      // Storage returns false (light theme) on init
      when(() => mockStorage.read<bool>('theme_is_dark')).thenReturn(false);
      when(() => mockStorage.write('theme_is_dark', any())).thenAnswer((_) async {});

      final controller = ThemeController(mockStorage);
      // Manually set to false (simulating onInit result)
      controller.isDarkMode.value = false;

      controller.toggleTheme();

      expect(controller.isDarkMode.value, isTrue);
      verify(() => mockStorage.write('theme_is_dark', true)).called(1);
    });

    test('switches isDarkMode from true to false and writes to storage',
        () async {
      when(() => mockStorage.read<bool>('theme_is_dark')).thenReturn(true);
      when(() => mockStorage.write('theme_is_dark', any())).thenAnswer((_) async {});

      final controller = ThemeController(mockStorage);
      controller.isDarkMode.value = true;

      controller.toggleTheme();

      expect(controller.isDarkMode.value, isFalse);
      verify(() => mockStorage.write('theme_is_dark', false)).called(1);
    });

    test('toggling twice returns to original state', () async {
      when(() => mockStorage.read<bool>('theme_is_dark')).thenReturn(false);
      when(() => mockStorage.write('theme_is_dark', any())).thenAnswer((_) async {});

      final controller = ThemeController(mockStorage);
      controller.isDarkMode.value = false;

      controller.toggleTheme(); // false → true
      controller.toggleTheme(); // true → false

      expect(controller.isDarkMode.value, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // ThemeController.onInit() — theme persistence
  // -------------------------------------------------------------------------

  group('ThemeController.onInit()', () {
    test('reads theme_is_dark=true from storage → isDarkMode=true', () {
      when(() => mockStorage.read<bool>('theme_is_dark')).thenReturn(true);

      final controller = ThemeController(mockStorage);
      controller.onInit();

      expect(controller.isDarkMode.value, isTrue);
    });

    test('reads theme_is_dark=false from storage → isDarkMode=false', () {
      when(() => mockStorage.read<bool>('theme_is_dark')).thenReturn(false);

      final controller = ThemeController(mockStorage);
      controller.onInit();

      expect(controller.isDarkMode.value, isFalse);
    });

    test('storage returns null (key absent) → isDarkMode=false (light theme default)',
        () {
      when(() => mockStorage.read<bool>('theme_is_dark')).thenReturn(null);

      final controller = ThemeController(mockStorage);
      controller.onInit();

      expect(controller.isDarkMode.value, isFalse);
    });

    test('storage read throws → isDarkMode=false (light theme fallback)', () {
      when(() => mockStorage.read<bool>('theme_is_dark'))
          .thenThrow(Exception('Storage failure'));

      final controller = ThemeController(mockStorage);
      controller.onInit();

      expect(controller.isDarkMode.value, isFalse);
    });
  });
}
