import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import '../models/enums.dart';
import '../../core/errors/app_exception.dart';
import '../../core/values/app_values.dart';

/// Image processing service using GetX patterns
class ImageProcessingService extends GetxService {
  static ImageProcessingService get to => Get.find();

  /// Get image dimensions from file path
  Future<List<int>> getImageSize(String? imagePath) async {
    try {
      if (imagePath == null || imagePath.isEmpty || imagePath == "None") {
        return [0, 0];
      }

      final file = File(imagePath);
      if (!await file.exists()) {
        throw FileException.notFound(imagePath);
      }

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw ImageProcessingException.corruptedImage();
      }

      return [image.height, image.width];
    } catch (e) {
      ErrorHandler.handleError(e, context: 'ImageProcessingService.getImageSize');
      if (e is AppException) rethrow;
      throw ImageProcessingException.processingFailed(e.toString());
    }
  }

  /// Validate image file format
  bool isValidImageFormat(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    return AppValues.supportedImageFormats.contains('.$extension');
  }

  /// Process image to bytes without saving to disk
  Future<Uint8List> processImageToBytes({
    required String filePath,
    String? logoPath,
    required int resolutionWidth,
    required int resolutionHeight,
  }) async {
    try {
      // Validate input file
      if (!await File(filePath).exists()) {
        throw FileException.notFound(filePath);
      }

      if (!isValidImageFormat(filePath)) {
        final extension = filePath.split('.').last;
        throw ImageProcessingException.unsupportedFormat(extension);
      }

      // Check file size
      final file = File(filePath);
      final fileSizeInMB = await file.length() / (1024 * 1024);
      if (fileSizeInMB > AppValues.maxFileSizeInMB) {
        throw FileException.sizeTooLarge(AppValues.maxFileSizeInMB);
      }

      // Process in isolate for better performance
      final receivePort = ReceivePort();
      await Isolate.spawn(_processImageInIsolate, [
        receivePort.sendPort,
        filePath,
        logoPath,
        resolutionWidth,
        resolutionHeight,
      ]);

      final completer = Completer<Uint8List>();
      receivePort.listen((message) {
        receivePort.close();
        if (message is String && message.startsWith('ERROR:')) {
          completer.completeError(
            ImageProcessingException.processingFailed(message.substring(6))
          );
        } else if (message is Uint8List) {
          completer.complete(message);
        } else {
          completer.completeError(
            ImageProcessingException.processingFailed('Unknown error')
          );
        }
      });

      return await completer.future.timeout(
        const Duration(seconds: AppValues.uploadTimeoutSeconds),
        onTimeout: () {
          throw ImageProcessingException.processingFailed('Processing timeout');
        },
      );
    } catch (e) {
      ErrorHandler.handleError(e, context: 'ImageProcessingService.processImageToBytes');
      rethrow;
    }
  }

  /// Process file with callback for progress updates
  Future<void> processFile({
    required String filePath,
    String? logoPath,
    String? outputPath,
    required int resolutionHeight,
    required int resolutionWidth,
    required bool saveOutputToDevice,
    required Function(ProcessStatus status, String? localOutputPath, Uint8List? imageBytes) onProcessed,
  }) async {
    try {
      // Validate input
      if (!await File(filePath).exists()) {
        onProcessed(ProcessStatus.failed, null, null);
        return;
      }

      if (!isValidImageFormat(filePath)) {
        onProcessed(ProcessStatus.failed, null, null);
        return;
      }

      // Process in isolate
      final receivePort = ReceivePort();
      await Isolate.spawn(_processFileInIsolate, [
        receivePort.sendPort,
        filePath,
        logoPath,
        outputPath,
        resolutionHeight,
        resolutionWidth,
        saveOutputToDevice,
      ]);

      receivePort.listen((message) {
        receivePort.close();
        
        if (message is List && message.length == 4) {
          final status = message[1] == 'Processed' ? ProcessStatus.processed : ProcessStatus.failed;
          final localOutputPath = message[2] as String?;
          final imageBytes = message[3] as Uint8List?;
          
          onProcessed(status, localOutputPath, imageBytes);
        } else {
          onProcessed(ProcessStatus.failed, null, null);
        }
      });
    } catch (e) {
      ErrorHandler.handleError(e, context: 'ImageProcessingService.processFile');
      onProcessed(ProcessStatus.failed, null, null);
    }
  }

  /// Static method to open and decode image
  static Future<img.Image?> _openRawImage(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      return img.decodeImage(bytes);
    } catch (e) {
      return null;
    }
  }

  /// Static method to resize image
  static Future<img.Image> _resizeImage(
      img.Image image, int targetWidth, int targetHeight) async {
    return img.copyResize(image, width: targetWidth, height: targetHeight);
  }

  /// Static method to add logo overlay
  static Future<void> _addLogoToImage(img.Image image, String? logoPath) async {
    if (logoPath == null || logoPath.isEmpty || logoPath == "None") {
      return; // Skip adding logo if path is invalid
    }

    try {
      final logoImage = await _openRawImage(logoPath);
      if (logoImage != null) {
        final targetX = image.width - logoImage.width;
        const targetY = 0; // Top-right corner
        img.compositeImage(image, logoImage, dstX: targetX, dstY: targetY);
      }
    } catch (e) {
      // Log error but continue without logo
      ErrorHandler.logWarning('Failed to add logo: $e', 'ImageProcessingService');
    }
  }

  /// Static method to save image
  static Future<void> _saveImage(img.Image image, String? outputPath) async {
    if (outputPath == null || outputPath.isEmpty || outputPath == "None") {
      return; // Skip saving if output path is invalid
    }
    
    try {
      final encodedImage = img.encodePng(image);
      await File(outputPath).writeAsBytes(encodedImage);
    } catch (e) {
      throw FileException.accessDenied(outputPath);
    }
  }

  /// Isolate function for processing image to bytes
  static void _processImageInIsolate(List<dynamic> args) async {
    try {
      final SendPort sendPort = args[0];
      final String filePath = args[1];
      final String? logoPath = args[2];
      final int resolutionWidth = args[3];
      final int resolutionHeight = args[4];

      final image = await _openRawImage(filePath);
      if (image == null) {
        sendPort.send('ERROR:Failed to decode image');
        return;
      }

      final resizedImage = await _resizeImage(image, resolutionWidth, resolutionHeight);
      await _addLogoToImage(resizedImage, logoPath);

      final encodedImage = img.encodePng(resizedImage);
      sendPort.send(encodedImage);
    } catch (e) {
      (args[0] as SendPort).send('ERROR:$e');
    }
  }

  /// Isolate function for processing file with output
  static void _processFileInIsolate(List<dynamic> args) async {
    try {
      final SendPort sendPort = args[0];
      final String filePath = args[1];
      final String? logoPath = args[2];
      final String? outputPath = args[3];
      final int resolutionHeight = args[4];
      final int resolutionWidth = args[5];
      final bool saveOutputToDevice = args[6];

      final image = await _openRawImage(filePath);
      if (image == null) {
        sendPort.send([filePath, 'Failed', null, null]);
        return;
      }

      final resizedImage = await _resizeImage(image, resolutionWidth, resolutionHeight);
      await _addLogoToImage(resizedImage, logoPath);

      if (saveOutputToDevice && outputPath != null && outputPath.isNotEmpty && outputPath != "None") {
        await _saveImage(resizedImage, outputPath);
        sendPort.send([filePath, 'Processed', outputPath, null]);
      } else {
        final encodedImage = img.encodePng(resizedImage);
        sendPort.send([filePath, 'Processed', null, encodedImage]);
      }
    } catch (e) {
      (args[0] as SendPort).send([args[1], 'Failed', null, null]);
    }
  }
}