// lib/routes/app_routes.dart

/// Defines all named route constants for the Institution Management Portal.
abstract class AppRoutes {
  static const login = '/login';
  static const shell = '/shell';
  static const dashboard = '/shell/dashboard';
  static const mentors = '/shell/mentors';
  static const mentorDetail = '/shell/mentors/detail/:expertId';
  static const profile = '/shell/profile';
  static const settings = '/shell/settings';
}
