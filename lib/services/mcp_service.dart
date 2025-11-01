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
}

