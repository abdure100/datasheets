import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Service for managing authentication tokens (Sanctum, FileMaker, etc.)
class TokenService {
  static const String _sanctumTokenKey = 'sanctum_token';

  /// Save Sanctum token to secure storage
  static Future<void> saveSanctumToken(String token) async {
    try {
      print('💾 TokenService.saveSanctumToken called');
      print('💾 Token length: ${token.length}');
      print('💾 Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sanctumTokenKey, token);
      
      // Verify it was saved
      final saved = prefs.getString(_sanctumTokenKey);
      if (saved != null && saved == token) {
        print('✅ Sanctum token saved and verified in SharedPreferences');
      } else {
        print('⚠️ Token save verification failed - saved: ${saved?.length ?? 0}, expected: ${token.length}');
      }
      
      AppConfig.sanctumToken = token;
      print('✅ Sanctum token also set in AppConfig.sanctumToken');
      print('💾 TokenService.saveSanctumToken completed successfully');
    } catch (e) {
      print('❌ Error saving Sanctum token: $e');
      print('❌ Error stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Load Sanctum token from storage
  static Future<String?> loadSanctumToken() async {
    try {
      print('📂 TokenService.loadSanctumToken called');
      print('📂 Loading from SharedPreferences key: $_sanctumTokenKey');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_sanctumTokenKey);
      
      if (token != null) {
        print('✅ Token found in SharedPreferences');
        print('📂 Token length: ${token.length}');
        print('📂 Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
        AppConfig.sanctumToken = token;
        print('✅ Sanctum token loaded and set in AppConfig');
        return token;
      } else {
        print('⚠️ No token found in SharedPreferences');
        print('📂 Checking AppConfig.sanctumToken: ${AppConfig.sanctumToken != null ? "exists (${AppConfig.sanctumToken!.length} chars)" : "null"}');
        return null;
      }
    } catch (e) {
      print('❌ Error loading Sanctum token: $e');
      print('❌ Error stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Clear Sanctum token
  static Future<void> clearSanctumToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sanctumTokenKey);
      AppConfig.sanctumToken = null;
      print('✅ Sanctum token cleared');
    } catch (e) {
      print('❌ Error clearing Sanctum token: $e');
    }
  }

  /// Check if Sanctum token exists
  static Future<bool> hasSanctumToken() async {
    final token = await loadSanctumToken();
    return token != null && token.isNotEmpty;
  }

  /// Get current Sanctum token (from memory or storage)
  static Future<String?> getSanctumToken() async {
    print('🔍 TokenService.getSanctumToken called');
    
    // Check AppConfig first (memory)
    if (AppConfig.sanctumToken != null && AppConfig.sanctumToken!.isNotEmpty) {
      print('✅ Token found in AppConfig (memory): ${AppConfig.sanctumToken!.length} chars');
      return AppConfig.sanctumToken;
    }
    
    print('📂 Token not in AppConfig, loading from storage...');
    final token = await loadSanctumToken();
    
    if (token != null) {
      print('✅ Token retrieved from storage');
    } else {
      print('❌ No token found in memory or storage');
    }
    
    return token;
  }
}

