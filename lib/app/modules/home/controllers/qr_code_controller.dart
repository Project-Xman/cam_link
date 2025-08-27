import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QRCodeController extends GetxController {
  static QRCodeController get to => Get.find();

  // Form key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Controllers - Using nullable to prevent access after disposal
  TextEditingController? _originalURLController;
  TextEditingController? _nameURLController;
  TextEditingController? _expiredURLController;
  TextEditingController? _passwordController;
  TextEditingController? _customerTextController;

  // Disposal tracking
  bool _isDisposed = false;

  // Public getters with null checks
  TextEditingController get originalURLController {
    if (_isDisposed) return TextEditingController();
    return _originalURLController ??= TextEditingController();
  }

  TextEditingController get nameURLController {
    if (_isDisposed) return TextEditingController();
    return _nameURLController ??= TextEditingController();
  }

  TextEditingController get expiredURLController {
    if (_isDisposed) return TextEditingController();
    return _expiredURLController ??= TextEditingController();
  }

  TextEditingController get passwordController {
    if (_isDisposed) return TextEditingController();
    return _passwordController ??= TextEditingController();
  }

  TextEditingController get customerTextController {
    if (_isDisposed) return TextEditingController();
    return _customerTextController ??= TextEditingController();
  }

  // Reactive variables
  final expiryTime = 0.obs;
  final cloaking = false.obs;
  final showPassword = true.obs;
  final response = ''.obs;
  final isLoading = false.obs;

  // API configuration
  String? selectedLinkId;
  String? apiKey = dotenv.env["SHORT_URL_PRIVATE_KEY"];

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
  }

  void _initializeControllers() {
    _originalURLController = TextEditingController();
    _nameURLController = TextEditingController();
    _expiredURLController = TextEditingController();
    _passwordController = TextEditingController();
    _customerTextController = TextEditingController();
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  /// Set expiry time
  void setExpiryTime(DateTime dateTime) {
    expiryTime.value = dateTime.millisecondsSinceEpoch;
  }

  /// Toggle cloaking
  void toggleCloaking(bool value) {
    cloaking.value = value;
  }

  /// Clear all form fields
  void clearForm() {
    if (!_isDisposed) {
      _originalURLController?.clear();
      _nameURLController?.clear();
      _expiredURLController?.clear();
      _passwordController?.clear();
      _customerTextController?.clear();
    }
    expiryTime.value = 0;
    cloaking.value = false;
    response.value = '';
  }

  /// Validate form
  bool validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    // Custom validation for expiry URL when expiry time is set
    if (expiryTime.value != 0 &&
        (_expiredURLController?.text.trim() ?? '').isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter an expiry redirect URL when expiry date is set',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
      return false;
    }

    if (selectedLinkId == null) {
      Get.snackbar(
        'Error',
        'Link ID not found',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
      return false;
    }

    if (apiKey == null) {
      Get.snackbar(
        'Error',
        'API key not found',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
      return false;
    }

    return true;
  }

  /// Check if expiry redirect URL is required
  bool get isExpiryUrlRequired => expiryTime.value != 0;

  /// Submit form to Short.io API
  Future<void> submitForm() async {
    if (!validateForm()) return;

    try {
      isLoading.value = true;

      final url = "https://api.short.io/links/$selectedLinkId";

      final payload = {
        "originalURL": _originalURLController?.text ?? '',
        "title": _nameURLController?.text ?? '',
        "customerText": (_customerTextController?.text ?? '').isEmpty
            ? null
            : _customerTextController?.text,
        "password": (_passwordController?.text ?? '').isEmpty
            ? null
            : _passwordController?.text,
        "cloaking": cloaking.value,
        "expiredURL": (_expiredURLController?.text ?? '').isEmpty
            ? null
            : _expiredURLController?.text,
        "expiresAt": expiryTime.value == 0 ? null : expiryTime.value,
      };

      final headers = {
        "accept": "application/json",
        "content-type": "application/json",
        "Authorization": apiKey!,
      };

      final httpResponse = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(payload),
      );

      response.value = httpResponse.body;

      if (httpResponse.statusCode == 200) {
        Get.snackbar(
          'Success',
          'QR Code created successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primaryContainer,
        );

        // Optionally clear form after success
        // clearForm();
      } else {
        Get.snackbar(
          'Error',
          'Failed to create QR Code: ${httpResponse.statusCode}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
        );
      }
    } catch (e) {
      response.value = 'Error: $e';
      Get.snackbar(
        'Network Error',
        'Failed to connect to server: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Set API configuration
  void setApiConfig({required String linkId, required String key}) {
    selectedLinkId = linkId;
    apiKey = key;
  }

  @override
  void onClose() {
    // Mark as disposed first
    _isDisposed = true;

    // Dispose controllers safely
    _originalURLController?.dispose();
    _nameURLController?.dispose();
    _expiredURLController?.dispose();
    _passwordController?.dispose();
    _customerTextController?.dispose();

    // Set to null to prevent access after disposal
    _originalURLController = null;
    _nameURLController = null;
    _expiredURLController = null;
    _passwordController = null;
    _customerTextController = null;

    super.onClose();
  }
}
