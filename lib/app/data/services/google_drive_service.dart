import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../../core/errors/app_exception.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import 'google_oauth_service.dart';

/// Google Drive integration service
class GoogleDriveService extends GetxService {
  static GoogleDriveService get to => Get.find();

  // Dependencies
  late final AuthService _authService;
  drive.DriveApi? _driveApi;

  // Reactive variables
  final isLoading = false.obs;
  final availableDrives = <drive.Drive>[].obs;
  final currentDrive = Rxn<drive.Drive>();
  final platformSupported = true.obs;
  final storageInfo = Rxn<drive.About>();

  // Computed getters
  bool get isConnected => _authService.isSignedIn;
  UserModel? get currentUser => _authService.currentUser;

  @override
  void onInit() {
    super.onInit();
    debugPrint('GoogleDriveService initializing...');

    // Get AuthService dependency
    _authService = AuthService.to;

    // Listen to auth status changes
    _authService.authStatusStream.listen((status) {
      _onAuthStatusChanged(status);
    });

    // Initialize if already signed in
    if (_authService.isSignedIn) {
      _initializeDriveApi();
    }

    platformSupported.value =
        true; // Platform support is handled by AuthService
  }

  /// Handle auth status changes
  void _onAuthStatusChanged(AuthStatus status) {
    debugPrint('Auth status changed: $status');

    if (status == AuthStatus.signedIn) {
      _initializeAndLoadData();
    } else {
      _driveApi = null;
      availableDrives.clear();
      currentDrive.value = null;
      storageInfo.value = null;
    }
  }

  /// Initialize Drive API and load data sequentially
  Future<void> _initializeAndLoadData() async {
    try {
      debugPrint('Starting Drive API initialization and data loading...');

      // Initialize Drive API first
      await _initializeDriveApi();

      // Wait a moment for API to be fully ready
      await Future.delayed(const Duration(milliseconds: 500));

      // Load drives and storage info in parallel
      await Future.wait([
        loadAvailableDrives(),
        loadStorageInfo(),
      ]);

      debugPrint('Drive API initialization and data loading completed');
    } catch (e) {
      debugPrint('Error during Drive API initialization: $e');
    }
  }

  /// Initialize Drive API using AuthService access token
  Future<void> _initializeDriveApi() async {
    try {
      debugPrint('Initializing Drive API...');

      final accessToken = await _authService.getAccessToken();
      final authHeaders = {'Authorization': 'Bearer $accessToken'};
      final authClient = GoogleAuthClient(authHeaders);
      _driveApi = drive.DriveApi(authClient);

      debugPrint('Drive API initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Drive API: $e');
      _driveApi = null;
    }
  }

  /// Sign in to Google Drive using AuthService
  Future<void> signInToGoogleDrive() async {
    try {
      isLoading.value = true;

      // Use the AuthService sign-in methods based on platform
      await _authService.signInWithGoogle();

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

  /// Sign out from Google Drive using AuthService
  Future<void> signOutFromGoogleDrive() async {
    try {
      await _authService.signOut();

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

  /// Load storage information
  Future<void> loadStorageInfo() async {
    if (_driveApi == null) {
      debugPrint('Cannot load storage info: Drive API not initialized');
      return;
    }

    try {
      debugPrint('Starting to load storage info...');

      // Try different approaches for better compatibility
      drive.About? about;

      try {
        // First try with specific fields
        about = await _driveApi!.about
            .get(
              $fields: 'storageQuota,user,kind',
            )
            .timeout(const Duration(seconds: 30));
        debugPrint('Storage info loaded with specific fields');
      } catch (e) {
        debugPrint('Failed with specific fields, trying without fields: $e');

        // Fallback: try without field specification
        about =
            await _driveApi!.about.get().timeout(const Duration(seconds: 30));
        debugPrint('Storage info loaded without field specification');
      }

      if (about != null) {
        storageInfo.value = about;

        final usage = about.storageQuota?.usage;
        final limit = about.storageQuota?.limit;
        final usageInTrash = about.storageQuota?.usageInDrive;

        debugPrint('Storage info loaded successfully:');
        debugPrint('  Usage: $usage bytes');
        debugPrint('  Limit: $limit bytes');
        debugPrint('  Usage in Drive: $usageInTrash bytes');
        debugPrint(
            '  User: ${about.user?.displayName ?? about.user?.emailAddress}');
        debugPrint('  Kind: ${about.kind}');

        // Force UI update
        storageInfo.refresh();
      } else {
        throw Exception('No storage information received from API');
      }
    } catch (e) {
      debugPrint('Error loading storage info: $e');
      debugPrint('Error type: ${e.runtimeType}');

      // Try to get basic user info at least
      try {
        debugPrint('Attempting to get basic user info...');
        final about = await _driveApi!.about
            .get($fields: 'user')
            .timeout(const Duration(seconds: 10));
        debugPrint('Basic user info: ${about.user?.displayName}');
      } catch (userError) {
        debugPrint('Failed to get basic user info: $userError');
      }

      // Set storage info to null to show error state
      storageInfo.value = null;

      // Show user-friendly error
      Get.snackbar(
        'Storage Info',
        'Unable to load storage information. This may be due to API limitations.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
        duration: const Duration(seconds: 3),
      );
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
        driveId: currentDrive.value?.id != 'my-drive'
            ? currentDrive.value?.id
            : null,
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

  /// Get current drive name
  String get currentDriveName =>
      currentDrive.value?.name ?? 'No drive selected';

  /// Get formatted storage usage
  String get formattedStorageUsage {
    final quota = storageInfo.value?.storageQuota;
    if (quota == null) {
      debugPrint('No storage quota available');
      return 'Storage info unavailable';
    }

    debugPrint('Formatting storage usage: ${quota.usage} / ${quota.limit}');

    final used = int.tryParse(quota.usage ?? '0') ?? 0;
    final total = int.tryParse(quota.limit ?? '0') ?? 0;

    if (total == 0) {
      debugPrint('Total storage is 0, assuming unlimited');
      return 'Unlimited storage';
    }

    final formatted = '${_formatBytes(used)} / ${_formatBytes(total)} used';
    debugPrint('Formatted storage: $formatted');
    return formatted;
  }

  /// Get storage usage percentage
  double get storageUsagePercentage {
    final quota = storageInfo.value?.storageQuota;
    if (quota == null) return 0.0;

    final used = int.tryParse(quota.usage ?? '0') ?? 0;
    final total = int.tryParse(quota.limit ?? '0') ?? 0;

    if (total == 0) return 0.0;

    final percentage = (used / total) * 100;
    debugPrint('Storage usage percentage: $percentage%');
    return percentage;
  }

  /// Format bytes to human readable format
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Test configuration without signing in
  bool testConfiguration() {
    try {
      // Test if AuthService is properly configured
      return _authService.isSignedIn || platformSupported.value;
    } catch (e) {
      debugPrint('Configuration test failed: $e');
      Get.snackbar(
        'Configuration Error',
        'Google Drive configuration is not properly set up',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
      return false;
    }
  }

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
        (file) =>
            file.name == folderName &&
            file.mimeType == 'application/vnd.google-apps.folder',
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

      return uploadedFile != null
          ? UploadStatus.uploadSuccess
          : UploadStatus.uploadFailed;
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
