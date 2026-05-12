import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import 'package:institution_portal/controllers/mentor_controller.dart';
import 'package:institution_portal/models/expert_model.dart';
import 'package:institution_portal/models/session_model.dart';
import 'package:institution_portal/models/topic_model.dart';
import 'package:institution_portal/services/firebase_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockFirebaseService extends Mock implements FirebaseService {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

TopicModel _makeTopic({
  String topicId = 'topic-1',
  String name = 'Flutter Basics',
  String expertId = 'expert-1',
  String sessionId = 'session-1',
  String institutionId = 'inst-123',
}) {
  return TopicModel(
    topicId: topicId,
    name: name,
    expertId: expertId,
    sessionId: sessionId,
    institutionId: institutionId,
  );
}

ExpertModel _makeExpert({
  String expertId = 'expert-1',
  String name = 'Jane Doe',
}) {
  return ExpertModel(expertId: expertId, name: name);
}

SessionModel _makeSession({
  String sessionId = 'session-1',
  String price = '100',
  String duration = '60',
  String sessionType = 'online',
}) {
  return SessionModel(
    sessionId: sessionId,
    price: price,
    duration: duration,
    sessionType: sessionType,
  );
}

void main() {
  late MockFirebaseService mockFirebaseService;

  setUp(() {
    Get.testMode = true;
    mockFirebaseService = MockFirebaseService();
  });

  tearDown(() {
    Get.reset();
  });

  // -------------------------------------------------------------------------
  // MentorController.loadMentors()
  // -------------------------------------------------------------------------

  group('MentorController.loadMentors()', () {
    test('success: builds mentorList from topics, experts, and sessions',
        () async {
      final topic = _makeTopic();
      final expert = _makeExpert();
      final session = _makeSession();

      when(() => mockFirebaseService.getTopicsForInstitution(any()))
          .thenAnswer((_) async => [topic]);
      when(() => mockFirebaseService.getExpert('expert-1'))
          .thenAnswer((_) async => expert);
      when(() => mockFirebaseService.getSession('session-1'))
          .thenAnswer((_) async => session);

      final controller =
          MentorController(firebaseService: mockFirebaseService);
      await controller.loadMentors('inst-123');

      expect(controller.mentorList.length, equals(1));
      expect(controller.mentorList.first.mentorName, equals('Jane Doe'));
      expect(controller.mentorList.first.topicName, equals('Flutter Basics'));
      expect(controller.mentorList.first.price, equals('100'));
      expect(controller.mentorList.first.duration, equals('60'));
      expect(controller.mentorList.first.sessionType, equals('online'));
      expect(controller.hasError.value, isFalse);
      expect(controller.isLoading.value, isFalse);
    });

    test('empty topics: mentorList is empty, no error', () async {
      when(() => mockFirebaseService.getTopicsForInstitution(any()))
          .thenAnswer((_) async => []);

      final controller =
          MentorController(firebaseService: mockFirebaseService);
      await controller.loadMentors('inst-123');

      expect(controller.mentorList, isEmpty);
      expect(controller.hasError.value, isFalse);
      expect(controller.isLoading.value, isFalse);
    });

    test('total failure: topics query throws FirebaseServiceException sets hasError',
        () async {
      when(() => mockFirebaseService.getTopicsForInstitution(any()))
          .thenThrow(const FirebaseServiceException('Firestore error'));

      final controller =
          MentorController(firebaseService: mockFirebaseService);
      await controller.loadMentors('inst-123');

      expect(controller.hasError.value, isTrue);
      expect(controller.errorMessage.value, isNotNull);
      expect(controller.mentorList, isEmpty);
      expect(controller.isLoading.value, isFalse);
    });

    test('total failure: unexpected exception sets hasError', () async {
      when(() => mockFirebaseService.getTopicsForInstitution(any()))
          .thenThrow(Exception('Unexpected'));

      final controller =
          MentorController(firebaseService: mockFirebaseService);
      await controller.loadMentors('inst-123');

      expect(controller.hasError.value, isTrue);
      expect(controller.errorMessage.value, isNotNull);
      expect(controller.isLoading.value, isFalse);
    });

    test(
        'partial failure: expert read fails — row excluded, other rows retained',
        () async {
      final topic1 = _makeTopic(topicId: 'topic-1', expertId: 'expert-1');
      final topic2 = _makeTopic(
          topicId: 'topic-2',
          expertId: 'expert-2',
          sessionId: 'session-2',
          name: 'Advanced Dart');
      final expert2 = _makeExpert(expertId: 'expert-2', name: 'John Smith');
      final session2 = _makeSession(sessionId: 'session-2');

      when(() => mockFirebaseService.getTopicsForInstitution(any()))
          .thenAnswer((_) async => [topic1, topic2]);
      // expert-1 returns null → row excluded
      when(() => mockFirebaseService.getExpert('expert-1'))
          .thenAnswer((_) async => null);
      when(() => mockFirebaseService.getSession('session-1'))
          .thenAnswer((_) async => _makeSession());
      when(() => mockFirebaseService.getExpert('expert-2'))
          .thenAnswer((_) async => expert2);
      when(() => mockFirebaseService.getSession('session-2'))
          .thenAnswer((_) async => session2);

      final controller =
          MentorController(firebaseService: mockFirebaseService);
      await controller.loadMentors('inst-123');

      // Only the row with expert-2 should be present
      expect(controller.mentorList.length, equals(1));
      expect(controller.mentorList.first.mentorName, equals('John Smith'));
      expect(controller.hasError.value, isFalse);
    });

    test('topic with empty sessionId: price/duration/sessionType are "Unknown"',
        () async {
      final topic = _makeTopic(sessionId: '');
      final expert = _makeExpert();

      when(() => mockFirebaseService.getTopicsForInstitution(any()))
          .thenAnswer((_) async => [topic]);
      when(() => mockFirebaseService.getExpert('expert-1'))
          .thenAnswer((_) async => expert);

      final controller =
          MentorController(firebaseService: mockFirebaseService);
      await controller.loadMentors('inst-123');

      expect(controller.mentorList.length, equals(1));
      expect(controller.mentorList.first.price, equals('Unknown'));
      expect(controller.mentorList.first.duration, equals('Unknown'));
      expect(controller.mentorList.first.sessionType, equals('Unknown'));
    });

    test('session read fails: price/duration/sessionType fall back to "Unknown"',
        () async {
      final topic = _makeTopic();
      final expert = _makeExpert();

      when(() => mockFirebaseService.getTopicsForInstitution(any()))
          .thenAnswer((_) async => [topic]);
      when(() => mockFirebaseService.getExpert('expert-1'))
          .thenAnswer((_) async => expert);
      when(() => mockFirebaseService.getSession('session-1'))
          .thenThrow(const FirebaseServiceException('Session read failed'));

      final controller =
          MentorController(firebaseService: mockFirebaseService);
      await controller.loadMentors('inst-123');

      expect(controller.mentorList.length, equals(1));
      expect(controller.mentorList.first.price, equals('Unknown'));
      expect(controller.mentorList.first.duration, equals('Unknown'));
      expect(controller.mentorList.first.sessionType, equals('Unknown'));
    });
  });
}
