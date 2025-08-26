import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/auth_controller.dart';
import '../../../core/values/app_strings.dart';
import '../../../core/values/app_values.dart';
import '../../../data/services/supabase_auth_service.dart';

class AdminApprovalPage extends GetView<AuthController> {
  const AdminApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Approval'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppValues.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Icon(
              Icons.admin_panel_settings_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppValues.paddingLarge),
            
            // Title
            Text(
              'Account Pending Approval',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppValues.paddingSmall),
            
            Text(
              'Your account is pending admin approval. Please contact support or wait for approval.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppValues.paddingXLarge),
            
            // Contact Support Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement contact support functionality
                },
                icon: const Icon(Icons.support_outlined),
                label: const Text('Contact Support'),
              ),
            ),
            const SizedBox(height: AppValues.paddingMedium),
            
            // Refresh Status Button
            Obx(() => SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: controller.isLoading.value ? null : _checkApprovalStatus,
                icon: const Icon(Icons.refresh_outlined),
                label: controller.isLoading.value
                    ? const Text('Checking...')
                    : const Text('Check Approval Status'),
              ),
            )),
            const SizedBox(height: AppValues.paddingLarge),
            
            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  // Sign out and go back to login
                  Supabase.instance.client.auth.signOut();
                  Get.offAllNamed('/auth/login');
                },
                child: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Check approval status
  Future<void> _checkApprovalStatus() async {
    try {
      controller.isLoading.value = true;
      
      // Check if user is approved
      final approved = await SupabaseAuthService.to.isUserApproved();
      
      if (approved) {
        // Navigate to home screen
        Get.offAllNamed('/home');
      } else {
        Get.snackbar(
          'Not Approved',
          'Your account is still pending approval.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to check approval status. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
    } finally {
      controller.isLoading.value = false;
    }
  }
}