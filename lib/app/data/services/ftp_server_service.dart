import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';

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
  final RxString _customSaveDirectory = ''.obs;
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
  String get customSaveDirectory => _customSaveDirectory.value;
  bool get autoProcessPhotos => _autoProcessPhotos.value;
  bool get autoUploadToGDrive => _autoUploadToGDrive.value;
  
  // Reactive getters
  RxBool get isServerRunningRx => _isServerRunning;
  RxString get serverIpRx => _serverIp;
  RxInt get serverPortRx => _serverPort;
  RxString get usernameRx => _username;
  RxString get passwordRx => _password;
  RxString get ftpDirectoryRx => _ftpDirectory;
  RxString get customSaveDirectoryRx => _customSaveDirectory;
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
      _customSaveDirectory.value = prefs.getString('ftp_custom_directory') ?? '';
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
      await prefs.setString('ftp_custom_directory', _customSaveDirectory.value);
      await prefs.setBool('ftp_auto_process', _autoProcessPhotos.value);
      await prefs.setBool('ftp_auto_gdrive', _autoUploadToGDrive.value);
    } catch (e) {
      _logger.e('Error saving FTP settings: $e');
    }
  }

  /// Initialize FTP directory with improved configuration support
  Future<void> _initializeFtpDirectory() async {
    try {
      Directory directory;
      
      if (_customSaveDirectory.value.isNotEmpty) {
        // Use custom directory if specified
        directory = Directory(_customSaveDirectory.value);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        
        // Validate write permissions
        if (!await _testDirectoryPermissions(directory.path)) {
          _logger.w('Custom directory lacks write permissions, falling back to default');
          _customSaveDirectory.value = '';
          await _saveSettings();
          return _initializeFtpDirectory(); // Recursive call with cleared custom path
        }
        
        _ftpDirectory.value = directory.path;
        _logger.i('Using custom FTP directory: ${directory.path}');
      } else {
        // Try to use external storage first
        try {
          directory = Directory('/storage/emulated/0/PhotoUploader/FTP');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          
          // Test write permissions
          if (await _testDirectoryPermissions(directory.path)) {
            _ftpDirectory.value = directory.path;
            _logger.i('Using external storage FTP directory: ${directory.path}');
          } else {
            throw Exception('No write permissions to external storage');
          }
        } catch (e) {
          _logger.w('External storage not available, using app directory: $e');
          
          // Fallback to app documents directory
          final appDir = await getApplicationDocumentsDirectory();
          directory = Directory(path.join(appDir.path, 'FTP'));
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          _ftpDirectory.value = directory.path;
          _logger.i('Using app documents FTP directory: ${directory.path}');
        }
      }
      
      // Create subdirectories for organization
      await _createSubDirectories();
      
    } catch (e) {
      _logger.e('Error initializing FTP directory: $e');
      // Final fallback to temp directory
      try {
        final tempDir = await getTemporaryDirectory();
        final directory = Directory(path.join(tempDir.path, 'FTP'));
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        _ftpDirectory.value = directory.path;
        _logger.i('Using temporary FTP directory: ${directory.path}');
      } catch (e2) {
        _logger.e('Error creating temporary FTP directory: $e2');
      }
    }
  }
  
  /// Test directory permissions
  Future<bool> _testDirectoryPermissions(String directoryPath) async {
    try {
      final testFile = File(path.join(directoryPath, '.test_write_${DateTime.now().millisecondsSinceEpoch}'));
      await testFile.writeAsString('test');
      final canRead = await testFile.readAsString() == 'test';
      await testFile.delete();
      return canRead;
    } catch (e) {
      _logger.w('Directory permission test failed for $directoryPath: $e');
      return false;
    }
  }
  
  /// Create organized subdirectories
  Future<void> _createSubDirectories() async {
    try {
      final subdirs = ['incoming', 'processed', 'uploaded'];
      for (final subdir in subdirs) {
        final dir = Directory(path.join(_ftpDirectory.value, subdir));
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      }
    } catch (e) {
      _logger.w('Error creating subdirectories: $e');
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

  /// Start FTP server (improved HTTP-based file receiver)
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

      // Validate directory exists and is writable
      if (_ftpDirectory.value.isEmpty || !await Directory(_ftpDirectory.value).exists()) {
        await _initializeFtpDirectory();
      }
      
      if (!await _testDirectoryPermissions(_ftpDirectory.value)) {
        Get.snackbar(
          'Directory Error',
          'FTP directory is not writable. Please check permissions.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
        );
        return false;
      }

      // Create HTTP server for file uploads with better configuration
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4, 
        _serverPort.value,
        backlog: 10,
      );
      
      // Configure server settings
      _server!.autoCompress = true;
      _server!.defaultResponseHeaders.set('Server', 'PhotoUploader-FTP/1.0');
      _server!.defaultResponseHeaders.set('Access-Control-Allow-Origin', '*');
      _server!.defaultResponseHeaders.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      _server!.defaultResponseHeaders.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Filename');
      
      _server!.listen((HttpRequest request) async {
        await _handleRequest(request);
      }, onError: (error) {
        _logger.e('FTP Server error: $error');
      });

      _isServerRunning.value = true;
      await _saveSettings();

      Get.snackbar(
        'FTP Server Started',
        'Server running on ${_serverIp.value}:${_serverPort.value}\nSave directory: ${_ftpDirectory.value}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
        duration: const Duration(seconds: 5),
      );

      _logger.i('FTP server started on port ${_serverPort.value}, directory: ${_ftpDirectory.value}');
      return true;
    } on SocketException catch (e) {
      _logger.e('Socket error starting FTP server: $e');
      
      String errorMessage = 'Failed to start FTP server';
      if (e.osError?.errorCode == 98 || e.message.contains('Address already in use')) {
        errorMessage = 'Port ${_serverPort.value} is already in use. Please choose a different port.';
      } else if (e.osError?.errorCode == 13) {
        errorMessage = 'Permission denied. Port ${_serverPort.value} may require elevated privileges.';
      }
      
      Get.snackbar(
        'Server Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
      return false;
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

  /// Handle HTTP requests (improved FTP-like functionality)
  Future<void> _handleRequest(HttpRequest request) async {
    try {
      // Handle CORS preflight requests
      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        return;
      }
      
      // Add CORS headers to all responses
      request.response.headers.set('Access-Control-Allow-Origin', '*');
      request.response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      request.response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Filename');
      
      if (request.method == 'POST' && request.uri.path == '/upload') {
        await _handleFileUpload(request);
      } else if (request.method == 'GET' && request.uri.path == '/') {
        await _handleStatusRequest(request);
      } else if (request.method == 'GET' && request.uri.path == '/files') {
        await _handleFileListRequest(request);
      } else if (request.method == 'POST' && request.uri.path == '/config') {
        await _handleConfigUpdate(request);
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.headers.contentType = ContentType.json;
        request.response.write(json.encode({
          'error': 'Not Found',
          'available_endpoints': ['/upload', '/', '/files', '/config']
        }));
        await request.response.close();
      }
    } catch (e) {
      _logger.e('Error handling request: $e');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.headers.contentType = ContentType.json;
        request.response.write(json.encode({
          'error': 'Internal Server Error',
          'message': e.toString()
        }));
        await request.response.close();
      } catch (closeError) {
        _logger.e('Error closing response: $closeError');
      }
    }
  }

  /// Handle file upload with improved validation and processing
  Future<void> _handleFileUpload(HttpRequest request) async {
    try {
      // Basic authentication check
      final auth = request.headers.value('authorization');
      if (!_isValidAuth(auth)) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.set('WWW-Authenticate', 'Basic realm="PhotoUploader FTP Server"');
        request.response.headers.contentType = ContentType.json;
        request.response.write(json.encode({
          'error': 'Unauthorized',
          'message': 'Valid credentials required'
        }));
        await request.response.close();
        return;
      }

      // Get filename from headers or generate one
      String filename = request.headers.value('x-filename') ?? 
                       request.uri.queryParameters['filename'] ??
                       'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Sanitize filename
      filename = _sanitizeFilename(filename);
      
      // Determine save location within FTP directory
      final saveDir = path.join(_ftpDirectory.value, 'incoming');
      final filePath = path.join(saveDir, filename);
      
      // Ensure directory exists
      final directory = Directory(saveDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Check available space (basic check)
      File file = File(filePath);
      if (await file.exists()) {
        // Generate unique filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final ext = path.extension(filename);
        final nameWithoutExt = path.basenameWithoutExtension(filename);
        filename = '${nameWithoutExt}_$timestamp$ext';
        final newFilePath = path.join(saveDir, filename);
        file = File(newFilePath);
      }

      // Write uploaded data to file with progress tracking
      final sink = file.openWrite();
      int bytesReceived = 0;
      final contentLength = request.contentLength;
      
      await for (final chunk in request) {
        sink.add(chunk);
        bytesReceived += chunk.length;
        
        // Log progress for large files
        if (contentLength > 0 && bytesReceived % (1024 * 1024) == 0) {
          final progress = (bytesReceived / contentLength * 100).toStringAsFixed(1);
          _logger.i('Upload progress: $progress% ($bytesReceived/$contentLength bytes)');
        }
      }
      
      await sink.close();
      
      final fileSize = await file.length();
      _logger.i('File uploaded: $filename (${fileSize} bytes)');

      // Process the uploaded photo if auto-processing is enabled
      if (_autoProcessPhotos.value) {
        await _processUploadedPhoto(file.path);
      }

      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(json.encode({
        'success': true,
        'message': 'File uploaded successfully',
        'filename': filename,
        'size': fileSize,
        'path': file.path,
        'auto_processed': _autoProcessPhotos.value
      }));
      await request.response.close();

      Get.snackbar(
        'File Received',
        'Photo uploaded: $filename (${_formatFileSize(fileSize)})',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
      );
    } catch (e) {
      _logger.e('Error handling file upload: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(json.encode({
        'error': 'Upload failed',
        'message': e.toString()
      }));
      await request.response.close();
    }
  }
  
  /// Sanitize filename to prevent directory traversal and invalid characters
  String _sanitizeFilename(String filename) {
    // Remove path separators and invalid characters
    String sanitized = filename.replaceAll(RegExp(r'[<>:"/\|?*]'), '_');
    sanitized = sanitized.replaceAll('..', '_');
    
    // Ensure it's not empty and has reasonable length
    if (sanitized.isEmpty || sanitized == '.') {
      sanitized = 'file_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    if (sanitized.length > 255) {
      final ext = path.extension(sanitized);
      sanitized = sanitized.substring(0, 250 - ext.length) + ext;
    }
    
    return sanitized;
  }
  
  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Handle status request with detailed information
  Future<void> _handleStatusRequest(HttpRequest request) async {
    try {
      final stats = await _getServerStats();
      final status = {
        'server': 'PhotoUploader FTP Server',
        'version': '1.0',
        'status': 'running',
        'uptime': DateTime.now().difference(_server?.address != null ? DateTime.now() : DateTime.now()).inSeconds,
        'directory': _ftpDirectory.value,
        'custom_directory': _customSaveDirectory.value,
        'auto_process': _autoProcessPhotos.value,
        'auto_gdrive': _autoUploadToGDrive.value,
        'server_ip': _serverIp.value,
        'server_port': _serverPort.value,
        'authentication': {
          'username': _username.value,
          'password_set': _password.value.isNotEmpty
        },
        'statistics': stats,
        'endpoints': {
          'upload': 'POST /upload',
          'status': 'GET /',
          'files': 'GET /files',
          'config': 'POST /config'
        }
      };

      request.response.headers.contentType = ContentType.json;
      request.response.write(json.encode(status));
      await request.response.close();
    } catch (e) {
      _logger.e('Error handling status request: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(json.encode({
        'error': 'Status request failed',
        'message': e.toString()
      }));
      await request.response.close();
    }
  }
  
  /// Handle file list request
  Future<void> _handleFileListRequest(HttpRequest request) async {
    try {
      // Basic authentication check
      final auth = request.headers.value('authorization');
      if (!_isValidAuth(auth)) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.set('WWW-Authenticate', 'Basic realm="PhotoUploader FTP Server"');
        request.response.headers.contentType = ContentType.json;
        request.response.write(json.encode({'error': 'Unauthorized'}));
        await request.response.close();
        return;
      }
      
      final files = await _listFiles();
      
      request.response.headers.contentType = ContentType.json;
      request.response.write(json.encode({
        'files': files,
        'directory': _ftpDirectory.value,
        'total_count': files.length
      }));
      await request.response.close();
    } catch (e) {
      _logger.e('Error handling file list request: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(json.encode({
        'error': 'File list failed',
        'message': e.toString()
      }));
      await request.response.close();
    }
  }
  
  /// Handle configuration update request
  Future<void> _handleConfigUpdate(HttpRequest request) async {
    try {
      // Basic authentication check
      final auth = request.headers.value('authorization');
      if (!_isValidAuth(auth)) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.set('WWW-Authenticate', 'Basic realm="PhotoUploader FTP Server"');
        request.response.headers.contentType = ContentType.json;
        request.response.write(json.encode({'error': 'Unauthorized'}));
        await request.response.close();
        return;
      }
      
      // Read request body
      final body = await utf8.decoder.bind(request).join();
      final config = json.decode(body) as Map<String, dynamic>;
      
      // Update configuration
      if (config.containsKey('auto_process')) {
        _autoProcessPhotos.value = config['auto_process'] as bool;
      }
      if (config.containsKey('auto_gdrive')) {
        _autoUploadToGDrive.value = config['auto_gdrive'] as bool;
      }
      if (config.containsKey('custom_directory')) {
        final newDir = config['custom_directory'] as String;
        await setCustomSaveDirectory(newDir);
      }
      
      await _saveSettings();
      
      request.response.headers.contentType = ContentType.json;
      request.response.write(json.encode({
        'success': true,
        'message': 'Configuration updated successfully',
        'config': {
          'auto_process': _autoProcessPhotos.value,
          'auto_gdrive': _autoUploadToGDrive.value,
          'custom_directory': _customSaveDirectory.value,
          'directory': _ftpDirectory.value
        }
      }));
      await request.response.close();
    } catch (e) {
      _logger.e('Error handling config update: $e');
      request.response.statusCode = HttpStatus.badRequest;
      request.response.headers.contentType = ContentType.json;
      request.response.write(json.encode({
        'error': 'Config update failed',
        'message': e.toString()
      }));
      await request.response.close();
    }
  }
  
  /// Get server statistics
  Future<Map<String, dynamic>> _getServerStats() async {
    try {
      final dir = Directory(_ftpDirectory.value);
      int fileCount = 0;
      int totalSize = 0;
      
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            fileCount++;
            try {
              totalSize += await entity.length();
            } catch (e) {
              // Ignore files we can't read
            }
          }
        }
      }
      
      return {
        'total_files': fileCount,
        'total_size': totalSize,
        'total_size_formatted': _formatFileSize(totalSize),
        'directory_exists': await dir.exists(),
        'directory_writable': await _testDirectoryPermissions(_ftpDirectory.value)
      };
    } catch (e) {
      _logger.e('Error getting server stats: $e');
      return {
        'error': e.toString()
      };
    }
  }
  
  /// List files in FTP directory
  Future<List<Map<String, dynamic>>> _listFiles() async {
    final files = <Map<String, dynamic>>[];
    
    try {
      final dir = Directory(_ftpDirectory.value);
      if (!await dir.exists()) {
        return files;
      }
      
      await for (final entity in dir.list(recursive: false)) {
        if (entity is File) {
          final stat = await entity.stat();
          files.add({
            'name': path.basename(entity.path),
            'path': entity.path,
            'size': stat.size,
            'size_formatted': _formatFileSize(stat.size),
            'modified': stat.modified.toIso8601String(),
            'type': path.extension(entity.path).toLowerCase()
          });
        } else if (entity is Directory) {
          files.add({
            'name': path.basename(entity.path),
            'path': entity.path,
            'type': 'directory',
            'size': 0,
            'size_formatted': '-'
          });
        }
      }
      
      // Sort by modification time, newest first
      files.sort((a, b) {
        if (a['type'] == 'directory' && b['type'] != 'directory') return -1;
        if (a['type'] != 'directory' && b['type'] == 'directory') return 1;
        if (a['modified'] != null && b['modified'] != null) {
          return DateTime.parse(b['modified']).compareTo(DateTime.parse(a['modified']));
        }
        return a['name'].compareTo(b['name']);
      });
      
    } catch (e) {
      _logger.e('Error listing files: $e');
    }
    
    return files;
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

  /// Set custom save directory for FTP uploads
  Future<bool> setCustomSaveDirectory(String directoryPath) async {
    try {
      if (directoryPath.isEmpty) {
        _customSaveDirectory.value = '';
        await _saveSettings();
        await _initializeFtpDirectory();
        
        Get.snackbar(
          'Directory Reset',
          'Using default FTP directory',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primaryContainer,
        );
        return true;
      }
      
      // Validate directory
      final dir = Directory(directoryPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // Test write permissions
      final testFile = File(path.join(directoryPath, '.test_write'));
      await testFile.writeAsString('test');
      await testFile.delete();
      
      _customSaveDirectory.value = directoryPath;
      await _saveSettings();
      await _initializeFtpDirectory();
      
      Get.snackbar(
        'Directory Set',
        'Custom FTP directory: $directoryPath',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
      );
      
      return true;
    } catch (e) {
      _logger.e('Error setting custom directory: $e');
      Get.snackbar(
        'Directory Error',
        'Cannot use directory: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
      return false;
    }
  }
  
  /// Get available storage directories
  Future<List<String>> getAvailableDirectories() async {
    final directories = <String>[];
    
    try {
      // External storage directories
      directories.add('/storage/emulated/0/PhotoUploader');
      directories.add('/storage/emulated/0/DCIM/PhotoUploader');
      directories.add('/storage/emulated/0/Pictures/PhotoUploader');
      directories.add('/storage/emulated/0/Download/PhotoUploader');
      
      // App-specific directories
      final appDir = await getApplicationDocumentsDirectory();
      directories.add(path.join(appDir.path, 'FTP'));
      
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        directories.add(path.join(externalDir.path, 'FTP'));
      }
      
    } catch (e) {
      _logger.e('Error getting available directories: $e');
    }
    
    return directories;
  }
}