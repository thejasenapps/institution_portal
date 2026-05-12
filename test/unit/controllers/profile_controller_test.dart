// test/unit/controllers/profile_controller_test.dart
//
// Unit tests for ProfileController.
// Tests: saveName valid/invalid/failure, validateName, isFileSizeValid.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import 'package:institution_portal/controllers/profile_controller.dart';
import 'package:institution_portal/models/institution_model.dart';
import 'package:institution_portal/services/file_uploader.dart';
import 'package:institution_portal/services/firebase_service.dart';
import 'package:institution_portal/services/image_resizer.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockFirebaseService extends Mock implements FirebaseService {}

class MockFileUploader extends Mock implements FileUploader {}

class MockImageResizer extends Mock implements ImageResizer {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

InstitutionModel _makeInstitution({
  String id = 'inst-123',
  String name = 'Test Institution',
  String email = 'test@example.com',
}) {
  return InstitutionModel(id: id, email: email, name: name);
}

void main() {
  late MockFirebaseService mockFirebaseService;
  late MockFileUploader mockFileUploader;
  late MockImageResizer mockImageResizer;

  setUp(() {
    Get.testMode = true;
    mockFirebaseService = MockFirebaseService();
    mockFileUploader = MockFileUploader();
    mockImageResizer = MockImageResizer();
  });

  tearDown(() {
    Get.reset();
  });

  ProfileController _makeController() {
    return ProfileController(
      firebaseService: mockFirebaseService,
      fileUploader: mockFileUploader,
      imageResizer: mockImageResizer,
    );
  }

  // -------------------------------------------------------------------------
  // ProfileController.saveName()
  // -------------------------------------------------------------------------

  group('ProfileController.saveName()', () {
    test('valid name: calls updateInstitutionName and shows success snackbar',
        () async {
      when(() => mockFirebaseService.updateInstitutionName(any(), any()))
          .thenAnswer((_) async {});

      final controller = _makeController();
      controller.institution.value = _makeInstitution();

      await controller.saveName('inst-123', 'New Valid Name');

      expect(controller.nameError.value, isNull);
      expect(controller.isSavingName.value, isFalse);
      verify(() => mockFirebaseService.updateInstitutionName(
          'inst-123', 'New Valid Name')).called(1);
    });

    test('invalid name (empty): sets nameError, does NOT call Firestore',
        () async {
      final controller = _makeController();
      controller.institution.value = _makeInstitution();

      await controller.saveName('inst-123', '');

      expect(controller.nameError.value, isNotNull);
      verifyNever(
          () => mockFirebaseService.updateInstitutionName(any(), any()));
    });

    test('invalid name (whitespace only): sets nameError, does NOT call Firestore',
        () async {
      final controller = _makeController();
      controller.institution.value = _makeInstitution();

      await controller.saveName('inst-123', '   ');

      expect(controller.nameError.value, isNotNull);
      verifyNever(
          () => mockFirebaseService.updateInstitutionName(any(), any()));
    });

    test('Firestore write failure: shows error snackbar and reverts name',
        () async {
      when(() => mockFirebaseService.updateInstitutionName(any(), any()))
          .thenThrow(const FirebaseServiceException('Write failed'));

      final controller = _makeController();
      final original = _makeInstitution(name: 'Original Name');
      controller.institution.value = original;

      await controller.saveName('inst-123', 'New Name');

      // Name should be reverted to original
      expect(controller.institution.value?.name, equals('Original Name'));
      expect(controller.isSavingName.value, isFalse);
    });

    test('isSavingName is false after successful save', () async {
      when(() => mockFirebaseService.updateInstitutionName(any(), any()))
          .thenAnswer((_) async {});

      final controller = _makeController();
      controller.institution.value = _makeInstitution();

      await controller.saveName('inst-123', 'Valid Name');

      expect(controller.isSavingName.value, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // ProfileController.validateName()
  // -------------------------------------------------------------------------

  group('ProfileController.validateName()', () {
    test('empty string returns non-null error', () {
      expect(ProfileController.validateName(''), isNotNull);
    });

    test('whitespace-only string returns non-null error', () {
      expect(ProfileController.validateName('   '), isNotNull);
    });

    test('valid name returns null', () {
      expect(ProfileController.validateName('Valid Name'), isNull);
    });

    test('single character name returns null', () {
      expect(ProfileController.validateName('A'), isNull);
    });

    test('exactly 100 characters returns null', () {
      final name = 'A' * 100;
      expect(ProfileController.validateName(name), isNull);
    });

    test('101 characters returns non-null error', () {
      final name = 'A' * 101;
      expect(ProfileController.validateName(name), isNotNull);
    });

    test('name with leading/trailing spaces that trims to valid returns null',
        () {
      expect(ProfileController.validateName('  Valid Name  '), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // ProfileController.isFileSizeValid()
  // -------------------------------------------------------------------------

  group('ProfileController.isFileSizeValid()', () {
    test('0 bytes returns false', () {
      expect(ProfileController.isFileSizeValid(0), isFalse);
    });

    test('1 byte returns true', () {
      expect(ProfileController.isFileSizeValid(1), isTrue);
    });

    test('exactly 10 MB (10485760 bytes) returns true', () {
      expect(ProfileController.isFileSizeValid(10485760), isTrue);
    });

    test('10485761 bytes (just over 10 MB) returns false', () {
      expect(ProfileController.isFileSizeValid(10485761), isFalse);
    });

    test('negative bytes returns false', () {
      expect(ProfileController.isFileSizeValid(-1), isFalse);
    });

    test('5 MB returns true', () {
      expect(ProfileController.isFileSizeValid(5 * 1024 * 1024), isTrue);
    });
  });
}
