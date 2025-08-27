import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

import '../../../core/values/app_values.dart';
import '../../../data/services/appwrite_auth_service.dart';

class SignupPage extends GetView<AuthController> {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is already authenticated and approved
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = AppwriteAuthService.to;
      if (auth.isAuthenticated) {
        final approved = await auth.isUserApproved();
        if (approved) {
          // User is authenticated and approved - route to home page
          Get.offAllNamed('/home');
        } else {
          // User is authenticated but not approved - route to admin approval page
          Get.offAllNamed('/auth/admin-approval');
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppValues.paddingLarge),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         MediaQuery.of(context).padding.bottom - 
                         kToolbarHeight,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            // App Logo
            Icon(
              Icons.person_add_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppValues.paddingLarge),
            
            // Title
            Text(
              'Create Account',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppValues.paddingSmall),
            
            Text(
              'Sign up to get started',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppValues.paddingXLarge),
            
            // Full Name Field
            TextFormField(
              controller: controller.nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outlined),
              ),
            ),
            const SizedBox(height: AppValues.paddingMedium),
            
            // Email Field
            TextFormField(
              controller: controller.emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppValues.paddingMedium),
            
            // Password Field
            TextFormField(
              controller: controller.passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outlined),
              ),
              obscureText: true,
            ),
            const SizedBox(height: AppValues.paddingMedium),
            
            // Confirm Password Field
            TextFormField(
              controller: controller.confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outlined),
              ),
              obscureText: true,
            ),
            const SizedBox(height: AppValues.paddingLarge),
            
            // Sign Up Button
            Obx(() => SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: controller.isLoading.value ? null : controller.signUp,
                child: controller.isLoading.value
                    ? const CircularProgressIndicator()
                    : const Text('Create Account'),
              ),
            )),
            const SizedBox(height: AppValues.paddingLarge),
            
            // Sign In Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account?"),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Sign In'),
                ),
              ],
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}