import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../data/services/hotspot_service.dart';
import '../../core/values/app_values.dart';

class HotspotCard extends StatelessWidget {
  const HotspotCard({super.key});

  @override
  Widget build(BuildContext context) {
    final hotspotService = HotspotService.to;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wifi_tethering,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: AppValues.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mobile Hotspot',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Obx(() => Text(
                            hotspotService.isHotspotEnabled
                                ? 'Active - ${hotspotService.hotspotName}'
                                : 'Inactive',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: hotspotService.isHotspotEnabled
                                      ? Colors.green
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          )),
                    ],
                  ),
                ),
                Obx(() => Switch(
                      value: hotspotService.isHotspotEnabled,
                      onChanged: hotspotService.isLoading
                          ? null
                          : (_) => hotspotService.toggleHotspot(),
                    )),
              ],
            ),
            const SizedBox(height: AppValues.paddingMedium),
            Obx(() {
              if (hotspotService.isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppValues.paddingMedium),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              return Column(
                children: [
                  if (hotspotService.isHotspotEnabled) ...[
                    Container(
                      padding: const EdgeInsets.all(AppValues.paddingMedium),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hotspot Details',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppValues.paddingSmall),
                          _buildDetailRow(
                            context,
                            'Network Name',
                            hotspotService.hotspotName,
                            onTap: () => _copyToClipboard(
                              hotspotService.hotspotName,
                              'Network name copied',
                            ),
                          ),
                          _buildDetailRow(
                            context,
                            'Password',
                            hotspotService.hotspotPassword,
                            onTap: () => _copyToClipboard(
                              hotspotService.hotspotPassword,
                              'Password copied',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppValues.paddingMedium),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showConfigurationDialog(context),
                          icon: const Icon(Icons.settings),
                          label: const Text('Configure'),
                        ),
                      ),
                      const SizedBox(width: AppValues.paddingMedium),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: hotspotService.isLoading
                              ? null
                              : () => hotspotService.toggleHotspot(),
                          icon: Icon(
                            hotspotService.isHotspotEnabled
                                ? Icons.stop
                                : Icons.play_arrow,
                          ),
                          label: Text(
                            hotspotService.isHotspotEnabled ? 'Stop' : 'Start',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.copy,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _showConfigurationDialog(BuildContext context) {
    final hotspotService = HotspotService.to;
    final nameController = TextEditingController(text: hotspotService.hotspotName);
    final passwordController = TextEditingController(text: hotspotService.hotspotPassword);

    Get.dialog(
      AlertDialog(
        title: const Text('Hotspot Configuration'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Network Name',
                  hintText: 'Enter hotspot name',
                  border: OutlineInputBorder(),
                ),
                maxLength: 32,
              ),
              const SizedBox(height: AppValues.paddingMedium),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter password (min 8 characters)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                maxLength: 63,
              ),
              const SizedBox(height: AppValues.paddingSmall),
              Text(
                'Note: Changes will restart the hotspot if currently active',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final password = passwordController.text.trim();
              
              if (name.isNotEmpty && password.length >= 8) {
                hotspotService.updateConfiguration(
                  name: name,
                  password: password,
                );
                Get.back();
              } else {
                Get.snackbar(
                  'Invalid Input',
                  'Name cannot be empty and password must be at least 8 characters',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}