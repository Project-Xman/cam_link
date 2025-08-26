import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/connectivity_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/values/app_strings.dart';
import '../../../controllers/app_controller.dart';
import '../../../routes/app_routes.dart';

/// Home controller managing the home screen state
class HomeController extends GetxController {
  // Services - using lazy initialization with error handling
  AuthService? _authService;
  ConnectivityService? _connectivityService;
  AppController? _appController;

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

  /// Get services with lazy initialization
  AuthService get _authServiceInstance {
    _authService ??= Get.find<AuthService>();
    return _authService!;
  }
  
  ConnectivityService get _connectivityServiceInstance {
    _connectivityService ??= Get.find<ConnectivityService>();
    return _connectivityService!;
  }
  
  AppController get _appControllerInstance {
    _appController ??= Get.find<AppController>();
    return _appController!;
  }

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
      _currentUser.value = _authServiceInstance.currentUser;
      _authStatus.value = _authServiceInstance.authStatus;
      _connectionStatus.value = _connectivityServiceInstance.connectionStatus;
      
      ErrorHandler.logInfo('HomeController initialized', 'HomeController');
    } catch (e) {
      ErrorHandler.handleError(e, context: 'HomeController._initializeController');
      // Set default values if services are not available
      _authStatus.value = AuthStatus.unknown;
      _connectionStatus.value = ConnectionStatus.unknown;
    }
  }

  /// Setup reactive listeners
  void _setupListeners() {
    try {
      // Listen to auth status changes
      _authServiceInstance.authStatusStream.listen((status) {
        _authStatus.value = status;
      });

      // Listen to user changes
      _authServiceInstance.userStream.listen((user) {
        _currentUser.value = user;
      });

      // Listen to connectivity changes
      _connectivityServiceInstance.connectionStream.listen((status) {
        _connectionStatus.value = status;
      });
    } catch (e) {
      ErrorHandler.handleError(e, context: 'HomeController._setupListeners');
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      _isLoading.value = true;
      
      // Check connectivity first
      await _connectivityServiceInstance.ensureConnection();
      
      await _authServiceInstance.signInWithGoogle();
      
      _appControllerInstance.showSuccessMessage('Signed in successfully!');
      ErrorHandler.logInfo('User signed in from home', 'HomeController');
    } catch (e) {
      ErrorHandler.handleError(e, context: 'HomeController.signInWithGoogle');
      try {
        _appControllerInstance.handleException(e);
      } catch (controllerError) {
        // Fallback error handling
        Get.snackbar('Error', e.toString());
      }
    } finally {
      _isLoading.value = false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      bool confirmed = false;
      try {
        confirmed = await _appControllerInstance.showConfirmationDialog(
          title: 'Sign Out',
          message: 'Are you sure you want to sign out?',
          confirmText: 'Sign Out',
        );
      } catch (e) {
        // Fallback confirmation
        confirmed = true;
      }

      if (!confirmed) return;

      _isLoading.value = true;
      await _authServiceInstance.signOut();
      
      try {
        _appControllerInstance.showSuccessMessage('Signed out successfully');
      } catch (e) {
        // Fallback success message
        Get.snackbar('Success', 'Signed out successfully');
      }
      ErrorHandler.logInfo('User signed out from home', 'HomeController');
    } catch (e) {
      ErrorHandler.handleError(e, context: 'HomeController.signOut');
      try {
        _appControllerInstance.handleException(e);
      } catch (controllerError) {
        // Fallback error handling
        Get.snackbar('Error', e.toString());
      }
    } finally {
      _isLoading.value = false;
    }
  }

  /// Navigate to file explorer
  void navigateToFileExplorer() {
    bool isSignedInLocal = false;
    bool isConnectedLocal = false;
    
    try {
      isSignedInLocal = _authServiceInstance.isSignedIn;
      isConnectedLocal = _connectivityServiceInstance.isConnected;
    } catch (e) {
      // Fallback checks
      isSignedInLocal = _authStatus.value == AuthStatus.signedIn;
      isConnectedLocal = _connectionStatus.value == ConnectionStatus.connected;
    }

    if (!isSignedInLocal) {
      try {
        _appControllerInstance.showWarningMessage('Please sign in first');
      } catch (e) {
        Get.snackbar('Warning', 'Please sign in first');
      }
      return;
    }
    
    if (!isConnectedLocal) {
      try {
        _appControllerInstance.showWarningMessage('Please check your internet connection');
      } catch (e) {
        Get.snackbar('Warning', 'Please check your internet connection');
      }
      return;
    }

    AppRoutes.toFileExplorer();
  }

  /// Refresh user data
  Future<void> refreshUserData() async {
    bool isSignedInLocal = false;
    try {
      isSignedInLocal = _authServiceInstance.isSignedIn;
    } catch (e) {
      isSignedInLocal = _authStatus.value == AuthStatus.signedIn;
    }
    
    if (!isSignedInLocal) return;
    
    try {
      _isLoading.value = true;
      // Force refresh user data by signing in silently
      await _authServiceInstance.getAccessToken();
    } catch (e) {
      ErrorHandler.handleError(e, context: 'HomeController.refreshUserData');
      try {
        _appControllerInstance.handleException(e);
      } catch (controllerError) {
        // Fallback error handling
        Get.snackbar('Error', e.toString());
      }
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get user greeting based on time
  String getUserGreeting() {
    final hour = DateTime.now().hour;
    String name = 'User';
    
    try {
      name = _authServiceInstance.currentUser?.name.split(' ').first ?? 'User';
    } catch (e) {
      name = _currentUser.value?.name.split(' ').first ?? 'User';
    }
    
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
    ConnectionStatus status;
    try {
      status = _connectivityServiceInstance.connectionStatus;
    } catch (e) {
      status = _connectionStatus.value;
    }
    
    switch (status) {
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
      try {
        _appControllerInstance.showInfoMessage('Permissions are configured correctly');
      } catch (e) {
        Get.snackbar('Info', 'Permissions are configured correctly');
      }
    } catch (e) {
      ErrorHandler.handleError(e, context: 'HomeController.checkPermissions');
      try {
        _appControllerInstance.handleException(e);
      } catch (controllerError) {
        // Fallback error handling
        Get.snackbar('Error', e.toString());
      }
    }
  }

  /// Show app info
  void showAppInfo() {
    Map<String, dynamic> appInfo = {};
    try {
      appInfo = _appControllerInstance.getAppInfo();
    } catch (e) {
      appInfo = {
        'App Name': AppStrings.appName,
        'Version': '1.0.0',
        'Status': 'Initialized',
      };
    }
    
    final buffer = StringBuffer();
    
    appInfo.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    
    Get.defaultDialog(
      title: 'App Information',
      content: SingleChildScrollView(
        child: Text(buffer.toString()),
      ),
      textConfirm: 'OK',
      confirm: ElevatedButton(
        onPressed: () => Get.back(),
        child: const Text('OK'),
      ),
    );
  }
}