// test/widget/login_page_test.dart
//
// Widget tests for LoginPage.
// Tests: email field present, institution ID field present,
//        submit button disabled when isLoading=true,
//        error text shown when errorMessage is set.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import 'package:institution_portal/controllers/auth_controller.dart';
import 'package:institution_portal/views/login_page.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockAuthController extends GetxController
    with Mock
    implements AuthController {
  @override
  final RxBool isLoading = false.obs;

  @override
  final RxnString errorMessage = RxnString();

  @override
  final RxString institutionId = ''.obs;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pumps [LoginPage] inside a [GetMaterialApp] with a pre-registered
/// [MockAuthController].
Future<void> pumpLoginPage(
  WidgetTester tester,
  MockAuthController mockAuth,
) async {
  Get.reset();
  Get.put<AuthController>(mockAuth);

  await tester.pumpWidget(
    GetMaterialApp(
      home: const LoginPage(),
    ),
  );
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockAuthController mockAuth;

  setUp(() {
    mockAuth = MockAuthController();
  });

  tearDown(() {
    Get.reset();
  });

  group('LoginPage widget tests', () {
    testWidgets('email field is present', (tester) async {
      await pumpLoginPage(tester, mockAuth);

      expect(find.byKey(const Key('emailField')), findsOneWidget);
    });

    testWidgets('institution ID field is present', (tester) async {
      await pumpLoginPage(tester, mockAuth);

      expect(find.byKey(const Key('institutionIdField')), findsOneWidget);
    });

    testWidgets('submit button is disabled when isLoading is true',
        (tester) async {
      mockAuth.isLoading.value = true;
      await pumpLoginPage(tester, mockAuth);

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('submitButton')),
      );
      expect(button.onPressed, isNull,
          reason: 'Button onPressed should be null when loading');
    });

    testWidgets('submit button is enabled when isLoading is false',
        (tester) async {
      mockAuth.isLoading.value = false;
      await pumpLoginPage(tester, mockAuth);

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('submitButton')),
      );
      expect(button.onPressed, isNotNull,
          reason: 'Button onPressed should not be null when not loading');
    });

    testWidgets('error text is shown when errorMessage is set', (tester) async {
      mockAuth.errorMessage.value = 'Invalid credentials. Please try again.';
      await pumpLoginPage(tester, mockAuth);

      expect(find.byKey(const Key('errorText')), findsOneWidget);
      expect(
        find.text('Invalid credentials. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('error text is hidden when errorMessage is null', (tester) async {
      mockAuth.errorMessage.value = null;
      await pumpLoginPage(tester, mockAuth);

      expect(find.byKey(const Key('errorText')), findsNothing);
    });

    testWidgets('loading spinner shown inside button when isLoading is true',
        (tester) async {
      mockAuth.isLoading.value = true;
      await pumpLoginPage(tester, mockAuth);

      // CircularProgressIndicator should be visible inside the button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // "Sign In" text should not be visible
      expect(find.text('Sign In'), findsNothing);
    });
  });
}
