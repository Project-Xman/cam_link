import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/home_controller.dart';
import '../../core/values/app_strings.dart';
import '../../core/values/app_values.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../shared/widgets/status_card.dart';
import '../../shared/widgets/feature_card.dart';
import '../../shared/widgets/google_drive_widget.dart';
import '../../routes/app_routes.dart';
import '../../data/services/appwrite_auth_service.dart';
import '../../data/services/approval_service.dart';

/// Modern Material 3 home page
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading) {
          return const LoadingWidget(message: 'Initializing...');
        }
        
        return CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.all(AppValues.paddingMedium),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildWelcomeSection(context),
                  const SizedBox(height: AppValues.paddingLarge),
                  _buildStatusSection(context),
                  const SizedBox(height: AppValues.paddingLarge),
                  _buildGoogleDriveSection(context),
                  const SizedBox(height: AppValues.paddingLarge),
                  _buildFeaturesSection(context),
                  const SizedBox(height: AppValues.paddingLarge),
                  _buildQuickActions(context),
                  const SizedBox(height: AppValues.paddingXLarge),
                ]),
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Build the app bar
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
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
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          AppStrings.appName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        titlePadding: const EdgeInsets.only(bottom: 16.0),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.secondaryContainer,
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.cloud_upload_outlined,
              size: 80,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  /// Build welcome section
  Widget _buildWelcomeSection(BuildContext context) {
    return Obx(() {
      // Get current user from Appwrite auth service
      final currentUser = AppwriteAuthService.to.currentUser;
      
      if (currentUser != null) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppValues.paddingLarge),
            child: Row(
              children: [
                UserAvatar(
                  user: currentUser,
                  radius: 30,
                ),
                const SizedBox(width: AppValues.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getUserGreeting(currentUser.name),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ready to upload your photos?',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (String result) {
                    switch (result) {
                      case 'profile':
                        _showUserProfile();
                        break;
                      case 'settings':
                        Get.toNamed(AppRoutes.settings);
                        break;
                      case 'logout':
                        _logout();
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'profile',
                      child: ListTile(
                        leading: Icon(Icons.account_circle),
                        title: Text('Profile'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'settings',
                      child: ListTile(
                        leading: Icon(Icons.settings),
                        title: Text('Settings'),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: ListTile(
                        leading: Icon(Icons.logout),
                        title: Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      } else {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppValues.paddingLarge),
            child: Column(
              children: [
                Icon(
                  Icons.waving_hand,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppValues.paddingMedium),
                Text(
                  'Welcome to ${AppStrings.appName}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect with Google to start uploading and managing your photos',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppValues.paddingLarge),
                FilledButton.icon(
                  onPressed: () {
                    // For now, we'll navigate to login since we're using Appwrite auth
                    Get.toNamed('/auth/login');
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  /// Build status section
  Widget _buildStatusSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Status',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppValues.paddingMedium),
        Obx(() => Row(
          children: [
            Expanded(
              child: StatusCard(
                title: 'Authentication',
                status: controller.authStatus.displayName,
                icon: controller.isSignedIn ? Icons.check_circle : Icons.account_circle_outlined,
                isPositive: controller.isSignedIn,
              ),
            ),
            const SizedBox(width: AppValues.paddingMedium),
            Expanded(
              child: StatusCard(
                title: 'Approval Status',
                status: _getApprovalStatus(),
                icon: _getApprovalIcon(),
                isPositive: _isApprovalPositive(),
              ),
            ),
          ],
        )),
        const SizedBox(height: AppValues.paddingMedium),
        Obx(() => StatusCard(
          title: 'Connection',
          status: controller.getConnectionStatusMessage(),
          icon: controller.isConnected ? Icons.wifi : Icons.wifi_off,
          isPositive: controller.isConnected,
        )),
      ],
    );
  }

  /// Build Google Drive section
  Widget _buildGoogleDriveSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cloud Storage',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppValues.paddingMedium),
        const GoogleDriveWidget(),
      ],
    );
  }

  /// Get approval status text
  String _getApprovalStatus() {
    try {
      final approvalService = ApprovalService.to;
      if (approvalService.isChecking.value) {
        return 'Checking...';
      }
      return approvalService.isApproved.value ? 'Approved' : 'Pending';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get approval status icon
  IconData _getApprovalIcon() {
    try {
      final approvalService = ApprovalService.to;
      if (approvalService.isChecking.value) {
        return Icons.hourglass_empty;
      }
      return approvalService.isApproved.value ? Icons.verified : Icons.pending;
    } catch (e) {
      return Icons.help_outline;
    }
  }

  /// Check if approval status is positive
  bool _isApprovalPositive() {
    try {
      final approvalService = ApprovalService.to;
      return approvalService.isApproved.value;
    } catch (e) {
      return false;
    }
  }

  /// Build features section
  Widget _buildFeaturesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppValues.paddingMedium),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppValues.paddingMedium,
          crossAxisSpacing: AppValues.paddingMedium,
          childAspectRatio: 1.2,
          children: [
            FeatureCard(
              icon: Icons.folder_open,
              title: 'File Explorer',
              description: 'Browse and select images for processing',
              onTap: controller.navigateToFileExplorer,
              enabled: controller.isSignedIn && controller.isConnected,
            ),
            FeatureCard(
              icon: Icons.image,
              title: 'Image Processing',
              description: 'Resize and add overlays to your images',
              onTap: () {}, // TODO: Navigate to image processing
              enabled: controller.isSignedIn,
            ),
            FeatureCard(
              icon: Icons.cloud_upload,
              title: 'Cloud Upload',
              description: 'Upload processed images to Google Drive',
              onTap: () {}, // TODO: Navigate to upload manager
              enabled: controller.isSignedIn && controller.isConnected,
            ),
            FeatureCard(
              icon: Icons.qr_code,
              title: 'QR Code Generator',
              description: 'Create custom QR codes with advanced options',
              onTap: () => Get.toNamed(AppRoutes.qrCodeForm),
              enabled: controller.isSignedIn,
            ),
            FeatureCard(
              icon: Icons.settings,
              title: 'Settings',
              description: 'Configure app preferences and options',
              onTap: () => Get.toNamed(AppRoutes.settings),
              enabled: true,
            ),
          ],
        ),
      ],
    );
  }

  /// Build quick actions
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppValues.paddingMedium),
        Wrap(
          spacing: AppValues.paddingMedium,
          runSpacing: AppValues.paddingSmall,
          children: [
            ActionChip(
              avatar: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh Data'),
              onPressed: controller.refreshUserData,
            ),
            ActionChip(
              avatar: const Icon(Icons.security, size: 18),
              label: const Text('Check Permissions'),
              onPressed: controller.checkPermissions,
            ),
            ActionChip(
              avatar: const Icon(Icons.qr_code, size: 18),
              label: const Text('QR Generator'),
              onPressed: () => Get.toNamed(AppRoutes.qrCodeForm),
            ),
            ActionChip(
              avatar: const Icon(Icons.info_outline, size: 18),
              label: const Text('App Info'),
              onPressed: controller.showAppInfo,
            ),
          ],
        ),
      ],
    );
  }

  // Helper method to get user greeting based on time
  String _getUserGreeting(String name) {
    final hour = DateTime.now().hour;
    final firstName = name.split(' ').first;
    
    if (hour < 12) {
      return 'Good morning, $firstName!';
    } else if (hour < 17) {
      return 'Good afternoon, $firstName!';
    } else {
      return 'Good evening, $firstName!';
    }
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
            UserAvatar(
              user: currentUser,
              radius: 40,
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