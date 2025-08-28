import 'package:logger/logger.dart';
import 'package:flutter/services.dart';

/// Base exception class for all app-specific exceptions
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Concrete implementation of AppException
class AppExceptionImpl extends AppException {
  AppExceptionImpl({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  }) : super();
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory NetworkException.noConnection() => const NetworkException(
        message: 'No internet connection available',
        code: 'NO_CONNECTION',
      );

  factory NetworkException.timeout() => const NetworkException(
        message: 'Request timeout',
        code: 'TIMEOUT',
      );

  factory NetworkException.serverError([String? details]) => NetworkException(
        message: 'Server error${details != null ? ': $details' : ''}',
        code: 'SERVER_ERROR',
      );
}

/// Authentication-related exceptions
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory AuthException.notSignedIn() => const AuthException(
        message: 'User is not signed in',
        code: 'NOT_SIGNED_IN',
      );

  factory AuthException.signInFailed([String? reason]) => AuthException(
        message: 'Sign in failed${reason != null ? ': $reason' : ''}',
        code: 'SIGN_IN_FAILED',
      );

  factory AuthException.tokenExpired() => const AuthException(
        message: 'Authentication token has expired',
        code: 'TOKEN_EXPIRED',
      );

  factory AuthException.notApproved() => const AuthException(
        message: 'Account not approved by admin',
        code: 'NOT_APPROVED',
      );
}

/// File-related exceptions
class FileException extends AppException {
  const FileException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory FileException.notFound(String path) => FileException(
        message: 'File not found: $path',
        code: 'FILE_NOT_FOUND',
      );

  factory FileException.accessDenied(String path) => FileException(
        message: 'Access denied to file: $path',
        code: 'ACCESS_DENIED',
      );

  factory FileException.invalidFormat(String expectedFormat) => FileException(
        message: 'Invalid file format. Expected: $expectedFormat',
        code: 'INVALID_FORMAT',
      );

  factory FileException.sizeTooLarge(int maxSizeMB) => FileException(
        message: 'File size exceeds limit of ${maxSizeMB}MB',
        code: 'SIZE_TOO_LARGE',
      );
}

/// Image processing exceptions
class ImageProcessingException extends AppException {
  const ImageProcessingException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory ImageProcessingException.processingFailed([String? reason]) => ImageProcessingException(
        message: 'Image processing failed${reason != null ? ': $reason' : ''}',
        code: 'PROCESSING_FAILED',
      );

  factory ImageProcessingException.unsupportedFormat(String format) => ImageProcessingException(
        message: 'Unsupported image format: $format',
        code: 'UNSUPPORTED_FORMAT',
      );

  factory ImageProcessingException.corruptedImage() => const ImageProcessingException(
        message: 'Image file is corrupted or unreadable',
        code: 'CORRUPTED_IMAGE',
      );
}

/// Upload-related exceptions
class UploadException extends AppException {
  const UploadException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory UploadException.failed([String? reason]) => UploadException(
        message: 'Upload failed${reason != null ? ': $reason' : ''}',
        code: 'UPLOAD_FAILED',
      );

  factory UploadException.cancelled() => const UploadException(
        message: 'Upload was cancelled',
        code: 'UPLOAD_CANCELLED',
      );

  factory UploadException.quotaExceeded() => const UploadException(
        message: 'Storage quota exceeded',
        code: 'QUOTA_EXCEEDED',
      );
}

/// Permission-related exceptions
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory PermissionException.denied(String permission) => PermissionException(
        message: 'Permission denied: $permission',
        code: 'PERMISSION_DENIED',
      );

  factory PermissionException.permanentlyDenied(String permission) => PermissionException(
        message: 'Permission permanently denied: $permission',
        code: 'PERMISSION_PERMANENTLY_DENIED',
      );
}

/// Error handler utility class
class ErrorHandler {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Handles and logs exceptions
  static void handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    String errorMessage;
    String errorType;

    if (error is AppException) {
      errorMessage = error.message;
      errorType = error.runtimeType.toString();
    } else {
      errorMessage = error.toString();
      errorType = 'UnknownError';
    }

    _logger.e(
      '[$errorType] ${context != null ? '[$context] ' : ''}$errorMessage',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Logs info messages
  static void logInfo(String message, [String? context]) {
    _logger.i('${context != null ? '[$context] ' : ''}$message');
  }

  /// Logs warning messages
  static void logWarning(String message, [String? context]) {
    _logger.w('${context != null ? '[$context] ' : ''}$message');
  }

  /// Logs debug messages
  static void logDebug(String message, [String? context]) {
    _logger.d('${context != null ? '[$context] ' : ''}$message');
  }

  /// Gets user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    // Handle PlatformException specifically
    if (error is PlatformException) {
      return _handlePlatformException(error);
    }
    
    if (error is NetworkException) {
      switch (error.code) {
        case 'NO_CONNECTION':
          return 'Please check your internet connection and try again.';
        case 'TIMEOUT':
          return 'Request timed out. Please try again.';
        case 'SERVER_ERROR':
          return 'Server is currently unavailable. Please try again later.';
        default:
          return 'Network error occurred. Please try again.';
      }
    } else if (error is AuthException) {
      switch (error.code) {
        case 'NOT_SIGNED_IN':
          return 'Please sign in to continue.';
        case 'SIGN_IN_FAILED':
          // Check if it's a redirect URI error
          if (error.message.contains('redirect_uri_mismatch') || 
              error.message.contains('invalid request')) {
            return 'OAuth configuration error. The redirect URI needs to be configured in Google Console. Please add "http://localhost:8080" to your OAuth client\'s authorized redirect URIs.';
          }
          return 'Sign in failed. Please check your credentials and try again.';
        case 'TOKEN_EXPIRED':
          return 'Your session has expired. Please sign in again.';
        case 'NOT_APPROVED':
          return 'Your account is pending admin approval.';
        default:
          return 'Authentication error. Please try again.';
      }
    } else if (error is FileException) {
      switch (error.code) {
        case 'FILE_NOT_FOUND':
          return 'File not found. Please select a valid file.';
        case 'ACCESS_DENIED':
          return 'Access denied. Please check file permissions.';
        case 'INVALID_FORMAT':
          return 'Invalid file format. Please select a supported file.';
        case 'SIZE_TOO_LARGE':
          return 'File is too large. Please select a smaller file.';
        default:
          return 'File error occurred. Please try again.';
      }
    } else if (error is ImageProcessingException) {
      switch (error.code) {
        case 'PROCESSING_FAILED':
          return 'Failed to process image. Please try with a different image.';
        case 'UNSUPPORTED_FORMAT':
          return 'Unsupported image format. Please use PNG, JPG, or JPEG.';
        case 'CORRUPTED_IMAGE':
          return 'Image file is corrupted. Please select a different image.';
        default:
          return 'Image processing error. Please try again.';
      }
    } else if (error is UploadException) {
      switch (error.code) {
        case 'UPLOAD_FAILED':
          return 'Upload failed. Please check your connection and try again.';
        case 'UPLOAD_CANCELLED':
          return 'Upload was cancelled.';
        case 'QUOTA_EXCEEDED':
          return 'Storage quota exceeded. Please free up some space.';
        default:
          return 'Upload error occurred. Please try again.';
      }
    } else if (error is PermissionException) {
      switch (error.code) {
        case 'PERMISSION_DENIED':
          return 'Permission required. Please grant the necessary permissions.';
        case 'PERMISSION_PERMANENTLY_DENIED':
          return 'Permission permanently denied. Please enable it in app settings.';
        default:
          return 'Permission error. Please check app permissions.';
      }
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Handle PlatformException specifically
  static String _handlePlatformException(PlatformException error) {
    logError('PlatformException occurred', error: error, context: 'ErrorHandler._handlePlatformException');
    
    switch (error.code) {
      case 'CANCELED':
        return 'Sign in was cancelled. Please try again.';
      case 'channel-error':
        return 'Connection error occurred. Please restart the app and try again.';
      case 'permission_denied':
        return 'Permission denied. Please grant the required permissions in app settings.';
      case 'not_available':
        return 'Feature not available on this device.';
      case 'network_error':
        return 'Network connection error. Please check your internet connection.';
      case 'auth_error':
      case 'sign_in_failed':
        return 'Authentication failed. Please sign in again.';
      case 'file_not_found':
        return 'File not found. Please try selecting a different file.';
      case 'invalid_image':
        return 'Invalid image file. Please select a valid image.';
      default:
        // Check if it's a redirect URI mismatch error
        if (error.message?.contains('redirect_uri_mismatch') == true || 
            error.message?.contains('invalid request') == true) {
          return 'OAuth configuration error. Please contact the developer to configure the redirect URI in Google Console.';
        }
        return 'Platform error occurred: ${error.message ?? 'Unknown error'}. Please try again.';
    }
  }

  /// Log error with enhanced detail
  static void logError(String message, {dynamic error, String? context}) {
    if (error is PlatformException) {
      _logger.e(
        '${context != null ? '[$context] ' : ''}$message\n'
        'Platform Error Details:\n'
        '  Code: ${error.code}\n'
        '  Message: ${error.message}\n'
        '  Details: ${error.details}',
        error: error,
      );
    } else {
      _logger.e(
        '${context != null ? '[$context] ' : ''}$message',
        error: error,
      );
    }
  }
}