import 'dart:typed_data';

/// Model for selected images in the image processing module
class SelectedImage {
  final String name;
  final Uint8List bytes;
  final int size;
  final DateTime selectedAt;

  SelectedImage({
    required this.name,
    required this.bytes,
    required this.size,
    DateTime? selectedAt,
  }) : selectedAt = selectedAt ?? DateTime.now();

  /// Get formatted file size
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get file extension from name
  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Check if image is valid format
  bool get isValidImage {
    const validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return validExtensions.contains(extension);
  }

  @override
  String toString() {
    return 'SelectedImage(name: $name, size: $formattedSize)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SelectedImage && other.name == name && other.size == size;
  }

  @override
  int get hashCode => name.hashCode ^ size.hashCode;
}