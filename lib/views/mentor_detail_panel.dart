// lib/views/mentor_detail_panel.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/mentor_row_model.dart';
import '../services/firebase_service.dart';
import '../utils/error_messages.dart';

/// Displays full details for a single mentor.
///
/// Can be used in two modes:
/// - **Inline panel** (desktop ≥ 1024 px): rendered as an [AnimatedContainer]
///   that slides in from the right inside [MentorsView]. Pass [isInlinePanel]
///   = `true` and provide an [onClose] callback.
/// - **Full-screen page** (mobile/tablet < 1024 px): navigated to via
///   `/shell/mentors/detail/:expertId`. The [MentorRowModel] is passed via
///   `Get.arguments`.
///
/// If [mentor.bio] or [mentor.profileImageUrl] are absent, the panel fetches
/// the Expert document lazily via [FirebaseService].
class MentorDetailPanel extends StatefulWidget {
  /// The mentor row data to display. When used as a full-screen page, this
  /// may be null and the data is read from [Get.arguments].
  final MentorRowModel? mentor;

  /// Called when the user taps the close button (inline panel mode only).
  final VoidCallback? onClose;

  /// Whether this widget is rendered as an inline side panel (true) or as a
  /// standalone full-screen page (false).
  final bool isInlinePanel;

  const MentorDetailPanel({
    super.key,
    this.mentor,
    this.onClose,
    this.isInlinePanel = false,
  });

  @override
  State<MentorDetailPanel> createState() => _MentorDetailPanelState();
}

class _MentorDetailPanelState extends State<MentorDetailPanel> {
  /// The resolved mentor data (may be enriched with bio/profileImageUrl).
  MentorRowModel? _mentor;

  /// Whether a lazy fetch for bio/profileImageUrl is in progress.
  bool _isFetchingDetails = false;

  @override
  void initState() {
    super.initState();

    // Resolve mentor from widget prop or Get.arguments (full-screen page mode).
    _mentor = widget.mentor ?? (Get.arguments as MentorRowModel?);

    // Lazily fetch bio and profileImageUrl if not already present.
    if (_mentor != null &&
        (_mentor!.bio == null || _mentor!.profileImageUrl == null)) {
      _fetchExpertDetails();
    }
  }

  @override
  void didUpdateWidget(MentorDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the selected mentor changes in inline panel mode, refresh.
    if (widget.mentor != null &&
        widget.mentor?.expertId != oldWidget.mentor?.expertId) {
      setState(() {
        _mentor = widget.mentor;
        _isFetchingDetails = false;
      });
      if (_mentor!.bio == null || _mentor!.profileImageUrl == null) {
        _fetchExpertDetails();
      }
    }
  }

  Future<void> _fetchExpertDetails() async {
    if (_mentor == null) return;
    setState(() => _isFetchingDetails = true);

    try {
      final firebaseService = Get.find<FirebaseService>();
      final expert = await firebaseService.getExpert(_mentor!.expertId);

      if (expert != null && mounted) {
        setState(() {
          _mentor = MentorRowModel(
            expertId: _mentor!.expertId,
            mentorName: _mentor!.mentorName,
            topicName: _mentor!.topicName,
            topicId: _mentor!.topicId,
            institutionId: _mentor!.institutionId,
            sessionId: _mentor!.sessionId,
            price: _mentor!.price,
            duration: _mentor!.duration,
            sessionType: _mentor!.sessionType,
            bio: expert.bio ?? _mentor!.bio,
            profileImageUrl:
                expert.profileImageUrl ?? _mentor!.profileImageUrl,
          );
        });
      }
    } catch (_) {
      // Fetch failed — display "—" for bio and fallback avatar for image.
      // No action needed; the UI already handles null values gracefully.
    } finally {
      if (mounted) {
        setState(() => _isFetchingDetails = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mentor == null) {
      return const SizedBox.shrink();
    }

    if (widget.isInlinePanel) {
      return _InlinePanel(
        mentor: _mentor!,
        isFetchingDetails: _isFetchingDetails,
        onClose: widget.onClose ?? () {},
      );
    }

    // Full-screen page mode (mobile/tablet).
    return Scaffold(
      appBar: AppBar(
        title: Text(_mentor!.mentorName),
        leading: BackButton(
          onPressed: () => Get.back(),
        ),
      ),
      body: _DetailContent(
        mentor: _mentor!,
        isFetchingDetails: _isFetchingDetails,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _InlinePanel — desktop side panel
// ---------------------------------------------------------------------------

class _InlinePanel extends StatelessWidget {
  final MentorRowModel mentor;
  final bool isFetchingDetails;
  final VoidCallback onClose;

  const _InlinePanel({
    required this.mentor,
    required this.isFetchingDetails,
    required this.onClose,
  });

  static const double _panelWidth = 360.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: _panelWidth,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8.0,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Panel header with close button.
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mentor Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Semantics(
                  label: AccessibilityLabels.close,
                  child: IconButton(
                    tooltip: AccessibilityLabels.close,
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable detail content.
          Expanded(
            child: _DetailContent(
              mentor: mentor,
              isFetchingDetails: isFetchingDetails,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DetailContent — shared content for both panel and full-screen page
// ---------------------------------------------------------------------------

class _DetailContent extends StatelessWidget {
  final MentorRowModel mentor;
  final bool isFetchingDetails;

  const _DetailContent({
    required this.mentor,
    required this.isFetchingDetails,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile image.
          Center(
            child: _ProfileImage(
              imageUrl: mentor.profileImageUrl,
              isFetching: isFetchingDetails,
            ),
          ),
          const SizedBox(height: 20.0),

          // Full name.
          Center(
            child: Text(
              mentor.mentorName,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24.0),

          // Detail fields.
          _DetailField(label: 'Expert ID', value: mentor.expertId),
          _DetailField(
            label: 'Bio',
            value: isFetchingDetails
                ? null // show loading placeholder
                : (mentor.bio?.isNotEmpty == true
                    ? mentor.bio!
                    : ProfileErrors.missingBio),
            isLoading: isFetchingDetails,
          ),
          const Divider(height: 32.0),
          _DetailField(label: 'Topic Name', value: mentor.topicName),
          _DetailField(label: 'Topic ID', value: mentor.topicId),
          _DetailField(label: 'Institution ID', value: mentor.institutionId),
          const Divider(height: 32.0),
          _DetailField(
            label: 'Session ID',
            value: mentor.sessionId.isNotEmpty
                ? mentor.sessionId
                : ProfileErrors.missingBio,
          ),
          _DetailField(label: 'Price', value: mentor.price),
          _DetailField(label: 'Duration', value: mentor.duration),
          _DetailField(label: 'Session Type', value: mentor.sessionType),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ProfileImage — circular avatar with CachedNetworkImage
// ---------------------------------------------------------------------------

class _ProfileImage extends StatelessWidget {
  final String? imageUrl;
  final bool isFetching;

  const _ProfileImage({
    required this.imageUrl,
    required this.isFetching,
  });

  static const double _size = 96.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isFetching || imageUrl == null || imageUrl!.isEmpty) {
      // Show placeholder avatar while fetching or when no URL is available.
      return CircleAvatar(
        radius: _size / 2,
        backgroundColor: colorScheme.primaryContainer,
        child: isFetching
            ? SizedBox(
                width: 32.0,
                height: 32.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: colorScheme.onPrimaryContainer,
                ),
              )
            : Icon(
                Icons.person,
                size: _size / 2,
                color: colorScheme.onPrimaryContainer,
              ),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        // Placeholder shown while the image loads.
        placeholder: (context, url) => CircleAvatar(
          radius: _size / 2,
          backgroundColor: colorScheme.primaryContainer,
          child: SizedBox(
            width: 32.0,
            height: 32.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        // Fallback avatar shown when the image fails to load.
        errorWidget: (context, url, error) => CircleAvatar(
          radius: _size / 2,
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.person,
            size: _size / 2,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DetailField — labelled value row
// ---------------------------------------------------------------------------

class _DetailField extends StatelessWidget {
  final String label;
  final String? value;
  final bool isLoading;

  const _DetailField({
    required this.label,
    this.value,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2.0),
          isLoading
              ? SizedBox(
                  height: 16.0,
                  width: 120.0,
                  child: LinearProgressIndicator(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                )
              : Text(
                  value ?? ProfileErrors.missingBio,
                  style: textTheme.bodyMedium,
                ),
        ],
      ),
    );
  }
}
