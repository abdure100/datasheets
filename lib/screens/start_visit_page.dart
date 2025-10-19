import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../models/visit.dart';
import '../services/filemaker_service.dart';
import '../providers/session_provider.dart';
import '../services/seeder/fixed_database_seeder.dart';

class StartVisitPage extends StatefulWidget {
  const StartVisitPage({super.key});

  @override
  State<StartVisitPage> createState() => _StartVisitPageState();
}

class _StartVisitPageState extends State<StartVisitPage> {
  final _formKey = GlobalKey<FormState>();
  Client? _selectedClient;
  List<Client> _clients = [];
  List<Visit> _plannedVisits = [];
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
    _loadPlannedVisits();
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

  Future<void> _loadPlannedVisits() async {
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      final plannedVisits = await fileMakerService.getPlannedVisits();
      
      print('🎯 UI: Loaded ${plannedVisits.length} planned visits');
      for (int i = 0; i < plannedVisits.length; i++) {
        print('🎯 UI Visit $i: ${plannedVisits[i].clientName} - ${plannedVisits[i].appointmentDate}');
      }
      
      setState(() {
        _plannedVisits = plannedVisits;
      });
      
      print('🎯 UI: _plannedVisits.length = ${_plannedVisits.length}');
    } catch (e) {
      print('❌ UI Error loading planned visits: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading planned visits: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildPlannedVisitRow(Visit visit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Time icon
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue[100],
            child: Icon(
              Icons.schedule,
              color: Colors.blue[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Visit Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.clientName ?? 'Unknown Patient',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (visit.appointmentDate != null && visit.appointmentDate!.isNotEmpty)
                  Text(
                    'Date: ${visit.appointmentDate}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                Text(
                  'Start: ${_formatDateTime(visit.startTs)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (visit.endTs != null)
                  Text(
                    'End: ${_formatDateTime(visit.endTs!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                if (visit.staffName != null && visit.staffName!.isNotEmpty)
                  Text(
                    'Staff: ${visit.staffName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          // Start Button
          ElevatedButton.icon(
            onPressed: () => _startPlannedVisit(visit),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
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
        ],
      ),
    );
  }

  Future<void> _startPlannedVisit(Visit visit) async {
    setState(() => _selectedClient = null);
    await _startVisitWithPlanned(visit);
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

  Future<void> _runDatabaseSeeder() async {
    setState(() => _isLoading = true);
    
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      final seeder = FixedDatabaseSeeder(fileMakerService);
      
      // Show confirmation dialog
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Load Demo Data'),
          content: const Text(
            'This will create simplified demo records including:\n'
            '• 1 Visit (Client skipped - already exists)\n'
            '• 2 Behavior Definitions\n'
            '• 2 Program Assignments\n'
            '• 1 Session Record\n'
            '• 1 Behavior Log\n\n'
            'Do you want to continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Load Data'),
            ),
          ],
        ),
      );
      
      if (shouldProceed != true) {
        setState(() => _isLoading = false);
        return;
      }
      
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Loading demo data...'),
            ],
          ),
        ),
      );
      
      // Run the seeder
      final results = await seeder.seedSimplifiedData(
        username: 'nafisa@test.com',
        clientId: '03626AAB-FEF9-4325-A70D-191463DBAF2A',
        staffId: '17ED033A-7CA9-4367-AA48-3C459DBBC24C',
      );
      
      // Close progress dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show results
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Demo Data Loaded!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Client: Skipped (already exists)'),
                Text('✅ Visit: ${results['visit'] != null ? 'Created' : 'Failed'}'),
                Text('✅ Behavior Definitions: ${results['behaviorDefinitions']?.length ?? 0}'),
                Text('✅ Program Assignments: ${results['programAssignments']?.length ?? 0}'),
                Text('✅ Session Records: ${results['sessionRecords']?.length ?? 0}'),
                Text('✅ Behavior Logs: ${results['behaviorLogs']?.length ?? 0}'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadClients(); // Refresh the client list
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      
    } catch (e) {
      // Close progress dialog if open
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading demo data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startVisitWithPlanned(Visit plannedVisit) async {
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      
      // Update the existing scheduled visit to "In Progress" status
      final updatedVisit = Visit(
        id: plannedVisit.id,                    // Keep the existing visit ID
        clientId: plannedVisit.clientId,        // Keep existing client ID
        staffId: plannedVisit.staffId,          // Keep existing staff ID
        serviceCode: plannedVisit.serviceCode,  // Keep existing service code
        startTs: DateTime.now(),                // Set current time as actual start time
        endTs: plannedVisit.endTs,              // Keep existing end time
        status: 'in_progress',                  // Change status to "in_progress"
        notes: plannedVisit.notes,              // Keep existing notes
        clientName: plannedVisit.clientName,    // Keep existing client name
        staffName: plannedVisit.staffName,      // Keep existing staff name
        appointmentDate: plannedVisit.appointmentDate, // Keep existing appointment date
        timeIn: plannedVisit.timeIn,            // Keep existing time_in
      );
      
      // Update the existing visit in FileMaker (don't create new one)
      final visit = await fileMakerService.updateVisit(updatedVisit);
      
      // Create client object for session
      final client = Client(
        id: plannedVisit.clientId,
        name: plannedVisit.clientName ?? 'Unknown Client',
        dateOfBirth: null,
      );
      
      // Start the session with the updated visit
      sessionProvider.startVisit(visit, client);
      
      // Load program assignments and behavior definitions for data logging
      try {
        final assignments = await fileMakerService.getProgramAssignments(client.id);
        sessionProvider.setActiveAssignments(assignments);
        print('✅ Loaded ${assignments.length} program assignments');
      } catch (e) {
        print('⚠️ Error loading program assignments: $e');
        // Continue without assignments
      }
      
      try {
        final behaviorDefs = await fileMakerService.getBehaviorDefinitions(clientId: client.id);
        sessionProvider.setBehaviorDefinitions(behaviorDefs);
        print('✅ Loaded ${behaviorDefs.length} behavior definitions');
      } catch (e) {
        print('⚠️ Error loading behavior definitions: $e');
        // Continue without behavior definitions
      }

      // Navigate to session page
      Navigator.pushReplacementNamed(
        context,
        '/session',
        arguments: {
          'visit': visit,
          'client': client,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting planned visit: $e')),
        );
      }
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
          // Database Seeder Button
          IconButton(
            onPressed: _isLoading ? null : _runDatabaseSeeder,
            icon: const Icon(Icons.data_object),
            tooltip: 'Load Demo Data',
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
                    
                    // Scheduled Visits Section
                    if (_plannedVisits.isNotEmpty) ...[
                      const Text(
                        '📅 Scheduled Visits',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          itemCount: _plannedVisits.length,
                          itemBuilder: (context, index) {
                            final visit = _plannedVisits[index];
                            return _buildPlannedVisitRow(visit);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
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
      
      // Logout from backend if needed
      await fileMakerService.logout();
      
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
