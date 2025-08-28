import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'appwrite_auth_service.dart';
import '../../routes/app_routes.dart';

/// Service to monitor user approval status in real-time
class ApprovalService extends GetxService {
  static ApprovalService get to => Get.find();

  late final AppwriteAuthService _authService;
  Timer? _approvalCheckTimer;
  Timer? _debounceTimer;
  
  // Reactive variables
  final isApproved = false.obs;
  final isChecking = false.obs;
  
  // Check interval (in seconds)
  static const int checkInterval = 60;
  
  // Debounce duration to prevent rapid status changes
  static const Duration debounceDuration = Duration(milliseconds: 5000);

  @override
  void onInit() {
    super.onInit();
    _authService = AppwriteAuthService.to;
    _initializeService();
  }

  /// Initialize the service asynchronously
  Future<void> _initializeService() async {
    await _initializeApprovalStatus();
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

  /// Initialize approval status from current user
  Future<void> _initializeApprovalStatus() async {
    if (_authService.isAuthenticated) {
      // Do an initial check to get the real status from database
      await _checkApprovalStatus();
    } else {
      isApproved.value = false;
    }
  }

  /// Check current user approval status
  Future<void> _checkApprovalStatus() async {
    if (!_authService.isAuthenticated) {
      isApproved.value = false;
      _authService.updateCurrentUserApprovalStatus(false);
      return;
    }

    try {
      isChecking.value = true;
      final approved = await _authService.isUserApproved();
      
      // Update status immediately during initialization or force check
      if (isApproved.value != approved) {
        isApproved.value = approved;
        _authService.updateCurrentUserApprovalStatus(approved);
        
        // Only use debounce for automatic periodic checks, not for force checks
        if (_approvalCheckTimer != null) {
          _debounceStatusUpdate(approved);
        }
      }
    } catch (e) {
      debugPrint('Error checking approval status: $e');
    } finally {
      isChecking.value = false;
    }
  }

  /// Handle approved user - redirect to home page
  void _handleApprovedUser() {
    final currentRoute = Get.currentRoute;
    
    // If user is on admin approval page, redirect to home
    if (currentRoute == AppRoutes.adminApproval) {
      Get.offAllNamed(AppRoutes.home);
      
      Get.snackbar(
        'Account Approved!',
        'Your account has been approved. Welcome to the application!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
        colorText: Get.theme.colorScheme.onPrimaryContainer,
        duration: const Duration(seconds: 5),
      );
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

  /// Debounce status updates to prevent flickering
  void _debounceStatusUpdate(bool approved) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () async {
      final wasApproved = isApproved.value;
      
      // Only handle navigation changes, not status updates (those are handled immediately)
      if (approved && !wasApproved) {
        // User just got approved - navigate to home
        _handleApprovedUser();
      } else if (!approved && wasApproved) {
        // User approval was revoked - handle accordingly
        _handleUnapprovedUser();
      }
    });
  }

  /// Force check approval status (for manual refresh)
  Future<void> forceCheckApproval() async {
    await _checkApprovalStatus();
    // Wait a bit to ensure the status is properly updated
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Stop monitoring (when user logs out)
  void stopMonitoring() {
    _approvalCheckTimer?.cancel();
    _approvalCheckTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    isApproved.value = false;
  }

  /// Start monitoring (when user logs in)
  void startMonitoring() {
    if (_approvalCheckTimer == null) {
      _startApprovalMonitoring();
    }
  }

  /// Get current approval status synchronously
  bool get currentApprovalStatus => isApproved.value;

  @override
  void onClose() {
    stopMonitoring();
    super.onClose();
  }
}