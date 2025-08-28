import 'package:get/get.dart';
import 'controllers/auth_controller.dart';
import '../../data/services/appwrite_auth_service.dart';

/// Authentication binding for dependency injection
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Services and controllers are already registered in InitialBinding
    // This binding ensures they're available for auth pages
    // No need to register again since they're permanent
  }
}