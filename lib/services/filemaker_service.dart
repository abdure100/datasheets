import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client.dart';
import '../models/visit.dart';
import '../models/program_assignment.dart';
import '../models/session_record.dart';
import '../models/behavior_definition.dart';
import '../models/behavior_log.dart';
import '../models/staff.dart';
import '../config/app_config.dart';
import 'location_service.dart';
import 'ip_service.dart';

class FileMakerService extends ChangeNotifier {
  static String get baseUrl => AppConfig.baseUrl;
  static String get database => AppConfig.database;
  static String get username => AppConfig.username;
  static String get password => AppConfig.password;
  
  String? _token;
  bool _isAuthenticated = false;
  late Dio _dio;
  DateTime? _tokenCreatedAt; // Track when token was created
  
  // Token expiration: FileMaker sessions expire after 15 minutes of inactivity
  // We'll proactively refresh after 14 minutes to avoid expiration
  static const Duration _tokenRefreshThreshold = Duration(minutes: 14);
  
  // Session global variables
  String? _currentStaffId;
  String? _currentCompanyId;
  String? _currentStaffName;
  String? _currentStaffEmail;
  bool? _currentStaffCanManualEntry;

  FileMakerService() {
    _dio = Dio();
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: AppConfig.connectionTimeout);
    _dio.options.receiveTimeout = const Duration(seconds: AppConfig.receiveTimeout);
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Accept'] = 'application/json';
    
    // Don't set User-Agent or Connection headers as they cause "unsafe header" warnings in web browsers
    // These headers are not essential for FileMaker API functionality
    
    // Add interceptor for automatic token refresh
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired, invalidate and refresh
          print('🔄 401 Unauthorized - Token expired, attempting to refresh...');
          
          // Invalidate the expired token first
          _invalidateToken();
          
          try {
            final refreshed = await authenticate();
            if (refreshed) {
              print('✅ Token refreshed successfully, retrying request...');
              
              // Retry the original request with new token
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer $_token';
              
              // Prevent infinite loops by tracking retry attempts
              final retryCount = options.extra['retryCount'] ?? 0;
              if (retryCount >= 1) {
                print('❌ Max retries reached, giving up');
                handler.next(error);
                return;
              }
              options.extra['retryCount'] = retryCount + 1;
              
              try {
                final response = await _dio.fetch(options);
                handler.resolve(response);
                return;
              } catch (retryError) {
                print('❌ Retry failed: $retryError');
                // Convert any error to DioException for handler
                if (retryError is DioException) {
                  handler.next(retryError);
                } else {
                  handler.next(DioException(
                    requestOptions: options,
                    error: retryError,
                  ));
                }
                return;
              }
            } else {
              print('❌ Token refresh failed - authentication unsuccessful');
            }
          } catch (e) {
            print('❌ Token refresh failed with error: $e');
          }
        } else if (error.response?.statusCode == 400) {
          // Bad request - log the error details
          print('❌ Bad Request (400): ${error.response?.data}');
          print('❌ Request URL: ${error.requestOptions.uri}');
          print('❌ Request Data: ${error.requestOptions.data}');
        }
        handler.next(error);
      },
    ));
    
    _loadStoredToken();
  }

  bool get isAuthenticated => _isAuthenticated;
  
  // Get current FileMaker token (for token exchange)
  String? get token => _token;

  // Check if token is likely expired based on age
  bool _isTokenExpired() {
    if (_tokenCreatedAt == null) {
      return true; // No timestamp means token is old/invalid
    }
    
    final age = DateTime.now().difference(_tokenCreatedAt!);
    // If token is older than 14 minutes, consider it expired
    return age >= _tokenRefreshThreshold;
  }

  // Validate existing token without re-authenticating
  Future<bool> validateToken() async {
    if (!_isAuthenticated || _token == null) {
      return false;
    }

    // First check token age - if it's too old, don't even try
    if (_isTokenExpired()) {
      print('⏰ Token is expired based on age (${DateTime.now().difference(_tokenCreatedAt!).inMinutes} minutes old)');
      return false;
    }

    try {
      // Try to make a simple request to validate the token - use _find instead of records with limit
      final response = await _dio.post('/databases/$database/layouts/api_staffs/_find', data: {
        'query': [{'email': '==test@example.com'}], // This will return no results but validate the token
        'limit': 1
      });
      return response.statusCode == 200;
    } catch (e) {
      // If validation fails, token is expired
      if (e is DioException && e.response?.statusCode == 401) {
        print('🔐 Token validation failed: 401 Unauthorized');
        _invalidateToken(); // Clear the expired token
      }
      return false;
    }
  }
  
  // Invalidate token and clear authentication state
  void _invalidateToken() {
    _token = null;
    _isAuthenticated = false;
    _tokenCreatedAt = null;
    _dio.options.headers.remove('Authorization');
    
    // Clear stored token and timestamp
    SharedPreferences.getInstance().then((prefs) async {
      await prefs.remove('filemaker_token');
      await prefs.remove('filemaker_token_created_at');
    });
    
    print('🗑️ Token invalidated and cleared');
  }
  
  // Session global variables getters
  String? get currentStaffId => _currentStaffId;
  String? get currentCompanyId => _currentCompanyId;
  String? get currentStaffName => _currentStaffName;
  bool? get currentStaffCanManualEntry => _currentStaffCanManualEntry;

  Future<void> _loadStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('filemaker_token');
      final tokenCreatedAtStr = prefs.getString('filemaker_token_created_at');
      
      if (storedToken != null) {
        _token = storedToken;
        
        // Load token creation timestamp if available
        if (tokenCreatedAtStr != null) {
          try {
            _tokenCreatedAt = DateTime.parse(tokenCreatedAtStr);
            final age = DateTime.now().difference(_tokenCreatedAt!);
            print('📋 Loaded stored token (age: ${age.inMinutes} minutes)');
            
            // Check if stored token is expired
            if (age >= _tokenRefreshThreshold) {
              print('⏰ Stored token is expired, will re-authenticate on next request');
              _isAuthenticated = false; // Will trigger re-auth on next request
              return;
            }
          } catch (e) {
            print('⚠️ Error parsing token timestamp: $e');
            // If we can't parse timestamp, assume token is old
            _tokenCreatedAt = DateTime.now().subtract(const Duration(minutes: 16)); // Force expiration
          }
        } else {
          // No timestamp stored, assume token is old (from before this feature)
          print('⚠️ No token timestamp found, assuming token is expired');
          _tokenCreatedAt = DateTime.now().subtract(const Duration(minutes: 16)); // Force expiration
          _isAuthenticated = false; // Will trigger re-auth on next request
          return;
        }
        
        _isAuthenticated = true;
        _dio.options.headers['Authorization'] = 'Bearer $_token';
        print('✅ Stored token loaded successfully');
      }
    } catch (e) {
      print('⚠️ Error loading stored token: $e');
      // Error loading stored token
    }
  }

  Future<void> _ensureAuthenticated() async {
    if (!_isAuthenticated || _token == null) {
      print('🔐 No token found, authenticating...');
      await authenticate();
      return;
    }
    
    // Check if token is expired based on age (proactive refresh)
    if (_isTokenExpired()) {
      print('⏰ Token expired (${DateTime.now().difference(_tokenCreatedAt!).inMinutes} minutes old), refreshing...');
      _invalidateToken();
      await authenticate();
      return;
    }
    
    // Token exists and is not expired by age, but validate it's still valid
    // Only validate if we're close to expiration (within 1 minute) to avoid unnecessary calls
    final age = DateTime.now().difference(_tokenCreatedAt!);
    if (age.inMinutes >= 13) {
      print('🔍 Token is close to expiration, validating...');
      final isValid = await validateToken();
      if (!isValid) {
        print('🔄 Token validation failed, re-authenticating...');
      await authenticate();
      }
    }
    // Otherwise, assume token is valid and skip validation to avoid unnecessary API calls
  }

  Future<bool> authenticate() async {
    try {
      final credentials = base64Encode(utf8.encode('$username:$password'));
      final url = '$baseUrl/databases/$database/sessions';
      
      print('🔐 Attempting authentication to: $url');
      print('🔐 Database: $database');
      print('🔐 Username: $username');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $credentials',
          'Accept': 'application/json',
        },
      );


      print('🔐 Response status: ${response.statusCode}');
      print('🔐 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['response']['token'];
        _isAuthenticated = true;
        _tokenCreatedAt = DateTime.now(); // Track when token was created
        
        print('✅ FileMaker authentication successful');
        print('📋 FileMaker token set: ${_token?.substring(0, 20) ?? "null"}...');
        print('📋 FileMaker token length: ${_token?.length ?? 0}');
        print('⏰ Token created at: $_tokenCreatedAt');
        
        // Set Authorization header for Dio instance
        _dio.options.headers['Authorization'] = 'Bearer $_token';
        
        // Store token and timestamp for future use
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('filemaker_token', _token!);
          await prefs.setString('filemaker_token_created_at', _tokenCreatedAt!.toIso8601String());
          print('✅ FileMaker token stored in SharedPreferences');
        } catch (e) {
          print('⚠️ Error storing FileMaker token: $e');
          // Ignore storage errors in web
        }
        
        notifyListeners();
        // Add delay to ensure token is fully processed
        await Future.delayed(const Duration(milliseconds: 500));
        return true;
      } else {
        print('Authentication failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Authentication error: $e');
    }
    return false;
  }


  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
    'Accept': 'application/json',
    'Cache-Control': 'no-cache',
  };

  void _logHeaders() {
  }

  // Helper method to make HTTP requests with automatic token refresh
  Future<http.Response> _makeHttpRequestWithRetry(
    String method,
    Uri url,
    Map<String, String> headers,
    String? body,
  ) async {
    // First attempt
    http.Response response;
    if (method == 'POST') {
      response = await http.post(url, headers: headers, body: body);
    } else if (method == 'PATCH') {
      response = await http.patch(url, headers: headers, body: body);
    } else if (method == 'DELETE') {
      response = await http.delete(url, headers: headers);
    } else {
      response = await http.get(url, headers: headers);
    }

    // If token expired, refresh and retry
    if (response.statusCode == 401) {
      print('🔄 HTTP request failed with 401, refreshing token...');
      final refreshed = await authenticate();
      if (refreshed) {
        print('✅ Token refreshed, retrying HTTP request...');
        // Update headers with new token
        final newHeaders = Map<String, String>.from(headers);
        newHeaders['Authorization'] = 'Bearer $_token';
        
        // Retry the request
        if (method == 'POST') {
          response = await http.post(url, headers: newHeaders, body: body);
        } else if (method == 'PATCH') {
          response = await http.patch(url, headers: newHeaders, body: body);
        } else if (method == 'DELETE') {
          response = await http.delete(url, headers: newHeaders);
        } else {
          response = await http.get(url, headers: newHeaders);
        }
      }
    }

    return response;
  }

  // Client operations
  Future<List<Client>> getClients() async {
    await _ensureAuthenticated();
    
    // Use company filter from session
    final companyId = _currentCompanyId;
    if (companyId == null) {
      throw Exception('No company ID available. Please login first.');
    }
    
    final query = {
      'query': [
        {'Company': '==$companyId'},
      ],
    };

    

    try {
      final response = await _dio.post(
        '/databases/$database/layouts/api_patients_list/_find',
        data: query,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
            'Cache-Control': 'no-cache',
          },
        ),
      );


      // FileMaker response analysis
      final data = response.data as Map<String, dynamic>;
      final msgs = (data['messages'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final code = msgs.isNotEmpty ? '${msgs.first['code']}' : null;
      final msg = msgs.isNotEmpty ? '${msgs.first['message']}' : null;


      // FileMaker "OK"
      if (code == '0') {
        final records = (data['response']?['data'] as List?) ?? const [];
        
        print('🔍 FileMaker getClients Response:');
        print('📊 Total records found: ${records.length}');
        print('📋 Full response data: ${jsonEncode(data)}');
        
        // Check what records we're getting
        if (records.isNotEmpty) {
          print('👥 First client record: ${jsonEncode(records.first)}');
          
          // Show all clients that will appear in dropdown
          for (int i = 0; i < records.length; i++) {
            final client = records[i]['fieldData'];
            print('👤 Client $i: ${jsonEncode(client)}');
          }
          
          
          // Check if all records have the same company and status
          final allCompanies = records.map((r) => r['fieldData']['Company']).toSet();
          final allStatuses = records.map((r) => r['fieldData']['Status']).toSet();
          print('🏢 All companies: $allCompanies');
          print('📊 All statuses: $allStatuses');
        }
        
        // Filter to only Active clients on the client side with robust error handling
        final activeClients = <Client>[];
        
        for (int i = 0; i < records.length; i++) {
          try {
            final record = records[i];
            final fieldData = record['fieldData'] as Map<String, dynamic>;
            
            // Only process Active clients
            if (fieldData['Status'] == 'Active') {
              final client = Client.fromJson(fieldData);
              activeClients.add(client);
            }
          } catch (e) {
            // Continue processing other clients instead of failing completely
            continue;
          }
        }
            
        
        return activeClients;
      }

      // FileMaker "no records match"
      if (code == '401') {
        return [];
      }

      // Any other FM error
      throw Exception('FileMaker error $code: $msg');

    } catch (e) {
      if (e is DioException) {
      }
      rethrow;
    }
  }

  // Staff operations
  Future<Staff?> getStaffByEmail(String email) async {
    await _ensureAuthenticated();

    final query = {
      'query': [
        {'email': '==${email.trim()}'},
      ],
      'limit': 1
    };


    try {
      final response = await _dio.post(
        '/databases/$database/layouts/api_staffs/_find',
        data: query,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
            'Cache-Control': 'no-cache',
          },
        ),
      );


      // FileMaker response analysis
      final data = response.data as Map<String, dynamic>;
      final msgs = (data['messages'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final code = msgs.isNotEmpty ? '${msgs.first['code']}' : null;
      final msg = msgs.isNotEmpty ? '${msgs.first['message']}' : null;


      // FileMaker "OK"
      if (code == '0') {
        final records = (data['response']?['data'] as List?) ?? const [];
        
        print('🔍 FileMaker getStaffByEmail Response:');
        print('📊 Total staff records found: ${records.length}');
        print('📋 Full response data: ${jsonEncode(data)}');
        
        if (records.isNotEmpty) {
          print('👤 Staff record: ${jsonEncode(records.first)}');
        }

        if (records.isEmpty) return null;
        final fieldData = (records.first['fieldData'] as Map<String, dynamic>)..removeWhere((k, v) => v == null);
        
        // Store session global variables
        _currentStaffId = fieldData['PrimaryKey']?.toString();
        _currentCompanyId = fieldData['Company']?.toString();
        _currentStaffName = fieldData['FullName']?.toString();
        _currentStaffEmail = fieldData['email']?.toString() ?? fieldData['Username']?.toString();
        _currentStaffCanManualEntry = fieldData['Allow_manual_entry'] == 1 || fieldData['Allow_manual_entry'] == '1';
        
        try {
          return Staff.fromJson(fieldData);
        } catch (e) {
          print('Error parsing staff data: $e');
          print('Field data: $fieldData');
          rethrow;
        }
      }

      // FileMaker "no records match"
      if (code == '401') {
        return null;
      }

      // Any other FM error
      throw Exception('FileMaker error $code: $msg');

    } catch (e) {
      if (e is DioException) {
      }
      rethrow;
    }
  }


  // Visit operations
  Future<Visit> createVisit(Visit visit) async {
    await _ensureAuthenticated();
    
    // Add required fields for api_appointments layout
    final visitData = visit.toJson();
    visitData['Appointment_date'] = '${visit.startTs.month.toString().padLeft(2, '0')}/${visit.startTs.day.toString().padLeft(2, '0')}/${visit.startTs.year}';
    visitData['start_ts'] = visit.startTs.toIso8601String().split('.')[0];
    
    // Add company ID if available
    if (_currentCompanyId != null) {
      visitData['Company'] = _currentCompanyId;
    }
    
    _logHeaders();
    
    final requestBody = json.encode({
      'fieldData': visitData,
    });
    
    // Try with explicit content-length header
    final headers = Map<String, String>.from(_headers);
    headers['Content-Length'] = requestBody.length.toString();
    
    
    final response = await _makeHttpRequestWithRetry(
      'POST',
      Uri.parse('$baseUrl/databases/$database/layouts/api_appointments/records'),
      headers,
      requestBody,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      final recordId = data['response']['recordId'];
      return visit.copyWith(id: recordId);
    }
    throw Exception('Failed to create visit: ${response.statusCode} - ${response.body}');
  }

  /// Helper function to format timestamp as MM/DD/YYYY HH:MM:SS AM/PM (e.g., "11/17/2025 12:54:41 AM")
  String _formatLocalTimestamp(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour12 = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final hour = hour12.toString().padLeft(2, '0'); // 2-digit hour with leading zero
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day/$year $hour:$minute:$second $amPm';
  }

  // Alternative createVisit method using Dio
  Future<Visit> createVisitWithDio(Visit visit, {bool skipLocation = false}) async {
    await _ensureAuthenticated();
    
    // Add required fields for api_appointments layout
    final visitData = visit.toJson();
    visitData['Appointment_date'] = '${visit.startTs.month.toString().padLeft(2, '0')}/${visit.startTs.day.toString().padLeft(2, '0')}/${visit.startTs.year}';
    visitData['start_ts'] = visit.startTs.toIso8601String().split('.')[0];
    
    // Format time_in from startTs (HH:MM:SS format)
    final timeIn = '${visit.startTs.hour.toString().padLeft(2, '0')}:${visit.startTs.minute.toString().padLeft(2, '0')}:${visit.startTs.second.toString().padLeft(2, '0')}';
    visitData['time_in'] = timeIn;
    
    // Format time_out from endTs if provided (HH:MM:SS format)
    if (visit.endTs != null) {
      final timeOut = '${visit.endTs!.hour.toString().padLeft(2, '0')}:${visit.endTs!.minute.toString().padLeft(2, '0')}:${visit.endTs!.second.toString().padLeft(2, '0')}';
      visitData['time_out'] = timeOut;
    }
    
    // Add company ID if available
    if (_currentCompanyId != null) {
      visitData['Company'] = _currentCompanyId;
    }
    
    visitData['update_flagx'] = 5; // Trigger processing in FileMaker
    
    // Get current location for start (skip for manual entries)
    if (!skipLocation) {
      final location = await LocationService.getCurrentLocation();
      if (location != null) {
        visitData['start_latitude'] = location['latitude']!;
        visitData['start_longitude'] = location['longitude']!;
        visitData['start_location_accuracy'] = location['accuracy']!;
      } else {
        visitData['start_latitude'] = '0.0';
        visitData['start_longitude'] = '0.0';
        visitData['start_location_accuracy'] = '0.0';
      }
    } else {
      visitData['start_latitude'] = '0.0';
      visitData['start_longitude'] = '0.0';
      visitData['start_location_accuracy'] = '0.0';
    }
    
    // Get device IP address
    final ipAddress = await IPService.getDeviceIPAddress();
    visitData['submitterIPAddress'] = ipAddress ?? 'unknown';
    
    // Add creation metadata
    // NOTE: These fields must exist in the api_appointments layout in FileMaker
    // If you get field errors, these fields may not exist in the layout
    // Use email if available, otherwise fall back to username or staff name
    if (_currentStaffEmail != null || _currentStaffName != null) {
      final createdBy = _currentStaffEmail ?? _currentStaffName ?? 'unknown';
      visitData['create_by'] = createdBy;
      visitData['modified_by'] = createdBy; // Set modified_by same as create_by on creation
      print('📝 Adding create_by: $createdBy');
      print('📝 Adding modified_by: $createdBy');
    } else {
      print('⚠️ No staff email or name available for create_by field');
    }
    
    // Add creation timestamp in format: MM/DD/YYYY HH:MM:SS AM/PM (e.g., "11/17/2025 12:54:41 AM")
    final now = DateTime.now();
    final timestamp = _formatLocalTimestamp(now);
    
    visitData['Local_CreationTimestamp'] = timestamp;
    visitData['Local_ModificationTimestamp'] = timestamp;
    print('📝 Adding Local_CreationTimestamp: ${visitData['Local_CreationTimestamp']}');
    print('📝 Adding Local_ModificationTimestamp: ${visitData['Local_ModificationTimestamp']}');
    
    print('📋 Full visitData keys before sending: ${visitData.keys.toList()}');
    
    try {
      print('📤 Sending POST request to create visit...');
      final response = await _dio.post(
        '/databases/$database/layouts/api_appointments/records',
        data: {'fieldData': visitData},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
            'Cache-Control': 'no-cache',
          },
        ),
      );

      print('📥 Response status code: ${response.statusCode}');
      print('📥 Response data type: ${response.data.runtimeType}');
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        print('📥 Response keys: ${data.keys.toList()}');
        
        if (data.containsKey('response')) {
          final responseData = data['response'];
          if (responseData is Map<String, dynamic>) {
            print('📥 Response data keys: ${responseData.keys.toList()}');
          }
        }
        if (data.containsKey('messages')) {
          final messages = data['messages'] as List?;
          print('📥 Messages count: ${messages?.length ?? 0}');
          if (messages != null && messages.isNotEmpty) {
            print('📥 First message: ${messages.first}');
          }
        }
      } else {
        print('📥 Response data: ${response.data}');
      }

      // Check for errors in response
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('messages')) {
          final messages = data['messages'] as List?;
          if (messages != null && messages.isNotEmpty) {
            final firstMessage = messages.first as Map<String, dynamic>;
            final code = firstMessage['code']?.toString();
            final message = firstMessage['message']?.toString();
            
            // Check if error is related to invalid field names
            if (code != '0' && code != null) {
              print('❌ FileMaker error code: $code');
              print('❌ FileMaker error message: $message');
              
              // If error is about invalid field, try without the new fields
              if (message?.toLowerCase().contains('field') == true || 
                  message?.toLowerCase().contains('invalid') == true) {
                print('⚠️ Possible field name issue. Fields we added: create_by, modified_by, Local_CreationTimestamp, Local_ModificationTimestamp');
                print('⚠️ Check if these fields exist in the api_appointments layout');
              }
            }
          }
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final recordId = response.data['response']['recordId'];
        
        // Now fetch the PrimaryKey using the recordId
        final findResponse = await _dio.post(
          '/databases/$database/layouts/api_appointments/_find',
          data: {
            'query': [
              {'recordId': '==$recordId'}
            ]
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
              'Accept': 'application/json',
            },
          ),
        );
        
        
        if (findResponse.statusCode == 200) {
          final findData = findResponse.data as Map<String, dynamic>;
          if (findData['response']['data'] != null && 
              (findData['response']['data'] as List).isNotEmpty) {
            final recordData = (findData['response']['data'] as List).first;
            final primaryKey = recordData['fieldData']['PrimaryKey'];
            
            final updatedVisit = visit.copyWith(id: primaryKey);
            return updatedVisit;
          }
        }
        
        // Fallback to recordId if PrimaryKey not found
        final updatedVisit = visit.copyWith(id: recordId.toString());
        return updatedVisit;
      }
      print('❌ Failed to create visit. Status: ${response.statusCode}');
      print('❌ Response data: ${response.data}');
      throw Exception('Failed to create visit with Dio: ${response.statusCode} - ${response.data}');
    } catch (e) {
      print('❌ Exception in createVisitWithDio: $e');
      print('❌ Exception type: ${e.runtimeType}');
      if (e is DioException) {
        print('❌ DioException response: ${e.response?.data}');
        print('❌ DioException status: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  /// Update visit notes in FileMaker
  /// Save notes to the dapi-api-notes layout (separate from visit record)
  Future<void> saveNoteToNotesLayout(String visitId, String notes) async {
    await _ensureAuthenticated();
    
    try {
      final modifiedBy = _currentStaffEmail ?? _currentStaffName ?? 'unknown';
      final now = DateTime.now();
      
      // Get device IP address
      final ipAddress = await IPService.getDeviceIPAddress();
      
      // Create note record in dapi-api-notes layout
      // appID links the note to the visit (appID=visitId)
      // Only include fields that exist in the dapi-api-notes layout
      final noteData = <String, dynamic>{
        'appID': visitId,  // Links the note to the visit (confirmed exists)
        'appNotes': notes.trim(),  // The actual note content
      };
      
      // Try to add optional fields - if they don't exist, FileMaker will ignore them
      // But we'll catch the error and retry without them if needed
      try {
        // Add these fields one at a time to identify which one is missing
        noteData['create_by'] = modifiedBy;
        noteData['modified_by'] = modifiedBy;
        noteData['Local_CreationTimestamp'] = _formatLocalTimestamp(now);
        noteData['Local_ModificationTimestamp'] = _formatLocalTimestamp(now);
        noteData['submitterIPAddress'] = ipAddress ?? 'unknown';
      } catch (e) {
        print('⚠️ Error adding optional fields: $e');
      }
      
      print('📝 Saving note to dapi-api-notes layout for visit: $visitId');
      print('📝 Note data: ${jsonEncode(noteData)}');
      
      try {
        final createResponse = await _dio.post(
          '/databases/$database/layouts/dapi-api-notes/records',
          data: {'fieldData': noteData},
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
              'Accept': 'application/json',
            },
          ),
        );
        
        if (createResponse.statusCode == 200 || createResponse.statusCode == 201) {
          print('✅ Note saved successfully to dapi-api-notes layout for visit: $visitId');
          print('📋 Response: ${jsonEncode(createResponse.data)}');
          return;
        } else {
          print('❌ Failed to save note: ${createResponse.statusCode}');
          print('❌ Response: ${jsonEncode(createResponse.data)}');
          throw Exception('Failed to save note: ${createResponse.statusCode}');
        }
      } on DioException catch (e) {
        print('❌ DioException when saving note:');
        print('   Status code: ${e.response?.statusCode}');
        print('   Response data: ${e.response?.data}');
        print('   Request data: ${jsonEncode(noteData)}');
        
        // Try to extract FileMaker error messages
        if (e.response?.data != null) {
          final responseData = e.response!.data;
          if (responseData is Map && responseData['messages'] != null) {
            final messages = responseData['messages'] as List;
            for (var msg in messages) {
              print('   FileMaker Error: ${msg['code']} - ${msg['message']}');
            }
            
            // If error is "Field is missing", try with minimal fields
            final firstMessage = messages.isNotEmpty ? messages[0] : null;
            if (firstMessage != null && firstMessage['code'] == 102) {
              print('⚠️ Field is missing error - trying with minimal fields (appID and appNotes only)...');
              final minimalNoteData = {
                'appID': visitId,
                'appNotes': notes.trim(),
              };
              
              try {
                final retryResponse = await _dio.post(
                  '/databases/$database/layouts/dapi-api-notes/records',
                  data: {'fieldData': minimalNoteData},
                  options: Options(
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $_token',
                      'Accept': 'application/json',
                    },
                  ),
                );
                
                if (retryResponse.statusCode == 200 || retryResponse.statusCode == 201) {
                  print('✅ Note saved successfully with minimal fields');
                  return;
                }
              } catch (retryError) {
                print('❌ Retry with minimal fields also failed: $retryError');
              }
            }
          }
        }
        
        rethrow;
      }
    } catch (e) {
      print('❌ Error saving note to dapi-api-notes layout: $e');
      rethrow;
    }
  }

  /// Preserves existing template in visit_notes field and appends generated notes
  /// NOTE: This method is kept for backward compatibility, but new notes should use saveNoteToNotesLayout
  Future<void> updateVisitNotes(String visitId, String notes) async {
    await _ensureAuthenticated();
    
    try {
      // First, find the recordId using the PrimaryKey
      final findResponse = await _dio.post(
        '/databases/$database/layouts/api_appointments/_find',
        data: {
          'query': [
            {'PrimaryKey': '==$visitId'}
          ]
        },
      );
      
      if (findResponse.statusCode == 200) {
        final data = findResponse.data['response']['data'] as List<dynamic>? ?? [];
        if (data.isNotEmpty) {
          final recordId = data[0]['recordId']?.toString();
          if (recordId != null) {
            // Get existing visit_notes (which contains the template)
            final fieldData = data[0]['fieldData'] as Map<String, dynamic>? ?? {};
            final existingNotes = fieldData['visit_notes']?.toString() ?? '';
            
            // Combine existing template with new notes
            // If template exists, append new notes to it; otherwise use new notes as-is
            String finalNotes;
            if (existingNotes.trim().isNotEmpty) {
              // Template exists - append generated notes
              finalNotes = '${existingNotes.trim()}\n\n${notes.trim()}';
            } else {
              // No template - use generated notes as-is
              finalNotes = notes.trim();
            }
            
            print('📝 Existing template length: ${existingNotes.length}');
            print('📝 Final notes length: ${finalNotes.length}');
            
            // Update the visit with combined notes
            final modifiedBy = _currentStaffEmail ?? _currentStaffName ?? 'unknown';
            final updateData = {
              'visit_notes': finalNotes,
              'update_flagx': 6, // Custom flag for notes update
              'modified_by': modifiedBy,
              'Local_ModificationTimestamp': _formatLocalTimestamp(DateTime.now()),
            };
            
            final updateResponse = await _dio.patch(
              '/databases/$database/layouts/api_appointments/records/$recordId',
              data: {'fieldData': updateData},
            );
            
            if (updateResponse.statusCode == 200) {
              print('✅ Visit notes updated successfully for visit: $visitId');
            } else {
              print('❌ Failed to update visit notes: ${updateResponse.statusCode}');
              throw Exception('Failed to update visit notes: ${updateResponse.statusCode}');
            }
          } else {
            throw Exception('Record ID not found for visit: $visitId');
          }
        } else {
          throw Exception('Visit not found: $visitId');
        }
      } else {
        throw Exception('Failed to find visit: ${findResponse.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating visit notes: $e');
      rethrow;
    }
  }

  Future<Visit> updateVisit(Visit visit) async {
    await _ensureAuthenticated();
    
    // First, find the recordId using the PrimaryKey
    final findResponse = await _dio.post(
      '/databases/$database/layouts/api_appointments/_find',
      data: {
        'query': [
          {'PrimaryKey': '==${visit.id}'}
        ]
      },
    );
    
    if (findResponse.statusCode == 200) {
      final data = findResponse.data['response']['data'] as List<dynamic>? ?? [];
      if (data.isNotEmpty) {
        final recordId = data[0]['recordId']?.toString();
        if (recordId != null) {
          // Update the visit with current timestamp and status
          final updateData = visit.toJson();
          updateData['start_ts'] = DateTime.now().toIso8601String().split('.')[0];
          updateData['statusInput'] = 'in_progress';
          updateData['update_flagx'] = 5; // Trigger processing in FileMaker
          updateData['modified_by'] = _currentStaffEmail ?? _currentStaffName ?? 'unknown';
          updateData['Local_ModificationTimestamp'] = _formatLocalTimestamp(DateTime.now());
          
          // Get current location for start
          final location = await LocationService.getCurrentLocation();
          if (location != null) {
            updateData['start_latitude'] = location['latitude']!;
            updateData['start_longitude'] = location['longitude']!;
            updateData['start_location_accuracy'] = location['accuracy']!;
          } else {
            updateData['start_latitude'] = '0.0';
            updateData['start_longitude'] = '0.0';
            updateData['start_location_accuracy'] = '0.0';
          }
          
          // Get device IP address
          final ipAddress = await IPService.getDeviceIPAddress();
          updateData['submitterIPAddress'] = ipAddress ?? 'unknown';
          
          final response = await _dio.patch(
            '/databases/$database/layouts/api_appointments/records/$recordId',
            data: {
              'fieldData': updateData,
            },
          );
          
          if (response.statusCode == 200) {
            return visit;
          }
        }
      }
    }
    throw Exception('Failed to update visit: ${findResponse.statusCode}');
  }

  Future<Map<String, dynamic>> closeVisit(String visitId, DateTime endTs) async {
    await _ensureAuthenticated();
    
    
    try {
      // First, find the recordId using the PrimaryKey
      final findResponse = await _dio.post(
        '/databases/$database/layouts/api_appointments/_find',
        data: {
          'query': [
            {'PrimaryKey': '==$visitId'}
          ]
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ),
      );
      
      if (findResponse.statusCode != 200) {
        throw Exception('Failed to find visit record: ${findResponse.statusCode}');
      }
      
      final findData = findResponse.data as Map<String, dynamic>;
      if (findData['response']['data'] == null || 
          (findData['response']['data'] as List).isEmpty) {
        throw Exception('Visit record not found');
      }
      
      final recordData = (findData['response']['data'] as List).first;
      final recordId = recordData['recordId'];
      
      // Get current location for end
      final location = await LocationService.getCurrentLocation();
      String endLatitude = '0.0';
      String endLongitude = '0.0';
      String endAccuracy = '0.0';
      
      if (location != null) {
        endLatitude = location['latitude']!;
        endLongitude = location['longitude']!;
        endAccuracy = location['accuracy']!;
      } else {
      }

      // Format time_out from endTs (HH:MM:SS format)
      final timeOut = '${endTs.hour.toString().padLeft(2, '0')}:${endTs.minute.toString().padLeft(2, '0')}:${endTs.second.toString().padLeft(2, '0')}';
      
      // Now update using the recordId
      final modifiedBy = _currentStaffEmail ?? _currentStaffName ?? 'unknown';
      final updateData = {
        'end_ts': endTs.toIso8601String().split('.')[0],
        'time_out': timeOut,          // Save time_out formatted from endTs
        'status': 'Submitted',        // Update both status fields
        'statusInput': 'Submitted',   // This appears to be the main status field
        'update_flagx': 3, // Trigger processing in FileMaker for session end
        'end_latitude': endLatitude,
        'end_longitude': endLongitude,
        'end_location_accuracy': endAccuracy,
        'modified_by': modifiedBy,
        'Local_ModificationTimestamp': _formatLocalTimestamp(DateTime.now()),
      };
      
      print('🔚 Closing visit: $visitId');
      print('📊 Update data: ${jsonEncode(updateData)}');
      
      final response = await _dio.patch(
        '/databases/$database/layouts/api_appointments/records/$recordId',
        data: {
          'fieldData': updateData,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ),
      );


      if (response.statusCode == 200) {
        print('✅ Visit closed successfully: $visitId');
        print('📋 Response: ${jsonEncode(response.data)}');
        return response.data['response'] ?? {};
      }
      
      throw Exception('Failed to close visit: ${response.statusCode}');
      
    } catch (e) {
      if (e is DioException) {
      }
      rethrow;
    }
  }

  /// Cancel a visit - sets statusInput to "Cancelled" and deleted_at to current timestamp
  Future<void> cancelVisit(String visitId) async {
    await _ensureAuthenticated();
    
    try {
      // First, find the recordId using the PrimaryKey
      final findResponse = await _dio.post(
        '/databases/$database/layouts/api_appointments/_find',
        data: {
          'query': [
            {'PrimaryKey': '==$visitId'}
          ]
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ),
      );
      
      if (findResponse.statusCode != 200) {
        throw Exception('Failed to find visit record: ${findResponse.statusCode}');
      }
      
      final findData = findResponse.data as Map<String, dynamic>;
      if (findData['response']['data'] == null || 
          (findData['response']['data'] as List).isEmpty) {
        throw Exception('Visit record not found');
      }
      
      final recordData = (findData['response']['data'] as List).first;
      final recordId = recordData['recordId'];
      
      // Set statusInput to "Cancelled", deleted_at to current timestamp, and update_flagx = 3
      final now = DateTime.now();
      final updateData = {
        'statusInput': 'Cancelled',
        'deleted_at': now.toIso8601String().split('.')[0],
        'update_flagx': 3,
      };
      
      print('❌ Cancelling visit: $visitId');
      print('📊 Update data: ${jsonEncode(updateData)}');
      
      final response = await _dio.patch(
        '/databases/$database/layouts/api_appointments/records/$recordId',
        data: {
          'fieldData': updateData,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        print('✅ Visit cancelled successfully: $visitId');
      } else {
        throw Exception('Failed to cancel visit: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException) {
        print('❌ DioException when cancelling visit: ${e.message}');
      }
      rethrow;
    }
  }

  /// Update visit end_ts without closing the visit
  Future<void> updateVisitEndTs(String visitId, DateTime endTs) async {
    await _ensureAuthenticated();
    
    try {
      // First, find the recordId using the PrimaryKey
      final findResponse = await _dio.post(
        '/databases/$database/layouts/api_appointments/_find',
        data: {
          'query': [
            {'PrimaryKey': '==$visitId'}
          ]
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ),
      );
      
      if (findResponse.statusCode != 200) {
        throw Exception('Failed to find visit record: ${findResponse.statusCode}');
      }
      
      final findData = findResponse.data as Map<String, dynamic>;
      if (findData['response']['data'] == null || 
          (findData['response']['data'] as List).isEmpty) {
        throw Exception('Visit record not found');
      }
      
      final recordData = (findData['response']['data'] as List).first;
      final recordId = recordData['recordId'];
      
      // Format time_out from endTs (HH:MM:SS format)
      final timeOut = '${endTs.hour.toString().padLeft(2, '0')}:${endTs.minute.toString().padLeft(2, '0')}:${endTs.second.toString().padLeft(2, '0')}';
      
      // Update end_ts and time_out
      final modifiedBy = _currentStaffEmail ?? _currentStaffName ?? 'unknown';
      final updateData = {
        'end_ts': endTs.toIso8601String().split('.')[0],
        'time_out': timeOut,  // Save time_out formatted from endTs
        'modified_by': modifiedBy,
        'Local_ModificationTimestamp': _formatLocalTimestamp(DateTime.now()),
      };
      
      print('⏰ Updating visit end_ts: $visitId');
      print('📊 Update data: ${jsonEncode(updateData)}');
      
      final response = await _dio.patch(
        '/databases/$database/layouts/api_appointments/records/$recordId',
        data: {
          'fieldData': updateData,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        print('✅ Visit end_ts updated successfully: $visitId');
      } else {
        throw Exception('Failed to update visit end_ts: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException) {
        print('❌ DioException when updating visit end_ts: ${e.message}');
      }
      rethrow;
    }
  }

  // Program Assignment operations
  Future<List<ProgramAssignment>> getProgramAssignments(String clientId, {String? ltgId}) async {
    await _ensureAuthenticated();
    
    // Use FileMaker's _find endpoint to filter by clientId on the server
    final query = {
      'query': [
        {'clientId': '==$clientId'},
        if (ltgId != null) {'ltgId': '==$ltgId'},
      ],
    };


    try {
      final response = await _dio.post(
        '/databases/$database/layouts/dapi-patient_programs/_find',
        data: query,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
            'Cache-Control': 'no-cache',
          },
        ),
      );


      final data = response.data as Map<String, dynamic>;
      final msgs = (data['messages'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final code = msgs.isNotEmpty ? '${msgs.first['code']}' : null;
      final msg = msgs.isNotEmpty ? '${msgs.first['message']}' : null;


      // FileMaker "OK"
      if (code == '0') {
        final records = (data['response']?['data'] as List?) ?? const [];
        
        // Check what data we're getting
        if (records.isNotEmpty) {
          
          // Check each field for null values (using FileMaker field names)
          
          // Check for FileMaker field name variations
        }
        
        // Parse records with error handling
        final assignments = <ProgramAssignment>[];
        for (int i = 0; i < records.length; i++) {
          try {
            final fieldData = records[i]['fieldData'];
            
            final assignment = ProgramAssignment.fromJson(fieldData);
            assignments.add(assignment);
          } catch (e) {
            // Continue with other assignments
          }
        }
        
        return assignments;
      }

      // FileMaker "no records match"
      if (code == '401') {
        return [];
      }

      throw Exception('FileMaker error $code: $msg');

    } catch (e) {
      if (e is DioException) {
      }
      rethrow;
    }
  }

  // Session Data operations
  Future<SessionRecord> upsertSessionRecord(SessionRecord record) async {
    await _ensureAuthenticated();
    
    try {
      print('💾 Upserting session record for visitId: ${record.visitId}, assignmentId: ${record.assignmentId}');
      
      // First, try to find existing record with same visitId and assignmentId
      final existingRecord = await findExistingSessionRecord(record.visitId, record.assignmentId);
      
      if (existingRecord != null) {
        print('🔄 Updating existing record: ${existingRecord.id}');
        // Update existing record
        return await _updateSessionRecord(existingRecord.id, record);
      } else {
        print('➕ Creating new record');
        // Create new record
        return await _createSessionRecord(record);
      }
      
    } catch (e) {
      print('❌ Error in upsertSessionRecord: $e');
      if (e is DioException) {
      }
      rethrow;
    }
  }

  // Update existing session record
  Future<SessionRecord> updateSessionRecord(SessionRecord record) async {
    await _ensureAuthenticated();
    
    // Add program times to payload (without milliseconds)
    final payloadWithTimes = Map<String, dynamic>.from(record.payload);
    if (record.programStartTime != null) {
      payloadWithTimes['program_start_time'] = record.programStartTime!.toIso8601String().split('.')[0];
    }
    if (record.programEndTime != null) {
      payloadWithTimes['program_end_time'] = record.programEndTime!.toIso8601String().split('.')[0];
    }

      final now = DateTime.now();
      final nowString = now.toIso8601String().split('.')[0];
      
      final sessionData = {
        'fieldData': {
        'visitId': record.visitId,
          'clientId': record.clientId,
          'assignmentId': record.assignmentId,
          'Company': record.company ?? _currentCompanyId ?? '',
          'startedAt_ts': record.startedAt?.toIso8601String().split('.')[0] ?? nowString,
          'updatedAt_ts': record.updatedAt?.toIso8601String().split('.')[0] ?? nowString,
        'payload_json': jsonEncode(payloadWithTimes),
          'staffId': record.staffId ?? '',
        'notes': record.notes ?? '',
        'intervention_phase': record.interventionPhase ?? 'baseline',
        'program_start_time': record.programStartTime?.toIso8601String().split('.')[0],
        'program_end_time': record.programEndTime?.toIso8601String().split('.')[0],
      }
    };
    
    print('🔍 Updating session record with data: ${jsonEncode(sessionData)}');
    
    final updateResponse = await _dio.patch(
      '/databases/$database/layouts/dapi-api_sessiondata/records/${record.id}',
      data: sessionData,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
        },
      ),
    );

    if (updateResponse.statusCode == 200) {
      return record;
    }
    
    print('❌ Failed to update session record: ${updateResponse.statusCode}');
    print('❌ Response data: ${updateResponse.data}');
    throw Exception('Failed to update session record: ${updateResponse.statusCode} - ${updateResponse.data}');
  }

  // Find existing session record by visitId and assignmentId
  Future<SessionRecord?> findExistingSessionRecord(String visitId, String assignmentId) async {
    try {
      print('🔍 Searching for existing record with visitId: $visitId, assignmentId: $assignmentId');
      
      // Search by visitId only (since assignmentId field might not be searchable)
      // Then filter by assignmentId in code
      final response = await _dio.post(
        '/databases/$database/layouts/dapi-api_sessiondata/_find',
        data: {
          'query': [
            {
              'visitId': '==$visitId',
            }
          ],
          'limit': 100  // Get all records for this visit, then filter
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('🔍 Search response status: ${response.statusCode}');
      print('🔍 Search response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final records = data['response']['data'] as List<dynamic>?;
        
        print('🔍 Found ${records?.length ?? 0} records for visitId');
        
        if (records != null && records.isNotEmpty) {
          // Filter by assignmentId in code since FileMaker search might not work for that field
          for (final recordData in records) {
            final fieldData = recordData['fieldData'] as Map<String, dynamic>;
            final recordAssignmentId = fieldData['assignmentId']?.toString() ?? '';
            
            print('🔍 Checking record ${recordData['recordId']} with assignmentId: "$recordAssignmentId"');
            
            if (recordAssignmentId == assignmentId) {
              print('✅ Found matching record: ${recordData['recordId']}');
              print('📋 Retrieved assignmentId from FileMaker: "$recordAssignmentId"');
              
              return SessionRecord(
                id: recordData['recordId'].toString(),
                visitId: fieldData['visitId'] ?? '',
                clientId: fieldData['clientId'] ?? '',
                assignmentId: recordAssignmentId,
                startedAt: fieldData['startedAt_ts'] != null 
                    ? DateTime.parse(fieldData['startedAt_ts']) 
                    : null,
                updatedAt: DateTime.now(),
                payload: fieldData['payload_json'] != null 
                    ? jsonDecode(fieldData['payload_json']) 
                    : {},
                staffId: fieldData['staffId'],
                notes: fieldData['notes'],
                interventionPhase: fieldData['intervention_phase'],
                company: fieldData['Company']?.toString(),
              );
            }
          }
          print('⚠️ Found ${records.length} records for visitId but none match assignmentId: $assignmentId');
        }
      }
      
      print('🔍 No existing record found');
      return null;
    } catch (e) {
      print('🔍 Error searching for existing record: $e');
      // If no records found or error, return null
      return null;
    }
  }

  // Create new session record
  Future<SessionRecord> _createSessionRecord(SessionRecord record) async {
    // Add program times to payload (without milliseconds)
    final payloadWithTimes = Map<String, dynamic>.from(record.payload);
    if (record.programStartTime != null) {
      payloadWithTimes['program_start_time'] = record.programStartTime!.toIso8601String().split('.')[0];
    }
    if (record.programEndTime != null) {
      payloadWithTimes['program_end_time'] = record.programEndTime!.toIso8601String().split('.')[0];
    }

    final now = DateTime.now();
    final nowString = now.toIso8601String().split('.')[0];

    // Build fieldData exactly matching behavior log pattern that works
    // Store all session-specific data in payload_json (like behavior logs do with behavior data)
    print('📋 SessionRecord assignmentId value: "${record.assignmentId}" (length: ${record.assignmentId.length})');
    print('📋 SessionRecord assignmentId isEmpty: ${record.assignmentId.isEmpty}');
    
    final fieldData = <String, dynamic>{
      'visitId': record.visitId,
      'clientId': record.clientId,
      'assignmentId': record.assignmentId,
      'payload_json': jsonEncode(payloadWithTimes),
      'staffId': record.staffId ?? '',
      'startedAt_ts': record.startedAt?.toIso8601String().split('.')[0] ?? nowString,
      'updatedAt_ts': record.updatedAt?.toIso8601String().split('.')[0] ?? nowString,
    };
    
    // Add intervention_phase if provided (only if it has a value to avoid empty string issues)
    if (record.interventionPhase != null && record.interventionPhase!.isNotEmpty) {
      fieldData['intervention_phase'] = record.interventionPhase;
    }

    final sessionData = {
      'fieldData': fieldData,
    };
    
    print('🔍 Creating session record with data: ${jsonEncode(sessionData)}');
    
    try {
      final createResponse = await _dio.post(
        '/databases/$database/layouts/dapi-api_sessiondata/records',
        data: sessionData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
            'Cache-Control': 'no-cache',
          },
        ),
      );

      if (createResponse.statusCode == 200 || createResponse.statusCode == 201) {
        final data = createResponse.data as Map<String, dynamic>;
        final recordId = data['response']['recordId'];
        print('✅ Successfully created session record: $recordId');
        
        // Verify what FileMaker actually saved by fetching the record back
        print('🔍 Verifying saved assignmentId by fetching record...');
        try {
          final verifyResponse = await _dio.get(
            '/databases/$database/layouts/dapi-api_sessiondata/records/$recordId',
            options: Options(
              headers: {
                'Authorization': 'Bearer $_token',
                'Accept': 'application/json',
              },
            ),
          );
          
          if (verifyResponse.statusCode == 200) {
            final verifyData = verifyResponse.data['response']['data'][0]['fieldData'] as Map<String, dynamic>;
            print('📋 FileMaker saved assignmentId: "${verifyData['assignmentId']}"');
            print('📋 Expected assignmentId: "${record.assignmentId}"');
            print('📋 assignmentId match: ${verifyData['assignmentId'] == record.assignmentId}');
          }
        } catch (e) {
          print('⚠️ Could not verify saved assignmentId: $e');
        }
        
        return record.copyWith(id: recordId.toString());
      }
      
      print('❌ Failed to create session record: ${createResponse.statusCode}');
      print('❌ Response data: ${createResponse.data}');
      throw Exception('Failed to create session record: ${createResponse.statusCode} - ${createResponse.data}');
    } on DioException catch (e) {
      print('❌ DioException when creating session record:');
      print('   Status Code: ${e.response?.statusCode}');
      print('   Response: ${e.response?.data}');
      print('   Request Data: ${jsonEncode(sessionData)}');
      print('   Error: ${e.message}');
      rethrow;
    }
  }

  // Update existing session record
  Future<SessionRecord> _updateSessionRecord(String recordId, SessionRecord record) async {
    // Check if this is an auto-save (has autoSaved flag)
    bool isAutoSave = record.payload['autoSaved'] == true;
    
    Map<String, dynamic> payloadWithTimes;
    
    if (isAutoSave) {
      print('🔄 Auto-save detected, preserving existing program data');
      // For auto-save, get the existing record first to preserve program data
      final existingRecord = await findExistingSessionRecord(record.visitId, record.assignmentId);
      if (existingRecord != null) {
        // Preserve existing program data and add auto-save metadata
        payloadWithTimes = Map<String, dynamic>.from(existingRecord.payload);
        payloadWithTimes['autoSaved'] = true;
        payloadWithTimes['autoSaveTimestamp'] = DateTime.now().toIso8601String();
        payloadWithTimes['sessionEnded'] = true;
        payloadWithTimes['endTimestamp'] = DateTime.now().toIso8601String();
        print('🔍 Preserved payload: $payloadWithTimes');
      } else {
        // Fallback to new payload if no existing record found
        payloadWithTimes = Map<String, dynamic>.from(record.payload);
      }
    } else {
      // Regular update - use new payload
      payloadWithTimes = Map<String, dynamic>.from(record.payload);
    }
    
    // Add program times to payload
    if (record.programStartTime != null) {
      payloadWithTimes['program_start_time'] = record.programStartTime!.toIso8601String().split('.')[0];
    }
    if (record.programEndTime != null) {
      payloadWithTimes['program_end_time'] = record.programEndTime!.toIso8601String().split('.')[0];
    }

    final now = DateTime.now();
    final nowString = now.toIso8601String().split('.')[0];

    // Build fieldData exactly matching the create pattern that works
    print('📋 Update SessionRecord assignmentId value: "${record.assignmentId}" (length: ${record.assignmentId.length})');
    print('📋 Update SessionRecord assignmentId isEmpty: ${record.assignmentId.isEmpty}');
    
    final fieldData = <String, dynamic>{
      'visitId': record.visitId,
      'clientId': record.clientId,
      'assignmentId': record.assignmentId,
      'payload_json': jsonEncode(payloadWithTimes),
      'staffId': record.staffId ?? '',
      'startedAt_ts': record.startedAt?.toIso8601String().split('.')[0] ?? nowString,
      'updatedAt_ts': record.updatedAt?.toIso8601String().split('.')[0] ?? nowString,
    };
    
    // Add intervention_phase if provided (only if it has a value to avoid empty string issues)
    if (record.interventionPhase != null && record.interventionPhase!.isNotEmpty) {
      fieldData['intervention_phase'] = record.interventionPhase;
    }

    final sessionData = {
      'fieldData': fieldData,
    };
    
    print('🔍 Updating session record $recordId with data: ${jsonEncode(sessionData)}');
    
    try {
      final updateResponse = await _dio.patch(
        '/databases/$database/layouts/dapi-api_sessiondata/records/$recordId',
        data: sessionData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
            'Cache-Control': 'no-cache',
          },
        ),
      );

      if (updateResponse.statusCode == 200) {
        print('✅ Successfully updated session record: $recordId');
        return record.copyWith(id: recordId);
      }
      
      print('❌ Failed to update session record: ${updateResponse.statusCode}');
      print('❌ Response data: ${updateResponse.data}');
      throw Exception('Failed to update session record: ${updateResponse.statusCode} - ${updateResponse.data}');
    } on DioException catch (e) {
      print('❌ DioException when updating session record:');
      print('   Status Code: ${e.response?.statusCode}');
      print('   Response: ${e.response?.data}');
      print('   Request Data: ${jsonEncode(sessionData)}');
      print('   Error: ${e.message}');
      rethrow;
    }
  }

  // Get all session records for a specific visit
  Future<List<SessionRecord>> getSessionRecordsForVisit(String visitId) async {
    await _ensureAuthenticated();
    
    try {
      print('🔍 Fetching session records for visit: $visitId');
      
      final response = await _dio.post(
        '/databases/$database/layouts/dapi-api_sessiondata/_find',
        data: {
          'query': [
            {
              'visitId': '==$visitId',
            }
          ],
          'limit': 1000  // Get up to 1000 records for this visit
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('🔍 Session records response status: ${response.statusCode}');
      print('🔍 Session records response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final records = data['response']['data'] as List<dynamic>?;
        
        if (records == null || records.isEmpty) {
          print('📝 No session records found for visit: $visitId');
          return [];
        }

        final sessionRecords = records.map((record) {
          final fieldData = record['fieldData'] as Map<String, dynamic>;
          return SessionRecord(
            id: record['recordId'] as String,
            visitId: fieldData['visitId'] as String? ?? '',
            clientId: fieldData['clientId'] as String? ?? '',
            assignmentId: fieldData['assignmentId'] as String? ?? '',
            startedAt: fieldData['startedAt_ts'] != null 
                ? DateTime.parse(fieldData['startedAt_ts'] as String)
                : null,
            updatedAt: fieldData['updatedAt_ts'] != null 
                ? DateTime.parse(fieldData['updatedAt_ts'] as String)
                : null,
            payload: fieldData['payload_json'] != null 
                ? jsonDecode(fieldData['payload_json'] as String) as Map<String, dynamic>
                : {},
            staffId: fieldData['staffId'] as String?,
            interventionPhase: fieldData['intervention_phase'] as String? ?? 'baseline',
            programStartTime: fieldData['program_start_time'] != null 
                ? DateTime.parse(fieldData['program_start_time'] as String)
                : null,
            programEndTime: fieldData['program_end_time'] != null 
                ? DateTime.parse(fieldData['program_end_time'] as String)
                : null,
            notes: fieldData['notes'] as String?,
            company: fieldData['Company'] as String?,
          );
        }).toList();

        print('✅ Fetched ${sessionRecords.length} session records for visit: $visitId');
        return sessionRecords;
      } else {
        print('❌ Failed to fetch session records: ${response.statusCode}');
        throw Exception('Failed to fetch session records: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching session records: $e');
      throw Exception('Error fetching session records: $e');
    }
  }

  // Behavior Definition operations
  Future<List<BehaviorDefinition>> getBehaviorDefinitions({String? clientId}) async {
    await _ensureAuthenticated();
    
    final query = <String, dynamic>{
      'limit': 100  // Limit to 100 records
    };
    
    // Always provide a query - use empty query to get all records if no clientId
    if (clientId != null && clientId.isNotEmpty) {
      query['query'] = [
        {'clientId': '==$clientId'},  // Search by provided client ID
      ];
    } else {
      // Empty query to get all behavior definitions
      query['query'] = [];
    }


    try {
      // Use direct record access instead of _find since we want all records
      final response = await _dio.get(
        '/databases/$database/layouts/dapi-patient_behaviors/records',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
            'Cache-Control': 'no-cache',
          },
        ),
      );


      final data = response.data as Map<String, dynamic>;
      final msgs = (data['messages'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final code = msgs.isNotEmpty ? '${msgs.first['code']}' : null;
      final msg = msgs.isNotEmpty ? '${msgs.first['message']}' : null;


      // FileMaker "OK"
      if (code == '0') {
        final records = (data['response']?['data'] as List?) ?? const [];
        
        // Parse behavior definitions
        final behaviorDefs = <BehaviorDefinition>[];
        for (int i = 0; i < records.length; i++) {
          try {
            final behaviorDef = BehaviorDefinition.fromJson(records[i]['fieldData']);
            behaviorDefs.add(behaviorDef);
          } catch (e) {
            // Continue with other records if one fails to parse
            continue;
          }
        }
        
        return behaviorDefs;
      }

      // FileMaker "no records match"
      if (code == '401') {
        return [];
      }

      throw Exception('FileMaker error $code: $msg');

    } catch (e) {
      if (e is DioException) {
      }
      rethrow;
    }
  }

  // Behavior Log operations
  Future<BehaviorLog> createBehaviorLog(BehaviorLog log) async {
    await _ensureAuthenticated();
    

    try {
      // Store behavior log data in payload_json field of session data
      final behaviorPayload = <String, dynamic>{
        'type': 'behavior_log',
        'behaviorId': log.behaviorId,
        'collector': log.collector ?? 'Current User',
        'createdAt': log.createdAt.toIso8601String(),
        'updatedAt': log.updatedAt.toIso8601String(),
      };
      
      // Only add non-null, non-zero values
      if (log.count != null && log.count! > 0) {
        behaviorPayload['count'] = log.count!;
      }
      if (log.notes != null && log.notes!.isNotEmpty) {
        behaviorPayload['notes'] = log.notes!;
      }
      if (log.antecedent != null && log.antecedent!.isNotEmpty) {
        behaviorPayload['antecedent'] = log.antecedent!;
      }
      if (log.behaviorDesc != null && log.behaviorDesc!.isNotEmpty) {
        behaviorPayload['behaviorDesc'] = log.behaviorDesc!;
      }
      if (log.consequence != null && log.consequence!.isNotEmpty) {
        behaviorPayload['consequence'] = log.consequence!;
      }
      if (log.setting != null && log.setting!.isNotEmpty) {
        behaviorPayload['setting'] = log.setting!;
      }
      if (log.perceivedFunction != null && log.perceivedFunction!.isNotEmpty) {
        behaviorPayload['perceivedFunction'] = log.perceivedFunction!;
      }
      if (log.severity != null && log.severity! > 0) {
        behaviorPayload['severity'] = log.severity!;
      }
      // Convert boolean values to strings for FileMaker compatibility
      if (log.injury != null) {
        behaviorPayload['injury'] = log.injury! ? 'true' : 'false';
      }
      if (log.restraintUsed != null) {
        behaviorPayload['restraintUsed'] = log.restraintUsed! ? 'true' : 'false';
      }
      if (log.startTs != null) {
        behaviorPayload['startTs'] = log.startTs!.toIso8601String();
      }
      if (log.endTs != null) {
        behaviorPayload['endTs'] = log.endTs!.toIso8601String();
      }
      if (log.durationSec != null && log.durationSec! > 0) {
        behaviorPayload['durationSec'] = log.durationSec!;
      }
      if (log.ratePerMin != null && log.ratePerMin! > 0) {
        behaviorPayload['ratePerMin'] = log.ratePerMin!;
      }
      
      // Only include essential fields with non-empty values
      final fieldData = <String, dynamic>{
        'visitId': log.visitId,
        'clientId': log.clientId,
        'assignmentId': log.assignmentId ?? '', // Always include assignmentId
        'payload_json': jsonEncode(behaviorPayload), // Convert to JSON string
        'staffId': '17ED033A-7CA9-4367-AA48-3C459DBBC24C', // Default staff ID
        'startedAt_ts': log.createdAt.toIso8601String().split('.')[0], // Complete timestamp without milliseconds
        'updatedAt_ts': log.updatedAt.toIso8601String().split('.')[0], // Complete timestamp without milliseconds
      };
      
      // Notes are already included in payload_json, no need to duplicate
      
      final behaviorLogData = {
        'fieldData': fieldData,
      };
      
      
      final response = await _dio.post(
        '/databases/$database/layouts/dapi-api_sessiondata/records',
        data: behaviorLogData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ),
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final recordId = data['response']['recordId'];
        return log.copyWith(id: recordId.toString());
      }
      
      throw Exception('Failed to create behavior log: ${response.statusCode}');
      
    } catch (e) {
      if (e is DioException) {
      }
      rethrow;
    }
  }

  Future<BehaviorLog> updateBehaviorLog(BehaviorLog log) async {
    await _ensureAuthenticated();
    

    try {
      final response = await _dio.patch(
        '/databases/$database/layouts/dapi-api_sessiondata/records/${log.id}',
        data: {
          'fieldData': log.toJson(),
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ),
      );


      if (response.statusCode == 200) {
        return log;
      }
      
      throw Exception('Failed to update behavior log: ${response.statusCode}');
      
    } catch (e) {
      if (e is DioException) {
      }
      rethrow;
    }
  }

  // Script execution
  Future<Map<String, dynamic>> evaluateAssignmentMastery(String assignmentId) async {
    await _ensureAuthenticated();
    
    final response = await _makeHttpRequestWithRetry(
      'PATCH',
      Uri.parse('$baseUrl/databases/$database/layouts/dapi-patient_programs/records/$assignmentId'),
      _headers,
      json.encode({
        'script': 'EvaluateAssignmentMastery',
        'script.param': json.encode({'assignmentId': assignmentId}),
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['response']['scriptResult'] ?? {};
    }
    throw Exception('Failed to evaluate assignment mastery: ${response.statusCode}');
  }

  Future<void> logout() async {
    if (_token != null) {
      try {
        await _makeHttpRequestWithRetry(
          'DELETE',
          Uri.parse('$baseUrl/databases/$database/sessions/$_token'),
          _headers,
          null,
        );
      } catch (e) {
        // Ignore logout errors
      }
    }
    
    _token = null;
    _isAuthenticated = false;
    _tokenCreatedAt = null;
    
    // Clear session global variables
    _currentStaffId = null;
    _currentCompanyId = null;
    _currentStaffName = null;
    _currentStaffEmail = null;
    _currentStaffCanManualEntry = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('filemaker_token');
      await prefs.remove('filemaker_token_created_at');
    } catch (e) {
      // Ignore storage errors
    }
    
    notifyListeners();
  }

  // Get planned visits for today
  Future<List<Visit>> getPlannedVisits() async {
    await _ensureAuthenticated();
    
    final today = DateTime.now();
    final todayStr = '${today.month.toString().padLeft(2, '0')}/${today.day.toString().padLeft(2, '0')}/${today.year}';
    
    try {
      // Filter by staff ID, status, and today's date
      final queryData = {
        'query': [
          {
            'staffId': '==$_currentStaffId',
            'statusInput': '==Planned',
            'Appointment_date': '==$todayStr',
          }
        ],
        'limit': 10,
        'sort': [
          {'fieldName': 'time_in', 'sortOrder': 'ascend'}
        ]
      };
      
      
      final response = await _dio.post(
        '/databases/$database/layouts/api_appointments/_find',
        data: queryData,
      );
      
      if (response.statusCode == 200) {
        final data = response.data['response']['data'] as List<dynamic>? ?? [];
        
        print('🔍 FileMaker getPlannedVisits Response:');
        print('📊 Total planned visits found: ${data.length}');
        
        final visits = <Visit>[];
        
        for (int i = 0; i < data.length; i++) {
          try {
            final item = data[i];
            final fieldData = item['fieldData'] as Map<String, dynamic>;
            
            // Parse appointment date and time to create proper timestamps
            final appointmentDate = fieldData['Appointment_date']?.toString();
            final timeIn = fieldData['time_in']?.toString();
            final timeOut = fieldData['time_out']?.toString();
            
            // Create start timestamp from appointment_date + time_in
            String? startTs;
            if (appointmentDate != null && appointmentDate.isNotEmpty && 
                timeIn != null && timeIn.isNotEmpty) {
              try {
                // Parse date (MM/DD/YYYY) and time (HH:MM:SS)
                final dateParts = appointmentDate.split('/');
                final timeParts = timeIn.split(':');
                if (dateParts.length == 3 && timeParts.length >= 2) {
                  final startDateTime = DateTime(
                    int.parse(dateParts[2]), // year
                    int.parse(dateParts[0]), // month
                    int.parse(dateParts[1]), // day
                    int.parse(timeParts[0]), // hour
                    int.parse(timeParts[1]), // minute
                  );
                  startTs = startDateTime.toIso8601String();
                }
              } catch (e) {
                print('⚠️ Error parsing start time: $e');
              }
            }
            
            // Create end timestamp from appointment_date + time_out
            String? endTs;
            if (appointmentDate != null && appointmentDate.isNotEmpty && 
                timeOut != null && timeOut.isNotEmpty) {
              try {
                final dateParts = appointmentDate.split('/');
                final timeParts = timeOut.split(':');
                if (dateParts.length == 3 && timeParts.length >= 2) {
                  final endDateTime = DateTime(
                    int.parse(dateParts[2]), // year
                    int.parse(dateParts[0]), // month
                    int.parse(dateParts[1]), // day
                    int.parse(timeParts[0]), // hour
                    int.parse(timeParts[1]), // minute
                  );
                  endTs = endDateTime.toIso8601String();
                }
              } catch (e) {
                print('⚠️ Error parsing end time: $e');
              }
            }
            
            final processedData = <String, dynamic>{
              'id': fieldData['PrimaryKey']?.toString() ?? '',
              'clientId': fieldData['clientId']?.toString() ?? '',
              'staffId': fieldData['staffId']?.toString() ?? '',
              'Procedure_Input': fieldData['Procedure_Input']?.toString() ?? 'Intervention (97153)',
              'start_ts': startTs ?? DateTime.now().toIso8601String(),
              'end_ts': endTs,
              'statusInput': fieldData['statusInput']?.toString() ?? 'Planned',
              'billableMinutes_n': fieldData['billableMinutes_n'],
              'units_total': fieldData['units_total'],
              'notes': fieldData['visit_notes']?.toString(),
              'Appointment_date': appointmentDate,
              'time_in': timeIn,
              'time_out': timeOut,
              'Patient_name': fieldData['Patient_name']?.toString(),
              'assignedto_name': fieldData['assignedto_name']?.toString(),
              'staff_title': fieldData['staff_title']?.toString(),
            };
            
            
            final visit = Visit.fromJson(processedData);
            visits.add(visit);
          } catch (e) {
            print('❌ Error processing visit $i: $e');
            continue;
          }
        }
        
        return visits;
      } else {
        throw Exception('Failed to load planned visits: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get completed sessions
  Future<List<Visit>> getCompletedSessions() async {
    await _ensureAuthenticated();
    
    
    try {
      final response = await _dio.post(
        '/databases/EIDBI/layouts/api_appointments/_find',
        data: {
          'query': [
            {'status': '==Submitted'}
          ],
          'limit': 100,
          'sort': [
            {'fieldName': 'start_ts', 'sortOrder': 'descend'}
          ]
        },
      );
      
      
      if (response.statusCode == 200) {
        final data = response.data['response']['data'] as List<dynamic>? ?? [];
        final sessions = <Visit>[];
        
        for (int i = 0; i < data.length; i++) {
          try {
            final item = data[i];
            final fieldData = item['fieldData'] as Map<String, dynamic>;
            
            // Handle null values and provide defaults for required fields
            final processedData = <String, dynamic>{
              'id': fieldData['PrimaryKey']?.toString() ?? '',
              'clientId': fieldData['clientId']?.toString() ?? '',
              'staffId': fieldData['staffId']?.toString() ?? '',
              'Procedure_Input': fieldData['Procedure_Input']?.toString() ?? 'Intervention (97153)',
              'start_ts': fieldData['start_ts']?.toString() ?? DateTime.now().toIso8601String(),
              'end_ts': fieldData['end_ts']?.toString(),
              'statusInput': fieldData['statusInput']?.toString() ?? 'Submitted',
              'billableMinutes_n': fieldData['billableMinutes_n'],
              'units_total': fieldData['units_total'],
              'notes': fieldData['visit_notes']?.toString(),
              'Appointment_date': fieldData['Appointment_date']?.toString(),
              'time_in': fieldData['time_in']?.toString(),
              'Patient_name': fieldData['Patient_name']?.toString(),
              'assignedto_name': fieldData['assignedto_name']?.toString(),
            };
            
            final session = Visit.fromJson(processedData);
            sessions.add(session);
          } catch (e) {
            // Continue processing other items instead of failing completely
            continue;
          }
        }
        
        return sessions;
      } else {
        throw Exception('Failed to load submitted sessions: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get raw visit fieldData from FileMaker (for accessing fields not in Visit model)
  Future<Map<String, dynamic>?> getVisitRawData(String visitId) async {
    await _ensureAuthenticated();
    
    try {
      final response = await _dio.post(
        '/databases/$database/layouts/api_appointments/_find',
        data: {
          'query': [
            {'PrimaryKey': '==$visitId'}
          ],
          'limit': 1
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final records = data['response']['data'] as List<dynamic>? ?? [];
        
        if (records.isNotEmpty) {
          final record = records.first;
          return record['fieldData'] as Map<String, dynamic>?;
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error fetching raw visit data: $e');
      return null;
    }
  }

  /// Get a visit by ID from FileMaker
  Future<Visit?> getVisitById(String visitId) async {
    await _ensureAuthenticated();
    
    try {
      final response = await _dio.post(
        '/databases/$database/layouts/api_appointments/_find',
        data: {
          'query': [
            {'PrimaryKey': '==$visitId'}
          ],
          'limit': 1
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final records = data['response']['data'] as List<dynamic>? ?? [];
        
        if (records.isNotEmpty) {
          final record = records.first;
          final fieldData = record['fieldData'] as Map<String, dynamic>;
          
          // Debug: Print what we're getting from FileMaker
          print('🔍 getVisitById - fieldData keys: ${fieldData.keys.toList()}');
          print('🔍 getVisitById - start_ts type: ${fieldData['start_ts']?.runtimeType}, value: ${fieldData['start_ts']}');
          print('🔍 getVisitById - end_ts type: ${fieldData['end_ts']?.runtimeType}, value: ${fieldData['end_ts']}');
          print('🔍 getVisitById - assignedto_name: ${fieldData['assignedto_name']}');
          print('🔍 getVisitById - staff_title: ${fieldData['staff_title']}');
          
          // Parse appointment date and times
          final appointmentDate = fieldData['Appointment_date']?.toString();
          final timeIn = fieldData['time_in']?.toString();
          final timeOut = fieldData['time_out']?.toString();
          
          // Parse start_ts - try multiple formats
          String? startTs;
          if (fieldData['start_ts'] != null) {
            try {
              final startTsValue = fieldData['start_ts'];
              if (startTsValue is String) {
                // Try to parse and validate the date
                final parsed = DateTime.parse(startTsValue);
                startTs = parsed.toIso8601String();
              } else {
                startTs = startTsValue.toString();
              }
            } catch (e) {
              print('⚠️ Error parsing start_ts: $e');
              // Try creating from appointment_date + time_in
              if (appointmentDate != null && appointmentDate.isNotEmpty &&
                  timeIn != null && timeIn.isNotEmpty) {
                try {
                  final dateParts = appointmentDate.split('/');
                  final timeParts = timeIn.split(':');
                  if (dateParts.length == 3 && timeParts.length >= 2) {
                    final startDateTime = DateTime(
                      int.parse(dateParts[2]), // year
                      int.parse(dateParts[0]), // month
                      int.parse(dateParts[1]), // day
                      int.parse(timeParts[0]), // hour
                      int.parse(timeParts[1]), // minute
                    );
                    startTs = startDateTime.toIso8601String();
                  }
                } catch (e2) {
                  print('⚠️ Error creating start_ts from appointment_date: $e2');
                }
              }
            }
          } else if (appointmentDate != null && appointmentDate.isNotEmpty &&
              timeIn != null && timeIn.isNotEmpty) {
            // Create start_ts from appointment_date + time_in
            try {
              final dateParts = appointmentDate.split('/');
              final timeParts = timeIn.split(':');
              if (dateParts.length == 3 && timeParts.length >= 2) {
                final startDateTime = DateTime(
                  int.parse(dateParts[2]), // year
                  int.parse(dateParts[0]), // month
                  int.parse(dateParts[1]), // day
                  int.parse(timeParts[0]), // hour
                  int.parse(timeParts[1]), // minute
                );
                startTs = startDateTime.toIso8601String();
              }
            } catch (e) {
              print('⚠️ Error creating start_ts from appointment_date: $e');
            }
          }
          
          // Parse end_ts from time_out and appointment_date
          String? endTs;
          final endTsValue = fieldData['end_ts'];
          if (endTsValue != null && endTsValue.toString().trim().isNotEmpty) {
            try {
              // Try to parse and validate the date
              final parsed = DateTime.parse(endTsValue.toString());
              endTs = parsed.toIso8601String();
            } catch (e) {
              print('⚠️ Error parsing end_ts: $e');
              // If parsing fails, use current time
              endTs = DateTime.now().toIso8601String();
            }
          } else {
            // If end_ts is empty or null, try creating from appointment_date + time_out first
            if (appointmentDate != null && appointmentDate.isNotEmpty &&
                timeOut != null && timeOut.isNotEmpty) {
              try {
                final dateParts = appointmentDate.split('/');
                final timeParts = timeOut.split(':');
                if (dateParts.length == 3 && timeParts.length >= 2) {
                  final endDateTime = DateTime(
                    int.parse(dateParts[2]), // year
                    int.parse(dateParts[0]), // month
                    int.parse(dateParts[1]), // day
                    int.parse(timeParts[0]), // hour
                    int.parse(timeParts[1]), // minute
                  );
                  endTs = endDateTime.toIso8601String();
                } else {
                  // Fallback to current time if parsing fails
                  endTs = DateTime.now().toIso8601String();
                }
              } catch (e) {
                print('⚠️ Error creating end_ts from appointment_date: $e');
                // Fallback to current time
                endTs = DateTime.now().toIso8601String();
              }
            } else {
              // If no appointment_date/time_out, use current time in same format as start_ts
              endTs = DateTime.now().toIso8601String();
            }
          }
          
          final processedData = <String, dynamic>{
            'id': fieldData['PrimaryKey']?.toString() ?? '',
            'clientId': fieldData['clientId']?.toString() ?? '',
            'staffId': fieldData['staffId']?.toString() ?? '',
            'Procedure_Input': fieldData['Procedure_Input']?.toString() ?? 'Intervention (97153)',
            'start_ts': startTs ?? DateTime.now().toIso8601String(),
            'end_ts': endTs,
            'statusInput': fieldData['statusInput']?.toString() ?? 'Planned',
            'billableMinutes_n': fieldData['billableMinutes_n'],
            'units_total': fieldData['units_total'],
            'notes': fieldData['visit_notes']?.toString(),
            'Appointment_date': appointmentDate,
            'time_in': timeIn,
            'time_out': timeOut,
            'Patient_name': fieldData['Patient_name']?.toString(),
            'assignedto_name': fieldData['assignedto_name']?.toString(),
            'staff_title': fieldData['staff_title']?.toString(),
          };
          
          return Visit.fromJson(processedData);
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error fetching visit by ID: $e');
      return null;
    }
  }

  // Get behavior logs for a specific visit
  Future<List<BehaviorLog>> getBehaviorLogsForVisit(String visitId) async {
    await _ensureAuthenticated();
    
    
    try {
      final response = await _dio.post(
        '/databases/$database/layouts/dapi-api_sessiondata/_find',
        data: {
          'query': [
            {'visitId': '==$visitId'}
          ],
          'limit': 1000,
          'sort': [
            {'fieldName': 'startedAt_ts', 'sortOrder': 'descend'}
          ]
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ),
      );
      
      print('🔍 Behavior logs response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data['response']['data'] as List<dynamic>? ?? [];
        final logs = <BehaviorLog>[];
        
        for (int i = 0; i < data.length; i++) {
          try {
            final item = data[i];
            final fieldData = item['fieldData'] as Map<String, dynamic>;
            
            // Check if this is a behavior log by checking payload_json
            final payloadJson = fieldData['payload_json'] as String?;
            if (payloadJson != null && payloadJson.isNotEmpty) {
              try {
                final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
                if (payload['type'] == 'behavior_log') {
                  // Extract behavior log data from payload and create BehaviorLog
                  final behaviorId = payload['behaviorId']?.toString() ?? '';
                  if (behaviorId.isNotEmpty) {
                    final log = BehaviorLog(
                      id: item['recordId']?.toString() ?? '',
                      visitId: fieldData['visitId']?.toString() ?? '',
                      clientId: fieldData['clientId']?.toString() ?? '',
                      behaviorId: behaviorId,
                      assignmentId: fieldData['assignmentId']?.toString(),
                      createdAt: fieldData['startedAt_ts'] != null 
                          ? DateTime.parse(fieldData['startedAt_ts'])
                          : DateTime.now(),
                      updatedAt: fieldData['updatedAt_ts'] != null 
                          ? DateTime.parse(fieldData['updatedAt_ts'])
                          : DateTime.now(),
                      count: payload['count'] as int?,
                      notes: payload['notes']?.toString(),
                      antecedent: payload['antecedent']?.toString(),
                      behaviorDesc: payload['behaviorDesc']?.toString(),
                      consequence: payload['consequence']?.toString(),
                      setting: payload['setting']?.toString(),
                      perceivedFunction: payload['perceivedFunction']?.toString(),
                      severity: payload['severity'] as int?,
                      injury: payload['injury']?.toString().toLowerCase() == 'true',
                      restraintUsed: payload['restraintUsed']?.toString().toLowerCase() == 'true',
                      collector: payload['collector']?.toString(),
                      startTs: payload['startTs'] != null 
                          ? DateTime.parse(payload['startTs'])
                          : null,
                      endTs: payload['endTs'] != null 
                          ? DateTime.parse(payload['endTs'])
                          : null,
                      durationSec: payload['durationSec'] as int?,
                      ratePerMin: payload['ratePerMin'] != null 
                          ? (payload['ratePerMin'] as num).toDouble()
                          : null,
                    );
            logs.add(log);
                  }
                }
          } catch (e) {
                print('⚠️ Error parsing payload_json for record ${item['recordId']}: $e');
                continue;
              }
            }
          } catch (e) {
            print('⚠️ Error processing behavior log record: $e');
            continue;
          }
        }
        
        print('✅ Fetched ${logs.length} behavior logs for visit: $visitId');
        return logs;
      } else {
        print('❌ Failed to load behavior logs: ${response.statusCode}');
        throw Exception('Failed to load behavior logs: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching behavior logs for visit: $e');
      rethrow;
    }
  }

  // Delete behavior logs for a specific visit
  Future<void> deleteBehaviorLogsForVisit(String visitId) async {
    await _ensureAuthenticated();
    
    try {
      // First, find all behavior logs for this visit
      final findResponse = await _dio.post(
        '/databases/EIDBI/layouts/dapi-api_sessiondata/_find',
        data: {
          'query': [
            {'visitId': '==$visitId'}
          ],
          'limit': 100
        },
      );
      
      if (findResponse.statusCode == 200) {
        final data = findResponse.data['response']['data'] as List<dynamic>? ?? [];
        
        // Delete each behavior log
        for (final item in data) {
          final recordId = item['recordId'];
          if (recordId != null) {
            await _dio.delete('/databases/EIDBI/layouts/dapi-api_sessiondata/records/$recordId');
          }
        }
        
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete a visit
  Future<void> deleteVisit(String visitId) async {
    await _ensureAuthenticated();
    
    try {
      // First, find the visit record
      final findResponse = await _dio.post(
        '/databases/EIDBI/layouts/api_appointments/_find',
        data: {
          'query': [
            {'PrimaryKey': '==$visitId'}
          ],
          'limit': 1
        },
      );
      
      if (findResponse.statusCode == 200) {
        final data = findResponse.data['response']['data'] as List<dynamic>? ?? [];
        if (data.isNotEmpty) {
          final recordId = data.first['recordId'];
          if (recordId != null) {
            await _dio.delete('/databases/EIDBI/layouts/api_appointments/records/$recordId');
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Create a session record for program data
  Future<void> createSessionRecord(Map<String, dynamic> sessionData) async {
    await _ensureAuthenticated();
    
    try {
      final response = await _dio.post(
        '/databases/EIDBI/layouts/dapi-api_sessiondata/records',
        data: {
          'fieldData': sessionData,
        },
      );
      
      
      if (response.statusCode == 200 || response.statusCode == 201) {
      } else {
        throw Exception('Failed to create session record: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException) {
      }
      rethrow;
    }
  }

  // Database Seeder Methods
  
  /// Create a client record
  Future<Client> createClient(Client client) async {
    await _ensureAuthenticated();
    
    try {
      final response = await _dio.post(
        '/databases/$database/layouts/api_patients/records',
        data: {
          'fieldData': client.toJson(),
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final recordId = data['response']['recordId'];
        return client.copyWith(id: recordId.toString());
      }
      
      throw Exception('Failed to create client: ${response.statusCode}');
    } catch (e) {
      if (e is DioException) {
        print('❌ DioException in createClient: ${e.message}');
        print('❌ Response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  /// Create a program assignment record
  Future<ProgramAssignment> createProgramAssignment(ProgramAssignment assignment) async {
    await _ensureAuthenticated();
    
    try {
      final response = await _dio.post(
        '/databases/$database/layouts/dapi-patient_programs/records',
        data: {
          'fieldData': assignment.toJson(),
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final recordId = data['response']['recordId'];
        return assignment.copyWith(id: recordId.toString());
      }
      
      throw Exception('Failed to create program assignment: ${response.statusCode}');
    } catch (e) {
      if (e is DioException) {
        print('❌ DioException in createProgramAssignment: ${e.message}');
        print('❌ Response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  /// Create a behavior definition record
  Future<BehaviorDefinition> createBehaviorDefinition(BehaviorDefinition definition) async {
    await _ensureAuthenticated();
    
    try {
      final response = await _dio.post(
        '/databases/$database/layouts/dapi-patient_behaviors/records',
        data: {
          'fieldData': definition.toJson(),
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final recordId = data['response']['recordId'];
        return definition.copyWith(id: recordId.toString());
      }
      
      throw Exception('Failed to create behavior definition: ${response.statusCode}');
    } catch (e) {
      if (e is DioException) {
        print('❌ DioException in createBehaviorDefinition: ${e.message}');
        print('❌ Response data: ${e.response?.data}');
      }
      rethrow;
    }
  }
}
