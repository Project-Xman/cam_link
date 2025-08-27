import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../file_explorer/file_explorer_controller.dart';
import '../../core/values/app_strings.dart';
import '../../core/values/app_values.dart';
import '../../data/services/appwrite_auth_service.dart';

class SettingsPage extends GetView<FileExplorerController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          // Add user profile and logout actions
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: _showUserProfile,
            tooltip: 'User Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppValues.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            _buildSectionHeader(context, 'User Profile'),
            _buildUserProfileCard(context),
            
            const SizedBox(height: AppValues.paddingLarge),
            
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

  Widget _buildUserProfileCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingMedium),
        child: Obx(() {
          // Get current user from Appwrite auth service
          final currentUser = AppwriteAuthService.to.currentUser;
          
          if (currentUser != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        currentUser.initials,
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppValues.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser.displayName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentUser.email,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppValues.paddingMedium),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showUserProfileDetails,
                        icon: const Icon(Icons.info_outline),
                        label: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: AppValues.paddingMedium),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Not signed in',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppValues.paddingMedium),
                FilledButton.icon(
                  onPressed: _login,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                ),
              ],
            );
          }
        }),
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
            // Use a stateful widget to properly manage the text controller
            _CloudFolderNameField(controller: controller),
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

  // User profile and logout methods
  void _showUserProfile() {
    final currentUser = AppwriteAuthService.to.currentUser;
    if (currentUser != null) {
      Get.defaultDialog(
        title: 'User Profile',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Get.theme.colorScheme.primaryContainer,
              child: Text(
                currentUser.initials,
                style: TextStyle(
                  color: Get.theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(height: AppValues.paddingMedium),
            Text(
              currentUser.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currentUser.email,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: AppValues.paddingMedium),
            Text(
              'User ID: ${currentUser.id}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            if (currentUser.approved) ...[
              const SizedBox(height: AppValues.paddingSmall),
              const Text(
                'Status: Approved',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else ...[
              const SizedBox(height: AppValues.paddingSmall),
              const Text(
                'Status: Pending Approval',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        textConfirm: 'Close',
        confirm: ElevatedButton(
          onPressed: () => Get.back(),
          child: const Text('Close'),
        ),
      );
    } else {
      Get.snackbar(
        'Error',
        'No user data available',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showUserProfileDetails() {
    _showUserProfile(); // Reuse the same method
  }

  void _login() {
    Get.toNamed('/auth/login');
  }

  void _logout() {
    Get.defaultDialog(
      title: 'Logout',
      middleText: 'Are you sure you want to logout?',
      confirm: FilledButton(
        onPressed: () {
          // Perform logout through Appwrite auth service
          AppwriteAuthService.to.signOut();
          Get.back(); // Close dialog
          Get.offAllNamed('/auth/login'); // Navigate to login
        },
        child: const Text('Logout'),
      ),
      cancel: OutlinedButton(
        onPressed: () => Get.back(), // Close dialog
        child: const Text('Cancel'),
      ),
    );
  }
}

// Separate widget to properly manage the text controller lifecycle
class _CloudFolderNameField extends StatefulWidget {
  final FileExplorerController controller;

  const _CloudFolderNameField({required this.controller});

  @override
  State<_CloudFolderNameField> createState() => _CloudFolderNameFieldState();
}

class _CloudFolderNameFieldState extends State<_CloudFolderNameField> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.controller.folderNameController.value,
    );
    
    // Listen to changes in the controller's value
    _textController.addListener(() {
      widget.controller.folderNameController.value = _textController.text;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            decoration: const InputDecoration(
              hintText: 'Enter folder name',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: AppValues.paddingSmall),
        Obx(() => FilledButton(
          onPressed: widget.controller.cloudFolderCreated.value
              ? null
              : widget.controller.createCloudFolder,
          child: Text(
            widget.controller.cloudFolderCreated.value
                ? 'Created'
                : 'Create',
          ),
        )),
      ],
    );
  }
}