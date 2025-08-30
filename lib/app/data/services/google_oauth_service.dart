import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:googleapis/drive/v3.dart'; // No longer needed
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:photo_uploader/app/data/services/platform_diagnostics_service.dart';
import '../models/user_model.dart';
import '../models/enums.dart';
import '../../core/errors/app_exception.dart';
import '../../core/values/app_values.dart';

/// Authentication service using GetX patterns
class AuthService extends GetxService {
  // Track the last signed-in Google account
  GoogleSignInAccount? _lastGoogleAccount;
  static AuthService get to => Get.find();

  // Configuration
  String? _clientId;
  String? _clientSecret;
  // GoogleSignIn is now a singleton
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  late final FlutterSecureStorage _storage;
  final bool _isWindows = !kIsWeb && Platform.isWindows;
  final Logger _logger = Logger();

  // Flags to track initialization
  bool _isInitialized = false;
  bool _isInitializing = false;

  // Reactive variables
  final _authStatus = AuthStatus.unknown.obs;
  final _currentUser = Rxn<UserModel>();

  // Getters
  AuthStatus get authStatus => _authStatus.value;
  UserModel? get currentUser => _currentUser.value;
  bool get isSignedIn => _authStatus.value == AuthStatus.signedIn;
  bool get isSigningIn => _authStatus.value == AuthStatus.signingIn;

  // Streams
  Stream<AuthStatus> get authStatusStream => _authStatus.stream;
  Stream<UserModel?> get userStream => _currentUser.stream;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeService();
    // Set up authentication event stream immediately after initialization
    if (!_isWindows) {
      _googleSignIn.authenticationEvents.listen((event) async {
        try {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _lastGoogleAccount = event.user;
            try {
              await _loadCurrentUser(_lastGoogleAccount);
            } catch (e) {
              ErrorHandler.logWarning(
                  'Failed to load current user during sign-in event: $e',
                  'AuthService._checkSignInStatus');
              _authStatus.value = AuthStatus.signedOut;
            }
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            _lastGoogleAccount = null;
            _authStatus.value = AuthStatus.signedOut;
          }
        } catch (e) {
          ErrorHandler.handleError(e,
              context: 'AuthService._checkSignInStatus.authenticationEvents');
          _authStatus.value = AuthStatus.signedOut;
        }
      }, onError: (e) {
        ErrorHandler.logWarning('Authentication event stream error: $e',
            'AuthService._checkSignInStatus');
        _authStatus.value = AuthStatus.signedOut;
      });
    }
    await _checkSignInStatus();
  }

  /// Initialize the authentication service with better error handling
  Future<void> _initializeService() async {
    // Prevent double initialization
    if (_isInitialized || _isInitializing) {
      return;
    }

    _isInitializing = true;

    try {
      // Initialize client IDs
      if (_clientId == null) {
        // _clientId = dotenv.env['WEB_CLIENT_ID'];
        // _clientSecret = dotenv.env['WEB_CLIENT_SECRET'];
        _clientId =
            "424570474094-66fio54fct71j2ufjl0pqnfdqdp64i60.apps.googleusercontent.com";
        _clientSecret = "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";

        if (_clientId == null) {
          throw AuthException.signInFailed('Client ID not configured');
        }
      }

      // Initialize storage
      _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );

      // GoogleSignIn is now a singleton and must be initialized
      await _googleSignIn.initialize(
        clientId: Platform.isIOS ? _clientId : null,
        serverClientId: _clientId,
      );
      // Event stream is now set up in onInit immediately after initialize

      _isInitialized = true;
      ErrorHandler.logInfo(
          'AuthService initialized successfully for platform: ${Platform.operatingSystem}');
    } on PlatformException catch (e) {
      ErrorHandler.logError(
          'PlatformException during AuthService initialization',
          error: e,
          context: 'AuthService._initializeService');
      final diagnostics = PlatformDiagnosticsService.to;
      diagnostics.logPlatformChannelError('google_sign_in', e);
      _authStatus.value = AuthStatus.error;
      rethrow;
    } catch (e) {
      ErrorHandler.handleError(e, context: 'AuthService._initializeService');
      _authStatus.value = AuthStatus.error;
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Check if user is already signed in
  /// Check if user is already signed in
  Future<void> _checkSignInStatus() async {
    try {
      if (_isWindows) {
        final accessToken = await _storage.read(key: 'accessToken');
        final refreshToken = await _storage.read(key: 'refreshToken');
        if (accessToken != null || refreshToken != null) {
          try {
            await _loadCurrentUser(null);
          } catch (e) {
            ErrorHandler.logWarning(
                'Failed to load current user during initialization: $e',
                'AuthService._checkSignInStatus');
            _authStatus.value = AuthStatus.signedOut;
            await _storage.delete(key: 'accessToken');
            await _storage.delete(key: 'refreshToken');
          }
        } else {
          _authStatus.value = AuthStatus.signedOut;
        }
      } else {
        // Now attempt lightweight authentication with proper error handling
        try {
          await _googleSignIn.attemptLightweightAuthentication();
          // If successful and we have a current user, the event listener will handle it
          // If not, we'll fall through to setting signed out status

          // Give a small delay to allow the event listener to process any sign-in events
          await Future.delayed(const Duration(milliseconds: 100));

          // If no sign-in event occurred, set status to signed out
          if (_authStatus.value == AuthStatus.unknown) {
            _authStatus.value = AuthStatus.signedOut;
          }
        } on GoogleSignInException catch (e) {
          ErrorHandler.logWarning(
              'Lightweight authentication failed: ${e.code}',
              'AuthService._checkSignInStatus');
          _authStatus.value = AuthStatus.signedOut;
        } catch (e) {
          ErrorHandler.logWarning(
              'Lightweight authentication failed with unexpected error: $e',
              'AuthService._checkSignInStatus');
          _authStatus.value = AuthStatus.signedOut;
        }
      }
    } catch (e) {
      ErrorHandler.handleError(e, context: 'AuthService._checkSignInStatus');
      _authStatus.value = AuthStatus.signedOut;
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      _authStatus.value = AuthStatus.signingIn;

      if (_isWindows) {
        await _signInWithGoogleWindows();
        // For Windows, we don't have a GoogleSignInAccount, so just reload user info
        await _loadCurrentUser(null);
      } else {
        await _signInWithGoogleNative();
        // Use the last signed-in account
        await _loadCurrentUser(_lastGoogleAccount);
      }
      _authStatus.value = AuthStatus.signedIn;

      ErrorHandler.logInfo('User signed in successfully');
    } catch (e) {
      _authStatus.value = AuthStatus.error;
      ErrorHandler.handleError(e, context: 'AuthService.signInWithGoogle');

      if (e is AuthException) {
        rethrow;
      } else {
        throw AuthException.signInFailed(e.toString());
      }
    }
  }

  /// Native Google Sign In (Android/iOS) with enhanced error handling and device compatibility
  Future<void> _signInWithGoogleNative() async {
    try {
      _logger.i('Starting interactive Google Sign In');
      if (_googleSignIn.supportsAuthenticate()) {
        try {
          await _googleSignIn.authenticate();
        } on GoogleSignInException catch (e) {
          _logger.e('Google Sign In failed: $e');
          if (e.code == GoogleSignInExceptionCode.canceled) {
            throw AuthException.signInFailed(
                'Google account re-authentication failed. Please sign in again.');
          }
          throw AuthException.signInFailed(
              'User cancelled sign in or sign in failed');
        } catch (e) {
          _logger.e('Google Sign In failed: $e');
          throw AuthException.signInFailed(
              'User cancelled sign in or sign in failed');
        }
      } else {
        throw AuthException.signInFailed(
            'This platform does not support authenticate().');
      }
      _logger.i('Successfully signed in user');
    } on PlatformException catch (e) {
      ErrorHandler.logError('PlatformException during Google Sign In',
          error: e, context: 'AuthService._signInWithGoogleNative');
      final diagnostics = PlatformDiagnosticsService.to;
      diagnostics.logPlatformChannelError('google_sign_in', e);

      // Provide more specific error messages
      String errorMessage = 'Native sign in failed';
      if (e.code == 'sign_in_failed') {
        errorMessage =
            'Google Sign In failed. Please check your internet connection and try again.';
      } else if (e.code == 'network_error') {
        errorMessage =
            'Network error during sign in. Please check your connection.';
      } else if (e.code == 'sign_in_canceled') {
        errorMessage = 'Sign in was cancelled by user.';
      } else if (e.code == 'sign_in_required') {
        errorMessage = 'Google Play Services authentication required.';
      } else if (e.code == 'account_suspended') {
        errorMessage = 'Google account is suspended.';
      } else if (e.code == 'invalid_account') {
        errorMessage = 'Invalid Google account.';
      }

      throw AuthException.signInFailed('$errorMessage (Code: ${e.code})');
    } catch (e) {
      if (e is AuthException) rethrow;
      _logger.e('Unexpected error during native sign in: $e');
      throw AuthException.signInFailed('Native sign in failed: $e');
    }
  }

  /// Windows Google Sign In using OAuth2 flow
  Future<void> _signInWithGoogleWindows() async {
    try {
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      // Use localhost with port 8080 - this needs to be configured in Google Console
      const redirectUri = 'http://localhost:8080';

      final authUrl = 'https://accounts.google.com/o/oauth2/v2/auth?'
          'response_type=code&'
          'client_id=$_clientId&'
          'redirect_uri=${Uri.encodeComponent(redirectUri)}&'
          'scope=${Uri.encodeComponent('https://www.googleapis.com/auth/drive.file profile email')}&'
          'code_challenge=$codeChallenge&'
          'code_challenge_method=S256&'
          'access_type=offline&'
          'prompt=consent';

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: 'http',
        options: const FlutterWebAuth2Options(
          timeout: 300000, // 5 minutes in milliseconds
        ),
      );

      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        throw AuthException.signInFailed('Authorization failed: $error');
      }

      if (code == null) {
        throw AuthException.signInFailed('Authorization code not received');
      }

      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'code': code,
          'client_id': _clientId!,
          'client_secret': _clientSecret!,
          'redirect_uri': redirectUri,
          'grant_type': 'authorization_code',
          'code_verifier': codeVerifier,
        },
      ).timeout(const Duration(seconds: AppValues.networkTimeoutSeconds));

      if (response.statusCode != 200) {
        throw AuthException.signInFailed(
            'Token exchange failed: ${response.body}');
      }

      final data = json.decode(response.body);
      await _storage.write(key: 'accessToken', value: data['access_token']);

      if (data['refresh_token'] != null) {
        await _storage.write(key: 'refreshToken', value: data['refresh_token']);
      }
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') {
        throw AuthException.signInFailed('User canceled sign in');
      }
      throw AuthException.signInFailed('Windows sign in failed: ${e.message}');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException.signInFailed('Windows sign in failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      if (!_isWindows) {
        await _googleSignIn.signOut();
      }

      await _storage.delete(key: 'accessToken');
      await _storage.delete(key: 'refreshToken');

      _authStatus.value = AuthStatus.signedOut;
      _currentUser.value = null;

      ErrorHandler.logInfo('User signed out successfully');
    } catch (e) {
      ErrorHandler.handleError(e, context: 'AuthService.signOut');
      throw AuthException.signInFailed('Sign out failed: $e');
    }
  }

  /// Get access token with automatic refresh
  Future<String> getAccessToken() async {
    try {
      if (_isWindows) {
        return await _getAccessTokenWindows();
      } else {
        return await _getAccessTokenNative();
      }
    } catch (e) {
      ErrorHandler.handleError(e, context: 'AuthService.getAccessToken');
      if (e is AuthException) rethrow;
      throw AuthException.tokenExpired();
    }
  }

  /// Get access token for Windows
  Future<String> _getAccessTokenWindows() async {
    String? accessToken = await _storage.read(key: 'accessToken');

    if (accessToken == null) {
      final refreshToken = await _storage.read(key: 'refreshToken');
      if (refreshToken == null) {
        throw AuthException.notSignedIn();
      }

      accessToken = await _refreshTokenWindows(refreshToken);
    }

    return accessToken;
  }

  /// Get access token for native platforms with enhanced error handling and automatic recovery
  Future<String> _getAccessTokenNative() async {
    try {
      // Use the tracked user from the last sign-in event
      final user = _lastGoogleAccount;
      if (user == null) {
        _logger.w('No signed in account found, user needs to sign in');
        throw AuthException.notSignedIn();
      }
      // Request the required scopes for Drive and profile/email
      const scopes = [
        'https://www.googleapis.com/auth/drive.file',
        'profile',
        'email',
      ];
      final authorization =
          await user.authorizationClient.authorizationForScopes(scopes);
      // If not granted, request interactively
      final authResult = authorization ??
          await user.authorizationClient.authorizeScopes(scopes);
      await _storage.write(key: 'accessToken', value: authResult.accessToken);
      return authResult.accessToken;
    } on PlatformException catch (e) {
      _logger.e('Platform exception getting access token: $e');
      final diagnostics = PlatformDiagnosticsService.to;
      diagnostics.logPlatformChannelError('google_sign_in', e);

      if (e.code == 'sign_in_required') {
        throw AuthException.notSignedIn();
      } else if (e.code == 'network_error') {
        throw AuthException.signInFailed(
            'Network error while refreshing token');
      } else if (e.code == 'sign_in_failed') {
        throw AuthException.tokenExpired();
      }

      throw AuthException.tokenExpired();
    } catch (e) {
      if (e is AuthException) rethrow;
      _logger.e('Unexpected error getting access token: $e');
      throw AuthException.tokenExpired();
    }
  }

  /// Refresh token for Windows
  Future<String> _refreshTokenWindows(String refreshToken) async {
    final response = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': _clientId!,
        'client_secret': _clientSecret!,
        'refresh_token': refreshToken,
        'grant_type': 'refresh_token',
      },
    ).timeout(const Duration(seconds: AppValues.networkTimeoutSeconds));

    if (response.statusCode != 200) {
      await signOut();
      throw AuthException.tokenExpired();
    }

    final data = json.decode(response.body);
    final newAccessToken = data['access_token'];
    await _storage.write(key: 'accessToken', value: newAccessToken);

    return newAccessToken;
  }

  /// Load current user information
  Future<void> _loadCurrentUser(GoogleSignInAccount? googleAccount) async {
    try {
      String? accessToken;
      if (googleAccount != null) {
        // Get access token for the user
        const scopes = [
          'https://www.googleapis.com/auth/drive.file',
          'profile',
          'email',
        ];
        var authorization = await googleAccount.authorizationClient
            .authorizationForScopes(scopes);
        // If not granted, request interactively
        var authResult = authorization ??
            await googleAccount.authorizationClient.authorizeScopes(scopes);
        accessToken = authResult.accessToken;
      } else {
        // For Windows, use the stored access token
        accessToken = await _storage.read(key: 'accessToken');
      }
      if (accessToken == null) {
        throw AuthException.notSignedIn();
      }
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: AppValues.networkTimeoutSeconds));
      if (response.statusCode != 200) {
        throw AuthException.signInFailed('Failed to get user info');
      }
      final userData = json.decode(response.body);
      _currentUser.value = UserModel(
        id: userData['sub'] ?? '',
        email: userData['email'] ?? '',
        name: userData['name'] ?? '',
        photoUrl: userData['picture'],
        accessToken: accessToken,
      );
      _authStatus.value = AuthStatus.signedIn;
    } catch (e) {
      ErrorHandler.handleError(e, context: 'AuthService._loadCurrentUser');
      _authStatus.value = AuthStatus.error;
      rethrow;
    }

    /// Request a server auth code for backend use
    /// Request a server auth code for backend use
    // ignore: unused_element
    Future<String?> requestServerAuthCode(List<String> scopes) async {
      final user = _lastGoogleAccount;
      if (user == null) {
        throw AuthException.notSignedIn();
      }
      final serverAuth = await user.authorizationClient.authorizeServer(scopes);
      return serverAuth?.serverAuthCode;
    }
  }

  /// Generate code verifier for PKCE
  String _generateCodeVerifier() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(64, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Generate code challenge for PKCE
  String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Execute operation with valid authentication
  Future<T> executeWithAuth<T>(
      Future<T> Function(String accessToken) operation) async {
    if (!isSignedIn) {
      throw AuthException.notSignedIn();
    }

    final accessToken = await getAccessToken();
    return await operation(accessToken);
  }
}
