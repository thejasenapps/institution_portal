import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:institution_portal/bindings/initial_binding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/theme_controller.dart';
import 'firebase_options.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'services/anonymous_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color _kBrandPurple = Color(0xFF6347D1);

ThemeData _buildAppTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _kBrandPurple,
    brightness: brightness,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
  );

  final borderRadius = BorderRadius.circular(10);

  return base.copyWith(
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: brightness == Brightness.light
          ? colorScheme.surface
          : colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surface,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
    ),
    dataTableTheme: DataTableThemeData(
      dividerThickness: 1,
      dataRowMinHeight: 54,
      headingRowHeight: 48,
      horizontalMargin: 16,
      headingRowColor: WidgetStatePropertyAll<Color>(
        colorScheme.surfaceContainerHigh.withValues(alpha: 0.55),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        minimumSize: const Size.fromHeight(48),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init();
  final prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs, permanent: true);
  Get.put<ThemeController>(ThemeController(GetStorage()), permanent: true);
  try {
    await AnonymousAuthService(FirebaseAuth.instance).ensureSignedIn();
  } catch (e) {
    // ignore: avoid_print
    print('Anonymous auth bootstrap failed: $e');
  }
  runApp(const InstitutionPortalApp());
}

/// Root widget for the Institution Management Portal.
///
/// Uses [GetMaterialApp] for GetX named routing and reactive theme binding.
/// The initial route is determined by whether a session is already stored in
/// [SharedPreferences] under the key `session_institution_id`.
class InstitutionPortalApp extends StatelessWidget {
  const InstitutionPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = Get.find<SharedPreferences>();
    final themeController = Get.find<ThemeController>();

    // Determine initial route based on persisted session.
    final storedId = prefs.getString('session_institution_id');
    final initialRoute = (storedId != null && storedId.isNotEmpty)
        ? AppRoutes.shell
        : AppRoutes.login;

    return Obx(
      () => GetMaterialApp(
        title: 'Institution Management Portal',
        debugShowCheckedModeBanner: false,
        theme: _buildAppTheme(Brightness.light),
        darkTheme: _buildAppTheme(Brightness.dark),
        themeMode: themeController.isDarkMode.value
            ? ThemeMode.dark
            : ThemeMode.light,
        initialRoute: initialRoute,
        initialBinding: InitialBinding(),
        getPages: AppPages.pages,
      ),
    );
  }
}
