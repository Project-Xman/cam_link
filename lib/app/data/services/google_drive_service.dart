import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:path/path.dart' as path;
import '../models/enums.dart';
import '../models/drive_storage_model.dart';
import 'auth_service.dart';
import '../../core/errors/app_exception.dart';
import '../../core/values/app_values.dart';

/// Google Drive service using GetX patterns
class GoogleDriveService extends GetxService {
  static GoogleDriveService get to => Get.find();

  // Fixed parent folder ID - you may want to make this configurable
  static const String _parentFolderId = '1tlOsLjC-zr7i4JOXgUUzhEEUa4Pn9lQj';

  late final AuthService _authService;

  @override
  void onInit() {
    super.onInit();
    _authService = AuthService.to;
  }

  /// Get Google Drive storage information
  Future<DriveStorageModel> getDriveStorageInfo() async {
    try {
      final accessToken = await _authService.getAccessToken();
      final client = GoogleHttpClient({'Authorization': 'Bearer $accessToken'});
      final drive = ga.DriveApi(client);

      final about = await drive.about.get($fields: 'storageQuota');
      final quota = about.storageQuota!;
      
      final totalStorage = double.parse(quota.limit ?? '0');
      final usedStorage = double.parse(quota.usageInDrive ?? '0');
      final availableStorage = totalStorage - usedStorage;

      return DriveStorageModel(
        totalStorage: totalStorage,
        usedStorage: usedStorage,
        availableStorage: availableStorage,
        formattedTotal: _formatBytes(totalStorage),
        formattedUsed: _formatBytes(usedStorage),
        formattedAvailable: _formatBytes(availableStorage),
      );
    } catch (e) {
      ErrorHandler.handleError(e, context: 'GoogleDriveService.getDriveStorageInfo');
      if (e is AuthException) rethrow;
      throw NetworkException.serverError('Failed to get drive storage info');
    }
  }

  /// Get drive size in GB (backward compatibility)
  Future<double> getDriveSize() async {
    try {
      final storageInfo = await getDriveStorageInfo();
      return storageInfo.usedStorage / 1e9; // Convert to GB
    } catch (e) {
      ErrorHandler.handleError(e, context: 'GoogleDriveService.getDriveSize');
      return 0.0;
    }
  }

  /// Create a folder in Google Drive
  Future<bool> createFolder(String folderName) async {
    try {
      final accessToken = await _authService.getAccessToken();
      final client = GoogleHttpClient({'Authorization': 'Bearer $accessToken'});
      final drive = ga.DriveApi(client);

      final folderId = await _getOrCreateFolderId(drive, folderName, _parentFolderId);
      return folderId != null;
    } catch (e) {
      ErrorHandler.handleError(e, context: 'GoogleDriveService.createFolder');
      return false;
    }
  }

  /// Upload file to Google Drive
  Future<UploadStatus> uploadFileToGoogleDrive(
    String folderName,
    File file,
    Function(double) onUploadProgress,
  ) async {
    try {
      // Validate file
      if (!await file.exists()) {
        throw FileException.notFound(file.path);
      }

      final fileSizeInMB = await file.length() / (1024 * 1024);
      if (fileSizeInMB > AppValues.maxFileSizeInMB) {
        throw FileException.sizeTooLarge(AppValues.maxFileSizeInMB);
      }

      final accessToken = await _authService.getAccessToken();
      final client = GoogleHttpClient({'Authorization': 'Bearer $accessToken'});
      final drive = ga.DriveApi(client);

      final folderId = await _getOrCreateFolderId(drive, folderName, _parentFolderId);
      if (folderId == null) {
        throw UploadException.failed('Failed to create or find folder');
      }

      final fileToUpload = ga.File()
        ..parents = [folderId]
        ..name = path.basename(file.path);

      // Start upload with progress tracking
      final receivePort = ReceivePort();
      await Isolate.spawn(_uploadFileWithProgress, {
        'sendPort': receivePort.sendPort,
        'filePath': file.path,
        'fileMetadata': fileToUpload.toJson(),
        'accessToken': accessToken,
        'folderId': folderId,
      });

      // Listen for progress updates
      await for (final message in receivePort) {
        if (message is double) {
          onUploadProgress(message);
        } else if (message == 'success') {
          receivePort.close();
          ErrorHandler.logInfo('File uploaded successfully: ${file.path}');
          return UploadStatus.uploadSuccess;
        } else if (message is String && message.startsWith('error:')) {
          receivePort.close();
          throw UploadException.failed(message.substring(6));
        }
      }

      return UploadStatus.uploadSuccess;
    } catch (e) {
      ErrorHandler.handleError(e, context: 'GoogleDriveService.uploadFileToGoogleDrive');
      if (e is AppException) rethrow;
      return UploadStatus.uploadFailed;
    }
  }

  /// Upload bytes to Google Drive
  Future<UploadStatus> uploadBytesToGoogleDrive(
    String folderName,
    Uint8List bytes,
    String fileName,
    Function(double) onUploadProgress,
  ) async {
    try {
      // Validate file size
      final fileSizeInMB = bytes.length / (1024 * 1024);
      if (fileSizeInMB > AppValues.maxFileSizeInMB) {
        throw FileException.sizeTooLarge(AppValues.maxFileSizeInMB);
      }

      final accessToken = await _authService.getAccessToken();
      final client = GoogleHttpClient({'Authorization': 'Bearer $accessToken'});
      final drive = ga.DriveApi(client);

      final folderId = await _getOrCreateFolderId(drive, folderName, _parentFolderId);
      if (folderId == null) {
        throw UploadException.failed('Failed to create or find folder');
      }

      final fileToUpload = ga.File()
        ..parents = [folderId]
        ..name = fileName;

      // Start upload with progress tracking
      final receivePort = ReceivePort();
      await Isolate.spawn(_uploadBytesWithProgress, {
        'sendPort': receivePort.sendPort,
        'bytes': bytes,
        'fileName': fileName,
        'fileMetadata': fileToUpload.toJson(),
        'accessToken': accessToken,
        'folderId': folderId,
      });

      // Listen for progress updates
      await for (final message in receivePort) {
        if (message is double) {
          onUploadProgress(message);
        } else if (message == 'success') {
          receivePort.close();
          ErrorHandler.logInfo('Bytes uploaded successfully: $fileName');
          return UploadStatus.uploadSuccess;
        } else if (message is String && message.startsWith('error:')) {
          receivePort.close();
          throw UploadException.failed(message.substring(6));
        }
      }

      return UploadStatus.uploadSuccess;
    } catch (e) {
      ErrorHandler.handleError(e, context: 'GoogleDriveService.uploadBytesToGoogleDrive');
      if (e is AppException) rethrow;
      return UploadStatus.uploadFailed;
    }
  }

  /// Get or create folder ID
  Future<String?> _getOrCreateFolderId(
    ga.DriveApi drive,
    String folderName,
    String parentFolderId,
  ) async {
    try {
      final effectiveParentId = parentFolderId.isEmpty ? 'root' : parentFolderId;
      
      // Check if folder already exists
      final folderList = await drive.files.list(
        q: "name='$folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false and '$effectiveParentId' in parents",
      );

      if (folderList.files != null && folderList.files!.isNotEmpty) {
        return folderList.files!.first.id;
      }

      // Create new folder
      final folder = ga.File()
        ..name = folderName
        ..parents = [effectiveParentId]
        ..mimeType = 'application/vnd.google-apps.folder';

      final folderCreation = await drive.files.create(folder);

      // Make the folder publicly accessible
      final permission = ga.Permission()
        ..role = 'reader'
        ..type = 'anyone';

      await drive.permissions.create(permission, folderCreation.id!);

      return folderCreation.id;
    } catch (e) {
      ErrorHandler.handleError(e, context: 'GoogleDriveService._getOrCreateFolderId');
      return null;
    }
  }

  /// Format bytes to human readable format
  String _formatBytes(double bytes) {
    if (bytes < 1024) return '${bytes.toStringAsFixed(0)} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Static method for file upload in isolate
  static void _uploadFileWithProgress(Map<String, dynamic> params) async {
    try {
      final sendPort = params['sendPort'] as SendPort;
      final filePath = params['filePath'] as String;
      final accessToken = params['accessToken'] as String;

      final client = GoogleHttpClient({'Authorization': 'Bearer $accessToken'});
      final drive = ga.DriveApi(client);

      final file = File(filePath);
      final fileSize = await file.length();
      const chunkSize = 1024 * 1024; // 1MB chunks

      final fileToUpload = ga.File()
        ..parents = [params['folderId'] as String]
        ..name = path.basename(filePath);

      // Upload with progress tracking
      await drive.files.create(
        fileToUpload,
        uploadMedia: ga.Media(file.openRead(), fileSize),
        uploadOptions: ga.ResumableUploadOptions(),
      );

      // Simulate progress for now - in a real implementation you'd track actual progress
      for (int i = 0; i <= 100; i += 10) {
        sendPort.send(i / 100.0);
        await Future.delayed(const Duration(milliseconds: 50));
      }

      sendPort.send('success');
    } catch (e) {
      (params['sendPort'] as SendPort).send('error:$e');
    }
  }

  /// Static method for bytes upload in isolate
  static void _uploadBytesWithProgress(Map<String, dynamic> params) async {
    try {
      final sendPort = params['sendPort'] as SendPort;
      final bytes = params['bytes'] as Uint8List;
      final fileName = params['fileName'] as String;
      final accessToken = params['accessToken'] as String;

      final client = GoogleHttpClient({'Authorization': 'Bearer $accessToken'});
      final drive = ga.DriveApi(client);

      final fileToUpload = ga.File()
        ..parents = [params['folderId'] as String]
        ..name = fileName;

      // Upload with progress tracking
      await drive.files.create(
        fileToUpload,
        uploadMedia: ga.Media(Stream.value(bytes), bytes.length),
        uploadOptions: ga.ResumableUploadOptions(),
      );

      // Simulate progress for now
      for (int i = 0; i <= 100; i += 10) {
        sendPort.send(i / 100.0);
        await Future.delayed(const Duration(milliseconds: 50));
      }

      sendPort.send('success');
    } catch (e) {
      (params['sendPort'] as SendPort).send('error:$e');
    }
  }
}

/// Custom HTTP client for Google APIs
class GoogleHttpClient extends IOClient {
  final Map<String, String> _headers;

  GoogleHttpClient(this._headers) : super();

  @override
  Future<IOStreamedResponse> send(http.BaseRequest request) =>
      super.send(request..headers.addAll(_headers));

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) =>
      super.head(url, headers: headers!..addAll(_headers));
}