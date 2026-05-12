// lib/routes/auth_middleware.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import 'app_routes.dart';

/// Route guard that redirects unauthenticated users to the login screen.
///
/// Applied to the `/shell` route so that all child routes are protected.
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    if (!auth.isAuthenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}
