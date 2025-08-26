import 'package:get/get.dart';
import 'file_explorer_controller.dart';
import '../../data/services/google_drive_service.dart';
import '../../data/services/image_processing_service.dart';
import '../../data/services/auth_service.dart';

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
      // Get the already initialized AuthService
      final authService = Get.find<AuthService>();
      Get.put(GoogleDriveService(authService: authService));
    }
    
    Get.lazyPut<FileExplorerController>(
      () => FileExplorerController(),
      fenix: true,
    );
  }
}