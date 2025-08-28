import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/gemini_pose_service.dart';
import '../../core/values/app_values.dart';
import '../../routes/app_routes.dart';

class PoseSuggestionsCard extends StatelessWidget {
  const PoseSuggestionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final poseService = GeminiPoseService.to;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: AppValues.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Pose Suggestions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Obx(() => Text(
                            poseService.isAvailable
                                ? 'Get creative photography pose ideas'
                                : 'Coming Soon - Configure API key to enable',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: poseService.isAvailable
                                      ? Theme.of(context).colorScheme.onSurfaceVariant
                                      : Colors.orange,
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
            Obx(() {
              if (!poseService.isAvailable) {
                return Container(
                  padding: const EdgeInsets.all(AppValues.paddingMedium),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: AppValues.paddingSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Feature Coming Soon',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add your Gemini API key to enable AI-powered pose suggestions',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.orange.shade700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(AppValues.paddingMedium),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Features',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppValues.paddingSmall),
                    _buildFeatureRow(
                      context,
                      Icons.person,
                      'Portrait poses for individuals and groups',
                    ),
                    _buildFeatureRow(
                      context,
                      Icons.landscape,
                      'Creative poses for different locations',
                    ),
                    _buildFeatureRow(
                      context,
                      Icons.mood,
                      'Mood-based pose recommendations',
                    ),
                    _buildFeatureRow(
                      context,
                      Icons.celebration,
                      'Occasion-specific pose ideas',
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppValues.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showQuickPose(context),
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Quick Pose'),
                  ),
                ),
                const SizedBox(width: AppValues.paddingMedium),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Get.toNamed(AppRoutes.poseSuggestions),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickPose(BuildContext context) async {
    final poseService = GeminiPoseService.to;
    
    if (!poseService.isAvailable) {
      Get.dialog(
        AlertDialog(
          title: const Text('Feature Not Available'),
          content: const Text(
            'AI Pose Suggestions require a Gemini API key to be configured. '
            'Please add your API key to the .env file to enable this feature.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Show loading dialog
    Get.dialog(
      const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppValues.paddingMedium),
            Text('Generating a creative pose idea...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final suggestion = await poseService.getRandomPose();
      Get.back(); // Close loading dialog

      // Show pose suggestion
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.purple),
              const SizedBox(width: 8),
              Expanded(child: Text(suggestion.title)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (suggestion.instructions.isNotEmpty) ...[
                  const SizedBox(height: AppValues.paddingMedium),
                  Text(
                    'Instructions:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppValues.paddingSmall),
                  Text(suggestion.instructions),
                ],
                if (suggestion.tips.isNotEmpty) ...[
                  const SizedBox(height: AppValues.paddingMedium),
                  Text(
                    'Tips:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppValues.paddingSmall),
                  ...suggestion.tips.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(tip)),
                          ],
                        ),
                      )),
                ],
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
                Get.toNamed(AppRoutes.poseSuggestions);
              },
              child: const Text('More Ideas'),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to generate pose suggestion: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
      );
    }
  }
}