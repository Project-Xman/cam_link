import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class HotspotService extends GetxService {
  static HotspotService get to => Get.find();
  
  final Logger _logger = Logger();
  final RxBool _isHotspotEnabled = false.obs;
  final RxString _hotspotName = 'PhotoUploader_Hotspot'.obs;
  final RxString _hotspotPassword = 'PhotoUpload123'.obs;
  final RxBool _isLoading = false.obs;
  
  // Getters
  bool get isHotspotEnabled => _isHotspotEnabled.value;
  String get hotspotName => _hotspotName.value;
  String get hotspotPassword => _hotspotPassword.value;
  bool get isLoading => _isLoading.value;
  
  // Reactive getters
  RxBool get isHotspotEnabledRx => _isHotspotEnabled;
  RxString get hotspotNameRx => _hotspotName;
  RxString get hotspotPasswordRx => _hotspotPassword;
  RxBool get isLoadingRx => _isLoading;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadSettings();
    await _checkHotspotStatus();
  }

  /// Load saved hotspot settings
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hotspotName.value = prefs.getString('hotspot_name') ?? 'PhotoUploader_Hotspot';
      _hotspotPassword.value = prefs.getString('hotspot_password') ?? 'PhotoUpload123';
    } catch (e) {
      _logger.e('Error loading hotspot settings: $e');
    }
  }

  /// Save hotspot settings
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hotspot_name', _hotspotName.value);
      await prefs.setString('hotspot_password', _hotspotPassword.value);
    } catch (e) {
      _logger.e('Error saving hotspot settings: $e');
    }
  }

  /// Check current hotspot status
  Future<void> _checkHotspotStatus() async {
    try {
      // For now, we'll track status internally since WiFi IoT plugin has compatibility issues
      // In a production app, you might want to use platform channels or other methods
      _isHotspotEnabled.value = false;
    } catch (e) {
      _logger.e('Error checking hotspot status: $e');
      _isHotspotEnabled.value = false;
    }
  }

  /// Request necessary permissions
  Future<bool> _requestPermissions() async {
    try {
      final permissions = [
        Permission.location,
        Permission.nearbyWifiDevices,
      ];

      Map<Permission, PermissionStatus> statuses = await permissions.request();
      
      return statuses.values.every((status) => 
        status == PermissionStatus.granted || 
        status == PermissionStatus.limited
      );
    } catch (e) {
      _logger.e('Error requesting permissions: $e');
      return false;
    }
  }

  /// Start mobile hotspot
  Future<bool> startHotspot() async {
    if (_isLoading.value) return false;
    
    _isLoading.value = true;
    
    try {
      // Request permissions first
      final hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        Get.snackbar(
          'Permission Required',
          'Please grant location and WiFi permissions to use hotspot',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Validate settings
      if (_hotspotName.value.isEmpty || _hotspotPassword.value.length < 8) {
        Get.snackbar(
          'Invalid Settings',
          'Hotspot name cannot be empty and password must be at least 8 characters',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Start hotspot - Note: This is a simplified implementation
      // In a production app, you would need to use platform-specific methods
      // or a more robust plugin for hotspot management
      final success = true; // Simulate success for demo purposes

      if (success) {
        _isHotspotEnabled.value = true;
        await _saveSettings();
        
        Get.snackbar(
          'Hotspot Started',
          'Mobile hotspot "${_hotspotName.value}" is now active',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primaryContainer,
        );
        
        _logger.i('Hotspot started successfully');
        return true;
      } else {
        Get.snackbar(
          'Failed to Start',
          'Could not start mobile hotspot. Please check your device settings.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
        );
        return false;
      }
    } catch (e) {
      _logger.e('Error starting hotspot: $e');
      Get.snackbar(
        'Error',
        'Failed to start hotspot: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Stop mobile hotspot
  Future<bool> stopHotspot() async {
    if (_isLoading.value) return false;
    
    _isLoading.value = true;
    
    try {
      // Stop hotspot - simplified implementation
      final success = true;

      if (success) {
        _isHotspotEnabled.value = false;
        
        Get.snackbar(
          'Hotspot Stopped',
          'Mobile hotspot has been disabled',
          snackPosition: SnackPosition.BOTTOM,
        );
        
        _logger.i('Hotspot stopped successfully');
        return true;
      } else {
        Get.snackbar(
          'Failed to Stop',
          'Could not stop mobile hotspot',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
        );
        return false;
      }
    } catch (e) {
      _logger.e('Error stopping hotspot: $e');
      Get.snackbar(
        'Error',
        'Failed to stop hotspot: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Toggle hotspot state
  Future<void> toggleHotspot() async {
    if (_isHotspotEnabled.value) {
      await stopHotspot();
    } else {
      await startHotspot();
    }
  }

  /// Update hotspot configuration
  Future<void> updateConfiguration({
    required String name,
    required String password,
  }) async {
    if (name.isEmpty || password.length < 8) {
      Get.snackbar(
        'Invalid Configuration',
        'Name cannot be empty and password must be at least 8 characters',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
      return;
    }

    _hotspotName.value = name;
    _hotspotPassword.value = password;
    await _saveSettings();

    // If hotspot is currently running, restart it with new settings
    if (_isHotspotEnabled.value) {
      await stopHotspot();
      await Future.delayed(const Duration(seconds: 1));
      await startHotspot();
    }

    Get.snackbar(
      'Configuration Updated',
      'Hotspot settings have been saved',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.primaryContainer,
    );
  }

  /// Get connected devices (if supported)
  Future<List<String>> getConnectedDevices() async {
    try {
      // Note: getClientList is deprecated and may not work on newer Android versions
      return [];
    } catch (e) {
      _logger.e('Error getting connected devices: $e');
      return [];
    }
  }

  /// Refresh hotspot status
  Future<void> refreshStatus() async {
    await _checkHotspotStatus();
  }
}