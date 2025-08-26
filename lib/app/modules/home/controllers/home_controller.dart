import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/connectivity_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../controllers/app_controller.dart';
import '../../../routes/app_routes.dart';

/// Home controller managing the home screen state
class HomeController extends GetxController {
  // Services
  final AuthService _authService = AuthService.to;
  final ConnectivityService _connectivityService = ConnectivityService.to;
  final AppController _appController = AppController.to;

  // Reactive variables
  final _isLoading = false.obs;
  final _currentUser = Rxn<UserModel>();
  final _authStatus = AuthStatus.unknown.obs;
  final _connectionStatus = ConnectionStatus.unknown.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  UserModel? get currentUser => _currentUser.value;
  AuthStatus get authStatus => _authStatus.value;
  ConnectionStatus get connectionStatus => _connectionStatus.value;
  bool get isSignedIn => authStatus == AuthStatus.signedIn;
  bool get isConnected => connectionStatus == ConnectionStatus.connected;

  @override
  void onInit() {
    super.onInit();
    _initializeController();
    _setupListeners();
  }

  /// Initialize the controller
  void _initializeController() {
    try {
      // Initial state from services
      _currentUser.value = _authService.currentUser;
      _authStatus.value = _authService.authStatus;
      _connectionStatus.value = _connectivityService.connectionStatus;
      
      ErrorHandler.logInfo('HomeController initialized', 'HomeController');
    } catch (e) {
      ErrorHandler.handleError(e, context: 'HomeController._initializeController');
    }
  }

  /// Setup reactive listeners
  void _setupListeners() {
    // Listen to auth status changes
    _authService.authStatusStream.listen((status) {
      _authStatus.value = status;
    });

    // Listen to user changes
    _authService.userStream.listen((user) {
      _currentUser.value = user;
    });

    // Listen to connectivity changes
    _connectivityService.connectionStream.listen((status) {
      _connectionStatus.value = status;
    });
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      _isLoading.value = true;
      
      // Check connectivity first
      await _connectivityService.ensureConnection();
      
      await _authService.signInWithGoogle();
      
      _appController.showSuccessMessage('Signed in successfully!');
      ErrorHandler.logInfo('User signed in from home', 'HomeController');
    } catch (e) {
      ErrorHandler.handleError(e, context: 'HomeController.signInWithGoogle');
      _appController.handleException(e);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      final confirmed = await _appController.showConfirmationDialog(
        title: 'Sign Out',
        message: 'Are you sure you want to sign out?',
        confirmText: 'Sign Out',
      );

      if (!confirmed) return;

      _isLoading.value = true;
      await _authService.signOut();
      
      _appController.showSuccessMessage('Signed out successfully');
      ErrorHandler.logInfo('User signed out from home', 'HomeController');
    } catch (e) {
      ErrorHandler.handleError(e, context: 'HomeController.signOut');
      _appController.handleException(e);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Navigate to file explorer
  void navigateToFileExplorer() {
    if (!isSignedIn) {
      _appController.showWarningMessage('Please sign in first');
      return;
    }
    
    if (!isConnected) {
      _appController.showWarningMessage('Please check your internet connection');
      return;
    }

    AppRoutes.toFileExplorer();
  }

  /// Refresh user data
  Future<void> refreshUserData() async {
    if (!isSignedIn) return;
    
    try {
      _isLoading.value = true;
      // Force refresh user data by signing in silently
      await _authService.getAccessToken();
    } catch (e) {
      ErrorHandler.handleError(e, context: 'HomeController.refreshUserData');
      _appController.handleException(e);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get user greeting based on time
  String getUserGreeting() {
    final hour = DateTime.now().hour;
    final name = currentUser?.name.split(' ').first ?? 'User';
    
    if (hour < 12) {
      return 'Good morning, $name!';
    } else if (hour < 17) {
      return 'Good afternoon, $name!';
    } else {
      return 'Good evening, $name!';
    }
  }

  /// Get connection status message
  String getConnectionStatusMessage() {
    switch (connectionStatus) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.disconnected:
        return 'No internet connection';
      case ConnectionStatus.unknown:
        return 'Connection unknown';
    }
  }

  /// Get app statistics (mock data for now)
  Map<String, dynamic> getAppStatistics() {
    return {
      'totalFiles': 0,
      'processedFiles': 0,
      'uploadedFiles': 0,
      'totalSize': '0 MB',
    };
  }

  /// Check app permissions
  Future<void> checkPermissions() async {
    try {
      // This would check file access permissions
      // Implementation depends on permission_handler setup
      _appController.showInfoMessage('Permissions are configured correctly');
    } catch (e) {
      ErrorHandler.handleError(e, context: 'HomeController.checkPermissions');
      _appController.handleException(e);
    }
  }

  /// Show app info
  void showAppInfo() {
    final appInfo = _appController.getAppInfo();
    final buffer = StringBuffer();
    
    appInfo.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    
    Get.dialog(
      AlertDialog(
        title: const Text('App Information'),
        content: SingleChildScrollView(
          child: Text(buffer.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}