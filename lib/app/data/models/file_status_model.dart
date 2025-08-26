import 'package:equatable/equatable.dart';
import 'enums.dart';

/// Model to track the status of individual files in the processing pipeline
class FileStatusModel extends Equatable {
  final String filePath;
  final ProcessStatus processStatus;
  final UploadStatus uploadStatus;
  final double uploadProgress;
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? uploadedAt;
  final String? errorMessage;

  FileStatusModel({
    required this.filePath,
    required this.processStatus,
    required this.uploadStatus,
    this.uploadProgress = 0.0,
    DateTime? createdAt,
    this.processedAt,
    this.uploadedAt,
    this.errorMessage,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a new instance with updated values
  FileStatusModel copyWith({
    String? filePath,
    ProcessStatus? processStatus,
    UploadStatus? uploadStatus,
    double? uploadProgress,
    DateTime? createdAt,
    DateTime? processedAt,
    DateTime? uploadedAt,
    String? errorMessage,
  }) {
    return FileStatusModel(
      filePath: filePath ?? this.filePath,
      processStatus: processStatus ?? this.processStatus,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Get file name from path
  String get fileName {
    return filePath.split('/').last;
  }

  /// Check if processing is complete
  bool get isProcessingComplete {
    return processStatus.isCompleted || processStatus.hasError;
  }

  /// Check if upload is complete
  bool get isUploadComplete {
    return uploadStatus.isCompleted || uploadStatus.hasError;
  }

  /// Check if both processing and upload are complete
  bool get isComplete {
    return isProcessingComplete && isUploadComplete;
  }

  /// Check if there are any errors
  bool get hasError {
    return processStatus.hasError || uploadStatus.hasError || errorMessage != null;
  }

  /// Get overall completion percentage (0.0 to 1.0)
  double get overallProgress {
    double processProgress = 0.0;
    double uploadProgress = 0.0;

    // Calculate process progress
    switch (processStatus) {
      case ProcessStatus.notStarted:
        processProgress = 0.0;
        break;
      case ProcessStatus.processing:
        processProgress = 0.5;
        break;
      case ProcessStatus.processed:
      case ProcessStatus.failed:
        processProgress = 1.0;
        break;
    }

    // Calculate upload progress
    switch (uploadStatus) {
      case UploadStatus.notSynced:
        uploadProgress = 0.0;
        break;
      case UploadStatus.uploading:
        uploadProgress = this.uploadProgress;
        break;
      case UploadStatus.uploadSuccess:
      case UploadStatus.uploadFailed:
      case UploadStatus.cancelled:
        uploadProgress = 1.0;
        break;
    }

    // Overall progress is average of processing and upload
    return (processProgress + uploadProgress) / 2.0;
  }

  /// Create instance from JSON
  factory FileStatusModel.fromJson(Map<String, dynamic> json) {
    return FileStatusModel(
      filePath: json['filePath'] as String,
      processStatus: ProcessStatus.values.firstWhere(
        (e) => e.name == json['processStatus'],
        orElse: () => ProcessStatus.notStarted,
      ),
      uploadStatus: UploadStatus.values.firstWhere(
        (e) => e.name == json['uploadStatus'],
        orElse: () => UploadStatus.notSynced,
      ),
      uploadProgress: (json['uploadProgress'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      processedAt: json['processedAt'] != null 
          ? DateTime.parse(json['processedAt'] as String)
          : null,
      uploadedAt: json['uploadedAt'] != null 
          ? DateTime.parse(json['uploadedAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'processStatus': processStatus.name,
      'uploadStatus': uploadStatus.name,
      'uploadProgress': uploadProgress,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'uploadedAt': uploadedAt?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  @override
  List<Object?> get props => [
        filePath,
        processStatus,
        uploadStatus,
        uploadProgress,
        createdAt,
        processedAt,
        uploadedAt,
        errorMessage,
      ];

  @override
  String toString() {
    return 'FileStatusModel{filePath: $filePath, processStatus: $processStatus, uploadStatus: $uploadStatus, uploadProgress: $uploadProgress}';
  }
}