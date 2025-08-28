import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/upload_manager_controller.dart';
import '../../core/values/app_values.dart';
import '../../shared/widgets/loading_widget.dart';


/// Upload manager page for uploading processed images to cloud storage
class UploadManagerPage extends GetView<UploadManagerController> {
  const UploadManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Manager'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          Obx(() => controller.hasImages
              ? IconButton(
                  icon: const Icon(Icons.cloud_upload),
                  onPressed: controller.isUploading.value ? null : controller.uploadAll,
                  tooltip: 'Upload All',
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && !controller.hasImages) {
          return const LoadingWidget(message: 'Loading images...');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppValues.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUploadOptionsSection(context),
              const SizedBox(height: AppValues.paddingLarge),
              if (controller.hasImages) ...[
                _buildImagesSection(context),
                const SizedBox(height: AppValues.paddingLarge),
                _buildUploadProgressSection(context),
                const SizedBox(height: AppValues.paddingLarge),
                _buildActionButtons(context),
              ] else
                _buildEmptyState(context),
            ],
          ),
        );
      }),
    );
  }

  /// Build upload options section
  Widget _buildUploadOptionsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_upload,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppValues.paddingSmall),
                Text(
                  'Upload Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppValues.paddingLarge),
            
            // Destination folder
            TextFormField(
              controller: controller.folderNameController,
              decoration: const InputDecoration(
                labelText: 'Destination Folder',
                border: OutlineInputBorder(),
                hintText: 'Enter folder name for uploads',
                prefixIcon: Icon(Icons.folder),
              ),
            ),
            const SizedBox(height: AppValues.paddingMedium),
            
            // Upload options
            Obx(() => CheckboxListTile(
                  title: const Text('Create date-based subfolders'),
                  subtitle: const Text('Organize uploads by date'),
                  value: controller.createDateFolders.value,
                  onChanged: controller.toggleDateFolders,
                )),
            Obx(() => CheckboxListTile(
                  title: const Text('Overwrite existing files'),
                  subtitle: const Text('Replace files with same name'),
                  value: controller.overwriteExisting.value,
                  onChanged: controller.toggleOverwrite,
                )),
            Obx(() => CheckboxListTile(
                  title: const Text('Add timestamp to filenames'),
                  subtitle: const Text('Prevent naming conflicts'),
                  value: controller.addTimestamp.value,
                  onChanged: controller.toggleTimestamp,
                )),
          ],
        ),
      ),
    );
  }

  /// Build images section
  Widget _buildImagesSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo_library,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppValues.paddingSmall),
                Text(
                  'Images to Upload (${controller.images.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: controller.selectMoreImages,
                  icon: const Icon(Icons.add),
                  label: const Text('Add More'),
                ),
              ],
            ),
            const SizedBox(height: AppValues.paddingMedium),
            Obx(() => ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.images.length,
                  itemBuilder: (context, index) {
                    final image = controller.images[index];
                    final uploadStatus = controller.uploadStatuses[index];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppValues.paddingSmall),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            image.bytes,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          image.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Size: ${image.formattedSize}'),
                            if (uploadStatus.isUploading)
                              LinearProgressIndicator(
                                value: uploadStatus.progress,
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildUploadStatusIcon(uploadStatus),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => controller.removeImage(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }

  /// Build upload status icon
  Widget _buildUploadStatusIcon(UploadStatus status) {
    switch (status.status) {
      case UploadState.pending:
        return const Icon(Icons.schedule, color: Colors.grey);
      case UploadState.uploading:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case UploadState.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case UploadState.failed:
        return const Icon(Icons.error, color: Colors.red);
    }
  }

  /// Build upload progress section
  Widget _buildUploadProgressSection(BuildContext context) {
    return Obx(() {
      if (!controller.isUploading.value && !controller.hasCompletedUploads) {
        return const SizedBox.shrink();
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppValues.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.upload,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppValues.paddingSmall),
                  Text(
                    'Upload Progress',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppValues.paddingMedium),
              
              // Overall progress
              Text('Overall Progress: ${controller.completedUploads}/${controller.totalImages}'),
              const SizedBox(height: AppValues.paddingSmall),
              LinearProgressIndicator(
                value: controller.overallProgress,
              ),
              const SizedBox(height: AppValues.paddingMedium),
              
              // Upload statistics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    'Completed',
                    controller.completedUploads.toString(),
                    Colors.green,
                    Icons.check_circle,
                  ),
                  _buildStatCard(
                    'Failed',
                    controller.failedUploads.toString(),
                    Colors.red,
                    Icons.error,
                  ),
                  _buildStatCard(
                    'Remaining',
                    controller.remainingUploads.toString(),
                    Colors.blue,
                    Icons.schedule,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Build stat card
  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(BuildContext context) {
    return Obx(() => Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.isUploading.value ? null : controller.clearAll,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear All'),
              ),
            ),
            const SizedBox(width: AppValues.paddingMedium),
            Expanded(
              child: FilledButton.icon(
                onPressed: controller.isUploading.value || !controller.hasImages
                    ? null
                    : controller.uploadAll,
                icon: controller.isUploading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(controller.isUploading.value ? 'Uploading...' : 'Upload All'),
              ),
            ),
          ],
        ));
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingXLarge),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppValues.paddingMedium),
            Text(
              'No Images to Upload',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppValues.paddingSmall),
            Text(
              'Select images from the image processing module or add them directly here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppValues.paddingLarge),
            FilledButton.icon(
              onPressed: controller.selectMoreImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Select Images'),
            ),
          ],
        ),
      ),
    );
  }
}