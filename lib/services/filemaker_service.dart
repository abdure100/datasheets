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
  static const String database = AppConfig.database;
  static const String username = AppConfig.username;
  static const String password = AppConfig.password;
  
  String? _token;
  bool _isAuthenticated = false;
  late Dio _dio;
  
  // Session global variables
  String? _currentStaffId;
  String? _currentCompanyId;
  String? _currentStaffName;
  bool? _currentStaffCanManualEntry;

  FileMakerService() {
    _dio = Dio();
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: AppConfig.connectionTimeout);
    _dio.options.receiveTimeout = const Duration(seconds: AppConfig.receiveTimeout);
    
    // Don't set User-Agent or Connection headers as they cause "unsafe header" warnings in web browsers
    // These headers are not essential for FileMaker API functionality
    
    // Add interceptor for automatic token refresh
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired, try to refresh
          print('🔄 Token expired, attempting to refresh...');
          try {
            final refreshed = await authenticate();
            if (refreshed) {
              print('✅ Token refreshed successfully');
              // Retry the original request with new token
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer $_token';
              
              try {
                final response = await _dio.fetch(options);
                handler.resolve(response);
                return;
              } catch (retryError) {
                print('❌ Retry failed: $retryError');
              }
            }
          } catch (e) {
            print('❌ Token refresh failed: $e');
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

  // Validate existing token without re-authenticating
  Future<bool> validateToken() async {
    if (!_isAuthenticated || _token == null) {
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
      return false;
    }
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
      if (storedToken != null) {
        _token = storedToken;
        _isAuthenticated = true;
        _dio.options.headers['Authorization'] = 'Bearer $_token';
      }
    } catch (e) {
      // Error loading stored token
    }
  }

  Future<void> _ensureAuthenticated() async {
    if (!_isAuthenticated || _token == null) {
      await authenticate();
    } else {
      // Validate existing token
      final isValid = await validateToken();
      if (!isValid) {
        print('🔄 Token validation failed, re-authenticating...');
      await authenticate();
      }
    }
  }

  Future<bool> authenticate() async {
    try {
      final credentials = base64Encode(utf8.encode('$username:$password'));
      
      final response = await http.post(
        Uri.parse('$baseUrl/databases/$database/sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $credentials',
          'Accept': 'application/json',
        },
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['response']['token'];
        _isAuthenticated = true;
        
        // Set Authorization header for Dio instance
        _dio.options.headers['Authorization'] = 'Bearer $_token';
        
        // Store token for future use
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('filemaker_token', _token!);
        } catch (e) {
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

  // Alternative createVisit method using Dio
  Future<Visit> createVisitWithDio(Visit visit, {bool skipLocation = false}) async {
    await _ensureAuthenticated();
    
    // Add required fields for api_appointments layout
    final visitData = visit.toJson();
    visitData['Appointment_date'] = '${visit.startTs.month.toString().padLeft(2, '0')}/${visit.startTs.day.toString().padLeft(2, '0')}/${visit.startTs.year}';
    visitData['start_ts'] = visit.startTs.toIso8601String().split('.')[0];
    
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
    
    
    try {
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

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('response')) {
          final responseData = data['response'];
          if (responseData is Map<String, dynamic>) {
          }
        }
        if (data.containsKey('messages')) {
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
      throw Exception('Failed to create visit with Dio: ${response.statusCode} - ${response.data}');
    } catch (e) {
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

      // Now update using the recordId
      final updateData = {
        'end_ts': endTs.toIso8601String().split('.')[0],
        'status': 'Submitted',        // Update both status fields
        'statusInput': 'Submitted',   // This appears to be the main status field
        'update_flagx': 3, // Trigger processing in FileMaker for session end
        'end_latitude': endLatitude,
        'end_longitude': endLongitude,
        'end_location_accuracy': endAccuracy,
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
    
    // Add program times to payload
    final payloadWithTimes = Map<String, dynamic>.from(record.payload);
    if (record.programStartTime != null) {
      payloadWithTimes['program_start_time'] = record.programStartTime!.toIso8601String();
    }
    if (record.programEndTime != null) {
      payloadWithTimes['program_end_time'] = record.programEndTime!.toIso8601String();
    }

      final sessionData = {
        'fieldData': {
        'visitId': record.visitId,
          'clientId': record.clientId,
          'assignmentId': record.assignmentId,
          'startedAt_ts': record.startedAt?.toIso8601String().split('.')[0] ?? DateTime.now().toIso8601String().split('.')[0],
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
      '/databases/$database/layouts/api_sessiondata/records/${record.id}',
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
      
      final response = await _dio.post(
        '/databases/$database/layouts/api_sessiondata/_find',
        data: {
          'query': [
            {
              'visitId': '==$visitId',
              'assignmentId': '==$assignmentId',
            }
          ]
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
        
        print('🔍 Found ${records?.length ?? 0} records');
        
        if (records != null && records.isNotEmpty) {
          final recordData = records.first as Map<String, dynamic>;
          final fieldData = recordData['fieldData'] as Map<String, dynamic>;
          
          print('🔍 Found existing record: ${recordData['recordId']}');
          
          return SessionRecord(
            id: recordData['recordId'].toString(),
            visitId: fieldData['visitId'] ?? '',
            clientId: fieldData['clientId'] ?? '',
            assignmentId: fieldData['assignmentId'] ?? '',
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
          );
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
    // Add program times to payload
    final payloadWithTimes = Map<String, dynamic>.from(record.payload);
    if (record.programStartTime != null) {
      payloadWithTimes['program_start_time'] = record.programStartTime!.toIso8601String();
    }
    if (record.programEndTime != null) {
      payloadWithTimes['program_end_time'] = record.programEndTime!.toIso8601String();
    }

    final sessionData = {
      'fieldData': {
        'visitId': record.visitId,
        'clientId': record.clientId,
        'assignmentId': record.assignmentId,
        'startedAt_ts': record.startedAt?.toIso8601String().split('.')[0] ?? DateTime.now().toIso8601String().split('.')[0],
        'payload_json': jsonEncode(payloadWithTimes),
        'staffId': record.staffId ?? '',
        'notes': record.notes ?? '',
        'intervention_phase': record.interventionPhase ?? 'baseline',
        'program_start_time': record.programStartTime?.toIso8601String().split('.')[0],
        'program_end_time': record.programEndTime?.toIso8601String().split('.')[0],
      }
    };
    
    print('🔍 Creating session record with data: ${jsonEncode(sessionData)}');
      
      final createResponse = await _dio.post(
        '/databases/$database/layouts/api_sessiondata/records',
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
        return record.copyWith(id: recordId.toString());
      }
      
    print('❌ Failed to create session record: ${createResponse.statusCode}');
    print('❌ Response data: ${createResponse.data}');
    throw Exception('Failed to create session record: ${createResponse.statusCode} - ${createResponse.data}');
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
      payloadWithTimes['program_start_time'] = record.programStartTime!.toIso8601String();
    }
    if (record.programEndTime != null) {
      payloadWithTimes['program_end_time'] = record.programEndTime!.toIso8601String();
    }

    final sessionData = {
      'fieldData': {
        'visitId': record.visitId,
        'clientId': record.clientId,
        'assignmentId': record.assignmentId,
        'startedAt_ts': record.startedAt?.toIso8601String().split('.')[0] ?? DateTime.now().toIso8601String().split('.')[0],
        'payload_json': jsonEncode(payloadWithTimes),
        'staffId': record.staffId ?? '',
        'notes': record.notes ?? '',
        'intervention_phase': record.interventionPhase ?? 'baseline',
        'program_start_time': record.programStartTime?.toIso8601String().split('.')[0],
        'program_end_time': record.programEndTime?.toIso8601String().split('.')[0],
      }
    };
    
    final updateResponse = await _dio.patch(
      '/databases/$database/layouts/api_sessiondata/records/$recordId',
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
      return record.copyWith(id: recordId);
    }
    
    throw Exception('Failed to update session record: ${updateResponse.statusCode}');
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
        'payload_json': jsonEncode(behaviorPayload), // Convert to JSON string
        'staffId': '17ED033A-7CA9-4367-AA48-3C459DBBC24C', // Default staff ID
        'startedAt_ts': log.createdAt.toIso8601String().split('.')[0], // Complete timestamp without milliseconds
        'updatedAt_ts': log.updatedAt.toIso8601String().split('.')[0], // Complete timestamp without milliseconds
      };
      
      // Only add assignmentId if it's not null and not empty
      if (log.assignmentId != null && log.assignmentId!.isNotEmpty) {
        fieldData['assignmentId'] = log.assignmentId!;
      }
      
      // Notes are already included in payload_json, no need to duplicate
      
      final behaviorLogData = {
        'fieldData': fieldData,
      };
      
      
      final response = await _dio.post(
        '/databases/$database/layouts/api_sessiondata/records',
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
        '/databases/$database/layouts/api_sessiondata/records/${log.id}',
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
    
    // Clear session global variables
    _currentStaffId = null;
    _currentCompanyId = null;
    _currentStaffName = null;
    _currentStaffCanManualEntry = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('filemaker_token');
    } catch (e) {
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

  // Get behavior logs for a specific visit
  Future<List<BehaviorLog>> getBehaviorLogsForVisit(String visitId) async {
    await _ensureAuthenticated();
    
    
    try {
      final response = await _dio.post(
        '/databases/EIDBI/layouts/api_sessiondata/_find',
        data: {
          'query': [
            {'visitId': '==$visitId'}
          ],
          'limit': 100,
          'sort': [
            {'fieldName': 'createdAt_ts', 'sortOrder': 'descend'}
          ]
        },
      );
      
      
      if (response.statusCode == 200) {
        final data = response.data['response']['data'] as List<dynamic>? ?? [];
        final logs = <BehaviorLog>[];
        
        for (int i = 0; i < data.length; i++) {
          try {
            final item = data[i];
            final fieldData = item['fieldData'] as Map<String, dynamic>;
            final log = BehaviorLog.fromJson(fieldData);
            logs.add(log);
          } catch (e) {
            // Continue processing other logs instead of failing completely
            continue;
          }
        }
        
        return logs;
      } else {
        throw Exception('Failed to load behavior logs: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete behavior logs for a specific visit
  Future<void> deleteBehaviorLogsForVisit(String visitId) async {
    await _ensureAuthenticated();
    
    try {
      // First, find all behavior logs for this visit
      final findResponse = await _dio.post(
        '/databases/EIDBI/layouts/api_sessiondata/_find',
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
            await _dio.delete('/databases/EIDBI/layouts/api_sessiondata/records/$recordId');
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
        '/databases/EIDBI/layouts/api_sessiondata/records',
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
}
