import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../data/services/ftp_server_service.dart';
import '../../core/values/app_values.dart';

class FtpCard extends StatelessWidget {
  const FtpCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ftpService = FtpServerService.to;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_shared,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: AppValues.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Camera FTP Server',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Obx(() => Text(
                            ftpService.isServerRunning
                                ? 'Running on ${ftpService.serverIp}:${ftpService.serverPort}'
                                : 'Stopped',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: ftpService.isServerRunning
                                      ? Colors.green
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          )),
                    ],
                  ),
                ),
                Obx(() => Switch(
                      value: ftpService.isServerRunning,
                      onChanged: (_) => ftpService.toggleServer(),
                    )),
              ],
            ),
            const SizedBox(height: AppValues.paddingMedium),
            Obx(() {
              if (ftpService.isServerRunning) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppValues.paddingMedium),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connection Details',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppValues.paddingSmall),
                          _buildDetailRow(
                            context,
                            'Host',
                            ftpService.serverIp,
                            onTap: () => _copyToClipboard(
                              ftpService.serverIp,
                              'Host IP copied',
                            ),
                          ),
                          _buildDetailRow(
                            context,
                            'Port',
                            ftpService.serverPort.toString(),
                            onTap: () => _copyToClipboard(
                              ftpService.serverPort.toString(),
                              'Port copied',
                            ),
                          ),
                          _buildDetailRow(
                            context,
                            'Username',
                            ftpService.username,
                            onTap: () => _copyToClipboard(
                              ftpService.username,
                              'Username copied',
                            ),
                          ),
                          _buildDetailRow(
                            context,
                            'Password',
                            ftpService.password,
                            onTap: () => _copyToClipboard(
                              ftpService.password,
                              'Password copied',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppValues.paddingMedium),
                    Container(
                      padding: const EdgeInsets.all(AppValues.paddingMedium),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auto Processing',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppValues.paddingSmall),
                          Row(
                            children: [
                              Icon(
                                ftpService.autoProcessPhotos
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 16,
                                color: ftpService.autoProcessPhotos
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Copy to Phone: ${ftpService.autoProcessPhotos ? "ON" : "OFF"}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                ftpService.autoUploadToGDrive
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 16,
                                color: ftpService.autoUploadToGDrive
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Auto Google Drive: ${ftpService.autoUploadToGDrive ? "ON" : "OFF"}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppValues.paddingMedium),
                  ],
                );
              } else {
                return Container(
                  padding: const EdgeInsets.all(AppValues.paddingMedium),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppValues.paddingSmall),
                      Expanded(
                        child: Text(
                          'Start the server to receive photos from your camera via FTP',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              }
            }),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showConfigurationDialog(context),
                    icon: const Icon(Icons.settings),
                    label: const Text('Configure'),
                  ),
                ),
                const SizedBox(width: AppValues.paddingMedium),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showConnectionDetails(context),
                    icon: const Icon(Icons.info),
                    label: const Text('Details'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppValues.paddingSmall),
            SizedBox(
              width: double.infinity,
              child: Obx(() => FilledButton.icon(
                    onPressed: () => ftpService.toggleServer(),
                    icon: Icon(
                      ftpService.isServerRunning ? Icons.stop : Icons.play_arrow,
                    ),
                    label: Text(
                      ftpService.isServerRunning ? 'Stop Server' : 'Start Server',
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.copy,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _showConfigurationDialog(BuildContext context) {
    final ftpService = FtpServerService.to;
    final portController = TextEditingController(text: ftpService.serverPort.toString());
    final usernameController = TextEditingController(text: ftpService.username);
    final passwordController = TextEditingController(text: ftpService.password);
    final autoProcess = ftpService.autoProcessPhotos.obs;
    final autoGDrive = ftpService.autoUploadToGDrive.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('FTP Server Configuration'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: 'Enter port number (e.g., 2121)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppValues.paddingMedium),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter FTP username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppValues.paddingMedium),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter FTP password (min 6 characters)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: AppValues.paddingMedium),
              Obx(() => SwitchListTile(
                    title: const Text('Auto Copy to Phone'),
                    subtitle: const Text('Automatically copy received photos to phone storage'),
                    value: autoProcess.value,
                    onChanged: (value) => autoProcess.value = value,
                  )),
              Obx(() => SwitchListTile(
                    title: const Text('Auto Upload to Google Drive'),
                    subtitle: const Text('Automatically upload received photos to Google Drive'),
                    value: autoGDrive.value,
                    onChanged: (value) => autoGDrive.value = value,
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final port = int.tryParse(portController.text.trim()) ?? 2121;
              final username = usernameController.text.trim();
              final password = passwordController.text.trim();
              
              if (username.isNotEmpty && password.length >= 6) {
                ftpService.updateConfiguration(
                  port: port,
                  username: username,
                  password: password,
                  autoProcess: autoProcess.value,
                  autoGDrive: autoGDrive.value,
                );
                Get.back();
              } else {
                Get.snackbar(
                  'Invalid Input',
                  'Username cannot be empty and password must be at least 6 characters',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showConnectionDetails(BuildContext context) {
    final ftpService = FtpServerService.to;
    
    Get.dialog(
      AlertDialog(
        title: const Text('FTP Connection Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Camera FTP Setup Instructions:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppValues.paddingMedium),
              Text(
                '1. Connect your camera to the same WiFi network as this phone\n'
                '2. Configure your camera\'s FTP settings with:\n'
                '   • Host: ${ftpService.serverIp}\n'
                '   • Port: ${ftpService.serverPort}\n'
                '   • Username: ${ftpService.username}\n'
                '   • Password: ${ftpService.password}\n'
                '3. Set upload path to "/" (root)\n'
                '4. Enable FTP upload on your camera\n\n'
                'Alternative HTTP Upload:\n'
                'POST to: http://${ftpService.serverIp}:${ftpService.serverPort}/upload\n'
                'With Basic Auth credentials above',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppValues.paddingMedium),
              Container(
                padding: const EdgeInsets.all(AppValues.paddingMedium),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: AppValues.paddingSmall),
                    Expanded(
                      child: Text(
                        'Make sure both devices are on the same network for FTP to work',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _copyToClipboard(
              ftpService.getConnectionDetails(),
              'Connection details copied',
            ),
            child: const Text('Copy Details'),
          ),
          FilledButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}