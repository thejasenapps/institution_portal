// lib/views/mentors_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/mentor_controller.dart';
import '../models/mentor_row_model.dart';
import '../routes/app_routes.dart';
import '../utils/breakpoints.dart';
import '../utils/error_messages.dart';
import 'mentor_detail_panel.dart';

/// The Mentors section of the Institution Management Portal.
///
/// Displays a [DataTable] of mentor rows loaded by [MentorController].
/// On desktop (≥ 1024 px), tapping a row opens an inline [MentorDetailPanel]
/// to the right. On mobile/tablet (< 1024 px), tapping navigates to the
/// detail route.
///
/// States handled:
/// - Loading: [LinearProgressIndicator] at the top.
/// - Error: full-area error state with Retry button.
/// - Empty: "No mentors are linked to your institution." message.
/// - Loaded: [DataTable] with rows.
class MentorsView extends StatefulWidget {
  const MentorsView({super.key});

  @override
  State<MentorsView> createState() => _MentorsViewState();
}

class _MentorsViewState extends State<MentorsView> {
  late final MentorController _mentorController;
  late final AuthController _authController;

  /// The currently selected [MentorRowModel] for the inline detail panel.
  /// Null when no row is selected (panel is hidden).
  MentorRowModel? _selectedMentor;

  @override
  void initState() {
    super.initState();
    _mentorController = Get.find<MentorController>();
    _authController = Get.find<AuthController>();

    // Trigger initial load if not already loaded.
    _loadIfNeeded();
  }

  Future<void> _loadIfNeeded() async {
    if (_mentorController.mentorList.isEmpty &&
        !_mentorController.isLoading.value &&
        !_mentorController.hasError.value) {
      final institutionId = _authController.institutionId.value;
      if (institutionId.isNotEmpty) {
        await _mentorController.loadMentors(institutionId);
      }
    }
  }

  Future<void> _onRetry() async {
    final institutionId = _authController.institutionId.value;
    if (institutionId.isNotEmpty) {
      await _mentorController.reload(institutionId);
    }
  }

  void _onRowTap(BuildContext context, MentorRowModel mentor, double width) {
    if (width >= Breakpoints.tablet) {
      // Desktop / tablet ≥ 1024 px: show inline panel.
      setState(() {
        _selectedMentor =
            _selectedMentor?.expertId == mentor.expertId ? null : mentor;
      });
    } else {
      // Mobile < 1024 px: navigate to detail route.
      Get.toNamed(
        AppRoutes.mentorDetail.replaceFirst(':expertId', mentor.expertId),
        arguments: mentor,
      );
    }
  }

  void _closePanel() {
    setState(() => _selectedMentor = null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= Breakpoints.tablet;

        return Obx(() {
          final isLoading = _mentorController.isLoading.value;
          final hasError = _mentorController.hasError.value;
          final mentors = _mentorController.mentorList;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Loading indicator ─────────────────────────────────────────
              if (isLoading)
                const LinearProgressIndicator()
              else
                const SizedBox(height: 4.0),

              // ── Main content ──────────────────────────────────────────────
              Expanded(
                child: hasError
                    ? _ErrorState(onRetry: _onRetry)
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Table area
                          Expanded(
                            child: _MentorTableArea(
                              mentors: mentors,
                              selectedExpertId: _selectedMentor?.expertId,
                              onRowTap: (mentor) =>
                                  _onRowTap(context, mentor, width),
                            ),
                          ),
                          // Inline detail panel (desktop only)
                          if (isDesktop && _selectedMentor != null)
                            MentorDetailPanel(
                              mentor: _selectedMentor!,
                              onClose: _closePanel,
                              isInlinePanel: true,
                            ),
                        ],
                      ),
              ),
            ],
          );
        });
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _MentorTableArea
// ---------------------------------------------------------------------------

class _MentorTableArea extends StatelessWidget {
  final List<MentorRowModel> mentors;
  final String? selectedExpertId;
  final void Function(MentorRowModel mentor) onRowTap;

  const _MentorTableArea({
    required this.mentors,
    required this.selectedExpertId,
    required this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    if (mentors.isEmpty) {
      return const _EmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mentors',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16.0),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: false,
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Mentor Name')),
                DataColumn(label: Text('Topic Name')),
                DataColumn(label: Text('Price')),
              ],
              rows: mentors.map((mentor) {
                final isSelected = mentor.expertId == selectedExpertId;
                return DataRow(
                  selected: isSelected,
                  onSelectChanged: (_) => onRowTap(mentor),
                  cells: [
                    DataCell(
                      Text(
                        mentor.expertId,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataCell(
                      Text(
                        mentor.mentorName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataCell(
                      Text(
                        mentor.topicName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataCell(
                      Text(
                        mentor.price,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _EmptyState
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64.0,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16.0),
            Text(
              MentorErrors.noMentors,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ErrorState
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.0,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Failed to load mentor data.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              'Please check your connection and try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
