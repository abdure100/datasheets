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
    _loadStoredToken();
  }

  bool get isAuthenticated => _isAuthenticated;

  // Validate existing token without re-authenticating
  Future<bool> validateToken() async {
    if (!_isAuthenticated || _token == null) {
      return false;
    }

    try {
      // Try to make a simple request to validate the token
      final response = await _dio.get('/databases/$database/layouts/api_staffs/records?limit=1');
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
      }
    } catch (e) {
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

    
    // Get all clients for validation
    try {
      final allClientsResponse = await _dio.get('/databases/$database/layouts/api_patients_list/records');
      final allClientsData = allClientsResponse.data as Map<String, dynamic>;
      final allClients = (allClientsData['response']?['data'] as List?) ?? const [];
      if (allClients.isNotEmpty) {
        final firstClient = allClients.first['fieldData'];
      }
    } catch (e) {
    }

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
        
        // Check what records we're getting
        if (records.isNotEmpty) {
          
          // Show all clients that will appear in dropdown
          for (int i = 0; i < records.length; i++) {
            final client = records[i]['fieldData'];
          }
          
          final firstRecord = records.first['fieldData'];
          
          // Check if all records have the same company and status
          final allCompanies = records.map((r) => r['fieldData']['Company']).toSet();
          final allStatuses = records.map((r) => r['fieldData']['Status']).toSet();
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
        if (records.isNotEmpty) {
        }

        if (records.isEmpty) return null;
        final fieldData = (records.first['fieldData'] as Map<String, dynamic>)..removeWhere((k, v) => v == null);
        
        // Store session global variables
        _currentStaffId = fieldData['PrimaryKey'];
        _currentCompanyId = fieldData['Company'];
        _currentStaffName = fieldData['FullName'];
        _currentStaffCanManualEntry = fieldData['Allow_manual_entry'] == 1;
        
        
        return Staff.fromJson(fieldData);
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
    
    
    var response = await http.post(
      Uri.parse('$baseUrl/databases/$database/layouts/api_appointments/records'),
      headers: headers,
      body: requestBody,
    );

    
    // Log FileMaker error messages
    final txt = response.body;
    Map<String, dynamic> j = {};
    try { j = jsonDecode(txt); } catch (_) {}
    if (j['messages'] != null) {
    }

    // If token expired or bad request, refresh and retry
    if (response.statusCode == 401 || response.statusCode == 400) {
      await authenticate();
      
      // Update headers with new token
      headers['Authorization'] = 'Bearer $_token';
      
      
      // Add small delay to ensure token is fully processed
      await Future.delayed(const Duration(milliseconds: 1000));
      
      response = await http.post(
        Uri.parse('$baseUrl/databases/$database/layouts/api_appointments/records'),
        headers: headers,
        body: requestBody,
      );
      
      // Log FileMaker error messages for retry
      final retryTxt = response.body;
      Map<String, dynamic> retryJ = {};
      try { retryJ = jsonDecode(retryTxt); } catch (_) {}
      if (retryJ['messages'] != null) {
      }
    }

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
      final response = await _dio.patch(
        '/databases/$database/layouts/api_appointments/records/$recordId',
        data: {
          'fieldData': {
            'end_ts': endTs.toIso8601String().split('.')[0],
            'statusInput': 'Submitted',
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


      if (response.statusCode == 200) {
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


      final data = response.data as Map<String, dynamic>;
      final msgs = (data['messages'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final code = msgs.isNotEmpty ? '${msgs.first['code']}' : null;
      final msg = msgs.isNotEmpty ? '${msgs.first['message']}' : null;


      // FileMaker "OK"
      if (code == '0') {
        final records = (data['response']?['data'] as List?) ?? const [];
        
        // Check what data we're getting
        if (records.isNotEmpty) {
          final firstRecord = records.first['fieldData'];
          
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
      // Create new record directly - without PrimaryKey (auto-generated)
      final sessionData = {
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
      
      throw Exception('Failed to create session record: ${createResponse.statusCode}');
      
    } catch (e) {
      if (e is DioException) {
      }
      rethrow;
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
