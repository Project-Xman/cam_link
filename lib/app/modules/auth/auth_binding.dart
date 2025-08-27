import 'package:get/get.dart';
import 'controllers/auth_controller.dart';
import '../../data/services/appwrite_auth_service.dart';

/// Authentication binding for dependency injection
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Register Appwrite Auth Service
    if (!Get.isRegistered<AppwriteAuthService>()) {
      Get.put(AppwriteAuthService(), permanent: true);
    }
    
    // Register Auth Controller
    Get.put(AuthController());
  }
}