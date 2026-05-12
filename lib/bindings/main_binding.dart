// lib/bindings/main_binding.dart

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:institution_portal/controllers/mentor_controller.dart';
import 'package:institution_portal/controllers/profile_controller.dart';
import 'package:institution_portal/services/file_uploader.dart';
import 'package:institution_portal/services/image_resizer.dart';

import '../controllers/navigation_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NavigationController>(() => NavigationController());
    Get.lazyPut<MentorController>(
          () => MentorController(firebaseService: Get.find()),
    );
    Get.lazyPut<ImageResizer>(() => ImageResizer());
    Get.lazyPut<FileUploader>(() => FileUploader(Dio()));
    Get.lazyPut<ProfileController>(
          () => ProfileController(
        firebaseService: Get.find(),
        fileUploader: Get.find(),
        imageResizer: Get.find(),
      ),
    );
  }
}
