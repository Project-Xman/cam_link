import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/services/storage_service.dart';
import '../data/services/connectivity_service.dart';
import '../data/services/platform_diagnostics_service.dart';
import '../core/errors/app_exception.dart';

/// Main app controller managing global app state
class AppController extends GetxController {
  static AppController get to => Get.find();

  // Services
  late final StorageService _storageService;
  late final ConnectivityService _connectivityService;
  late final PlatformDiagnosticsService _diagnosticsService;

  // Reactive variables
  final _themeMode = ThemeMode.system.obs;
  final _locale = const Locale('en', 'US').obs;
  final _isLoading = false.obs;
  final _isInitialized = false.obs;

  // Getters
  ThemeMode get themeMode => _themeMode.value;
  Locale get locale => _locale.value;
  bool get isLoading => _isLoading.value;
  bool get isInitialized => _isInitialized.value;
  bool get isDarkMode => _themeMode.value == ThemeMode.dark;
  bool get isSystemTheme => _themeMode.value == ThemeMode.system;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeServices();
    await _loadSavedSettings();
    _isInitialized.value = true;
    ErrorHandler.logInfo('AppController initialized');
  }

  /// Initialize required services
  Future<void> _initializeServices() async {
    try {
      _storageService = Get.find<StorageService>();
      _connectivityService = Get.find<ConnectivityService>();
      _diagnosticsService = Get.find<PlatformDiagnosticsService>();
    } catch (e) {
      ErrorHandler.handleError(e, context: 'AppController._initializeServices');
      rethrow;
    }
  }

  /// Load saved app settings
  Future<void> _loadSavedSettings() async {
    try {
      // Load theme mode
      final savedTheme = _storageService.getThemeMode();
      if (savedTheme != null) {
        _themeMode.value = ThemeMode.values.firstWhere(
          (mode) => mode.name == savedTheme,
          orElse: () => ThemeMode.system,
        );
      }

      // Load language
      final savedLanguage = _storageService.getLanguageCode();
      if (savedLanguage != null) {
        _locale.value = Locale(savedLanguage);
      }
    } catch (e) {
      ErrorHandler.handleError(e, context: 'AppController._loadSavedSettings');
    }
  }

  /// Change app theme mode
  Future<void> changeThemeMode(ThemeMode mode) async {
    try {
      _themeMode.value = mode;
      await _storageService.saveThemeMode(mode.name);
      Get.changeThemeMode(mode);
      ErrorHandler.logInfo('Theme mode changed to: ${mode.name}');
    } catch (e) {
      ErrorHandler.handleError(e, context: 'AppController.changeThemeMode');
      _showErrorSnackbar('Failed to change theme');
    }
  }

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    final newMode = _themeMode.value == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    await changeThemeMode(newMode);
  }

  /// Change app language
  Future<void> changeLanguage(Locale newLocale) async {
    try {
      _locale.value = newLocale;
      await _storageService.saveLanguageCode(newLocale.languageCode);
      Get.updateLocale(newLocale);
      ErrorHandler.logInfo('Language changed to: ${newLocale.languageCode}');
    } catch (e) {
      ErrorHandler.handleError(e, context: 'AppController.changeLanguage');
      _showErrorSnackbar('Failed to change language');
    }
  }

  /// Show loading state
  void showLoading() {
    _isLoading.value = true;
  }

  /// Hide loading state
  void hideLoading() {
    _isLoading.value = false;
  }

  /// Execute operation with loading state
  Future<T> executeWithLoading<T>(Future<T> Function() operation) async {
    try {
      showLoading();
      return await operation();
    } finally {
      hideLoading();
    }
  }

  /// Show success message
  void showSuccessMessage(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.primaryContainer,
      colorText: Get.theme.colorScheme.onPrimaryContainer,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: Icon(
        Icons.check_circle_outline,
        color: Get.theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  /// Show error message
  void showErrorMessage(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.errorContainer,
      colorText: Get.theme.colorScheme.onErrorContainer,
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: Icon(
        Icons.error_outline,
        color: Get.theme.colorScheme.onErrorContainer,
      ),
    );
  }

  /// Show warning message
  void showWarningMessage(String message) {
    Get.snackbar(
      'Warning',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.tertiaryContainer,
      colorText: Get.theme.colorScheme.onTertiaryContainer,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: Icon(
        Icons.warning_amber_outlined,
        color: Get.theme.colorScheme.onTertiaryContainer,
      ),
    );
  }

  /// Show info message
  void showInfoMessage(String message) {
    Get.snackbar(
      'Info',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.secondaryContainer,
      colorText: Get.theme.colorScheme.onSecondaryContainer,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: Icon(
        Icons.info_outline,
        color: Get.theme.colorScheme.onSecondaryContainer,
      ),
    );
  }

  /// Handle app-wide exceptions
  void handleException(dynamic exception) {
    final message = ErrorHandler.getUserFriendlyMessage(exception);
    showErrorMessage(message);
    ErrorHandler.handleError(exception, context: 'AppController.handleException');
  }

  /// Show confirmation dialog
  Future<bool> showConfirmationDialog({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Show loading dialog
  void showLoadingDialog({String? message}) {
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message),
            ],
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Hide loading dialog
  void hideLoadingDialog() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  /// Private helper to show error snackbar
  void _showErrorSnackbar(String message) {
    showErrorMessage(message);
  }

  /// Get app info
  Map<String, String> getAppInfo() {
    return {
      'Theme Mode': _themeMode.value.name,
      'Language': _locale.value.languageCode,
      'Connection Status': _connectivityService.connectionStatus.displayName,
      'Is Connected': _connectivityService.isConnected.toString(),
    };
  }

  /// Reset app to defaults
  Future<void> resetToDefaults() async {
    try {
      await _storageService.clearAll();
      _themeMode.value = ThemeMode.system;
      _locale.value = const Locale('en', 'US');
      Get.changeThemeMode(ThemeMode.system);
      Get.updateLocale(const Locale('en', 'US'));
      showSuccessMessage('App settings reset to defaults');
      ErrorHandler.logInfo('App reset to defaults');
    } catch (e) {
      ErrorHandler.handleError(e, context: 'AppController.resetToDefaults');
      showErrorMessage('Failed to reset app settings');
    }
  }

  /// Run platform diagnostics and show results
  Future<void> runPlatformDiagnostics() async {
    try {
      showLoading();
      final diagnosis = await _diagnosticsService.diagnoseChannelIssues();
      hideLoading();

      // Format diagnosis results for display
      final buffer = StringBuffer();
      buffer.writeln('Platform Diagnostics Report');
      buffer.writeln('========================');
      buffer.writeln('Timestamp: ${diagnosis['timestamp']}');
      buffer.writeln('Platform: ${diagnosis['platform']}');
      buffer.writeln('Debug Mode: ${diagnosis['isDebugMode']}');
      
      if (diagnosis['errors'] != null && (diagnosis['errors'] as List).isNotEmpty) {
        buffer.writeln('\nErrors:');
        for (final error in diagnosis['errors']) {
          buffer.writeln('  - $error');
        }
      }
      
      if (diagnosis['pluginStatus'] != null) {
        buffer.writeln('\nPlugin Status:');
        (diagnosis['pluginStatus'] as Map).forEach((plugin, status) {
          buffer.writeln('  $plugin: ${status ? 'OK' : 'FAILED'}');
        });
      }
      
      if (diagnosis['commonIssues'] != null && (diagnosis['commonIssues'] as List).isNotEmpty) {
        buffer.writeln('\nCommon Issues:');
        for (final issue in diagnosis['commonIssues']) {
          buffer.writeln('  - $issue');
        }
      }
      
      if (diagnosis['recommendations'] != null && (diagnosis['recommendations'] as List).isNotEmpty) {
        buffer.writeln('\nRecommendations:');
        for (final recommendation in diagnosis['recommendations']) {
          buffer.writeln('  - $recommendation');
        }
      }

      await Get.defaultDialog(
        title: 'Diagnostics Report',
        content: SingleChildScrollView(
          child: Text(buffer.toString(), style: const TextStyle(fontFamily: 'monospace')),
        ),
        textConfirm: 'OK',
        confirmTextColor: Get.theme.colorScheme.onPrimary,
        buttonColor: Get.theme.colorScheme.primary,
        onConfirm: Get.back,
      );
    } catch (e) {
      hideLoading();
      handleException(e);
    }
  }
}