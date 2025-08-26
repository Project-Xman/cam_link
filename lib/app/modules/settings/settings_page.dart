import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../file_explorer/file_explorer_controller.dart';
import '../../core/values/app_strings.dart';
import '../../core/values/app_values.dart';

class SettingsPage extends GetView<FileExplorerController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppValues.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Folder Settings Section
            _buildSectionHeader(context, 'Folder Settings'),
            _buildFolderSettingsCard(context),
            
            const SizedBox(height: AppValues.paddingLarge),
            
            // Processing Settings Section
            _buildSectionHeader(context, 'Processing Settings'),
            _buildProcessingSettingsCard(context),
            
            const SizedBox(height: AppValues.paddingLarge),
            
            // Cloud Settings Section
            _buildSectionHeader(context, 'Google Drive Settings'),
            _buildCloudSettingsCard(context),
            
            const SizedBox(height: AppValues.paddingLarge),
            
            // App Information Section
            _buildSectionHeader(context, 'App Information'),
            _buildAppInfoCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppValues.paddingSmall),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFolderSettingsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingTile(
              context,
              icon: Icons.folder_outlined,
              title: 'Input Folder',
              subtitle: Obx(() => Text(
                controller.selectedPath.value.isNotEmpty
                    ? path.basename(controller.selectedPath.value)
                    : 'Not selected',
              )),
              onTap: _selectFolder,
            ),
            const Divider(),
            _buildSettingTile(
              context,
              icon: Icons.folder_open_outlined,
              title: 'Output Folder',
              subtitle: Obx(() => Text(
                controller.outputPath.value.isNotEmpty
                    ? path.basename(controller.outputPath.value)
                    : 'Not selected',
              )),
              onTap: _selectOutputFolder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingSettingsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingTile(
              context,
              icon: Icons.photo_size_select_actual_outlined,
              title: AppStrings.resolution,
              subtitle: Obx(() => Text(
                '${controller.resolutionWidth.value} x ${controller.resolutionHeight.value}',
              )),
              onTap: () => _showResolutionDialog(context),
            ),
            const Divider(),
            Obx(() => SwitchListTile(
              secondary: const Icon(Icons.save_outlined),
              title: const Text(AppStrings.saveToDevice),
              subtitle: const Text('Save processed images locally'),
              value: controller.saveOutputToDevice.value,
              onChanged: (_) => controller.toggleSaveToDevice(),
            )),
            const Divider(),
            _buildSettingTile(
              context,
              icon: Icons.image_outlined,
              title: 'Overlay Image',
              subtitle: Obx(() => Text(
                controller.selectedOverlayImage.value != null
                    ? path.basename(controller.selectedOverlayImage.value!)
                    : 'None selected',
              )),
              onTap: _selectOverlayImage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudSettingsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.cloudFolderName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppValues.paddingSmall),
            Row(
              children: [
                Expanded(
                  child: Obx(() => TextField(
                    controller: TextEditingController(
                      text: controller.folderNameController.value,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter folder name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      controller.folderNameController.value = value;
                    },
                  )),
                ),
                const SizedBox(width: AppValues.paddingSmall),
                Obx(() => FilledButton(
                  onPressed: controller.cloudFolderCreated.value
                      ? null
                      : controller.createCloudFolder,
                  child: Text(
                    controller.cloudFolderCreated.value
                        ? 'Created'
                        : 'Create',
                  ),
                )),
              ],
            ),
            const SizedBox(height: AppValues.paddingMedium),
            Obx(() => Text(
              controller.cloudFolderCreated.value
                  ? 'Cloud folder created successfully'
                  : 'Create a cloud folder to upload images to Google Drive',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: controller.cloudFolderCreated.value
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoTile(
              context,
              icon: Icons.info_outlined,
              title: 'App Name',
              subtitle: AppStrings.appName,
            ),
            const Divider(),
            _buildInfoTile(
              context,
              icon: Icons.code_outlined,
              title: 'Version',
              subtitle: '1.0.0',
            ),
            const Divider(),
            _buildInfoTile(
              context,
              icon: Icons.copyright_outlined,
              title: 'License',
              subtitle: 'MIT License',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Future<void> _selectFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      await controller.selectFolder(result);
    }
  }

  Future<void> _selectOutputFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      await controller.selectOutputFolder(result);
    }
  }

  Future<void> _selectOverlayImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png'],
    );
    
    if (result != null && result.files.single.path != null) {
      await controller.selectOverlayImage(result.files.single.path!);
    }
  }

  Future<void> _showResolutionDialog(BuildContext context) async {
    int? width = controller.resolutionWidth.value;
    int? height = controller.resolutionHeight.value;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Resolution'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Width',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: width.toString()),
                onChanged: (value) {
                  width = int.tryParse(value);
                },
              ),
              const SizedBox(height: AppValues.paddingMedium),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Height',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: height.toString()),
                onChanged: (value) {
                  height = int.tryParse(value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (width != null && height != null && width! > 0 && height! > 0) {
                  controller.updateResolution(width!, height!);
                  Navigator.of(context).pop();
                }
              },
              child: const Text(AppStrings.save),
            ),
          ],
        );
      },
    );
  }
}