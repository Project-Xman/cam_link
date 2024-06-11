import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get/get.dart';

class GlobalState extends GetxController {
  RxInt imagesDetected = 0.obs;
  RxInt imagesProcessed = 0.obs;
  RxInt imagesUploaded = 0.obs;

  void incrementImagesDetected() async {
    imagesDetected.value++;
    await showImageProcessingOverlay(
        imagesDetected.value, imagesProcessed.value, imagesUploaded.value);
  }

  void incrementImagesProcessed() async {
    imagesProcessed.value++;
    await showImageProcessingOverlay(
        imagesDetected.value, imagesProcessed.value, imagesUploaded.value);
  }

  void incrementImagesUploaded() async {
    imagesUploaded.value++;
    await showImageProcessingOverlay(
        imagesDetected.value, imagesProcessed.value, imagesUploaded.value);
  }

  Future<void> showImageProcessingOverlay(
      int totalImages, int processed, int uploaded) async {
    await FlutterOverlayWindow.shareData([totalImages, processed, uploaded]);
  }

  void reset() async {
    imagesDetected.value = 0;
    imagesProcessed.value = 0;
    imagesUploaded.value = 0;
    await showImageProcessingOverlay(
        imagesDetected.value, imagesProcessed.value, imagesUploaded.value);
  }

  int get totalImages => imagesDetected.value;
  int get totalImagesProcessed => imagesProcessed.value;
  int get totalImagesUploaded => imagesUploaded.value;
}
