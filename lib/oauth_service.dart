import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:http/http.dart' as http;

var _clientId = dotenv.env['WEB_CLIENT_ID'];
var _clientSecret = dotenv.env['WEB_CLIENT_SECRET'];

class GoogleSignInService {
  late final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final bool _isWindows = !kIsWeb && Platform.isWindows;

  GoogleSignInService() {
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
  }

  Future<void> signInWithGoogle() async {
    if (_isWindows) {
      await _signInWithGoogleWindows();
    } else {
      await _signInWithGoogleNative();
    }
  }

  Future<void> _signInWithGoogleNative() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        await _storage.write(key: 'accessToken', value: auth.accessToken);
        await _storage.write(key: 'refreshToken', value: auth.idToken);
      }
    } catch (e) {
      developer.log('Error signing in with Google: $e');
    }
  }

  Future<void> _signInWithGoogleWindows() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    final authUrl =
        'https://accounts.google.com/o/oauth2/v2/auth?response_type=code'
        '&client_id=$_clientId'
        '&redirect_uri=http://localhost:8080'
        '&scope=https://www.googleapis.com/auth/drive.file profile email'
        '&code_challenge=$codeChallenge'
        '&code_challenge_method=S256';

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: 'http://localhost:8080',
      );

      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];

      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        body: {
          'code': code,
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'redirect_uri': 'http://localhost:8080',
          'grant_type': 'authorization_code',
          'code_verifier': codeVerifier,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storage.write(key: 'accessToken', value: data['access_token']);
        await _storage.write(key: 'refreshToken', value: data['refresh_token']);
      } else {
        throw Exception('Failed to obtain access token');
      }
    } catch (e) {
      developer.log('Error signing in with Google on Windows: $e');
    }
  }

  Future<void> signOut() async {
    if (_isWindows) {
      await _storage.delete(key: 'accessToken');
      await _storage.delete(key: 'refreshToken');
    } else {
      await _googleSignIn.signOut();
      await _storage.delete(key: 'accessToken');
      await _storage.delete(key: 'refreshToken');
    }
  }

  Future<String?> getAccessToken() async {
    if (_isWindows) {
      String? accessToken = await _storage.read(key: 'accessToken');
      if (accessToken == null) {
        String? refreshToken = await _storage.read(key: 'refreshToken');
        if (refreshToken != null) {
          final response = await http.post(
            Uri.parse('https://oauth2.googleapis.com/token'),
            body: {
              'client_id': _clientId,
              'client_secret': _clientSecret,
              'refresh_token': refreshToken,
              'grant_type': 'refresh_token',
            },
          );
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            accessToken = data['access_token'];
            await _storage.write(key: 'accessToken', value: accessToken);
          } else {
            await signOut();
            return null;
          }
        } else {
          return null;
        }
      }
      return accessToken;
    } else {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        return auth.accessToken;
      }
      return null;
    }
  }

  Future<bool> isSignedIn() async {
    if (_isWindows) {
      final accessToken = await _storage.read(key: 'accessToken');
      final refreshToken = await _storage.read(key: 'refreshToken');
      return accessToken != null || refreshToken != null;
    } else {
      return await _googleSignIn.isSignedIn();
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final accessToken = await getAccessToken();
    if (accessToken != null) {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 200) {
        developer.log('User info: ${response.body.toString()}');
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get user info');
      }
    } else {
      throw Exception('No user signed in');
    }
  }

  String _generateCodeVerifier() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(64, (_) => chars[random.nextInt(chars.length)]).join();
  }

  String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
