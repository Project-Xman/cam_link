import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'file_explorer_controller.dart';
import '../../shared/widgets/file_status_display.dart';
import '../../core/values/app_strings.dart';

class FileExplorerPage extends GetView<FileExplorerController> {
  const FileExplorerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Explorer'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          Obx(() => controller.isWatching.value
              ? IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: controller.stopWatching,
                  tooltip: AppStrings.stopWatching,
                )
              : IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: controller.startWatching,
                  tooltip: AppStrings.startWatching,
                )),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshFileList(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 1200) {
            return _buildDesktopLayout(context);
          } else if (constraints.maxWidth > 600) {
            return _buildTabletLayout(context);
          } else {
            return _buildMobileLayout(context);
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main file explorer
          Expanded(
            flex: 3,
            child: _buildFileExplorer(context),
          ),
          const SizedBox(width: 16),
          // Status sidebar
          SizedBox(
            width: 400,
            child: _buildStatusCard(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Status row
          SizedBox(
            height: 300,
            child: _buildStatusCard(context),
          ),
          const SizedBox(height: 16),
          // File explorer
          Expanded(child: _buildFileExplorer(context)),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Files', icon: Icon(Icons.folder_outlined)),
              Tab(text: 'Status', icon: Icon(Icons.analytics)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFileExplorer(context),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildStatusCard(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileExplorer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.folder_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Files',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Obx(() => controller.selectedPath.value.isNotEmpty
                    ? Chip(
                        avatar: Icon(
                          controller.isWatching.value 
                              ? Icons.visibility 
                              : Icons.visibility_off,
                          size: 18,
                        ),
                        label: Text(
                          controller.isWatching.value 
                              ? 'Watching' 
                              : 'Not Watching',
                        ),
                        backgroundColor: controller.isWatching.value
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                      )
                    : const SizedBox.shrink()),
              ],
            ),
            const SizedBox(height: 16),
            
            // Selected path display
            Obx(() => controller.selectedPath.value.isNotEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Watching: ${controller.selectedPath.value}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha:0.5),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a folder to start monitoring',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose a directory to watch for new images',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha:0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _selectFolder,
                          icon: const Icon(Icons.folder_outlined),
                          label: const Text(AppStrings.selectFolder),
                        ),
                      ],
                    ),
                  )),
            
            const SizedBox(height: 16),
            
            // File list
            Expanded(
              child: Obx(() {
                final files = controller.fileList;
                
                if (files.isEmpty && controller.selectedPath.value.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 64,
                          color: colorScheme.onSurfaceVariant.withValues(alpha:0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.noFilesFound,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final filePath = files[index];
                    final fileName = path.basename(filePath);
                    final fileStatus = controller.getFileStatus(filePath);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      color: colorScheme.surface,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.image_outlined,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          fileName,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: fileStatus != null
                            ? CompactFileStatusDisplay(
                                processStatus: fileStatus.processStatus,
                                uploadStatus: fileStatus.uploadStatus,
                                uploadProgress: fileStatus.uploadProgress,
                              )
                            : null,
                        trailing: fileStatus != null
                            ? _buildFileActionButton(context, filePath, fileStatus)
                            : IconButton(
                                icon: const Icon(Icons.play_circle_outlined),
                                onPressed: () => controller.processFile(filePath),
                                tooltip: 'Process File',
                              ),
                        onTap: () => controller.processFile(filePath),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileActionButton(BuildContext context, String filePath, fileStatus) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (fileStatus.processStatus.isInProgress || fileStatus.uploadStatus.isInProgress) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: fileStatus.uploadStatus.isInProgress 
              ? fileStatus.uploadProgress 
              : null,
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      );
    }
    
    if (fileStatus.hasError) {
      return IconButton(
        icon: Icon(Icons.error_outline, color: colorScheme.error),
        onPressed: () => controller.processFile(filePath),
        tooltip: 'Retry',
      );
    }
    
    if (fileStatus.isComplete) {
      return Icon(Icons.check_circle, color: colorScheme.primary);
    }
    
    return IconButton(
      icon: const Icon(Icons.play_circle_outlined),
      onPressed: () => controller.processFile(filePath),
      tooltip: 'Process File',
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Statistics',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: controller.resetStatistics,
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Statistics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Obx(() => _buildStatCard(
                  context,
                  Icons.camera_alt_outlined,
                  'Detected',
                  controller.imagesDetected.value,
                  colorScheme.tertiary,
                )),
                Obx(() => _buildStatCard(
                  context,
                  Icons.image_outlined,
                  'Processed',
                  controller.imagesProcessed.value,
                  colorScheme.secondary,
                )),
                Obx(() => _buildStatCard(
                  context,
                  Icons.cloud_upload_outlined,
                  'Uploaded',
                  controller.imagesUploaded.value,
                  colorScheme.primary,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String label, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _selectFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      await controller.selectFolder(result);
    }
  }
}