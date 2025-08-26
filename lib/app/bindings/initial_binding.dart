import 'package:get/get.dart';
import '../data/services/storage_service.dart';
import '../data/services/connectivity_service.dart';
import '../data/services/platform_diagnostics_service.dart';
import '../data/services/google_oauth_service.dart';
import '../data/services/google_drive_service.dart';
import '../data/services/image_processing_service.dart';
import '../data/services/supabase_auth_service.dart';
import '../controllers/app_controller.dart';

/// Initial bindings that are loaded when the app starts
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize services in proper order
    // 1. Core services that don't depend on others
    Get.put(StorageService(), permanent: true);
    
    Get.put(ConnectivityService(), permanent: true);

    // 2. Platform diagnostics service
    Get.put(PlatformDiagnosticsService(), permanent: true);

    // 3. Supabase authentication service
    Get.put(SupabaseAuthService(), permanent: true);

    // 4. Original Firebase authentication service
    Get.put(AuthService(), permanent: true);

    // 5. Services that depend on others
    Get.put(GoogleDriveService(authService: Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null), permanent: true);

    // 6. Independent services
    Get.put(ImageProcessingService(), permanent: true);

    // 7. App controller (depends on other services)
    Get.put(AppController(), permanent: true);
  }
}