import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/values/app_strings.dart';
import '../../controllers/app_controller.dart';
import '../../data/services/google_oauth_service.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/supabase_auth_service.dart';
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
        final supabaseAuthService = Get.find<SupabaseAuthService>();
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
        // Check Supabase auth status
        final supabaseAuth = Supabase.instance.client.auth;
        final session = supabaseAuth.currentSession;
        
        if (session != null) {
          // Check if user is approved
          final supabaseAuthService = Get.find<SupabaseAuthService>();
          final approved = await supabaseAuthService.isUserApproved();
          
          if (approved) {
            // User is authenticated and approved
            AppRoutes.toHome();
          } else {
            // User is authenticated but not approved
            AppRoutes.toAdminApproval();
          }
        } else {
          // User is not authenticated
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Icon(
              Icons.cloud_upload_outlined,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            // App name
            const Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
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