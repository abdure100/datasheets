import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/client.dart';
import '../models/visit.dart';
import '../services/filemaker_service.dart';
import '../services/auth_service.dart';
import '../providers/session_provider.dart';
import '../config/app_config.dart';

class StartVisitPage extends StatefulWidget {
  const StartVisitPage({super.key});

  @override
  State<StartVisitPage> createState() => _StartVisitPageState();
}

class _StartVisitPageState extends State<StartVisitPage> {
  final _formKey = GlobalKey<FormState>();
  Client? _selectedClient;
  List<Client> _clients = [];
  bool _isLoading = false;
  bool _isHistoricalMode = false;
  final DateTime _selectedDate = DateTime.now();
  final TimeOfDay _selectedStartTime = TimeOfDay.now();
  final TimeOfDay _selectedEndTime = TimeOfDay.now();
  
  // Get current user info from FileMakerService
  String get _currentStaffId => Provider.of<FileMakerService>(context, listen: false).currentStaffId ?? '';
  String get _currentStaffName => Provider.of<FileMakerService>(context, listen: false).currentStaffName ?? 'Current User';
  String get _currentServiceCode => 'Intervention (97153)'; // Fixed service code

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    try {
      print('🔄 Loading clients...');
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      final clients = await fileMakerService.getClients();
      
      print('✅ Loaded ${clients.length} clients');
      for (int i = 0; i < clients.length; i++) {
        print('👤 Client $i: ${clients[i].name} (ID: ${clients[i].id})');
      }
      
      // Sort clients by namefull alphabetically
      clients.sort((a, b) => a.name.compareTo(b.name));
      
      setState(() {
        _clients = clients;
        _isLoading = false;
      });
      
      print('📋 Client list updated in UI');
    } catch (e) {
      print('❌ Error loading clients: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading clients: $e')),
        );
      }
    }
  }


  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }


  Widget _buildClientRow(Client client) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Text(
              client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Client Info - Wider column
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (client.dateOfBirth != null && client.dateOfBirth!.isNotEmpty)
                  Text(
                    'DOB: ${client.dateOfBirth}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          // Session Button (changes based on mode) - Constrained to take less space
          Flexible(
            flex: 1,
            child: _isHistoricalMode
              ? ElevatedButton.icon(
                  onPressed: () => _enterManualSheet(client),
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Enter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: () => _startSessionWithClient(client),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  ),
                ),
        ],
      ),
    );
  }


  Future<void> _startSessionWithClient(Client client) async {
    setState(() => _selectedClient = client);
    await _startVisit();
  }

  Future<void> _enterManualSheet(Client client) async {
    setState(() => _selectedClient = client);
    
    // Navigate to manual session page
    Navigator.pushNamed(
      context,
      '/manual-session',
      arguments: {
        'client': client,
      },
    );
  }

  /// Capture image from camera and upload to API
  Future<void> _captureAndUploadGoal() async {
    try {
      // First, select a patient/client if not already selected
      Client? selectedPatient = _selectedClient;
      
      if (selectedPatient == null) {
        // Show dialog to select a patient
        selectedPatient = await _showPatientSelectionDialog();
        if (selectedPatient == null) {
          // User cancelled patient selection
          return;
        }
      }

      // Open camera to capture image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) {
        // User cancelled
        return;
      }

      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Upload image to API
      final success = await _uploadImageToAPI(File(image.path), selectedPatient.id);

      // Close loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Goal image captured and uploaded successfully for ${selectedPatient.name}!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload goal image. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading indicator if still open
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show dialog to select a patient/client
  Future<Client?> _showPatientSelectionDialog() async {
    if (_clients.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No patients available. Please load patients first.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return null;
    }

    return showDialog<Client>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Patient'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _clients.length,
            itemBuilder: (context, index) {
              final client = _clients[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(client.name),
                onTap: () => Navigator.of(context).pop(client),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Upload image to API endpoint using multipart/form-data
  /// Route: POST /patient/{id}/goals/import
  Future<bool> _uploadImageToAPI(File imageFile, String patientId) async {
    try {
      // Build API URL: POST /patient/{id}/goals/import
      // Use webBaseUrl for web routes (different from API routes)
      final apiUrl = '${AppConfig.webBaseUrl}${AppConfig.goalsImportEndpoint}/$patientId/goals/import';
      
      print('📤 Uploading image to: $apiUrl');
      print('📤 Patient ID: $patientId');
      print('📤 Image path: ${imageFile.path}');
      print('📤 Web base URL: ${AppConfig.webBaseUrl}');

      // Fetch CSRF token first (required for web routes)
      // Laravel Sanctum provides /sanctum/csrf-cookie endpoint
      print('🔐 Fetching CSRF token from Sanctum...');
      final csrfCookieUrl = '${AppConfig.webBaseUrl}/sanctum/csrf-cookie';
      final csrfResponse = await http.get(Uri.parse(csrfCookieUrl));
      
      // Extract cookies from response
      // Cookies can be in a list or comma-separated string
      final setCookieHeaders = csrfResponse.headers['set-cookie'];
      String? sessionCookie;
      String? xsrfToken;
      
      // Handle both single string and list of cookies
      final cookieStrings = setCookieHeaders is List 
          ? (setCookieHeaders as List).cast<String>()
          : (setCookieHeaders != null ? [setCookieHeaders as String] : <String>[]);
      
      print('🍪 Received ${cookieStrings.length} cookie(s)');
      
      for (final cookieStr in cookieStrings) {
        print('🍪 Cookie: $cookieStr');
        
        // Extract laravel_session cookie
        final sessionMatch = RegExp(r'laravel_session=([^;]+)').firstMatch(cookieStr);
        if (sessionMatch != null) {
          sessionCookie = 'laravel_session=${sessionMatch.group(1)}';
          print('✅ Session cookie extracted');
        }
        
        // Extract XSRF-TOKEN cookie
        final xsrfMatch = RegExp(r'XSRF-TOKEN=([^;]+)').firstMatch(cookieStr);
        if (xsrfMatch != null) {
          xsrfToken = Uri.decodeComponent(xsrfMatch.group(1)!);
          print('✅ XSRF-TOKEN extracted: ${xsrfToken.substring(0, xsrfToken.length > 20 ? 20 : xsrfToken.length)}...');
        }
      }
      
      if (sessionCookie == null) {
        print('⚠️ No session cookie found');
      }
      if (xsrfToken == null) {
        print('⚠️ No XSRF-TOKEN found - CSRF protection may fail');
      }

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        if (sessionCookie != null) 'Cookie': sessionCookie,
        if (xsrfToken != null) 'X-XSRF-TOKEN': xsrfToken,
      });

      // Add patient_id field
      request.fields['patient_id'] = patientId;
      
      // Add CSRF token as _token field (Laravel web routes expect this)
      if (xsrfToken != null) {
        request.fields['_token'] = xsrfToken;
        print('✅ CSRF token added to request as _token field');
      } else {
        print('⚠️ No CSRF token available - request may fail with 419 error');
      }

      // Add image file to files[] array
      final fileName = imageFile.path.split('/').last;

      request.files.add(
        await http.MultipartFile.fromPath(
          'files[]',  // Laravel expects files[] array
          imageFile.path,
          filename: fileName,
        ),
      );

      // Add CSRF token if available (for web routes)
      // Note: For API routes, Bearer token is usually sufficient
      // If CSRF is required, you may need to fetch it first
      
      print('📤 Request fields: ${request.fields}');
      print('📤 Request files count: ${request.files.length}');

      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout - server may not be responding');
        },
      );
      final response = await http.Response.fromStream(streamedResponse);

      print('📤 Upload response status: ${response.statusCode}');
      print('📤 Upload response headers: ${response.headers}');
      print('📤 Upload response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Upload successful!');
        return true;
      } else {
        print('❌ Upload failed with status: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        
        // Check for common error codes
        if (response.statusCode == 401) {
          print('❌ Authentication failed - Sanctum token may be invalid or expired');
        } else if (response.statusCode == 403) {
          print('❌ Forbidden - CSRF token may be required or permission denied');
          print('❌ Web routes typically require CSRF token, not Bearer token');
          print('❌ Consider using API route: /api/patient/{id}/goals/import');
        } else if (response.statusCode == 419) {
          print('❌ CSRF token mismatch - web route requires CSRF token');
          print('❌ Solution: Use API route or fetch CSRF token first');
        } else if (response.statusCode == 404) {
          print('❌ Route not found - check if /patient/{id}/goals/import exists');
        } else if (response.statusCode == 422) {
          print('❌ Validation error - check request format');
        } else if (response.statusCode == 500) {
          print('❌ Server error - check Laravel logs');
        }
        
        return false;
      }
    } on SocketException catch (e) {
      print('❌ Network error: ${e.message}');
      print('❌ Error details: $e');
      print('❌ Make sure server is accessible at ${AppConfig.webBaseUrl}');
      return false;
    } on http.ClientException catch (e) {
      print('❌ HTTP client error: ${e.message}');
      print('❌ Error details: $e');
      if (e.message.contains('Connection refused')) {
        print('❌ Connection refused - server may not be running or URL is incorrect');
        print('❌ Expected server at: ${AppConfig.webBaseUrl}');
      }
      return false;
    } catch (e, stackTrace) {
      print('❌ Unexpected error uploading image: $e');
      print('❌ Stack trace: $stackTrace');
      if (e.toString().contains('Connection refused')) {
        print('❌ Connection refused - server is not running or URL is incorrect');
        print('❌ Expected server at: ${AppConfig.webBaseUrl}');
      } else if (e.toString().contains('timeout')) {
        print('❌ Request timeout - server may be slow or unreachable');
      }
      return false;
    }
  }


  Future<void> _testConnection() async {
    setState(() => _isLoading = true);
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      
      // Validate existing token
      final isValid = await fileMakerService.validateToken();
      
      if (isValid) {
        // Token is valid, reload clients and show success message
        await _loadClients();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection successful! Clients refreshed.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Token is invalid, FileMaker server has already logged us out
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Redirecting to login...'),
              backgroundColor: Colors.orange,
            ),
          );
          
          // Navigate to login page (FileMaker server already logged us out)
          Navigator.pushReplacementNamed(context, '/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection test error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }



  Future<void> _startVisit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);

      // Create visit with manual or current timestamp
      final startDateTime = _isHistoricalMode 
          ? DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _selectedStartTime.hour,
              _selectedStartTime.minute,
            )
          : DateTime.now();
      
      final endDateTime = _isHistoricalMode 
          ? DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _selectedEndTime.hour,
              _selectedEndTime.minute,
            )
          : null;
      
      final visit = Visit(
        id: '', // Will be set by FileMaker
        clientId: _selectedClient!.id,
        staffId: _currentStaffId,
        serviceCode: _currentServiceCode,
        startTs: startDateTime,
        endTs: endDateTime,
        status: 'in_progress',
      );

      final createdVisit = await fileMakerService.createVisitWithDio(visit, skipLocation: _isHistoricalMode);
      
      // Start session
      sessionProvider.startVisit(createdVisit, _selectedClient!);
      
      // Load program assignments and behavior definitions
      try {
        final assignments = await fileMakerService.getProgramAssignments(_selectedClient!.id);
        sessionProvider.setActiveAssignments(assignments);
      } catch (e) {
        // Continue without assignments
      }
      
      try {
        final behaviorDefs = await fileMakerService.getBehaviorDefinitions(clientId: _selectedClient!.id);
        sessionProvider.setBehaviorDefinitions(behaviorDefs);
      } catch (e) {
        // Continue without behavior definitions
      }

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (_isHistoricalMode) {
          // For manual sessions, show a message and return to client list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Manual session created. You can now enter session data.'),
              backgroundColor: Colors.green,
            ),
          );
          // Stay on the client selection page for manual entry
        } else {
          // For live sessions, navigate to session page
          Navigator.pushReplacementNamed(
            context,
            '/session',
            arguments: {
              'visit': createdVisit,
              'client': _selectedClient!,
            },
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting visit: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showLogoutDialog(),
        ),
        actions: [
          // MCP Test Button - Hidden
          // IconButton(
          //   onPressed: () => Navigator.pushNamed(context, '/mcp-test'),
          //   icon: const Icon(Icons.science),
          //   tooltip: 'Test MCP API',
          // ),
          // Behaviors Button
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/behaviors'),
            icon: const Icon(Icons.psychology),
            tooltip: 'View Behavior Definitions',
          ),
          // Completed Sessions Button
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/completed-sessions'),
            icon: const Icon(Icons.history),
            tooltip: 'View Completed Sessions',
          ),
          // Refresh/Validate Session Button
          IconButton(
            onPressed: _isLoading ? null : _testConnection,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh & Validate Session',
          ),
          // Staff Avatar with Dropdown
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  _logout();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Text(
                  _currentStaffName.isNotEmpty ? _currentStaffName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    
                    
                    // Manual Entry Mode Toggle (moved before Start Session)
                    Consumer<FileMakerService>(
                      builder: (context, fileMakerService, child) {
                        final canManualEntry = fileMakerService.currentStaffCanManualEntry ?? false;
                        
                        if (!canManualEntry) {
                          return const SizedBox.shrink(); // Hide the toggle if no permission
                        }
                        
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.history,
                                      color: _isHistoricalMode ? Theme.of(context).primaryColor : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Manual Entry Mode',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Switch(
                                      value: _isHistoricalMode,
                                      onChanged: (value) {
                                        setState(() {
                                          _isHistoricalMode = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                if (_isHistoricalMode) ...[
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Enter session data manually with start and end times',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Start a Session Now Section
                    const Text(
                      '🚀 Start a Session Now',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _clients.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No patients available (${_clients.length})',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Check console for loading details',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _clients.length,
                              itemBuilder: (context, index) {
                                final client = _clients[index];
                                print('🎨 Building UI for client: ${client.name}');
                                return _buildClientRow(client);
                              },
                            ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Past Notes Section
                    const Text(
                      '📋 Past Notes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, '/completed-sessions');
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 24, color: Colors.orange),
                              SizedBox(width: 12),
                              Text(
                                'View Completed Sessions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Capture Goal Section (similar to Past Notes)
                    const Text(
                      '🎯 Capture Goal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: _captureAndUploadGoal,
                        borderRadius: BorderRadius.circular(8),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.flag, size: 24, color: Colors.blue),
                              SizedBox(width: 12),
                              Text(
                                'Capture Goal',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout? This will end your current session.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    try {
      // Clear any stored session data
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      
      // Logout from FileMaker backend
      await fileMakerService.logout();
      
      // Logout from Laravel backend (revoke Sanctum token)
      await AuthService.logout();
      
      // Navigate back to login page
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      // Even if logout fails, still navigate to login page
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }
}
