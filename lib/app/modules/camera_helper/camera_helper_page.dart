import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../../data/services/camera_analysis_service.dart';
import '../../data/services/sun_weather_service.dart';
import '../../data/services/sensor_availability_service.dart';
import '../../core/values/app_values.dart';

class CameraHelperPage extends StatefulWidget {
  const CameraHelperPage({super.key});

  @override
  State<CameraHelperPage> createState() => _CameraHelperPageState();
}

class _CameraHelperPageState extends State<CameraHelperPage> {
  final CameraAnalysisService _cameraService = CameraAnalysisService.to;
  final SunWeatherService _sunWeatherService = SunWeatherService.to;
  late final SensorAvailabilityService _sensorService;
  bool _showAdvancedSettings = false;
  bool _showEnvironmentData = true;
  bool _showRecommendations = true;
  bool _showSunWeatherData = true;

  @override
  void initState() {
    super.initState();
    try {
      _sensorService = SensorAvailabilityService.to;
    } catch (e) {
      // Sensor service not available, continue without it
    }
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _cameraService.startCamera();
  }

  @override
  void dispose() {
    _cameraService.stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Camera Helper'),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: Obx(() {
        if (!_cameraService.isInitialized) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Initializing Camera...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        }

        if (!_cameraService.isCameraActive || _cameraService.cameraController == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt, size: 64, color: Colors.white54),
                const SizedBox(height: 16),
                const Text(
                  'Camera not available',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initializeCamera,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            // Camera preview
            _buildCameraPreview(),
            
            // Focus point indicator
            _buildFocusIndicator(),
            
            // Top overlay with environment data
            if (_showEnvironmentData) _buildTopOverlay(),
            
            // Sun and weather overlay
            if (_showSunWeatherData) _buildSunWeatherOverlay(),
            
            // Bottom overlay with camera settings
            _buildBottomOverlay(),
            
            // Side overlay with recommendations
            if (_showRecommendations) _buildRecommendationsOverlay(),
            
            // Advanced settings overlay
            if (_showAdvancedSettings) _buildAdvancedSettingsOverlay(),
          ],
        );
      }),
      floatingActionButton: _buildFloatingActions(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCameraPreview() {
    return GestureDetector(
      onTapUp: (details) => _handleTapToFocus(details),
      child: SizedBox.expand(
        child: CameraPreview(_cameraService.cameraController!),
      ),
    );
  }

  Widget _buildFocusIndicator() {
    return Obx(() {
      final focusPoint = _cameraService.focusPoint;
      if (focusPoint == null) return const SizedBox.shrink();

      return Positioned(
        left: focusPoint.x * MediaQuery.of(context).size.width - 25,
        top: focusPoint.y * MediaQuery.of(context).size.height - 25,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(
              color: focusPoint.isOptimal ? Colors.green : Colors.orange,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: focusPoint.isOptimal ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTopOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(AppValues.paddingMedium),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            final environment = _cameraService.environmentData;
            if (environment == null) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildEnvironmentCard(
                      Icons.thermostat,
                      'Temperature',
                      '${_cameraService.estimatedTemperature.toStringAsFixed(1)}°C',
                      _getTemperatureColor(_cameraService.estimatedTemperature),
                    ),
                    const SizedBox(width: 8),
                    _buildEnvironmentCard(
                      Icons.wb_sunny,
                      'Light',
                      environment.lightingCondition,
                      _getLightColor(environment.lightLevel),
                    ),
                    const SizedBox(width: 8),
                    _buildEnvironmentCard(
                      Icons.balance,
                      'Stability',
                      environment.isStable ? 'Stable' : 'Unstable',
                      environment.isStable ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                if (environment.recommendation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info, color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            environment.recommendation,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEnvironmentCard(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(AppValues.paddingMedium),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Photography tip
              Obx(() {
                final tip = _cameraService.photographyTip;
                if (tip.isEmpty) return const SizedBox.shrink();

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              
              // Camera settings
              Obx(() {
                final settings = _cameraService.currentSettings;
                if (settings == null) return const SizedBox.shrink();

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSettingDisplay('ISO', settings.iso.toInt().toString()),
                    _buildSettingDisplay('Shutter', '1/${(1/settings.exposureTime).round()}'),
                    _buildSettingDisplay('f/', settings.aperture.toStringAsFixed(1)),
                    _buildSettingDisplay('WB', '${settings.whiteBalance.toInt()}K'),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingDisplay(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSunWeatherOverlay() {
    return Positioned(
      left: 8,
      top: MediaQuery.of(context).size.height * 0.15,
      child: Obx(() {
        final sunPos = _sunWeatherService.sunPosition;
        final sunTimes = _sunWeatherService.sunTimes;
        final weather = _sunWeatherService.weatherData;
        final location = _sunWeatherService.currentLocation;
        
        if (sunPos == null && weather == null) return const SizedBox.shrink();

        return Container(
          width: 280,
          constraints: const BoxConstraints(maxHeight: 400),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.wb_sunny, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Sun & Weather',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (_sunWeatherService.isUpdating)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.amber,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Location info
                if (location != null) ...[
                  _buildInfoSection('Location', [
                    _buildInfoRow('City', location.city),
                    _buildInfoRow('Coordinates', '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}'),
                    _buildInfoRow('Altitude', '${location.altitude.toStringAsFixed(0)}m'),
                  ]),
                  const SizedBox(height: 8),
                ],
                
                // Sun position
                if (sunPos != null) ...[
                  _buildInfoSection('Sun Position', [
                    _buildInfoRow('Elevation', '${sunPos.elevation.toStringAsFixed(1)}°'),
                    _buildInfoRow('Azimuth', '${sunPos.azimuth.toStringAsFixed(1)}°'),
                    _buildInfoRow('Shadow Length', sunPos.shadowLength.isFinite ? '${sunPos.shadowLength.toStringAsFixed(1)}x' : '∞'),
                    _buildInfoRow('Shadow Direction', '${sunPos.shadowDirection.toStringAsFixed(1)}°'),
                  ]),
                  const SizedBox(height: 8),
                ],
                
                // Sun times
                if (sunTimes != null) ...[
                  _buildInfoSection('Sun Times', [
                    _buildInfoRow('Dawn', _formatTime(sunTimes.dawn)),
                    _buildInfoRow('Sunrise', _formatTime(sunTimes.sunrise)),
                    _buildInfoRow('Solar Noon', _formatTime(sunTimes.solarNoon)),
                    _buildInfoRow('Sunset', _formatTime(sunTimes.sunset)),
                    _buildInfoRow('Dusk', _formatTime(sunTimes.dusk)),
                  ]),
                  const SizedBox(height: 8),
                ],
                
                // Weather data
                if (weather != null) ...[
                  _buildInfoSection('Weather', [
                    _buildInfoRow('Temperature', '${weather.temperature.toStringAsFixed(1)}°C'),
                    _buildInfoRow('Humidity', '${weather.humidity.toStringAsFixed(0)}%'),
                    _buildInfoRow('Pressure', '${weather.pressure.toStringAsFixed(0)} hPa'),
                    _buildInfoRow('Wind Speed', '${weather.windSpeed.toStringAsFixed(1)} m/s'),
                    _buildInfoRow('Wind Direction', '${weather.windDirection.toStringAsFixed(0)}°'),
                    _buildInfoRow('Visibility', '${weather.visibility.toStringAsFixed(1)} km'),
                    _buildInfoRow('UV Index', weather.uvIndex.toStringAsFixed(1)),
                    _buildInfoRow('Cloud Cover', '${weather.cloudCover.toStringAsFixed(0)}%'),
                    _buildInfoRow('Condition', weather.condition),
                  ]),
                  const SizedBox(height: 8),
                ],
                
                // Photography recommendations
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.camera_enhance, color: Colors.blue, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Photography Tips',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ...(_sunWeatherService.getPhotographyRecommendations().take(3).map(
                        (tip) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            '• $tip',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  Widget _buildSensorStatus() {
    try {
      return Obx(() {
        if (!_sensorService.sensorsChecked) {
          return _buildAdvancedSetting('Sensors', 'Checking...');
        }
        
        return Column(
          children: [
            _buildAdvancedSetting('Accelerometer', _sensorService.hasAccelerometer ? 'Available' : 'Fallback Mode'),
            _buildAdvancedSetting('Gyroscope', _sensorService.hasGyroscope ? 'Available' : 'Not Available'),
            if (!_sensorService.hasAccelerometer || !_sensorService.hasGyroscope)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Using simulated sensor data',
                  style: TextStyle(
                    color: Colors.orange.shade300,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        );
      });
    } catch (e) {
      return _buildAdvancedSetting('Sensors', 'Service Unavailable');
    }
  }

  Widget _buildRecommendationsOverlay() {
    return Positioned(
      right: 8,
      top: MediaQuery.of(context).size.height * 0.3,
      child: Obx(() {
        final recommendations = _cameraService.recommendations;
        final sunWeatherRecommendations = _sunWeatherService.getPhotographyRecommendations();
        final allRecommendations = [...recommendations, ...sunWeatherRecommendations];
        
        if (allRecommendations.isEmpty) return const SizedBox.shrink();

        return Container(
          width: 200,
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            child: Column(
              children: allRecommendations.map((rec) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        rec,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAdvancedSettingsOverlay() {
    return Positioned(
      left: 8,
      top: MediaQuery.of(context).size.height * 0.2,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Advanced Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => setState(() => _showAdvancedSettings = false),
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            Obx(() {
              final settings = _cameraService.currentSettings;
              final environment = _cameraService.environmentData;
              
              if (settings == null || environment == null) {
                return const Text('No data available', style: TextStyle(color: Colors.white70));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAdvancedSetting('Exposure Time', '${settings.exposureTime.toStringAsFixed(4)}s'),
                  _buildAdvancedSetting('ISO', settings.iso.toInt().toString()),
                  _buildAdvancedSetting('Aperture', 'f/${settings.aperture}'),
                  _buildAdvancedSetting('Focal Length', '${settings.focalLength}mm'),
                  _buildAdvancedSetting('White Balance', '${settings.whiteBalance.toInt()}K'),
                  _buildAdvancedSetting('Brightness', '${(settings.brightness * 100).toInt()}%'),
                  _buildAdvancedSetting('Contrast', '${(settings.contrast * 100).toInt()}%'),
                  _buildAdvancedSetting('Saturation', '${(settings.saturation * 100).toInt()}%'),
                  const Divider(color: Colors.white24),
                  _buildAdvancedSetting('Device Tilt', '${environment.deviceTilt.toStringAsFixed(1)}°'),
                  _buildAdvancedSetting('Light Level', '${(environment.lightLevel * 100).toInt()}%'),
                  _buildAdvancedSetting('Humidity', '${environment.humidity.toStringAsFixed(1)}%'),
                  const Divider(color: Colors.white24),
                  _buildSensorStatus(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSetting(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton(
          heroTag: 'switch_camera',
          mini: true,
          onPressed: _switchCamera,
          backgroundColor: Colors.black.withValues(alpha: 0.7),
          child: const Icon(Icons.flip_camera_ios, color: Colors.white),
        ),
        FloatingActionButton(
          heroTag: 'capture',
          onPressed: _capturePhoto,
          backgroundColor: Colors.white,
          child: const Icon(Icons.camera_alt, color: Colors.black),
        ),
        FloatingActionButton(
          heroTag: 'advanced',
          mini: true,
          onPressed: () => setState(() => _showAdvancedSettings = !_showAdvancedSettings),
          backgroundColor: Colors.black.withValues(alpha: 0.7),
          child: Icon(
            _showAdvancedSettings ? Icons.visibility_off : Icons.visibility,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void _handleTapToFocus(TapUpDetails details) {
    final size = MediaQuery.of(context).size;
    final x = details.localPosition.dx / size.width;
    final y = details.localPosition.dy / size.height;
    
    _cameraService.setFocusPoint(x, y);
  }

  Future<void> _switchCamera() async {
    await _cameraService.switchCamera();
  }

  Future<void> _capturePhoto() async {
    final image = await _cameraService.capturePhoto();
    if (image != null) {
      Get.snackbar(
        'Photo Captured',
        'Saved to: ${image.path}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to capture photo',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  void _showSettingsDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Display Settings'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Environment Data'),
                  value: _showEnvironmentData,
                  onChanged: (value) {
                    setState(() => _showEnvironmentData = value);
                    this.setState(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text('Recommendations'),
                  value: _showRecommendations,
                  onChanged: (value) {
                    setState(() => _showRecommendations = value);
                    this.setState(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text('Sun & Weather Data'),
                  value: _showSunWeatherData,
                  onChanged: (value) {
                    setState(() => _showSunWeatherData = value);
                    this.setState(() {});
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Camera Helper Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Real-time temperature estimation'),
              const Text('• Lighting condition analysis'),
              const Text('• Device stability monitoring'),
              const Text('• Focus point optimization'),
              const Text('• Camera settings display'),
              const Text('• Photography recommendations'),
              const Text('• Advanced settings overlay'),
              const SizedBox(height: 16),
              const Text(
                'Usage:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Tap anywhere to set focus point'),
              const Text('• Use camera button to capture'),
              const Text('• Switch cameras with flip button'),
              const Text('• Toggle overlays in settings'),
              const SizedBox(height: 16),
              Obx(() {
                final capabilities = _cameraService.deviceCapabilities;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Device Info:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Cameras: ${capabilities['cameras_count']}'),
                    Text('Current: ${_cameraService.currentCameraInfo}'),
                    Text('Flash: ${capabilities['has_flash'] ? 'Yes' : 'No'}'),
                    Text('Stabilization: ${capabilities['has_stabilization'] ? 'Yes' : 'No'}'),
                  ],
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getTemperatureColor(double temp) {
    if (temp < 5) return Colors.blue;
    if (temp < 15) return Colors.lightBlue;
    if (temp < 25) return Colors.green;
    if (temp < 35) return Colors.orange;
    return Colors.red;
  }

  Color _getLightColor(double lightLevel) {
    if (lightLevel < 0.2) return Colors.indigo;
    if (lightLevel < 0.4) return Colors.blue;
    if (lightLevel < 0.6) return Colors.orange;
    if (lightLevel < 0.8) return Colors.amber;
    return Colors.yellow;
  }
}