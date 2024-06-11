import 'package:flutter/material.dart';

import 'enums.dart';

class FileStatusDisplay extends StatelessWidget {
  final ProcessStatus processStatus;
  final UploadStatus uploadStatus;

  const FileStatusDisplay({
    super.key,
    required this.processStatus,
    required this.uploadStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Process: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              _processStatusString(processStatus),
              style: TextStyle(
                color: processStatus == ProcessStatus.processed
                    ? Colors.green
                    : processStatus == ProcessStatus.processing
                        ? Colors.blue
                        : Colors.grey,
              ),
            ),
            if (processStatus == ProcessStatus.processing)
              const SizedBox(width: 5),
            if (processStatus == ProcessStatus.processing)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upload: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              _uploadStatusString(uploadStatus),
              style: TextStyle(
                color: uploadStatus == UploadStatus.uploadSuccess
                    ? Colors.green
                    : uploadStatus == UploadStatus.uploading
                        ? Colors.blue
                        : uploadStatus == UploadStatus.uploadFailed
                            ? Colors.red
                            : Colors.grey,
              ),
            ),
            if (uploadStatus == UploadStatus.uploading)
              const SizedBox(width: 5),
            if (uploadStatus == UploadStatus.uploading)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ],
    );
  }

  String _processStatusString(ProcessStatus status) {
    switch (status) {
      case ProcessStatus.notDone:
        return 'Not Done';
      case ProcessStatus.processing:
        return 'Processing';
      case ProcessStatus.processed:
        return 'Processed';
    }
  }

  String _uploadStatusString(UploadStatus status) {
    switch (status) {
      case UploadStatus.notSynced:
        return 'Not Synced';
      case UploadStatus.uploading:
        return 'Uploading';
      case UploadStatus.uploadSuccess:
        return 'Upload Success';
      case UploadStatus.uploadFailed:
        return 'Upload Failed';
    }
  }
}
