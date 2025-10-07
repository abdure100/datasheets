import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/visit.dart';
import '../models/client.dart';
import '../services/filemaker_service.dart';
import 'session_details_page.dart';

class CompletedSessionsPage extends StatefulWidget {
  const CompletedSessionsPage({super.key});

  @override
  State<CompletedSessionsPage> createState() => _CompletedSessionsPageState();
}

class _CompletedSessionsPageState extends State<CompletedSessionsPage> {
  List<Visit> _completedSessions = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCompletedSessions();
  }

  Future<void> _loadCompletedSessions() async {
    setState(() => _isLoading = true);
    
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      final sessions = await fileMakerService.getCompletedSessions();
      
      setState(() {
        _completedSessions = sessions;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sessions: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Visit> get _filteredSessions {
    if (_searchQuery.isEmpty) return _completedSessions;
    
    return _completedSessions.where((session) {
      return session.clientName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Sessions'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadCompletedSessions,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by client name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Sessions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSessions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _filteredSessions.length,
                        itemBuilder: (context, index) {
                          final session = _filteredSessions[index];
                          return _buildSessionCard(session);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty 
                ? 'No completed sessions found'
                : 'No sessions match your search',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Completed sessions will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionCard(Visit session) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            session.clientName?.substring(0, 1).toUpperCase() ?? '?',
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          session.clientName ?? 'Unknown Client',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${_formatDate(session.startTs)}'),
            Text('Time: ${_formatTime(session.startTs)} - ${_formatTime(session.endTs)}'),
            if (session.staffName != null)
              Text('Staff: ${session.staffName}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (session.status == 'completed')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Completed',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => _navigateToSessionDetails(session),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToSessionDetails(Visit session) {
    Navigator.pushNamed(
      context,
      '/session-details',
      arguments: {'session': session},
    );
  }
}
