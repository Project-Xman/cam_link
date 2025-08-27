import 'dart:async';
import 'package:get/get.dart';
import 'appwrite_auth_service.dart';
import '../../routes/app_routes.dart';

/// Service to monitor user approval status in real-time
class ApprovalService extends GetxService {
  static ApprovalService get to => Get.find();

  late final AppwriteAuthService _authService;
  Timer? _approvalCheckTimer;
  
  // Reactive variables
  final isApproved = false.obs;
  final isChecking = false.obs;
  
  // Check interval (in seconds)
  static const int checkInterval = 30;

  @override
  void onInit() {
    super.onInit();
    _authService = AppwriteAuthService.to;
    _startApprovalMonitoring();
  }

  /// Start monitoring approval status
  void _startApprovalMonitoring() {
    // Initial check
    _checkApprovalStatus();
    
    // Set up periodic checks
    _approvalCheckTimer = Timer.periodic(
      const Duration(seconds: checkInterval),
      (_) => _checkApprovalStatus(),
    );
  }

  /// Check current user approval status
  Future<void> _checkApprovalStatus() async {
    if (!_authService.isAuthenticated) {
      isApproved.value = false;
      return;
    }

    try {
      isChecking.value = true;
      final approved = await _authService.isUserApproved();
      
      // If approval status changed
      if (isApproved.value != approved) {
        isApproved.value = approved;
        
        if (!approved) {
          _handleUnapprovedUser();
        }
      }
    } catch (e) {
      print('Error checking approval status: $e');
    } finally {
      isChecking.value = false;
    }
  }

  /// Handle unapproved user - redirect to approval page
  void _handleUnapprovedUser() {
    // Don't redirect if already on approval page or auth pages
    final currentRoute = Get.currentRoute;
    final allowedRoutes = [
      AppRoutes.adminApproval,
      AppRoutes.login,
      AppRoutes.signup,
      AppRoutes.forgotPassword,
    ];

    if (!allowedRoutes.contains(currentRoute)) {
      Get.offAllNamed(AppRoutes.adminApproval);
      
      Get.snackbar(
        'Access Restricted',
        'Your account requires admin approval to access the application.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.errorContainer,
        colorText: Get.theme.colorScheme.onErrorContainer,
        duration: const Duration(seconds: 5),
      );
    }
  }

  /// Force check approval status (for manual refresh)
  Future<void> forceCheckApproval() async {
    await _checkApprovalStatus();
  }

  /// Stop monitoring (when user logs out)
  void stopMonitoring() {
    _approvalCheckTimer?.cancel();
    _approvalCheckTimer = null;
    isApproved.value = false;
  }

  /// Start monitoring (when user logs in)
  void startMonitoring() {
    if (_approvalCheckTimer == null) {
      _startApprovalMonitoring();
    }
  }

  @override
  void onClose() {
    stopMonitoring();
    super.onClose();
  }
}