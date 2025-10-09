import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/behavior_definition.dart';
import '../models/behavior_log.dart';
import '../providers/session_provider.dart';
import 'behavior_modal.dart';

class BehaviorCard extends StatefulWidget {
  final BehaviorDefinition behaviorDefinition;
  final String? visitId;
  final String? clientId;
  final Function(BehaviorLog)? onBehaviorLogged;

  const BehaviorCard({
    super.key,
    required this.behaviorDefinition,
    this.visitId,
    this.clientId,
    this.onBehaviorLogged,
  });

  @override
  State<BehaviorCard> createState() => _BehaviorCardState();
}

class _BehaviorCardState extends State<BehaviorCard> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        // Get behavior logs for this specific behavior
        final behaviorLogs = sessionProvider.behaviorLogs
            .where((log) => 
                log.behaviorId == widget.behaviorDefinition.id &&
                log.visitId == widget.visitId)
            .toList();
        
        return Card(
          elevation: 3,
          color: Colors.orange[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.orange[300]!,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Behavior Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.behaviorDefinition.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Code: ${widget.behaviorDefinition.code}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (widget.behaviorDefinition.defaultLogType.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Type: ${widget.behaviorDefinition.defaultLogType}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Log Count Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${behaviorLogs.length} logs',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Severity Scale (if available)
                if (widget.behaviorDefinition.severityScale.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Severity Scale:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatSeverityScale(widget.behaviorDefinition.severityScale),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Recent Logs (last 3)
                if (behaviorLogs.isNotEmpty) ...[
                  const Text(
                    'Recent Logs:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...behaviorLogs.take(3).map((log) => Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.record_voice_over,
                          size: 16,
                          color: Colors.orange[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatLogSummary(log),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          _formatTime(log.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),
                ],
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.visitId != null && widget.clientId != null 
                            ? _logBehavior 
                            : null,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Log Behavior'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    if (behaviorLogs.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _viewAllLogs,
                          icon: const Icon(Icons.list, size: 16),
                          label: const Text('View All'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange[700],
                            side: BorderSide(color: Colors.orange[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
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

  String _formatSeverityScale(Map<String, dynamic> severityScale) {
    if (severityScale.isEmpty) return 'No scale defined';
    
    final entries = severityScale.entries.toList();
    if (entries.isEmpty) return 'No scale defined';
    
    return entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }

  String _formatLogSummary(BehaviorLog log) {
    final parts = <String>[];
    
    if (log.count != null && log.count! > 0) {
      parts.add('Count: ${log.count}');
    }
    
    if (log.severity != null && log.severity! > 0) {
      parts.add('Severity: ${log.severity}');
    }
    
    if (log.notes != null && log.notes!.isNotEmpty) {
      final note = log.notes!.length > 20 
          ? '${log.notes!.substring(0, 20)}...' 
          : log.notes!;
      parts.add('Note: $note');
    }
    
    return parts.isNotEmpty ? parts.join(' • ') : 'Logged';
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _logBehavior() async {
    if (widget.visitId == null || widget.clientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot log behavior: Missing visit or client information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<BehaviorLog>(
      context: context,
      isScrollControlled: true,
      builder: (context) => BehaviorModal(
        visitId: widget.visitId!,
        clientId: widget.clientId!,
        assignmentId: null, // General behavior logging
        behaviorDefinitions: [widget.behaviorDefinition],
      ),
    );
    
    if (result != null && widget.onBehaviorLogged != null) {
      widget.onBehaviorLogged!(result);
    }
  }

  void _viewAllLogs() {
    // TODO: Implement view all logs functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('View all logs functionality coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
