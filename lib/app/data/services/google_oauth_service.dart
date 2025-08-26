import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:http/http.dart' as http;
import 'package:photo_uploader/app/data/services/platform_diagnostics_service.dart';
import '../models/user_model.dart';
import '../models/enums.dart';
import '../../core/errors/app_exception.dart';
import '../../core/values/app_values.dart';

/// Authentication service using GetX patterns
class AuthService extends GetxService {
  static AuthService get to => Get.find();

  // Configuration
  String? _clientId;
  String? _clientSecret;
  late final GoogleSignIn _googleSignIn;
  late final FlutterSecureStorage _storage;
  final bool _isWindows = !kIsWeb && Platform.isWindows;

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
    await _checkSignInStatus();
  }

  /// Initialize the authentication service
  Future<void> _initializeService() async {
    // Prevent double initialization
    if (_isInitialized || _isInitializing) {
      return;
    }
    
    _isInitializing = true;
    
    try {
      // Initialize client IDs
      if (_clientId == null) {
        _clientId = dotenv.env['WEB_CLIENT_ID'];
        _clientSecret = dotenv.env['WEB_CLIENT_SECRET'];
        
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

      // Initialize Google Sign In
      _googleSignIn = GoogleSignIn(
        clientId: !_isWindows ? _clientId : null,
        scopes: [
          'https://www.googleapis.com/auth/drive.file',
          DriveApi.driveFileScope,
          'profile',
          'email',
        ],
        serverClientId: _clientId,
      );

      _isInitialized = true;
      ErrorHandler.logInfo('AuthService initialized successfully');
    } on PlatformException catch (e) {
      ErrorHandler.logError('PlatformException during AuthService initialization', error: e, context: 'AuthService._initializeService');
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
  Future<void> _checkSignInStatus() async {
    try {
      if (_isWindows) {
        final accessToken = await _storage.read(key: 'accessToken');
        final refreshToken = await _storage.read(key: 'refreshToken');
        
        if (accessToken != null || refreshToken != null) {
          try {
            await _loadCurrentUser();
          } catch (e) {
            // If we can't load the current user, just set as signed out
            ErrorHandler.logWarning('Failed to load current user during initialization: $e', 'AuthService._checkSignInStatus');
            _authStatus.value = AuthStatus.signedOut;
            // Clear invalid tokens
            await _storage.delete(key: 'accessToken');
            await _storage.delete(key: 'refreshToken');
          }
        } else {
          _authStatus.value = AuthStatus.signedOut;
        }
      } else {
        final account = await _googleSignIn.signInSilently();
        if (account != null) {
          try {
            await _loadCurrentUser();
          } catch (e) {
            // If we can't load the current user, just set as signed out
            ErrorHandler.logWarning('Failed to load current user during initialization: $e', 'AuthService._checkSignInStatus');
            _authStatus.value = AuthStatus.signedOut;
          }
        } else {
          _authStatus.value = AuthStatus.signedOut;
        }
      }
    } catch (e) {
      ErrorHandler.handleError(e, context: 'AuthService._checkSignInStatus');
      _authStatus.value = AuthStatus.signedOut; // Default to signed out on error
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      _authStatus.value = AuthStatus.signingIn;
      
      if (_isWindows) {
        await _signInWithGoogleWindows();
      } else {
        await _signInWithGoogleNative();
      }
      
      await _loadCurrentUser();
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

  /// Native Google Sign In (Android/iOS)
  Future<void> _signInWithGoogleNative() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        throw AuthException.signInFailed('User cancelled sign in');
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      
      if (auth.accessToken == null) {
        throw AuthException.signInFailed('Failed to obtain access token');
      }

      await _storage.write(key: 'accessToken', value: auth.accessToken);
      if (auth.idToken != null) {
        await _storage.write(key: 'refreshToken', value: auth.idToken);
      }
    } on PlatformException catch (e) {
      ErrorHandler.logError('PlatformException during Google Sign In', error: e, context: 'AuthService._signInWithGoogleNative');
      final diagnostics = PlatformDiagnosticsService.to;
      diagnostics.logPlatformChannelError('google_sign_in', e);
      if (e is PlatformException) rethrow;
      throw AuthException.signInFailed('Native sign in failed: $e');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException.signInFailed('Native sign in failed: $e');
    }
  }

  /// Windows Google Sign In using OAuth2 flow
  Future<void> _signInWithGoogleWindows() async {
    try {
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      final authUrl = 'https://accounts.google.com/o/oauth2/v2/auth?'
          'response_type=code&'
          'client_id=$_clientId&'
          'redirect_uri=http://localhost:8080&'
          'scope=https://www.googleapis.com/auth/drive.file profile email&'
          'code_challenge=$codeChallenge&'
          'code_challenge_method=S256';

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: 'http://localhost:8080',
      );

      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];

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
          'redirect_uri': 'http://localhost:8080',
          'grant_type': 'authorization_code',
          'code_verifier': codeVerifier,
        },
      ).timeout(Duration(seconds: AppValues.networkTimeoutSeconds));

      if (response.statusCode != 200) {
        throw AuthException.signInFailed('Token exchange failed: ${response.body}');
      }

      final data = json.decode(response.body);
      await _storage.write(key: 'accessToken', value: data['access_token']);
      
      if (data['refresh_token'] != null) {
        await _storage.write(key: 'refreshToken', value: data['refresh_token']);
      }
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

  /// Get access token for native platforms
  Future<String> _getAccessTokenNative() async {
    final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
    if (account == null) {
      throw AuthException.notSignedIn();
    }
    
    final GoogleSignInAuthentication auth = await account.authentication;
    if (auth.accessToken == null) {
      throw AuthException.tokenExpired();
    }
    
    return auth.accessToken!;
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
    ).timeout(Duration(seconds: AppValues.networkTimeoutSeconds));

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
  Future<void> _loadCurrentUser() async {
    try {
      final accessToken = await getAccessToken();
      
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(Duration(seconds: AppValues.networkTimeoutSeconds));

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
  }

  /// Generate code verifier for PKCE
  String _generateCodeVerifier() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
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
  Future<T> executeWithAuth<T>(Future<T> Function(String accessToken) operation) async {
    if (!isSignedIn) {
      throw AuthException.notSignedIn();
    }
    
    final accessToken = await getAccessToken();
    return await operation(accessToken);
  }
}