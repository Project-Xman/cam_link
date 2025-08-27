import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/appwrite_auth_service.dart';
import '../../../core/errors/app_exception.dart';

/// Authentication Controller using GetX patterns
class AuthController extends GetxController {
  static AuthController get to => Get.find();

  // Services
  late final AppwriteAuthService _authService;

  // Form fields - Using nullable controllers to check if they're disposed
  TextEditingController? _emailController;
  TextEditingController? _passwordController;
  TextEditingController? _nameController;
  TextEditingController? _confirmPasswordController;

  // Reactive variables
  final isLoading = false.obs;
  final isApproved = false.obs;
  
  // Disposal tracking
  bool _isDisposed = false;

  // Public getters with null checks and lazy initialization
  TextEditingController get emailController {
    if (_isDisposed) return TextEditingController();
    if (_emailController == null) {
      _emailController = TextEditingController();
    }
    return _emailController!;
  }
  
  TextEditingController get passwordController {
    if (_isDisposed) return TextEditingController();
    if (_passwordController == null) {
      _passwordController = TextEditingController();
    }
    return _passwordController!;
  }
  
  TextEditingController get nameController {
    if (_isDisposed) return TextEditingController();
    if (_nameController == null) {
      _nameController = TextEditingController();
    }
    return _nameController!;
  }
  
  TextEditingController get confirmPasswordController {
    if (_isDisposed) return TextEditingController();
    if (_confirmPasswordController == null) {
      _confirmPasswordController = TextEditingController();
    }
    return _confirmPasswordController!;
  }

  @override
  void onInit() {
    super.onInit();
    _authService = AppwriteAuthService.to;
    _initializeControllers();
  }

  /// Initialize text editing controllers
  void _initializeControllers() {
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _nameController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  /// Sign up a new user
  Future<void> signUp() async {
    if (!_validateSignUpForm()) return;

    try {
      isLoading.value = true;
      
      // Clear any existing session before signup
      await _authService.clearSession();
      
      await _authService.signUp(
        email: _emailController?.text.trim() ?? '',
        password: _passwordController?.text ?? '',
        fullName: _nameController?.text.trim() ?? '',
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
        email: _emailController?.text.trim() ?? '',
        password: _passwordController?.text ?? '',
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
      _passwordController?.clear();
    }
  }

  /// Send password reset email
  Future<void> resetPassword() async {
    if (!_validateEmail()) return;

    try {
      isLoading.value = true;
      await _authService.resetPassword(_emailController?.text.trim() ?? '');
      
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
    // Check if controllers are disposed
    if (_nameController == null || _emailController == null || _passwordController == null || _confirmPasswordController == null) {
      Get.snackbar(
        'Error',
        'Form not initialized properly',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if ((_nameController?.text.trim() ?? '').isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your full name',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (!_validateEmail()) return false;

    if ((_passwordController?.text ?? '').length < 6) {
      Get.snackbar(
        'Error',
        'Password must be at least 6 characters',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if ((_passwordController?.text ?? '') != (_confirmPasswordController?.text ?? '')) {
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
    // Check if controllers are disposed
    if (_emailController == null || _passwordController == null) {
      Get.snackbar(
        'Error',
        'Form not initialized properly',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (!_validateEmail()) return false;

    if ((_passwordController?.text ?? '').isEmpty) {
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
    // Check if controller is disposed
    if (_emailController == null) {
      Get.snackbar(
        'Error',
        'Form not initialized properly',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if ((_emailController?.text.trim() ?? '').isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (!GetUtils.isEmail(_emailController?.text.trim() ?? '')) {
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
    _emailController?.clear();
    _passwordController?.clear();
    _nameController?.clear();
    _confirmPasswordController?.clear();
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
    // Mark as disposed first
    _isDisposed = true;
    
    // Dispose controllers safely
    _emailController?.dispose();
    _passwordController?.dispose();
    _nameController?.dispose();
    _confirmPasswordController?.dispose();
    
    // Set to null to prevent access after disposal
    _emailController = null;
    _passwordController = null;
    _nameController = null;
    _confirmPasswordController = null;
    
    super.onClose();
  }
}