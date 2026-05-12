// test/integration/firestore_integration_test.dart
//
// Integration tests for FirebaseService and MentorController using
// fake_cloud_firestore to simulate Firestore without a real emulator.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:institution_portal/controllers/mentor_controller.dart';
import 'package:institution_portal/models/expert_model.dart';
import 'package:institution_portal/models/institution_model.dart';
import 'package:institution_portal/models/session_model.dart';
import 'package:institution_portal/models/topic_model.dart';
import 'package:institution_portal/services/firebase_service.dart';

void main() {
  group('Firestore Integration — MentorController end-to-end', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirebaseService firebaseService;
    late MentorController mentorController;

    const String institutionId = 'inst-001';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      firebaseService = FirebaseService(fakeFirestore);
      mentorController =
          MentorController(firebaseService: firebaseService);
    });

    tearDown(() {
      Get.reset();
    });

    /// Seeds Firestore with topics, experts, and sessions for [institutionId].
    Future<void> _seedData({
      required List<Map<String, dynamic>> topics,
      required List<Map<String, dynamic>> experts,
      required List<Map<String, dynamic>> sessions,
    }) async {
      for (final topic in topics) {
        await fakeFirestore.collection('topics').add(topic);
      }
      for (final expert in experts) {
        await fakeFirestore
            .collection('experts')
            .doc(expert['expertId'] as String)
            .set(expert);
      }
      for (final session in sessions) {
        await fakeFirestore
            .collection('sessions')
            .doc(session['sessionId'] as String)
            .set(session);
      }
    }

    test(
        'loadMentors builds correct MentorRow list from seeded topics, experts, and sessions',
        () async {
      await _seedData(
        topics: [
          {
            'topicId': 'topic-1',
            'name': 'Flutter Development',
            'expertId': 'expert-1',
            'sessionId': 'session-1',
            'institutionId': institutionId,
          },
          {
            'topicId': 'topic-2',
            'name': 'Dart Basics',
            'expertId': 'expert-2',
            'sessionId': 'session-2',
            'institutionId': institutionId,
          },
        ],
        experts: [
          {
            'expertId': 'expert-1',
            'name': 'Alice Smith',
            'bio': 'Flutter expert',
          },
          {
            'expertId': 'expert-2',
            'name': 'Bob Jones',
            'bio': 'Dart specialist',
          },
        ],
        sessions: [
          {
            'sessionId': 'session-1',
            'price': '100',
            'duration': '60',
            'sessionType': 'online',
          },
          {
            'sessionId': 'session-2',
            'price': '80',
            'duration': '45',
            'sessionType': 'in-person',
          },
        ],
      );

      await mentorController.loadMentors(institutionId);

      expect(mentorController.isLoading.value, isFalse);
      expect(mentorController.hasError.value, isFalse);
      expect(mentorController.mentorList.length, equals(2));

      // Verify first row (order may vary — find by expertId)
      final row1 = mentorController.mentorList
          .firstWhere((r) => r.expertId == 'expert-1');
      expect(row1.mentorName, equals('Alice Smith'));
      expect(row1.topicName, equals('Flutter Development'));
      expect(row1.price, equals('100'));
      expect(row1.duration, equals('60'));
      expect(row1.sessionType, equals('online'));
      expect(row1.institutionId, equals(institutionId));

      // Verify second row
      final row2 = mentorController.mentorList
          .firstWhere((r) => r.expertId == 'expert-2');
      expect(row2.mentorName, equals('Bob Jones'));
      expect(row2.topicName, equals('Dart Basics'));
      expect(row2.price, equals('80'));
      expect(row2.duration, equals('45'));
      expect(row2.sessionType, equals('in-person'));
    });

    test(
        'loadMentors sets price/duration/sessionType to "Unknown" when sessionId is empty',
        () async {
      await _seedData(
        topics: [
          {
            'topicId': 'topic-3',
            'name': 'No Session Topic',
            'expertId': 'expert-3',
            'sessionId': '', // empty — no session
            'institutionId': institutionId,
          },
        ],
        experts: [
          {
            'expertId': 'expert-3',
            'name': 'Carol White',
          },
        ],
        sessions: [],
      );

      await mentorController.loadMentors(institutionId);

      expect(mentorController.mentorList.length, equals(1));
      final row = mentorController.mentorList.first;
      expect(row.price, equals('Unknown'));
      expect(row.duration, equals('Unknown'));
      expect(row.sessionType, equals('Unknown'));
    });

    test('loadMentors returns empty list when no topics exist for institution',
        () async {
      // No data seeded for this institution
      await mentorController.loadMentors('nonexistent-inst');

      expect(mentorController.mentorList, isEmpty);
      expect(mentorController.hasError.value, isFalse);
    });
  });

  group('Firestore Integration — updateInstitutionName', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirebaseService firebaseService;

    const String institutionId = 'inst-write-001';

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      firebaseService = FirebaseService(fakeFirestore);

      // Seed an institution document
      await fakeFirestore.collection('institutions').add({
        'id': institutionId,
        'email': 'test@example.com',
        'name': 'Original Name',
        'logoUrl': 'https://example.com/logo.png',
      });
    });

    test('updateInstitutionName writes only the name field', () async {
      await firebaseService.updateInstitutionName(institutionId, 'New Name');

      // Read back the document
      final snapshot = await fakeFirestore
          .collection('institutions')
          .where('id', isEqualTo: institutionId)
          .limit(1)
          .get();

      expect(snapshot.docs, isNotEmpty);
      final data = snapshot.docs.first.data();

      // Name should be updated
      expect(data['name'], equals('New Name'));

      // Other fields should remain unchanged
      expect(data['email'], equals('test@example.com'));
      expect(data['logoUrl'], equals('https://example.com/logo.png'));
      expect(data['id'], equals(institutionId));
    });

    test('updateInstitutionName can be read back via getInstitution', () async {
      await firebaseService.updateInstitutionName(institutionId, 'Updated Name');

      final institution = await firebaseService.getInstitution(institutionId);

      expect(institution, isNotNull);
      expect(institution!.name, equals('Updated Name'));
    });

    test(
        'updateInstitutionName throws FirebaseServiceException for unknown institutionId',
        () async {
      expect(
        () => firebaseService.updateInstitutionName('unknown-id', 'Name'),
        throwsA(isA<FirebaseServiceException>()),
      );
    });
  });

  group('Firestore Integration — updateInstitutionLogoUrl', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirebaseService firebaseService;

    const String institutionId = 'inst-logo-001';

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      firebaseService = FirebaseService(fakeFirestore);

      // Seed an institution document
      await fakeFirestore.collection('institutions').add({
        'id': institutionId,
        'email': 'logo@example.com',
        'name': 'Logo Test Institution',
        'logoUrl': 'https://example.com/old-logo.png',
      });
    });

    test('updateInstitutionLogoUrl writes only the logoUrl field', () async {
      const newLogoUrl = 'https://res.cloudinary.com/demo/image/upload/new.jpg';
      await firebaseService.updateInstitutionLogoUrl(
          institutionId, newLogoUrl);

      // Read back the document
      final snapshot = await fakeFirestore
          .collection('institutions')
          .where('id', isEqualTo: institutionId)
          .limit(1)
          .get();

      expect(snapshot.docs, isNotEmpty);
      final data = snapshot.docs.first.data();

      // logoUrl should be updated
      expect(data['logoUrl'], equals(newLogoUrl));

      // Other fields should remain unchanged
      expect(data['name'], equals('Logo Test Institution'));
      expect(data['email'], equals('logo@example.com'));
      expect(data['id'], equals(institutionId));
    });

    test('updateInstitutionLogoUrl can be read back via getInstitution',
        () async {
      const newLogoUrl = 'https://res.cloudinary.com/demo/image/upload/new.jpg';
      await firebaseService.updateInstitutionLogoUrl(
          institutionId, newLogoUrl);

      final institution = await firebaseService.getInstitution(institutionId);

      expect(institution, isNotNull);
      expect(institution!.logoUrl, equals(newLogoUrl));
    });

    test(
        'updateInstitutionLogoUrl throws FirebaseServiceException for unknown institutionId',
        () async {
      expect(
        () => firebaseService.updateInstitutionLogoUrl(
            'unknown-id', 'https://example.com/logo.png'),
        throwsA(isA<FirebaseServiceException>()),
      );
    });
  });

  group('Firestore Integration — model round-trips', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirebaseService firebaseService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      firebaseService = FirebaseService(fakeFirestore);
    });

    test('TopicModel.fromFirestore round-trip', () async {
      await fakeFirestore.collection('topics').doc('t1').set({
        'topicId': 't1',
        'name': 'Test Topic',
        'expertId': 'e1',
        'sessionId': 's1',
        'institutionId': 'inst-1',
        'skillType': 'technical',
      });

      final doc =
          await fakeFirestore.collection('topics').doc('t1').get();
      final topic = TopicModel.fromFirestore(doc);

      expect(topic.topicId, equals('t1'));
      expect(topic.name, equals('Test Topic'));
      expect(topic.expertId, equals('e1'));
      expect(topic.sessionId, equals('s1'));
      expect(topic.institutionId, equals('inst-1'));
      expect(topic.skillType, equals('technical'));
    });

    test('ExpertModel.fromFirestore round-trip', () async {
      await fakeFirestore.collection('experts').doc('e1').set({
        'expertId': 'e1',
        'name': 'Expert Name',
        'bio': 'Expert bio text',
        'profileImageUrl': 'https://example.com/photo.jpg',
      });

      final doc =
          await fakeFirestore.collection('experts').doc('e1').get();
      final expert = ExpertModel.fromFirestore(doc);

      expect(expert.expertId, equals('e1'));
      expect(expert.name, equals('Expert Name'));
      expect(expert.bio, equals('Expert bio text'));
      expect(expert.profileImageUrl, equals('https://example.com/photo.jpg'));
    });

    test('SessionModel.fromFirestore round-trip', () async {
      await fakeFirestore.collection('sessions').doc('s1').set({
        'sessionId': 's1',
        'price': '150',
        'duration': '90',
        'sessionType': 'group',
      });

      final doc =
          await fakeFirestore.collection('sessions').doc('s1').get();
      final session = SessionModel.fromFirestore(doc);

      expect(session.sessionId, equals('s1'));
      expect(session.price, equals('150'));
      expect(session.duration, equals('90'));
      expect(session.sessionType, equals('group'));
    });

    test('InstitutionModel.fromFirestore round-trip', () async {
      await fakeFirestore.collection('institutions').doc('inst-doc').set({
        'id': 'inst-rt-001',
        'email': 'rt@example.com',
        'name': 'Round Trip Institution',
        'logoUrl': 'https://example.com/logo.png',
        'plan': 'premium',
      });

      final doc = await fakeFirestore
          .collection('institutions')
          .doc('inst-doc')
          .get();
      final institution = InstitutionModel.fromFirestore(doc);

      expect(institution.id, equals('inst-rt-001'));
      expect(institution.email, equals('rt@example.com'));
      expect(institution.name, equals('Round Trip Institution'));
      expect(institution.logoUrl, equals('https://example.com/logo.png'));
      expect(institution.plan, equals('premium'));
    });
  });
}
