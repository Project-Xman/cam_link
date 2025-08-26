import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/user_model.dart';
import '../../core/errors/app_exception.dart';
import '../../core/values/app_values.dart';

/// Service for local storage operations using GetStorage
class StorageService extends GetxService {
  static StorageService get to => Get.find();
  
  GetStorage? _box;
  bool _isInitialized = false;
  bool _isInitializing = false;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeStorage();
  }

  /// Initialize storage
  Future<void> _initializeStorage() async {
    // Prevent double initialization
    if (_isInitialized || _isInitializing) {
      return;
    }
    
    _isInitializing = true;
    
    try {
      await GetStorage.init();
      _box ??= GetStorage();
      _isInitialized = true;
    } finally {
      _isInitializing = false;
    }
  }

  /// Ensure storage is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initializeStorage();
    }
    
    if (_box == null) {
      await GetStorage.init();
      _box = GetStorage();
      _isInitialized = true;
    }
  }

  /// Save user data
  Future<void> saveUser(UserModel user) async {
    await _ensureInitialized();
    try {
      await _box!.write(AppValues.userPrefsKey, user.toJson());
    } catch (e) {
      throw FileException.accessDenied('user preferences');
    }
  }

  /// Get saved user data
  UserModel? getUser() {
    if (_box == null) return null;
    try {
      final userData = _box!.read<Map<String, dynamic>>(AppValues.userPrefsKey);
      if (userData != null) {
        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Remove user data
  Future<void> removeUser() async {
    await _ensureInitialized();
    try {
      await _box!.remove(AppValues.userPrefsKey);
    } catch (e) {
      throw FileException.accessDenied('user preferences');
    }
  }

  /// Save theme mode
  Future<void> saveThemeMode(String themeMode) async {
    await _ensureInitialized();
    try {
      await _box!.write(AppValues.themeKey, themeMode);
    } catch (e) {
      throw FileException.accessDenied('theme preferences');
    }
  }

  /// Get saved theme mode
  String? getThemeMode() {
    if (_box == null) return null;
    try {
      return _box!.read<String>(AppValues.themeKey);
    } catch (e) {
      return null;
    }
  }

  /// Save language code
  Future<void> saveLanguageCode(String languageCode) async {
    await _ensureInitialized();
    try {
      await _box!.write(AppValues.languageKey, languageCode);
    } catch (e) {
      throw FileException.accessDenied('language preferences');
    }
  }

  /// Get saved language code
  String? getLanguageCode() {
    if (_box == null) return null;
    try {
      return _box!.read<String>(AppValues.languageKey);
    } catch (e) {
      return null;
    }
  }

  /// Save generic data
  Future<void> saveData<T>(String key, T value) async {
    await _ensureInitialized();
    try {
      await _box!.write(key, value);
    } catch (e) {
      throw FileException.accessDenied(key);
    }
  }

  /// Get generic data
  T? getData<T>(String key) {
    if (_box == null) return null;
    try {
      return _box!.read<T>(key);
    } catch (e) {
      return null;
    }
  }

  /// Remove data by key
  Future<void> removeData(String key) async {
    await _ensureInitialized();
    try {
      await _box!.remove(key);
    } catch (e) {
      throw FileException.accessDenied(key);
    }
  }

  /// Clear all data
  Future<void> clearAll() async {
    await _ensureInitialized();
    try {
      await _box!.erase();
    } catch (e) {
      throw FileException.accessDenied('storage');
    }
  }

  /// Check if key exists
  bool hasData(String key) {
    if (_box == null) return false;
    try {
      return _box!.hasData(key);
    } catch (e) {
      return false;
    }
  }

  /// Get all keys
  Iterable<String> getAllKeys() {
    if (_box == null) return [];
    try {
      return _box!.getKeys().cast<String>();
    } catch (e) {
      return [];
    }
  }

  /// Listen to changes for a specific key
  void listenKey(String key, void Function(dynamic) callback) {
    if (_box != null) {
      _box!.listenKey(key, callback);
    }
  }

  /// Save app settings
  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    await _ensureInitialized();
    try {
      await _box!.write('app_settings', settings);
    } catch (e) {
      throw FileException.accessDenied('app settings');
    }
  }

  /// Get app settings
  Map<String, dynamic> getAppSettings() {
    if (_box == null) return {};
    try {
      return _box!.read<Map<String, dynamic>>('app_settings') ?? {};
    } catch (e) {
      return {};
    }
  }

  /// Save recent folders
  Future<void> saveRecentFolders(List<String> folders) async {
    await _ensureInitialized();
    try {
      await _box!.write('recent_folders', folders);
    } catch (e) {
      throw FileException.accessDenied('recent folders');
    }
  }

  /// Get recent folders
  List<String> getRecentFolders() {
    if (_box == null) return [];
    try {
      final folders = _box!.read<List>('recent_folders');
      return folders?.cast<String>() ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Save processing settings
  Future<void> saveProcessingSettings({
    required int width,
    required int height,
    required bool saveToDevice,
    String? overlayImagePath,
  }) async {
    await _ensureInitialized();
    try {
      final settings = {
        'width': width,
        'height': height,
        'saveToDevice': saveToDevice,
        'overlayImagePath': overlayImagePath,
      };
      await _box!.write('processing_settings', settings);
    } catch (e) {
      throw FileException.accessDenied('processing settings');
    }
  }

  /// Get processing settings
  Map<String, dynamic> getProcessingSettings() {
    if (_box == null) return {
      'width': AppValues.defaultImageWidth,
      'height': AppValues.defaultImageHeight,
      'saveToDevice': false,
      'overlayImagePath': null,
    };
    
    try {
      return _box!.read<Map<String, dynamic>>('processing_settings') ?? {
        'width': AppValues.defaultImageWidth,
        'height': AppValues.defaultImageHeight,
        'saveToDevice': false,
        'overlayImagePath': null,
      };
    } catch (e) {
      return {
        'width': AppValues.defaultImageWidth,
        'height': AppValues.defaultImageHeight,
        'saveToDevice': false,
        'overlayImagePath': null,
      };
    }
  }
}