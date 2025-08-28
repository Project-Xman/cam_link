import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

class SunPosition {
  final double azimuth;
  final double elevation;
  final double shadowLength;
  final double shadowDirection;

  SunPosition({
    required this.azimuth,
    required this.elevation,
    required this.shadowLength,
    required this.shadowDirection,
  });
}

class SunTimes {
  final DateTime dawn;
  final DateTime sunrise;
  final DateTime solarNoon;
  final DateTime sunset;
  final DateTime dusk;

  SunTimes({
    required this.dawn,
    required this.sunrise,
    required this.solarNoon,
    required this.sunset,
    required this.dusk,
  });
}

class WeatherData {
  final double temperature;
  final double humidity;
  final double pressure;
  final double windSpeed;
  final double windDirection;
  final double visibility;
  final double uvIndex;
  final String condition;
  final String description;
  final double cloudCover;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.windDirection,
    required this.visibility,
    required this.uvIndex,
    required this.condition,
    required this.description,
    required this.cloudCover,
  });
}

class LocationData {
  final double latitude;
  final double longitude;
  final double altitude;
  final String address;
  final String city;
  final String country;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.address,
    required this.city,
    required this.country,
  });
}

class SunWeatherService extends GetxService {
  static SunWeatherService get to => Get.find();
  
  final Logger _logger = Logger();
  
  // Reactive variables
  final Rx<LocationData?> _currentLocation = Rx<LocationData?>(null);
  final Rx<SunPosition?> _sunPosition = Rx<SunPosition?>(null);
  final Rx<SunTimes?> _sunTimes = Rx<SunTimes?>(null);
  final Rx<WeatherData?> _weatherData = Rx<WeatherData?>(null);
  final RxBool _isLocationEnabled = false.obs;
  final RxBool _isUpdating = false.obs;
  
  Timer? _updateTimer;
  
  // Getters
  LocationData? get currentLocation => _currentLocation.value;
  SunPosition? get sunPosition => _sunPosition.value;
  SunTimes? get sunTimes => _sunTimes.value;
  WeatherData? get weatherData => _weatherData.value;
  bool get isLocationEnabled => _isLocationEnabled.value;
  bool get isUpdating => _isUpdating.value;
  
  // Reactive getters
  Rx<LocationData?> get currentLocationRx => _currentLocation;
  Rx<SunPosition?> get sunPositionRx => _sunPosition;
  Rx<SunTimes?> get sunTimesRx => _sunTimes;
  Rx<WeatherData?> get weatherDataRx => _weatherData;
  RxBool get isLocationEnabledRx => _isLocationEnabled;
  RxBool get isUpdatingRx => _isUpdating;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeLocationServices();
    _startPeriodicUpdates();
  }

  @override
  void onClose() {
    _updateTimer?.cancel();
    super.onClose();
  }

  /// Initialize location services
  Future<void> _initializeLocationServices() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.w('Location services are disabled - using fallback location');
        _initializeFallbackLocation();
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _logger.w('Location permissions are denied - using fallback location');
          _initializeFallbackLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _logger.w('Location permissions are permanently denied - using fallback location');
        _initializeFallbackLocation();
        return;
      }

      _isLocationEnabled.value = true;
      await updateLocation();
      
      _logger.i('Location services initialized successfully');
    } catch (e) {
      _logger.e('Error initializing location services: $e - using fallback location');
      _initializeFallbackLocation();
    }
  }

  /// Initialize fallback location when GPS is not available
  void _initializeFallbackLocation() {
    // Use a default location (New York City) for demonstration
    _currentLocation.value = LocationData(
      latitude: 40.7128,
      longitude: -74.0060,
      altitude: 10.0,
      address: 'Demo Location, New York',
      city: 'New York',
      country: 'United States',
    );

    _isLocationEnabled.value = true;
    _updateSunData();
    _updateWeatherData();
    
    _logger.i('Fallback location initialized');
  }

  /// Update current location and related data
  Future<void> updateLocation() async {
    if (!_isLocationEnabled.value) return;

    try {
      _isUpdating.value = true;

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      String address = 'Unknown location';
      String city = 'Unknown city';
      String country = 'Unknown country';

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          address = '${placemark.street ?? ''}, ${placemark.locality ?? ''}';
          city = placemark.locality ?? 'Unknown city';
          country = placemark.country ?? 'Unknown country';
        }
      } catch (e) {
        _logger.w('Error getting address from coordinates: $e');
        // Continue with coordinates only
      }

      _currentLocation.value = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        address: address,
        city: city,
        country: country,
      );

      // Update sun and weather data
      await _updateSunData();
      await _updateWeatherData();

      _logger.i('Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      _logger.e('Error updating location: $e');
      // If location update fails, ensure we still have fallback data
      if (_currentLocation.value == null) {
        _initializeFallbackLocation();
      }
    } finally {
      _isUpdating.value = false;
    }
  }

  /// Update sun position and times
  Future<void> _updateSunData() async {
    final location = _currentLocation.value;
    if (location == null) return;

    try {
      final now = DateTime.now();
      
      // Calculate sun position
      final sunPos = _calculateSunPosition(
        location.latitude,
        location.longitude,
        now,
      );
      _sunPosition.value = sunPos;

      // Calculate sun times
      final sunTimesData = _calculateSunTimes(
        location.latitude,
        location.longitude,
        now,
      );
      _sunTimes.value = sunTimesData;

      _logger.i('Sun data updated');
    } catch (e) {
      _logger.e('Error updating sun data: $e');
    }
  }

  /// Update weather data (simulated - in real app, use weather API)
  Future<void> _updateWeatherData() async {
    final location = _currentLocation.value;
    if (location == null) return;

    try {
      // Simulate weather data (replace with actual weather API call)
      _weatherData.value = WeatherData(
        temperature: 20 + Random().nextDouble() * 15,
        humidity: 40 + Random().nextDouble() * 40,
        pressure: 1013 + Random().nextDouble() * 20 - 10,
        windSpeed: Random().nextDouble() * 20,
        windDirection: Random().nextDouble() * 360,
        visibility: 10 + Random().nextDouble() * 15,
        uvIndex: Random().nextDouble() * 11,
        condition: _getRandomWeatherCondition(),
        description: 'Partly cloudy with light winds',
        cloudCover: Random().nextDouble() * 100,
      );

      _logger.i('Weather data updated');
    } catch (e) {
      _logger.e('Error updating weather data: $e');
    }
  }

  /// Calculate sun position using astronomical formulas
  SunPosition _calculateSunPosition(double lat, double lon, DateTime dateTime) {
    // Convert to radians
    final latRad = lat * pi / 180;
    
    // Calculate Julian day
    final julianDay = _calculateJulianDay(dateTime);
    
    // Calculate sun's position
    final n = julianDay - 2451545.0;
    final L = (280.460 + 0.9856474 * n) % 360;
    final g = ((357.528 + 0.9856003 * n) % 360) * pi / 180;
    final lambda = (L + 1.915 * sin(g) + 0.020 * sin(2 * g)) * pi / 180;
    
    // Calculate sun's declination
    final declination = asin(sin(23.439 * pi / 180) * sin(lambda));
    
    // Calculate hour angle (accounting for longitude and time)
    final solarTime = dateTime.hour + dateTime.minute / 60.0 + dateTime.second / 3600.0;
    final hourAngle = ((solarTime - 12) * 15 + lon) * pi / 180;
    
    // Calculate elevation and azimuth
    final elevation = asin(
      sin(latRad) * sin(declination) + 
      cos(latRad) * cos(declination) * cos(hourAngle)
    );
    
    final azimuth = atan2(
      sin(hourAngle),
      cos(hourAngle) * sin(latRad) - tan(declination) * cos(latRad)
    );
    
    // Calculate shadow properties
    final shadowLength = _calculateShadowLength(elevation);
    final shadowDirection = (azimuth + pi) % (2 * pi);
    
    return SunPosition(
      azimuth: azimuth * 180 / pi,
      elevation: elevation * 180 / pi,
      shadowLength: shadowLength,
      shadowDirection: shadowDirection * 180 / pi,
    );
  }

  /// Calculate sun times for the day
  SunTimes _calculateSunTimes(double lat, double lon, DateTime date) {
    // Simplified sun times calculation based on latitude and longitude
    
    // Calculate approximate times (in hours from midnight)
    final solarNoonHour = 12 - lon / 15;
    
    // Calculate sunrise/sunset hour angle
    final latRad = lat * pi / 180;
    final declination = 23.45 * sin((360 * (284 + date.dayOfYear) / 365) * pi / 180) * pi / 180;
    final hourAngle = acos(-tan(latRad) * tan(declination));
    final hourAngleDeg = hourAngle * 180 / pi / 15;
    
    final sunriseHour = solarNoonHour - hourAngleDeg;
    final sunsetHour = solarNoonHour + hourAngleDeg;
    
    // Civil twilight (6 degrees below horizon)
    final civilTwilightAngle = acos(-tan(latRad) * tan(declination + 6 * pi / 180));
    final civilTwilightHours = civilTwilightAngle * 180 / pi / 15;
    
    final dawnHour = solarNoonHour - civilTwilightHours;
    final duskHour = solarNoonHour + civilTwilightHours;
    
    return SunTimes(
      dawn: _hourToDateTime(date, dawnHour),
      sunrise: _hourToDateTime(date, sunriseHour),
      solarNoon: _hourToDateTime(date, solarNoonHour),
      sunset: _hourToDateTime(date, sunsetHour),
      dusk: _hourToDateTime(date, duskHour),
    );
  }

  /// Calculate Julian day number
  double _calculateJulianDay(DateTime dateTime) {
    final a = (14 - dateTime.month) ~/ 12;
    final y = dateTime.year + 4800 - a;
    final m = dateTime.month + 12 * a - 3;
    
    return dateTime.day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
  }

  /// Calculate shadow length based on sun elevation
  double _calculateShadowLength(double elevationRad) {
    if (elevationRad <= 0) return double.infinity;
    return 1.0 / tan(elevationRad); // Assuming object height of 1 unit
  }

  /// Convert hour to DateTime
  DateTime _hourToDateTime(DateTime date, double hour) {
    final hours = hour.floor();
    final minutes = ((hour - hours) * 60).floor();
    final seconds = (((hour - hours) * 60 - minutes) * 60).floor();
    
    return DateTime(date.year, date.month, date.day, hours, minutes, seconds);
  }

  /// Get random weather condition for simulation
  String _getRandomWeatherCondition() {
    final conditions = [
      'Clear',
      'Partly Cloudy',
      'Cloudy',
      'Overcast',
      'Light Rain',
      'Rain',
      'Thunderstorm',
      'Snow',
      'Fog',
      'Mist',
    ];
    return conditions[Random().nextInt(conditions.length)];
  }

  /// Start periodic updates
  void _startPeriodicUpdates() {
    _updateTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isLocationEnabled.value) {
        _updateSunData();
        _updateWeatherData();
      }
    });
  }

  /// Get formatted sun times
  Map<String, String> getFormattedSunTimes() {
    final times = _sunTimes.value;
    if (times == null) return {};

    final formatter = DateFormat('HH:mm:ss');
    
    return {
      'dawn': formatter.format(times.dawn),
      'sunrise': formatter.format(times.sunrise),
      'culmination': formatter.format(times.solarNoon),
      'sunset': formatter.format(times.sunset),
      'dusk': formatter.format(times.dusk),
    };
  }

  /// Get photography recommendations based on sun position and weather
  List<String> getPhotographyRecommendations() {
    final recommendations = <String>[];
    final sunPos = _sunPosition.value;
    final weather = _weatherData.value;
    final times = _sunTimes.value;
    
    if (sunPos == null || weather == null || times == null) return recommendations;

    final now = DateTime.now();
    
    // Sun position recommendations
    if (sunPos.elevation < 10) {
      recommendations.add('Low sun angle - perfect for dramatic shadows and golden hour photography');
    } else if (sunPos.elevation > 60) {
      recommendations.add('High sun - use fill flash or reflectors to avoid harsh shadows');
    }

    // Time-based recommendations
    final minutesToSunrise = times.sunrise.difference(now).inMinutes;
    final minutesToSunset = times.sunset.difference(now).inMinutes;
    
    if (minutesToSunrise > 0 && minutesToSunrise < 30) {
      recommendations.add('Sunrise approaching in ${minutesToSunrise}min - prepare for golden hour');
    } else if (minutesToSunset > 0 && minutesToSunset < 60) {
      recommendations.add('Golden hour starting soon - ${minutesToSunset}min until sunset');
    }

    // Weather recommendations
    if (weather.cloudCover > 80) {
      recommendations.add('Heavy cloud cover - great for soft, even lighting');
    } else if (weather.cloudCover < 20) {
      recommendations.add('Clear skies - watch for harsh shadows, consider using diffusers');
    }

    if (weather.windSpeed > 15) {
      recommendations.add('Windy conditions - use faster shutter speeds for sharp images');
    }

    if (weather.uvIndex > 8) {
      recommendations.add('High UV index - protect your equipment and consider UV filters');
    }

    return recommendations;
  }

  /// Get current lighting condition based on sun position and weather
  String getCurrentLightingCondition() {
    final sunPos = _sunPosition.value;
    final weather = _weatherData.value;
    
    if (sunPos == null || weather == null) return 'Unknown';

    if (sunPos.elevation < -6) return 'Night';
    if (sunPos.elevation < 0) return 'Civil Twilight';
    if (sunPos.elevation < 6) return 'Golden Hour';
    if (sunPos.elevation < 12) return 'Blue Hour';
    
    if (weather.cloudCover > 80) return 'Overcast';
    if (weather.cloudCover > 50) return 'Partly Cloudy';
    
    return 'Bright Sun';
  }
}

extension on DateTime {
  int get dayOfYear {
    return difference(DateTime(year, 1, 1)).inDays + 1;
  }
}