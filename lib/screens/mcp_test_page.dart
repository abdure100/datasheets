import 'package:flutter/material.dart';
import '../services/mcp_service.dart';
import '../services/token_service.dart';
import '../config/app_config.dart';

class MCPTestPage extends StatefulWidget {
  const MCPTestPage({super.key});

  @override
  State<MCPTestPage> createState() => _MCPTestPageState();
}

class _MCPTestPageState extends State<MCPTestPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _visitIdController = TextEditingController();
  final TextEditingController _assignmentIdController = TextEditingController();
  
  String _testResults = '';
  bool _isTesting = false;
  String? _sanctumToken;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    print('🔄 MCP Test Page: Loading token...');
    final token = await TokenService.getSanctumToken();
    print('🔄 MCP Test Page: Token result: ${token != null ? "Found (${token.length} chars)" : "null"}');
    setState(() {
      _sanctumToken = token;
      if (token != null) {
        print('✅ MCP Test Page: Token loaded into state');
      } else {
        print('⚠️ MCP Test Page: No token in state');
      }
    });
  }

  void _addResult(String message) {
    setState(() {
      _testResults += '${DateTime.now().toString().substring(11, 19)}: $message\n';
    });
  }

  Future<void> _testToken() async {
    setState(() => _isTesting = true);
    _addResult('🔍 Testing Sanctum Token...');
    
    try {
      final token = await TokenService.getSanctumToken();
      if (token != null && token.isNotEmpty) {
        _addResult('✅ Token found: ${token.substring(0, 20)}...');
        _addResult('📋 Token length: ${token.length} characters');
      } else {
        _addResult('❌ No token found. Please set token using TokenService.saveSanctumToken()');
      }
    } catch (e) {
      _addResult('❌ Error checking token: $e');
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _setToken() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Sanctum Token'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Sanctum Token',
            hintText: 'Paste your Sanctum token here',
          ),
          obscureText: false,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await TokenService.saveSanctumToken(result);
        _addResult('✅ Token saved successfully');
        await _loadToken();
      } catch (e) {
        _addResult('❌ Error saving token: $e');
      }
    }
  }

  Future<void> _testChat() async {
    if (_sanctumToken == null || _sanctumToken!.isEmpty) {
      _addResult('❌ No Sanctum token available. Please set token first.');
      return;
    }

    setState(() => _isTesting = true);
    _addResult('\n🔄 Testing MCP Chat Endpoint...');
    
    try {
      final mcpService = MCPService(token: _sanctumToken);
      final message = _messageController.text.isEmpty 
          ? 'Hello, this is a test message'
          : _messageController.text;
      
      _addResult('📤 Sending message: "$message"');
      if (_visitIdController.text.isNotEmpty) {
        _addResult('📋 Visit ID: ${_visitIdController.text}');
      }
      if (_assignmentIdController.text.isNotEmpty) {
        _addResult('📋 Assignment ID: ${_assignmentIdController.text}');
      }
      
      final response = await mcpService.chat(
        message: message,
        visitId: _visitIdController.text.isEmpty ? null : _visitIdController.text,
        assignmentId: _assignmentIdController.text.isEmpty ? null : _assignmentIdController.text,
      );
      
      _addResult('✅ Chat response received');
      _addResult('📥 Response: ${response.toString().substring(0, response.toString().length > 200 ? 200 : response.toString().length)}...');
      
      if (response['response'] != null && response['response']['message'] != null) {
        _addResult('💬 Message: ${response['response']['message']}');
      }
    } catch (e) {
      _addResult('❌ Chat test failed: $e');
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _testCompletions() async {
    if (_sanctumToken == null || _sanctumToken!.isEmpty) {
      _addResult('❌ No Sanctum token available. Please set token first.');
      return;
    }

    setState(() => _isTesting = true);
    _addResult('\n🔄 Testing MCP Completions Endpoint...');
    
    try {
      final mcpService = MCPService(token: _sanctumToken);
      
      final messages = [
        {'role': 'system', 'content': 'You are a helpful assistant.'},
        {'role': 'user', 'content': _messageController.text.isEmpty 
            ? 'Say hello'
            : _messageController.text},
      ];
      
      _addResult('📤 Sending messages: ${messages.length}');
      if (_visitIdController.text.isNotEmpty) {
        _addResult('📋 Visit ID: ${_visitIdController.text}');
      }
      if (_assignmentIdController.text.isNotEmpty) {
        _addResult('📋 Assignment ID: ${_assignmentIdController.text}');
      }
      
      final response = await mcpService.completions(
        messages: messages,
        visitId: _visitIdController.text.isEmpty ? null : _visitIdController.text,
        assignmentId: _assignmentIdController.text.isEmpty ? null : _assignmentIdController.text,
        model: 'meta-llama/Meta-Llama-3.1-8B-Instruct',
        temperature: 0.7,
        maxTokens: 100,
      );
      
      _addResult('✅ Completions response received');
      _addResult('📥 Response keys: ${response.keys.join(", ")}');
      
      if (response['response'] != null) {
        final responseData = response['response'];
        if (responseData['choices'] != null && responseData['choices'].isNotEmpty) {
          final content = responseData['choices'][0]['message']['content'];
          _addResult('💬 Generated text: $content');
        }
      }
    } catch (e) {
      _addResult('❌ Completions test failed: $e');
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _testContext() async {
    if (_sanctumToken == null || _sanctumToken!.isEmpty) {
      _addResult('❌ No Sanctum token available. Please set token first.');
      return;
    }

    setState(() => _isTesting = true);
    _addResult('\n🔄 Testing MCP Context Endpoint...');
    
    try {
      final mcpService = MCPService(token: _sanctumToken);
      
      _addResult('📋 Visit ID: ${_visitIdController.text.isEmpty ? "Not provided" : _visitIdController.text}');
      _addResult('📋 Assignment ID: ${_assignmentIdController.text.isEmpty ? "Not provided" : _assignmentIdController.text}');
      
      final response = await mcpService.getContext(
        visitId: _visitIdController.text.isEmpty ? null : _visitIdController.text,
        assignmentId: _assignmentIdController.text.isEmpty ? null : _assignmentIdController.text,
      );
      
      _addResult('✅ Context response received');
      _addResult('📥 Response: ${response.toString().substring(0, response.toString().length > 300 ? 300 : response.toString().length)}...');
    } catch (e) {
      _addResult('❌ Context test failed: $e');
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _testAll() async {
    _addResult('\n🧪 Starting Full MCP Test Suite...');
    _addResult('📡 Base URL: ${AppConfig.mcpBaseUrl}');
    _addResult('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    await _testToken();
    if (_sanctumToken == null || _sanctumToken!.isEmpty) {
      _addResult('\n⚠️ Skipping API tests - no token available');
      return;
    }
    
    await Future.delayed(const Duration(seconds: 1));
    await _testContext();
    
    await Future.delayed(const Duration(seconds: 1));
    await _testChat();
    
    await Future.delayed(const Duration(seconds: 1));
    await _testCompletions();
    
    _addResult('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _addResult('✅ Test suite completed');
  }

  void _clearResults() {
    setState(() {
      _testResults = '';
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _visitIdController.dispose();
    _assignmentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP API Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearResults,
            tooltip: 'Clear Results',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Configuration Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Base URL: ${AppConfig.mcpBaseUrl}'),
                    const SizedBox(height: 4),
                    Text(
                      'Token: ${_sanctumToken != null && _sanctumToken!.isNotEmpty ? "${_sanctumToken!.substring(0, 20)}..." : "Not set"}',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Token Management
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTesting ? null : _testToken,
                    icon: const Icon(Icons.vpn_key),
                    label: const Text('Check Token'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTesting ? null : _setToken,
                    icon: const Icon(Icons.edit),
                    label: const Text('Set Token'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Input Fields
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Test Message',
                hintText: 'Enter a message to test',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _visitIdController,
                    decoration: const InputDecoration(
                      labelText: 'Visit ID (optional)',
                      hintText: 'Visit ID for context',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _assignmentIdController,
                    decoration: const InputDecoration(
                      labelText: 'Assignment ID (optional)',
                      hintText: 'Assignment ID for context',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Test Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : _testAll,
                  icon: _isTesting 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: const Text('Run All Tests'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : _testChat,
                  icon: const Icon(Icons.chat),
                  label: const Text('Test Chat'),
                ),
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : _testCompletions,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Test Completions'),
                ),
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : _testContext,
                  icon: const Icon(Icons.search),
                  label: const Text('Test Context'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Results
            Card(
              child: Container(
                height: 300,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Test Results',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearResults,
                          tooltip: 'Clear',
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          _testResults.isEmpty ? 'No tests run yet. Click a test button to begin.' : _testResults,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

