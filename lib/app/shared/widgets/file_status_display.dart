import 'package:flutter/material.dart';
import '../../data/models/enums.dart';

/// A modern Material 3 widget to display file processing and upload status
class FileStatusDisplay extends StatelessWidget {
  final ProcessStatus processStatus;
  final UploadStatus uploadStatus;
  final double? uploadProgress;
  final bool showProgress;

  const FileStatusDisplay({
    super.key,
    required this.processStatus,
    required this.uploadStatus,
    this.uploadProgress,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Process Status Row
            _buildStatusRow(
              context: context,
              label: 'Process',
              status: processStatus.displayName,
              color: _getProcessStatusColor(processStatus, colorScheme),
              isLoading: processStatus.isInProgress,
              icon: _getProcessStatusIcon(processStatus),
            ),
            
            const SizedBox(height: 8),
            
            // Upload Status Row
            _buildStatusRow(
              context: context,
              label: 'Upload',
              status: uploadStatus.displayName,
              color: _getUploadStatusColor(uploadStatus, colorScheme),
              isLoading: uploadStatus.isInProgress,
              icon: _getUploadStatusIcon(uploadStatus),
            ),
            
            // Upload Progress (if uploading and showProgress is true)
            if (uploadStatus.isInProgress && showProgress && uploadProgress != null) ...[
              const SizedBox(height: 8),
              _buildProgressIndicator(context, uploadProgress!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required BuildContext context,
    required String label,
    required String status,
    required Color color,
    required bool isLoading,
    required IconData icon,
  }) {
    final textTheme = Theme.of(context).textTheme;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status Icon
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        
        // Label
        Text(
          '$label: ',
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        // Status Text
        Text(
          status,
          style: textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        // Loading Indicator
        if (isLoading) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressIndicator(BuildContext context, double progress) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      ],
    );
  }

  Color _getProcessStatusColor(ProcessStatus status, ColorScheme colorScheme) {
    switch (status) {
      case ProcessStatus.processed:
        return colorScheme.primary;
      case ProcessStatus.processing:
        return colorScheme.secondary;
      case ProcessStatus.failed:
        return colorScheme.error;
      case ProcessStatus.notStarted:
        return colorScheme.onSurfaceVariant;
    }
  }

  Color _getUploadStatusColor(UploadStatus status, ColorScheme colorScheme) {
    switch (status) {
      case UploadStatus.uploadSuccess:
        return colorScheme.primary;
      case UploadStatus.uploading:
        return colorScheme.secondary;
      case UploadStatus.uploadFailed:
        return colorScheme.error;
      case UploadStatus.cancelled:
        return colorScheme.outline;
      case UploadStatus.notSynced:
        return colorScheme.onSurfaceVariant;
    }
  }

  IconData _getProcessStatusIcon(ProcessStatus status) {
    switch (status) {
      case ProcessStatus.processed:
        return Icons.check_circle_outline;
      case ProcessStatus.processing:
        return Icons.hourglass_empty;
      case ProcessStatus.failed:
        return Icons.error_outline;
      case ProcessStatus.notStarted:
        return Icons.radio_button_unchecked;
    }
  }

  IconData _getUploadStatusIcon(UploadStatus status) {
    switch (status) {
      case UploadStatus.uploadSuccess:
        return Icons.cloud_done_outlined;
      case UploadStatus.uploading:
        return Icons.cloud_upload_outlined;
      case UploadStatus.uploadFailed:
        return Icons.cloud_off_outlined;
      case UploadStatus.cancelled:
        return Icons.cancel_outlined;
      case UploadStatus.notSynced:
        return Icons.cloud_queue_outlined;
    }
  }
}

/// Compact version of file status display for lists
class CompactFileStatusDisplay extends StatelessWidget {
  final ProcessStatus processStatus;
  final UploadStatus uploadStatus;
  final double? uploadProgress;

  const CompactFileStatusDisplay({
    super.key,
    required this.processStatus,
    required this.uploadStatus,
    this.uploadProgress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Process Status Icon
        Icon(
          _getProcessStatusIcon(processStatus),
          size: 16,
          color: _getProcessStatusColor(processStatus, colorScheme),
        ),
        
        const SizedBox(width: 4),
        
        // Upload Status Icon
        Icon(
          _getUploadStatusIcon(uploadStatus),
          size: 16,
          color: _getUploadStatusColor(uploadStatus, colorScheme),
        ),
        
        // Progress indicator for uploading
        if (uploadStatus.isInProgress) ...[
          const SizedBox(width: 4),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: uploadProgress,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getUploadStatusColor(uploadStatus, colorScheme),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getProcessStatusColor(ProcessStatus status, ColorScheme colorScheme) {
    switch (status) {
      case ProcessStatus.processed:
        return colorScheme.primary;
      case ProcessStatus.processing:
        return colorScheme.secondary;
      case ProcessStatus.failed:
        return colorScheme.error;
      case ProcessStatus.notStarted:
        return colorScheme.onSurfaceVariant;
    }
  }

  Color _getUploadStatusColor(UploadStatus status, ColorScheme colorScheme) {
    switch (status) {
      case UploadStatus.uploadSuccess:
        return colorScheme.primary;
      case UploadStatus.uploading:
        return colorScheme.secondary;
      case UploadStatus.uploadFailed:
        return colorScheme.error;
      case UploadStatus.cancelled:
        return colorScheme.outline;
      case UploadStatus.notSynced:
        return colorScheme.onSurfaceVariant;
    }
  }

  IconData _getProcessStatusIcon(ProcessStatus status) {
    switch (status) {
      case ProcessStatus.processed:
        return Icons.check_circle;
      case ProcessStatus.processing:
        return Icons.hourglass_empty;
      case ProcessStatus.failed:
        return Icons.error;
      case ProcessStatus.notStarted:
        return Icons.radio_button_unchecked;
    }
  }

  IconData _getUploadStatusIcon(UploadStatus status) {
    switch (status) {
      case UploadStatus.uploadSuccess:
        return Icons.cloud_done;
      case UploadStatus.uploading:
        return Icons.cloud_upload;
      case UploadStatus.uploadFailed:
        return Icons.cloud_off;
      case UploadStatus.cancelled:
        return Icons.cancel;
      case UploadStatus.notSynced:
        return Icons.cloud_queue;
    }
  }
}