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
import '../../data/services/google_oauth_service.dart';
import '../../core/errors/app_exception.dart';
import '../../core/values/app_strings.dart';
import '../../data/services/appwrite_auth_service.dart';

/// File Explorer Controller using GetX patterns
class FileExplorerController extends GetxController {
  static FileExplorerController get to => Get.find();

  // Services
  late final ImageProcessingService _imageProcessingService;
  late final GoogleDriveService _googleDriveService;
  late final AuthService _authService;
  late final AppwriteAuthService _appwriteAuthService;

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

  // Getters for auth services
  AuthService get authService => _authService;
  AppwriteAuthService get appwriteAuthService => _appwriteAuthService;

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
    _appwriteAuthService = AppwriteAuthService.to;
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
        const GetSnackBar(
          title: AppStrings.error,
          message: AppStrings.noFolderSelected,
          duration: Duration(seconds: 2),
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
          message: e.toString(),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Stop watching the selected directory
  Future<void> stopWatching() async {
    _watcherSubscription?.cancel();
    _directoryWatcher = null;
    isWatching.value = false;
  }

  /// Refresh the file list
  Future<void> refreshFileList() async {
    if (selectedPath.value.isEmpty) return;

    try {
      final directory = Directory(selectedPath.value);
      if (!await directory.exists()) return;

      final files = directory.listSync(recursive: false);
      final imageFiles = <String>[];

      for (final file in files) {
        if (file is File) {
          final extension = path.extension(file.path).toLowerCase();
          if (extension == '.jpg' || extension == '.jpeg' || extension == '.png') {
            imageFiles.add(file.path);
          }
        }
      }

      fileList.value = imageFiles;
      imagesDetected.value = imageFiles.length;
    } catch (e) {
      ErrorHandler.handleError(e, context: 'FileExplorerController.refreshFileList');
    }
  }

  /// Handle file system events
  void _handleFileSystemEvent(WatchEvent event) {
    // Debounce file system events to avoid processing the same file multiple times
    Future.delayed(const Duration(milliseconds: 100), () {
      refreshFileList();
    });
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

  /// Create cloud folder
  Future<void> createCloudFolder() async {
    if (folderNameController.value.isEmpty) {
      Get.showSnackbar(
        const GetSnackBar(
          title: AppStrings.error,
          message: 'Please enter a folder name',
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final success = await _googleDriveService.createFolder(folderNameController.value);
      if (success) {
        cloudFolderCreated.value = true;
        Get.showSnackbar(
          const GetSnackBar(
            title: AppStrings.success,
            message: 'Cloud folder created successfully',
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Failed to create cloud folder');
      }
    } catch (e) {
      ErrorHandler.handleError(e, context: 'FileExplorerController.createCloudFolder');
      Get.showSnackbar(
        GetSnackBar(
          title: AppStrings.error,
          message: e.toString(),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Process all images in the selected folder
  Future<void> processAllImages() async {
    if (fileList.isEmpty) {
      Get.showSnackbar(
        const GetSnackBar(
          title: AppStrings.success,
          message: 'No images to process',
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      for (final filePath in fileList) {
        await processImage(filePath);
      }
      
      Get.showSnackbar(
        const GetSnackBar(
          title: AppStrings.success,
          message: 'All images processed successfully',
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ErrorHandler.handleError(e, context: 'FileExplorerController.processAllImages');
      Get.showSnackbar(
        GetSnackBar(
          title: AppStrings.error,
          message: e.toString(),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Process a single image
  Future<void> processImage(String filePath) async {
    try {
      // Update file status
      final fileName = path.basename(filePath);
      fileStatusMap[fileName] = FileStatusModel(
        filePath: filePath,
        processStatus: ProcessStatus.processing,
        uploadStatus: UploadStatus.notSynced,
      );

      // Process image
      final outputFileName = '${path.basenameWithoutExtension(filePath)}_processed${path.extension(filePath)}';
      final outputPathFull = outputPath.value.isNotEmpty 
          ? path.join(outputPath.value, outputFileName) 
          : null;

      await _imageProcessingService.processFile(
        filePath: filePath,
        logoPath: selectedOverlayImage.value,
        outputPath: outputPathFull,
        resolutionHeight: resolutionHeight.value,
        resolutionWidth: resolutionWidth.value,
        saveOutputToDevice: saveOutputToDevice.value,
        onProcessed: (ProcessStatus status, String? localOutputPath, Uint8List? imageBytes) async {
          // Update file status based on processing result
          fileStatusMap[fileName] = fileStatusMap[fileName]!.copyWith(
            processStatus: status,
            processedAt: DateTime.now(),
          );

          if (status == ProcessStatus.processed && imageBytes != null) {
            // Upload to cloud if authenticated and platform is supported
            if (_authService.isSignedIn && _googleDriveService.platformSupported.value) {
              // Update status to uploading
              fileStatusMap[fileName] = fileStatusMap[fileName]!.copyWith(
                uploadStatus: UploadStatus.uploading,
              );

              try {
                final uploadStatus = await _googleDriveService.uploadBytesToGoogleDrive(
                  folderNameController.value.isEmpty ? 'PhotoUploader' : folderNameController.value,
                  imageBytes,
                  outputFileName,
                  (progress) {
                    // Update upload progress
                    fileStatusMap[fileName] = fileStatusMap[fileName]!.copyWith(
                      uploadProgress: progress,
                    );
                  },
                );

                // Update final upload status
                fileStatusMap[fileName] = fileStatusMap[fileName]!.copyWith(
                  uploadStatus: uploadStatus,
                  uploadedAt: DateTime.now(),
                );

                if (uploadStatus == UploadStatus.uploadSuccess) {
                  imagesUploaded.value++;
                }
              } catch (e) {
                // Update status to upload failed
                fileStatusMap[fileName] = fileStatusMap[fileName]!.copyWith(
                  uploadStatus: UploadStatus.uploadFailed,
                  errorMessage: e.toString(),
                );
              }
            }

            imagesProcessed.value++;
          } else if (status == ProcessStatus.failed) {
            // Update status to failed
            fileStatusMap[fileName] = fileStatusMap[fileName]!.copyWith(
              processStatus: ProcessStatus.failed,
              errorMessage: 'Failed to process image',
            );
          }
        },
      );
    } catch (e) {
      // Update file status to error
      final fileName = path.basename(filePath);
      fileStatusMap[fileName] = FileStatusModel(
        filePath: filePath,
        processStatus: ProcessStatus.failed,
        uploadStatus: UploadStatus.notSynced,
        errorMessage: e.toString(),
      );
      
      ErrorHandler.handleError(e, context: 'FileExplorerController.processImage');
    }
  }
  
  /// Get file status for a specific file path
  FileStatusModel? getFileStatus(String filePath) {
    final fileName = path.basename(filePath);
    return fileStatusMap[fileName];
  }
  
  /// Process a specific file (alias for processImage)
  Future<void> processFile(String filePath) async {
    return processImage(filePath);
  }
  
  /// Reset statistics
  void resetStatistics() {
    imagesDetected.value = 0;
    imagesProcessed.value = 0;
    imagesUploaded.value = 0;
    fileStatusMap.clear();
  }
}