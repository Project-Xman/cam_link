import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/values/app_strings.dart';
import '../../../core/values/app_values.dart';
import '../../../data/services/appwrite_auth_service.dart';
import '../../../data/services/approval_service.dart';

class AdminApprovalPage extends GetView<AuthController> {
  const AdminApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Refresh user data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await AppwriteAuthService.to.refreshUserData();
      } catch (e) {
        // Silently handle refresh errors
      }
    });
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
              'Your account has been created successfully but requires admin approval before you can access the application.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppValues.paddingMedium),
            
            // User Info Card
            Obx(() => Card(
              child: Padding(
                padding: const EdgeInsets.all(AppValues.paddingMedium),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppValues.paddingSmall),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account Details',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                AppwriteAuthService.to.currentUser?.email ?? 'No email',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                AppwriteAuthService.to.currentUser?.name ?? 'No name',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
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
            
            // Real-time Status Display
            Obx(() {
              try {
                final approvalService = ApprovalService.to;
                return Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(AppValues.paddingMedium),
                    child: Row(
                      children: [
                        Icon(
                          approvalService.isChecking.value 
                            ? Icons.hourglass_empty 
                            : Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppValues.paddingSmall),
                        Expanded(
                          child: Text(
                            approvalService.isChecking.value
                              ? 'Checking approval status...'
                              : 'Status is checked automatically every 30 seconds',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } catch (e) {
                return const SizedBox.shrink();
              }
            }),
            const SizedBox(height: AppValues.paddingMedium),
            
            // Manual Refresh Button
            Obx(() => SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: controller.isLoading.value ? null : _checkApprovalStatus,
                icon: const Icon(Icons.refresh_outlined),
                label: controller.isLoading.value
                    ? const Text('Checking...')
                    : const Text('Check Now'),
              ),
            )),
            const SizedBox(height: AppValues.paddingLarge),
            
            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  // Sign out and go back to login
                  AppwriteAuthService.to.signOut();
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
      
      // Force check through approval service
      try {
        final approvalService = ApprovalService.to;
        await approvalService.forceCheckApproval();
      } catch (e) {
        // Fallback to direct check
        final isApproved = await AppwriteAuthService.to.isUserApproved();
        
        if (isApproved) {
          // User is now approved - navigate to home screen
          Get.offAllNamed('/home');
          return;
        }
      }
      
      Get.snackbar(
        'Status Updated',
        'Approval status has been refreshed.',
        snackPosition: SnackPosition.BOTTOM,
      );
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