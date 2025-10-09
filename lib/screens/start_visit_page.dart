import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../models/visit.dart';
import '../services/filemaker_service.dart';
import '../providers/session_provider.dart';

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
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      final clients = await fileMakerService.getClients();
      
      // Sort clients by namefull alphabetically
      clients.sort((a, b) => a.name.compareTo(b.name));
      
      setState(() {
        _clients = clients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading clients: $e')),
        );
      }
    }
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
          // Client Info
          Expanded(
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
          // Session Button (changes based on mode)
          _isHistoricalMode
              ? ElevatedButton.icon(
                  onPressed: () => _enterManualSheet(client),
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Enter Manual Sheet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: () => _startSessionWithClient(client),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        title: const Text('Select Client'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Select a Client to Start Session',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    
                    // Historical Entry Mode Toggle (only show if staff has permission)
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
                                    const Text(
                                      'Manual Entry Mode',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
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
                    
                    // Client Selection Table
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _clients.isEmpty
                          ? const Center(
                              child: Text('No clients available'),
                            )
                          : ListView.builder(
                              itemCount: _clients.length,
                              itemBuilder: (context, index) {
                                final client = _clients[index];
                                return _buildClientRow(client);
                              },
                            ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  void _logout() {
    // Clear any stored session data
    // Navigate back to login page
    Navigator.pushReplacementNamed(context, '/');
  }
}
