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
      
      final result = await fileMakerService.closeVisit(widget.visit!.id, DateTime.now());
      
      sessionProvider.endVisit();
      
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
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

  @override
  Widget build(BuildContext context) {
    if (widget.visit == null || widget.client == null) {
      return const Scaffold(
        body: Center(
          child: Text('No active session'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client!.name),
        actions: [
          Text(
            _formatDuration(_elapsed),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Session Time: ${_formatDuration(_elapsed)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
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
                              ),
                            ),
                          ],
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
                      onSave: (payload) async {
                        try {
                          final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
                          
                          final sessionRecord = SessionRecord(
                            id: '', // Will be set by FileMaker
                            visitId: widget.visit!.id,
                            clientId: widget.client!.id,
                            assignmentId: assignment.id ?? '',
                            startedAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                            payload: payload,
                            staffId: widget.visit!.staffId,
                          );
                          
                          final savedRecord = await fileMakerService.upsertSessionRecord(sessionRecord);
                          sessionProvider.addSessionRecord(savedRecord);
                          
                          // Check for mastery if this is a reduction program
                          if (assignment.dataType?.contains('reduction') == true || 
                              assignment.dataType?.contains('decrease') == true) {
                            try {
                              if (assignment.id != null) {
                                await fileMakerService.evaluateAssignmentMastery(assignment.id!);
                              }
                            } catch (e) {
                              print('Mastery evaluation error: $e');
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
    );
  }
}
