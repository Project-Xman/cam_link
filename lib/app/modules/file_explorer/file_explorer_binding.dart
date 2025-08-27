import 'package:get/get.dart';
import 'file_explorer_controller.dart';
import '../../data/services/google_drive_service.dart';
import '../../data/services/image_processing_service.dart';
import '../../data/services/google_oauth_service.dart';

/// Binding for File Explorer module
class FileExplorerBinding extends Bindings {
  @override
  void dependencies() {
    // Register ImageProcessingService if not already registered
    if (!Get.isRegistered<ImageProcessingService>()) {
      Get.put(ImageProcessingService());
    }
    
    // Register GoogleDriveService if not already registered
    if (!Get.isRegistered<GoogleDriveService>()) {
      Get.put(GoogleDriveService());
    }
    
    // Register AuthService if not already registered
    if (!Get.isRegistered<AuthService>()) {
      Get.put(AuthService());
    }
    
    Get.lazyPut<FileExplorerController>(
      () => FileExplorerController(),
      fenix: true,
    );
  }
}