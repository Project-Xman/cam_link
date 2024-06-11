import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:photo_uploader/oauth_service.dart';
import 'package:watcher/watcher.dart';

import 'enums.dart';
import 'file_status_display.dart';
import 'global_state.dart';
import 'google_drive_uploader.dart';
import 'image_processor.dart';

class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({super.key});

  @override
  FileExplorerScreenState createState() => FileExplorerScreenState();
}

class FileExplorerScreenState extends State<FileExplorerScreen> {
  final ImageProcessor _imageProcessor = ImageProcessor();
  final GoogleDriveService googleDriveService = GoogleDriveService();
  final GoogleSignInService _oauthService = GoogleSignInService();

  final GlobalState controller = Get.find(tag: 'global');

  final Map<String, Map<String, dynamic>> _fileStatusMap = {};
  List<int> _logoDimensions = [0, 0];
  String _selectedPath = "";
  String _outputPath = "";
  List<String> _fileList = [];
  DirectoryWatcher? _directoryWatcher;
  bool _isWatching = false;
  int resolutionWidth = 1920;
  int resolutionHeight = 1080;
  bool saveOutputToDevice = false;
  String? _selectedOverlayImage = "";
  String? outputPath;
  bool signedIn = false;
  Map<String, dynamic>? currentUser;
  final TextEditingController _folderNameController = TextEditingController();
  double _driveSize = 0.0;
  bool status = false;
  bool show = false;

  final key = dotenv.env['SHORT_URL_PRIVATE_KEY'];
  List<dynamic> _links = [];
  String? _selectedLinkId;
  Map<String, dynamic> _linkDetails = {};

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _originalURLController = TextEditingController();
  final TextEditingController _nameURLController = TextEditingController();
  final TextEditingController _expiredURLController = TextEditingController();
  int _expiryTime = 0;
  final TextEditingController _passwordController = TextEditingController();
  bool _cloaking = false;
  String _response = '';

  @override
  void initState() {
    super.initState();
    _initStatus();
    _checkSignInStatus();
    _fetchLinks();
    if (!signedIn) {
      _handleSignIn().then((_) {
        setState(() {
          signedIn = true;
        });
        _getCurrentUser();
      });
    }
  }

  Future<void> _initStatus() async {
    status = await FlutterOverlayWindow.isPermissionGranted();
    if (!status) {
      await FlutterOverlayWindow.requestPermission();
    }
  }

  void _getCurrentUser() async {
    try {
      final user = await _oauthService.getCurrentUser();
      setState(() {
        currentUser = user;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Current user: ${user?['name']}')),
        );
      }
    } catch (e) {
      log('Error retrieving current user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _getDriveSize() async {
    try {
      final driveSize = await googleDriveService.getDriveSize();
      setState(() {
        _driveSize = driveSize;
      });
    } catch (e) {
      log('Error getting drive size: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  bool compareNumbersInRange(int number1main, int number2main,
      int number1comparevalue, int number2comparevalue, int rangeLimit) {
    if (rangeLimit < 200) {
      bool condition1 = (number1main - number1comparevalue).abs() <= rangeLimit;
      bool condition2 = (number2main - number2comparevalue).abs() <= rangeLimit;
      return condition1 && condition2;
    }
    return false;
  }

  Future<void> _pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      if (status) {
        if (await FlutterOverlayWindow.isActive()) {
          await FlutterOverlayWindow.closeOverlay();
        }

        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          overlayTitle: "Status Overlay",
          overlayContent:
              'Images Detected: ${controller.totalImages}\nImages Processed: ${controller.totalImagesProcessed}\nImages Uploaded: ${controller.totalImagesUploaded}',
          flag: OverlayFlag.defaultFlag,
          visibility: NotificationVisibility.visibilityPublic,
          height: 200,
          width: 450,
          startPosition: const OverlayPosition(0, -259),
        );
      }
      setState(() {
        _selectedPath = result;
        _fileList = _listFiles(_selectedPath).map((e) => e.path).toList();
        _startWatching();
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected folder: $_selectedPath')),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No folder selected')),
        );
      }
    }
  }

  Future<void> _pickOutputFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        _outputPath = result;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Output folder: $_outputPath')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No output folder selected')),
        );
      }
    }
  }

  Future<void> _pickOverlayImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    // Check file type is .png or not
    if (result != null) {
      if (result.files.single.path!.endsWith('.png')) {
        setState(() {
          _selectedOverlayImage = result.files.single.path!;
          _imageProcessor
              .getImageSize(_selectedOverlayImage)
              .then((dimensions) {
            setState(() {
              _logoDimensions = dimensions;
            });
          });
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Overlay image: $_selectedOverlayImage')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a .png file')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No overlay image selected')),
        );
      }
    }
  }

  Future<void> _processFile(String filePath) async {
    if (_folderNameController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cloud Folder not Created')),
        );
        return;
      }
    }
    setState(() {
      controller.incrementImagesDetected();
      _fileStatusMap[filePath] = {
        'processStatus': ProcessStatus.processing,
        'uploadStatus': UploadStatus.notSynced,
        'uploadProgress': 0.0,
      };
    });
    if (!saveOutputToDevice) {
      outputPath = null;
    } else {
      if (_outputPath.isEmpty) {
        AlertDialog(
          title: const Text('Output Path Not Selected'),
          content: const Text(
              'Please select an output path to save the processed images.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
        log('Output path not selected.');

        return;
      }
      outputPath = path.join(_outputPath, path.basename(filePath));
    }

    await _imageProcessor.processFile(
      filePath: filePath,
      logoPath: _selectedOverlayImage,
      outputPath: outputPath,
      resolutionHeight: resolutionHeight,
      resolutionWidth: resolutionWidth,
      saveOutputToDevice: saveOutputToDevice,
      onProcessed: (status, localOutputPath, imageBytes) async {
        setState(() {
          _fileStatusMap[filePath] = {
            'processStatus': status == 'Processed'
                ? ProcessStatus.processed
                : ProcessStatus.notDone,
            'uploadStatus': _fileStatusMap[filePath]?['uploadStatus'] ??
                UploadStatus.notSynced,
            'uploadProgress':
                _fileStatusMap[filePath]?['uploadProgress'] ?? 0.0,
          };
          _refreshFileList();
          if (status == 'Processed') {
            controller
                .incrementImagesProcessed(); // Increment the number of images processed
          }
        });

        if (status == 'Processed') {
          if (saveOutputToDevice) {
            log('Image processed and saved: $localOutputPath');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('Image processed and saved: $localOutputPath')),
              );
            }

            await _uploadFileToDrive(localOutputPath!, filePath);
          } else {
            log('Image processed, uploading directly...');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Image processed, uploading...')),
              );
            }
            await _uploadBytesToDrive(imageBytes!, filePath);
          }
        } else {
          log('Failed to process image: $filePath');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to process image: $filePath')),
            );
          }
        }
      },
    );
  }

  Future<void> _uploadBytesToDrive(
      Uint8List bytes, String originalFilePath) async {
    setState(() {
      _fileStatusMap[originalFilePath] = {
        'processStatus': _fileStatusMap[originalFilePath]?['processStatus'] ??
            ProcessStatus.notDone,
        'uploadStatus': UploadStatus.uploading,
        'uploadProgress': 0.0,
      };
    });
    final fileName = path.basename(originalFilePath);
    final uploadStatus = await googleDriveService.uploadBytesToGoogleDrive(
        _folderNameController.text, bytes, fileName, (progress) {
      setState(() {
        _fileStatusMap[originalFilePath]?['uploadProgress'] = progress;
      });
    });
    setState(() {
      _fileStatusMap[originalFilePath] = {
        'processStatus': _fileStatusMap[originalFilePath]?['processStatus'] ??
            ProcessStatus.notDone,
        'uploadStatus': uploadStatus == UploadStatus.uploadSuccess
            ? UploadStatus.uploadSuccess
            : UploadStatus.uploadFailed,
        'uploadProgress': 0.0,
      };
      if (uploadStatus == UploadStatus.uploadSuccess) {
        controller
            .incrementImagesUploaded(); // Increment the number of images uploaded
      }
    });
  }

  Future<void> _uploadFileToDrive(
      String filePath, String originalFilePath) async {
    setState(() {
      _fileStatusMap[originalFilePath] = {
        'processStatus': _fileStatusMap[originalFilePath]?['processStatus'] ??
            ProcessStatus.notDone,
        'uploadStatus': UploadStatus.uploading,
        'uploadProgress': 0.0,
      };
    });
    final uploadStatus = await googleDriveService.uploadFileToGoogleDrive(
        _folderNameController.text, File(filePath), (progress) {
      setState(() {
        _fileStatusMap[originalFilePath]?['uploadProgress'] = progress;
      });
    });
    setState(() {
      _fileStatusMap[originalFilePath] = {
        'processStatus': _fileStatusMap[originalFilePath]?['processStatus'] ??
            ProcessStatus.notDone,
        'uploadStatus': uploadStatus == UploadStatus.uploadSuccess
            ? UploadStatus.uploadSuccess
            : UploadStatus.uploadFailed,
        'uploadProgress': 0.0,
      };
      if (uploadStatus == UploadStatus.uploadSuccess) {
        controller
            .incrementImagesUploaded(); // Increment the number of images uploaded
      }
    });
  }

  Future<void> _startWatching() async {
    _stopWatching();
    _directoryWatcher = DirectoryWatcher(_selectedPath);
    _directoryWatcher!.events.listen((event) {
      log("Triggered");
      if (event.type == ChangeType.ADD || event.type == ChangeType.MODIFY) {
        log('File added or modified: $event');
        _fileStatusMap[event.path] = {
          'processStatus': ProcessStatus.notDone,
          'uploadStatus': UploadStatus.notSynced,
        };
        _refreshFileList();
        _processFile(event.path);
      }
      if (event.type == ChangeType.REMOVE) {
        setState(() {
          _fileStatusMap.remove(event.path);
          _refreshFileList();
        });
      }
    });
    _isWatching = true;
  }

  void _refreshFileList() {
    final filesAndDirs = _listFiles(_selectedPath);
    setState(() {
      _fileList = filesAndDirs.map((e) => e.path).toList();
    });
  }

  List<FileSystemEntity> _listFiles(String path) {
    if (path.isEmpty) return [];
    final directory = Directory(path);
    return directory.listSync();
  }

  void _stopWatching() {
    _directoryWatcher = null;
    _isWatching = false;
  }

  void _createFolder() async {
    if (_folderNameController.text.isEmpty) {
      AlertDialog(
        title: const Text('Output Path Not Selected'),
        content: const Text(
            'Please select an output path to save the processed images.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    }
    if (_folderNameController.text.isNotEmpty) {
      DateTime now = DateTime.now();
      String formattedDate =
          '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
      String folderName = '$formattedDate  ${_folderNameController.text}';
      bool success = await googleDriveService.createFolder(folderName);
      if (success) {
        setState(() {
          _folderNameController.text =
              '$formattedDate  ${_folderNameController.text}';
        });
      }
      final snackBar = SnackBar(
        content: Text(success
            ? 'Folder created: $folderName'
            : 'Failed to create folder: $folderName'),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> _checkSignInStatus() async {
    bool isSignedIn = await googleDriveService.isSignedIn();
    setState(() {
      signedIn = isSignedIn;
    });
  }

  Future<void> _handleSignIn() async {
    await googleDriveService.loginWithGoogle();
    await _checkSignInStatus();
  }

  Future<void> _handleSignOut() async {
    await googleDriveService.logoutFromGoogle();
    setState(() {
      signedIn = false;
      currentUser = null;
    });
  }

  Future<void> _fetchLinks() async {
    if (key == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Private key not found')),
        );
      }
      return;
    }
    const url =
        "https://api.short.io/api/links?domain_id=1120445&limit=30&dateSortOrder=desc";
    final headers = {"accept": "application/json", "Authorization": key!};

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      setState(() {
        _links = json.decode(response.body)['links'];
        log(_links.toString());
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch links')),
        );
      }
    }
  }

  Future<void> _fetchLinkDetails(String path) async {
    if (key == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Private key not found')),
        );
      }
      return;
    }
    final url =
        "https://api.short.io/links/expand?domain=fjma.short.gy&path=$path";
    final headers = {
      "accept": "application/json",
      "Authorization": key! // Replace with your actual API key
    };

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      setState(() {
        _linkDetails = json.decode(response.body);
        log(_linkDetails.toString());
        _populateFormFields();
      });
    } else {
      // Handle error
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLinkId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Link ID not found')),
          );
        }
        return;
      }

      final url = "https://api.short.io/links/{$_selectedLinkId}";

      if (key == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Private key not found')),
          );
        }
        return;
      }

      final payload = {
        "originalURL": _originalURLController.text,
        "title": _nameURLController.text,
        "password":
            _passwordController.text.isEmpty ? null : _passwordController.text,
        "cloaking": _cloaking,
        "expiredURL": _expiredURLController.text.isEmpty
            ? null
            : _expiredURLController.text,
        "expiresAt": _expiryTime == 0 ? null : _expiryTime,
      };
      final headers = {
        "accept": "application/json",
        "content-type": "application/json",
        "Authorization": key!
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(payload),
      );

      setState(() {
        _response = response.body;
      });
    }
  }

  void _populateFormFields() {
    _originalURLController.text = _linkDetails['originalURL'] ?? '';
    _nameURLController.text = _linkDetails['title'] ?? '';
    _expiryTime = _linkDetails['expiresAt']?.toInt() ?? 0;
    _expiredURLController.text = _linkDetails['expiredURL'] ?? '';
    _passwordController.text =
        _linkDetails['hasPassword'] ?? false ? '***' : '';
    _cloaking = _linkDetails['cloaking'] ?? false;
  }

  @override
  void dispose() {
    _stopWatching();
    _expiredURLController.dispose();
    _expiryTime = 0;
    _nameURLController.dispose();
    _originalURLController.dispose();
    _passwordController.dispose();
    _formKey.currentState?.dispose();
    _folderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Photo Booth',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFileList,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 1200) {
              // Desktop layout
              return _buildDesktopLayout();
            } else if (constraints.maxWidth > 600) {
              // Tablet layout
              return _buildTabletLayout();
            } else {
              // Mobile layout
              return _buildMobileLayout();
            }
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildFileExplorer(),
        ),
        const SizedBox(width: 8),
        SingleChildScrollView(
          child: Column(
            children: [
              _buildSettingsCard(),
              const SizedBox(height: 8),
              _buildStatusCard(),
              const SizedBox(height: 8),
              _buildURLSettingsCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildSettingsCard(isScroll: true)),
              const SizedBox(height: 8),
              Expanded(child: _buildURLSettingsCard(isScroll: true)),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildStatusCard()),
              const SizedBox(height: 8),
              Expanded(child: _buildFileExplorer()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSettingsCard(),
          const SizedBox(height: 8),
          _buildStatusCard(),
          const SizedBox(height: 8),
          _buildURLSettingsCard(),
          const SizedBox(height: 8),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: _buildFileExplorer(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({bool isScroll = false}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(minWidth: 300, maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            physics: isScroll
                ? const ScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Settings',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _folderNameController,
                decoration: const InputDecoration(
                  labelText: 'Google Drive Folder',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: signedIn ? _createFolder : null,
                icon: const Icon(Icons.create_new_folder),
                label: const Text('Create Folder'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Save Output to Device:'),
                  const SizedBox(width: 10),
                  Switch(
                    value: saveOutputToDevice,
                    onChanged: (value) {
                      if (!value) {
                        _outputPath = "";
                      }
                      setState(() {
                        saveOutputToDevice = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Output:'),
                  const SizedBox(width: 10),
                  DropdownMenu<int>(
                    leadingIcon: const Icon(Icons.output),
                    key: UniqueKey(),
                    label: const Text('Resolution'),
                    initialSelection: 1920,
                    onSelected: (value) {
                      setState(() {
                        resolutionWidth = value!;
                        resolutionHeight = (value * 9 / 16).round();
                      });
                    },
                    dropdownMenuEntries: const [
                      DropdownMenuEntry<int>(
                        value: 1920,
                        label: '1920x1080',
                      ),
                      DropdownMenuEntry<int>(
                        value: 1280,
                        label: '1280x720',
                      ),
                      DropdownMenuEntry<int>(
                        value: 640,
                        label: '640x360',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  createMaterial3Button(
                      context, Icons.image, 'Pick Overlay', _pickOverlayImage),
                  createMaterial3Button(
                      context, Icons.folder_open, 'Select Folder', _pickFolder),
                  createMaterial3Button(context, Icons.folder_open,
                      'Select Output Folder', _pickOutputFolder,
                      enabled: saveOutputToDevice),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(minWidth: 410, maxWidth: 500),
        child: SingleChildScrollView(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onDoubleTap: () async {
                        final status =
                            await FlutterOverlayWindow.isPermissionGranted();
                        if (!status) {
                          await FlutterOverlayWindow.requestPermission();
                        }
                        if (await FlutterOverlayWindow.isActive()) {
                          await FlutterOverlayWindow.closeOverlay();
                          return;
                        }
                        await FlutterOverlayWindow.showOverlay(
                          enableDrag: true,
                          overlayTitle: "Status Overlay",
                          overlayContent:
                              'Images Detected: ${controller.totalImages}\nImages Processed: ${controller.totalImagesProcessed}\nImages Uploaded: ${controller.totalImagesUploaded}',
                          flag: OverlayFlag.defaultFlag,
                          visibility: NotificationVisibility.visibilityPublic,
                          height: 200,
                          width: 450,
                          startPosition: const OverlayPosition(0, -259),
                        );
                      },
                      child: const Text('Status',
                          style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Overlay Image:',
                      style: TextStyle(
                          color: _selectedOverlayImage?.isNotEmpty == true
                              ? null
                              : Colors.orange),
                    ),
                    SizedBox(
                      width: 350,
                      child: Text(
                        _selectedOverlayImage?.isNotEmpty == true
                            ? _selectedOverlayImage!
                            : 'None',
                        style: const TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                        'Overlay Image Dimensions: ${_logoDimensions[1]}x${_logoDimensions[0]}',
                        style: TextStyle(
                            color: compareNumbersInRange(
                                    _logoDimensions[1],
                                    _logoDimensions[0],
                                    resolutionWidth,
                                    resolutionHeight,
                                    10)
                                ? null
                                : Colors.red)),
                    Text(
                        'Image Dimensions: $resolutionWidth x $resolutionHeight',
                        style: TextStyle(
                            color: compareNumbersInRange(
                                    _logoDimensions[1],
                                    _logoDimensions[0],
                                    resolutionWidth,
                                    resolutionHeight,
                                    10)
                                ? null
                                : Colors.red)),
                    Text(
                        'Google Drive Folder: ${_folderNameController.text.isNotEmpty ? _folderNameController.text : 'None'}',
                        style: TextStyle(
                            color: _folderNameController.text.isNotEmpty
                                ? null
                                : Colors.red)),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          currentUser == null
                              ? 'Not signed in'
                              : 'Signed in as ${currentUser?['name']}',
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          icon: currentUser == null
                              ? const Icon(Icons.login)
                              : const Icon(Icons.logout),
                          label: currentUser == null
                              ? const Text('Login')
                              : const Text('Logout'),
                          onPressed: currentUser == null
                              ? _handleSignIn
                              : _handleSignOut,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    signedIn
                        ? Wrap(
                            alignment: WrapAlignment.spaceEvenly,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text('Drive Usage:'),
                              ElevatedButton.icon(
                                onPressed: _getDriveSize,
                                icon: const Icon(Icons.cloud),
                                label: Text(_driveSize == 0.0
                                    ? 'Get Drive Size'
                                    : 'Drive Size: ${_driveSize.toStringAsFixed(2)} GB'),
                              ),
                            ],
                          )
                        : const SizedBox(),
                    const SizedBox(height: 20),
                    const Text(
                      'Selected Folder:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w300),
                    ),
                    Text(
                      _selectedPath.isNotEmpty ? _selectedPath : 'None',
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Output Folder:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w300),
                    ),
                    Text(
                      _outputPath.isNotEmpty ? _outputPath : 'None',
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 370,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          _buildImageCount(Icons.camera_alt,
                              controller.totalImages, Colors.lightBlue),
                          _buildImageCount(
                              Icons.image,
                              controller.totalImagesProcessed,
                              Colors.deepOrange),
                          _buildImageCount(
                              Icons.upload,
                              controller.totalImagesUploaded,
                              Colors.lightGreen),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileExplorer() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Files',
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                ],
              ),
            ),
            _isWatching
                ? SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entity = File(_fileList[index]);
                        final icon = Icon(
                          entity.statSync().type ==
                                  FileSystemEntityType.directory
                              ? Icons.folder
                              : Icons.insert_drive_file,
                          color: entity.statSync().type ==
                                  FileSystemEntityType.directory
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.primary,
                        );
                        final text = entity.path.split('/').last;
                        final status = _fileStatusMap[entity.path] ??
                            {
                              'processStatus': ProcessStatus.notDone,
                              'uploadStatus': UploadStatus.notSynced,
                              'uploadProgress': 0.0,
                            };

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: icon,
                              title: Text(text),
                              subtitle: status['uploadStatus'] ==
                                      UploadStatus.uploading
                                  ? LinearProgressIndicator(
                                      value: status['uploadProgress'],
                                      borderRadius: BorderRadius.circular(4),
                                    )
                                  : null,
                              trailing: FileStatusDisplay(
                                processStatus: status['processStatus'],
                                uploadStatus: status['uploadStatus'],
                              ),
                              onTap: () {
                                if (entity.statSync().type ==
                                    FileSystemEntityType.file) {
                                  _processFile(entity.path);
                                }
                              },
                            ),
                          ),
                        );
                      },
                      childCount: _fileList.length,
                    ),
                  )
                : SliverToBoxAdapter(
                    child: SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          'Select a folder to start monitoring.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildURLSettingsCard({bool isScroll = false}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(minWidth: 410, maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
              shrinkWrap: true,
              physics: isScroll
                  ? const ScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              children: [
                const Text("URL Settings",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.left),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Link',
                    border: OutlineInputBorder(),
                  ),
                  items: _links.map((link) {
                    return DropdownMenuItem<String>(
                      value: link['idString'],
                      child: Text(link['title']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLinkId = value;
                      final selectedLink = _links
                          .firstWhere((link) => link['idString'] == value);
                      _fetchLinkDetails(selectedLink['path']);
                    });
                  },
                  value: _selectedLinkId,
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _originalURLController,
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
                      TextFormField(
                        controller: _nameURLController,
                        decoration: const InputDecoration(
                          labelText: 'QR Code Name URL',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 2.0),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: TextButton(
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.all(Colors.transparent),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                            onPressed: () {
                              DatePicker.showDateTimePicker(context,
                                  showTitleActions: true,
                                  minTime: DateTime.now(),
                                  maxTime: DateTime(2019, 6, 7),
                                  onConfirm: (date) {
                                setState(() {
                                  _expiryTime = date.millisecondsSinceEpoch;
                                });
                              },
                                  currentTime: DateTime.now(),
                                  locale: LocaleType.en);
                            },
                            child: Text(
                              _expiryTime == 0
                                  ? 'Select Expiry Date'
                                  : 'Expiry Date: ${DateTime.fromMillisecondsSinceEpoch(_expiryTime).toIso8601String()}',
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 51, 116, 53)),
                            )),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _expiredURLController,
                        decoration: const InputDecoration(
                          labelText: 'QR Code Expiry Redirect URL',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timelapse),
                        ),
                        validator: (value) {
                          if (_expiryTime != 0) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an expiry redirect URL';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'QR Code Redirect URL Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.password),
                          suffix: GestureDetector(
                            onTap: () {
                              setState(() {
                                show = !show;
                              });
                            },
                            child: Icon(
                                show ? Icons.visibility : Icons.visibility_off),
                          ),
                        ),
                        obscureText: show,
                      ),
                      const SizedBox(height: 16),
                      Row(
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
                            value: _cloaking,
                            onChanged: (value) {
                              setState(() {
                                _cloaking = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      createMaterial3Button(
                        context,
                        Icons.save,
                        'Submit The QR Code Details',
                        _submitForm,
                      ),
                      const SizedBox(height: 16),
                      Text(_response),
                    ],
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  ElevatedButton createMaterial3Button(
    BuildContext context,
    IconData icon,
    String text,
    VoidCallback onPressed, {
    bool? enabled = true,
  }) {
    return ElevatedButton.icon(
      onPressed: enabled == false ? null : onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        foregroundColor: Theme.of(context).buttonTheme.colorScheme!.onPrimary,
        backgroundColor: Theme.of(context).buttonTheme.colorScheme!.primary,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildImageCount(IconData icon, int count, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 30.0,
          color: color,
        ),
        Text('$count', style: TextStyle(fontSize: 14.0, color: color)),
      ],
    );
  }
}
