import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/appwrite_auth_service.dart';
import '../../../core/errors/app_exception.dart';

/// Authentication Controller using GetX patterns
class AuthController extends GetxController {
  static AuthController get to => Get.find();

  // Services
  late final AppwriteAuthService _authService;

  // Form fields - Initialize immediately to prevent disposal issues
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController nameController;
  late final TextEditingController confirmPasswordController;

  // Reactive variables
  final isLoading = false.obs;
  final isApproved = false.obs;
  final _isDisposed = false.obs;

  @override
  void onInit() {
    super.onInit();
    _authService = AppwriteAuthService.to;
    _initializeControllers();
  }

  /// Initialize text editing controllers
  void _initializeControllers() {
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
      
      // Clear any existing session before signup
      await _authService.clearSession();
      
      await _authService.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        fullName: nameController.text.trim(),
      );
      
      // Show success message
      Get.snackbar(
        'Success',
        'Account created successfully. Waiting for admin approval.',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      // Navigate to admin approval page since user is created but not approved
      Get.offAllNamed('/auth/admin-approval');
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
      // Clear form fields after submission
      _clearFormFields();
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
      
      if (approved) {
        // Navigate to home screen
        Get.offAllNamed('/home');
      } else {
        // Navigate to admin approval page
        Get.offAllNamed('/auth/admin-approval');
      }
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
      // Clear password field after submission
      passwordController.clear();
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

  /// Check if current user is approved
  Future<bool> checkUserApproval() async {
    try {
      return await _authService.isUserApproved();
    } catch (e) {
      return false;
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
  void _clearFormFields() {
    if (!_isDisposed.value) {
      emailController.clear();
      passwordController.clear();
      nameController.clear();
      confirmPasswordController.clear();
    }
  }

  /// Public method to clear form
  void clearForm() {
    _clearFormFields();
  }

  /// Logout method
  Future<void> logout() async {
    try {
      await _authService.signOut();
      Get.offAllNamed('/auth/login');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to logout. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
    }
  }

  @override
  void onClose() {
    // Mark as disposed to prevent further operations
    _isDisposed.value = true;
    
    // Dispose controllers safely
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    
    super.onClose();
  }
}