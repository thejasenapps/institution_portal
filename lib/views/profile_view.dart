// lib/views/profile_view.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../utils/breakpoints.dart';
import '../utils/date_formatter.dart';
import '../utils/error_messages.dart';
import '../widgets/expandable_history_panel.dart';

/// The Profile section of the Institution Management Portal.
///
/// Displays institution name (editable), logo (tappable to upload),
/// subscription expiry and plan (read-only), and the expandable subscription
/// history panel.
///
/// Layout:
/// - ≥ 1024 px: two-column (profile summary left, subscription right)
/// - < 1024 px: single-column
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileController _controller;
  late final AuthController _authController;

  bool _isEditingName = false;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ProfileController>();
    _authController = Get.find<AuthController>();
    _nameController = TextEditingController();

    final institutionId = _authController.institutionId.value;
    if (institutionId.isNotEmpty && _controller.institution.value == null) {
      _controller.loadInstitution(institutionId);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startEditing(String currentName) {
    setState(() {
      _isEditingName = true;
      _nameController.text = currentName;
    });
    _controller.nameError.value = null;
  }

  void _cancelEditing() {
    setState(() => _isEditingName = false);
    _controller.nameError.value = null;
  }

  Future<void> _saveName() async {
    final institutionId = _authController.institutionId.value;
    await _controller.saveName(institutionId, _nameController.text);
    if (_controller.nameError.value == null &&
        !_controller.isSavingName.value) {
      setState(() => _isEditingName = false);
    }
  }

  void _onLogoTap() {
    if (_controller.isUploadingLogo.value) return;
    final institutionId = _authController.institutionId.value;
    _controller.pickAndUploadLogo(institutionId);
  }

  String _institutionInitial(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }

  bool _isLikelyRemoteUrl(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  String? institutionLogoUrl(dynamic logoField) {
    if (logoField == null) return null;
    if (logoField is String) {
      final t = logoField.trim();
      return t.isEmpty ? null : t;
    }
    final t = logoField.toString().trim();
    return t.isEmpty ? null : t;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24.0),
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= Breakpoints.tablet;
                return isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildProfileSummaryCard()),
                          const SizedBox(width: 28.0),
                          Expanded(flex: 3, child: _buildReadOnlySection()),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileSummaryCard(),
                          const SizedBox(height: 24.0),
                          _buildReadOnlySection(),
                        ],
                      );
              },
            ),
            const SizedBox(height: 32.0),
            Obx(() {
              final inst = _controller.institution.value;
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ExpandableHistoryPanel(
                  entries: inst?.subscriptionHistory ?? [],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummaryCard() {
    return Obx(() {
      final inst = _controller.institution.value;
      final logoSrc = institutionLogoUrl(inst?.logo);
      final usesNetworkLogo = logoSrc != null && _isLikelyRemoteUrl(logoSrc);
      final currentName = inst?.name ?? '';

      if (!_isEditingName) {
        _nameController.text = currentName;
      }

      final colorScheme = Theme.of(context).colorScheme;

      return Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 112,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.18),
                        colorScheme.primaryContainer.withValues(alpha: 0.42),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -46,
                  child: Center(
                    child: _buildLogoArea(context, logoSrc, usesNetworkLogo),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 52),
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    currentName.isNotEmpty ? currentName : '—',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Institutional Partner',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildNameControls(context, currentName),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLogoArea(
    BuildContext context,
    String? logoSrc,
    bool usesNetworkLogo,
  ) {
    return Obx(() {
      final isUploading = _controller.isUploadingLogo.value;
      final colorScheme = Theme.of(context).colorScheme;
      final name = _controller.institution.value?.name ?? '';
      final initial = _institutionInitial(name);

      final Widget avatarChild;
      if (usesNetworkLogo && logoSrc != null) {
        avatarChild = ClipOval(
          child: CachedNetworkImage(
            imageUrl: logoSrc,
            width: 96.0,
            height: 96.0,
            fit: BoxFit.cover,
            placeholder: (context, url) => SizedBox(
              width: 96.0,
              height: 96.0,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: colorScheme.primary,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 34.0,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      } else {
        avatarChild = Center(
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 34.0,
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
            ),
          ),
        );
      }

      return Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: isUploading ? null : _onLogoTap,
            child: Semantics(
              label: 'Institution logo. Tap to upload a new logo.',
              button: true,
              child: CircleAvatar(
                radius: 48.0,
                backgroundColor: colorScheme.surface,
                child: avatarChild,
              ),
            ),
          ),
          if (isUploading)
            Container(
              width: 96.0,
              height: 96.0,
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

  Widget _buildNameControls(BuildContext context, String currentName) {
    return Obx(() {
      final nameErr = _controller.nameError.value;
      final isSaving = _controller.isSavingName.value;

      if (_isEditingName) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: 'Institution Name',
                errorText: nameErr,
              ),
              onSubmitted: (_) => _saveName(),
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _saveName,
                    child: isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSaving ? null : _cancelEditing,
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        );
      }

      return OutlinedButton.icon(
        onPressed: () => _startEditing(currentName),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('Edit profile'),
      );
    });
  }

  Widget _buildReadOnlySection() {
    return Obx(() {
      final inst = _controller.institution.value;
      final expiryText = formatSubscriptionDate(
        inst?.currentSubscriptionEndDate,
      );
      final plan = inst?.subscriptionPlan ?? '—';
      final active = inst?.isSubscriptionActive == true;
      final colorScheme = Theme.of(context).colorScheme;

      Widget expirySubcard(BuildContext _) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expiry Date',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10.0),
              Text(
                expiryText,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (active) ...[
                const SizedBox(height: 10.0),
                Chip(
                  avatar: Icon(
                    Icons.check_circle,
                    size: 18,
                    color: colorScheme.onPrimary,
                  ),
                  label: Text(
                    StatusLabels.active,
                    style: TextStyle(color: colorScheme.onPrimary),
                  ),
                  backgroundColor: Colors.green.shade700.withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 0,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        );
      }

      Widget planSubcard() {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10.0),
              Text(
                plan,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Institution billing amount',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subscription Details',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18.0),
              LayoutBuilder(
                builder: (context, c) {
                  final narrow = c.maxWidth < 520;
                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        expirySubcard(context),
                        const SizedBox(height: 12.0),
                        planSubcard(),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: expirySubcard(context)),
                      const SizedBox(width: 16.0),
                      Expanded(child: planSubcard()),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }
}
