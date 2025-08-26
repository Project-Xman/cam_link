import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../core/errors/app_exception.dart';
import '../models/user_model.dart';

/// Supabase Authentication Service using GetX patterns
class SupabaseAuthService extends GetxService {
  static SupabaseAuthService get to => Get.find();

  final _supabase = supabase.Supabase.instance.client;
  final _authState = Rxn<supabase.AuthState>();

  // Reactive variables
  final _isLoading = false.obs;
  final _currentUser = Rxn<UserModel>();

  // Getters
  bool get isLoading => _isLoading.value;
  UserModel? get currentUser => _currentUser.value;
  bool get isAuthenticated => _supabase.auth.currentSession != null;
  String? get userId => _supabase.auth.currentSession?.user.id;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      _authState.value = data;
      if (data.session != null) {
        _updateCurrentUser(data.session!.user);
      } else {
        _currentUser.value = null;
      }
    });
  }

  /// Sign up a new user
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      _isLoading.value = true;
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      if (response.user != null) {
        // The trigger function will automatically create the user in camlink.users table
        // Send email verification
        await _supabase.auth.resend(
          email: email,
          type: supabase.OtpType.signup,
        );
      }
    } on supabase.AuthException catch (e) {
      rethrow;
    } catch (e) {
      throw AppExceptionImpl(
        message: 'Sign up failed: ${e.toString()}',
        originalException: e,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Sign in existing user
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading.value = true;
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Check if user is approved
        final userResponse = await _supabase
            .from('camlink.users')
            .select('approved')
            .eq('id', response.user!.id)
            .single();

        if (userResponse['approved'] != true) {
          // Sign out the user if not approved
          await _supabase.auth.signOut();
          throw AppExceptionImpl(
            message: 'Account not approved by admin',
            code: 'NOT_APPROVED',
          );
        }

        _updateCurrentUser(response.user!);
      }
    } on supabase.AuthException catch (e) {
      rethrow;
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
      await _supabase.auth.signOut();
      _currentUser.value = null;
    } catch (e) {
      throw AppExceptionImpl(
        message: 'Sign out failed: ${e.toString()}',
        originalException: e,
      );
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      _isLoading.value = true;
      await _supabase.auth.resetPasswordForEmail(email);
    } on supabase.AuthException catch (e) {
      rethrow;
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
  Future<void> updatePassword(String password) async {
    try {
      _isLoading.value = true;
      await _supabase.auth.updateUser(
        supabase.UserAttributes(
          password: password,
        ),
      );
    } on supabase.AuthException catch (e) {
      rethrow;
    } catch (e) {
      throw AppExceptionImpl(
        message: 'Password update failed: ${e.toString()}',
        originalException: e,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Check if current user is approved
  Future<bool> isUserApproved() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;
      
      final response = await _supabase
          .from('camlink.users')
          .select('approved')
          .eq('id', currentUser.id)
          .single();
          
      return response['approved'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Refresh user data
  Future<void> refreshUserData() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        final userResponse = await _supabase
            .from('camlink.users')
            .select('*')
            .eq('id', currentUser.id)
            .single();
            
        _currentUser.value = UserModel(
          id: userResponse['id'],
          email: userResponse['email'],
          name: userResponse['full_name'],
          approved: userResponse['approved'],
        );
      }
    } catch (e) {
      // Silently fail, as this is not critical
    }
  }

  /// Update current user data
  void _updateCurrentUser(supabase.User user) {
    _currentUser.value = UserModel(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['full_name'] as String? ?? '',
      photoUrl: user.userMetadata?['avatar_url'] as String? ?? '',
      approved: false, // Will be updated when we fetch from database
    );
    
    // Update with actual approval status
    refreshUserData();
  }

  /// Get Supabase client instance
  supabase.SupabaseClient get client => _supabase;
}