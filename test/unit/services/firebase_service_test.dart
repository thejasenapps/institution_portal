import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:institution_portal/services/firebase_service.dart';

void main() {
  group('FirebaseService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirebaseService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = FirebaseService(fakeFirestore);
    });

    // -------------------------------------------------------------------------
    // findInstitutionByEmail
    // -------------------------------------------------------------------------
    group('findInstitutionByEmail', () {
      test('returns InstitutionModel when email matches', () async {
        // Seed a document with a lowercase email
        await fakeFirestore.collection('institutions').add({
          'id': 'inst-001',
          'email': 'test@example.com',
          'name': 'Test Institution',
          'logoUrl': null,
          'subscriptionHistory': [],
        });

        final result =
            await service.findInstitutionByEmail('test@example.com');

        expect(result, isNotNull);
        expect(result!.email, equals('test@example.com'));
        expect(result.name, equals('Test Institution'));
        expect(result.id, equals('inst-001'));
      });

      test('is case-insensitive — uppercased input matches lowercase stored email',
          () async {
        await fakeFirestore.collection('institutions').add({
          'id': 'inst-002',
          'email': 'upper@example.com',
          'name': 'Upper Institution',
          'subscriptionHistory': [],
        });

        // FirebaseService lowercases the input before querying
        final result =
            await service.findInstitutionByEmail('UPPER@EXAMPLE.COM');

        expect(result, isNotNull);
        expect(result!.email, equals('upper@example.com'));
      });

      test('returns null when no document matches the email', () async {
        // Collection is empty — no match
        final result =
            await service.findInstitutionByEmail('nobody@example.com');

        expect(result, isNull);
      });

      test('returns null when collection has documents but none match', () async {
        await fakeFirestore.collection('institutions').add({
          'id': 'inst-003',
          'email': 'other@example.com',
          'name': 'Other Institution',
          'subscriptionHistory': [],
        });

        final result =
            await service.findInstitutionByEmail('notfound@example.com');

        expect(result, isNull);
      });
    });

    // -------------------------------------------------------------------------
    // getTopicsForInstitution
    // -------------------------------------------------------------------------
    group('getTopicsForInstitution', () {
      test('returns multiple topics for a given institutionId', () async {
        const institutionId = 'inst-abc';

        await fakeFirestore.collection('topics').add({
          'topicId': 'topic-1',
          'name': 'Flutter Basics',
          'expertId': 'exp-1',
          'sessionId': 'sess-1',
          'institutionId': institutionId,
        });
        await fakeFirestore.collection('topics').add({
          'topicId': 'topic-2',
          'name': 'Dart Advanced',
          'expertId': 'exp-2',
          'sessionId': 'sess-2',
          'institutionId': institutionId,
        });
        // A topic belonging to a different institution — should NOT appear
        await fakeFirestore.collection('topics').add({
          'topicId': 'topic-3',
          'name': 'Other Topic',
          'expertId': 'exp-3',
          'sessionId': 'sess-3',
          'institutionId': 'other-inst',
        });

        final topics =
            await service.getTopicsForInstitution(institutionId);

        expect(topics.length, equals(2));
        final names = topics.map((t) => t.name).toSet();
        expect(names, containsAll(['Flutter Basics', 'Dart Advanced']));
      });

      test('returns empty list when institution has no topics', () async {
        // No documents seeded for this institution
        final topics =
            await service.getTopicsForInstitution('inst-no-topics');

        expect(topics, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // updateInstitutionName
    // -------------------------------------------------------------------------
    group('updateInstitutionName', () {
      test('successfully updates the name field', () async {
        const institutionId = 'inst-upd-name';

        final docRef = await fakeFirestore.collection('institutions').add({
          'id': institutionId,
          'email': 'update@example.com',
          'name': 'Old Name',
          'subscriptionHistory': [],
        });

        await service.updateInstitutionName(institutionId, 'New Name');

        final updated = await docRef.get();
        final data = updated.data() as Map<String, dynamic>;
        expect(data['name'], equals('New Name'));
      });

      test('throws FirebaseServiceException when institution document not found',
          () async {
        // No document with this id exists
        expect(
          () => service.updateInstitutionName('nonexistent-id', 'Any Name'),
          throwsA(isA<FirebaseServiceException>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // updateInstitutionLogoUrl
    // -------------------------------------------------------------------------
    group('updateInstitutionLogoUrl', () {
      test('successfully updates the logoUrl field', () async {
        const institutionId = 'inst-upd-logo';

        final docRef = await fakeFirestore.collection('institutions').add({
          'id': institutionId,
          'email': 'logo@example.com',
          'name': 'Logo Institution',
          'logoUrl': null,
          'subscriptionHistory': [],
        });

        const newLogoUrl = 'https://example.com/logo.png';
        await service.updateInstitutionLogoUrl(institutionId, newLogoUrl);

        final updated = await docRef.get();
        final data = updated.data() as Map<String, dynamic>;
        expect(data['logoUrl'], equals(newLogoUrl));
      });

      test('throws FirebaseServiceException when institution document not found',
          () async {
        expect(
          () => service.updateInstitutionLogoUrl(
              'nonexistent-id', 'https://example.com/logo.png'),
          throwsA(isA<FirebaseServiceException>()),
        );
      });
    });
  });
}
