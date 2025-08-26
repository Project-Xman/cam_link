import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/supabase_auth_service.dart';
import '../../../core/errors/app_exception.dart';

/// Authentication Controller using GetX patterns
class AuthController extends GetxController {
  static AuthController get to => Get.find();

  // Services
  late final SupabaseAuthService _authService;

  // Form fields
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController nameController;
  late final TextEditingController confirmPasswordController;

  // Reactive variables
  final isLoading = false.obs;
  final isApproved = false.obs;

  @override
  void onInit() {
    super.onInit();
    _authService = SupabaseAuthService.to;
    emailController = TextEditingController();
    passwordController = TextEditingController();
    nameController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  /// Sign up a new user
  Future<void> signUp() async {
    if (!_validateSignUpForm()) return;

    try {
      isLoading.value = true;
      await _authService.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        fullName: nameController.text.trim(),
      );
      
      // Show success message
      Get.snackbar(
        'Success',
        'Account created successfully. Please check your email for verification.',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      // Navigate to login screen
      Get.back();
    } on AppException catch (e) {
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create account. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Sign in existing user
  Future<void> signIn() async {
    if (!_validateSignInForm()) return;

    try {
      isLoading.value = true;
      await _authService.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      
      // Check if user is approved
      final approved = await _authService.isUserApproved();
      if (!approved) {
        // Sign out and show approval message
        await _authService.signOut();
        Get.snackbar(
          'Account Not Approved',
          'Your account is pending admin approval. Please contact support.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      
      // Navigate to home screen
      Get.offAllNamed('/home');
    } on AppException catch (e) {
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to sign in. Please check your credentials and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Send password reset email
  Future<void> resetPassword() async {
    if (!_validateEmail()) return;

    try {
      isLoading.value = true;
      await _authService.resetPassword(emailController.text.trim());
      
      Get.snackbar(
        'Password Reset',
        'Password reset email sent. Please check your inbox.',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      Get.back();
    } on AppException catch (e) {
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send password reset email. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Validate sign up form
  bool _validateSignUpForm() {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your full name',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (!_validateEmail()) return false;

    if (passwordController.text.length < 6) {
      Get.snackbar(
        'Error',
        'Password must be at least 6 characters',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar(
        'Error',
        'Passwords do not match',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }

  /// Validate sign in form
  bool _validateSignInForm() {
    if (!_validateEmail()) return false;

    if (passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your password',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }

  /// Validate email
  bool _validateEmail() {
    if (emailController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (!GetUtils.isEmail(emailController.text.trim())) {
      Get.snackbar(
        'Error',
        'Please enter a valid email address',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }

  /// Clear form fields
  void clearForm() {
    emailController.clear();
    passwordController.clear();
    nameController.clear();
    confirmPasswordController.clear();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}