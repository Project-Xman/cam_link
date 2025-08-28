import 'package:get/get.dart';
import 'controllers/upload_manager_controller.dart';

/// Binding for Upload Manager module
class UploadManagerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UploadManagerController>(
      () => UploadManagerController(),
    );
  }
}