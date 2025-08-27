import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/values/app_strings.dart';
import '../../controllers/app_controller.dart';
import '../../data/services/google_oauth_service.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/appwrite_auth_service.dart';
import '../../routes/app_routes.dart';

/// Splash screen to initialize app services
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize app services and navigate to appropriate screen
  Future<void> _initializeApp() async {
    try {
      // Add a small delay to show the splash screen
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Ensure all services are initialized by waiting for them to be available
      await _waitForServices();
      
      // Check authentication status
      await _checkAuthStatus();
    } catch (e) {
      // Handle initialization errors
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to initialize app: ${e.toString()}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        
        // Navigate to login as fallback
        if (mounted) {
          AppRoutes.toLogin();
        }
      }
    }
  }

  /// Wait for all required services to be available
  Future<void> _waitForServices() async {
    const maxAttempts = 20; // 10 seconds with 500ms delays
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      try {
        // Check if all services are available
        final storageService = Get.find<StorageService>();
        final connectivityService = Get.find<ConnectivityService>();
        final authService = Get.find<AuthService>();
        final appwriteAuthService = Get.find<AppwriteAuthService>();
        final appController = Get.find<AppController>();
        
        // If we get here, all services are available
        return;
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) {
          throw Exception('Services failed to initialize after $maxAttempts attempts');
        }
        // Wait before trying again
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  /// Check authentication status and navigate accordingly
  Future<void> _checkAuthStatus() async {
    if (mounted) {
      try {
        // Check Appwrite auth status
        final appwriteAuth = AppwriteAuthService.to;
        
        if (appwriteAuth.isAuthenticated) {
          // User is authenticated, check approval status
          final currentUser = appwriteAuth.currentUser;
          
          // In a real implementation, you would check a custom user status field
          // For now, we'll use the approved field from the UserModel
          if (currentUser != null && currentUser.approved) {
            // User is authenticated and approved - route to home page
            AppRoutes.toHome();
          } else {
            // User is authenticated but not approved - route to admin approval page
            AppRoutes.toAdminApproval();
          }
        } else {
          // User is not authenticated - route to login page
          AppRoutes.toLogin();
        }
      } catch (e) {
        // Navigate to login on error
        AppRoutes.toLogin();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Icon(
              Icons.cloud_upload_outlined,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            // App name
            Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 30),
            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              'Initializing...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}