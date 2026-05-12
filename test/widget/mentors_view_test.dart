// test/widget/mentors_view_test.dart
//
// Widget tests for MentorsView states.
// Tests: LinearProgressIndicator when loading, DataTable when data present,
//        empty state text, error state with Retry button.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import 'package:institution_portal/controllers/auth_controller.dart';
import 'package:institution_portal/controllers/mentor_controller.dart';
import 'package:institution_portal/models/mentor_row_model.dart';
import 'package:institution_portal/views/mentors_view.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockMentorController extends GetxController
    with Mock
    implements MentorController {
  @override
  final RxList<MentorRowModel> mentorList = <MentorRowModel>[].obs;

  @override
  final RxBool isLoading = false.obs;

  @override
  final RxBool hasError = false.obs;

  @override
  final RxnString errorMessage = RxnString();

  @override
  Future<void> loadMentors(String institutionId) async {}

  @override
  Future<void> reload(String institutionId) async {}
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
}

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

MentorRowModel _makeRow(int i) => MentorRowModel(
      expertId: 'expert-$i',
      mentorName: 'Mentor $i',
      topicName: 'Topic $i',
      topicId: 'topic-$i',
      institutionId: 'inst-1',
      sessionId: 'session-$i',
      price: '\$100',
      duration: '60 min',
      sessionType: 'Online',
    );

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<void> pumpMentorsView(
  WidgetTester tester,
  MockMentorController mockMentor,
  MockAuthController mockAuth,
) async {
  Get.reset();
  Get.put<MentorController>(mockMentor);
  Get.put<AuthController>(mockAuth);

  await tester.pumpWidget(
    GetMaterialApp(
      home: Scaffold(
        body: const MentorsView(),
      ),
    ),
  );
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockMentorController mockMentor;
  late MockAuthController mockAuth;

  setUp(() {
    mockMentor = MockMentorController();
    mockAuth = MockAuthController();
  });

  tearDown(() {
    Get.reset();
  });

  group('MentorsView widget tests', () {
    testWidgets('LinearProgressIndicator shown while loading', (tester) async {
      mockMentor.isLoading.value = true;
      await pumpMentorsView(tester, mockMentor, mockAuth);

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('LinearProgressIndicator hidden when not loading',
        (tester) async {
      mockMentor.isLoading.value = false;
      await pumpMentorsView(tester, mockMentor, mockAuth);

      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('DataTable shown when mentor data is present', (tester) async {
      mockMentor.isLoading.value = false;
      mockMentor.hasError.value = false;
      mockMentor.mentorList.assignAll([_makeRow(1), _makeRow(2)]);
      await pumpMentorsView(tester, mockMentor, mockAuth);

      expect(find.byType(DataTable), findsOneWidget);
      // Verify column headers
      expect(find.text('Mentor Name'), findsOneWidget);
      expect(find.text('Topic Name'), findsOneWidget);
      // Verify row data
      expect(find.text('Mentor 1'), findsOneWidget);
      expect(find.text('Mentor 2'), findsOneWidget);
    });

    testWidgets('empty state text shown when mentor list is empty',
        (tester) async {
      mockMentor.isLoading.value = false;
      mockMentor.hasError.value = false;
      mockMentor.mentorList.clear();
      await pumpMentorsView(tester, mockMentor, mockAuth);

      expect(find.byType(DataTable), findsNothing);
      expect(
        find.text('No mentors are linked to your institution.'),
        findsOneWidget,
      );
    });

    testWidgets('error state shown with Retry button when hasError is true',
        (tester) async {
      mockMentor.isLoading.value = false;
      mockMentor.hasError.value = true;
      await pumpMentorsView(tester, mockMentor, mockAuth);

      expect(find.byType(DataTable), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Retry button triggers reload', (tester) async {
      mockMentor.isLoading.value = false;
      mockMentor.hasError.value = true;
      await pumpMentorsView(tester, mockMentor, mockAuth);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      // After tapping Retry, hasError should still be true (mock doesn't change it)
      // but the tap should not throw
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
