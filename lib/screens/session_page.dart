import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/visit.dart';
import '../models/client.dart';
import '../models/session_record.dart';
import '../services/filemaker_service.dart';
import '../providers/session_provider.dart';
import '../widgets/program_card.dart';
import '../widgets/behavior_board.dart';

class SessionPage extends StatefulWidget {
  final Visit? visit;
  final Client? client;

  const SessionPage({
    super.key,
    this.visit,
    this.client,
  });

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isEnding = false;
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
          content: const Text(
            'Are you sure you want to end this session? '
            'All session data will be saved and the timer will stop.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
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
      // User confirmed, end the session
      await _endVisit();
    }
  }

  Future<void> _showSaveUnsavedDataDialog() async {
    // Get all active assignments
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
      // User wants to save data, show instructions and don't end session yet
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
      
      // Don't end the session yet, let user save data manually
      setState(() => _isEnding = false);
      return;
    }
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
          final activeAssignments = sessionProvider.activeAssignments;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Session Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Session Time - First Row
                        Row(
                          children: [
                            const Text(
                              'Session Time:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDuration(_elapsed),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // End Session Button - Second Row
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isEnding ? null : _endVisit,
                            icon: _isEnding 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.stop),
                            label: Text(_isEnding ? 'Ending...' : 'End Session'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Service: ${widget.visit!.serviceCode}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Program Assignments Section
                const Text(
                  'Program Data Collection',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                if (activeAssignments.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No active program assignments found for this client.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...activeAssignments.map((assignment) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ProgramCard(
                      assignment: assignment,
                      visitId: widget.visit!.id,
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
                          
                          // Check for mastery if this is a reduction program
                          if (assignment.dataType?.contains('reduction') == true || 
                              assignment.dataType?.contains('decrease') == true) {
                            try {
                              if (assignment.id != null) {
                                await fileMakerService.evaluateAssignmentMastery(assignment.id!);
                              }
                            } catch (e) {
                            }
                          }
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Data saved successfully'),
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
                      onBehaviorLogged: (log) {
                        sessionProvider.addBehaviorLog(log);
                      },
                    ),
                  )),
                
                const SizedBox(height: 30),
                
                // Behavior Logging Section
                const Text(
                  'Behavior Logging',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                BehaviorBoard(
                  visitId: widget.visit!.id,
                  clientId: widget.client!.id,
                  onBehaviorLogged: (log) {
                    sessionProvider.addBehaviorLog(log);
                  },
                ),
              ],
            ),
          );
        },
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
