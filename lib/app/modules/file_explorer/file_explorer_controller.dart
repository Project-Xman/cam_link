import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:watcher/watcher.dart';
import 'package:path/path.dart' as path;
import '../../data/models/enums.dart';
import '../../data/models/file_status_model.dart';
import '../../data/services/image_processing_service.dart';
import '../../data/services/google_drive_service.dart';
import '../../data/services/auth_service.dart';
import '../../core/errors/app_exception.dart';
import '../../core/values/app_strings.dart';

/// File Explorer Controller using GetX patterns
class FileExplorerController extends GetxController {
  static FileExplorerController get to => Get.find();

  // Services
  late final ImageProcessingService _imageProcessingService;
  late final GoogleDriveService _googleDriveService;
  late final AuthService _authService;

  // Observable state
  final selectedPath = ''.obs;
  final outputPath = ''.obs;
  final isWatching = false.obs;
  final fileList = <String>[].obs;
  final fileStatusMap = <String, FileStatusModel>{}.obs;
  
  // Processing settings
  final selectedOverlayImage = Rxn<String>();
  final logoDimensions = <int>[0, 0].obs;
  final resolutionWidth = 1920.obs;
  final resolutionHeight = 1080.obs;
  final saveOutputToDevice = false.obs;
  
  // Cloud folder settings
  final folderNameController = ''.obs;
  final cloudFolderCreated = false.obs;
  
  // Statistics
  final imagesDetected = 0.obs;
  final imagesProcessed = 0.obs;
  final imagesUploaded = 0.obs;
  
  // Internal state
  DirectoryWatcher? _directoryWatcher;
  StreamSubscription? _watcherSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
  }

  @override
  void onClose() {
    stopWatching();
    _watcherSubscription?.cancel();
    super.onClose();
  }

  void _initializeServices() {
    _imageProcessingService = ImageProcessingService.to;
    _googleDriveService = GoogleDriveService.to;
    _authService = AuthService.to;
  }

  /// Select a folder to monitor
  Future<void> selectFolder(String folderPath) async {
    try {
      final directory = Directory(folderPath);
      if (!await directory.exists()) {
        throw FileException.notFound(folderPath);
      }

      selectedPath.value = folderPath;
      await refreshFileList();
      await startWatching();
      
      Get.showSnackbar(
        GetSnackBar(
          title: AppStrings.folderSelected,
          message: folderPath,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ErrorHandler.handleError(e, context: 'FileExplorerController.selectFolder');
      Get.showSnackbar(
        GetSnackBar(
          title: AppStrings.error,
          message: e.toString(),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Select output folder for processed images
  Future<void> selectOutputFolder(String folderPath) async {
    try {
      final directory = Directory(folderPath);
      if (!await directory.exists()) {
        throw FileException.notFound(folderPath);
      }

      outputPath.value = folderPath;
      
      Get.showSnackbar(
        GetSnackBar(
          title: AppStrings.outputFolderSelected,
          message: folderPath,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ErrorHandler.handleError(e, context: 'FileExplorerController.selectOutputFolder');
      Get.showSnackbar(
        GetSnackBar(
          title: AppStrings.error,
          message: e.toString(),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Select overlay image (logo/watermark)
  Future<void> selectOverlayImage(String imagePath) async {
    try {
      if (!imagePath.toLowerCase().endsWith('.png')) {
        throw ImageProcessingException.unsupportedFormat('PNG files only');
      }

      if (!await File(imagePath).exists()) {
        throw FileException.notFound(imagePath);
      }

      selectedOverlayImage.value = imagePath;
      
      // Get image dimensions
      final dimensions = await _imageProcessingService.getImageSize(imagePath);
      logoDimensions.value = dimensions;
      
      Get.showSnackbar(
        GetSnackBar(
          title: AppStrings.overlayImageSelected,
          message: path.basename(imagePath),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ErrorHandler.handleError(e, context: 'FileExplorerController.selectOverlayImage');
      Get.showSnackbar(
        GetSnackBar(
          title: AppStrings.error,
          message: e.toString(),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Start watching the selected directory
  Future<void> startWatching() async {
    if (selectedPath.value.isEmpty) {
      Get.showSnackbar(
        GetSnackBar(
          title: AppStrings.error,
          message: AppStrings.noFolderSelected,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      await stopWatching();
      
      _directoryWatcher = DirectoryWatcher(selectedPath.value);
      _watcherSubscription = _directoryWatcher!.events.listen((event) {
        _handleFileSystemEvent(event);
      });
      
      isWatching.value = true;
      
      Get.showSnackbar(
        GetSnackBar(
          title: AppStrings.success,
          message: 'Started watching: ${selectedPath.value}',
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ErrorHandler.handleError(e, context: 'FileExplorerController.startWatching');
      Get.showSnackbar(
        GetSnackBar(
          title: AppStrings.error,
          message: 'Failed to start watching: $e',
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Stop watching the directory
  Future<void> stopWatching() async {
    await _watcherSubscription?.cancel();
    _watcherSubscription = null;
    _directoryWatcher = null;
    isWatching.value = false;
  }

  /// Handle file system events
  void _handleFileSystemEvent(WatchEvent event) {
    if (event.type == ChangeType.ADD || event.type == ChangeType.MODIFY) {
      // Check if it's an image file
      final extension = path.extension(event.path).toLowerCase();
      if (['.jpg', '.jpeg', '.png', '.bmp', '.webp'].contains(extension)) {
        _addFileToProcess(event.path);
      }
    } else if (event.type == ChangeType.REMOVE) {
      _removeFileFromProcess(event.path);
    }
  }

  /// Add file to processing queue
  void _addFileToProcess(String filePath) {
    fileStatusMap[filePath] = FileStatusModel(
      filePath: filePath,
      processStatus: ProcessStatus.notStarted,
      uploadStatus: UploadStatus.notSynced,
      uploadProgress: 0.0,
    );
    
    imagesDetected.value++;
    refreshFileList();
    
    // Auto-process if conditions are met
    if (cloudFolderCreated.value) {
      processFile(filePath);
    }
  }

  /// Remove file from processing
  void _removeFileFromProcess(String filePath) {
    fileStatusMap.remove(filePath);
    refreshFileList();
  }

  /// Process a single file
  Future<void> processFile(String filePath) async {
    if (folderNameController.value.isEmpty) {
      Get.showSnackbar(
        GetSnackBar(
          title: AppStrings.error,
          message: 'Cloud folder not created',
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Update status to processing
      final currentStatus = fileStatusMap[filePath];
      if (currentStatus != null) {
        fileStatusMap[filePath] = currentStatus.copyWith(
          processStatus: ProcessStatus.processing,
        );
      }

      String? localOutputPath;
      if (saveOutputToDevice.value && outputPath.value.isNotEmpty) {
        localOutputPath = path.join(outputPath.value, path.basename(filePath));
      }

      // Process the image
      await _imageProcessingService.processFile(
        filePath: filePath,
        logoPath: selectedOverlayImage.value,
        outputPath: localOutputPath,
        resolutionHeight: resolutionHeight.value,
        resolutionWidth: resolutionWidth.value,
        saveOutputToDevice: saveOutputToDevice.value,
        onProcessed: (status, outputPath, imageBytes) async {
          await _onFileProcessed(filePath, status, outputPath, imageBytes);
        },
      );
    } catch (e) {
      ErrorHandler.handleError(e, context: 'FileExplorerController.processFile');
      
      // Update status to failed
      final currentStatus = fileStatusMap[filePath];
      if (currentStatus != null) {
        fileStatusMap[filePath] = currentStatus.copyWith(
          processStatus: ProcessStatus.failed,
        );
      }
    }
  }

  /// Handle file processing completion
  Future<void> _onFileProcessed(
    String filePath,
    ProcessStatus status,
    String? localOutputPath,
    Uint8List? imageBytes,
  ) async {
    // Update process status
    final currentStatus = fileStatusMap[filePath];
    if (currentStatus != null) {
      fileStatusMap[filePath] = currentStatus.copyWith(
        processStatus: status,
      );
    }

    if (status == ProcessStatus.processed) {
      imagesProcessed.value++;
      
      // Upload to Google Drive
      if (saveOutputToDevice.value && localOutputPath != null) {
        await _uploadFileToDrive(localOutputPath, filePath);
      } else if (imageBytes != null) {
        await _uploadBytesToDrive(imageBytes, filePath);
      }
    }
  }

  /// Upload file to Google Drive
  Future<void> _uploadFileToDrive(String localPath, String originalPath) async {
    try {
      // Update status to uploading
      final currentStatus = fileStatusMap[originalPath];
      if (currentStatus != null) {
        fileStatusMap[originalPath] = currentStatus.copyWith(
          uploadStatus: UploadStatus.uploading,
          uploadProgress: 0.0,
        );
      }

      final file = File(localPath);
      final uploadStatus = await _googleDriveService.uploadFileToGoogleDrive(
        folderNameController.value,
        file,
        (progress) {
          // Update progress
          final progressStatus = fileStatusMap[originalPath];
          if (progressStatus != null) {
            fileStatusMap[originalPath] = progressStatus.copyWith(
              uploadProgress: progress,
            );
          }
        },
      );

      // Update final status
      final finalStatus = fileStatusMap[originalPath];
      if (finalStatus != null) {
        fileStatusMap[originalPath] = finalStatus.copyWith(
          uploadStatus: uploadStatus,
          uploadProgress: uploadStatus == UploadStatus.uploadSuccess ? 1.0 : 0.0,
        );
      }

      if (uploadStatus == UploadStatus.uploadSuccess) {
        imagesUploaded.value++;
      }
    } catch (e) {
      ErrorHandler.handleError(e, context: 'FileExplorerController._uploadFileToDrive');
      
      // Update status to failed
      final currentStatus = fileStatusMap[originalPath];
      if (currentStatus != null) {
        fileStatusMap[originalPath] = currentStatus.copyWith(
          uploadStatus: UploadStatus.uploadFailed,
        );
      }
    }
  }

  /// Upload bytes to Google Drive
  Future<void> _uploadBytesToDrive(Uint8List bytes, String originalPath) async {
    try {
      // Update status to uploading
      final currentStatus = fileStatusMap[originalPath];
      if (currentStatus != null) {
        fileStatusMap[originalPath] = currentStatus.copyWith(
          uploadStatus: UploadStatus.uploading,
          uploadProgress: 0.0,
        );
      }

      final fileName = path.basename(originalPath);
      final uploadStatus = await _googleDriveService.uploadBytesToGoogleDrive(
        folderNameController.value,
        bytes,
        fileName,
        (progress) {
          // Update progress
          final progressStatus2 = fileStatusMap[originalPath];
          if (progressStatus2 != null) {
            fileStatusMap[originalPath] = progressStatus2.copyWith(
              uploadProgress: progress,
            );
          }
        },
      );

      // Update final status
      final finalStatus2 = fileStatusMap[originalPath];
      if (finalStatus2 != null) {
        fileStatusMap[originalPath] = finalStatus2.copyWith(
          uploadStatus: uploadStatus,
          uploadProgress: uploadStatus == UploadStatus.uploadSuccess ? 1.0 : 0.0,
        );
      }

      if (uploadStatus == UploadStatus.uploadSuccess) {
        imagesUploaded.value++;
      }
    } catch (e) {
      ErrorHandler.handleError(e, context: 'FileExplorerController._uploadBytesToDrive');
      
      // Update status to failed
      final currentStatus = fileStatusMap[originalPath];
      if (currentStatus != null) {
        fileStatusMap[originalPath] = currentStatus.copyWith(
          uploadStatus: UploadStatus.uploadFailed,
        );
      }
    }
  }

  /// Create cloud folder
  Future<void> createCloudFolder() async {
    if (folderNameController.value.isEmpty) {
      Get.showSnackbar(
        GetSnackBar(
          title: AppStrings.error,
          message: 'Please enter a folder name',
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final now = DateTime.now();
      final formattedDate = '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
      final finalFolderName = '$formattedDate ${folderNameController.value}';
      
      final success = await _googleDriveService.createFolder(finalFolderName);
      
      if (success) {
        folderNameController.value = finalFolderName;
        cloudFolderCreated.value = true;
        
        Get.showSnackbar(
          GetSnackBar(
            title: AppStrings.success,
            message: AppStrings.cloudFolderCreated,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        Get.showSnackbar(
          GetSnackBar(
            title: AppStrings.error,
            message: AppStrings.cloudFolderCreateFailed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ErrorHandler.handleError(e, context: 'FileExplorerController.createCloudFolder');
      Get.showSnackbar(
        GetSnackBar(
          title: AppStrings.error,
          message: 'Failed to create folder: $e',
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Refresh file list
  Future<void> refreshFileList() async {
    if (selectedPath.value.isEmpty) return;

    try {
      final directory = Directory(selectedPath.value);
      final entities = await directory.list().toList();
      
      fileList.value = entities
          .whereType<File>()
          .map((entity) => entity.path)
          .where((path) {
            final extension = path.split('.').last.toLowerCase();
            return ['jpg', 'jpeg', 'png', 'bmp', 'webp'].contains(extension);
          })
          .toList();
    } catch (e) {
      ErrorHandler.handleError(e, context: 'FileExplorerController._refreshFileList');
    }
  }

  /// Reset all statistics
  void resetStatistics() {
    imagesDetected.value = 0;
    imagesProcessed.value = 0;
    imagesUploaded.value = 0;
    fileStatusMap.clear();
  }

  /// Get file status for a specific file
  FileStatusModel? getFileStatus(String filePath) {
    return fileStatusMap[filePath];
  }

  /// Update resolution settings
  void updateResolution(int width, int height) {
    resolutionWidth.value = width;
    resolutionHeight.value = height;
  }

  /// Toggle save to device setting
  void toggleSaveToDevice() {
    saveOutputToDevice.value = !saveOutputToDevice.value;
  }
}