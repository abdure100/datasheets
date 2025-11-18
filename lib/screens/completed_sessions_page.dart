import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/visit.dart';
import '../services/filemaker_service.dart';

class CompletedSessionsPage extends StatefulWidget {
  const CompletedSessionsPage({super.key});

  @override
  State<CompletedSessionsPage> createState() => _CompletedSessionsPageState();
}

class _CompletedSessionsPageState extends State<CompletedSessionsPage> {
  List<Visit> _completedSessions = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedSection = 'All'; // 'All', 'Capture', 'Goal'

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
    List<Visit> filtered = _completedSessions;
    
    // Filter by section
    if (_selectedSection == 'Capture') {
      // Filter for sessions that need to be captured (e.g., not yet fully processed)
      filtered = filtered.where((session) {
        // Add your capture logic here - for now, filter by status or other criteria
        return session.status != 'Submitted' || session.notes == null || session.notes!.isEmpty;
      }).toList();
    } else if (_selectedSection == 'Goal') {
      // Filter for sessions related to goals (you may need to add goal-related filtering)
      // For now, return all sessions
      filtered = filtered;
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((session) {
        return session.clientName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      }).toList();
    }
    
    return filtered;
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
          // Bulk Export Button
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export_excel') {
                _exportToExcel();
              } else if (value == 'export_pdf') {
                _exportToPDF();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'export_excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Export to Excel'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'export_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Export to PDF'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Export Sessions',
          ),
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
      body: Column(
        children: [
          // Section Filter Tabs
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildSectionTab('All', Icons.list),
                const SizedBox(width: 8),
                _buildSectionTab('Capture', Icons.camera_alt),
                const SizedBox(width: 8),
                _buildSectionTab('Goal', Icons.flag),
              ],
            ),
          ),
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
            (session.clientName != null && session.clientName!.isNotEmpty)
                ? session.clientName!.substring(0, 1).toUpperCase()
                : '?',
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
            if (session.endTs != null)
              Text('Time: ${_formatTime(session.startTs)} - ${_formatTime(session.endTs)}')
            else Text('Start: ${_formatTime(session.startTs)}'),
            if (session.staffName != null && session.staffName!.isNotEmpty)
              Text('Staff: ${session.staffName}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (session.status == 'Submitted')
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

  Widget _buildSectionTab(String section, IconData icon) {
    final isSelected = _selectedSection == section;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSection = section;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[700] : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Text(
                section,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout() {
    // Clear any stored session data
    // Navigate back to login page
    Navigator.pushReplacementNamed(context, '/');
  }

  Future<void> _exportToExcel() async {
    if (_filteredSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sessions to export')),
      );
      return;
    }

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Sessions'];
      
      // Add headers
      sheet.appendRow([
        TextCellValue('Client Name'),
        TextCellValue('Date'),
        TextCellValue('Start Time'),
        TextCellValue('End Time'),
        TextCellValue('Duration'),
        TextCellValue('Staff Name'),
        TextCellValue('Service Code'),
        TextCellValue('Status'),
      ]);

      // Add data rows
      for (final session in _filteredSessions) {
        final duration = session.endTs != null
            ? session.endTs!.difference(session.startTs)
            : null;
        final durationStr = duration != null
            ? '${duration.inHours}h ${duration.inMinutes.remainder(60)}m'
            : 'N/A';

        sheet.appendRow([
          TextCellValue(session.clientName ?? 'N/A'),
          TextCellValue(_formatDate(session.startTs)),
          TextCellValue(_formatTime(session.startTs)),
          TextCellValue(session.endTs != null ? _formatTime(session.endTs) : 'N/A'),
          TextCellValue(durationStr),
          TextCellValue(session.staffName ?? 'N/A'),
          TextCellValue(session.serviceCode),
          TextCellValue(session.status),
        ]);
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/completed_sessions_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      // Share file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Completed Sessions Export',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel file exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting to Excel: $e')),
        );
      }
    }
  }

  Future<void> _exportToPDF() async {
    if (_filteredSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sessions to export')),
      );
      return;
    }

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Completed Sessions Report',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Header row
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Client', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Time', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Staff', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Service', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Data rows
                  ..._filteredSessions.map((session) {
                    final startTime = _formatTime(session.startTs);
                    final endTime = session.endTs != null ? _formatTime(session.endTs) : 'N/A';
                    final timeRange = '$startTime - $endTime';

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(session.clientName ?? 'N/A'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(_formatDate(session.startTs)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(timeRange),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(session.staffName ?? 'N/A'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(session.serviceCode),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ];
          },
        ),
      );

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/completed_sessions_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Share file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Completed Sessions Report',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF file exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting to PDF: $e')),
        );
      }
    }
  }
}
