// lib/views/main_shell.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/navigation_controller.dart';
import '../utils/breakpoints.dart';
import 'dashboard_view.dart';
import 'mentors_view.dart';
import 'profile_view.dart';
import 'settings_view.dart';

// ---------------------------------------------------------------------------
// Navigation item descriptor
// ---------------------------------------------------------------------------

class _NavItem {
  final int index;
  final IconData icon;
  final String label;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.label,
  });
}

const List<_NavItem> _navItems = [
  _NavItem(index: 0, icon: Icons.dashboard, label: 'Dashboard'),
  _NavItem(index: 1, icon: Icons.people, label: 'Mentors'),
  _NavItem(index: 2, icon: Icons.business, label: 'Profile'),
  _NavItem(index: 3, icon: Icons.settings, label: 'Settings'),
];

const _NavItem _logoutItem = _NavItem(
  index: -1,
  icon: Icons.logout,
  label: 'Logout',
);

// ---------------------------------------------------------------------------
// MainShell
// ---------------------------------------------------------------------------

/// Root scaffold rendered after successful authentication.
///
/// Uses [LayoutBuilder] to determine the current breakpoint and renders:
/// - Desktop / Tablet (≥ 768 px): persistent [Sidebar] + content area.
/// - Mobile (< 768 px): hamburger [AppBar] + [Drawer] + content area.
///
/// The content area uses [Obx] to swap between the four section views based
/// on [NavigationController.activeIndex].
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<NavigationController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < Breakpoints.mobile;
        final isTablet =
            width >= Breakpoints.mobile && width < Breakpoints.tablet;

        return Scaffold(
          // ── Mobile: hamburger AppBar ──────────────────────────────────────
          appBar: isMobile
              ? AppBar(
                  title: Obx(() => Text(_sectionTitle(nav.activeIndex.value))),
                  leading: Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu),
                      tooltip: 'Open navigation menu',
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                )
              : null,

          // ── Mobile: Drawer with full nav items ────────────────────────────
          drawer: isMobile
              ? Drawer(
                  child: SafeArea(
                    child: Obx(
                      () => _DrawerContent(
                        activeIndex: nav.activeIndex.value,
                        onItemTap: (index) {
                          Navigator.of(context).pop(); // close drawer
                          nav.navigateTo(index);
                        },
                        onLogoutTap: () {
                          Navigator.of(context).pop();
                          Get.find<AuthController>().logout();
                        },
                      ),
                    ),
                  ),
                )
              : null,

          // ── Body: sidebar + content ───────────────────────────────────────
          body: Row(
            children: [
              if (!isMobile)
                Obx(() => Sidebar(
                  collapsed: isTablet,
                  activeIndex: nav.activeIndex.value,
                  onItemTap: nav.navigateTo,
                  onLogoutTap: Get.find<AuthController>().logout,
                )),
              Expanded(
                child: Obx(() => _contentView(nav.activeIndex.value)),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Returns the section title for the mobile AppBar.
  String _sectionTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Mentors';
      case 2:
        return 'Profile';
      case 3:
        return 'Settings';
      default:
        return 'Institution Portal';
    }
  }

  /// Returns the content view widget for the given [activeIndex].
  Widget _contentView(int index) {
    switch (index) {
      case 0:
        return const DashboardView();
      case 1:
        return const MentorsView();
      case 2:
        return const ProfileView();
      case 3:
        return const SettingsView();
      default:
        return const DashboardView();
    }
  }
}

// ---------------------------------------------------------------------------
// Sidebar
// ---------------------------------------------------------------------------

/// Persistent left sidebar shown on tablet and desktop breakpoints.
///
/// - [collapsed] = `true` → 72 px wide, icons + tooltips only.
/// - [collapsed] = `false` → 240 px wide, icons + text labels.
///
/// The active item is highlighted with a filled background chip driven by
/// [activeIndex]. The Logout item is pinned to the bottom via a [Spacer].
class Sidebar extends StatelessWidget {
  /// Whether the sidebar is in collapsed (icon-only) mode.
  final bool collapsed;

  /// The currently active navigation index.
  final int activeIndex;

  /// Called when a navigation item is tapped.
  final void Function(int index) onItemTap;

  /// Called when the Logout item is tapped.
  final VoidCallback onLogoutTap;

  const Sidebar({
    super.key,
    required this.collapsed,
    required this.activeIndex,
    required this.onItemTap,
    required this.onLogoutTap,
  });

  static const double _expandedWidth = 240.0;
  static const double _collapsedWidth = 72.0;

  @override
  Widget build(BuildContext context) {
    final width = collapsed ? _collapsedWidth : _expandedWidth;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Logo / brand area ─────────────────────────────────────────────
          SizedBox(
            height: 64,
            child: Center(
              child: collapsed
                  ? Icon(Icons.school, color: colorScheme.primary, size: 28)
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Institution Portal',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
          ),

          const Divider(height: 1),

          // ── Navigation items ──────────────────────────────────────────────
          for (final item in _navItems)
            _SidebarItem(
              icon: item.icon,
              label: item.label,
              isActive: activeIndex == item.index,
              collapsed: collapsed,
              onTap: () => onItemTap(item.index),
            ),

          // ── Push Logout to bottom ─────────────────────────────────────────
          const Spacer(),

          const Divider(height: 1),

          // ── Logout ────────────────────────────────────────────────────────
          _SidebarItem(
            icon: _logoutItem.icon,
            label: _logoutItem.label,
            isActive: false,
            collapsed: collapsed,
            onTap: onLogoutTap,
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SidebarItem
// ---------------------------------------------------------------------------

/// A single item in the [Sidebar].
///
/// - When [collapsed] is `true`, shows only the icon wrapped in a [Tooltip].
/// - When [collapsed] is `false`, shows icon + label side by side.
/// - When [isActive] is `true`, renders a filled background chip highlight.
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool collapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurfaceVariant;
    final iconColor = isActive ? activeColor : inactiveColor;

    Widget itemContent;

    if (collapsed) {
      // Icon-only with tooltip
      itemContent = Tooltip(
        message: label,
        preferBelow: false,
        child: Container(
          width: double.infinity,
          height: 48,
          alignment: Alignment.center,
          decoration: isActive
              ? BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Icon(icon, color: iconColor, size: 24),
        ),
      );
    } else {
      // Icon + label
      itemContent = Container(
        width: double.infinity,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: isActive
            ? BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: iconColor,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Semantics(
          label: label,
          button: true,
          selected: isActive,
          child: itemContent,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DrawerContent
// ---------------------------------------------------------------------------

/// Full navigation list rendered inside the mobile [Drawer].
///
/// Shows icons + labels for all items. Active item is highlighted.
/// Logout is pinned to the bottom via [Spacer].
class _DrawerContent extends StatelessWidget {
  final int activeIndex;
  final void Function(int index) onItemTap;
  final VoidCallback onLogoutTap;

  const _DrawerContent({
    required this.activeIndex,
    required this.onItemTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Drawer header ─────────────────────────────────────────────────
        DrawerHeader(
          decoration: BoxDecoration(color: colorScheme.primaryContainer),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.school, color: colorScheme.primary, size: 36),
              const SizedBox(height: 8),
              Text(
                'Institution Portal',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),

        // ── Navigation items ──────────────────────────────────────────────
        for (final item in _navItems)
          _SidebarItem(
            icon: item.icon,
            label: item.label,
            isActive: activeIndex == item.index,
            collapsed: false,
            onTap: () => onItemTap(item.index),
          ),

        // ── Push Logout to bottom ─────────────────────────────────────────
        const Spacer(),

        const Divider(height: 1),

        // ── Logout ────────────────────────────────────────────────────────
        _SidebarItem(
          icon: _logoutItem.icon,
          label: _logoutItem.label,
          isActive: false,
          collapsed: false,
          onTap: onLogoutTap,
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}
