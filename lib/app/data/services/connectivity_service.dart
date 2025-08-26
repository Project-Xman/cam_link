import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import '../models/enums.dart';
import '../../core/errors/app_exception.dart';

/// Service for monitoring network connectivity
class ConnectivityService extends GetxService {
  static ConnectivityService get to => Get.find();
  
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  
  final _connectionStatus = ConnectionStatus.unknown.obs;
  final _isConnected = false.obs;

  /// Current connection status
  ConnectionStatus get connectionStatus => _connectionStatus.value;
  
  /// Whether device is connected to internet
  bool get isConnected => _isConnected.value;
  
  /// Stream of connection status changes
  Stream<ConnectionStatus> get connectionStream => _connectionStatus.stream;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initConnectivity();
    _startListening();
  }

  @override
  void onClose() {
    _connectivitySubscription.cancel();
    super.onClose();
  }

  /// Initialize connectivity status
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      _connectionStatus.value = ConnectionStatus.unknown;
      _isConnected.value = false;
    }
  }

  /// Start listening to connectivity changes
  void _startListening() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
      onError: (error) {
        _connectionStatus.value = ConnectionStatus.unknown;
        _isConnected.value = false;
      },
    );
  }

  /// Update connection status based on connectivity results
  void _updateConnectionStatus(ConnectivityResult result) {
    final hasConnection = result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn;

    _isConnected.value = hasConnection;
    _connectionStatus.value = hasConnection 
        ? ConnectionStatus.connected 
        : ConnectionStatus.disconnected;
  }

  /// Check if device has internet connectivity
  Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn;
    } catch (e) {
      return false;
    }
  }

  /// Ensure internet connection is available
  Future<void> ensureConnection() async {
    if (!await hasInternetConnection()) {
      throw NetworkException.noConnection();
    }
  }

  /// Get detailed connection type
  Future<String> getConnectionType() async {
    try {
      final result = await _connectivity.checkConnectivity();
      switch (result) {
        case ConnectivityResult.wifi:
          return 'WiFi';
        case ConnectivityResult.mobile:
          return 'Mobile';
        case ConnectivityResult.ethernet:
          return 'Ethernet';
        case ConnectivityResult.vpn:
          return 'VPN';
        case ConnectivityResult.none:
          return 'None';
        default:
          return 'Unknown';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Wait for connection to be available
  Future<void> waitForConnection({Duration? timeout}) async {
    if (isConnected) return;

    final completer = Completer<void>();
    late StreamSubscription subscription;

    subscription = connectionStream.listen((status) {
      if (status == ConnectionStatus.connected) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    if (timeout != null) {
      Timer(timeout, () {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.completeError(NetworkException.timeout());
        }
      });
    }

    return completer.future;
  }

  /// Execute a function with network requirement
  Future<T> executeWithConnection<T>(
    Future<T> Function() operation, {
    Duration? timeout,
  }) async {
    await ensureConnection();
    
    if (timeout != null) {
      return operation().timeout(timeout).catchError((error) {
        if (error is TimeoutException) {
          throw NetworkException.timeout();
        }
        throw error;
      });
    }
    
    return operation();
  }
}