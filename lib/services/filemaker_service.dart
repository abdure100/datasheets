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
import 'location_service.dart';

class FileMakerService extends ChangeNotifier {
  static const String baseUrl = 'https://devdb.sphereemr.com/fmi/data/v1';
  static const String database = 'EIDBI';
  static const String username = 'fmapi';
  static const String password = r'Sphere321$';
  
  String? _token;
  bool _isAuthenticated = false;
  late Dio _dio;
  
  // Session global variables
  String? _currentStaffId;
  String? _currentCompanyId;
  String? _currentStaffName;

  FileMakerService() {
    _dio = Dio();
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  bool get isAuthenticated => _isAuthenticated;
  
  // Session global variables getters
  String? get currentStaffId => _currentStaffId;
  String? get currentCompanyId => _currentCompanyId;
  String? get currentStaffName => _currentStaffName;

  Future<bool> authenticate() async {
    try {
      final credentials = base64Encode(utf8.encode('$username:$password'));
      print('Attempting to authenticate with FileMaker...');
      print('URL: $baseUrl/databases/$database/sessions');
      
      final response = await http.post(
        Uri.parse('$baseUrl/databases/$database/sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $credentials',
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['response']['token'];
        _isAuthenticated = true;
        
        // Store token for future use
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('filemaker_token', _token!);
        } catch (e) {
          // Ignore storage errors in web
          print('Token storage error (ignored): $e');
        }
        
        notifyListeners();
        print('Authentication successful!');
        // Add delay to ensure token is fully processed
        await Future.delayed(const Duration(milliseconds: 500));
        return true;
      } else {
        print('Authentication failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('FileMaker authentication error: $e');
      print('Error type: ${e.runtimeType}');
    }
    return false;
  }

  Future<void> _ensureAuthenticated() async {
    if (!_isAuthenticated || _token == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final storedToken = prefs.getString('filemaker_token');
        
        if (storedToken != null) {
          _token = storedToken;
          _isAuthenticated = true;
        } else {
          await authenticate();
        }
      } catch (e) {
        // If storage fails, just try to authenticate
        print('Storage error, attempting authentication: $e');
        await authenticate();
      }
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
    'User-Agent': 'curl/8.7.1',
    'Accept': 'application/json',
    'Connection': 'keep-alive',
    'Cache-Control': 'no-cache',
  };

  void _logHeaders() {
    print('Current token: $_token');
    print('Headers: $_headers');
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

    print('=== FILEMAKER CLIENTS LOOKUP REQUEST (DIO) ===');
    print('URL: /databases/$database/layouts/api_patients_list/_find');
    print('Query: $query');
    print('Company ID: $companyId');
    print('Searching for clients in company: $companyId with Status: Active');
    print('Current staff ID: $_currentStaffId');
    print('Current company ID: $_currentCompanyId');
    
    // Test: Try to get all clients first to see what we have
    print('=== TESTING: Getting all clients first ===');
    try {
      final allClientsResponse = await _dio.get('/databases/$database/layouts/api_patients_list/records');
      final allClientsData = allClientsResponse.data as Map<String, dynamic>;
      final allClients = (allClientsData['response']?['data'] as List?) ?? const [];
      print('Total clients in database: ${allClients.length}');
      if (allClients.isNotEmpty) {
        final firstClient = allClients.first['fieldData'];
        print('First client company: ${firstClient['Company']}');
        print('First client status: ${firstClient['Status']}');
        print('Available fields: ${firstClient.keys.toList()}');
      }
    } catch (e) {
      print('Error getting all clients: $e');
    }
    print('==========================================');

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

      print('=== FILEMAKER CLIENTS LOOKUP RESPONSE (DIO) ===');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Data: ${response.data}');
      print('==============================================');

      // FileMaker response analysis
      final data = response.data as Map<String, dynamic>;
      final msgs = (data['messages'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final code = msgs.isNotEmpty ? '${msgs.first['code']}' : null;
      final msg = msgs.isNotEmpty ? '${msgs.first['message']}' : null;

      print('=== FILEMAKER MESSAGE ANALYSIS (DIO) ===');
      print('Messages count: ${msgs.length}');
      print('First message code: $code');
      print('First message text: $msg');
      print('All messages: $msgs');
      print('=========================================');

      // FileMaker "OK"
      if (code == '0') {
        final records = (data['response']?['data'] as List?) ?? const [];
        print('=== SUCCESSFUL CLIENTS LOOKUP (DIO) ===');
        print('Records found: ${records.length}');
        
        // Debug: Check what records we're getting
        if (records.isNotEmpty) {
          print('=== CLIENT DROPDOWN RESULTS ===');
          print('Total Active clients found: ${records.length}');
          
          // Show all clients that will appear in dropdown
          for (int i = 0; i < records.length; i++) {
            final client = records[i]['fieldData'];
            print('${i + 1}. ${client['namefull']} (${client['Status']})');
          }
          
          print('=== FILTER VERIFICATION ===');
          final firstRecord = records.first['fieldData'];
          print('First record Company: ${firstRecord['Company']}');
          print('First record Status: ${firstRecord['Status']}');
          print('Expected Company: $companyId');
          print('Expected Status: Active');
          
          // Check if all records have the same company and status
          final allCompanies = records.map((r) => r['fieldData']['Company']).toSet();
          final allStatuses = records.map((r) => r['fieldData']['Status']).toSet();
          print('All companies in results: $allCompanies');
          print('All statuses in results: $allStatuses');
          print('Company filter working: ${allCompanies.contains(companyId)}');
          print('Status filter working: ${allStatuses.contains('Active')}');
          print('=====================================');
        }
        print('=======================================');
        
        // Filter to only Active clients on the client side
        final activeClients = records
            .where((record) => record['fieldData']['Status'] == 'Active')
            .map((record) => Client.fromJson(record['fieldData']))
            .toList();
            
        print('=== CLIENT-SIDE FILTERING ===');
        print('Total records from company: ${records.length}');
        print('Active clients after filtering: ${activeClients.length}');
        print('================================');
        
        return activeClients;
      }

      // FileMaker "no records match"
      if (code == '401') {
        print('No clients found for company: $companyId');
        return [];
      }

      // Any other FM error
      throw Exception('FileMaker error $code: $msg');

    } catch (e) {
      print('=== DIO ERROR ===');
      print('Error: $e');
      if (e is DioException) {
        print('DioException type: ${e.type}');
        print('DioException message: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }
      print('=================');
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

    print('=== FILEMAKER STAFF LOOKUP REQUEST (DIO) ===');
    print('URL: /databases/$database/layouts/api_staffs/_find');
    print('Query: $query');
    print('Searching staff by email: ${email.trim()}');

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

      print('=== FILEMAKER STAFF LOOKUP RESPONSE (DIO) ===');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Data: ${response.data}');
      print('=============================================');

      // FileMaker response analysis
      final data = response.data as Map<String, dynamic>;
      final msgs = (data['messages'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final code = msgs.isNotEmpty ? '${msgs.first['code']}' : null;
      final msg = msgs.isNotEmpty ? '${msgs.first['message']}' : null;

      print('=== FILEMAKER MESSAGE ANALYSIS (DIO) ===');
      print('Messages count: ${msgs.length}');
      print('First message code: $code');
      print('First message text: $msg');
      print('All messages: $msgs');
      print('=========================================');

      // FileMaker "OK"
      if (code == '0') {
        final records = (data['response']?['data'] as List?) ?? const [];
        print('=== SUCCESSFUL STAFF LOOKUP (DIO) ===');
        print('Data records found: ${records.length}');
        if (records.isNotEmpty) {
          print('First record: ${records.first}');
          print('Field data: ${records.first['fieldData']}');
        }
        print('=====================================');

        if (records.isEmpty) return null;
        final fieldData = (records.first['fieldData'] as Map<String, dynamic>)..removeWhere((k, v) => v == null);
        print('=== EXTRACTED STAFF DATA (DIO) ===');
        print('Cleaned field data: $fieldData');
        print('Staff name: ${fieldData['FullName'] ?? fieldData['name']}');
        print('Staff email: ${fieldData['email']}');
        print('==================================');
        
        // Store session global variables
        _currentStaffId = fieldData['PrimaryKey'];
        _currentCompanyId = fieldData['Company'];
        _currentStaffName = fieldData['FullName'];
        
        print('=== SESSION VARIABLES SET ===');
        print('Current Staff ID: $_currentStaffId');
        print('Current Company ID: $_currentCompanyId');
        print('=============================');
        
        print('Found staff: ${fieldData['FullName'] ?? fieldData['name']} (${fieldData['email']})');
        return Staff.fromJson(fieldData);
      }

      // FileMaker "no records match"
      if (code == '401') {
        print('No staff found with email: $email');
        return null;
      }

      // Any other FM error
      throw Exception('FileMaker error $code: $msg');

    } catch (e) {
      print('=== DIO ERROR ===');
      print('Error: $e');
      if (e is DioException) {
        print('DioException type: ${e.type}');
        print('DioException message: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }
      print('=================');
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
    
    print('Creating visit with data: $visitData');
    _logHeaders();
    
    final requestBody = json.encode({
      'fieldData': visitData,
    });
    
    // Try with explicit content-length header
    final headers = Map<String, String>.from(_headers);
    headers['Content-Length'] = requestBody.length.toString();
    
    print('=== REQUEST DETAILS ===');
    print('Request URL: $baseUrl/databases/$database/layouts/api_appointments/records');
    print('Request method: POST');
    print('Request headers: $headers');
    print('Request body: $requestBody');
    print('Request body length: ${requestBody.length}');
    print('Request body (pretty): ${json.encode(json.decode(requestBody))}');
    print('======================');
    
    var response = await http.post(
      Uri.parse('$baseUrl/databases/$database/layouts/api_appointments/records'),
      headers: headers,
      body: requestBody,
    );

    print('=== RESPONSE DETAILS ===');
    print('Response status: ${response.statusCode}');
    print('Response headers: ${response.headers}');
    print('Response body: ${response.body}');
    print('Response body length: ${response.body.length}');
    print('Response body (pretty): ${response.body.isNotEmpty ? json.encode(json.decode(response.body)) : "EMPTY"}');
    
    // Log FileMaker error messages
    final txt = response.body;
    Map<String, dynamic> j = {};
    try { j = jsonDecode(txt); } catch (_) {}
    print('FM full reply: $txt');
    if (j['messages'] != null) {
      print('FM messages: ${jsonEncode(j['messages'])}');
    }
    print('========================');

    // If token expired or bad request, refresh and retry
    if (response.statusCode == 401 || response.statusCode == 400) {
      print('Token expired or bad request, refreshing...');
      await authenticate();
      
      // Update headers with new token
      headers['Authorization'] = 'Bearer $_token';
      
      print('=== RETRY REQUEST DETAILS ===');
      print('Retry URL: $baseUrl/databases/$database/layouts/api_appointments/records');
      print('Retry method: POST');
      print('Retry headers: $headers');
      print('Retry request body: $requestBody');
      print('Retry request body length: ${requestBody.length}');
      print('Retry request body (pretty): ${json.encode(json.decode(requestBody))}');
      print('=============================');
      
      // Add small delay to ensure token is fully processed
      await Future.delayed(const Duration(milliseconds: 1000));
      
      response = await http.post(
        Uri.parse('$baseUrl/databases/$database/layouts/api_appointments/records'),
        headers: headers,
        body: requestBody,
      );
      print('=== RETRY RESPONSE DETAILS ===');
      print('Retry response status: ${response.statusCode}');
      print('Retry response headers: ${response.headers}');
      print('Retry response body: ${response.body}');
      print('Retry response body length: ${response.body.length}');
      print('Retry response body (pretty): ${response.body.isNotEmpty ? json.encode(json.decode(response.body)) : "EMPTY"}');
      
      // Log FileMaker error messages for retry
      final retryTxt = response.body;
      Map<String, dynamic> retryJ = {};
      try { retryJ = jsonDecode(retryTxt); } catch (_) {}
      print('FM retry full reply: $retryTxt');
      if (retryJ['messages'] != null) {
        print('FM retry messages: ${jsonEncode(retryJ['messages'])}');
      }
      print('================================');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      final recordId = data['response']['recordId'];
      return visit.copyWith(id: recordId);
    }
    throw Exception('Failed to create visit: ${response.statusCode} - ${response.body}');
  }

  // Alternative createVisit method using Dio
  Future<Visit> createVisitWithDio(Visit visit) async {
    await _ensureAuthenticated();
    
    // Add required fields for api_appointments layout
    final visitData = visit.toJson();
    visitData['Appointment_date'] = '${visit.startTs.month.toString().padLeft(2, '0')}/${visit.startTs.day.toString().padLeft(2, '0')}/${visit.startTs.year}';
    visitData['start_ts'] = visit.startTs.toIso8601String().split('.')[0];
    
    visitData['update_flagx'] = 5; // Trigger processing in FileMaker
    
    // Get current location for start
    print('Getting current location for visit start...');
    final location = await LocationService.getCurrentLocation();
    if (location != null) {
      visitData['start_latitude'] = location['latitude']!;
      visitData['start_longitude'] = location['longitude']!;
      visitData['start_location_accuracy'] = location['accuracy']!;
      print('Location obtained: ${location['latitude']}, ${location['longitude']}');
    } else {
      visitData['start_latitude'] = '0.0';
      visitData['start_longitude'] = '0.0';
      visitData['start_location_accuracy'] = '0.0';
      print('Location not available, using default values');
    }
    
    print('Creating visit with Dio - data: $visitData');
    
    try {
      final response = await _dio.post(
        '/databases/$database/layouts/api_appointments/records',
        data: {'fieldData': visitData},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'User-Agent': 'curl/8.7.1',
            'Accept': 'application/json',
            'Connection': 'keep-alive',
            'Cache-Control': 'no-cache',
          },
        ),
      );

      print('Dio response status: ${response.statusCode}');
      print('Dio response data: ${response.data}');
      print('=== RAW FILEMAKER RESPONSE DEBUG ===');
      print('Full response: ${response.data}');
      print('Response type: ${response.data.runtimeType}');
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        print('Response keys: ${data.keys.toList()}');
        if (data.containsKey('response')) {
          final responseData = data['response'];
          print('Response data type: ${responseData.runtimeType}');
          if (responseData is Map<String, dynamic>) {
            print('Response data keys: ${responseData.keys.toList()}');
            print('recordId: ${responseData['recordId']} (type: ${responseData['recordId'].runtimeType})');
            print('PrimaryKey: ${responseData['PrimaryKey']} (type: ${responseData['PrimaryKey'].runtimeType})');
            print('modId: ${responseData['modId']} (type: ${responseData['modId'].runtimeType})');
          }
        }
        if (data.containsKey('messages')) {
          print('Messages: ${data['messages']}');
        }
      }
      print('=====================================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final recordId = response.data['response']['recordId'];
        print('=== VISIT CREATION SUCCESS ===');
        print('RecordId from FileMaker: $recordId');
        print('Visit ID before copyWith: ${visit.id}');
        
        // Now fetch the PrimaryKey using the recordId
        print('Fetching PrimaryKey for recordId: $recordId');
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
        
        print('Find response status: ${findResponse.statusCode}');
        print('Find response data: ${findResponse.data}');
        
        if (findResponse.statusCode == 200) {
          final findData = findResponse.data as Map<String, dynamic>;
          if (findData['response']['data'] != null && 
              (findData['response']['data'] as List).isNotEmpty) {
            final recordData = (findData['response']['data'] as List).first;
            final primaryKey = recordData['fieldData']['PrimaryKey'];
            print('Found PrimaryKey: $primaryKey');
            
            final updatedVisit = visit.copyWith(id: primaryKey);
            print('Visit ID after copyWith: ${updatedVisit.id}');
            print('==============================');
            return updatedVisit;
          }
        }
        
        // Fallback to recordId if PrimaryKey not found
        print('PrimaryKey not found, using recordId as fallback');
        final updatedVisit = visit.copyWith(id: recordId.toString());
        print('Visit ID after copyWith: ${updatedVisit.id}');
        print('==============================');
        return updatedVisit;
      }
      throw Exception('Failed to create visit with Dio: ${response.statusCode} - ${response.data}');
    } catch (e) {
      print('Dio error: $e');
      rethrow;
    }
  }

  Future<Visit> updateVisit(Visit visit) async {
    await _ensureAuthenticated();
    
    final response = await http.patch(
      Uri.parse('$baseUrl/databases/$database/layouts/dapi-appointments_new/records/${visit.id}'),
      headers: _headers,
      body: json.encode({
        'fieldData': visit.toJson(),
      }),
    );

    if (response.statusCode == 200) {
      return visit;
    }
    throw Exception('Failed to update visit: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> closeVisit(String visitId, DateTime endTs) async {
    await _ensureAuthenticated();
    
    print('=== FILEMAKER CLOSE VISIT REQUEST (DIO) ===');
    print('Visit ID (PrimaryKey): $visitId');
    print('End Time: ${endTs.toIso8601String()}');
    print('Finding recordId for PrimaryKey...');
    
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
      print('Found recordId: $recordId');
      
      // Get current location for end
      print('Getting current location for visit end...');
      final location = await LocationService.getCurrentLocation();
      String endLatitude = '0.0';
      String endLongitude = '0.0';
      String endAccuracy = '0.0';
      
      if (location != null) {
        endLatitude = location['latitude']!;
        endLongitude = location['longitude']!;
        endAccuracy = location['accuracy']!;
        print('End location obtained: $endLatitude, $endLongitude');
      } else {
        print('End location not available, using default values');
      }

      // Now update using the recordId
      final response = await _dio.patch(
        '/databases/$database/layouts/api_appointments/records/$recordId',
        data: {
          'fieldData': {
            'end_ts': endTs.toIso8601String().split('.')[0],
            'statusInput': 'submitted',
            'update_flagx': 5, // Trigger processing in FileMaker
            'end_latitude': endLatitude,
            'end_longitude': endLongitude,
            'end_location_accuracy': endAccuracy,
          },
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ),
      );

      print('=== FILEMAKER CLOSE VISIT RESPONSE (DIO) ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
      print('===========================================');

      if (response.statusCode == 200) {
        print('Successfully closed visit: $visitId');
        return response.data['response'] ?? {};
      }
      
      throw Exception('Failed to close visit: ${response.statusCode}');
      
    } catch (e) {
      print('=== DIO CLOSE VISIT ERROR ===');
      print('Error: $e');
      if (e is DioException) {
        print('DioException type: ${e.type}');
        print('DioException message: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }
      print('=============================');
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

    print('=== FILEMAKER PROGRAM ASSIGNMENTS LOOKUP REQUEST (DIO) ===');
    print('URL: /databases/$database/layouts/api_program_assignments/_find');
    print('Query: $query');
    print('Client ID: $clientId');
    print('LTG ID: $ltgId');
    print('Searching for program assignments for client: $clientId${ltgId != null ? ', LTG: $ltgId' : ''}');

    try {
      final response = await _dio.post(
        '/databases/$database/layouts/api_program_assignments/_find',
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

      print('=== FILEMAKER PROGRAM ASSIGNMENTS LOOKUP RESPONSE (DIO) ===');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Data: ${response.data}');
      print('==========================================================');

      final data = response.data as Map<String, dynamic>;
      final msgs = (data['messages'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final code = msgs.isNotEmpty ? '${msgs.first['code']}' : null;
      final msg = msgs.isNotEmpty ? '${msgs.first['message']}' : null;

      print('=== FILEMAKER MESSAGE ANALYSIS (DIO) ===');
      print('Messages count: ${msgs.length}');
      print('First message code: $code');
      print('First message text: $msg');
      print('All messages: $msgs');
      print('=========================================');

      // FileMaker "OK"
      if (code == '0') {
        final records = (data['response']?['data'] as List?) ?? const [];
        print('=== SUCCESSFUL PROGRAM ASSIGNMENTS LOOKUP (DIO) ===');
        print('Records found: ${records.length}');
        print('===================================================');
        
        // Debug: Check what data we're getting
        if (records.isNotEmpty) {
          print('=== PROGRAM ASSIGNMENT DATA DEBUG ===');
          final firstRecord = records.first['fieldData'];
          print('First record fieldData: $firstRecord');
          print('Available fields: ${firstRecord.keys.toList()}');
          
          // Check each field for null values (using FileMaker field names)
          print('=== FIELD NULL CHECK (FileMaker Names) ===');
          print('PrimaryKey: ${firstRecord['PrimaryKey']} (null: ${firstRecord['PrimaryKey'] == null})');
          print('clientId: ${firstRecord['clientId']} (null: ${firstRecord['clientId'] == null})');
          print('SubMilestone_name: ${firstRecord['SubMilestone_name']} (null: ${firstRecord['SubMilestone_name'] == null})');
          print('Datacollection_type: ${firstRecord['Datacollection_type']} (null: ${firstRecord['Datacollection_type'] == null})');
          print('Status: ${firstRecord['Status']} (null: ${firstRecord['Status'] == null})');
          print('Intervention_phase: ${firstRecord['Intervention_phase']} (null: ${firstRecord['Intervention_phase'] == null})');
          print('Mastery_Criteria: ${firstRecord['Mastery_Criteria']} (null: ${firstRecord['Mastery_Criteria'] == null})');
          print('config_json: ${firstRecord['config_json']} (null: ${firstRecord['config_json'] == null})');
          print('==========================================');
          
          // Check for FileMaker field name variations
          print('=== FILEMAKER FIELD VARIATIONS ===');
          print('PrimaryKey: ${firstRecord['PrimaryKey']} (null: ${firstRecord['PrimaryKey'] == null})');
          print('SubMilestone_name: ${firstRecord['SubMilestone_name']} (null: ${firstRecord['SubMilestone_name'] == null})');
          print('Datacollection_type: ${firstRecord['Datacollection_type']} (null: ${firstRecord['Datacollection_type'] == null})');
          print('Status: ${firstRecord['Status']} (null: ${firstRecord['Status'] == null})');
          print('Intervention_phase: ${firstRecord['Intervention_phase']} (null: ${firstRecord['Intervention_phase'] == null})');
          print('Mastery_Criteria: ${firstRecord['Mastery_Criteria']} (null: ${firstRecord['Mastery_Criteria'] == null})');
          print('config_json: ${firstRecord['config_json']} (null: ${firstRecord['config_json'] == null})');
          print('==================================');
        }
        
        // Parse records with error handling
        final assignments = <ProgramAssignment>[];
        for (int i = 0; i < records.length; i++) {
          try {
            final fieldData = records[i]['fieldData'];
            print('Parsing assignment ${i + 1} with data: $fieldData');
            
            final assignment = ProgramAssignment.fromJson(fieldData);
            assignments.add(assignment);
            print('Successfully parsed assignment ${i + 1}: ${assignment.displayName}');
            print('  - ID: ${assignment.id}');
            print('  - Name: ${assignment.name}');
            print('  - DataType: ${assignment.dataType}');
            print('  - Status: ${assignment.status}');
          } catch (e, stackTrace) {
            print('Error parsing assignment ${i + 1}: $e');
            print('Stack trace: $stackTrace');
            print('Raw data: ${records[i]['fieldData']}');
            // Continue with other assignments
          }
        }
        
        print('Successfully parsed ${assignments.length} out of ${records.length} assignments');
        return assignments;
      }

      // FileMaker "no records match"
      if (code == '401') {
        print('No program assignments found for client: $clientId');
        return [];
      }

      throw Exception('FileMaker error $code: $msg');

    } catch (e) {
      print('=== DIO ERROR ===');
      print('Error: $e');
      if (e is DioException) {
        print('DioException type: ${e.type}');
        print('DioException message: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }
      print('=================');
      rethrow;
    }
  }

  // Session Data operations
  Future<SessionRecord> upsertSessionRecord(SessionRecord record) async {
    await _ensureAuthenticated();
    
      print('=== FILEMAKER SESSION DATA CREATE REQUEST (DIO) ===');
      print('URL: /databases/$database/layouts/api_sessiondata/records');
      print('Visit ID: ${record.visitId} (type: ${record.visitId.runtimeType})');
      print('Client ID: ${record.clientId} (type: ${record.clientId.runtimeType})');
      print('Assignment ID: ${record.assignmentId} (type: ${record.assignmentId.runtimeType})');
      print('Creating new session record...');

    try {
      // Create new record directly - without PrimaryKey (auto-generated)
      final testData = {
        'fieldData': {
          'visitId': record.visitId,  // Use visit ID as-is
          'clientId': record.clientId,
          'assignmentId': record.assignmentId,
          'startedAt_ts': record.startedAt?.toIso8601String().split('.')[0] ?? DateTime.now().toIso8601String().split('.')[0],
          'payload_json': jsonEncode(record.payload),
          'staffId': record.staffId ?? '',
        }
      };
      
      // Validate each field before sending
      print('=== FIELD VALIDATION ===');
      print('visitId: "${record.visitId}" (empty: ${record.visitId.isEmpty})');
      print('clientId: "${record.clientId}" (empty: ${record.clientId.isEmpty})');
      print('assignmentId: "${record.assignmentId}" (empty: ${record.assignmentId.isEmpty})');
      print('=======================');
      
      print('=== TESTING WITHOUT PRIMARYKEY (UPDATED) ===');
      print('Sending data: $testData');
      print('=============================================');
      
      final createResponse = await _dio.post(
        '/databases/$database/layouts/api_sessiondata/records',
        data: testData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
            'Cache-Control': 'no-cache',
          },
        ),
      );

      print('=== FILEMAKER SESSION DATA CREATE RESPONSE (DIO) ===');
      print('Status Code: ${createResponse.statusCode}');
      print('Response Data: ${createResponse.data}');
      print('====================================================');

      if (createResponse.statusCode == 200 || createResponse.statusCode == 201) {
        final data = createResponse.data as Map<String, dynamic>;
        final recordId = data['response']['recordId'];
        print('Successfully created new session record with ID: $recordId');
        return record.copyWith(id: recordId.toString());
      }
      
      throw Exception('Failed to create session record: ${createResponse.statusCode}');
      
    } catch (e) {
      print('=== DIO SESSION DATA ERROR ===');
      print('Error: $e');
      if (e is DioException) {
        print('DioException type: ${e.type}');
        print('DioException message: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }
      print('==============================');
      rethrow;
    }
  }

  // Behavior Definition operations
  Future<List<BehaviorDefinition>> getBehaviorDefinitions({String? clientId}) async {
    await _ensureAuthenticated();
    
    final query = {
      'query': [
        {'clientId': '==D2E0071C-8DCD-46B4-A758-C4147F8BBE97'},  // Search by specific client ID
      ],
      'limit': 100  // Limit to 100 records
    };

    print('=== FILEMAKER BEHAVIOR DEFINITIONS LOOKUP REQUEST (DIO) ===');
    print('URL: /databases/$database/layouts/api_behavior_defs/_find');
    print('Query: $query');
    print('Client ID: $clientId');
    print('Searching for behavior definitions for client: D2E0071C-8DCD-46B4-A758-C4147F8BBE97');

    try {
      final response = await _dio.post(
        '/databases/$database/layouts/api_behavior_defs/_find',
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

      print('=== FILEMAKER BEHAVIOR DEFINITIONS LOOKUP RESPONSE (DIO) ===');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Data: ${response.data}');
      print('========================================================');

      final data = response.data as Map<String, dynamic>;
      final msgs = (data['messages'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final code = msgs.isNotEmpty ? '${msgs.first['code']}' : null;
      final msg = msgs.isNotEmpty ? '${msgs.first['message']}' : null;

      print('=== FILEMAKER MESSAGE ANALYSIS (DIO) ===');
      print('Messages count: ${msgs.length}');
      print('First message code: $code');
      print('First message text: $msg');
      print('All messages: $msgs');
      print('=========================================');

      // FileMaker "OK"
      if (code == '0') {
        final records = (data['response']?['data'] as List?) ?? const [];
      print('=== SUCCESSFUL BEHAVIOR DEFINITIONS LOOKUP (DIO) ===');
      print('Records found: ${records.length}');
      if (records.isNotEmpty) {
        print('First record: ${records.first}');
      } else {
        print('No behavior definitions found in database');
      }
      print('=====================================================');
        
        // Parse behavior definitions with debugging
        final behaviorDefs = <BehaviorDefinition>[];
        for (int i = 0; i < records.length; i++) {
          try {
            print('Parsing behavior definition ${i + 1}: ${records[i]['fieldData']}');
            final behaviorDef = BehaviorDefinition.fromJson(records[i]['fieldData']);
            behaviorDefs.add(behaviorDef);
            print('Successfully parsed behavior definition ${i + 1}: ${behaviorDef.name}');
          } catch (e) {
            print('Error parsing behavior definition ${i + 1}: $e');
            print('Raw data: ${records[i]['fieldData']}');
          }
        }
        
        print('Successfully parsed ${behaviorDefs.length} out of ${records.length} behavior definitions');
        return behaviorDefs;
      }

      // FileMaker "no records match"
      if (code == '401') {
        print('No behavior definitions found for client: $clientId');
        return [];
      }

      throw Exception('FileMaker error $code: $msg');

    } catch (e) {
      print('=== DIO ERROR ===');
      print('Error: $e');
      if (e is DioException) {
        print('DioException type: ${e.type}');
        print('DioException message: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }
      print('=================');
      rethrow;
    }
  }

  // Behavior Log operations
  Future<BehaviorLog> createBehaviorLog(BehaviorLog log) async {
    await _ensureAuthenticated();
    
    print('=== FILEMAKER BEHAVIOR LOG CREATE REQUEST (DIO) ===');
    print('URL: /databases/$database/layouts/api_sessiondata/records');
    print('Creating new behavior log...');

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
      
      print('Simplified Behavior Log Data: $behaviorLogData');
      
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

      print('=== FILEMAKER BEHAVIOR LOG CREATE RESPONSE (DIO) ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
      print('===================================================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final recordId = data['response']['recordId'];
        print('Successfully created behavior log with ID: $recordId');
        return log.copyWith(id: recordId.toString());
      }
      
      throw Exception('Failed to create behavior log: ${response.statusCode}');
      
    } catch (e) {
      print('=== DIO BEHAVIOR LOG ERROR ===');
      print('Error: $e');
      if (e is DioException) {
        print('DioException type: ${e.type}');
        print('DioException message: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }
      print('=============================');
      rethrow;
    }
  }

  Future<BehaviorLog> updateBehaviorLog(BehaviorLog log) async {
    await _ensureAuthenticated();
    
    print('=== FILEMAKER BEHAVIOR LOG UPDATE REQUEST (DIO) ===');
    print('URL: /databases/$database/layouts/api_sessiondata/records/${log.id}');
    print('Behavior Log Data: ${log.toJson()}');
    print('Updating behavior log...');

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

      print('=== FILEMAKER BEHAVIOR LOG UPDATE RESPONSE (DIO) ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
      print('===================================================');

      if (response.statusCode == 200) {
        print('Successfully updated behavior log with ID: ${log.id}');
        return log;
      }
      
      throw Exception('Failed to update behavior log: ${response.statusCode}');
      
    } catch (e) {
      print('=== DIO BEHAVIOR LOG UPDATE ERROR ===');
      print('Error: $e');
      if (e is DioException) {
        print('DioException type: ${e.type}');
        print('DioException message: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }
      print('=====================================');
      rethrow;
    }
  }

  // Script execution
  Future<Map<String, dynamic>> evaluateAssignmentMastery(String assignmentId) async {
    await _ensureAuthenticated();
    
    final response = await http.patch(
      Uri.parse('$baseUrl/databases/$database/layouts/api_program_assignments/records/$assignmentId'),
      headers: _headers,
      body: json.encode({
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
        await http.delete(
          Uri.parse('$baseUrl/databases/$database/sessions/$_token'),
          headers: _headers,
        );
      } catch (e) {
        print('Logout error: $e');
      }
    }
    
    _token = null;
    _isAuthenticated = false;
    
    // Clear session global variables
    _currentStaffId = null;
    _currentCompanyId = null;
    _currentStaffName = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('filemaker_token');
    } catch (e) {
      print('Token removal error (ignored): $e');
    }
    
    notifyListeners();
  }
}
