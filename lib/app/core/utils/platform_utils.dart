import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utility class for platform detection and capabilities
class PlatformUtils {
  /// Check if running on a mobile platform (Android/iOS)
  static bool get isMobile {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  /// Check if running on a desktop platform (Windows/macOS/Linux)
  static bool get isDesktop {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (e) {
      return false;
    }
  }

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Get platform name for logging/display
  static String get platformName {
    if (kIsWeb) return 'Web';
    
    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isLinux) return 'Linux';
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Check if platform likely supports hardware sensors
  static bool get supportsSensors {
    return isMobile; // Mobile platforms typically have sensors
  }

  /// Check if platform likely supports GPS
  static bool get supportsGPS {
    return isMobile; // Mobile platforms typically have GPS
  }

  /// Check if platform likely supports camera
  static bool get supportsCamera {
    return isMobile; // Mobile platforms typically have cameras
  }

  /// Get platform-specific sensor availability expectations
  static Map<String, bool> get expectedSensorSupport {
    return {
      'accelerometer': supportsSensors,
      'gyroscope': supportsSensors,
      'magnetometer': supportsSensors,
      'gps': supportsGPS,
      'camera': supportsCamera,
    };
  }

  /// Check if running in debug mode
  static bool get isDebugMode => kDebugMode;

  /// Check if running in release mode
  static bool get isReleaseMode => kReleaseMode;

  /// Check if running in profile mode
  static bool get isProfileMode => kProfileMode;
}