import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/services/google_drive_service.dart';
import '../../../data/models/enums.dart' as enums;
import '../../../core/errors/app_exception.dart';
import '../../image_processing/models/selected_image.dart';

/// Upload states
enum UploadState { pending, uploading, completed, failed }

/// Upload status for individual images
class UploadStatus {
  final UploadState status;
  final double progress;
  final String? error;

  UploadStatus({
    required this.status,
    this.progress = 0.0,
    this.error,
  });

  bool get isUploading => status == UploadState.uploading;
  bool get isCompleted => status == UploadState.completed;
  bool get isFailed => status == UploadState.failed;
  bool get isPending => status == UploadState.pending;
}

/// Controller for upload manager functionality
class UploadManagerController extends GetxController {
  // Dependencies
  late final GoogleDriveService _driveService;

  // Reactive variables
  final isLoading = false.obs;
  final isUploading = false.obs;
  final images = <SelectedImage>[].obs;
  final uploadStatuses = <UploadStatus>[].obs;

  // Upload options
  final createDateFolders = true.obs;
  final overwriteExisting = false.obs;
  final addTimestamp = true.obs;

  // Text controllers
  late final TextEditingController folderNameController;

  // Getters
  bool get hasImages => images.isNotEmpty;
  bool get hasCompletedUploads =>
      uploadStatuses.any((status) => status.isCompleted);
  int get totalImages => images.length;
  int get completedUploads =>
      uploadStatuses.where((status) => status.isCompleted).length;
  int get failedUploads =>
      uploadStatuses.where((status) => status.isFailed).length;
  int get remainingUploads => totalImages - completedUploads - failedUploads;
  double get overallProgress =>
      totalImages > 0 ? completedUploads / totalImages : 0.0;

  @override
  void onInit() {
    super.onInit();
    _initializeService();
    _initializeControllers();
    _loadArgumentImages();
  }

  @override
  void onClose() {
    _disposeControllers();
    super.onClose();
  }

  /// Initialize service
  void _initializeService() {
    _driveService = GoogleDriveService.to;
  }

  /// Initialize text controllers
  void _initializeControllers() {
    folderNameController = TextEditingController(text: 'ProcessedImages');
  }

  /// Dispose text controllers
  void _disposeControllers() {
    folderNameController.dispose();
  }

  /// Load images from navigation arguments
  void _loadArgumentImages() {
    final arguments = Get.arguments;
    if (arguments != null && arguments is List<SelectedImage>) {
      images.addAll(arguments);
      _initializeUploadStatuses();
    }
  }

  /// Initialize upload statuses for all images
  void _initializeUploadStatuses() {
    uploadStatuses.clear();
    for (int i = 0; i < images.length; i++) {
      uploadStatuses.add(UploadStatus(status: UploadState.pending));
    }
  }

  /// Select more images to add to upload queue
  Future<void> selectMoreImages() async {
    try {
      isLoading.value = true;

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (file.bytes != null) {
            final selectedImage = SelectedImage(
              name: file.name,
              bytes: file.bytes!,
              size: file.size,
            );
            images.add(selectedImage);
            uploadStatuses.add(UploadStatus(status: UploadState.pending));
          }
        }

        Get.snackbar(
          'Images Added',
          '${result.files.length} image(s) added to upload queue',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primaryContainer,
        );
      }
    } catch (e) {
      _handleError('Failed to select images', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Remove image at index
  void removeImage(int index) {
    if (index >= 0 && index < images.length) {
      images.removeAt(index);
      uploadStatuses.removeAt(index);
    }
  }

  /// Clear all images
  void clearAll() {
    images.clear();
    uploadStatuses.clear();
    Get.snackbar(
      'Queue Cleared',
      'All images have been removed from upload queue',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Toggle date folders option
  void toggleDateFolders(bool? value) {
    createDateFolders.value = value ?? true;
  }

  /// Toggle overwrite existing option
  void toggleOverwrite(bool? value) {
    overwriteExisting.value = value ?? false;
  }

  /// Toggle timestamp option
  void toggleTimestamp(bool? value) {
    addTimestamp.value = value ?? true;
  }

  /// Upload all images
  Future<void> uploadAll() async {
    if (images.isEmpty) {
      Get.snackbar(
        'No Images',
        'Please select images to upload',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
      return;
    }

    if (!_driveService.isConnected) {
      Get.snackbar(
        'Not Connected',
        'Please connect to Google Drive first',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
      return;
    }

    try {
      isUploading.value = true;

      // Reset all statuses to pending
      for (int i = 0; i < uploadStatuses.length; i++) {
        uploadStatuses[i] = UploadStatus(status: UploadState.pending);
      }

      // Upload images one by one
      for (int i = 0; i < images.length; i++) {
        await _uploadSingleImage(i);
      }

      // Show completion message
      final completed = completedUploads;
      final failed = failedUploads;

      if (failed == 0) {
        Get.snackbar(
          'Upload Complete',
          'All $completed images uploaded successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primaryContainer,
        );
      } else {
        Get.snackbar(
          'Upload Finished',
          '$completed uploaded, $failed failed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
        );
      }
    } catch (e) {
      _handleError('Upload process failed', e);
    } finally {
      isUploading.value = false;
    }
  }

  /// Upload a single image
  Future<void> _uploadSingleImage(int index) async {
    if (index >= images.length) return;

    final image = images[index];

    try {
      // Update status to uploading
      uploadStatuses[index] = UploadStatus(
        status: UploadState.uploading,
        progress: 0.0,
      );

      // Generate filename
      final filename = _generateFilename(image.name);

      // Generate folder name
      final folderName = _generateFolderName();

      // Simulate upload progress (since Google Drive API doesn't provide real progress)
      for (double progress = 0.1; progress <= 0.9; progress += 0.1) {
        uploadStatuses[index] = UploadStatus(
          status: UploadState.uploading,
          progress: progress,
        );
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Perform actual upload
      final result = await _driveService.uploadBytesToGoogleDrive(
        folderName,
        image.bytes,
        filename,
        (progress) {
          uploadStatuses[index] = UploadStatus(
            status: UploadState.uploading,
            progress: progress,
          );
        },
      );

      // Update final status
      if (result == enums.UploadStatus.uploadSuccess) {
        uploadStatuses[index] = UploadStatus(
          status: UploadState.completed,
          progress: 1.0,
        );
      } else {
        uploadStatuses[index] = UploadStatus(
          status: UploadState.failed,
          error: 'Upload failed',
        );
      }
    } catch (e) {
      uploadStatuses[index] = UploadStatus(
        status: UploadState.failed,
        error: e.toString(),
      );
    }
  }

  /// Generate filename with options
  String _generateFilename(String originalName) {
    String filename = originalName;

    // Add timestamp if enabled
    if (addTimestamp.value) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final parts = filename.split('.');
      if (parts.length > 1) {
        final name = parts.sublist(0, parts.length - 1).join('.');
        final extension = parts.last;
        filename = '${name}_$timestamp.$extension';
      } else {
        filename = '${filename}_$timestamp';
      }
    }

    return filename;
  }

  /// Generate folder name with options
  String _generateFolderName() {
    String folderName = folderNameController.text.trim();
    if (folderName.isEmpty) {
      folderName = 'ProcessedImages';
    }

    // Add date subfolder if enabled
    if (createDateFolders.value) {
      final now = DateTime.now();
      final dateFolder =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      folderName = '$folderName/$dateFolder';
    }

    return folderName;
  }

  /// Handle errors
  void _handleError(String message, dynamic error) {
    ErrorHandler.handleError(error, context: 'UploadManagerController');

    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.errorContainer,
      colorText: Get.theme.colorScheme.onErrorContainer,
    );
  }
}
