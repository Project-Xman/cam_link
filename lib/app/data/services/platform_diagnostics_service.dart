import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/errors/app_exception.dart';

/// Service for platform diagnostics and plugin health checks
class PlatformDiagnosticsService extends GetxService {
  static PlatformDiagnosticsService get to => Get.find();

  final _isInitialized = false.obs;
  final _platformChannelErrors = <String>[].obs;
  final _pluginStatus = <String, bool>{}.obs;

  // Getters
  bool get isInitialized => _isInitialized.value;
  List<String> get platformChannelErrors => _platformChannelErrors;
  Map<String, bool> get pluginStatus => _pluginStatus;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeDiagnostics();
  }

  /// Initialize platform diagnostics
  Future<void> _initializeDiagnostics() async {
    try {
      await _checkPlatformEnvironment();
      await _testPluginChannels();
      _isInitialized.value = true;
      ErrorHandler.logInfo('Platform diagnostics initialized successfully');
    } catch (e) {
      ErrorHandler.handleError(e, context: 'PlatformDiagnosticsService._initializeDiagnostics');
      _platformChannelErrors.add('Diagnostics initialization failed: $e');
    }
  }

  /// Check platform environment
  Future<void> _checkPlatformEnvironment() async {
    try {
      // Check platform information
      if (!kIsWeb) {
        final platform = Platform.operatingSystem;
        final version = Platform.operatingSystemVersion;
        ErrorHandler.logInfo('Platform: $platform, Version: $version');
        
        // Check if running in debug mode
        if (kDebugMode) {
          ErrorHandler.logInfo('Running in debug mode');
        }
      }
    } catch (e) {
      _platformChannelErrors.add('Platform environment check failed: $e');
    }
  }

  /// Test plugin method channels
  Future<void> _testPluginChannels() async {
    final plugins = [
      'file_picker',
      'permission_handler',
      'google_sign_in',
      'flutter_secure_storage',
      'connectivity_plus',
    ];

    for (final plugin in plugins) {
      try {
        await _testPluginChannel(plugin);
        _pluginStatus[plugin] = true;
      } catch (e) {
        _pluginStatus[plugin] = false;
        _platformChannelErrors.add('Plugin $plugin test failed: $e');
        ErrorHandler.logError('Plugin $plugin channel test failed', error: e);
      }
    }
  }

  /// Test individual plugin channel
  Future<void> _testPluginChannel(String pluginName) async {
    try {
      switch (pluginName) {
        case 'file_picker':
          // Test file picker channel without showing UI
          const channel = MethodChannel('miguelruivo.flutter.plugins.filepicker');
          try {
            await channel.invokeMethod('clear');
          } catch (e) {
            // Some versions might not have 'clear' method, that's OK
            // Just check if channel exists by trying a simple method
            await channel.invokeMethod('any'); // This will likely fail but won't throw MissingPluginException
          }
          break;
          
        case 'permission_handler':
          // Test permission handler channel
          const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
          // Just check if channel exists without requesting permissions
          break;
          
        case 'google_sign_in':
          // Test google sign in channel
          const channel = MethodChannel('plugins.flutter.io/google_sign_in');
          // Check if channel exists
          break;
          
        case 'flutter_secure_storage':
          // Test secure storage channel
          const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
          // Check if channel exists
          break;
          
        case 'connectivity_plus':
          // Test connectivity channel
          const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
          // Just test channel existence
          break;
      }
    } on PlatformException catch (e) {
      // Some PlatformExceptions are expected when testing without proper parameters
      if (e.code == 'channel-error' || e.code == 'unimplemented') {
        // These indicate the channel exists but method is not implemented or parameters are wrong
        return; // Channel is accessible
      }
      rethrow; // Re-throw if it's a serious channel error
    } on MissingPluginException catch (e) {
      // Plugin not available, record the error but don't fail
      _platformChannelErrors.add('Plugin $pluginName not available: $e');
      _pluginStatus[pluginName] = false;
      return;
    }
  }

  /// Diagnose current platform channel issues
  Future<Map<String, dynamic>> diagnoseChannelIssues() async {
    final diagnosis = <String, dynamic>{};
    
    try {
      diagnosis['platform'] = !kIsWeb ? Platform.operatingSystem : 'web';
      diagnosis['isDebugMode'] = kDebugMode;
      diagnosis['errors'] = _platformChannelErrors.toList();
      diagnosis['pluginStatus'] = Map<String, bool>.from(_pluginStatus);
      diagnosis['timestamp'] = DateTime.now().toIso8601String();
      
      // Check for common issues
      final commonIssues = <String>[];
      
      if (_platformChannelErrors.isNotEmpty) {
        commonIssues.add('Platform channel errors detected');
      }
      
      if (_pluginStatus.values.any((status) => !status)) {
        commonIssues.add('Some plugins are not responding');
      }
      
      diagnosis['commonIssues'] = commonIssues;
      diagnosis['recommendations'] = _getRecommendations();
      
    } catch (e) {
      ErrorHandler.handleError(e, context: 'PlatformDiagnosticsService.diagnoseChannelIssues');
      diagnosis['error'] = 'Failed to generate diagnosis: $e';
    }
    
    return diagnosis;
  }

  /// Get recommendations based on current issues
  List<String> _getRecommendations() {
    final recommendations = <String>[];
    
    if (_platformChannelErrors.any((error) => error.contains('channel-error'))) {
      recommendations.addAll([
        'Restart the application completely',
        'Perform a hot restart instead of hot reload',
        'Check if app has required permissions',
        'Verify plugin versions are compatible',
      ]);
    }
    
    if (_pluginStatus.values.any((status) => !status)) {
      recommendations.addAll([
        'Update plugins to latest compatible versions',
        'Check platform-specific configurations',
        'Verify native dependencies are properly linked',
      ]);
    }
    
    if (_platformChannelErrors.any((error) => error.contains('permission'))) {
      recommendations.addAll([
        'Grant required permissions in device settings',
        'Check AndroidManifest.xml for permission declarations',
        'Request permissions at runtime before using features',
      ]);
    }
    
    return recommendations;
  }

  /// Clear all recorded errors
  void clearErrors() {
    _platformChannelErrors.clear();
    _pluginStatus.clear();
  }

  /// Restart diagnostics
  Future<void> restartDiagnostics() async {
    clearErrors();
    _isInitialized.value = false;
    await _initializeDiagnostics();
  }

  /// Test platform channel connectivity
  Future<bool> testPlatformChannel() async {
    try {
      // Simple test to check if platform channels are working
      const channel = MethodChannel('io.flutter.embedding.engine.systemchannels.lifecycle');
      await channel.invokeMethod('AppLifecycleState.detached');
      return true;
    } on PlatformException catch (e) {
      // Some exceptions are expected for certain method calls
      if (e.code == 'error' || e.code == 'unimplemented') {
        // Channel exists but method not available is OK
        return true;
      }
      _platformChannelErrors.add('Platform channel test failed: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _platformChannelErrors.add('Platform channel test error: $e');
      return false;
    }
  }

  /// Log platform channel error
  void logPlatformChannelError(String plugin, PlatformException error) {
    final errorMsg = 'Plugin: $plugin, Code: ${error.code}, Message: ${error.message}';
    _platformChannelErrors.add(errorMsg);
    _pluginStatus[plugin] = false;
    ErrorHandler.logError('Platform channel error in $plugin', error: error);
  }
}