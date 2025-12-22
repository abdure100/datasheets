import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Service for interacting with MCP (Model Context Protocol) API endpoints
class MCPService {
  final String baseUrl;
  final String? token;
  
  MCPService({
    String? baseUrl,
    this.token,
  }) : baseUrl = baseUrl ?? AppConfig.mcpBaseUrl;

  Map<String, String> get headers => {
    if (token != null) 'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Send a chat message and get an AI response with automatic context
  /// 
  /// [message] - The user's message/question
  /// [visitId] - Optional visit ID for context filtering
  /// [assignmentId] - Optional assignment ID for context filtering
  /// [model] - AI model to use (default: meta-llama/Meta-Llama-3.1-8B-Instruct)
  /// [temperature] - Temperature for AI response (default: 0.7)
  /// [maxTokens] - Maximum tokens in response (default: 500)
  Future<Map<String, dynamic>> chat({
    required String message,
    String? visitId,
    String? assignmentId,
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    try {
      final body = <String, dynamic>{
        'message': message,
        if (visitId != null) 'visitId': visitId,
        if (assignmentId != null) 'assignmentId': assignmentId,
        if (model != null) 'model': model,
        if (temperature != null) 'temperature': temperature,
        if (maxTokens != null) 'max_tokens': maxTokens,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/mcp/chat'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['error'] ?? 'Unknown error from MCP API');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or missing token');
      } else if (response.statusCode == 422) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Validation error');
      } else {
        throw Exception('MCP API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ MCP chat error: $e');
      rethrow;
    }
  }

  /// Retrieve available context without generating an AI response
  /// 
  /// [visitId] - Optional visit ID for context filtering
  /// [assignmentId] - Optional assignment ID for context filtering
  Future<Map<String, dynamic>> getContext({
    String? visitId,
    String? assignmentId,
  }) async {
    try {
      final body = <String, dynamic>{
        if (visitId != null) 'visitId': visitId,
        if (assignmentId != null) 'assignmentId': assignmentId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/mcp/context'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['error'] ?? 'Unknown error from MCP API');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or missing token');
      } else {
        throw Exception('MCP API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ MCP getContext error: $e');
      rethrow;
    }
  }

  /// Test the API session context retrieval (useful for debugging)
  /// 
  /// [visitId] - Optional visit ID
  /// [assignmentId] - Optional assignment ID
  Future<Map<String, dynamic>> testContext({
    String? visitId,
    String? assignmentId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (visitId != null) queryParams['visitId'] = visitId;
      if (assignmentId != null) queryParams['assignmentId'] = assignmentId;

      final uri = Uri.parse('$baseUrl/mcp/test-context')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['error'] ?? 'Unknown error from MCP API');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or missing token');
      } else {
        throw Exception('MCP API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ MCP testContext error: $e');
      rethrow;
    }
  }

  /// OpenAI-compatible chat completions endpoint with context support
  /// 
  /// [messages] - List of chat messages (OpenAI format)
  /// [visitId] - Optional visit ID for context filtering
  /// [assignmentId] - Optional assignment ID for context filtering
  /// [model] - AI model to use
  /// [temperature] - Temperature for AI response
  /// [maxTokens] - Maximum tokens in response
  /// [stream] - Whether to stream the response (default: false)
  Future<Map<String, dynamic>> completions({
    required List<Map<String, String>> messages,
    String? visitId,
    String? assignmentId,
    String? model,
    double? temperature,
    int? maxTokens,
    bool stream = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'messages': messages,
        if (visitId != null) 'visitId': visitId,
        if (assignmentId != null) 'assignmentId': assignmentId,
        if (model != null) 'model': model,
        if (temperature != null) 'temperature': temperature,
        if (maxTokens != null) 'max_tokens': maxTokens,
        'stream': stream,
      };

      print('📤 MCP Completions Request:');
      print('   - visitId: ${visitId ?? "null"}');
      print('   - assignmentId: ${assignmentId ?? "null (not sent)"}');
      print('   - Request body keys: ${body.keys.toList()}');
      print('   - URL: $baseUrl/mcp/completions');
      
      // Log full request body (truncate messages if too long)
      final bodyForLog = Map<String, dynamic>.from(body);
      if (bodyForLog['messages'] != null) {
        final messages = bodyForLog['messages'] as List;
        if (messages.isNotEmpty) {
          // Show first message preview
          final firstMsg = messages[0] as Map<String, dynamic>;
          final firstContent = firstMsg['content']?.toString() ?? '';
          final preview = firstContent.length > 200 
              ? '${firstContent.substring(0, 200)}...' 
              : firstContent;
          print('   - Messages count: ${messages.length}');
          print('   - First message role: ${firstMsg['role']}');
          print('   - First message content preview: $preview');
        }
      }
      
      // Log full request body as JSON (for debugging)
      try {
        final bodyJson = jsonEncode(body);
        print('   - Full request body: $bodyJson');
      } catch (e) {
        print('   - Could not encode request body: $e');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/mcp/completions'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['error'] ?? 'Unknown error from MCP API');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or missing token');
      } else {
        throw Exception('MCP API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ MCP completions error: $e');
      rethrow;
    }
  }

  /// Generate note using the new generate-note endpoint
  /// 
  /// [prompt] - Full prompt with instructions and visit info
  /// [visitId] - Required visit ID for context retrieval
  /// [clientId] - Optional client ID
  /// [model] - AI model to use (default: meta-llama/Meta-Llama-3.1-8B-Instruct)
  /// [temperature] - Temperature for AI response (default: 0.7)
  /// [maxTokens] - Maximum tokens in response (default: 1500)
  Future<Map<String, dynamic>> generateNote({
    required String prompt,
    required String visitId,
    String? clientId,
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    try {
      final body = <String, dynamic>{
        'prompt': prompt,
        'visitId': visitId,
        if (clientId != null) 'clientId': clientId,
        if (model != null) 'model': model,
        if (temperature != null) 'temperature': temperature,
        if (maxTokens != null) 'max_tokens': maxTokens,
      };

      final fullUrl = '$baseUrl/mcp/generate-note';
      
      print('📤 MCP Generate Note Request:');
      print('   - visitId: $visitId');
      print('   - clientId: ${clientId ?? "null"}');
      print('   - Base URL: $baseUrl');
      print('   - Full URL: $fullUrl');
      print('   - Prompt length: ${prompt.length} characters');
      print('   - Prompt preview: ${prompt.length > 200 ? "${prompt.substring(0, 200)}..." : prompt}');
      print('   - Headers: ${headers.keys.toList()}');
      print('   - Body keys: ${body.keys.toList()}');

      print('📤 Sending HTTP POST request to: $fullUrl');
      print('📤 Headers: $headers');
      print('📤 Body JSON: ${jsonEncode(body)}');
      
      http.Response response;
      try {
        print('📤 About to call http.post...');
        response = await http.post(
          Uri.parse(fullUrl),
          headers: headers,
          body: jsonEncode(body),
        );
        print('📥 HTTP response received from: $fullUrl');
        print('📥 Response status: ${response.statusCode}');
      } catch (e, stackTrace) {
        print('❌ Exception during http.post: $e');
        print('❌ Exception type: ${e.runtimeType}');
        print('❌ Stack trace: $stackTrace');
        rethrow;
      }

      print('📥 Response status code: ${response.statusCode}');
      print('📥 Response body length: ${response.body.length} bytes');

      if (response.statusCode == 200) {
        print('📥 Parsing response JSON...');
        final data = jsonDecode(response.body);
        print('📥 Response parsed successfully');
        print('📥 Response keys: ${data.keys.toList()}');
        print('📥 Response success: ${data['success']}');
        print('📥 Response has note: ${data.containsKey('note')}');
        
        if (data['success'] == true) {
          final note = data['note'] as String?;
          if (note != null) {
            print('✅ Note generated successfully via MCP generate-note endpoint');
            print('✅ Note length: ${note.length} characters');
            return data;
          } else {
            print('⚠️ Response success=true but note is null or missing');
            throw Exception('Note is missing from response');
          }
        } else {
          throw Exception(data['error'] ?? 'Unknown error from MCP API');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or missing token');
      } else {
        final errorBody = response.body;
        print('❌ MCP generate-note error: ${response.statusCode} - $errorBody');
        throw Exception('MCP API error: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      print('❌ MCP generateNote error: $e');
      rethrow;
    }
  }

  /// Analyze a program using the simplified analyze endpoint
  /// 
  /// [programId] - The assignment/program ID to analyze
  /// Returns the full analysis response including mastery status
  Future<Map<String, dynamic>> analyzeProgram({
    required String programId,
  }) async {
    try {
      final body = <String, dynamic>{
        'program_id': programId,
      };

      print('📤 MCP Analyze Program Request:');
      print('   - program_id: $programId');
      print('   - URL: $baseUrl/arawello/analyze');
      print('   - Full request body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/arawello/analyze'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📥 MCP Analyze Program Response:');
      print('   - Status: ${response.statusCode}');
      print('   - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['error'] ?? data['message'] ?? 'Unknown error from analyze endpoint');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or missing token');
      } else {
        final errorBody = response.body;
        throw Exception('Analyze endpoint error: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      print('❌ MCP analyze program error: $e');
      rethrow;
    }
  }

  /// Submit Patient Rights & Responsibilities form
  /// 
  /// [payload] - Map containing all form data:
  ///   - clientId: Patient ID (required)
  ///   - guardian_name (required)
  ///   - guardian_date (required)
  ///   - qsp_name (required)
  ///   - qsp_date (required)
  ///   - All consent checkboxes (benefits_of_treatment, treatment_administration, etc.)
  ///   - Optional: signatures, interpreter fields
  Future<Map<String, dynamic>> submitRightsResponsibilities(Map<String, dynamic> payload) async {
    // This endpoint is on portal.sphereemr.com, not fms.sphereemr.com
    const String portalUrl = 'https://portal.sphereemr.com/api';
    
    try {
      final url = '$portalUrl/mcp/rights-responsibilities';
      final body = jsonEncode(payload);
      
      print('📝 Submitting Rights & Responsibilities form');
      print('   - URL: $url');
      print('   - Client ID: ${payload['clientId']}');
      print('   - Guardian: ${payload['guardian_name']}');
      print('   - Full Payload: $body');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('📥 Rights & Responsibilities Response:');
      print('   - Status: ${response.statusCode}');
      print('   - Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ Rights & Responsibilities form submitted successfully');
          return data;
        } else {
          throw Exception(data['error'] ?? data['message'] ?? 'Unknown error');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or missing token');
      } else if (response.statusCode == 422) {
        final errorBody = jsonDecode(response.body);
        throw Exception('Validation error: ${errorBody['message'] ?? errorBody['errors'] ?? response.body}');
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Rights & Responsibilities submission error: $e');
      rethrow;
    }
  }
}

