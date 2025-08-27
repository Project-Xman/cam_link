import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
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
  static const String DATABASE_ID = 'main_db'; // Created via CLI
  static const String USER_COLLECTION_ID = 'users'; // Created via CLI
  
  // Reactive variables
  final _isLoading = false.obs;
  final _currentUser = Rxn<UserModel>();

  // Getters
  bool get isLoading => _isLoading.value;
  UserModel? get currentUser => _currentUser.value;
  bool get isAuthenticated => _currentUser.value != null;

  @override
  void onInit() {
    super.onInit();
    _initializeClient();
    _checkExistingSession();
  }

  /// Initialize Appwrite client
  void _initializeClient() {
    _client = Client();
    _client
        .setEndpoint(Environment.appwritePublicEndpoint)
        .setProject(Environment.appwriteProjectId)
        .setSelfSigned(status: true);
    
    _account = Account(_client);
    _databases = Databases(_client);
  }

  /// Check for existing session on initialization
  Future<void> _checkExistingSession() async {
    try {
      final user = await _account.get();
      _updateCurrentUser(user);
    } catch (e) {
      // No active session or error getting user
      _currentUser.value = null;
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

      _updateCurrentUser(user);
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
        databaseId: DATABASE_ID,
        collectionId: USER_COLLECTION_ID,
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
      print('Failed to create user document: AppwriteException: ${e.type}, ${e.message} (${e.code})');
      rethrow; // Re-throw to handle in signup method
    } catch (e) {
      print('Failed to create user document: $e');
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
      
      final session = await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      // Get user data
      final user = await _account.get();
      _updateCurrentUser(user);
      
      // Start approval monitoring after successful sign in
      try {
        if (Get.isRegistered<ApprovalService>()) {
          final approvalService = Get.find<ApprovalService>();
          approvalService.startMonitoring();
        }
      } catch (e) {
        // ApprovalService not initialized yet, will be handled in bindings
      }
    } on AppwriteException catch (e) {
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
          databaseId: DATABASE_ID,
          collectionId: USER_COLLECTION_ID,
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
      approved: user.emailVerification, // Using email verification as approval status
    );
  }

  /// Get Appwrite client instance
  Client get client => _client;
  
  /// Update user approval status (for admin use)
  Future<void> updateUserApprovalStatus(String userId, bool approved) async {
    try {
      await _databases.updateDocument(
        databaseId: DATABASE_ID,
        collectionId: USER_COLLECTION_ID,
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