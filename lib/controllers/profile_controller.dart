import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import '../models/institution_model.dart';
import '../services/file_uploader.dart';
import '../services/firebase_service.dart';
import '../services/image_resizer.dart';
import '../utils/error_messages.dart';

/// Controller responsible for loading institution profile data and performing
/// the two allowed Firestore writes: updating the institution name and logo URL.
///
/// Depends on [FirebaseService], [FileUploader], and [ImageResizer].
class ProfileController extends GetxController {
  // ---------------------------------------------------------------------------
  // Observables
  // ---------------------------------------------------------------------------

  /// The currently loaded institution. Null until [loadInstitution] completes.
  final Rxn<InstitutionModel> institution = Rxn<InstitutionModel>();

  /// True while a logo upload is in progress.
  final RxBool isUploadingLogo = false.obs;

  /// True while a name save operation is in progress.
  final RxBool isSavingName = false.obs;

  /// Holds the current name validation error, or null when the name is valid.
  final RxnString nameError = RxnString();

  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  final FirebaseService _firebaseService;
  final FileUploader _fileUploader;
  final ImageResizer _imageResizer;

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  ProfileController({
    required FirebaseService firebaseService,
    required FileUploader fileUploader,
    required ImageResizer imageResizer,
  }) : _firebaseService = firebaseService,
       _fileUploader = fileUploader,
       _imageResizer = imageResizer;

  // ---------------------------------------------------------------------------
  // Public methods
  // ---------------------------------------------------------------------------

  /// Fetches the institution document for [institutionId] from Firestore and
  /// stores it in [institution].
  ///
  /// Shows a SnackBar on failure.
  Future<void> loadInstitution(String institutionId) async {
    try {
      final result = await _firebaseService.getInstitution(institutionId);
      institution.value = result;
    } catch (e) {
      _showErrorSnackBar('Failed to load institution data. Please try again.');
    }
  }

  /// Validates [newName] via [validateName], then writes it to Firestore via
  /// [FirebaseService.updateInstitutionName].
  ///
  /// - Sets [nameError] if validation fails and returns early.
  /// - Sets [isSavingName] to true while the write is in progress.
  /// - Shows a success SnackBar on success and updates [institution] in memory.
  /// - Shows an error SnackBar and reverts the displayed name on failure.
  Future<void> saveName(String institutionId, String newName) async {
    // Validate first
    final error = validateName(newName);
    if (error != null) {
      nameError.value = error;
      return;
    }
    nameError.value = null;

    isSavingName.value = true;
    final previousInstitution = institution.value;
    try {
      await _firebaseService.updateInstitutionName(
        institutionId,
        newName.trim(),
      );

      // Update the in-memory model to reflect the saved name.
      // All fields are preserved so computed getters remain correct.
      if (institution.value != null) {
        final prev = institution.value!;
        institution.value = InstitutionModel(
          id: prev.id,
          email: prev.email,
          domainUrl: prev.domainUrl,
          name: newName.trim(),
          logo: prev.logo,
          subscriptionStatus: prev.subscriptionStatus,
          subscriptionStartDate: prev.subscriptionStartDate,
          subscriptionEndDate: prev.subscriptionEndDate,
          subscriptionAmount: prev.subscriptionAmount,
          subscriptionHistory: prev.subscriptionHistory,
          trialLimit: prev.trialLimit,
          origin: prev.origin,
          registeredAt: prev.registeredAt,
        );
      }

      Get.snackbar(
        'Success',
        SuccessMessages.nameUpdated,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      // Revert to previous value on failure
      institution.value = previousInstitution;
      _showErrorSnackBar(
        'Failed to update institution name. Please try again.',
      );
    } finally {
      isSavingName.value = false;
    }
  }

  /// Opens a browser file picker restricted to JPEG and PNG files, validates
  /// the selected file's size, resizes and encodes it via [ImageResizer], uploads
  /// it via [FileUploader], then writes the resulting URL to Firestore via
  /// [FirebaseService.updateInstitutionLogoUrl].
  ///
  /// - Shows a SnackBar if the file exceeds 10 MB.
  /// - Sets [isUploadingLogo] to true while the upload is in progress.
  /// - Shows a SnackBar on any error.
  Future<void> pickAndUploadLogo(String institutionId) async {
    // Open file picker via ImagePickerPlugin.
    // We use getImageFromSource (accepts image/*) and then validate the
    // extension to enforce JPEG/PNG-only restriction.
    isUploadingLogo.value = true;
    final picker = ImagePickerPlugin();
    final XFile? pickedFile = await picker.getImageFromSource(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) {
      // User cancelled the picker.
      return;
    }

    // Validate that the selected file is JPEG or PNG.
    final name = pickedFile.name.toLowerCase();
    if (!name.endsWith('.jpg') &&
        !name.endsWith('.jpeg') &&
        !name.endsWith('.png')) {
      _showErrorSnackBar('Only JPEG and PNG images are supported.');
      return;
    }

    // Read the file bytes
    final Uint8List bytes;
    try {
      bytes = await pickedFile.readAsBytes();
    } catch (e) {
      _showErrorSnackBar('Failed to read the selected file. Please try again.');
      return;
    }

    // Validate file size
    if (!isFileSizeValid(bytes.length)) {
      Get.snackbar(
        'File Too Large',
        ProfileErrors.imageTooLarge,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      // Resize and encode the image
      final resizedBytes = await _imageResizer.resizeAndEncode(bytes);

      // Upload to Cloudinary via FileUploader
      final filename =
          'logo_${institutionId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final uploadResult = await _fileUploader.uploadFile(
        resizedBytes,
        filename,
      );

      final logoUrl = uploadResult['media-url'] as String?;
      if (logoUrl == null || logoUrl.isEmpty) {
        _showErrorSnackBar(
          'Upload succeeded but no URL was returned. Please try again.',
        );
        return;
      }

      // Write the URL to Firestore
      await _firebaseService.updateInstitutionLogoUrl(institutionId, logoUrl);

      // Update the in-memory model immediately.
      // All fields are preserved so computed getters remain correct.
      if (institution.value != null) {
        final prev = institution.value!;
        institution.value = InstitutionModel(
          id: prev.id,
          email: prev.email,
          domainUrl: prev.domainUrl,
          name: prev.name,
          logo: logoUrl,
          subscriptionStatus: prev.subscriptionStatus,
          subscriptionStartDate: prev.subscriptionStartDate,
          subscriptionEndDate: prev.subscriptionEndDate,
          subscriptionAmount: prev.subscriptionAmount,
          subscriptionHistory: prev.subscriptionHistory,
          trialLimit: prev.trialLimit,
          origin: prev.origin,
          registeredAt: prev.registeredAt,
        );
      }

      Get.snackbar(
        'Success',
        'Institution logo updated.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _showErrorSnackBar('Failed to upload logo. Please try again.');
    } finally {
      isUploadingLogo.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Static validation helpers
  // ---------------------------------------------------------------------------

  /// Returns `null` if [name] trimmed is between 1 and 100 characters inclusive.
  /// Returns a non-null error string otherwise.
  static String? validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Name cannot be empty.';
    if (trimmed.length > 100) return 'Name must be 100 characters or fewer.';
    return null;
  }

  /// Returns `true` if [bytes] is greater than 0 and at most 10 MB
  /// (10 × 1024 × 1024 = 10,485,760 bytes).
  static bool isFileSizeValid(int bytes) {
    return bytes > 0 && bytes <= 10 * 1024 * 1024;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _showErrorSnackBar(String message) {
    Get.snackbar('Error', message, snackPosition: SnackPosition.BOTTOM);
  }
}
