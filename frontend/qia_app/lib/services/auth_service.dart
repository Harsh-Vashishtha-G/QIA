import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:local_auth/local_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../utils/logger.dart';
import 'secure_storage.dart';
import 'error_recovery.dart';

class AuthService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  final _secureStorage = SecureStorage();
  final _errorRecovery = ErrorRecovery();
  String? _token;
  bool _isAuthenticated = false;
  DateTime? _tokenExpiry;
  Timer? _refreshTimer;

  bool get isAuthenticated => _isAuthenticated;

  AuthService() {
    _initializeAuth();
    _registerRecoveryStrategies();
  }

  void _registerRecoveryStrategies() {
    _errorRecovery.registerRecoveryStrategy(
      'token_refresh',
      () async {
        await logout();
        // Trigger re-authentication flow
        notifyListeners();
      },
    );

    _errorRecovery.registerRecoveryStrategy(
      'biometric_auth',
      () async {
        // Clear biometric credentials and force password login
        await _secureStorage.secureDelete('biometric_credentials');
        notifyListeners();
      },
    );
  }

  Future<void> _initializeAuth() async {
    try {
      // Check for existing token
      _token = await _storage.read(key: 'auth_token');
      if (_token != null) {
        final decodedToken = JwtDecoder.decode(_token!);
        _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
        
        if (_tokenExpiry!.isAfter(DateTime.now())) {
          _isAuthenticated = true;
          _scheduleTokenRefresh();
          notifyListeners();
        } else {
          // Token expired, try to refresh
          await refreshToken();
        }
      }
    } catch (e) {
      Logger.error('Auth initialization failed', error: e);
      await logout();
    }
  }

  Future<void> login(String email, String password) async {
    return _errorRecovery.tryOperation(
      operationType: 'login',
      operation: () async {
        try {
          final response = await http.post(
            Uri.parse('${AppConfig.apiUrl}/auth/token'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'username': email,
              'password': password,
            }),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            await _handleAuthResponse(data);
            
            // Store credentials securely
            if (await _localAuth.canCheckBiometrics) {
              await _secureStorage.secureBiometricWrite(
                'biometric_credentials',
                json.encode({
                  'email': email,
                  'password': password,
                }),
              );
            }
          } else {
            throw HttpException('Login failed: ${response.body}');
          }
        } catch (e) {
          Logger.error('Login failed', error: e);
          rethrow;
        }
      },
    );
  }

  Future<void> biometricLogin() async {
    try {
      final credentials = await _storage.read(key: 'biometric_credentials');
      if (credentials == null) {
        throw Exception('No stored credentials for biometric login');
      }

      final decodedCredentials = json.decode(credentials);
      await login(
        decodedCredentials['email'],
        decodedCredentials['password'],
      );
    } catch (e) {
      Logger.error('Biometric login failed', error: e);
      rethrow;
    }
  }

  Future<String?> getToken() async {
    if (_token != null && _tokenExpiry!.isAfter(DateTime.now())) {
      return _token;
    }
    
    // Try to refresh token if expired
    if (_token != null) {
      await refreshToken();
      if (_isAuthenticated) {
        return _token;
      }
    }
    
    return null;
  }

  Future<void> refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _handleAuthResponse(data);
      } else {
        throw HttpException('Token refresh failed: ${response.body}');
      }
    } catch (e) {
      Logger.error('Token refresh failed', error: e);
      await logout();
    }
  }

  Future<void> _handleAuthResponse(Map<String, dynamic> data) async {
    _token = data['access_token'];
    final decodedToken = JwtDecoder.decode(_token!);
    _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
    
    await _storage.write(key: 'auth_token', value: _token);
    await _storage.write(key: 'refresh_token', value: data['refresh_token']);
    
    _isAuthenticated = true;
    _scheduleTokenRefresh();
    notifyListeners();
  }

  void _scheduleTokenRefresh() {
    _refreshTimer?.cancel();
    if (_tokenExpiry != null) {
      final timeUntilExpiry = _tokenExpiry!.difference(DateTime.now());
      final refreshTime = timeUntilExpiry - const Duration(minutes: 5);
      
      if (refreshTime.isNegative) {
        refreshToken();
      } else {
        _refreshTimer = Timer(refreshTime, refreshToken);
      }
    }
  }

  Future<void> logout() async {
    try {
      _refreshTimer?.cancel();
      _token = null;
      _tokenExpiry = null;
      _isAuthenticated = false;
      
      await Future.wait([
        _storage.delete(key: 'auth_token'),
        _storage.delete(key: 'refresh_token'),
        _storage.delete(key: 'biometric_credentials'),
      ]);
      
      notifyListeners();
    } catch (e) {
      Logger.error('Logout failed', error: e);
      rethrow;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
} 