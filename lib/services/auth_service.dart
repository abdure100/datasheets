import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'token_service.dart';

/// Service for authenticating with Laravel backend and obtaining Sanctum tokens
class AuthService {
  static const String loginEndpoint = '/auth/login';
  static const String exchangeEndpoint = '/auth/exchange-filemaker-token';
  static const String logoutEndpoint = '/auth/logout';
  static const String meEndpoint = '/auth/me';

  /// Exchange FileMaker token for Sanctum token
  /// This avoids re-authentication if you already have a FileMaker token
  /// Returns the Sanctum token if successful, null otherwise
  static Future<String?> exchangeFileMakerToken({
    required String filemakerToken,
    String? email,
    String? database,
  }) async {
    try {
      final url = '${AppConfig.mcpBaseUrl}$exchangeEndpoint';
      print('🔐 Attempting FileMaker token exchange to: $url');
      print('🔍 URL DEBUG: mcpBaseUrl=${AppConfig.mcpBaseUrl}, endpoint=$exchangeEndpoint');
      
      final body = <String, dynamic>{
        'filemaker_token': filemakerToken,
      };
      
      if (email != null) {
        body['email'] = email;
      }
      if (database != null) {
        body['database'] = database;
      }
      
      print('📤 Token exchange request body: ${jsonEncode(body)}');
      print('📤 Token exchange request body keys: ${body.keys.toList()}');
      print('📤 Token exchange request - filemaker_token length: ${filemakerToken.length}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('🔐 Token exchange response status: ${response.statusCode}');
      print('🔐 Token exchange response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        print('📋 Token exchange response data keys: ${data.keys.toList()}');
        print('📋 success: ${data['success']}, token exists: ${data['token'] != null}');
        
        // Expected response format:
        // {
        //   "success": true,
        //   "token": "1|xxxxxxxxxxxx...",
        //   "user": {...},
        //   "token_type": "Bearer",
        //   "expires_at": null,
        //   "filemaker_token_accepted": true
        // }
        
        if (data['success'] == true && data['token'] != null) {
          final token = data['token'] as String;
          print('✅ Sanctum token received via exchange');
          print('📋 Token length: ${token.length}');
          print('📋 Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
          
          // Log user info if provided
          if (data['user'] != null) {
            final user = data['user'] as Map<String, dynamic>;
            print('👤 User: ${user['name'] ?? 'N/A'} (${user['email'] ?? 'N/A'})');
            if (user['company_id'] != null) {
              print('🏢 Company ID from MCP API: ${user['company_id']}');
            } else {
              print('⚠️ Company ID missing from MCP API response');
            }
          }
          
          // Log token metadata
          if (data['token_type'] != null) {
            print('📋 Token type: ${data['token_type']}');
          }
          if (data['filemaker_token_accepted'] != null) {
            print('📋 FileMaker token accepted: ${data['filemaker_token_accepted']}');
          }
          
          // Store the token securely
          print('💾 Calling TokenService.saveSanctumToken...');
          print('💾 Token to save length: ${token.length}');
          print('💾 Token to save preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
          await TokenService.saveSanctumToken(token);
          
          // Small delay to ensure storage write completes
          await Future.delayed(const Duration(milliseconds: 100));
          
          // Verify it was saved
          print('🔍 Verifying token was saved...');
          final verifyToken = await TokenService.getSanctumToken();
          if (verifyToken != null) {
            print('🔍 Verify token length: ${verifyToken.length}');
            print('🔍 Verify token preview: ${verifyToken.substring(0, verifyToken.length > 20 ? 20 : verifyToken.length)}...');
            print('🔍 Tokens match: ${verifyToken == token}');
            
            if (verifyToken == token) {
              print('✅ Token verified after saving - ready for MCP API calls');
            } else {
              print('⚠️ Token verification failed - tokens do not match');
              print('⚠️ Original token length: ${token.length}');
              print('⚠️ Retrieved token length: ${verifyToken.length}');
            }
          } else {
            print('❌ Token verification failed - token is null after saving');
            print('❌ This indicates a storage issue');
          }
          
          return token;
        } else {
          print('❌ Token exchange response missing token or success flag');
          print('📋 Response data: $data');
          return null;
        }
      } else {
        final errorData = jsonDecode(response.body);
        print('❌ Token exchange failed with status ${response.statusCode}');
        print('❌ Error message: ${errorData['message'] ?? 'Unknown error'}');
        print('❌ Full error response: ${response.body}');
        
        // If it's a 401, the FileMaker token might be invalid or the backend needs it validated first
        if (response.statusCode == 401) {
          print('🔍 DEBUG: 401 Unauthorized - FileMaker token rejected by backend');
          print('🔍 DEBUG: This could mean:');
          print('🔍 DEBUG:   1. Token needs to be validated with FileMaker first');
          print('🔍 DEBUG:   2. Backend expects token in different format');
          print('🔍 DEBUG:   3. Token has expired or is invalid');
        }
        
        throw Exception(errorData['message'] ?? 'Token exchange failed');
      }
    } catch (e) {
      print('❌ Error during token exchange: $e');
      rethrow;
    }
  }

  /// Login with email and password to get Sanctum token
  /// Returns the token if successful, null otherwise
  /// Note: Prefer using exchangeFileMakerToken if you already have a FileMaker token
  static Future<String?> login(String email, String password) async {
    try {
      final url = '${AppConfig.mcpBaseUrl}$loginEndpoint';
      print('🔐 Attempting Laravel login to: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('🔐 Laravel login response status: ${response.statusCode}');
      print('🔐 Laravel login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['token'] != null) {
          final token = data['token'] as String;
          print('✅ Sanctum token received: ${token.substring(0, 20)}...');
          
          // Store the token securely
          await TokenService.saveSanctumToken(token);
          
          return token;
        } else {
          print('❌ Login response missing token or success flag');
          return null;
        }
      } else {
        final errorData = jsonDecode(response.body);
        print('❌ Login failed: ${errorData['message'] ?? 'Unknown error'}');
        throw Exception(errorData['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('❌ Error during Laravel login: $e');
      rethrow;
    }
  }

  /// Logout and revoke the Sanctum token
  static Future<void> logout() async {
    try {
      final token = await TokenService.getSanctumToken();
      if (token == null) {
        print('⚠️ No token to logout');
        return;
      }

      final url = '${AppConfig.mcpBaseUrl}$logoutEndpoint';
      print('🔐 Attempting Laravel logout to: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Logout successful');
      } else {
        print('⚠️ Logout request failed: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error during logout: $e');
    } finally {
      // Always clear the token locally
      await TokenService.clearSanctumToken();
    }
  }

  /// Get current authenticated user info
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await TokenService.getSanctumToken();
      if (token == null) {
        return null;
      }

      final url = '${AppConfig.mcpBaseUrl}$meEndpoint';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user'] as Map<String, dynamic>?;
      } else {
        print('❌ Failed to get current user: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }
}

