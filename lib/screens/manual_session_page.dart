import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../models/visit.dart';
import '../models/program_assignment.dart';
import '../models/behavior_definition.dart';
import '../models/session_record.dart';
import '../services/filemaker_service.dart';
import '../services/note_drafting_service.dart';
import '../providers/session_provider.dart';
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
  bool _isGeneratingNotes = false;
  bool _showNotes = false;
  String _generatedNote = '';
  final TextEditingController _noteController = TextEditingController();

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

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      
      // Load program assignments and filter by active status
      final allAssignments = await fileMakerService.getProgramAssignments(_client.id);
      final assignments = allAssignments.where((a) => a.isActive).toList();
      
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
        // Validate that time out is after time in
        _validateTimeOut();
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
        // Validate that time out is after time in
        _validateTimeOut();
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _validateTimeOut() {
    final timeInMinutes = _selectedTimeIn.hour * 60 + _selectedTimeIn.minute;
    final timeOutMinutes = _selectedTimeOut.hour * 60 + _selectedTimeOut.minute;
    
    if (timeOutMinutes <= timeInMinutes) {
      // If time out is not after time in, set it to 1 hour later
      final newTimeOutMinutes = timeInMinutes + 60; // Add 1 hour
      final newHour = (newTimeOutMinutes / 60).floor();
      final newMinute = newTimeOutMinutes % 60;
      
      setState(() {
        _selectedTimeOut = TimeOfDay(hour: newHour, minute: newMinute);
      });
      
      // Show warning message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Time Out must be after Time In. Adjusted to 1 hour later.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
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
        status: 'in_progress',
      );

      final createdVisit = await fileMakerService.createVisitWithDio(visit, skipLocation: true);
      setState(() => _createdVisit = createdVisit);
      
      // Initialize session provider
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      sessionProvider.startVisit(createdVisit, _client);
      sessionProvider.setActiveAssignments(_assignments);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating session: $e')),
        );
      }
    }
  }

  /// Generate clinical notes from session data
  Future<void> _generateNotes() async {
    if (_createdVisit == null || _isGeneratingNotes) return;

    setState(() {
      _isGeneratingNotes = true;
    });

    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      
      // Fetch fresh visit record from FileMaker to get latest assignedto_name
      print('🔄 Fetching fresh visit record from FileMaker...');
      final freshVisit = await fileMakerService.getVisitById(_createdVisit!.id);
      final visit = freshVisit ?? _createdVisit!;
      
      if (freshVisit != null) {
        print('✅ Fetched fresh visit record with assignedto_name: ${freshVisit.staffName}');
      } else {
        print('⚠️ Could not fetch fresh visit, using existing visit record');
      }
      
      // Fetch fresh session data from FileMaker
      print('🔄 Fetching fresh session data from FileMaker...');
      final sessionRecords = await fileMakerService.getSessionRecordsForVisit(visit.id);
      print('✅ Fetched ${sessionRecords.length} session records from FileMaker');
      
      // Get program assignments (already loaded)
      final assignments = _assignments;

      // Get staff name from assignedto_name - use currentStaffName only if assignedto_name is null/empty
      final staffName = visit.staffName?.isNotEmpty == true 
          ? visit.staffName! 
          : (fileMakerService.currentStaffName ?? 'Provider');
      final staffTitle = visit.staffTitle?.isNotEmpty == true 
          ? visit.staffTitle! 
          : 'BCBA'; // Use staff_title from visit, fallback to BCBA
      final providerName = staffTitle.isNotEmpty 
          ? '$staffName, $staffTitle' 
          : staffName;
      final npi = 'ATYPICAL'; // TODO: Get NPI from FileMaker when field is available
      
      print('👤 Provider info from visit: assignedto_name="${visit.staffName}", staff_title="${visit.staffTitle}"');
      print('👤 Provider info final: name=$staffName, title=$staffTitle, providerName=$providerName');
      
      // Convert to SessionData
      final sessionData = NoteDraftingService.convertSessionRecordsToSessionData(
        visit: visit,
        client: _client,
        sessionRecords: sessionRecords,
        assignments: assignments,
        providerName: providerName,
        npi: npi,
      );

      print('🔄 Sending session data to LLM for note generation...');
      print('📊 Session data summary:');
      print('  - Visit ID: ${_createdVisit!.id}');
      print('  - Client: ${_client.name}');
      print('  - Session Records: ${sessionRecords.length}');
      print('  - Assignments: ${assignments.length}');
      
      // Generate note with MCP context
      final noteDraft = await NoteDraftingService.generateNoteDraft(
        session: sessionData,
        ragContext: 'Use SOAP tone; focus on measurable outcomes and data-driven observations.',
        visitId: _createdVisit?.id,
      );

      setState(() {
        _generatedNote = noteDraft;
        _showNotes = true;
        _isGeneratingNotes = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clinical note generated! Please review and submit.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Show review dialog instead of automatically ending
        await _showNoteReviewDialog(noteDraft);
      }

    } catch (e) {
      setState(() {
        _isGeneratingNotes = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showNoteReviewDialog(String noteDraft) async {
    final TextEditingController editController = TextEditingController(text: noteDraft);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Review & Edit Clinical Notes'),
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: Column(
                  children: [
                    const Text(
                      'You can edit the generated notes below:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TextField(
                        controller: editController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Edit your clinical notes here...',
                          contentPadding: EdgeInsets.all(12),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Submit & End Session'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      // User confirmed, save edited note and end session
      final editedNote = editController.text.trim();
      await _saveNoteToFileMaker(editedNote);
      await _endSession();
    }
  }

  Future<void> _saveNoteToFileMaker(String note) async {
    if (_createdVisit == null) return;
    
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      
      // Save note to visit record
      await fileMakerService.updateVisitNotes(_createdVisit!.id, note);
      
      // Also save to session records if any exist
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      if (sessionProvider.sessionRecords.isNotEmpty) {
        final latestRecord = sessionProvider.sessionRecords.last;
        // Create updated record with notes
        final updatedRecord = SessionRecord(
          id: latestRecord.id,
          visitId: latestRecord.visitId,
          clientId: latestRecord.clientId,
          assignmentId: latestRecord.assignmentId,
          startedAt: latestRecord.startedAt,
          updatedAt: DateTime.now(),
          payload: latestRecord.payload,
          staffId: latestRecord.staffId,
          interventionPhase: latestRecord.interventionPhase,
          programStartTime: latestRecord.programStartTime,
          programEndTime: latestRecord.programEndTime,
          notes: note, // Add the note here
        );
        await fileMakerService.updateSessionRecord(updatedRecord);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _endSession() async {
    if (_createdVisit == null) return;
    
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      
      // Close the visit using the manually entered end time
      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTimeOut.hour,
        _selectedTimeOut.minute,
      );
      final result = await fileMakerService.closeVisit(_createdVisit!.id, endDateTime);
      
      // Clear session provider
      sessionProvider.endVisit();
      
      if (mounted) {
        // Navigate back to overview
        Navigator.pushReplacementNamed(context, '/start-visit');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Session ended successfully. '
              'Billable minutes: ${result['billableMinutes'] ?? 0}, '
              'Units: ${result['billableUnits'] ?? 0}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending session: $e'),
            backgroundColor: Colors.red,
          ),
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
      // Update visit status to Submitted when session is completed using manual end time
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTimeOut.hour,
        _selectedTimeOut.minute,
      );
      await fileMakerService.closeVisit(_createdVisit!.id, endDateTime);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Add a small delay to ensure the snackbar is shown
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Navigate back to client selection
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
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

    return WillPopScope(
      onWillPop: () async {
        await _showBackWarningDialog();
        return false; // Prevent default back navigation
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text('Manual Session - ${_client.name}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showBackWarningDialog(),
        ),
        actions: [
          // Logout Dropdown
          PopupMenuButton<String>(
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
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.account_circle, color: Colors.white),
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
                    
                    // Generate Notes Button (moved to top)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGeneratingNotes ? null : _generateNotes,
                        icon: _isGeneratingNotes 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(_isGeneratingNotes ? 'Generating Notes...' : 'Generate & Edit Notes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                          onSave: (data) async {
                            // Handle program data saving
                            await _saveProgramData(assignment.id ?? '', data);
                          },
                          onBehaviorLogged: (behaviorLog) {
                            // Handle behavior logging
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
                        },
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      // No behavior definitions available
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
                              const Text(
                                'Please contact your administrator to set up behavior definitions for this client.',
                                style: TextStyle(
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
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Future<void> _showBackWarningDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unsaved Data'),
          content: const Text(
            'You have unsaved data that will be lost. Do you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes, Delete Data'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // Delete logs related to this visitId
      await _deleteVisitLogs();
      // Go back to client list
      Navigator.pop(context);
    }
  }


  Future<void> _saveProgramData(String assignmentId, Map<String, dynamic> data) async {
    if (_createdVisit?.id == null) return;
    
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      
      // Find the assignment to get its phase
      final assignment = _assignments.firstWhere(
        (a) => a.id == assignmentId,
        orElse: () => const ProgramAssignment(
          id: '',
          clientId: '',
          name: '',
          phase: 'baseline', // Default fallback
        ),
      );
      
      // Parse program times from data if available
      DateTime? programStartTime;
      DateTime? programEndTime;
      if (data['programStartTime'] != null) {
        programStartTime = DateTime.parse(data['programStartTime']);
      }
      if (data['programEndTime'] != null) {
        programEndTime = DateTime.parse(data['programEndTime']);
      }

      // Create SessionRecord object for upsert
      final sessionRecord = SessionRecord(
        id: '', // Will be set by FileMaker
        visitId: _createdVisit!.id,
        clientId: _client.id,
        assignmentId: assignmentId,
        startedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        payload: data,
        staffId: fileMakerService.currentStaffId,
        interventionPhase: assignment.phase ?? 'baseline',
        programStartTime: programStartTime,
        programEndTime: programEndTime,
      );
      
      // Use upsertSessionRecord to handle both create and update
      await fileMakerService.upsertSessionRecord(sessionRecord);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Program data saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving program data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteVisitLogs() async {
    if (_createdVisit?.id == null) return;
    
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      // Delete behavior logs for this visit
      await fileMakerService.deleteBehaviorLogsForVisit(_createdVisit!.id);
      // Delete the visit itself
      await fileMakerService.deleteVisit(_createdVisit!.id);
    } catch (e) {
    }
  }



  void _logout() {
    // Clear any stored session data
    // Navigate back to login page
    Navigator.pushReplacementNamed(context, '/');
  }
}
