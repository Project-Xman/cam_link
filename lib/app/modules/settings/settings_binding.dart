import 'package:get/get.dart';
import '../file_explorer/file_explorer_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    // The FileExplorerController should already be registered
    // We're just using it in the settings page
    if (!Get.isRegistered<FileExplorerController>()) {
      Get.put(FileExplorerController());
    }
  }
}