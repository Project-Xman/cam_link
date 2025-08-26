import 'package:equatable/equatable.dart';

/// Model representing Google Drive storage information
class DriveStorageModel extends Equatable {
  final double totalStorage;
  final double usedStorage;
  final double availableStorage;
  final String formattedTotal;
  final String formattedUsed;
  final String formattedAvailable;

  const DriveStorageModel({
    required this.totalStorage,
    required this.usedStorage,
    required this.availableStorage,
    required this.formattedTotal,
    required this.formattedUsed,
    required this.formattedAvailable,
  });

  /// Get storage usage percentage (0.0 to 1.0)
  double get usagePercentage {
    if (totalStorage == 0) return 0.0;
    return usedStorage / totalStorage;
  }

  /// Check if storage is nearly full (>90%)
  bool get isNearlyFull => usagePercentage > 0.9;

  /// Check if storage is critically full (>95%)
  bool get isCriticallyFull => usagePercentage > 0.95;

  /// Create instance from JSON
  factory DriveStorageModel.fromJson(Map<String, dynamic> json) {
    return DriveStorageModel(
      totalStorage: (json['totalStorage'] as num).toDouble(),
      usedStorage: (json['usedStorage'] as num).toDouble(),
      availableStorage: (json['availableStorage'] as num).toDouble(),
      formattedTotal: json['formattedTotal'] as String,
      formattedUsed: json['formattedUsed'] as String,
      formattedAvailable: json['formattedAvailable'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalStorage': totalStorage,
      'usedStorage': usedStorage,
      'availableStorage': availableStorage,
      'formattedTotal': formattedTotal,
      'formattedUsed': formattedUsed,
      'formattedAvailable': formattedAvailable,
    };
  }

  @override
  List<Object?> get props => [
        totalStorage,
        usedStorage,
        availableStorage,
        formattedTotal,
        formattedUsed,
        formattedAvailable,
      ];

  @override
  String toString() {
    return 'DriveStorageModel{used: $formattedUsed, total: $formattedTotal, available: $formattedAvailable}';
  }
}