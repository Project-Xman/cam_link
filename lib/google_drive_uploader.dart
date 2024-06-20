import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:googleapis/drive/v3.dart' as ga;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:path/path.dart' as path;
import 'package:photo_uploader/enums.dart';
import 'package:photo_uploader/oauth_service.dart';

class GoogleDriveService {
  final GoogleSignInService _oauthService = GoogleSignInService();

  Future<void> loginWithGoogle() => _oauthService.signInWithGoogle();
  Future<void> logoutFromGoogle() => _oauthService.signOut();
  Future<bool> isSignedIn() => _oauthService.isSignedIn();

  Future<double> getDriveSize() async {
    String? accessToken = await _oauthService.getAccessToken();
    if (accessToken == null) {
      log('No access token. User not authenticated.');
      return 0.0;
    }

    var client = GoogleHttpClient({'Authorization': 'Bearer $accessToken'});
    var drive = ga.DriveApi(client);

    var about = await drive.about.get($fields: 'storageQuota');
    double driveSizeGB = int.parse(about.storageQuota!.usageInDrive!) / 1e9;
    return driveSizeGB;
  }

  Future<bool> createFolder(String folderName) async {
    String? accessToken = await _oauthService.getAccessToken();
    if (accessToken == null) {
      log('No access token. User not authenticated.');
      return false;
    }

    var client = GoogleHttpClient({'Authorization': 'Bearer $accessToken'});
    var drive = ga.DriveApi(client);

    const parentFolderId = '1tlOsLjC-zr7i4JOXgUUzhEEUa4Pn9lQj';

    String? folderId =
        await _getOrCreateFolderId(drive, folderName, parentFolderId);
    return folderId != null ? true : false;
  }

  Future<String?> _getOrCreateFolderId(
      ga.DriveApi drive, String folderName, String parentFolderId) async {
    if (parentFolderId.isEmpty) {
      parentFolderId = 'root';
    }
    try {
      var folderList = await drive.files.list(
          q: "name='$folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false and '$parentFolderId' in parents");
      if (folderList.files != null && folderList.files!.isNotEmpty) {
        return folderList.files!.first.id;
      }

      var folder = ga.File()
        ..name = folderName
        ..parents = [parentFolderId]
        ..mimeType = 'application/vnd.google-apps.folder';

      var folderCreation = await drive.files.create(folder);

      // Make the folder publicly accessible
      var permission = ga.Permission()
        ..role = 'reader'
        ..type = 'anyone';

      await drive.permissions.create(permission, folderCreation.id!);

      return folderCreation.id;
    } catch (e) {
      log('Error creating folder: $e');
      return null;
    }
  }

  Future<UploadStatus> uploadFileToGoogleDrive(
      String folderName, File file, Function(double) onUploadProgress) async {
    String? accessToken = await _oauthService.getAccessToken();
    if (accessToken == null) {
      log('No access token. User not authenticated.');
      return UploadStatus.uploadFailed;
    }

    var client = GoogleHttpClient({'Authorization': 'Bearer $accessToken'});
    var drive = ga.DriveApi(client);

    const parentFolderId = '1tlOsLjC-zr7i4JOXgUUzhEEUa4Pn9lQj';

    String? folderId =
        await _getOrCreateFolderId(drive, folderName, parentFolderId);

    if (folderId != null) {
      var fileToUpload = ga.File()
        ..parents = [folderId]
        ..name = path.basename(file.path);

      var response = await drive.files.create(
        fileToUpload,
        uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
        uploadOptions: ga.ResumableUploadOptions(),
      );

      // Create a separate isolate for the upload
      final receivePort = ReceivePort();
      await Isolate.spawn(_uploadFile, {
        'sendPort': receivePort.sendPort,
        'filePath': file.path,
        'fileId': response.id!,
        'accessToken': accessToken,
      });

      // Listen for upload progress
      receivePort.listen((message) {
        if (message is double) {
          onUploadProgress(message);
        } else if (message == 'done') {
          receivePort.close();
        }
      });

      return UploadStatus.uploadSuccess;
    } else {
      log('Failed to create or find folder.');
      return UploadStatus.uploadFailed;
    }
  }

  Future<UploadStatus> uploadBytesToGoogleDrive(
      String folderName,
      Uint8List bytes,
      String fileName,
      Function(double) onUploadProgress) async {
    String? accessToken = await _oauthService.getAccessToken();
    if (accessToken == null) {
      log('No access token. User not authenticated.');
      return UploadStatus.uploadFailed;
    }

    var client = GoogleHttpClient({'Authorization': 'Bearer $accessToken'});
    var drive = ga.DriveApi(client);

    const parentFolderId = '1tlOsLjC-zr7i4JOXgUUzhEEUa4Pn9lQj';

    String? folderId =
        await _getOrCreateFolderId(drive, folderName, parentFolderId);

    if (folderId != null) {
      var fileToUpload = ga.File()
        ..parents = [folderId]
        ..name = fileName;

      var response = await drive.files.create(
        fileToUpload,
        uploadMedia: ga.Media(Stream.value(bytes), bytes.length),
        uploadOptions: ga.ResumableUploadOptions(),
      );

      // Create a separate isolate for the upload
      final receivePort = ReceivePort();
      await Isolate.spawn(_uploadBytes, {
        'sendPort': receivePort.sendPort,
        'bytes': bytes,
        'fileId': response.id!,
        'accessToken': accessToken,
      });

      // Listen for upload progress
      receivePort.listen((message) {
        if (message is double) {
          onUploadProgress(message);
        } else if (message == 'done') {
          receivePort.close();
        }
      });

      return UploadStatus.uploadSuccess;
    } else {
      log('Failed to create or find folder.');
      return UploadStatus.uploadFailed;
    }
  }

  static void _uploadFile(Map<String, dynamic> params) async {
    final sendPort = params['sendPort'] as SendPort;
    final filePath = params['filePath'] as String;
    final accessToken = params['accessToken'] as String;

    var client = GoogleHttpClient({'Authorization': 'Bearer $accessToken'});
    var drive = ga.DriveApi(client);

    final file = File(filePath);
    final fileSize = file.lengthSync();
    const chunkSize = 1024 * 1024; // 1MB

    final uploadSession = await drive.files.create(
      ga.File(),
      uploadMedia: ga.Media(file.openRead(), fileSize),
      uploadOptions: ga.ResumableUploadOptions(),
    );

    int start = 0;
    while (start < fileSize) {
      final end =
          (start + chunkSize) > fileSize ? fileSize : (start + chunkSize);
      final chunk = file.openRead(start, end);

      await drive.files.update(
        ga.File(),
        uploadSession.id!,
        uploadMedia: ga.Media(chunk, end - start),
        uploadOptions: ga.ResumableUploadOptions(),
      );

      start += chunkSize;
      sendPort.send(start / fileSize);
    }

    sendPort.send('done');
  }

  static void _uploadBytes(Map<String, dynamic> params) async {
    final sendPort = params['sendPort'] as SendPort;
    final bytes = params['bytes'] as Uint8List;
    final accessToken = params['accessToken'] as String;

    var client = GoogleHttpClient({'Authorization': 'Bearer $accessToken'});
    var drive = ga.DriveApi(client);

    final fileSize = bytes.length;
    const chunkSize = 1024 * 1024; // 1MB

    final uploadSession = await drive.files.create(
      ga.File(),
      uploadMedia: ga.Media(Stream.value(bytes), fileSize),
      uploadOptions: ga.ResumableUploadOptions(),
    );

    int start = 0;
    while (start < fileSize) {
      final end =
          (start + chunkSize) > fileSize ? fileSize : (start + chunkSize);
      final chunk = bytes.sublist(start, end);

      await drive.files.update(
        ga.File(),
        uploadSession.id!,
        uploadMedia: ga.Media(Stream.value(chunk), end - start),
        uploadOptions: ga.ResumableUploadOptions(),
      );

      start += chunkSize;
      sendPort.send(start / fileSize);
    }

    sendPort.send('done');
  }
}

class GoogleHttpClient extends IOClient {
  final Map<String, String> _headers;

  GoogleHttpClient(this._headers) : super();

  @override
  Future<IOStreamedResponse> send(http.BaseRequest request) =>
      super.send(request..headers.addAll(_headers));

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) =>
      super.head(url, headers: headers!..addAll(_headers));
}
