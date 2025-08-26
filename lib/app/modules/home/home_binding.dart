import 'package:get/get.dart';
import 'controllers/home_controller.dart';

/// Home module bindings
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Register HomeController
    Get.lazyPut<HomeController>(
      () => HomeController(),
    );
  }
}