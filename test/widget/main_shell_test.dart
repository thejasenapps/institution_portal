// test/widget/main_shell_test.dart
//
// Widget tests for MainShell responsive layout.
// Tests: sidebar width 240px on desktop, 72px on tablet, hidden on mobile,
//        Drawer opens on mobile.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import 'package:institution_portal/controllers/auth_controller.dart';
import 'package:institution_portal/controllers/navigation_controller.dart';
import 'package:institution_portal/views/main_shell.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockNavigationController extends GetxController
    with Mock
    implements NavigationController {
  @override
  final RxInt activeIndex = 0.obs;

  @override
  void navigateTo(int index) {
    activeIndex.value = index;
  }
}

class MockAuthController extends GetxController
    with Mock
    implements AuthController {
  @override
  final RxString institutionId = 'test-institution'.obs;

  @override
  final RxBool isLoading = false.obs;

  @override
  final RxnString errorMessage = RxnString();

  @override
  bool get isAuthenticated => institutionId.value.isNotEmpty;

  @override
  Future<void> logout() async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Sets the physical screen size to [width] x [height] logical pixels
/// (at device pixel ratio 1.0 so logical == physical).
void setScreenSize(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> pumpMainShell(
  WidgetTester tester,
  MockNavigationController mockNav,
  MockAuthController mockAuth,
) async {
  Get.reset();
  Get.put<NavigationController>(mockNav);
  Get.put<AuthController>(mockAuth);

  await tester.pumpWidget(
    GetMaterialApp(
      home: const MainShell(),
    ),
  );
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockNavigationController mockNav;
  late MockAuthController mockAuth;

  setUp(() {
    mockNav = MockNavigationController();
    mockAuth = MockAuthController();
  });

  tearDown(() {
    Get.reset();
  });

  group('MainShell sidebar width tests', () {
    testWidgets('sidebar is 240px wide on desktop (>= 1280px)', (tester) async {
      // Desktop: width >= 1280px
      setScreenSize(tester, 1440, 900);
      await pumpMainShell(tester, mockNav, mockAuth);

      // Find the Sidebar widget and verify its rendered width
      final sidebarFinder = find.byType(Sidebar);
      expect(sidebarFinder, findsOneWidget);

      final sidebarBox =
          tester.renderObject(sidebarFinder) as RenderBox;
      expect(sidebarBox.size.width, equals(240.0));
    });

    testWidgets('sidebar is 72px wide on tablet (768px - 1023px)', (tester) async {
      // Tablet: 768 <= width < 1024
      setScreenSize(tester, 900, 600);
      await pumpMainShell(tester, mockNav, mockAuth);

      final sidebarFinder = find.byType(Sidebar);
      expect(sidebarFinder, findsOneWidget);

      final sidebarBox =
          tester.renderObject(sidebarFinder) as RenderBox;
      expect(sidebarBox.size.width, equals(72.0));
    });

    testWidgets('sidebar is hidden on mobile (< 768px)', (tester) async {
      // Mobile: width < 768
      setScreenSize(tester, 375, 812);
      await pumpMainShell(tester, mockNav, mockAuth);

      // Sidebar widget should not be present in the tree
      expect(find.byType(Sidebar), findsNothing);
    });

    testWidgets('Drawer is present on mobile', (tester) async {
      setScreenSize(tester, 375, 812);
      await pumpMainShell(tester, mockNav, mockAuth);

      // AppBar with hamburger menu should be visible
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('Drawer opens when hamburger icon is tapped on mobile',
        (tester) async {
      setScreenSize(tester, 375, 812);
      await pumpMainShell(tester, mockNav, mockAuth);

      // Tap the hamburger menu icon
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Drawer should now be open — DrawerHeader is a reliable indicator
      expect(find.byType(DrawerHeader), findsOneWidget);
    });

    testWidgets('no AppBar shown on desktop', (tester) async {
      setScreenSize(tester, 1440, 900);
      await pumpMainShell(tester, mockNav, mockAuth);

      expect(find.byType(AppBar), findsNothing);
    });
  });
}
