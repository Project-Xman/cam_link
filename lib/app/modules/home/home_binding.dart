import 'package:get/get.dart';
import 'controllers/home_controller.dart';
import '../../data/services/auth_service.dart';

/// Home module bindings
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Register AuthService if not already registered
    if (!Get.isRegistered<AuthService>()) {
      Get.putAsync<AuthService>(() async {
        final service = AuthService();
        await service.onInit();
        return service;
      });
    }
    
    // Register HomeController
    Get.lazyPut<HomeController>(
      () => HomeController(),
    );
  }
}