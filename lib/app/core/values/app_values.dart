class AppValues {
  // App Information
  static const String appName = 'CamLink';
  static const String appVersion = '1.0.0';
  
  // UI Constants
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  
  // Animation Durations
  static const int animationDurationShort = 150;
  static const int animationDurationMedium = 300;
  static const int animationDurationLong = 500;
  
  // Image Processing
  static const int defaultImageWidth = 1920;
  static const int defaultImageHeight = 1080;
  static const List<String> supportedImageFormats = ['.jpg', '.jpeg', '.png', '.bmp'];
  
  // File Sizes
  static const int maxFileSizeInMB = 50;
  static const int maxBatchUploadCount = 100;
  
  // Timeouts
  static const int networkTimeoutSeconds = 30;
  static const int uploadTimeoutSeconds = 120;
  
  // Storage Keys
  static const String userPrefsKey = 'user_preferences';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
}