import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:get/get.dart';
import '../controllers/qr_code_controller.dart';

class QRCodeFormPage extends GetView<QRCodeController> {
  const QRCodeFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Generator'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            onPressed: controller.clearForm,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Form',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 16),
              
              // QR Code Redirect URL
              TextFormField(
                controller: controller.originalURLController,
                decoration: const InputDecoration(
                  labelText: 'QR Code Redirect URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a redirect URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // QR Code Name URL
              TextFormField(
                controller: controller.nameURLController,
                decoration: const InputDecoration(
                  labelText: 'QR Code Name URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              
              // NEW: QR Code Customer Text Field
              TextFormField(
                controller: controller.customerTextController,
                decoration: const InputDecoration(
                  labelText: 'QR Code Customer Text',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                  hintText: 'Enter custom text for the QR code',
                  helperText: 'Optional: Add personalized text to your QR code',
                ),
                maxLines: 2,
                maxLength: 100,
                validator: (value) {
                  if (value != null && value.length > 100) {
                    return 'Customer text must be less than 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Expiry Date Picker
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: TextButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.transparent),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  onPressed: () {
                    DatePicker.showDateTimePicker(
                      context,
                      showTitleActions: true,
                      minTime: DateTime.now(),
                      maxTime: DateTime(2030, 12, 31),
                      onConfirm: (date) {
                        controller.setExpiryTime(date);
                      },
                      currentTime: DateTime.now(),
                      locale: LocaleType.en,
                    );
                  },
                  child: Obx(() => Text(
                    controller.expiryTime.value == 0
                        ? 'Select Expiry Date'
                        : 'Expiry Date: ${DateTime.fromMillisecondsSinceEpoch(controller.expiryTime.value).toIso8601String()}',
                    style: const TextStyle(color: Color.fromARGB(255, 51, 116, 53)),
                  )),
                ),
              ),
              const SizedBox(height: 16),
              
              // QR Code Expiry Redirect URL
              TextFormField(
                controller: controller.expiredURLController,
                decoration: const InputDecoration(
                  labelText: 'QR Code Expiry Redirect URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timelapse),
                  helperText: 'Optional - only needed if expiry date is set',
                ),
                validator: (value) {
                  // Simple validation without reactive dependencies
                  return null; // We'll handle this validation in the controller
                },
              ),
              const SizedBox(height: 16),
              
              // Password Field
              Obx(() {
                return TextFormField(
                  controller: controller.passwordController,
                  decoration: InputDecoration(
                    labelText: 'QR Code Redirect URL Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.password),
                    suffixIcon: IconButton(
                      onPressed: controller.togglePasswordVisibility,
                      icon: Icon(
                        controller.showPassword.value 
                          ? Icons.visibility 
                          : Icons.visibility_off,
                      ),
                    ),
                  ),
                  obscureText: controller.showPassword.value,
                );
              }),
              const SizedBox(height: 16),
              
              // Cloaking Switch
              Obx(() {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'QR Code Redirect URL Cloaking',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Switch(
                      value: controller.cloaking.value,
                      onChanged: controller.toggleCloaking,
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
              
              // Submit Button
              Obx(() {
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: controller.isLoading.value ? null : controller.submitForm,
                    icon: controller.isLoading.value 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                    label: Text(
                      controller.isLoading.value 
                        ? 'Submitting...' 
                        : 'Submit The QR Code Details',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              
              // Response Text
              Obx(() {
                return controller.response.value.isNotEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'API Response:',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            controller.response.value,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }


}