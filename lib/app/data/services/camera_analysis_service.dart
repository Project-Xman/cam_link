import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'sensor_availability_service.dart';


class CameraSettings {
  final double exposureTime;
  final double iso;
  final double aperture;
  final double focalLength;
  final double whiteBalance;
  final double brightness;
  final double contrast;
  final double saturation;
  final String flashMode;
  final String focusMode;
  final bool isStabilized;

  CameraSettings({
    required this.exposureTime,
    required this.iso,
    required this.aperture,
    required this.focalLength,
    required this.whiteBalance,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.flashMode,
    required this.focusMode,
    required this.isStabilized,
  });
}

class EnvironmentData {
  final double temperature;
  final double humidity;
  final double lightLevel;
  final double deviceTilt;
  final double deviceRotation;
  final bool isStable;
  final String lightingCondition;
  final String recommendation;

  EnvironmentData({
    required this.temperature,
    required this.humidity,
    required this.lightLevel,
    required this.deviceTilt,
    required this.deviceRotation,
    required this.isStable,
    required this.lightingCondition,
    required this.recommendation,
  });
}

class FocusPoint {
  final double x;
  final double y;
  final double confidence;
  final double sharpness;
  final bool isOptimal;

  FocusPoint({
    required this.x,
    required this.y,
    required this.confidence,
    required this.sharpness,
    required this.isOptimal,
  });
}

class CameraAnalysisService extends GetxService {
  static CameraAnalysisService get to => Get.find();
  
  final Logger _logger = Logger();
  
  // Camera controller
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  
  // Sensor streams
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  // Reactive variables
  final RxBool _isInitialized = false.obs;
  final RxBool _isAnalyzing = false.obs;
  final RxBool _isCameraActive = false.obs;
  final Rx<CameraSettings?> _currentSettings = Rx<CameraSettings?>(null);
  final Rx<EnvironmentData?> _environmentData = Rx<EnvironmentData?>(null);
  final Rx<FocusPoint?> _focusPoint = Rx<FocusPoint?>(null);
  final RxDouble _estimatedTemperature = 20.0.obs;
  final RxString _photographyTip = ''.obs;
  final RxList<String> _recommendations = <String>[].obs;
  
  // Analysis parameters
  Timer? _analysisTimer;
  double _lastAccelX = 0.0;
  double _lastAccelY = 0.0;
  double _lastAccelZ = 0.0;
  double _deviceStability = 0.0;
  
  // Getters
  bool get isInitialized => _isInitialized.value;
  bool get isAnalyzing => _isAnalyzing.value;
  bool get isCameraActive => _isCameraActive.value;
  CameraSettings? get currentSettings => _currentSettings.value;
  EnvironmentData? get environmentData => _environmentData.value;
  FocusPoint? get focusPoint => _focusPoint.value;
  double get estimatedTemperature => _estimatedTemperature.value;
  String get photographyTip => _photographyTip.value;
  List<String> get recommendations => _recommendations;
  CameraController? get cameraController => _cameraController;
  
  // Reactive getters
  RxBool get isInitializedRx => _isInitialized;
  RxBool get isAnalyzingRx => _isAnalyzing;
  RxBool get isCameraActiveRx => _isCameraActive;
  Rx<CameraSettings?> get currentSettingsRx => _currentSettings;
  Rx<EnvironmentData?> get environmentDataRx => _environmentData;
  Rx<FocusPoint?> get focusPointRx => _focusPoint;
  RxDouble get estimatedTemperatureRx => _estimatedTemperature;
  RxString get photographyTipRx => _photographyTip;
  RxList<String> get recommendationsRx => _recommendations;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeCameras();
    _initializeSensors();
  }

  @override
  void onClose() {
    stopAnalysis();
    _disposeCameras();
    _disposeSensors();
    super.onClose();
  }

  /// Initialize available cameras
  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
      _isInitialized.value = _cameras.isNotEmpty;
      
      if (_cameras.isNotEmpty) {
        _logger.i('Found ${_cameras.length} cameras');
      } else {
        _logger.w('No cameras found on device');
      }
    } catch (e) {
      _logger.e('Error initializing cameras: $e');
      _isInitialized.value = false;
    }
  }

  /// Initialize sensor listeners
  void _initializeSensors() {
    // Check if sensor availability service is available
    try {
      final sensorService = SensorAvailabilityService.to;
      
      // Wait for sensor check to complete
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (sensorService.sensorsChecked) {
          timer.cancel();
          _setupSensorListeners(sensorService);
        }
      });
    } catch (e) {
      _logger.w('SensorAvailabilityService not available, using direct sensor access');
      _setupSensorListeners(null);
    }
  }

  /// Setup sensor listeners based on availability
  void _setupSensorListeners(SensorAvailabilityService? sensorService) {
    try {
      // Check if accelerometer is available
      if (sensorService?.hasAccelerometer ?? true) {
        _accelerometerSubscription = accelerometerEventStream().listen(
          (event) {
            _lastAccelX = event.x;
            _lastAccelY = event.y;
            _lastAccelZ = event.z;
            _calculateDeviceStability();
          },
          onError: (error) {
            _logger.w('Accelerometer error: $error');
            _initializeFallbackSensors();
          },
        );
      } else {
        _logger.i('Accelerometer not available, using fallback');
        _initializeFallbackSensors();
      }

      // Check if gyroscope is available
      if (sensorService?.hasGyroscope ?? true) {
        _gyroscopeSubscription = gyroscopeEventStream().listen(
          (event) {
            // Process gyroscope data for advanced stability analysis
            _updateEnvironmentData();
          },
          onError: (error) {
            _logger.w('Gyroscope error: $error');
            // Continue without gyroscope data
          },
        );
      } else {
        _logger.i('Gyroscope not available, continuing without it');
      }
      
      _logger.i('Sensor listeners initialized successfully');
    } catch (e) {
      _logger.e('Error initializing sensors: $e');
      _initializeFallbackSensors();
    }
  }

  /// Initialize fallback sensor simulation when hardware sensors are not available
  void _initializeFallbackSensors() {
    _logger.i('Using simulated sensor data - hardware sensors not available');
    
    // Set default values for missing sensors
    _deviceStability = 0.8; // Assume reasonably stable
    _lastAccelX = 0.0;
    _lastAccelY = 0.0;
    _lastAccelZ = 9.8; // Standard gravity
    
    // Start a timer to simulate sensor updates
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isInitialized.value) {
        timer.cancel();
        return;
      }
      
      // Add small random variations to simulate device movement
      _lastAccelX = (Random().nextDouble() - 0.5) * 0.2;
      _lastAccelY = (Random().nextDouble() - 0.5) * 0.2;
      _lastAccelZ = 9.8 + (Random().nextDouble() - 0.5) * 0.1;
      
      _calculateDeviceStability();
      _updateEnvironmentData();
    });
  }

  /// Start camera and analysis
  Future<bool> startCamera({int cameraIndex = 0}) async {
    if (!_isInitialized.value || _cameras.isEmpty) {
      return false;
    }

    try {
      if (cameraIndex >= _cameras.length) {
        cameraIndex = 0;
      }

      _cameraController = CameraController(
        _cameras[cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      _isCameraActive.value = true;
      
      // Start continuous analysis
      startAnalysis();
      
      _logger.i('Camera started successfully');
      return true;
    } catch (e) {
      _logger.e('Error starting camera: $e');
      _isCameraActive.value = false;
      return false;
    }
  }

  /// Stop camera
  Future<void> stopCamera() async {
    try {
      stopAnalysis();
      await _cameraController?.dispose();
      _cameraController = null;
      _isCameraActive.value = false;
      _logger.i('Camera stopped');
    } catch (e) {
      _logger.e('Error stopping camera: $e');
    }
  }

  /// Start continuous analysis
  void startAnalysis() {
    if (_isAnalyzing.value) return;
    
    _isAnalyzing.value = true;
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _performAnalysis();
    });
    
    _logger.i('Camera analysis started');
  }

  /// Stop analysis
  void stopAnalysis() {
    _isAnalyzing.value = false;
    _analysisTimer?.cancel();
    _analysisTimer = null;
    _logger.i('Camera analysis stopped');
  }

  /// Perform comprehensive camera analysis
  void _performAnalysis() {
    if (!_isCameraActive.value || _cameraController == null) return;

    try {
      _analyzeCameraSettings();
      _updateEnvironmentData();
      _generateRecommendations();
      _updatePhotographyTip();
    } catch (e) {
      _logger.e('Error during analysis: $e');
    }
  }

  /// Analyze current camera settings
  void _analyzeCameraSettings() {
    if (_cameraController == null) return;

    try {
      // Get current camera values (simulated for demo)
      final settings = CameraSettings(
        exposureTime: _estimateExposureTime(),
        iso: _estimateISO(),
        aperture: _estimateAperture(),
        focalLength: _estimateFocalLength(),
        whiteBalance: _estimateWhiteBalance(),
        brightness: _estimateBrightness(),
        contrast: _estimateContrast(),
        saturation: _estimateSaturation(),
        flashMode: _getFlashMode(),
        focusMode: _getFocusMode(),
        isStabilized: _isImageStabilized(),
      );

      _currentSettings.value = settings;
    } catch (e) {
      _logger.e('Error analyzing camera settings: $e');
    }
  }

  /// Calculate device stability from accelerometer
  void _calculateDeviceStability() {
    final totalAccel = sqrt(
      _lastAccelX * _lastAccelX + 
      _lastAccelY * _lastAccelY + 
      _lastAccelZ * _lastAccelZ
    );
    
    // Normalize stability (0-1, where 1 is most stable)
    _deviceStability = max(0.0, min(1.0, 1.0 - (totalAccel - 9.8).abs() / 5.0));
  }

  /// Update environment data
  void _updateEnvironmentData() {
    try {
      final temperature = _estimateTemperature();
      final lightLevel = _estimateLightLevel();
      final tilt = _calculateDeviceTilt();
      
      final environmentData = EnvironmentData(
        temperature: temperature,
        humidity: _estimateHumidity(),
        lightLevel: lightLevel,
        deviceTilt: tilt,
        deviceRotation: _calculateDeviceRotation(),
        isStable: _deviceStability > 0.7,
        lightingCondition: _getLightingCondition(lightLevel),
        recommendation: _getEnvironmentRecommendation(temperature, lightLevel),
      );

      _environmentData.value = environmentData;
      _estimatedTemperature.value = temperature;
    } catch (e) {
      _logger.e('Error updating environment data: $e');
    }
  }

  /// Generate photography recommendations
  void _generateRecommendations() {
    final recommendations = <String>[];
    final settings = _currentSettings.value;
    final environment = _environmentData.value;

    if (settings == null || environment == null) return;

    // Stability recommendations
    if (!environment.isStable) {
      recommendations.add('Use a tripod or stabilize your device for sharper images');
    }

    // Exposure recommendations
    if (settings.exposureTime > 1/60) {
      recommendations.add('Consider faster shutter speed to avoid motion blur');
    }

    // ISO recommendations
    if (settings.iso > 800) {
      recommendations.add('High ISO detected - consider adding more light to reduce noise');
    }

    // Lighting recommendations
    if (environment.lightLevel < 0.3) {
      recommendations.add('Low light detected - consider using flash or increasing exposure');
    } else if (environment.lightLevel > 0.8) {
      recommendations.add('Bright conditions - consider reducing exposure or using ND filter');
    }

    // Temperature recommendations
    if (environment.temperature < 5) {
      recommendations.add('Cold conditions - battery may drain faster, keep device warm');
    } else if (environment.temperature > 35) {
      recommendations.add('Hot conditions - avoid overheating, find shade when possible');
    }

    // Focus recommendations
    final focus = _focusPoint.value;
    if (focus != null && !focus.isOptimal) {
      recommendations.add('Focus point may not be optimal - tap to refocus');
    }

    _recommendations.value = recommendations;
  }

  /// Update photography tip
  void _updatePhotographyTip() {
    final settings = _currentSettings.value;
    final environment = _environmentData.value;

    if (settings == null || environment == null) return;

    String tip = '';

    // Generate contextual tips
    if (environment.lightingCondition == 'Golden Hour') {
      tip = 'Perfect golden hour lighting! Use lower ISO and capture warm tones.';
    } else if (environment.lightingCondition == 'Blue Hour') {
      tip = 'Blue hour magic! Use tripod and longer exposure for stunning results.';
    } else if (environment.lightingCondition == 'Overcast') {
      tip = 'Soft, even lighting perfect for portraits. No harsh shadows to worry about.';
    } else if (environment.lightingCondition == 'Bright Sun') {
      tip = 'Harsh lighting - find open shade or use fill flash for better results.';
    } else if (environment.lightingCondition == 'Low Light') {
      tip = 'Low light challenge! Use higher ISO, wider aperture, or add artificial light.';
    } else {
      tip = 'Analyze your scene and adjust settings for the best results.';
    }

    _photographyTip.value = tip;
  }

  /// Set focus point and analyze
  Future<void> setFocusPoint(double x, double y) async {
    if (_cameraController == null || !_isCameraActive.value) return;

    try {
      await _cameraController!.setFocusPoint(Offset(x, y));
      
      // Simulate focus analysis
      final focusPoint = FocusPoint(
        x: x,
        y: y,
        confidence: _calculateFocusConfidence(x, y),
        sharpness: _calculateSharpness(x, y),
        isOptimal: _isFocusOptimal(x, y),
      );

      _focusPoint.value = focusPoint;
      _logger.i('Focus point set at ($x, $y)');
    } catch (e) {
      _logger.e('Error setting focus point: $e');
    }
  }

  /// Switch between cameras
  Future<bool> switchCamera() async {
    if (_cameras.length < 2) return false;

    final currentIndex = _cameras.indexOf(_cameraController!.description);
    final nextIndex = (currentIndex + 1) % _cameras.length;

    await stopCamera();
    return await startCamera(cameraIndex: nextIndex);
  }

  /// Capture photo with current settings
  Future<XFile?> capturePhoto() async {
    if (_cameraController == null || !_isCameraActive.value) return null;

    try {
      final image = await _cameraController!.takePicture();
      _logger.i('Photo captured: ${image.path}');
      return image;
    } catch (e) {
      _logger.e('Error capturing photo: $e');
      return null;
    }
  }

  // Estimation methods (simulated for demo - in real app, these would use actual camera APIs)
  
  double _estimateExposureTime() {
    final lightLevel = _estimateLightLevel();
    return lightLevel > 0.7 ? 1/250 : lightLevel > 0.4 ? 1/125 : 1/60;
  }

  double _estimateISO() {
    final lightLevel = _estimateLightLevel();
    return lightLevel > 0.7 ? 100 : lightLevel > 0.4 ? 400 : 800;
  }

  double _estimateAperture() => 2.8; // Most mobile cameras have fixed aperture

  double _estimateFocalLength() => 26.0; // Typical mobile camera focal length

  double _estimateWhiteBalance() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour <= 10) return 5500; // Morning
    if (hour >= 11 && hour <= 15) return 6500; // Midday
    if (hour >= 16 && hour <= 19) return 3200; // Evening
    return 2800; // Night
  }

  double _estimateBrightness() => _estimateLightLevel();

  double _estimateContrast() => 0.5;

  double _estimateSaturation() => 0.6;

  String _getFlashMode() => 'auto';

  String _getFocusMode() => 'continuous';

  bool _isImageStabilized() => true; // Most modern phones have OIS

  double _estimateTemperature() {
    // Simulate temperature based on time and device sensors
    final hour = DateTime.now().hour;
    final baseTemp = 20.0;
    final variation = sin((hour - 6) * pi / 12) * 10;
    return baseTemp + variation + Random().nextDouble() * 4 - 2;
  }

  double _estimateHumidity() => 50.0 + Random().nextDouble() * 30;

  double _estimateLightLevel() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour <= 8) return 0.4; // Dawn
    if (hour >= 9 && hour <= 16) return 0.9; // Day
    if (hour >= 17 && hour <= 19) return 0.6; // Dusk
    return 0.1; // Night
  }

  double _calculateDeviceTilt() {
    return atan2(_lastAccelY, _lastAccelZ) * 180 / pi;
  }

  double _calculateDeviceRotation() {
    return atan2(_lastAccelX, _lastAccelY) * 180 / pi;
  }

  String _getLightingCondition(double lightLevel) {
    if (lightLevel > 0.8) return 'Bright Sun';
    if (lightLevel > 0.6) return 'Overcast';
    if (lightLevel > 0.4) return 'Golden Hour';
    if (lightLevel > 0.2) return 'Blue Hour';
    return 'Low Light';
  }

  String _getEnvironmentRecommendation(double temperature, double lightLevel) {
    if (temperature < 0) return 'Extremely cold - protect your device';
    if (temperature > 40) return 'Very hot - avoid overheating';
    if (lightLevel < 0.2) return 'Very low light - use tripod';
    if (lightLevel > 0.9) return 'Very bright - consider filters';
    return 'Good conditions for photography';
  }

  double _calculateFocusConfidence(double x, double y) {
    // Simulate focus confidence based on position
    final centerDistance = sqrt((x - 0.5) * (x - 0.5) + (y - 0.5) * (y - 0.5));
    return max(0.0, 1.0 - centerDistance);
  }

  double _calculateSharpness(double x, double y) {
    // Simulate sharpness calculation
    return 0.7 + Random().nextDouble() * 0.3;
  }

  bool _isFocusOptimal(double x, double y) {
    return _calculateFocusConfidence(x, y) > 0.7 && _calculateSharpness(x, y) > 0.8;
  }

  void _disposeCameras() {
    _cameraController?.dispose();
    _cameraController = null;
  }

  void _disposeSensors() {
    _safelyDisposeSensor(_accelerometerSubscription, 'accelerometer');
    _safelyDisposeSensor(_gyroscopeSubscription, 'gyroscope');
  }

  /// Safely dispose sensor subscription with error handling
  void _safelyDisposeSensor(StreamSubscription? subscription, String sensorName) {
    if (subscription == null) return;
    
    try {
      subscription.cancel();
    } catch (e) {
      _logger.w('Error disposing $sensorName subscription: $e');
      // Ignore disposal errors on platforms that don't support sensors
    }
  }

  /// Get available cameras info
  List<CameraDescription> get availableCamerasList => _cameras;

  /// Get current camera info
  String get currentCameraInfo {
    if (_cameraController == null) return 'No camera active';
    
    final camera = _cameraController!.description;
    return '${camera.name} (${camera.lensDirection.name})';
  }

  /// Get device capabilities
  Map<String, dynamic> get deviceCapabilities {
    return {
      'cameras_count': _cameras.length,
      'has_flash': _cameras.any((c) => c.name.contains('flash')),
      'has_front_camera': _cameras.any((c) => c.lensDirection == CameraLensDirection.front),
      'has_back_camera': _cameras.any((c) => c.lensDirection == CameraLensDirection.back),
      'max_resolution': 'High', // Simplified
      'has_stabilization': true,
    };
  }
}