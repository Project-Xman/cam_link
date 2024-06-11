import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageProcessor {
  static Future<img.Image?> _openRawImage(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return img.decodeImage(bytes);
  }

  static Future<img.Image> _resizeImage(
      img.Image image, int targetWidth, int targetHeight) async {
    return img.copyResize(image, width: targetWidth, height: targetHeight);
  }

  Future<List<int>> getImageSize(String? logoPath) async {
    if (logoPath == null || logoPath.isEmpty || logoPath == "None") {
      return [0, 0];
    }
    final logoBytes = await File(logoPath).readAsBytes();
    final image = img.decodeImage(logoBytes);
    if (image == null) {
      return [0, 0];
    }
    final height = image.height;
    final width = image.width;
    return [height, width];
  }

  static Future<void> _addLogoToImage(img.Image image, String? logoPath) async {
    if (logoPath == null || logoPath.isEmpty || logoPath == "None") {
      return; // Skip adding logo if path is invalid
    }

    List<int> logoDimensions = await ImageProcessor().getImageSize(logoPath);
    if (logoDimensions[0] == 0 && logoDimensions[1] == 0) {
      return;
    }

    int logoWidth = logoDimensions[1];
    final targetX = image.width - logoWidth;
    const targetY = 0; // Top-right corner

    img.Image? logoImage = await _openRawImage(logoPath);
    if (logoImage != null) {
      img.compositeImage(image, logoImage, dstX: targetX, dstY: targetY);
    }
  }

  static Future<void> _saveImage(img.Image image, String? outputPath) async {
    if (outputPath == null || outputPath.isEmpty || outputPath == "None") {
      return; // Skip saving if output path is invalid
    }
    final encodedImage = img.encodePng(image);
    await File(outputPath).writeAsBytes(encodedImage);
  }

  Future<Uint8List> processImageToBytes({
    required String filePath,
    String? logoPath,
    required int resolutionWidth,
    required int resolutionHeight,
  }) async {
    final image = await _openRawImage(filePath);
    if (image == null) {
      throw Exception('Failed to open image: $filePath');
    }

    final resizedImage =
        await _resizeImage(image, resolutionWidth, resolutionHeight);
    await _addLogoToImage(
        resizedImage, logoPath); // This will skip if logoPath is invalid

    return img.encodePng(resizedImage);
  }

  static void _processFileInIsolate(List<dynamic> args) async {
    final SendPort sendPort = args[0];
    final String filePath = args[1];
    final String? logoPath = args[2];
    final String? outputPath = args[3];
    final int resolutionHeight = args[4];
    final int resolutionWidth = args[5];
    final bool saveOutputToDevice = args[6];

    final image = await _openRawImage(filePath);
    if (image != null) {
      final resizedImage =
          await _resizeImage(image, resolutionWidth, resolutionHeight);
      await _addLogoToImage(
          resizedImage, logoPath); // This will skip if logoPath is invalid

      if (saveOutputToDevice &&
          outputPath != null &&
          outputPath.isNotEmpty &&
          outputPath != "None") {
        await _saveImage(resizedImage, outputPath);
        sendPort.send([filePath, 'Processed', outputPath, null]);
      } else {
        final encodedImage = img.encodePng(resizedImage);
        sendPort.send([filePath, 'Processed', null, encodedImage]);
      }
    } else {
      sendPort.send([filePath, 'Failed', null, null]);
    }
  }

  Future<void> processFile({
    required String filePath,
    String? logoPath,
    String? outputPath,
    required int resolutionHeight,
    required int resolutionWidth,
    required bool saveOutputToDevice,
    required Function(String, String?, Uint8List?) onProcessed,
  }) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_processFileInIsolate, [
      receivePort.sendPort,
      filePath,
      logoPath,
      outputPath,
      resolutionHeight,
      resolutionWidth,
      saveOutputToDevice
    ]);

    receivePort.listen((message) {
      final status = message[1];
      final localOutputPath = message[2];
      final imageBytes = message[3];

      onProcessed(status, localOutputPath, imageBytes);
      receivePort.close();
    });
  }
}
