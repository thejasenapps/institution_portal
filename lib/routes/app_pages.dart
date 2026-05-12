// lib/routes/app_pages.dart

import 'package:get/get.dart';

import '../bindings/initial_binding.dart';
import '../bindings/main_binding.dart';
import '../bindings/mentor_binding.dart';
import '../bindings/profile_binding.dart';
import '../views/dashboard_view.dart';
import '../views/login_page.dart';
import '../views/main_shell.dart';
import '../views/mentor_detail_panel.dart';
import '../views/mentors_view.dart';
import '../views/profile_view.dart';
import '../views/settings_view.dart';
import 'app_routes.dart';
import 'auth_middleware.dart';

/// Defines all application pages (routes) for GetX named routing.
class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
    ),
    GetPage(
      name: AppRoutes.shell,
      page: () => const MainShell(),
      binding: MainBinding(),
      middlewares: [AuthMiddleware()],
      children: [
        GetPage(
          name: '/dashboard',
          page: () => const DashboardView(),
        ),
        GetPage(
          name: '/mentors',
          page: () => const MentorsView(),
        ),
        GetPage(
          name: '/mentors/detail/:expertId',
          page: () => const MentorDetailPanel(),
        ),
        GetPage(
          name: '/profile',
          page: () => const ProfileView(),
        ),
        GetPage(
          name: '/settings',
          page: () => const SettingsView(),
        ),
      ],
    ),
  ];
}
