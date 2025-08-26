import 'package:get/get.dart';
import 'file_explorer_controller.dart';

/// Binding for File Explorer module
class FileExplorerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FileExplorerController>(
      () => FileExplorerController(),
      fenix: true,
    );
  }
}