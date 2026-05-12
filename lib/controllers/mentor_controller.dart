// lib/controllers/mentor_controller.dart

import 'package:get/get.dart';

import '../models/mentor_row_model.dart';
import '../models/topic_model.dart';
import '../models/expert_model.dart';
import '../models/session_model.dart';
import '../services/firebase_service.dart';
import '../utils/error_messages.dart';

/// Controls the loading and exposure of mentor data for the Institution Portal.
///
/// Queries Firestore topics for the authenticated institution, then fans out
/// parallel expert/session reads to build [MentorRowModel] objects.
///
/// Registered via [MentorBinding] when the `/shell/mentors` route is accessed.
class MentorController extends GetxController {
  // ---------------------------------------------------------------------------
  // Observables
  // ---------------------------------------------------------------------------

  /// The list of mentor rows built from topics + experts + sessions.
  final RxList<MentorRowModel> mentorList = <MentorRowModel>[].obs;

  /// Whether a load operation is currently in progress.
  final RxBool isLoading = false.obs;

  /// Whether the most recent topics query failed entirely.
  final RxBool hasError = false.obs;

  /// The error message from the most recent total failure, or `null`.
  final RxnString errorMessage = RxnString();

  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  final FirebaseService _firebaseService;

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  MentorController({required FirebaseService firebaseService})
    : _firebaseService = firebaseService;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Loads mentor data for [institutionId].
  ///
  /// 1. Queries the `topics` collection for all documents where
  ///    `institutionId` equals [institutionId].
  /// 2. For each topic, performs parallel reads of the expert and (if
  ///    `sessionId` is non-empty) the session document.
  /// 3. Builds a [MentorRowModel] per topic:
  ///    - If the session read was skipped or failed, `price`, `duration`, and
  ///      `sessionType` are set to `"Unknown"`.
  ///    - If the expert read fails, the row is excluded and a SnackBar is shown.
  /// 4. On total topics query failure, sets [hasError] = `true`.
  Future<void> loadMentors(String institutionId) async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = null;

    List<TopicModel> topics;

    try {
      topics = await _firebaseService.getTopicsForInstitution(institutionId);
    } on FirebaseServiceException catch (e) {
      hasError.value = true;
      errorMessage.value =
          'Failed to load mentor data. Please check your connection and try again.';
      isLoading.value = false;
      // Log for debugging — not shown to user
      // ignore: avoid_print
      print('MentorController: topics query failed: $e');
      return;
    } catch (e) {
      hasError.value = true;
      errorMessage.value =
          'An unexpected error occurred while loading mentor data.';
      isLoading.value = false;
      // ignore: avoid_print
      print('MentorController: unexpected error during topics query: $e');
      return;
    }

    // Fan out parallel expert + session reads for each topic.
    bool hadPartialFailure = false;
    final List<MentorRowModel> rows = [];

    // Process all topics in parallel using Future.wait.
    final futures = topics.map((topic) => _buildMentorRow(topic));
    final results = await Future.wait(
      futures.map(
        (f) => f.then<MentorRowModel?>((row) => row).catchError((Object e) {
          hadPartialFailure = true;
          // ignore: avoid_print
          print('MentorController: failed to build row for topic: $e');
          return null;
        }),
      ),
    );

    for (final row in results) {
      if (row != null) {
        rows.add(row);
      }
    }

    mentorList.assignAll(rows);

    if (hadPartialFailure) {
      Get.snackbar(
        'Warning',
        MentorErrors.partialLoadFailure,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }

    isLoading.value = false;
  }

  /// Clears [mentorList] and re-runs [loadMentors] for [institutionId].
  Future<void> reload(String institutionId) async {
    mentorList.clear();
    await loadMentors(institutionId);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Builds a [MentorRowModel] for [topic] by reading the expert and (if
  /// applicable) the session document in parallel.
  ///
  /// Throws if the expert read fails (caller handles exclusion).
  /// Session failures are caught internally and result in `"Unknown"` values.
  Future<MentorRowModel> _buildMentorRow(TopicModel topic) async {
    // Determine whether to fetch the session.
    final bool hasSession = topic.sessionId.isNotEmpty;

    // Run expert and session reads in parallel.
    final expertFuture = _firebaseService.getExpert(topic.expertId ?? '');
    final sessionFuture = hasSession
        ? _firebaseService.getSession(topic.sessionId)
        : null;

    ExpertModel? expert;
    SessionModel? session;

    if (sessionFuture != null) {
      // Parallel fetch — expert failure propagates, session failure is caught.
      final results = await Future.wait([
        expertFuture,
        sessionFuture.then<SessionModel?>((s) => s).catchError((Object e) {
          // ignore: avoid_print
          print(
            'MentorController: session read failed for sessionId=${topic.sessionId}: $e',
          );
          return null;
        }),
      ]);
      expert = results[0] as ExpertModel?;
      session = results[1] as SessionModel?;
    } else {
      // No session to fetch — only read the expert.
      expert = await expertFuture;
    }

    // Expert is required — if null or missing, throw to exclude this row.
    if (expert == null) {
      throw FirebaseServiceException(
        'Expert not found for expertId=${topic.expertId}',
      );
    }

    // Build the row with session data or "Unknown" placeholders.
    return MentorRowModel(
      expertId: topic.expertId ?? '',
      mentorName: expert.name,
      topicName: topic.name,
      topicId: topic.topicId,
      institutionId: topic.institutionId ?? '',
      sessionId: topic.sessionId,
      price: topic.topicRate.toString(),
      duration: session!.selectedHours.toString(),
      sessionType: session?.sessionType ?? SessionPlaceholders.unknown,
      bio: expert.name,
      profileImageUrl: expert.imageFile,
    );
  }
}
