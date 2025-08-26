import 'package:equatable/equatable.dart';
import 'enums.dart';

/// Model representing a file being processed
class FileModel extends Equatable {
  final String path;
  final String name;
  final String extension;
  final int sizeInBytes;
  final DateTime? lastModified;
  final ProcessStatus processStatus;
  final UploadStatus uploadStatus;
  final double uploadProgress;
  final String? errorMessage;
  final DateTime? processedAt;
  final DateTime? uploadedAt;

  const FileModel({
    required this.path,
    required this.name,
    required this.extension,
    required this.sizeInBytes,
    this.lastModified,
    this.processStatus = ProcessStatus.notStarted,
    this.uploadStatus = UploadStatus.notSynced,
    this.uploadProgress = 0.0,
    this.errorMessage,
    this.processedAt,
    this.uploadedAt,
  });

  /// Create FileModel from file path
  factory FileModel.fromPath(String filePath) {
    final fileName = filePath.split('/').last;
    final parts = fileName.split('.');
    final name = parts.length > 1 ? parts.sublist(0, parts.length - 1).join('.') : fileName;
    final extension = parts.length > 1 ? '.${parts.last}' : '';

    return FileModel(
      path: filePath,
      name: name,
      extension: extension,
      sizeInBytes: 0, // Will be set when file is read
    );
  }

  /// Get file size in human-readable format
  String get formattedSize {
    if (sizeInBytes < 1024) return '${sizeInBytes}B';
    if (sizeInBytes < 1024 * 1024) return '${(sizeInBytes / 1024).toStringAsFixed(1)}KB';
    if (sizeInBytes < 1024 * 1024 * 1024) return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Check if file is an image
  bool get isImage {
    const imageExtensions = ['.jpg', '.jpeg', '.png', '.bmp', '.gif', '.webp'];
    return imageExtensions.contains(extension.toLowerCase());
  }

  /// Check if file is supported for processing
  bool get isSupported {
    const supportedExtensions = ['.jpg', '.jpeg', '.png', '.bmp'];
    return supportedExtensions.contains(extension.toLowerCase());
  }

  /// Get current status display
  String get statusDisplay {
    if (processStatus.hasError || uploadStatus.hasError) {
      return errorMessage ?? 'Error occurred';
    }
    if (uploadStatus.isInProgress) {
      return '${uploadStatus.displayName} (${(uploadProgress * 100).toInt()}%)';
    }
    if (uploadStatus.isCompleted) {
      return uploadStatus.displayName;
    }
    return processStatus.displayName;
  }

  /// Copy with updated fields
  FileModel copyWith({
    String? path,
    String? name,
    String? extension,
    int? sizeInBytes,
    DateTime? lastModified,
    ProcessStatus? processStatus,
    UploadStatus? uploadStatus,
    double? uploadProgress,
    String? errorMessage,
    DateTime? processedAt,
    DateTime? uploadedAt,
  }) {
    return FileModel(
      path: path ?? this.path,
      name: name ?? this.name,
      extension: extension ?? this.extension,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      lastModified: lastModified ?? this.lastModified,
      processStatus: processStatus ?? this.processStatus,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
      processedAt: processedAt ?? this.processedAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'extension': extension,
      'sizeInBytes': sizeInBytes,
      'lastModified': lastModified?.millisecondsSinceEpoch,
      'processStatus': processStatus.name,
      'uploadStatus': uploadStatus.name,
      'uploadProgress': uploadProgress,
      'errorMessage': errorMessage,
      'processedAt': processedAt?.millisecondsSinceEpoch,
      'uploadedAt': uploadedAt?.millisecondsSinceEpoch,
    };
  }

  /// Create from JSON
  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      path: json['path'] as String,
      name: json['name'] as String,
      extension: json['extension'] as String,
      sizeInBytes: json['sizeInBytes'] as int,
      lastModified: json['lastModified'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['lastModified'] as int)
          : null,
      processStatus: ProcessStatus.values.firstWhere(
        (e) => e.name == json['processStatus'],
        orElse: () => ProcessStatus.notStarted,
      ),
      uploadStatus: UploadStatus.values.firstWhere(
        (e) => e.name == json['uploadStatus'],
        orElse: () => UploadStatus.notSynced,
      ),
      uploadProgress: (json['uploadProgress'] as num?)?.toDouble() ?? 0.0,
      errorMessage: json['errorMessage'] as String?,
      processedAt: json['processedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['processedAt'] as int)
          : null,
      uploadedAt: json['uploadedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['uploadedAt'] as int)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        path,
        name,
        extension,
        sizeInBytes,
        lastModified,
        processStatus,
        uploadStatus,
        uploadProgress,
        errorMessage,
        processedAt,
        uploadedAt,
      ];

  @override
  String toString() {
    return 'FileModel(path: $path, name: $name, processStatus: $processStatus, uploadStatus: $uploadStatus)';
  }
}