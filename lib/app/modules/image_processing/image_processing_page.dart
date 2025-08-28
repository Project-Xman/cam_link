import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/image_processing_controller.dart';
import '../../core/values/app_values.dart';
import '../../shared/widgets/loading_widget.dart';

/// Image processing page for resizing and adding overlays
class ImageProcessingPage extends GetView<ImageProcessingController> {
  const ImageProcessingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Processing'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          Obx(() => controller.selectedImages.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: controller.clearAllImages,
                  tooltip: 'Clear All',
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingWidget(message: 'Processing images...');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppValues.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSelectionSection(context),
              const SizedBox(height: AppValues.paddingLarge),
              if (controller.selectedImages.isNotEmpty) ...[
                _buildProcessingOptionsSection(context),
                const SizedBox(height: AppValues.paddingLarge),
                _buildSelectedImagesSection(context),
                const SizedBox(height: AppValues.paddingLarge),
                _buildActionButtons(context),
              ],
            ],
          ),
        );
      }),
    );
  }

  /// Build image selection section
  Widget _buildImageSelectionSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppValues.paddingSmall),
                Text(
                  'Select Images',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppValues.paddingMedium),
            Text(
              'Choose images to process. You can select multiple images at once.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppValues.paddingLarge),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: controller.selectImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Select from Gallery'),
                  ),
                ),
                const SizedBox(width: AppValues.paddingMedium),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.selectFromFileExplorer,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Browse Files'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build processing options section
  Widget _buildProcessingOptionsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppValues.paddingSmall),
                Text(
                  'Processing Options',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppValues.paddingLarge),
            
            // Resize options
            _buildResizeOptions(context),
            const SizedBox(height: AppValues.paddingLarge),
            
            // Overlay options
            _buildOverlayOptions(context),
            const SizedBox(height: AppValues.paddingLarge),
            
            // Quality options
            _buildQualityOptions(context),
          ],
        ),
      ),
    );
  }

  /// Build resize options
  Widget _buildResizeOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resize Options',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppValues.paddingMedium),
        Obx(() => SwitchListTile(
              title: const Text('Enable Resize'),
              subtitle: const Text('Resize images to specified dimensions'),
              value: controller.enableResize.value,
              onChanged: controller.toggleResize,
            )),
        Obx(() => controller.enableResize.value
            ? Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller.widthController,
                          decoration: const InputDecoration(
                            labelText: 'Width (px)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppValues.paddingMedium),
                      Expanded(
                        child: TextFormField(
                          controller: controller.heightController,
                          decoration: const InputDecoration(
                            labelText: 'Height (px)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppValues.paddingMedium),
                  Obx(() => CheckboxListTile(
                        title: const Text('Maintain Aspect Ratio'),
                        subtitle: const Text('Keep original proportions'),
                        value: controller.maintainAspectRatio.value,
                        onChanged: controller.toggleAspectRatio,
                      )),
                ],
              )
            : const SizedBox.shrink()),
      ],
    );
  }

  /// Build overlay options
  Widget _buildOverlayOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overlay Options',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppValues.paddingMedium),
        Obx(() => SwitchListTile(
              title: const Text('Add Text Overlay'),
              subtitle: const Text('Add custom text to images'),
              value: controller.enableTextOverlay.value,
              onChanged: controller.toggleTextOverlay,
            )),
        Obx(() => controller.enableTextOverlay.value
            ? Column(
                children: [
                  TextFormField(
                    controller: controller.overlayTextController,
                    decoration: const InputDecoration(
                      labelText: 'Overlay Text',
                      border: OutlineInputBorder(),
                      hintText: 'Enter text to overlay on images',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppValues.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: controller.overlayPosition.value,
                          decoration: const InputDecoration(
                            labelText: 'Position',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'topLeft', child: Text('Top Left')),
                            DropdownMenuItem(value: 'topRight', child: Text('Top Right')),
                            DropdownMenuItem(value: 'bottomLeft', child: Text('Bottom Left')),
                            DropdownMenuItem(value: 'bottomRight', child: Text('Bottom Right')),
                            DropdownMenuItem(value: 'center', child: Text('Center')),
                          ],
                          onChanged: controller.setOverlayPosition,
                        ),
                      ),
                      const SizedBox(width: AppValues.paddingMedium),
                      Expanded(
                        child: TextFormField(
                          controller: controller.fontSizeController,
                          decoration: const InputDecoration(
                            labelText: 'Font Size',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : const SizedBox.shrink()),
      ],
    );
  }

  /// Build quality options
  Widget _buildQualityOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quality Options',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppValues.paddingMedium),
        Obx(() => Column(
              children: [
                Text('Quality: ${(controller.imageQuality.value * 100).round()}%'),
                Slider(
                  value: controller.imageQuality.value,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: '${(controller.imageQuality.value * 100).round()}%',
                  onChanged: controller.setImageQuality,
                ),
              ],
            )),
      ],
    );
  }

  /// Build selected images section
  Widget _buildSelectedImagesSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppValues.paddingSmall),
                Text(
                  'Selected Images (${controller.selectedImages.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppValues.paddingMedium),
            Obx(() => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppValues.paddingSmall,
                    mainAxisSpacing: AppValues.paddingSmall,
                  ),
                  itemCount: controller.selectedImages.length,
                  itemBuilder: (context, index) {
                    final image = controller.selectedImages[index];
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              image.bytes,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => controller.removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: controller.previewProcessing,
            icon: const Icon(Icons.preview),
            label: const Text('Preview'),
          ),
        ),
        const SizedBox(width: AppValues.paddingMedium),
        Expanded(
          child: FilledButton.icon(
            onPressed: controller.processImages,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Process Images'),
          ),
        ),
      ],
    );
  }
}