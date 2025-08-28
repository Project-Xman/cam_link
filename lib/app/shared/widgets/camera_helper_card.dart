import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/camera_analysis_service.dart';
import '../../core/values/app_values.dart';
import '../../routes/app_routes.dart';

class CameraHelperCard extends StatelessWidget {
  const CameraHelperCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cameraService = CameraAnalysisService.to;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.camera_enhance,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: AppValues.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Camera Assistant',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Obx(() => Text(
                            cameraService.isInitialized
                                ? 'Real-time photography analysis and guidance'
                                : 'Advanced camera features and analysis',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          )),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: AppValues.paddingMedium),
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
                    'Smart Features',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppValues.paddingSmall),
                  _buildFeatureRow(
                    context,
                    Icons.thermostat,
                    'Temperature Detection',
                    'Real-time environment temperature estimation',
                  ),
                  _buildFeatureRow(
                    context,
                    Icons.camera_alt,
                    'Exposure Analysis',
                    'Optimal camera settings recommendations',
                  ),
                  _buildFeatureRow(
                    context,
                    Icons.center_focus_strong,
                    'Focus Assistant',
                    'Smart focus point analysis and guidance',
                  ),
                  _buildFeatureRow(
                    context,
                    Icons.wb_sunny,
                    'Lighting Conditions',
                    'Automatic lighting analysis and tips',
                  ),
                  _buildFeatureRow(
                    context,
                    Icons.balance,
                    'Stability Monitor',
                    'Device shake detection and warnings',
                  ),
                  _buildFeatureRow(
                    context,
                    Icons.wb_sunny,
                    'Sun Position Tracking',
                    'Real-time sun position and shadow calculations',
                  ),
                  _buildFeatureRow(
                    context,
                    Icons.cloud,
                    'Weather Integration',
                    'Live weather data for optimal photography',
                  ),
                  _buildFeatureRow(
                    context,
                    Icons.location_on,
                    'Location-Based Tips',
                    'GPS-based photography recommendations',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppValues.paddingMedium),
            Obx(() {
              if (cameraService.isInitialized) {
                final capabilities = cameraService.deviceCapabilities;
                return Container(
                  padding: const EdgeInsets.all(AppValues.paddingMedium),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device Capabilities',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppValues.paddingSmall),
                      Row(
                        children: [
                          _buildCapabilityChip(
                            context,
                            '${capabilities['cameras_count']} Cameras',
                            Icons.camera_alt,
                          ),
                          const SizedBox(width: 8),
                          if (capabilities['has_flash'])
                            _buildCapabilityChip(
                              context,
                              'Flash',
                              Icons.flash_on,
                            ),
                          const SizedBox(width: 8),
                          if (capabilities['has_stabilization'])
                            _buildCapabilityChip(
                              context,
                              'Stabilization',
                              Icons.balance,
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              } else {
                return Container(
                  padding: const EdgeInsets.all(AppValues.paddingMedium),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: AppValues.paddingSmall),
                      Expanded(
                        child: Text(
                          'Camera initialization required. Grant camera permissions to enable all features.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade700,
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            }),
            const SizedBox(height: AppValues.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showQuickAnalysis(context),
                    icon: const Icon(Icons.analytics),
                    label: const Text('Quick Analysis'),
                  ),
                ),
                const SizedBox(width: AppValues.paddingMedium),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Get.toNamed(AppRoutes.cameraHelper),
                    icon: const Icon(Icons.camera_enhance),
                    label: const Text('Open Camera'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  void _showQuickAnalysis(BuildContext context) {
    final cameraService = CameraAnalysisService.to;
    
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue),
            SizedBox(width: 8),
            Text('Quick Camera Analysis'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device Information',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Obx(() {
                final capabilities = cameraService.deviceCapabilities;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Available Cameras', '${capabilities['cameras_count']}'),
                    _buildInfoRow('Flash Support', capabilities['has_flash'] ? 'Yes' : 'No'),
                    _buildInfoRow('Front Camera', capabilities['has_front_camera'] ? 'Yes' : 'No'),
                    _buildInfoRow('Back Camera', capabilities['has_back_camera'] ? 'Yes' : 'No'),
                    _buildInfoRow('Stabilization', capabilities['has_stabilization'] ? 'Yes' : 'No'),
                    _buildInfoRow('Max Resolution', capabilities['max_resolution']),
                  ],
                );
              }),
              const SizedBox(height: 16),
              Text(
                'Current Status',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Service Status', cameraService.isInitialized ? 'Ready' : 'Initializing'),
                      _buildInfoRow('Camera Active', cameraService.isCameraActive ? 'Yes' : 'No'),
                      _buildInfoRow('Analysis Running', cameraService.isAnalyzing ? 'Yes' : 'No'),
                      if (cameraService.isCameraActive)
                        _buildInfoRow('Current Camera', cameraService.currentCameraInfo),
                    ],
                  )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Pro Tips',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Tap anywhere on screen to set focus point\n'
                      '• Watch temperature for optimal device performance\n'
                      '• Use stability indicator to avoid blurry photos\n'
                      '• Follow lighting recommendations for best results',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              Get.toNamed(AppRoutes.cameraHelper);
            },
            child: const Text('Open Camera Helper'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}