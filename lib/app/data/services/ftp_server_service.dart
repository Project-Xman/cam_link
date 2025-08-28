import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:network_info_plus/network_info_plus.dart';

class FtpServerService extends GetxService {
  static FtpServerService get to => Get.find();
  
  final Logger _logger = Logger();
  
  // Server state
  final RxBool _isServerRunning = false.obs;
  final RxString _serverIp = ''.obs;
  final RxInt _serverPort = 2121.obs;
  final RxString _username = 'camera'.obs;
  final RxString _password = 'upload123'.obs;
  final RxString _ftpDirectory = ''.obs;
  final RxBool _autoProcessPhotos = true.obs;
  final RxBool _autoUploadToGDrive = false.obs;
  
  // Server instance
  HttpServer? _server;
  Timer? _statusTimer;
  
  // Getters
  bool get isServerRunning => _isServerRunning.value;
  String get serverIp => _serverIp.value;
  int get serverPort => _serverPort.value;
  String get username => _username.value;
  String get password => _password.value;
  String get ftpDirectory => _ftpDirectory.value;
  bool get autoProcessPhotos => _autoProcessPhotos.value;
  bool get autoUploadToGDrive => _autoUploadToGDrive.value;
  
  // Reactive getters
  RxBool get isServerRunningRx => _isServerRunning;
  RxString get serverIpRx => _serverIp;
  RxInt get serverPortRx => _serverPort;
  RxString get usernameRx => _username;
  RxString get passwordRx => _password;
  RxString get ftpDirectoryRx => _ftpDirectory;
  RxBool get autoProcessPhotosRx => _autoProcessPhotos;
  RxBool get autoUploadToGDriveRx => _autoUploadToGDrive;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadSettings();
    await _initializeFtpDirectory();
    await _updateNetworkInfo();
    
    // Start periodic network info updates
    _statusTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _updateNetworkInfo(),
    );
  }

  @override
  void onClose() {
    _statusTimer?.cancel();
    stopServer();
    super.onClose();
  }

  /// Load saved FTP settings
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _serverPort.value = prefs.getInt('ftp_port') ?? 2121;
      _username.value = prefs.getString('ftp_username') ?? 'camera';
      _password.value = prefs.getString('ftp_password') ?? 'upload123';
      _autoProcessPhotos.value = prefs.getBool('ftp_auto_process') ?? true;
      _autoUploadToGDrive.value = prefs.getBool('ftp_auto_gdrive') ?? false;
    } catch (e) {
      _logger.e('Error loading FTP settings: $e');
    }
  }

  /// Save FTP settings
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('ftp_port', _serverPort.value);
      await prefs.setString('ftp_username', _username.value);
      await prefs.setString('ftp_password', _password.value);
      await prefs.setBool('ftp_auto_process', _autoProcessPhotos.value);
      await prefs.setBool('ftp_auto_gdrive', _autoUploadToGDrive.value);
    } catch (e) {
      _logger.e('Error saving FTP settings: $e');
    }
  }

  /// Initialize FTP directory
  Future<void> _initializeFtpDirectory() async {
    try {
      final directory = Directory('/storage/emulated/0/PhotoUploader/FTP');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      _ftpDirectory.value = directory.path;
    } catch (e) {
      _logger.e('Error initializing FTP directory: $e');
      // Fallback to app documents directory
      try {
        final directory = Directory('/data/data/com.example.photo_uploader/files/FTP');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        _ftpDirectory.value = directory.path;
      } catch (e2) {
        _logger.e('Error creating fallback FTP directory: $e2');
      }
    }
  }

  /// Update network information
  Future<void> _updateNetworkInfo() async {
    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();
      _serverIp.value = wifiIP ?? 'Unknown';
    } catch (e) {
      _logger.e('Error getting network info: $e');
      _serverIp.value = 'Unknown';
    }
  }

  /// Request storage permissions
  Future<bool> _requestPermissions() async {
    try {
      final permissions = [
        Permission.storage,
        Permission.manageExternalStorage,
      ];

      Map<Permission, PermissionStatus> statuses = await permissions.request();
      
      return statuses.values.any((status) => 
        status == PermissionStatus.granted || 
        status == PermissionStatus.limited
      );
    } catch (e) {
      _logger.e('Error requesting permissions: $e');
      return false;
    }
  }

  /// Start FTP server (simplified HTTP-based file receiver)
  Future<bool> startServer() async {
    if (_isServerRunning.value) return true;

    try {
      // Request permissions
      final hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        Get.snackbar(
          'Permission Required',
          'Please grant storage permissions to use FTP server',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Create HTTP server for file uploads
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _serverPort.value);
      
      _server!.listen((HttpRequest request) async {
        await _handleRequest(request);
      });

      _isServerRunning.value = true;
      await _saveSettings();

      Get.snackbar(
        'FTP Server Started',
        'Server running on ${_serverIp.value}:${_serverPort.value}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
      );

      _logger.i('FTP server started on port ${_serverPort.value}');
      return true;
    } catch (e) {
      _logger.e('Error starting FTP server: $e');
      Get.snackbar(
        'Server Error',
        'Failed to start FTP server: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
      return false;
    }
  }

  /// Stop FTP server
  Future<bool> stopServer() async {
    if (!_isServerRunning.value) return true;

    try {
      await _server?.close();
      _server = null;
      _isServerRunning.value = false;

      Get.snackbar(
        'FTP Server Stopped',
        'Server has been stopped',
        snackPosition: SnackPosition.BOTTOM,
      );

      _logger.i('FTP server stopped');
      return true;
    } catch (e) {
      _logger.e('Error stopping FTP server: $e');
      return false;
    }
  }

  /// Handle HTTP requests (simplified FTP-like functionality)
  Future<void> _handleRequest(HttpRequest request) async {
    try {
      if (request.method == 'POST' && request.uri.path == '/upload') {
        await _handleFileUpload(request);
      } else if (request.method == 'GET' && request.uri.path == '/') {
        await _handleStatusRequest(request);
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('Not Found');
        await request.response.close();
      }
    } catch (e) {
      _logger.e('Error handling request: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Internal Server Error');
      await request.response.close();
    }
  }

  /// Handle file upload
  Future<void> _handleFileUpload(HttpRequest request) async {
    try {
      // Basic authentication check
      final auth = request.headers.value('authorization');
      if (!_isValidAuth(auth)) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.set('WWW-Authenticate', 'Basic realm="FTP Server"');
        request.response.write('Unauthorized');
        await request.response.close();
        return;
      }

      // Get filename from headers or generate one
      final filename = request.headers.value('x-filename') ?? 
                     'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final filePath = path.join(_ftpDirectory.value, filename);
      final file = File(filePath);

      // Write uploaded data to file
      final sink = file.openWrite();
      await sink.addStream(request);
      await sink.close();

      _logger.i('File uploaded: $filename');

      // Process the uploaded photo if auto-processing is enabled
      if (_autoProcessPhotos.value) {
        await _processUploadedPhoto(filePath);
      }

      request.response.statusCode = HttpStatus.ok;
      request.response.write('File uploaded successfully');
      await request.response.close();

      Get.snackbar(
        'File Received',
        'Photo uploaded via FTP: $filename',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
      );
    } catch (e) {
      _logger.e('Error handling file upload: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Upload failed');
      await request.response.close();
    }
  }

  /// Handle status request
  Future<void> _handleStatusRequest(HttpRequest request) async {
    try {
      final status = {
        'server': 'PhotoUploader FTP Server',
        'status': 'running',
        'directory': _ftpDirectory.value,
        'auto_process': _autoProcessPhotos.value,
        'auto_gdrive': _autoUploadToGDrive.value,
      };

      request.response.headers.contentType = ContentType.json;
      request.response.write(status.toString());
      await request.response.close();
    } catch (e) {
      _logger.e('Error handling status request: $e');
    }
  }

  /// Validate basic authentication
  bool _isValidAuth(String? auth) {
    if (auth == null || !auth.startsWith('Basic ')) return false;
    
    try {
      final credentials = String.fromCharCodes(
        base64.decode(auth.substring(6))
      );
      final parts = credentials.split(':');
      return parts.length == 2 && 
             parts[0] == _username.value && 
             parts[1] == _password.value;
    } catch (e) {
      return false;
    }
  }

  /// Process uploaded photo
  Future<void> _processUploadedPhoto(String filePath) async {
    try {
      _logger.i('Processing uploaded photo: $filePath');
      
      // Copy to phone's photo directory
      final phoneDir = Directory('/storage/emulated/0/DCIM/PhotoUploader');
      if (!await phoneDir.exists()) {
        await phoneDir.create(recursive: true);
      }
      
      final fileName = path.basename(filePath);
      final phonePath = path.join(phoneDir.path, fileName);
      await File(filePath).copy(phonePath);
      
      _logger.i('Photo copied to phone: $phonePath');

      // Auto-upload to Google Drive if enabled
      if (_autoUploadToGDrive.value) {
        // This would integrate with your existing Google Drive service
        // For now, just log the intent
        _logger.i('Auto-upload to Google Drive requested for: $fileName');
        
        // You can integrate with your existing GoogleDriveService here
        // GoogleDriveService.to.uploadFile(phonePath);
      }
    } catch (e) {
      _logger.e('Error processing uploaded photo: $e');
    }
  }

  /// Update server configuration
  Future<void> updateConfiguration({
    required int port,
    required String username,
    required String password,
    required bool autoProcess,
    required bool autoGDrive,
  }) async {
    if (username.isEmpty || password.length < 6) {
      Get.snackbar(
        'Invalid Configuration',
        'Username cannot be empty and password must be at least 6 characters',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
      return;
    }

    final wasRunning = _isServerRunning.value;
    
    // Stop server if running
    if (wasRunning) {
      await stopServer();
    }

    // Update settings
    _serverPort.value = port;
    _username.value = username;
    _password.value = password;
    _autoProcessPhotos.value = autoProcess;
    _autoUploadToGDrive.value = autoGDrive;
    
    await _saveSettings();

    // Restart server if it was running
    if (wasRunning) {
      await Future.delayed(const Duration(seconds: 1));
      await startServer();
    }

    Get.snackbar(
      'Configuration Updated',
      'FTP server settings have been saved',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.primaryContainer,
    );
  }

  /// Get server connection details
  String getConnectionDetails() {
    if (!_isServerRunning.value) {
      return 'Server is not running';
    }
    
    return '''
FTP Server Details:
Host: ${_serverIp.value}
Port: ${_serverPort.value}
Username: ${_username.value}
Password: ${_password.value}
Directory: ${_ftpDirectory.value}

Upload URL: http://${_serverIp.value}:${_serverPort.value}/upload
''';
  }

  /// Toggle server state
  Future<void> toggleServer() async {
    if (_isServerRunning.value) {
      await stopServer();
    } else {
      await startServer();
    }
  }

  /// Get uploaded files list
  Future<List<FileSystemEntity>> getUploadedFiles() async {
    try {
      final directory = Directory(_ftpDirectory.value);
      if (await directory.exists()) {
        return directory.listSync()
          .whereType<File>()
          .toList();
      }
      return [];
    } catch (e) {
      _logger.e('Error getting uploaded files: $e');
      return [];
    }
  }
}