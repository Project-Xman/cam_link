/// Processing status for images
enum ProcessStatus {
  notStarted('Not Started'),
  processing('Processing'),
  processed('Processed'),
  failed('Failed');

  const ProcessStatus(this.displayName);
  final String displayName;

  bool get isCompleted => this == processed;
  bool get isInProgress => this == processing;
  bool get hasError => this == failed;
}

/// Upload status for processed images
enum UploadStatus {
  notSynced('Not Synced'),
  uploading('Uploading'),
  uploadSuccess('Upload Success'),
  uploadFailed('Upload Failed'),
  cancelled('Cancelled');

  const UploadStatus(this.displayName);
  final String displayName;

  bool get isCompleted => this == uploadSuccess;
  bool get isInProgress => this == uploading;
  bool get hasError => this == uploadFailed;
}

/// Authentication status
enum AuthStatus {
  unknown('Unknown'),
  signedOut('Signed Out'),
  signingIn('Signing In'),
  signedIn('Signed In'),
  error('Error');

  const AuthStatus(this.displayName);
  final String displayName;

  bool get isSignedIn => this == signedIn;
  bool get isInProgress => this == signingIn;
}

/// Network connection status
enum ConnectionStatus {
  unknown('Unknown'),
  connected('Connected'),
  disconnected('Disconnected');

  const ConnectionStatus(this.displayName);
  final String displayName;

  bool get isConnected => this == connected;
}

/// File watching status
enum WatchStatus {
  stopped('Stopped'),
  starting('Starting'),
  watching('Watching'),
  error('Error');

  const WatchStatus(this.displayName);
  final String displayName;

  bool get isActive => this == watching;
  bool get isInProgress => this == starting;
}