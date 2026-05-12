import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:institution_portal/controllers/auth_controller.dart';
import 'package:institution_portal/models/institution_model.dart';
import 'package:institution_portal/services/firebase_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockFirebaseService extends Mock implements FirebaseService {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a minimal [InstitutionModel] for testing.
InstitutionModel _makeInstitution({
  String id = 'inst-123',
  String email = 'test@example.com',
  String name = 'Test Institution',
}) {
  return InstitutionModel(id: id, email: email, name: name);
}

void main() {
  late MockFirebaseService mockFirebaseService;
  late SharedPreferences prefs;

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockFirebaseService = MockFirebaseService();
  });

  tearDown(() {
    Get.reset();
  });

  // -------------------------------------------------------------------------
  // AuthController.login()
  // -------------------------------------------------------------------------

  group('AuthController.login()', () {
    test('success: valid credentials navigate to /shell and persist session',
        () async {
      final institution = _makeInstitution();
      when(() => mockFirebaseService.findInstitutionByEmail(any()))
          .thenAnswer((_) async => institution);

      final controller = AuthController(
        firebaseService: mockFirebaseService,
        prefs: prefs,
      );

      await controller.login('test@example.com', 'inst-123');

      expect(controller.institutionId.value, equals('inst-123'));
      expect(controller.errorMessage.value, isNull);
      expect(prefs.getString('session_institution_id'), equals('inst-123'));
    });

    test('credential mismatch: wrong institution ID sets errorMessage', () async {
      final institution = _makeInstitution(id: 'inst-123');
      when(() => mockFirebaseService.findInstitutionByEmail(any()))
          .thenAnswer((_) async => institution);

      final controller = AuthController(
        firebaseService: mockFirebaseService,
        prefs: prefs,
      );

      await controller.login('test@example.com', 'wrong-id');

      expect(controller.institutionId.value, isEmpty);
      expect(controller.errorMessage.value, isNotNull);
      expect(controller.errorMessage.value,
          contains('Invalid credentials'));
    });

    test('credential mismatch: institution not found sets errorMessage',
        () async {
      when(() => mockFirebaseService.findInstitutionByEmail(any()))
          .thenAnswer((_) async => null);

      final controller = AuthController(
        firebaseService: mockFirebaseService,
        prefs: prefs,
      );

      await controller.login('unknown@example.com', 'inst-123');

      expect(controller.institutionId.value, isEmpty);
      expect(controller.errorMessage.value, isNotNull);
      expect(controller.errorMessage.value, contains('Invalid credentials'));
    });

    test('network error: FirebaseServiceException sets errorMessage', () async {
      when(() => mockFirebaseService.findInstitutionByEmail(any()))
          .thenThrow(const FirebaseServiceException('Network error'));

      final controller = AuthController(
        firebaseService: mockFirebaseService,
        prefs: prefs,
      );

      await controller.login('test@example.com', 'inst-123');

      expect(controller.institutionId.value, isEmpty);
      expect(controller.errorMessage.value, isNotNull);
      expect(controller.errorMessage.value,
          contains('Authentication failed'));
    });

    test('isLoading is false after login completes', () async {
      when(() => mockFirebaseService.findInstitutionByEmail(any()))
          .thenAnswer((_) async => _makeInstitution());

      final controller = AuthController(
        firebaseService: mockFirebaseService,
        prefs: prefs,
      );

      await controller.login('test@example.com', 'inst-123');

      expect(controller.isLoading.value, isFalse);
    });

    test('invalid email format sets errorMessage without calling Firebase',
        () async {
      final controller = AuthController(
        firebaseService: mockFirebaseService,
        prefs: prefs,
      );

      await controller.login('not-an-email', 'inst-123');

      expect(controller.errorMessage.value, isNotNull);
      verifyNever(() => mockFirebaseService.findInstitutionByEmail(any()));
    });
  });

  // -------------------------------------------------------------------------
  // AuthController.restoreSession()
  // -------------------------------------------------------------------------

  group('AuthController.restoreSession()', () {
    test('session present: restores institutionId from SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues(
          {'session_institution_id': 'stored-inst'});
      prefs = await SharedPreferences.getInstance();

      final controller = AuthController(
        firebaseService: mockFirebaseService,
        prefs: prefs,
      );

      // onInit calls restoreSession automatically, but call explicitly too
      await controller.restoreSession();

      expect(controller.institutionId.value, equals('stored-inst'));
    });

    test('session absent: institutionId remains empty', () async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      final controller = AuthController(
        firebaseService: mockFirebaseService,
        prefs: prefs,
      );

      await controller.restoreSession();

      expect(controller.institutionId.value, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // AuthController.logout()
  // -------------------------------------------------------------------------

  group('AuthController.logout()', () {
    test('clears institutionId and removes SharedPreferences key', () async {
      SharedPreferences.setMockInitialValues(
          {'session_institution_id': 'inst-123'});
      prefs = await SharedPreferences.getInstance();

      final controller = AuthController(
        firebaseService: mockFirebaseService,
        prefs: prefs,
      );
      controller.institutionId.value = 'inst-123';

      await controller.logout();

      expect(controller.institutionId.value, isEmpty);
      expect(prefs.getString('session_institution_id'), isNull);
    });

    test('isAuthenticated returns false after logout', () async {
      SharedPreferences.setMockInitialValues(
          {'session_institution_id': 'inst-123'});
      prefs = await SharedPreferences.getInstance();

      final controller = AuthController(
        firebaseService: mockFirebaseService,
        prefs: prefs,
      );
      controller.institutionId.value = 'inst-123';

      await controller.logout();

      expect(controller.isAuthenticated, isFalse);
    });
  });
}
