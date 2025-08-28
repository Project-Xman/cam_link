import 'dart:async';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/utils/platform_utils.dart';

/// Service to check sensor availability and provide fallback mechanisms
class SensorAvailabilityService extends GetxService {
  static SensorAvailabilityService get to => Get.find();
  
  final Logger _logger = Logger();
  
  final RxBool _hasAccelerometer = false.obs;
  final RxBool _hasGyroscope = false.obs;
  final RxBool _sensorsChecked = false.obs;
  
  bool get hasAccelerometer => _hasAccelerometer.value;
  bool get hasGyroscope => _hasGyroscope.value;
  bool get sensorsChecked => _sensorsChecked.value;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    await _checkSensorAvailability();
  }

  /// Check if sensors are available on the device
  Future<void> _checkSensorAvailability() async {
    try {
      // Check platform first - desktop platforms typically don't have sensors
      if (!PlatformUtils.supportsSensors) {
        _logger.i('${PlatformUtils.platformName} platform detected - sensors not expected');
        _hasAccelerometer.value = false;
        _hasGyroscope.value = false;
        _sensorsChecked.value = true;
        return;
      }

      // Test accelerometer availability
      await _testAccelerometer();
      
      // Test gyroscope availability  
      await _testGyroscope();

      _sensorsChecked.value = true;
      
      _logger.i('Sensor availability check complete:');
      _logger.i('  Platform: ${PlatformUtils.platformName}');
      _logger.i('  Accelerometer: ${_hasAccelerometer.value}');
      _logger.i('  Gyroscope: ${_hasGyroscope.value}');
      
    } catch (e) {
      _logger.e('Error checking sensor availability: $e');
      _hasAccelerometer.value = false;
      _hasGyroscope.value = false;
      _sensorsChecked.value = true;
    }
  }

  /// Test accelerometer availability with safe subscription handling
  Future<void> _testAccelerometer() async {
    StreamSubscription? accelSub;
    bool accelAvailable = false;
    
    try {
      final completer = Completer<void>();
      
      accelSub = accelerometerEventStream().listen(
        (event) {
          accelAvailable = true;
          if (!completer.isCompleted) completer.complete();
        },
        onError: (error) {
          _logger.w('Accelerometer not available: $error');
          accelAvailable = false;
          if (!completer.isCompleted) completer.complete();
        },
      );
      
      // Wait for either data or timeout
      await Future.any([
        completer.future,
        Future.delayed(const Duration(milliseconds: 1000)),
      ]);
      
      _hasAccelerometer.value = accelAvailable;
    } catch (e) {
      _logger.w('Accelerometer check failed: $e');
      _hasAccelerometer.value = false;
    } finally {
      await _safelyCancel(accelSub, 'accelerometer');
    }
  }

  /// Test gyroscope availability with safe subscription handling
  Future<void> _testGyroscope() async {
    StreamSubscription? gyroSub;
    bool gyroAvailable = false;
    
    try {
      final completer = Completer<void>();
      
      gyroSub = gyroscopeEventStream().listen(
        (event) {
          gyroAvailable = true;
          if (!completer.isCompleted) completer.complete();
        },
        onError: (error) {
          _logger.w('Gyroscope not available: $error');
          gyroAvailable = false;
          if (!completer.isCompleted) completer.complete();
        },
      );
      
      // Wait for either data or timeout
      await Future.any([
        completer.future,
        Future.delayed(const Duration(milliseconds: 1000)),
      ]);
      
      _hasGyroscope.value = gyroAvailable;
    } catch (e) {
      _logger.w('Gyroscope check failed: $e');
      _hasGyroscope.value = false;
    } finally {
      await _safelyCancel(gyroSub, 'gyroscope');
    }
  }

  /// Safely cancel subscription with error handling
  Future<void> _safelyCancel(StreamSubscription? subscription, String sensorName) async {
    if (subscription == null) return;
    
    try {
      await subscription.cancel();
    } catch (e) {
      _logger.w('Error canceling $sensorName subscription: $e');
      // Ignore cancellation errors on platforms that don't support sensors
    }
  }



  /// Get sensor status summary
  Map<String, dynamic> getSensorStatus() {
    return {
      'accelerometer_available': _hasAccelerometer.value,
      'gyroscope_available': _hasGyroscope.value,
      'sensors_checked': _sensorsChecked.value,
      'fallback_mode': !_hasAccelerometer.value || !_hasGyroscope.value,
    };
  }
}