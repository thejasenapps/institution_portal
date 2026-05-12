// lib/bindings/initial_binding.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/auth_controller.dart';
import '../services/firebase_service.dart';

// lib/bindings/initial_binding.dart

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FirebaseService>(
          () => FirebaseService(FirebaseFirestore.instance),
      fenix: true,
    );

    Get.put<AuthController>(
      AuthController(
        firebaseService: Get.find(),
        prefs: Get.find<SharedPreferences>(),
      ),
      permanent: true,
    );
  }
}
