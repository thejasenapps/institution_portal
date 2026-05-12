// lib/views/dashboard_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/mentor_controller.dart';
import '../controllers/profile_controller.dart';
import '../utils/breakpoints.dart';
import '../utils/date_formatter.dart';
import '../utils/error_messages.dart';
import '../widgets/stat_card.dart';

/// The Dashboard section of the Institution Management Portal.
///
/// Displays summary stat cards (Total Mentors, Subscription Expiry) in a
/// responsive grid, a reload button, and a [MaterialBanner] on fetch errors.
///
/// Reactive updates are driven by [Obx] wrappers around [MentorController]
/// and [ProfileController] observables.
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final MentorController _mentorController;
  late final ProfileController _profileController;
  late final AuthController _authController;

  /// Whether the error banner is currently visible.
  bool _showBanner = false;

  /// Which data source(s) failed — used in the banner message.
  String _bannerMessage = '';

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _mentorController = Get.find<MentorController>();
    _profileController = Get.find<ProfileController>();

    // Trigger initial load if data is not already present.
    _loadData();
  }

  /// Loads mentor and institution data if not already loaded.
  Future<void> _loadData() async {
    final institutionId = _authController.institutionId.value;
    if (institutionId.isEmpty) return;

    // Run both loads concurrently and surface any errors as a banner.
    await _runLoads(institutionId);
  }

  /// Runs mentor and institution loads concurrently, then evaluates errors.
  Future<void> _runLoads(String institutionId) async {
    await Future.wait([
      _mentorController.loadMentors(institutionId),
      _profileController.loadInstitution(institutionId),
    ]);

    _evaluateBanner();
  }

  /// Checks controller error states and updates the banner accordingly.
  void _evaluateBanner() {
    final mentorFailed = _mentorController.hasError.value;
    final profileFailed = _profileController.institution.value == null &&
        !_mentorController.isLoading.value;

    if (mentorFailed || profileFailed) {
      final parts = <String>[];
      if (mentorFailed) parts.add('mentor data');
      if (profileFailed) parts.add('institution data');
      setState(() {
        _bannerMessage =
            'Failed to load ${parts.join(' and ')}. Please retry.';
        _showBanner = true;
      });
    } else {
      setState(() {
        _showBanner = false;
      });
    }
  }

  /// Reloads all data when the user taps the reload button.
  Future<void> _onReload() async {
    setState(() => _showBanner = false);
    final institutionId = _authController.institutionId.value;
    if (institutionId.isEmpty) return;

    await Future.wait([
      _mentorController.reload(institutionId),
      _profileController.loadInstitution(institutionId),
    ]);

    _evaluateBanner();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Material Banner shown on fetch error.
          if (_showBanner)
            MaterialBanner(
              content: Text(_bannerMessage),
              leading: const Icon(Icons.error_outline),
              actions: [
                TextButton(
                  onPressed: _onReload,
                  child: const Text('Retry'),
                ),
                TextButton(
                  onPressed: () => setState(() => _showBanner = false),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          // Main scrollable content.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with title and reload button.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dashboard',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Semantics(
                        label: AccessibilityLabels.reloadMentorData,
                        child: IconButton(
                          tooltip: AccessibilityLabels.reloadMentorData,
                          icon: const Icon(Icons.refresh),
                          onPressed: _onReload,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  // Responsive stat card grid.
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final int columns;
                      if (width >= Breakpoints.desktop) {
                        columns = 3; // ≥ 1280 px → 3+ columns
                      } else if (width >= Breakpoints.tablet) {
                        columns = 2; // 1024–1279 px → 2 columns
                      } else {
                        columns = 1; // < 1024 px → 1 column
                      }

                      return _StatCardGrid(
                        columns: columns,
                        mentorController: _mentorController,
                        profileController: _profileController,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _StatCardGrid — internal widget that renders the responsive grid
// ---------------------------------------------------------------------------

class _StatCardGrid extends StatelessWidget {
  final int columns;
  final MentorController mentorController;
  final ProfileController profileController;

  const _StatCardGrid({
    required this.columns,
    required this.mentorController,
    required this.profileController,
  });

  @override
  Widget build(BuildContext context) {
    // Build the list of stat cards reactively.
    return Obx(() {
      final mentorCount = mentorController.mentorList.length;
      final institution = profileController.institution.value;
      final expiryText = formatSubscriptionDate(institution?.subscriptionExpiry);

      final cards = <Widget>[
        StatCard(
          title: 'Total Mentors',
          value: '$mentorCount',
          icon: Icons.people_outline,
        ),
        StatCard(
          title: 'Subscription Expiry',
          value: expiryText,
          icon: Icons.calendar_today_outlined,
        ),
      ];

      if (columns == 1) {
        // Single-column: stack cards vertically.
        return Column(
          children: cards
              .map((card) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: card,
                  ))
              .toList(),
        );
      }

      // Multi-column: use a LayoutBuilder + Wrap for a responsive grid.
      return LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final cardWidth =
              (totalWidth - (columns - 1) * 16.0) / columns;

          return Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            children: cards.map((card) {
              return SizedBox(
                width: cardWidth,
                child: card,
              );
            }).toList(),
          );
        },
      );
    });
  }
}
