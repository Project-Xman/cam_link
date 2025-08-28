import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'dart:io';
import '../../core/errors/app_exception.dart';
import '../models/user_model.dart';
import '../../core/values/environment.dart';
import '../services/approval_service.dart';

/// Appwrite Authentication Service using GetX patterns
class AppwriteAuthService extends GetxService {
  static AppwriteAuthService get to => Get.find();

  late final Client _client;
  late final Account _account;
  late final Databases _databases;
  
  // Database constants
  static const String databaseId = 'main_db'; // Created via CLI
  static const String userCollectionId = 'users'; // Created via CLI
  
  // Reactive variables
  final _isLoading = false.obs;
  final _currentUser = Rxn<UserModel>();
  final _isInitialized = false.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  UserModel? get currentUser => _currentUser.value;
  bool get isAuthenticated => _currentUser.value != null;
  bool get isInitialized => _isInitialized.value;

  @override
  void onInit() {
    super.onInit();
    _initializeClient();
    _initializeAuth();
  }

  /// Initialize authentication and check existing session
  Future<void> _initializeAuth() async {
    await _checkExistingSession();
    _isInitialized.value = true;
  }

  /// Initialize Appwrite client
  void _initializeClient() {
    // Override SSL certificate validation for development/testing
    HttpOverrides.global = _AppwriteHttpOverrides();
    
    _client = Client();
    _client
        .setEndpoint(Environment.appwritePublicEndpoint)
        .setProject(Environment.appwriteProjectId)
        .setSelfSigned(status: true); // Enable for SSL issues with cloud endpoints
    
    _account = Account(_client);
    _databases = Databases(_client);
  }

  /// Check for existing session on initialization
  Future<void> _checkExistingSession() async {
    try {
      _isLoading.value = true;
      final user = await _account.get();
      _updateCurrentUser(user);
      
      // Start approval monitoring
      try {
        if (Get.isRegistered<ApprovalService>()) {
          final approvalService = Get.find<ApprovalService>();
          approvalService.startMonitoring();
        }
      } catch (e) {
        // ApprovalService not initialized yet, will be handled later
      }
    } catch (e) {
      // No active session or error getting user
      _currentUser.value = null;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Sign up a new user
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      _isLoading.value = true;
      
      // First, ensure no active session exists
      try {
        await _account.deleteSession(sessionId: 'current');
      } catch (e) {
        // Ignore error if no session exists
      }
      
      final user = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: fullName,
      );

      // Create session after account creation
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      // Create user document in database
      await _createUserDocument(user);

      // Get updated user data
      final updatedUser = await _account.get();
      _updateCurrentUser(updatedUser);
      
      // Start approval monitoring
      try {
        if (Get.isRegistered<ApprovalService>()) {
          final approvalService = Get.find<ApprovalService>();
          approvalService.startMonitoring();
        }
      } catch (e) {
        // ApprovalService not initialized yet, will be handled later
      }
    } on AppwriteException catch (e) {
      throw AppExceptionImpl(
        message: 'Sign up failed: ${e.message}',
        code: e.type,
        originalException: e,
      );
    } catch (e) {
      throw AppExceptionImpl(
        message: 'Sign up failed: ${e.toString()}',
        originalException: e,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Create user document in database
  Future<void> _createUserDocument(appwrite_models.User appwriteUser) async {
    try {
      await _databases.createDocument(
        databaseId: databaseId,
        collectionId: userCollectionId,
        documentId: appwriteUser.$id,
        data: {
          'email': appwriteUser.email,
          'name': appwriteUser.name,
          'photoUrl': appwriteUser.prefs.data['photoUrl'] as String? ?? '',
          'approved': false, // Default to false until admin approves
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } on AppwriteException catch (e) {
      debugPrint('Failed to create user document: AppwriteException: ${e.type}, ${e.message} (${e.code})');
      rethrow; // Re-throw to handle in signup method
    } catch (e) {
      debugPrint('Failed to create user document: $e');
      rethrow; // Re-throw to handle in signup method
    }
  }

  /// Sign in existing user
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading.value = true;
      
      // Check if there's already an active session
      try {
        final existingUser = await _account.get();
        if (existingUser.email == email) {
          // User is already signed in with the same email
          _updateCurrentUser(existingUser);
          return;
        } else {
          // Different user is signed in, sign them out first
          await _account.deleteSession(sessionId: 'current');
        }
      } catch (e) {
        // No active session, proceed with sign in
      }
      
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      // Get user data
      final user = await _account.get();
      _updateCurrentUser(user);
      
      // Start approval monitoring
      try {
        if (Get.isRegistered<ApprovalService>()) {
          final approvalService = Get.find<ApprovalService>();
          approvalService.startMonitoring();
        }
      } catch (e) {
        // ApprovalService not initialized yet, will be handled in bindings
      }
    } on AppwriteException catch (e) {
      // Handle specific Appwrite errors
      if (e.type == 'user_session_already_exists') {
        // Session already exists, try to get current user
        try {
          final user = await _account.get();
          _updateCurrentUser(user);
          return;
        } catch (getUserError) {
          // If we can't get user, delete session and try again
          try {
            await _account.deleteSession(sessionId: 'current');
            await _account.createEmailPasswordSession(
              email: email,
              password: password,
            );
            final user = await _account.get();
            _updateCurrentUser(user);
            return;
          } catch (retryError) {
            throw AppExceptionImpl(
              message: 'Sign in failed after retry: ${retryError.toString()}',
              originalException: retryError,
            );
          }
        }
      }
      
      throw AppExceptionImpl(
        message: 'Sign in failed: ${e.message}',
        code: e.type,
        originalException: e,
      );
    } catch (e) {
      throw AppExceptionImpl(
        message: 'Sign in failed: ${e.toString()}',
        originalException: e,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      // Stop approval monitoring
      try {
        if (Get.isRegistered<ApprovalService>()) {
          final approvalService = Get.find<ApprovalService>();
          approvalService.stopMonitoring();
        }
      } catch (e) {
        // ApprovalService not found, ignore
      }
      
      // Try to delete current session
      try {
        await _account.deleteSession(sessionId: 'current');
      } catch (e) {
        // If no session exists, that's fine
      }
      
      // Clear user data
      _currentUser.value = null;
    } on AppwriteException catch (e) {
      // Clear user data even if sign out fails
      _currentUser.value = null;
      throw AppExceptionImpl(
        message: 'Sign out failed: ${e.message}',
        code: e.type,
        originalException: e,
      );
    } catch (e) {
      // Clear user data even if sign out fails
      _currentUser.value = null;
      throw AppExceptionImpl(
        message: 'Sign out failed: ${e.toString()}',
        originalException: e,
      );
    }
  }

  /// Clear any existing session (useful before signup)
  Future<void> clearSession() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } catch (e) {
      // Ignore errors - no session to clear
    }
    _currentUser.value = null;
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      _isLoading.value = true;
      
      await _account.createRecovery(
        email: email,
        url: 'https://your-app-url.com/reset-password', // Replace with your actual reset URL
      );
    } on AppwriteException catch (e) {
      throw AppExceptionImpl(
        message: 'Password reset failed: ${e.message}',
        code: e.type,
        originalException: e,
      );
    } catch (e) {
      throw AppExceptionImpl(
        message: 'Password reset failed: ${e.toString()}',
        originalException: e,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update password
  Future<void> updatePassword(String password, String oldPassword) async {
    try {
      _isLoading.value = true;
      
      await _account.updatePassword(
        password: password,
        oldPassword: oldPassword,
      );
    } on AppwriteException catch (e) {
      throw AppExceptionImpl(
        message: 'Password update failed: ${e.message}',
        code: e.type,
        originalException: e,
      );
    } catch (e) {
      throw AppExceptionImpl(
        message: 'Password update failed: ${e.toString()}',
        originalException: e,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refresh user data
  Future<void> refreshUserData() async {
    try {
      final user = await _account.get();
      _updateCurrentUser(user);
    } on AppwriteException catch (e) {
      throw AppExceptionImpl(
        message: 'Failed to refresh user data: ${e.message}',
        code: e.type,
        originalException: e,
      );
    } catch (e) {
      // Silently fail, as this is not critical
    }
  }

  /// Check if current user is approved
  /// Now checks the database field instead of email verification
  Future<bool> isUserApproved() async {
    try {
      // Refresh user data to get the latest status
      await refreshUserData();
      
      final currentUser = this.currentUser;
      if (currentUser != null) {
        // Check the approved field in the database
        final document = await _databases.getDocument(
          databaseId: databaseId,
          collectionId: userCollectionId,
          documentId: currentUser.id,
        );
        
        return document.data['approved'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Update current user data
  void _updateCurrentUser(appwrite_models.User user) {
    _currentUser.value = UserModel(
      id: user.$id,
      email: user.email,
      name: user.name,
      photoUrl: user.prefs.data['photoUrl'] as String?,
      approved: false, // Will be updated by approval service
    );
  }

  /// Update current user approval status in memory (called by approval service)
  void updateCurrentUserApprovalStatus(bool approved) {
    final currentUser = _currentUser.value;
    if (currentUser != null) {
      _currentUser.value = currentUser.copyWith(approved: approved);
    }
  }

  /// Wait for authentication initialization to complete
  Future<void> waitForInitialization() async {
    while (!_isInitialized.value) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Get Appwrite client instance
  Client get client => _client;
  
  /// Update user approval status in database (for admin use)
  Future<void> updateUserApprovalStatusInDatabase(String userId, bool approved) async {
    try {
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: userCollectionId,
        documentId: userId,
        data: {
          'approved': approved,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } on AppwriteException catch (e) {
      throw AppExceptionImpl(
        message: 'Failed to update user approval status: ${e.message}',
        code: e.type,
        originalException: e,
      );
    } catch (e) {
      throw AppExceptionImpl(
        message: 'Failed to update user approval status: ${e.toString()}',
        originalException: e,
      );
    }
  }
}

/// Custom HTTP overrides to handle SSL certificate issues
class _AppwriteHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Only allow for Appwrite cloud endpoints
        return host.contains('cloud.appwrite.io');
      };
  }
}