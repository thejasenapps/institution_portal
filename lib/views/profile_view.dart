// lib/views/profile_view.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../utils/breakpoints.dart';
import '../utils/date_formatter.dart';
import '../widgets/expandable_history_panel.dart';

/// The Profile section of the Institution Management Portal.
///
/// Displays institution name (editable), logo (tappable to upload),
/// subscription expiry and plan (read-only), and the expandable subscription
/// history panel.
///
/// Layout:
/// - ≥ 1024 px: two-column (editable fields left, read-only info right)
/// - < 1024 px: single-column
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileController _controller;
  late final AuthController _authController;

  /// Whether the name field is currently in edit mode.
  bool _isEditingName = false;

  /// Controller for the name text field.
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ProfileController>();
    _authController = Get.find<AuthController>();
    _nameController = TextEditingController();

    // Load institution data if not already loaded.
    final institutionId = _authController.institutionId.value;
    if (institutionId.isNotEmpty &&
        _controller.institution.value == null) {
      _controller.loadInstitution(institutionId);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Enters edit mode and seeds the text field with the current name.
  void _startEditing(String currentName) {
    setState(() {
      _isEditingName = true;
      _nameController.text = currentName;
    });
    _controller.nameError.value = null;
  }

  /// Cancels editing and reverts to the saved name.
  void _cancelEditing() {
    setState(() => _isEditingName = false);
    _controller.nameError.value = null;
  }

  /// Saves the edited name via the controller.
  Future<void> _saveName() async {
    final institutionId = _authController.institutionId.value;
    await _controller.saveName(institutionId, _nameController.text);
    // Only exit edit mode if save succeeded (nameError is null and not saving).
    if (_controller.nameError.value == null &&
        !_controller.isSavingName.value) {
      setState(() => _isEditingName = false);
    }
  }

  /// Triggers logo pick and upload.
  void _onLogoTap() {
    if (_controller.isUploadingLogo.value) return;
    final institutionId = _authController.institutionId.value;
    _controller.pickAndUploadLogo(institutionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24.0),
            // Responsive layout: two-column on desktop, single-column otherwise.
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= Breakpoints.tablet;
                return isDesktop
                    ? _buildTwoColumnLayout(context)
                    : _buildSingleColumnLayout(context);
              },
            ),
            const SizedBox(height: 32.0),
            // Expandable subscription history panel.
            Obx(() {
              final inst = _controller.institution.value;
              return ExpandableHistoryPanel(
                entries: inst?.subscriptionHistory ?? [],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Layout builders
  // ---------------------------------------------------------------------------

  Widget _buildTwoColumnLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column: editable fields (logo + name).
        Expanded(child: _buildEditableSection(context)),
        const SizedBox(width: 32.0),
        // Right column: read-only info.
        Expanded(child: _buildReadOnlySection(context)),
      ],
    );
  }

  Widget _buildSingleColumnLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEditableSection(context),
        const SizedBox(height: 24.0),
        _buildReadOnlySection(context),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Editable section (logo + name)
  // ---------------------------------------------------------------------------

  Widget _buildEditableSection(BuildContext context) {
    return Obx(() {
      final inst = _controller.institution.value;
      final logoUrl = inst?.logoUrl;
      final currentName = inst?.name ?? '';

      // Seed the text field when not editing (reflects external updates).
      if (!_isEditingName) {
        _nameController.text = currentName;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo area.
          _buildLogoArea(context, logoUrl),
          const SizedBox(height: 24.0),
          // Name field.
          _buildNameField(context, currentName),
        ],
      );
    });
  }

  Widget _buildLogoArea(BuildContext context, String? logoUrl) {
    return Obx(() {
      final isUploading = _controller.isUploadingLogo.value;

      return Stack(
        alignment: Alignment.center,
        children: [
          // Tappable logo circle.
          GestureDetector(
            onTap: isUploading ? null : _onLogoTap,
            child: Semantics(
              label: 'Institution logo. Tap to upload a new logo.',
              button: true,
              child: CircleAvatar(
                radius: 56.0,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ClipOval(
                  child: logoUrl != null && logoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: logoUrl,
                          width: 112.0,
                          height: 112.0,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const SizedBox(
                            width: 112.0,
                            height: 112.0,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.business,
                            size: 48.0,
                          ),
                        )
                      : const Icon(Icons.business, size: 48.0),
                ),
              ),
            ),
          ),
          // Loading overlay while uploading.
          if (isUploading)
            Container(
              width: 112.0,
              height: 112.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.45),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3.0,
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildNameField(BuildContext context, String currentName) {
    return Obx(() {
      final nameErr = _controller.nameError.value;
      final isSaving = _controller.isSavingName.value;

      if (_isEditingName) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: 'Institution Name',
                errorText: nameErr,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _saveName(),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                ElevatedButton(
                  onPressed: isSaving ? null : _saveName,
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
                const SizedBox(width: 8.0),
                OutlinedButton(
                  onPressed: isSaving ? null : _cancelEditing,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        );
      }

      // Read-only display with edit button.
      return Row(
        children: [
          Expanded(
            child: Text(
              currentName.isNotEmpty ? currentName : '—',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit institution name',
            onPressed: () => _startEditing(currentName),
          ),
        ],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Read-only section (subscription expiry + plan)
  // ---------------------------------------------------------------------------

  Widget _buildReadOnlySection(BuildContext context) {
    return Obx(() {
      final inst = _controller.institution.value;
      final expiryText = formatSubscriptionDate(inst?.subscriptionExpiry);
      final plan = inst?.plan ?? '—';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscription Details',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16.0),
          _buildReadOnlyRow(context, 'Expiry Date', expiryText),
          const SizedBox(height: 12.0),
          _buildReadOnlyRow(context, 'Plan', plan),
        ],
      );
    });
  }

  Widget _buildReadOnlyRow(
      BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: textTheme.bodyLarge,
        ),
      ],
    );
  }
}
