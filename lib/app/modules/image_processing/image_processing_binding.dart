import 'package:get/get.dart';
import 'controllers/image_processing_controller.dart';

/// Binding for Image Processing module
class ImageProcessingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ImageProcessingController>(
      () => ImageProcessingController(),
    );
  }
}