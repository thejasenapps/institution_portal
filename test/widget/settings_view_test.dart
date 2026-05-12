// test/widget/settings_view_test.dart
//
// Widget tests for SettingsView.
// Tests: SwitchListTile present, label shows "Dark Mode" when isDarkMode=false,
//        label shows "Light Mode" when isDarkMode=true.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mocktail/mocktail.dart';

import 'package:institution_portal/controllers/theme_controller.dart';
import 'package:institution_portal/views/settings_view.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockGetStorage extends Mock implements GetStorage {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<void> pumpSettingsView(
  WidgetTester tester,
  ThemeController themeController,
) async {
  Get.reset();
  Get.put<ThemeController>(themeController);

  await tester.pumpWidget(
    GetMaterialApp(
      home: const Scaffold(body: SettingsView()),
    ),
  );
  await tester.pump();
}

void main() {
  late MockGetStorage mockStorage;

  setUp(() {
    Get.testMode = true;
    mockStorage = MockGetStorage();
    when(() => mockStorage.read<bool>(any())).thenReturn(null);
    when(() => mockStorage.write(any(), any())).thenAnswer((_) async {});
  });

  tearDown(() {
    Get.reset();
  });

  group('SettingsView widget tests', () {
    testWidgets('SwitchListTile is present', (tester) async {
      final controller = ThemeController(mockStorage);
      controller.isDarkMode.value = false;
      await pumpSettingsView(tester, controller);

      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('label shows "Dark Mode" when isDarkMode is false',
        (tester) async {
      final controller = ThemeController(mockStorage);
      controller.isDarkMode.value = false;
      await pumpSettingsView(tester, controller);

      // When light theme is active, the toggle offers to switch to dark mode
      expect(find.text('Dark Mode'), findsOneWidget);
    });

    testWidgets('label shows "Light Mode" when isDarkMode is true',
        (tester) async {
      final controller = ThemeController(mockStorage);
      controller.isDarkMode.value = true;
      await pumpSettingsView(tester, controller);

      // When dark theme is active, the toggle offers to switch to light mode
      expect(find.text('Light Mode'), findsOneWidget);
    });

    testWidgets('secondary text shows "Currently using light theme" when isDarkMode=false',
        (tester) async {
      final controller = ThemeController(mockStorage);
      controller.isDarkMode.value = false;
      await pumpSettingsView(tester, controller);

      expect(find.text('Currently using light theme'), findsOneWidget);
    });

    testWidgets('secondary text shows "Currently using dark theme" when isDarkMode=true',
        (tester) async {
      final controller = ThemeController(mockStorage);
      controller.isDarkMode.value = true;
      await pumpSettingsView(tester, controller);

      expect(find.text('Currently using dark theme'), findsOneWidget);
    });

    testWidgets('SwitchListTile value is false when isDarkMode=false',
        (tester) async {
      final controller = ThemeController(mockStorage);
      controller.isDarkMode.value = false;
      await pumpSettingsView(tester, controller);

      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTile.value, isFalse);
    });

    testWidgets('SwitchListTile value is true when isDarkMode=true',
        (tester) async {
      final controller = ThemeController(mockStorage);
      controller.isDarkMode.value = true;
      await pumpSettingsView(tester, controller);

      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTile.value, isTrue);
    });
  });
}
