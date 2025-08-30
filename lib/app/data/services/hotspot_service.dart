import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

class HotspotService extends GetxService {
  static HotspotService get to => Get.find();
  
  final Logger _logger = Logger();
  final RxBool _isHotspotEnabled = false.obs;
  final RxString _hotspotName = 'PhotoUploader_Hotspot'.obs;
  final RxString _hotspotPassword = 'PhotoUpload123'.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isWifiEnabled = false.obs;
  final RxBool _isMobileDataEnabled = false.obs;
  
  // Platform channels for native hotspot management
  static const MethodChannel _hotspotChannel = MethodChannel('com.photoUploader/hotspot');
  static const MethodChannel _wifiChannel = MethodChannel('com.photoUploader/wifi');
  
  // Getters
  bool get isHotspotEnabled => _isHotspotEnabled.value;
  String get hotspotName => _hotspotName.value;
  String get hotspotPassword => _hotspotPassword.value;
  bool get isLoading => _isLoading.value;
  bool get isWifiEnabled => _isWifiEnabled.value;
  bool get isMobileDataEnabled => _isMobileDataEnabled.value;
  
  // Reactive getters
  RxBool get isHotspotEnabledRx => _isHotspotEnabled;
  RxString get hotspotNameRx => _hotspotName;
  RxString get hotspotPasswordRx => _hotspotPassword;
  RxBool get isLoadingRx => _isLoading;
  RxBool get isWifiEnabledRx => _isWifiEnabled;
  RxBool get isMobileDataEnabledRx => _isMobileDataEnabled;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadSettings();
    await _checkNetworkStatus();
    await _checkHotspotStatus();
    
    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _checkNetworkStatus();
    });
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

  /// Check current network status
  Future<void> _checkNetworkStatus() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _isWifiEnabled.value = connectivityResult == ConnectivityResult.wifi;
      _isMobileDataEnabled.value = connectivityResult == ConnectivityResult.mobile;
      
      _logger.i('Network status - WiFi: ${_isWifiEnabled.value}, Mobile: ${_isMobileDataEnabled.value}');
    } catch (e) {
      _logger.e('Error checking network status: $e');
    }
  }
  
  /// Check current hotspot status
  Future<void> _checkHotspotStatus() async {
    try {
      if (Platform.isAndroid) {
        final bool isEnabled = await _hotspotChannel.invokeMethod('isHotspotEnabled') ?? false;
        _isHotspotEnabled.value = isEnabled;
      } else {
        // For iOS/other platforms, hotspot is not directly controllable
        _isHotspotEnabled.value = false;
      }
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
      
      // Add system alert window permission for hotspot on Android
      if (Platform.isAndroid) {
        permissions.add(Permission.systemAlertWindow);
      }

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
  
  /// Enable WiFi if disabled
  Future<bool> _enableWifi() async {
    try {
      if (Platform.isAndroid) {
        final bool success = await _wifiChannel.invokeMethod('enableWifi') ?? false;
        if (success) {
          _isWifiEnabled.value = true;
          _logger.i('WiFi enabled successfully');
        }
        return success;
      }
      return true; // iOS WiFi cannot be programmatically controlled
    } catch (e) {
      _logger.e('Error enabling WiFi: $e');
      return false;
    }
  }
  
  /// Disable WiFi if enabled (for non-simultaneous devices)
  Future<bool> _disableWifi() async {
    try {
      if (Platform.isAndroid) {
        final bool success = await _wifiChannel.invokeMethod('disableWifi') ?? false;
        if (success) {
          _isWifiEnabled.value = false;
          _logger.i('WiFi disabled successfully');
        }
        return success;
      }
      return true; // iOS WiFi cannot be programmatically controlled
    } catch (e) {
      _logger.e('Error disabling WiFi: $e');
      return false;
    }
  }
  
  /// Check if device supports simultaneous WiFi and mobile hotspot
  Future<bool> _checkSimultaneousSupport() async {
    try {
      if (Platform.isAndroid) {
        final bool isSupported = await _hotspotChannel.invokeMethod('supportsSimultaneous') ?? false;
        return isSupported;
      }
      return false; // iOS doesn't support this
    } catch (e) {
      _logger.e('Error checking simultaneous support: $e');
      return false;
    }
  }

  /// Start mobile hotspot with improved device compatibility
  Future<bool> startHotspot() async {
    if (_isLoading.value) return false;
    
    _isLoading.value = true;
    
    try {
      // Check platform support
      if (!Platform.isAndroid) {
        Get.snackbar(
          'Not Supported',
          'Hotspot control is only available on Android devices',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
        );
        return false;
      }
      
      // Check if device supports hotspot functionality
      final isSupported = await isHotspotSupported();
      if (!isSupported) {
        Get.snackbar(
          'Not Supported',
          'Hotspot functionality is not supported on this device',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
        );
        return false;
      }
      
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
      
      // Check current hotspot status first
      await _checkHotspotStatus();
      if (_isHotspotEnabled.value) {
        Get.snackbar(
          'Already Running',
          'Mobile hotspot is already enabled',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primaryContainer,
        );
        return true;
      }
      
      // Check device capabilities and handle WiFi appropriately
      final supportsSimultaneous = await _checkSimultaneousSupport();
      await _checkNetworkStatus();
      
      _logger.i('Device supports simultaneous WiFi/Hotspot: $supportsSimultaneous');
      _logger.i('Current WiFi status: ${_isWifiEnabled.value}, Mobile: ${_isMobileDataEnabled.value}');
      
      // Handle WiFi requirements based on device capabilities
      if (!supportsSimultaneous) {
        // Device doesn't support simultaneous - need mobile data
        if (!_isMobileDataEnabled.value) {
          Get.snackbar(
            'Mobile Data Required',
            'This device requires mobile data to use hotspot. Please enable mobile data first.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.errorContainer,
            duration: const Duration(seconds: 5),
          );
          await openHotspotSettings();
          return false;
        }
        
        // Disable WiFi if it's connected to allow hotspot
        if (_isWifiEnabled.value) {
          _logger.i('Disabling WiFi to enable hotspot on non-simultaneous device');
          final wifiDisabled = await _disableWifi();
          if (!wifiDisabled) {
            Get.snackbar(
              'WiFi Conflict',
              'Please manually disable WiFi to enable hotspot on this device',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Get.theme.colorScheme.errorContainer,
            );
            await openHotspotSettings();
            return false;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      } else {
        // Device supports simultaneous - ensure mobile data is available
        if (!_isMobileDataEnabled.value && !_isWifiEnabled.value) {
          Get.snackbar(
            'Internet Connection Required',
            'Please enable mobile data or WiFi for hotspot to provide internet access',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.errorContainer,
          );
          return false;
        }
      }

      // Attempt to start hotspot using platform channel
      final Map<String, dynamic> config = {
        'ssid': _hotspotName.value,
        'password': _hotspotPassword.value,
        'security': 'WPA2',
      };
      
      final bool success = await _hotspotChannel.invokeMethod('startHotspot', config) ?? false;

      if (success) {
        _isHotspotEnabled.value = true;
        await _saveSettings();
        
        // Update network status
        await _checkNetworkStatus();
        
        Get.snackbar(
          'Hotspot Started',
          'Mobile hotspot "${_hotspotName.value}" is now active',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primaryContainer,
        );
        
        _logger.i('Hotspot started successfully');
        return true;
      } else {
        // If platform method fails, guide user to manual setup
        Get.snackbar(
          'Manual Setup Required',
          'Please enable hotspot manually in device settings. Tap to open settings.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
          duration: const Duration(seconds: 7),
          mainButton: TextButton(
            onPressed: () => openHotspotSettings(),
            child: const Text('OPEN SETTINGS'),
          ),
        );
        await openHotspotSettings();
        return false;
      }
    } on PlatformException catch (e) {
      _logger.e('Platform exception starting hotspot: $e');
      
      String errorMessage = 'Failed to start hotspot';
      bool showSettings = false;
      
      if (e.code == 'PERMISSION_DENIED') {
        errorMessage = 'Permission denied. Please grant hotspot permissions in device settings.';
        showSettings = true;
      } else if (e.code == 'NOT_SUPPORTED') {
        errorMessage = 'Hotspot is not supported on this device.';
      } else if (e.code == 'ALREADY_ENABLED') {
        errorMessage = 'Hotspot is already enabled.';
        _isHotspotEnabled.value = true;
        return true;
      } else if (e.code == 'REQUIRES_SETTINGS') {
        errorMessage = 'This Android version requires manual hotspot setup.';
        showSettings = true;
      }
      
      Get.snackbar(
        'Platform Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
        duration: const Duration(seconds: 5),
        mainButton: showSettings ? TextButton(
          onPressed: () => openHotspotSettings(),
          child: const Text('SETTINGS'),
        ) : null,
      );
      
      if (showSettings) {
        await openHotspotSettings();
      }
      
      return false;
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
      // Check platform support
      if (!Platform.isAndroid) {
        Get.snackbar(
          'Not Supported',
          'Hotspot control is only available on Android devices',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
        );
        return false;
      }
      
      // Check if hotspot is already disabled
      await _checkHotspotStatus();
      if (!_isHotspotEnabled.value) {
        Get.snackbar(
          'Already Stopped',
          'Mobile hotspot is already disabled',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primaryContainer,
        );
        return true;
      }
      
      // Stop hotspot using platform channel
      final bool success = await _hotspotChannel.invokeMethod('stopHotspot') ?? false;

      if (success) {
        _isHotspotEnabled.value = false;
        
        // Update network status
        await _checkNetworkStatus();
        
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
          'Could not stop mobile hotspot. Please try disabling it manually.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
        );
        return false;
      }
    } on PlatformException catch (e) {
      _logger.e('Platform exception stopping hotspot: $e');
      
      String errorMessage = 'Failed to stop hotspot';
      if (e.code == 'PERMISSION_DENIED') {
        errorMessage = 'Permission denied. Please grant hotspot permissions in device settings.';
      } else if (e.code == 'NOT_SUPPORTED') {
        errorMessage = 'Hotspot is not supported on this device.';
      } else if (e.code == 'ALREADY_DISABLED') {
        errorMessage = 'Hotspot is already disabled.';
        _isHotspotEnabled.value = false;
        return true;
      }
      
      Get.snackbar(
        'Platform Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
      return false;
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
  Future<List<Map<String, dynamic>>> getConnectedDevices() async {
    try {
      if (Platform.isAndroid && _isHotspotEnabled.value) {
        final List<dynamic> devices = await _hotspotChannel.invokeMethod('getConnectedDevices') ?? [];
        return devices.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      _logger.e('Error getting connected devices: $e');
      return [];
    }
  }
  
  /// Get network information for debugging
  Future<Map<String, dynamic>> getNetworkInfo() async {
    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();
      final wifiName = await info.getWifiName();
      final wifiBSSID = await info.getWifiBSSID();
      
      return {
        'wifiIP': wifiIP,
        'wifiName': wifiName,
        'wifiBSSID': wifiBSSID,
        'isWifiEnabled': _isWifiEnabled.value,
        'isMobileDataEnabled': _isMobileDataEnabled.value,
        'isHotspotEnabled': _isHotspotEnabled.value,
      };
    } catch (e) {
      _logger.e('Error getting network info: $e');
      return {};
    }
  }

  /// Refresh all status
  Future<void> refreshStatus() async {
    await _checkNetworkStatus();
    await _checkHotspotStatus();
  }
  
  /// Open device hotspot settings
  Future<void> openHotspotSettings() async {
    try {
      if (Platform.isAndroid) {
        await _hotspotChannel.invokeMethod('openHotspotSettings');
      } else {
        Get.snackbar(
          'Settings',
          'Please manually enable Personal Hotspot in Settings > Personal Hotspot',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      _logger.e('Error opening hotspot settings: $e');
      Get.snackbar(
        'Error',
        'Could not open hotspot settings. Please navigate manually.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
    }
  }
}

/// Extension methods for better error handling and device compatibility
extension HotspotServiceExtensions on HotspotService {
  /// Check if the current device supports hotspot functionality
  Future<bool> isHotspotSupported() async {
    try {
      if (Platform.isAndroid) {
        return await HotspotService._hotspotChannel.invokeMethod('isSupported') ?? false;
      }
      return false; // iOS doesn't allow programmatic hotspot control
    } catch (e) {
      _logger.e('Error checking hotspot support: $e');
      return false;
    }
  }
  
  /// Get device-specific hotspot limitations
  Future<Map<String, dynamic>> getDeviceLimitations() async {
    try {
      if (Platform.isAndroid) {
        return await HotspotService._hotspotChannel.invokeMethod('getDeviceLimitations') ?? {};
      }
      return {
        'maxConnectedDevices': 0,
        'supportsSimultaneous': false,
        'supportedSecurityTypes': [],
        'reason': 'iOS does not allow programmatic hotspot control'
      };
    } catch (e) {
      _logger.e('Error getting device limitations: $e');
      return {};
    }
  }
}