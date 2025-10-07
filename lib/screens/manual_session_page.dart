import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../models/visit.dart';
import '../models/program_assignment.dart';
import '../models/behavior_definition.dart';
import '../services/filemaker_service.dart';
import '../widgets/program_card.dart';
import '../widgets/behavior_board.dart';

class ManualSessionPage extends StatefulWidget {
  final Client client;
  
  const ManualSessionPage({super.key, required this.client});

  @override
  State<ManualSessionPage> createState() => _ManualSessionPageState();
}

class _ManualSessionPageState extends State<ManualSessionPage> {
  final _formKey = GlobalKey<FormState>();
  late Client _client;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTimeIn = TimeOfDay.now();
  TimeOfDay _selectedTimeOut = TimeOfDay.now();
  bool _isLoading = false;
  bool _isSaving = false;
  
  List<ProgramAssignment> _assignments = [];
  List<BehaviorDefinition> _behaviorDefs = [];
  Visit? _createdVisit;

  @override
  void initState() {
    super.initState();
    _client = widget.client;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_createdVisit == null) {
      // Use post-frame callback to avoid calling ScaffoldMessenger during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
        _createVisit(); // Automatically create session
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      
      // Load program assignments
      final assignments = await fileMakerService.getProgramAssignments(_client.id);
      
      // Load behavior definitions
      final behaviorDefs = await fileMakerService.getBehaviorDefinitions(clientId: _client.id);
      
      setState(() {
        _assignments = assignments;
        _behaviorDefs = behaviorDefs;
      });
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _selectTimeIn() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimeIn,
    );
    if (picked != null && picked != _selectedTimeIn) {
      setState(() {
        _selectedTimeIn = picked;
      });
    }
  }

  Future<void> _selectTimeOut() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimeOut,
    );
    if (picked != null && picked != _selectedTimeOut) {
      setState(() {
        _selectedTimeOut = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _createVisit() async {
    if (_createdVisit != null) return; // Already created
    
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTimeIn.hour,
        _selectedTimeIn.minute,
      );
      
      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTimeOut.hour,
        _selectedTimeOut.minute,
      );
      
      final visit = Visit(
        id: '',
        clientId: _client.id,
        staffId: fileMakerService.currentStaffId ?? '',
        serviceCode: 'Intervention (97153)',
        startTs: startDateTime,
        endTs: endDateTime,
        status: 'completed',
      );

      final createdVisit = await fileMakerService.createVisitWithDio(visit, skipLocation: true);
      setState(() => _createdVisit = createdVisit);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating session: $e')),
        );
      }
    }
  }

  Future<void> _saveSession() async {
    if (_createdVisit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create the session first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      // Save session data here
      // This would include saving any program data and behavior logs
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to client selection
        Navigator.popUntil(context, (route) => route.isFirst);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving session: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _client = args?['client'] as Client;

    return Scaffold(
      appBar: AppBar(
        title: Text('Manual Session - ${_client.name}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                    // Session Details Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Session Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Date Selection
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Date:', style: TextStyle(fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      InkWell(
                                        onTap: _selectDate,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey[300]!),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.calendar_today, size: 16),
                                              const SizedBox(width: 8),
                                              Text(_formatDate(_selectedDate)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Time Selection
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Time In:', style: TextStyle(fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      InkWell(
                                        onTap: _selectTimeIn,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey[300]!),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.access_time, size: 16),
                                              const SizedBox(width: 8),
                                              Text(_formatTime(_selectedTimeIn)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Time Out:', style: TextStyle(fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      InkWell(
                                        onTap: _selectTimeOut,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey[300]!),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.access_time, size: 16),
                                              const SizedBox(width: 8),
                                              Text(_formatTime(_selectedTimeOut)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Session Status
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                border: Border.all(color: Colors.green),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    'Session created automatically',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Program Assignments
                    if (_assignments.isNotEmpty) ...[
                      const Text(
                        'Program Assignments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._assignments.map((assignment) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ProgramCard(
                          assignment: assignment,
                          visitId: _createdVisit?.id,
                          clientId: _client.id,
                          onSave: (data) {
                            // Handle program data saving
                            print('Program data saved: $data');
                          },
                          onBehaviorLogged: (behaviorLog) {
                            // Handle behavior logging
                            print('Behavior logged: ${behaviorLog.behaviorDesc}');
                          },
                        ),
                      )),
                      const SizedBox(height: 20),
                    ],
                    
                    // Behavior Board
                    if (_behaviorDefs.isNotEmpty) ...[
                      const Text(
                        'Behavior Logging',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      BehaviorBoard(
                        visitId: _createdVisit?.id ?? '',
                        clientId: _client.id,
                        assignmentId: null, // General behavior logging
                        behaviorDefinitions: _behaviorDefs, // Pass the loaded behavior definitions
                        onBehaviorLogged: (behaviorLog) {
                          // Handle behavior logging
                          print('Behavior logged: ${behaviorLog.behaviorDesc}');
                        },
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      // Debug info when no behavior definitions
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 48,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No behavior definitions found for ${_client.name}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Client ID: ${_client.id}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveSession,
                        icon: _isSaving 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Saving...' : 'Save Session'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
}
