import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/behavior_definition.dart';
import '../models/behavior_log.dart';
import '../services/filemaker_service.dart';
import '../providers/session_provider.dart';
import 'behavior_modal.dart';

class BehaviorBoard extends StatefulWidget {
  final String visitId;
  final String clientId;
  final String? assignmentId; // Optional assignment ID for context-aware logging
  final Function(BehaviorLog) onBehaviorLogged;

  const BehaviorBoard({
    super.key,
    required this.visitId,
    required this.clientId,
    this.assignmentId, // Optional - if null, allows general behavior logging
    required this.onBehaviorLogged,
  });

  @override
  State<BehaviorBoard> createState() => _BehaviorBoardState();
}

class _BehaviorBoardState extends State<BehaviorBoard> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        final behaviorDefs = sessionProvider.behaviorDefinitions;
        final behaviorLogs = sessionProvider.behaviorLogs
            .where((log) => log.visitId == widget.visitId)
            .toList();
            
        // Debug prints removed

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Behavior Logging',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showBehaviorModal(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Log Behavior'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                if (behaviorDefs.isEmpty)
                  const Text(
                    'No behavior definitions found for this client.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  )
                else
                  Column(
                    children: [
                      // Quick Log Buttons
                      const Text(
                        'Quick Log:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: behaviorDefs.map((def) {
                          return ElevatedButton.icon(
                            onPressed: () => _quickLogBehavior(def),
                            icon: const Icon(Icons.add_circle),
                            label: Text(def.name),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Recent Logs
                      if (behaviorLogs.isNotEmpty) ...[
                        const Text(
                          'Recent Logs:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        ...behaviorLogs.take(5).map((log) => _buildLogCard(log)),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogCard(BehaviorLog log) {
    final behaviorDef = Provider.of<SessionProvider>(context, listen: false)
        .behaviorDefinitions
        .firstWhere((def) => def.id == log.behaviorId, orElse: () => const BehaviorDefinition(
              id: '',
              name: 'Unknown',
              code: '',
              defaultLogType: '',
              severityScaleJson: {},
            ));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getLogTypeColor(log),
          child: Icon(_getLogTypeIcon(log), color: Colors.white),
        ),
        title: Row(
          children: [
            Expanded(child: Text(behaviorDef.name)),
            if (log.assignmentId != null && log.assignmentId!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Program',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(_formatLogSummary(log)),
        trailing: Text(_formatLogTime(log)),
        onTap: () => _editBehaviorLog(log),
      ),
    );
  }

  Color _getLogTypeColor(BehaviorLog log) {
    if (log.isTiming) return Colors.blue;
    if (log.isCounting) return Colors.green;
    if (log.isABC) return Colors.purple;
    return Colors.grey;
  }

  IconData _getLogTypeIcon(BehaviorLog log) {
    if (log.isTiming) return Icons.timer;
    if (log.isCounting) return Icons.add_circle;
    if (log.isABC) return Icons.assignment;
    return Icons.info;
  }

  String _formatLogSummary(BehaviorLog log) {
    String summary = '';
    if (log.isTiming) {
      summary = 'Duration: ${log.durationSec ?? 0}s';
    } else if (log.isCounting) {
      summary = 'Count: ${log.count ?? 0}';
    } else if (log.isABC) {
      summary = 'ABC Data';
    } else {
      summary = 'Behavior logged';
    }
    
    // Add program context if available
    if (log.assignmentId != null && log.assignmentId!.isNotEmpty) {
      summary += ' • Program-specific';
    }
    
    return summary;
  }

  String _formatLogTime(BehaviorLog log) {
    final time = log.createdAt;
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }

  Future<void> _quickLogBehavior(BehaviorDefinition behaviorDef) async {
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      
      final log = BehaviorLog(
        id: '', // Will be set by FileMaker
        visitId: widget.visitId,
        clientId: widget.clientId,
        behaviorId: behaviorDef.id,
        assignmentId: widget.assignmentId, // Use context assignment ID
        count: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final savedLog = await fileMakerService.createBehaviorLog(log);
      widget.onBehaviorLogged(savedLog);
      
      if (mounted) {
        final programContext = widget.assignmentId != null ? ' to current program' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${behaviorDef.name} logged successfully$programContext'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging behavior: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showBehaviorModal(BuildContext context) async {
    final result = await showModalBottomSheet<BehaviorLog>(
      context: context,
      isScrollControlled: true,
      builder: (context) => BehaviorModal(
        visitId: widget.visitId,
        clientId: widget.clientId,
        assignmentId: widget.assignmentId, // Pass assignment context
      ),
    );
    
    if (result != null) {
      widget.onBehaviorLogged(result);
    }
  }

  Future<void> _editBehaviorLog(BehaviorLog log) async {
    final result = await showModalBottomSheet<BehaviorLog>(
      context: context,
      isScrollControlled: true,
      builder: (context) => BehaviorModal(
        visitId: widget.visitId,
        clientId: widget.clientId,
        assignmentId: widget.assignmentId, // Pass assignment context
        existingLog: log,
      ),
    );
    
    if (result != null) {
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      sessionProvider.updateBehaviorLog(result);
    }
  }
}
