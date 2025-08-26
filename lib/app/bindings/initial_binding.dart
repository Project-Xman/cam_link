import 'package:get/get.dart';
import '../data/services/storage_service.dart';
import '../data/services/connectivity_service.dart';
import '../data/services/platform_diagnostics_service.dart';
import '../controllers/app_controller.dart';

/// Initial bindings that are loaded when the app starts
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services (singletons)
    Get.putAsync<StorageService>(() async {
      final service = StorageService();
      await service.onInit();
      return service;
    }, permanent: true);
    
    Get.putAsync<ConnectivityService>(() async {
      final service = ConnectivityService();
      await service.onInit();
      return service;
    }, permanent: true);

    // Platform diagnostics service (singleton)
    Get.putAsync<PlatformDiagnosticsService>(() async {
      final service = PlatformDiagnosticsService();
      await service.onInit();
      return service;
    }, permanent: true);

    // App controller (singleton)
    Get.putAsync<AppController>(() async {
      final controller = AppController();
      await controller.onInit();
      return controller;
    }, permanent: true);
  }
}