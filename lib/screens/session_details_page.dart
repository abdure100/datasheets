import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/visit.dart';
import '../models/behavior_log.dart';
import '../services/filemaker_service.dart';

class SessionDetailsPage extends StatefulWidget {
  final Visit session;

  const SessionDetailsPage({
    super.key,
    required this.session,
  });

  @override
  State<SessionDetailsPage> createState() => _SessionDetailsPageState();
}

class _SessionDetailsPageState extends State<SessionDetailsPage> {
  List<BehaviorLog> _behaviorLogs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSessionDetails();
  }

  Future<void> _loadSessionDetails() async {
    setState(() => _isLoading = true);
    
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      final logs = await fileMakerService.getBehaviorLogsForVisit(widget.session.id);
      
      setState(() {
        _behaviorLogs = logs;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading session details: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSessionInfo(),
                  const SizedBox(height: 24),
                  _buildBehaviorLogs(),
                ],
              ),
            ),
    );
  }

  Widget _buildSessionInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    widget.session.clientName?.substring(0, 1).toUpperCase() ?? '?',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.session.clientName ?? 'Unknown Client',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Session ID: ${widget.session.id}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Date', _formatDate(widget.session.startTs)),
            _buildInfoRow('Start Time', _formatTime(widget.session.startTs)),
            if (widget.session.endTs != null)
              _buildInfoRow('End Time', _formatTime(widget.session.endTs)),
            if (widget.session.endTs != null)
              _buildInfoRow('Duration', _calculateDuration()),
            if (widget.session.staffName != null && widget.session.staffName!.isNotEmpty)
              _buildInfoRow('Staff', widget.session.staffName!),
            if (widget.session.notes != null && widget.session.notes!.isNotEmpty)
              _buildInfoRow('Notes', widget.session.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorLogs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Behavior Logs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_behaviorLogs.length}',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_behaviorLogs.isEmpty)
          _buildEmptyBehaviorLogs()
        else
          ..._behaviorLogs.map((log) => _buildBehaviorLogCard(log)),
      ],
    );
  }

  Widget _buildEmptyBehaviorLogs() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.psychology,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No behavior logs recorded',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This session had no behavior logging',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBehaviorLogCard(BehaviorLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getLogTypeIcon(log),
                  color: _getLogTypeColor(log),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.behaviorName ?? 'Unknown Behavior',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  _formatLogTime(log.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (log.count != null && log.count! > 0) ...[
              const SizedBox(height: 8),
              Text('Count: ${log.count}'),
            ],
            if (log.durationSec != null && log.durationSec! > 0) ...[
              const SizedBox(height: 4),
              Text('Duration: ${log.durationSec}s'),
            ],
            if (log.antecedent != null && log.antecedent!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Antecedent: ${log.antecedent}'),
            ],
            if (log.behaviorDesc != null && log.behaviorDesc!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Behavior: ${log.behaviorDesc}'),
            ],
            if (log.consequence != null && log.consequence!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Consequence: ${log.consequence}'),
            ],
            if (log.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.notes!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getLogTypeIcon(BehaviorLog log) {
    if (log.isTiming) return Icons.timer;
    if (log.isABC) return Icons.assignment;
    return Icons.add_circle;
  }

  Color _getLogTypeColor(BehaviorLog log) {
    if (log.isTiming) return Colors.blue;
    if (log.isABC) return Colors.purple;
    return Colors.orange;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatLogTime(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _calculateDuration() {
    if (widget.session.endTs == null) {
      return 'Unknown';
    }
    
    final duration = widget.session.endTs!.difference(widget.session.startTs);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  void _logout() {
    // Clear any stored session data
    // Navigate back to login page
    Navigator.pushReplacementNamed(context, '/');
  }
}
