// lib/bindings/profile_binding.dart

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';
import '../services/file_uploader.dart';
import '../services/image_resizer.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
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
