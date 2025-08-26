import 'package:equatable/equatable.dart';

/// Model representing an authenticated user
class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? tokenExpiry;
  final Map<String, dynamic>? additionalData;
  final bool approved;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiry,
    this.additionalData,
    this.approved = false,
  });

  /// Check if user has valid authentication tokens
  bool get hasValidToken {
    if (accessToken == null) return false;
    if (tokenExpiry == null) return true; // Assume valid if no expiry
    return DateTime.now().isBefore(tokenExpiry!);
  }

  /// Get user's display name or email
  String get displayName => name.isNotEmpty ? name : email;

  /// Get user's initials for avatar
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first[0].toUpperCase();
    } else if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'U';
  }

  /// Copy with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiry,
    Map<String, dynamic>? additionalData,
    bool? approved,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
      additionalData: additionalData ?? this.additionalData,
      approved: approved ?? this.approved,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenExpiry': tokenExpiry?.millisecondsSinceEpoch,
      'additionalData': additionalData,
      'approved': approved,
    };
  }

  /// Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      tokenExpiry: json['tokenExpiry'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['tokenExpiry'] as int)
          : null,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
      approved: json['approved'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        photoUrl,
        accessToken,
        refreshToken,
        tokenExpiry,
        additionalData,
        approved,
      ];

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, approved: $approved)';
  }
}

/// Model for Google Drive storage information
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

  /// Get storage usage percentage
  double get usagePercentage => totalStorage > 0 ? usedStorage / totalStorage : 0.0;

  /// Check if storage is nearly full (>90%)
  bool get isNearlyFull => usagePercentage > 0.9;

  /// Check if storage is full (>95%)
  bool get isFull => usagePercentage > 0.95;

  @override
  List<Object?> get props => [
        totalStorage,
        usedStorage,
        availableStorage,
        formattedTotal,
        formattedUsed,
        formattedAvailable,
      ];
}