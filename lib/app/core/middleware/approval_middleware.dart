import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/appwrite_auth_service.dart';
import '../../routes/app_routes.dart';

/// Middleware to check user approval status before navigation
class ApprovalMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // Allow access to auth routes without approval check
    final allowedRoutes = [
      AppRoutes.login,
      AppRoutes.signup,
      AppRoutes.forgotPassword,
      AppRoutes.adminApproval,
      AppRoutes.splash,
    ];

    if (allowedRoutes.contains(route)) {
      return null; // Allow navigation
    }

    // Check if user is authenticated
    final authService = AppwriteAuthService.to;
    if (!authService.isAuthenticated) {
      return const RouteSettings(name: '/auth/login');
    }

    // For authenticated users, we'll check approval status asynchronously
    // This will be handled by the ApprovalService
    return null;
  }
}