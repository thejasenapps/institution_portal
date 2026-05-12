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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init();
  final prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs, permanent: true);
  Get.put<ThemeController>(ThemeController(GetStorage()), permanent: true);
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
    final initialRoute =
        (storedId != null && storedId.isNotEmpty) ? AppRoutes.shell : AppRoutes.login;

    return Obx(
      () => GetMaterialApp(
        title: 'Institution Management Portal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
        initialRoute: initialRoute,
        initialBinding: InitialBinding(),
        getPages: AppPages.pages,
      ),
    );
  }
}
