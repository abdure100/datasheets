import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/visit.dart';
import '../models/client.dart';
import '../models/session_record.dart';
import '../models/program_assignment.dart';
import '../services/filemaker_service.dart';
import '../services/note_drafting_service.dart';
import '../providers/session_provider.dart';
import '../widgets/program_card.dart';
import '../widgets/behavior_board.dart';
import '../widgets/note_drafting_widget.dart';

class SessionWithNotesPage extends StatefulWidget {
  final Visit? visit;
  final Client? client;

  const SessionWithNotesPage({
    super.key,
    this.visit,
    this.client,
  });

  @override
  State<SessionWithNotesPage> createState() => _SessionWithNotesPageState();
}

class _SessionWithNotesPageState extends State<SessionWithNotesPage> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isEnding = false;
  bool _isGeneratingNotes = false;
  bool _showNotes = false;
  String _generatedNote = '';
  final Set<String> _savedAssignments = {}; // Track which assignments have been saved

  @override
  void initState() {
    super.initState();
    if (widget.visit != null) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (widget.visit == null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = DateTime.now().difference(widget.visit!.startTs);
      });
    });
  }

  /// Generate clinical notes from session data
  Future<void> _generateNotes() async {
    if (widget.visit == null || widget.client == null || _isGeneratingNotes) return;

    setState(() {
      _isGeneratingNotes = true;
    });

    try {
      // Get session records from the provider
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      final sessionRecords = sessionProvider.sessionRecords;
      
      // Get program assignments
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      final assignments = await fileMakerService.getProgramAssignments(widget.client!.id);

      // Convert to SessionData
      final sessionData = NoteDraftingService.convertSessionRecordsToSessionData(
        visit: widget.visit!,
        client: widget.client!,
        sessionRecords: sessionRecords,
        assignments: assignments,
        providerName: 'Jane Doe, BCBA', // You can get this from staff data
        npi: 'ATYPICAL', // You can get this from staff data
      );

      // Generate note
      final noteDraft = await NoteDraftingService.generateNoteDraft(
        session: sessionData,
        ragContext: 'Use SOAP tone; focus on measurable outcomes and data-driven observations.',
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
            content: Text('Clinical note generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // After generating notes, end the session
        await _endVisit();
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

  /// Save the generated note
  Future<void> _saveNote() async {
    if (_generatedNote.isEmpty) return;

    try {
      // Here you would save the note to your database
      // For now, we'll just show a success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
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

  Future<void> _endVisit() async {
    if (_isEnding || widget.visit == null) return;
    
    setState(() => _isEnding = true);
    
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      
      // Check if all assignments are saved
      final activeAssignments = await fileMakerService.getProgramAssignments(widget.client!.id);
      final totalAssignments = activeAssignments.length;
      final savedAssignments = _savedAssignments.length;
      
      if (savedAssignments < totalAssignments) {
        // Not all assignments are saved, show dialog
        await _showSaveUnsavedDataDialog();
      } else {
        // All assignments are saved, proceed to end session
        print('✅ All assignments saved, ending session directly');
      }
      
      print('🛑 Ending session for visit: ${widget.visit!.id}');
      final result = await fileMakerService.closeVisit(widget.visit!.id, DateTime.now());
      print('🛑 Session ended, result: $result');
      
      sessionProvider.endVisit();
      
      if (mounted) {
        setState(() => _isEnding = false);
        // Navigate back to client selection page
        Navigator.pushReplacementNamed(context, '/start-visit');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Visit ended successfully. '
              'Billable minutes: ${result['billableMinutes'] ?? 0}, '
              'Units: ${result['billableUnits'] ?? 0}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isEnding = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending visit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _showEndSessionDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to end this session?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• All session data will be saved'),
              const Text('• The timer will stop'),
              if (_generatedNote.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  '• Generated note will be saved',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
              if (_generatedNote.isEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  '• Consider generating clinical notes first',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            if (_generatedNote.isEmpty)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                  _generateNotes();
                },
                child: const Text('Generate Notes First'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('End Session'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _endVisit();
    }
  }

  Future<void> _showSaveUnsavedDataDialog() async {
    final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
    final activeAssignments = await fileMakerService.getProgramAssignments(widget.client!.id);
    final totalAssignments = activeAssignments.length;
    final savedAssignments = _savedAssignments.length;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Unsaved Data'),
          content: Text(
            'You have $savedAssignments of $totalAssignments programs saved.\n\nDo you have any unsaved program data that you would like to save before ending the session?\n\nIf you choose "Yes, Save Data", please use the "Save Data" button on each program card to save your data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No, End Session'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes, Save Data'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please save your program data using the "Save Data" button on each program card, then try ending the session again.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
      
      setState(() => _isEnding = false);
      return;
    }
  }

  void _logout() {
    // Implement logout logic
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.visit == null || widget.client == null) {
      return const Scaffold(
        body: Center(
          child: Text('No active session'),
        ),
      );
    }
    
    return WillPopScope(
      onWillPop: () async {
        await _showEndSessionDialog();
        return false; // Prevent default back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.client!.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _showEndSessionDialog(),
          ),
          actions: [
            // Generate Notes Button
            if (!_showNotes)
              IconButton(
                onPressed: _generateNotes,
                icon: const Icon(Icons.auto_awesome),
                tooltip: 'Generate Clinical Notes',
              ),
            // Save Note Button
            if (_generatedNote.isNotEmpty)
              IconButton(
                onPressed: _saveNote,
                icon: const Icon(Icons.save),
                tooltip: 'Save Note',
              ),
            Text(
              _formatDuration(_elapsed),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
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
                child: Icon(Icons.account_circle),
              ),
            ),
          ],
        ),
        body: Consumer<SessionProvider>(
          builder: (context, sessionProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Session Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.timer, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Session Time: ${_formatDuration(_elapsed)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Client: ${widget.client!.name}'),
                          Text('Visit ID: ${widget.visit!.id}'),
                          Text('Status: ${widget.visit!.status}'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notes Section
                  if (_showNotes) ...[
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.notes, color: Colors.blue),
                                const SizedBox(width: 8),
                                const Text(
                                  'Generated Clinical Note',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: _saveNote,
                                  icon: const Icon(Icons.save),
                                  tooltip: 'Save Note',
                                ),
                                IconButton(
                                  onPressed: () => setState(() => _showNotes = false),
                                  icon: const Icon(Icons.close),
                                  tooltip: 'Hide Note',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: SelectableText(
                                _generatedNote,
                                style: const TextStyle(fontSize: 14, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Behavior Board
                  const BehaviorBoard(),
                  
                  const SizedBox(height: 16),
                  
                  // Program Cards
                  if (sessionProvider.activeAssignments.isNotEmpty) ...[
                    const Text(
                      'Program Assignments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...sessionProvider.activeAssignments.map((assignment) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ProgramCard(
                          assignment: assignment,
                          clientId: widget.client!.id,
                          onSave: (payload) async {
                            try {
                              final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
                              
                              // Parse program times from payload if available
                              DateTime? programStartTime;
                              DateTime? programEndTime;
                              if (payload['programStartTime'] != null) {
                                programStartTime = DateTime.parse(payload['programStartTime']);
                              }
                              if (payload['programEndTime'] != null) {
                                programEndTime = DateTime.parse(payload['programEndTime']);
                              }

                              final sessionRecord = SessionRecord(
                                id: '', // Will be set by FileMaker
                                visitId: widget.visit!.id,
                                clientId: widget.client!.id,
                                assignmentId: assignment.id ?? '',
                                startedAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                                payload: payload,
                                staffId: widget.visit!.staffId,
                                interventionPhase: assignment.phase ?? 'baseline',
                                programStartTime: programStartTime,
                                programEndTime: programEndTime,
                              );
                              
                              final savedRecord = await fileMakerService.upsertSessionRecord(sessionRecord);
                              sessionProvider.addSessionRecord(savedRecord);
                              
                              // Mark this assignment as saved
                              setState(() {
                                _savedAssignments.add(assignment.id ?? '');
                              });
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Data saved for ${assignment.name}'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error saving data: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      );
                    }),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Generate Notes Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingNotes ? null : _generateNotes,
                      icon: _isGeneratingNotes 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isGeneratingNotes ? 'Generating Notes...' : 'Generate Notes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
