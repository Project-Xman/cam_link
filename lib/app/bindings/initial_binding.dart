import 'package:get/get.dart';
import '../data/services/storage_service.dart';
import '../data/services/connectivity_service.dart';
import '../data/services/platform_diagnostics_service.dart';
import '../data/services/google_oauth_service.dart';
import '../data/services/google_drive_service.dart';
import '../data/services/image_processing_service.dart';
import '../data/services/appwrite_auth_service.dart';
import '../data/services/approval_service.dart';
import '../data/services/hotspot_service.dart';
import '../data/services/ftp_server_service.dart';
import '../data/services/gemini_pose_service.dart';
import '../data/services/camera_analysis_service.dart';
import '../data/services/sun_weather_service.dart';
import '../data/services/sensor_availability_service.dart';
import '../controllers/app_controller.dart';
import '../modules/home/controllers/home_controller.dart';
import '../modules/auth/controllers/auth_controller.dart';

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

    // 3. Appwrite authentication service
    Get.put(AppwriteAuthService(), permanent: true);

    // 4. Auth controller (depends on AppwriteAuthService)
    Get.put(AuthController(), permanent: true);

    // 5. Approval monitoring service
    Get.put(ApprovalService(), permanent: true);

    // 6. Google OAuth service (for Google Drive integration)
    Get.put(AuthService(), permanent: true);

    // 7. Google Drive service
    Get.put(GoogleDriveService(), permanent: true);

    // 8. Independent services
    Get.put(ImageProcessingService(), permanent: true);

    // 9. Hotspot and FTP services
    Get.put(HotspotService(), permanent: true);
    Get.put(FtpServerService(), permanent: true);

    // 10. Sensor and AI services
    Get.put(SensorAvailabilityService(), permanent: true);
    Get.put(GeminiPoseService(), permanent: true);
    Get.put(CameraAnalysisService(), permanent: true);
    Get.put(SunWeatherService(), permanent: true);

    // 11. App controller (depends on other services)
    Get.put(AppController(), permanent: true);

    // 12. Home controller (depends on other services)
    Get.lazyPut(() => HomeController());
  }
}