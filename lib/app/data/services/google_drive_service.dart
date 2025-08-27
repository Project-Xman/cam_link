import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../../core/errors/app_exception.dart';
import '../models/enums.dart';

/// Google Drive integration service
class GoogleDriveService extends GetxService {
  static GoogleDriveService get to => Get.find();

  GoogleSignIn? _googleSignIn;
  drive.DriveApi? _driveApi;
  GoogleSignInAccount? _currentUser;
  
  // Platform support check
  final bool _isPlatformSupported = _checkPlatformSupport();
  
  // Reactive variables
  final isConnected = false.obs;
  final isLoading = false.obs;
  final availableDrives = <drive.Drive>[].obs;
  final currentDrive = Rxn<drive.Drive>();
  final platformSupported = true.obs;

  /// Check if current platform supports Google Sign-In
  static bool _checkPlatformSupport() {
    if (kIsWeb) return true;
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) return true;
    return false; // Windows and Linux are not fully supported
  }

  @override
  void onInit() {
    super.onInit();
    platformSupported.value = _isPlatformSupported;
    
    if (_isPlatformSupported) {
      _initializeGoogleSignIn();
    } else {
      _showPlatformNotSupportedMessage();
    }
  }

  /// Show platform not supported message
  void _showPlatformNotSupportedMessage() {
    Get.snackbar(
      'Platform Not Supported',
      'Google Drive integration is not available on this platform. Please use a supported device (Android, iOS, macOS, or Web).',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.errorContainer,
      duration: const Duration(seconds: 5),
    );
  }

  /// Initialize Google Sign In
  void _initializeGoogleSignIn() {
    try {
      _googleSignIn = GoogleSignIn(
        scopes: [
          'https://www.googleapis.com/auth/drive',
          'https://www.googleapis.com/auth/drive.file',
          'https://www.googleapis.com/auth/drive.readonly',
        ],
      );

      // Listen to sign in state changes
      _googleSignIn!.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
        _currentUser = account;
        isConnected.value = account != null;
        
        if (account != null) {
          _initializeDriveApi();
          loadAvailableDrives();
        } else {
          _driveApi = null;
          availableDrives.clear();
          currentDrive.value = null;
        }
      });

      // Check if user is already signed in
      _googleSignIn!.signInSilently().catchError((error) {
        debugPrint('Silent sign-in failed: $error');
        // Ignore silent sign-in errors
      });
    } catch (e) {
      debugPrint('Failed to initialize Google Sign-In: $e');
      platformSupported.value = false;
      _showPlatformNotSupportedMessage();
    }
  }

  /// Initialize Drive API
  Future<void> _initializeDriveApi() async {
    if (_currentUser == null) return;

    try {
      final authHeaders = await _currentUser!.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      _driveApi = drive.DriveApi(authenticateClient);
    } catch (e) {
      debugPrint('Error initializing Drive API: $e');
    }
  }

  /// Sign in to Google Drive
  Future<void> signInToGoogleDrive() async {
    if (!_isPlatformSupported || _googleSignIn == null) {
      _showPlatformNotSupportedMessage();
      return;
    }

    try {
      isLoading.value = true;
      
      final account = await _googleSignIn!.signIn();
      if (account == null) {
        throw AppExceptionImpl(
          message: 'Google Sign In was cancelled',
        );
      }

      Get.snackbar(
        'Success',
        'Connected to Google Drive successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppExceptionImpl(
        message: 'Failed to connect to Google Drive: $e',
        originalException: e,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Sign out from Google Drive
  Future<void> signOutFromGoogleDrive() async {
    if (!_isPlatformSupported || _googleSignIn == null) {
      return;
    }

    try {
      await _googleSignIn!.signOut();
      
      Get.snackbar(
        'Disconnected',
        'Disconnected from Google Drive',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      throw AppExceptionImpl(
        message: 'Failed to disconnect from Google Drive: $e',
        originalException: e,
      );
    }
  }

  /// Load available drives (My Drive + Shared Drives)
  Future<void> loadAvailableDrives() async {
    if (_driveApi == null) return;

    try {
      isLoading.value = true;
      availableDrives.clear();

      // Get My Drive (always available)
      final myDrive = drive.Drive()
        ..id = 'my-drive'
        ..name = 'My Drive'
        ..kind = 'drive#drive';
      
      availableDrives.add(myDrive);

      // Get Shared Drives
      try {
        final sharedDrives = await _driveApi!.drives.list();
        if (sharedDrives.drives != null) {
          availableDrives.addAll(sharedDrives.drives!);
        }
      } catch (e) {
        debugPrint('Error loading shared drives: $e');
        // Continue with just My Drive
      }

      // Set default drive to My Drive
      if (currentDrive.value == null && availableDrives.isNotEmpty) {
        currentDrive.value = availableDrives.first;
      }

    } catch (e) {
      throw AppExceptionImpl(
        message: 'Failed to load available drives: $e',
        originalException: e,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Select a drive
  void selectDrive(drive.Drive selectedDrive) {
    currentDrive.value = selectedDrive;
    
    Get.snackbar(
      'Drive Selected',
      'Selected: ${selectedDrive.name}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Upload file to selected drive
  Future<drive.File?> uploadFile({
    required String fileName,
    required List<int> fileBytes,
    required String mimeType,
    String? folderId,
  }) async {
    if (_driveApi == null) {
      throw AppExceptionImpl(message: 'Google Drive not connected');
    }

    try {
      isLoading.value = true;

      final driveFile = drive.File()
        ..name = fileName
        ..parents = folderId != null ? [folderId] : null;

      final media = drive.Media(
        Stream.fromIterable([fileBytes]),
        fileBytes.length,
        contentType: mimeType,
      );

      final uploadedFile = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      Get.snackbar(
        'Upload Success',
        'File uploaded: $fileName',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
      );

      return uploadedFile;
    } catch (e) {
      throw AppExceptionImpl(
        message: 'Failed to upload file: $e',
        originalException: e,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// List files in current drive
  Future<List<drive.File>> listFiles({
    String? folderId,
    int maxResults = 100,
  }) async {
    if (_driveApi == null) {
      throw AppExceptionImpl(message: 'Google Drive not connected');
    }

    try {
      String query = "trashed=false";
      if (folderId != null) {
        query += " and '$folderId' in parents";
      }

      final fileList = await _driveApi!.files.list(
        q: query,
        pageSize: maxResults,
        spaces: currentDrive.value?.id == 'my-drive' ? 'drive' : null,
        driveId: currentDrive.value?.id != 'my-drive' ? currentDrive.value?.id : null,
        includeItemsFromAllDrives: true,
        supportsAllDrives: true,
      );

      return fileList.files ?? [];
    } catch (e) {
      throw AppExceptionImpl(
        message: 'Failed to list files: $e',
        originalException: e,
      );
    }
  }

  /// Get current user info
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Get current drive name
  String get currentDriveName => currentDrive.value?.name ?? 'No drive selected';

  /// Create folder in current drive
  Future<bool> createFolder(String folderName) async {
    if (_driveApi == null) {
      throw AppExceptionImpl(message: 'Google Drive not connected');
    }

    try {
      isLoading.value = true;

      final folder = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await _driveApi!.files.create(folder);
      
      Get.snackbar(
        'Folder Created',
        'Folder "$folderName" created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
      );

      return createdFolder.id != null;
    } catch (e) {
      throw AppExceptionImpl(
        message: 'Failed to create folder: $e',
        originalException: e,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Upload bytes to Google Drive with progress callback
  Future<UploadStatus> uploadBytesToGoogleDrive(
    String folderName,
    List<int> fileBytes,
    String fileName,
    Function(double)? onProgress,
  ) async {
    if (_driveApi == null) {
      return UploadStatus.uploadFailed;
    }

    try {
      // Find or create folder
      String? folderId;
      final files = await listFiles();
      final existingFolder = files.firstWhereOrNull(
        (file) => file.name == folderName && file.mimeType == 'application/vnd.google-apps.folder',
      );

      if (existingFolder != null) {
        folderId = existingFolder.id;
      } else {
        // Create folder
        final folder = drive.File()
          ..name = folderName
          ..mimeType = 'application/vnd.google-apps.folder';
        final createdFolder = await _driveApi!.files.create(folder);
        folderId = createdFolder.id;
      }

      // Upload file
      final uploadedFile = await uploadFile(
        fileName: fileName,
        fileBytes: fileBytes,
        mimeType: 'image/jpeg', // Assuming processed images are JPEG
        folderId: folderId,
      );

      return uploadedFile != null ? UploadStatus.uploadSuccess : UploadStatus.uploadFailed;
    } catch (e) {
      debugPrint('Upload error: $e');
      return UploadStatus.uploadFailed;
    }
  }
}

/// Custom HTTP client for Google APIs authentication
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}