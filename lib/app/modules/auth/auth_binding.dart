import 'package:get/get.dart';
import 'controllers/auth_controller.dart';
import '../../data/services/supabase_auth_service.dart';

/// Authentication binding for dependency injection
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Register Supabase Auth Service
    if (!Get.isRegistered<SupabaseAuthService>()) {
      Get.put(SupabaseAuthService(), permanent: true);
    }
    
    // Register Auth Controller
    Get.put(AuthController());
  }
}