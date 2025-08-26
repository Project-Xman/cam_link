import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/values/app_strings.dart';
import '../../../core/values/app_values.dart';

class ForgotPasswordPage extends GetView<AuthController> {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppValues.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Icon(
              Icons.lock_reset_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppValues.paddingLarge),
            
            // Title
            Text(
              'Forgot Password?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppValues.paddingSmall),
            
            Text(
              'Enter your email to reset your password',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppValues.paddingXLarge),
            
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
            const SizedBox(height: AppValues.paddingLarge),
            
            // Reset Password Button
            Obx(() => SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: controller.isLoading.value ? null : controller.resetPassword,
                child: controller.isLoading.value
                    ? const CircularProgressIndicator()
                    : const Text('Send Reset Link'),
              ),
            )),
            const SizedBox(height: AppValues.paddingLarge),
            
            // Back to Sign In Link
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Back to Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}