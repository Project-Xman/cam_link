import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/google_drive_service.dart';
import '../../core/values/app_values.dart';

/// Widget to display Google Drive connection status and available drives
class GoogleDriveWidget extends GetView<GoogleDriveService> {
  const GoogleDriveWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppValues.paddingSmall),
                Text(
                  'Google Drive',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Obx(() => controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: AppValues.paddingMedium),
            
            Obx(() {
              if (!controller.platformSupported.value) {
                return _buildPlatformNotSupportedState(context);
              } else if (!controller.isConnected.value) {
                return _buildDisconnectedState(context);
              } else {
                return _buildConnectedState(context);
              }
            }),
          ],
        ),
      ),
    );
  }

  /// Build disconnected state UI
  Widget _buildDisconnectedState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Not connected to Google Drive',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppValues.paddingMedium),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () async {
              try {
                await controller.signInToGoogleDrive();
              } catch (e) {
                Get.snackbar(
                  'Connection Error',
                  e.toString(),
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Get.theme.colorScheme.errorContainer,
                );
              }
            },
            icon: const Icon(Icons.login),
            label: const Text('Connect to Google Drive'),
          ),
        ),
      ],
    );
  }

  /// Build connected state UI
  Widget _buildConnectedState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Connection status
        Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 16,
            ),
            const SizedBox(width: AppValues.paddingSmall),
            Text(
              'Connected as ${controller.currentUser?.displayName ?? 'Unknown'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppValues.paddingMedium),
        
        // Available drives
        Obx(() {
          if (controller.availableDrives.isEmpty) {
            return const Text('Loading drives...');
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Drives:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppValues.paddingSmall),
              
              // Drive selection dropdown
              DropdownButtonFormField<String>(
                value: controller.currentDrive.value?.id,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppValues.paddingMedium,
                    vertical: AppValues.paddingSmall,
                  ),
                ),
                items: controller.availableDrives.map((drive) {
                  return DropdownMenuItem<String>(
                    value: drive.id,
                    child: Row(
                      children: [
                        Icon(
                          drive.id == 'my-drive' 
                            ? Icons.folder_special 
                            : Icons.folder_shared,
                          size: 16,
                        ),
                        const SizedBox(width: AppValues.paddingSmall),
                        Expanded(
                          child: Text(
                            drive.name ?? 'Unknown Drive',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? driveId) {
                  if (driveId != null) {
                    final selectedDrive = controller.availableDrives
                        .firstWhere((drive) => drive.id == driveId);
                    controller.selectDrive(selectedDrive);
                  }
                },
              ),
              const SizedBox(height: AppValues.paddingMedium),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.loadAvailableDrives,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ),
                  const SizedBox(width: AppValues.paddingSmall),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        try {
                          await controller.signOutFromGoogleDrive();
                        } catch (e) {
                          Get.snackbar(
                            'Disconnect Error',
                            e.toString(),
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Get.theme.colorScheme.errorContainer,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Disconnect'),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Build platform not supported state UI
  Widget _buildPlatformNotSupportedState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning,
              color: Theme.of(context).colorScheme.error,
              size: 16,
            ),
            const SizedBox(width: AppValues.paddingSmall),
            Expanded(
              child: Text(
                'Google Drive integration is not available on this platform',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppValues.paddingSmall),
        Text(
          'Please use a supported device (Android, iOS, macOS, or Web) to access Google Drive features.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}