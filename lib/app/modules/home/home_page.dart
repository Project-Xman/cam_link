import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/home_controller.dart';
import '../../core/values/app_strings.dart';
import '../../core/values/app_values.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../shared/widgets/status_card.dart';
import '../../shared/widgets/feature_card.dart';
import '../../routes/app_routes.dart';

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
      if (controller.isSignedIn) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppValues.paddingLarge),
            child: Row(
              children: [
                UserAvatar(
                  user: controller.currentUser!,
                  radius: 30,
                ),
                const SizedBox(width: AppValues.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.getUserGreeting(),
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
                IconButton(
                  onPressed: controller.signOut,
                  icon: const Icon(Icons.logout),
                  tooltip: 'Sign Out',
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
                  onPressed: controller.signInWithGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text('Connect in with Google Drive'),
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
                title: 'Connection',
                status: controller.getConnectionStatusMessage(),
                icon: controller.isConnected ? Icons.wifi : Icons.wifi_off,
                isPositive: controller.isConnected,
              ),
            ),
          ],
        )),
      ],
    );
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
              avatar: const Icon(Icons.info_outline, size: 18),
              label: const Text('App Info'),
              onPressed: controller.showAppInfo,
            ),
          ],
        ),
      ],
    );
  }
}