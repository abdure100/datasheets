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

  Future<void> _testConnection() async {
    setState(() => _isLoading = true);
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      final success = await fileMakerService.authenticate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Connection successful!' : 'Connection failed. Check console for details.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
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

      // Create visit
      final visit = Visit(
        id: '', // Will be set by FileMaker
        clientId: _selectedClient!.id,
        staffId: _currentStaffId,
        serviceCode: _currentServiceCode,
        startTs: DateTime.now(),
        status: 'in_progress',
      );

      final createdVisit = await fileMakerService.createVisitWithDio(visit);
      
      // Start session
      sessionProvider.startVisit(createdVisit, _selectedClient!);
      
      // Load program assignments and behavior definitions
      try {
        final assignments = await fileMakerService.getProgramAssignments(_selectedClient!.id);
        sessionProvider.setActiveAssignments(assignments);
        print('Loaded ${assignments.length} program assignments');
      } catch (e) {
        print('Error loading program assignments: $e');
        // Continue without assignments
      }
      
      try {
        final behaviorDefs = await fileMakerService.getBehaviorDefinitions(clientId: _selectedClient!.id);
        sessionProvider.setBehaviorDefinitions(behaviorDefs);
        print('Loaded ${behaviorDefs.length} behavior definitions');
      } catch (e) {
        print('Error loading behavior definitions: $e');
        // Continue without behavior definitions
      }

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/session',
          arguments: {
            'visit': createdVisit,
            'client': _selectedClient!,
          },
        );
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
        title: const Text('Start Visit'),
        centerTitle: true,
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
                      'Start New Session',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    
                    // Client Selection
                    DropdownButtonFormField<Client>(
                      initialValue: _selectedClient,
                      decoration: const InputDecoration(
                        labelText: 'Client',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: _clients.map((client) {
                        return DropdownMenuItem(
                          value: client,
                          child: Text(client.name),
                        );
                      }).toList(),
                      onChanged: (client) {
                        setState(() => _selectedClient = client);
                      },
                      validator: (value) {
                        if (value == null) return 'Please select a client';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Staff Member (Read-only)
                    TextFormField(
                      initialValue: _currentStaffName,
                      decoration: const InputDecoration(
                        labelText: 'Staff Member',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
                        filled: true,
                        fillColor: Color(0xFFF5F5F5),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 20),

                    // Service Code (Read-only)
                    TextFormField(
                      initialValue: _currentServiceCode,
                      decoration: const InputDecoration(
                        labelText: 'Service Code',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.code),
                        filled: true,
                        fillColor: Color(0xFFF5F5F5),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 20),

                    // Test Connection Button
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _testConnection,
                      icon: const Icon(Icons.wifi),
                      label: const Text('Test FileMaker Connection'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Start Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _startVisit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Start Visit',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
