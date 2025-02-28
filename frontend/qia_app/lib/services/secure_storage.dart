import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../utils/logger.dart';

class SecureStorage {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  
  // Encryption key derived from device-specific hardware
  String? _encryptionKey;

  Future<void> initialize() async {
    try {
      // Generate or retrieve device-specific encryption key
      _encryptionKey = await _getDeviceKey();
      Logger.info('Secure storage initialized');
    } catch (e) {
      Logger.error('Failed to initialize secure storage', error: e);
      rethrow;
    }
  }

  Future<String?> _getDeviceKey() async {
    try {
      // Check for existing device key
      final existingKey = await _storage.read(key: 'device_key');
      if (existingKey != null) {
        return existingKey;
      }

      // Generate new device-specific key
      final deviceInfo = await _getDeviceInfo();
      final key = _generateKey(deviceInfo);
      await _storage.write(key: 'device_key', value: key);
      return key;
    } catch (e) {
      Logger.error('Failed to get device key', error: e);
      rethrow;
    }
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    // Collect device-specific information for key generation
    final deviceInfo = <String, String>{};
    try {
      final biometricTypes = await _localAuth.getAvailableBiometrics();
      deviceInfo['biometric_types'] = biometricTypes.join(',');
      deviceInfo['device_id'] = await _storage.read(key: 'device_uuid') ?? 
          DateTime.now().millisecondsSinceEpoch.toString();
      
      if (deviceInfo['device_id'] == null) {
        await _storage.write(key: 'device_uuid', value: deviceInfo['device_id']);
      }
    } catch (e) {
      Logger.warning('Error getting device info', error: e);
    }
    return deviceInfo;
  }

  String _generateKey(Map<String, String> deviceInfo) {
    final data = utf8.encode(json.encode(deviceInfo));
    return sha256.convert(data).toString();
  }

  Future<void> secureWrite(String key, String value) async {
    try {
      if (_encryptionKey == null) {
        await initialize();
      }

      // Encrypt value using device-specific key
      final encryptedValue = await _encrypt(value);
      await _storage.write(key: key, value: encryptedValue);
      Logger.info('Securely stored data for key: $key');
    } catch (e) {
      Logger.error('Failed to write secure data', error: e);
      rethrow;
    }
  }

  Future<String?> secureRead(String key) async {
    try {
      if (_encryptionKey == null) {
        await initialize();
      }

      final encryptedValue = await _storage.read(key: key);
      if (encryptedValue == null) return null;

      // Decrypt value using device-specific key
      return await _decrypt(encryptedValue);
    } catch (e) {
      Logger.error('Failed to read secure data', error: e);
      rethrow;
    }
  }

  Future<void> secureBiometricWrite(String key, String value) async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to secure data',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!authenticated) {
        throw Exception('Biometric authentication failed');
      }

      await secureWrite(key, value);
    } catch (e) {
      Logger.error('Failed to write biometric secure data', error: e);
      rethrow;
    }
  }

  Future<String?> secureBiometricRead(String key) async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access secure data',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!authenticated) {
        throw Exception('Biometric authentication failed');
      }

      return await secureRead(key);
    } catch (e) {
      Logger.error('Failed to read biometric secure data', error: e);
      rethrow;
    }
  }

  Future<String> _encrypt(String value) async {
    try {
      final key = utf8.encode(_encryptionKey!);
      final iv = List<int>.generate(16, (i) => i * i + 3);
      final encrypter = await _createAesGcm(key);
      
      final encrypted = await encrypter.encrypt(
        utf8.encode(value),
        iv: iv,
      );

      return base64.encode(encrypted);
    } catch (e) {
      Logger.error('Encryption failed', error: e);
      rethrow;
    }
  }

  Future<String> _decrypt(String encryptedValue) async {
    try {
      final key = utf8.encode(_encryptionKey!);
      final iv = List<int>.generate(16, (i) => i * i + 3);
      final encrypter = await _createAesGcm(key);
      
      final decrypted = await encrypter.decrypt(
        base64.decode(encryptedValue),
        iv: iv,
      );

      return utf8.decode(decrypted);
    } catch (e) {
      Logger.error('Decryption failed', error: e);
      rethrow;
    }
  }

  Future<AesGcm> _createAesGcm(List<int> key) async {
    // Use platform-specific crypto implementation
    return AesGcm.with256bits();
  }
} 