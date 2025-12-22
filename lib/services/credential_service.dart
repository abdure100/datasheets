import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing and retrieving user credentials
/// Uses iOS Keychain on iOS devices and Android Keystore on Android
class CredentialService {
  // Use default secure storage options
  // On iOS: Uses Keychain with default accessibility
  // On Android: Uses EncryptedSharedPreferences
  static const _storage = FlutterSecureStorage();

  static const String _usernameKey = 'saved_username';
  static const String _passwordKey = 'saved_password';

  /// Save username and password securely
  static Future<void> saveCredentials({
    required String username,
    required String password,
  }) async {
    try {
      await _storage.write(key: _usernameKey, value: username);
      await _storage.write(key: _passwordKey, value: password);
      print('✅ Credentials saved securely');
    } catch (e) {
      print('❌ Error saving credentials: $e');
      rethrow;
    }
  }

  /// Load saved username
  static Future<String?> getSavedUsername() async {
    try {
      return await _storage.read(key: _usernameKey);
    } catch (e) {
      print('❌ Error loading saved username: $e');
      return null;
    }
  }

  /// Load saved password
  static Future<String?> getSavedPassword() async {
    try {
      return await _storage.read(key: _passwordKey);
    } catch (e) {
      print('❌ Error loading saved password: $e');
      return null;
    }
  }

  /// Load both username and password
  static Future<Map<String, String?>> getSavedCredentials() async {
    try {
      final username = await getSavedUsername();
      final password = await getSavedPassword();
      return {
        'username': username,
        'password': password,
      };
    } catch (e) {
      print('❌ Error loading saved credentials: $e');
      return {'username': null, 'password': null};
    }
  }

  /// Clear saved credentials
  static Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: _usernameKey);
      await _storage.delete(key: _passwordKey);
      print('✅ Credentials cleared');
    } catch (e) {
      print('❌ Error clearing credentials: $e');
    }
  }

  /// Check if credentials are saved
  static Future<bool> hasSavedCredentials() async {
    try {
      final username = await getSavedUsername();
      final password = await getSavedPassword();
      return username != null && password != null;
    } catch (e) {
      return false;
    }
  }
}

