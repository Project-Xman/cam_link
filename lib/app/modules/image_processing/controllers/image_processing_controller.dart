import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/services/image_processing_service.dart';
import '../../../core/errors/app_exception.dart';
import '../../../routes/app_routes.dart';
import '../models/selected_image.dart';

/// Controller for image processing functionality
class ImageProcessingController extends GetxController {
  // Dependencies
  late final ImageProcessingService _imageProcessingService;

  // Reactive variables
  final isLoading = false.obs;
  final selectedImages = <SelectedImage>[].obs;
  
  // Processing options
  final enableResize = false.obs;
  final enableTextOverlay = false.obs;
  final maintainAspectRatio = true.obs;
  final imageQuality = 0.8.obs;
  final overlayPosition = 'bottomRight'.obs;

  // Text controllers
  late final TextEditingController widthController;
  late final TextEditingController heightController;
  late final TextEditingController overlayTextController;
  late final TextEditingController fontSizeController;

  // Getters
  bool get hasSelectedImages => selectedImages.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _initializeService();
    _initializeControllers();
  }

  @override
  void onClose() {
    _disposeControllers();
    super.onClose();
  }

  /// Initialize service
  void _initializeService() {
    _imageProcessingService = ImageProcessingService.to;
  }

  /// Initialize text controllers
  void _initializeControllers() {
    widthController = TextEditingController(text: '800');
    heightController = TextEditingController(text: '600');
    overlayTextController = TextEditingController();
    fontSizeController = TextEditingController(text: '24');
  }

  /// Dispose text controllers
  void _disposeControllers() {
    widthController.dispose();
    heightController.dispose();
    overlayTextController.dispose();
    fontSizeController.dispose();
  }

  /// Select images from gallery
  Future<void> selectImages() async {
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
            selectedImages.add(selectedImage);
          }
        }

        Get.snackbar(
          'Images Selected',
          '${result.files.length} image(s) selected successfully',
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

  /// Select images from file explorer
  Future<void> selectFromFileExplorer() async {
    try {
      // Navigate to file explorer and wait for result
      final result = await Get.toNamed(AppRoutes.fileExplorer);
      
      if (result != null && result is List<SelectedImage>) {
        selectedImages.addAll(result);
        
        Get.snackbar(
          'Images Selected',
          '${result.length} image(s) selected from file explorer',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primaryContainer,
        );
      }
    } catch (e) {
      _handleError('Failed to select from file explorer', e);
    }
  }

  /// Remove image at index
  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  /// Clear all selected images
  void clearAllImages() {
    selectedImages.clear();
    Get.snackbar(
      'Images Cleared',
      'All selected images have been removed',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Toggle resize option
  void toggleResize(bool? value) {
    enableResize.value = value ?? false;
  }

  /// Toggle text overlay option
  void toggleTextOverlay(bool? value) {
    enableTextOverlay.value = value ?? false;
  }

  /// Toggle aspect ratio maintenance
  void toggleAspectRatio(bool? value) {
    maintainAspectRatio.value = value ?? true;
  }

  /// Set image quality
  void setImageQuality(double value) {
    imageQuality.value = value;
  }

  /// Set overlay position
  void setOverlayPosition(String? position) {
    if (position != null) {
      overlayPosition.value = position;
    }
  }

  /// Preview processing with current settings
  Future<void> previewProcessing() async {
    if (selectedImages.isEmpty) {
      Get.snackbar(
        'No Images',
        'Please select images to preview',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Process first image as preview
      final firstImage = selectedImages.first;
      final processedBytes = await _processImage(firstImage.bytes);

      // Show preview dialog
      Get.dialog(
        AlertDialog(
          title: const Text('Processing Preview'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: Column(
              children: [
                Expanded(
                  child: Image.memory(
                    processedBytes,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preview of processed image with current settings',
                  style: Get.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                Get.back();
                processImages();
              },
              child: const Text('Process All'),
            ),
          ],
        ),
      );
    } catch (e) {
      _handleError('Failed to generate preview', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Process all selected images
  Future<void> processImages() async {
    if (selectedImages.isEmpty) {
      Get.snackbar(
        'No Images',
        'Please select images to process',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
      return;
    }

    try {
      isLoading.value = true;

      final processedImages = <SelectedImage>[];

      for (int i = 0; i < selectedImages.length; i++) {
        final image = selectedImages[i];
        
        // Update progress
        Get.snackbar(
          'Processing',
          'Processing image ${i + 1} of ${selectedImages.length}...',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 1),
        );

        final processedBytes = await _processImage(image.bytes);
        
        final processedImage = SelectedImage(
          name: 'processed_${image.name}',
          bytes: processedBytes,
          size: processedBytes.length,
        );
        
        processedImages.add(processedImage);
      }

      // Navigate to upload manager with processed images
      Get.toNamed('/upload-manager', arguments: processedImages);

    } catch (e) {
      _handleError('Failed to process images', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Process a single image with current settings
  Future<Uint8List> _processImage(Uint8List imageBytes) async {
    var processedBytes = imageBytes;

    // Apply resize if enabled
    if (enableResize.value) {
      final width = int.tryParse(widthController.text) ?? 800;
      final height = int.tryParse(heightController.text) ?? 600;
      
      processedBytes = await _imageProcessingService.resizeImage(
        processedBytes,
        width,
        height,
        maintainAspectRatio: maintainAspectRatio.value,
      );
    }

    // Apply text overlay if enabled
    if (enableTextOverlay.value && overlayTextController.text.isNotEmpty) {
      final fontSize = double.tryParse(fontSizeController.text) ?? 24.0;
      
      processedBytes = await _imageProcessingService.addTextOverlay(
        processedBytes,
        overlayTextController.text,
        position: overlayPosition.value,
        fontSize: fontSize,
      );
    }

    // Apply quality compression
    processedBytes = await _imageProcessingService.compressImage(
      processedBytes,
      quality: imageQuality.value,
    );

    return processedBytes;
  }

  /// Handle errors
  void _handleError(String message, dynamic error) {
    ErrorHandler.handleError(error, context: 'ImageProcessingController');
    
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.errorContainer,
      colorText: Get.theme.colorScheme.onErrorContainer,
    );
  }
}