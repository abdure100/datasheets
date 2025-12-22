import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/filemaker_service.dart';
import '../services/auth_service.dart';
import '../services/mcp_service.dart';
import '../services/token_service.dart';
import 'start_visit_page.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  String get _currentStaffName => Provider.of<FileMakerService>(context, listen: false).currentStaffName ?? 'Current User';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showLogoutDialog(),
        ),
        actions: [
          // Behaviors Button
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/behaviors'),
            icon: const Icon(Icons.psychology),
            tooltip: 'View Behavior Definitions',
          ),
          // Completed Sessions Button
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/completed-sessions'),
            icon: const Icon(Icons.history),
            tooltip: 'View Completed Sessions',
          ),
          // Staff Avatar with Dropdown
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'profile') {
                  _showProfileDialog();
                } else if (value == 'logout') {
                  _logout();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text('Profile'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
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
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Text(
                  _currentStaffName.isNotEmpty ? _currentStaffName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Patients',
            ),
            Tab(
              icon: Icon(Icons.description),
              text: 'Forms',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Tab 1: Patients - client list and session management
          DatasheetTab(),
          // Tab 2: Forms - shows all form types to select from
          ConsentBehavioralHealthTab(),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout? This will end your current session.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _logout();
    }
  }

  void _showProfileDialog() {
    final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
    final staffName = fileMakerService.currentStaffName ?? 'Unknown';
    final companyName = fileMakerService.currentCompanyName ?? 'Unknown Company';
    final staffEmail = fileMakerService.currentStaffEmail ?? 'No email';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                staffName.isNotEmpty ? staffName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(staffName, style: const TextStyle(fontSize: 18)),
                  Text(companyName, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(staffEmail),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Company'),
              subtitle: Text(companyName),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      await fileMakerService.logout();
      await AuthService.logout();
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }
}

/// Datasheet Tab - Contains client list and session management
class DatasheetTab extends StatelessWidget {
  const DatasheetTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const DatasheetTabContent();
  }
}

/// Forms Tab - Shows form type boxes
class ConsentBehavioralHealthTab extends StatelessWidget {
  const ConsentBehavioralHealthTab({super.key});

  // Available form types
  static const List<Map<String, dynamic>> _formTypes = [
    {
      'id': 'patient_rights_responsibilities',
      'name': 'Patient Rights & Responsibilities',
      'description': 'Outlines patient rights and responsibilities for services',
      'icon': Icons.gavel,
      'color': Colors.indigo,
    },
    {
      'id': 'consent_behavioral_health_aba',
      'name': 'Consent for Behavioral Health & ABA',
      'description': 'Consent for behavioral health and ABA services',
      'icon': Icons.health_and_safety,
      'color': Colors.teal,
    },
    {
      'id': 'consent_evaluation',
      'name': 'Consent for Evaluation',
      'description': 'Consent for diagnostic and functional evaluations',
      'icon': Icons.assignment,
      'color': Colors.purple,
    },
    {
      'id': 'hipaa_authorization',
      'name': 'HIPAA Authorization',
      'description': 'Authorization for release of health information',
      'icon': Icons.security,
      'color': Colors.blue,
    },
    {
      'id': 'telehealth_consent',
      'name': 'Telehealth Consent',
      'description': 'Consent for telehealth/remote services',
      'icon': Icons.videocam,
      'color': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Header section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Select a form',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
          
          // Form type cards grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final formType = _formTypes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FormTypeBox(formType: formType),
                  );
                },
                childCount: _formTypes.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Form type box widget
class _FormTypeBox extends StatelessWidget {
  final Map<String, dynamic> formType;
  
  const _FormTypeBox({required this.formType});

  @override
  Widget build(BuildContext context) {
    final Color color = formType['color'] as Color;
    
    return Card(
      elevation: 2,
      shadowColor: color.withAlpha(40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openFormType(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                color.withAlpha(15),
              ],
            ),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  formType['icon'] as IconData,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Text(
                  formType['name'],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Arrow indicator
              Icon(
                Icons.chevron_right,
                color: color.withAlpha(150),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFormType(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormTypeClientsPage(formType: formType),
      ),
    );
  }
}

/// Page showing clients for a specific form type
class FormTypeClientsPage extends StatefulWidget {
  final Map<String, dynamic> formType;

  const FormTypeClientsPage({super.key, required this.formType});

  @override
  State<FormTypeClientsPage> createState() => _FormTypeClientsPageState();
}

class _FormTypeClientsPageState extends State<FormTypeClientsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _clients = [];
  List<Map<String, dynamic>> _pendingForms = [];
  List<Map<String, dynamic>> _completedForms = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadClients(); // This also calls _loadForms after clients are loaded
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      final clients = await fileMakerService.getClients();
      clients.sort((a, b) => a.name.compareTo(b.name));
      setState(() {
        _clients = clients;
        _isLoading = false;
      });
      // Load forms after clients so we have client names available
      await _loadForms();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadForms() async {
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      
      // Only load for patient_rights_responsibilities for now
      if (widget.formType['id'] == 'patient_rights_responsibilities') {
        final records = await fileMakerService.getPatientRightsRecords();
        
        // Match client names with records
        final formsWithClientNames = records.map((record) {
          // Find client name from _clients list
          final clientId = record['clientId'];
          final matchingClients = _clients.where((c) => c.id == clientId);
          final clientName = matchingClients.isNotEmpty 
              ? matchingClients.first.name 
              : 'Unknown Client';
          
          return {
            ...record,
            'clientName': clientName,
          };
        }).toList();
        
        // For now, all submitted forms go to "pending"
        // In future, we could add a status field to differentiate pending vs completed
        setState(() {
          _pendingForms = formsWithClientNames;
          _completedForms = [];
        });
      } else {
        setState(() {
          _pendingForms = [];
          _completedForms = [];
        });
      }
    } catch (e) {
      print('Error loading forms: $e');
      setState(() {
        _pendingForms = [];
        _completedForms = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.formType['color'] as Color;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.formType['name']),
        backgroundColor: color,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Add'),
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending'),
            Tab(icon: Icon(Icons.check_circle_outline), text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Add Tab - Client list
          _buildAddTab(color),
          // Pending Tab
          _buildPendingTab(color),
          // Completed Tab
          _buildCompletedTab(color),
        ],
      ),
    );
  }

  Widget _buildAddTab(Color color) {
    return Column(
      children: [
        // Description header
        Container(
          padding: const EdgeInsets.all(16),
          color: color.withAlpha(20),
          child: Row(
            children: [
              Icon(widget.formType['icon'] as IconData, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.formType['description'],
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search clients...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        // Client list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildClientList(),
        ),
      ],
    );
  }

  Widget _buildClientList() {
    // Get client IDs that already have forms (pending or completed)
    final clientsWithForms = <String>{
      ..._pendingForms.map((f) => f['clientId']?.toString() ?? ''),
      ..._completedForms.map((f) => f['clientId']?.toString() ?? ''),
    };
    
    // Debug: print what we're comparing
    print('📋 Clients with forms: $clientsWithForms');
    print('📋 All client IDs: ${_clients.map((c) => c.id).toList()}');
    
    // Filter clients: match search AND don't have a form yet
    final filteredClients = _clients.where((client) {
      final matchesSearch = client.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final hasNoForm = !clientsWithForms.contains(client.id);
      print('  👤 ${client.name}: id=${client.id}, hasNoForm=$hasNoForm');
      return matchesSearch && hasNoForm;
    }).toList();

    if (filteredClients.isEmpty) {
      // Check if it's because all clients have forms or just no search results
      final allClientsHaveForms = _clients.isNotEmpty && 
          _clients.every((c) => clientsWithForms.contains(c.id));
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              allClientsHaveForms ? Icons.check_circle_outline : Icons.people_outline, 
              size: 64, 
              color: allClientsHaveForms ? Colors.green[300] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              allClientsHaveForms 
                  ? 'All clients have forms' 
                  : 'No clients found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            if (allClientsHaveForms)
              Text(
                'Check the Pending or Completed tabs',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              )
            else
              TextButton.icon(
                onPressed: _loadClients,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClients,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredClients.length,
        itemBuilder: (context, index) {
          final client = filteredClients[index];
          return _buildClientCard(client);
        },
      ),
    );
  }

  Widget _buildClientCard(dynamic client) {
    final Color color = widget.formType['color'] as Color;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color.withAlpha(30),
          child: Text(
            client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ),
        title: Text(
          client.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: client.dateOfBirth != null && client.dateOfBirth!.isNotEmpty
            ? Text('DOB: ${client.dateOfBirth}')
            : null,
        trailing: ElevatedButton.icon(
          onPressed: () => _openForm(client),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add'),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  void _openForm(dynamic client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ConsentFormSheet(
            client: client,
            formTypeId: widget.formType['id'],
            scrollController: scrollController,
            onSubmit: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.formType['name']} submitted for ${client.name}'),
                  backgroundColor: Colors.green,
                ),
              );
              await _loadForms(); // Refresh forms list after submit
              // Switch to Pending tab to show the new record
              _tabController.animateTo(1);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPendingTab(Color color) {
    if (_pendingForms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pending_actions, size: 64, color: Colors.orange[300]),
            const SizedBox(height: 16),
            Text(
              'No pending forms',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Forms awaiting signature or completion will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadForms,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingForms.length,
        itemBuilder: (context, index) {
          final form = _pendingForms[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Colors.orange[100],
                child: Icon(Icons.pending_actions, color: Colors.orange[700]),
              ),
              title: Text(form['clientName'] ?? 'Unknown Client'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Guardian: ${form['guardian_name'] ?? 'N/A'}'),
                  Text('Date: ${form['guardian_date'] ?? 'N/A'}'),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.visibility, color: color),
                onPressed: () {
                  _showFormDetails(form, color);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompletedTab(Color color) {
    if (_completedForms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
            const SizedBox(height: 16),
            Text(
              'No completed forms',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed forms will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadForms,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _completedForms.length,
        itemBuilder: (context, index) {
          final form = _completedForms[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Colors.green[100],
                child: Icon(Icons.check_circle, color: Colors.green[700]),
              ),
              title: Text(form['clientName'] ?? 'Unknown Client'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Guardian: ${form['guardian_name'] ?? 'N/A'}'),
                  Text('Date: ${form['guardian_date'] ?? 'N/A'}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.visibility, color: color),
                    onPressed: () {
                      _showFormDetails(form, color);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.grey),
                    onPressed: () {
                      // TODO: Download PDF
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFormDetails(Map<String, dynamic> form, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.description, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                form['clientName'] ?? 'Form Details',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Guardian Name', form['guardian_name'] ?? 'N/A'),
              _detailRow('Date Signed', form['guardian_date'] ?? 'N/A'),
              const Divider(),
              _detailRow('Consent for Data Collection', form['consent_for_data_collection'] == 1 ? '✓ Yes' : '✗ No'),
              _detailRow('Release of Information', form['release_of_Information'] == 1 ? '✓ Yes' : '✗ No'),
              _detailRow('Telehealth Consent', form['telehealth_consent'] == 1 ? '✓ Yes' : '✗ No'),
              _detailRow('Financial Responsibility', form['financialResponsibility'] == 1 ? '✓ Yes' : '✗ No'),
              _detailRow('Client Rights & Responsibilities', form['client_rights_responsibilites'] == 1 ? '✓ Yes' : '✗ No'),
              _detailRow('Benefits of Treatment', form['benefits_of_treatment'] == 1 ? '✓ Yes' : '✗ No'),
              const Divider(),
              _detailRow('Record ID', form['recordId'] ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}

/// Consent Form Bottom Sheet
class ConsentFormSheet extends StatefulWidget {
  final dynamic client;
  final String formTypeId;
  final ScrollController scrollController;
  final VoidCallback onSubmit;

  const ConsentFormSheet({
    super.key,
    required this.client,
    required this.formTypeId,
    required this.scrollController,
    required this.onSubmit,
  });

  @override
  State<ConsentFormSheet> createState() => _ConsentFormSheetState();
}

class _ConsentFormSheetState extends State<ConsentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  
  // Caregivers/Guardians list from FileMaker
  List<Map<String, dynamic>> _caregivers = [];
  Map<String, dynamic>? _selectedCaregiver;
  bool _isLoadingCaregivers = true;
  
  // ==========================================
  // Patient Rights & Responsibilities Fields
  // API: https://portal.sphereemr.com/api/mcp/rights-responsibilities
  // ==========================================
  
  // Section 1: ABA Treatment Informed Consent
  bool _benefitsOfTreatment = false;
  bool _treatmentAdministration = false;
  bool _risksSideEffects = false;
  bool _alternativeTreatments = false;
  bool _consequencesNonTreatment = false;
  
  // Section 2: Data & Privacy
  bool _consentForDataCollection = false;
  bool _releaseOfInformation = false;
  bool _telehealthConsent = false;
  
  // Section 3: Financial & Administrative
  bool _financialResponsibility = false;
  bool _clientRightsResponsibilities = false;
  
  // Guardian Signature
  DateTime? _guardianDate;
  final List<Offset?> _guardianSignaturePoints = [];
  bool _guardianSignatureCaptured = false;
  String _guardianRelationship = '';
  
  // Interpreter Signature (optional)
  bool _interpreterUsed = false;
  Map<String, dynamic>? _selectedInterpreter;
  final _interpreterNameController = TextEditingController();
  DateTime? _interpreterDate;
  final List<Offset?> _interpreterSignaturePoints = [];
  bool _interpreterSignatureCaptured = false;
  
  // QSP Signature
  final _qspNameController = TextEditingController();
  DateTime? _qspDate;
  final List<Offset?> _qspSignaturePoints = [];
  bool _qspSignatureCaptured = false;
  
  // ==========================================
  // Generic Consent Form Fields (for other form types)
  // ==========================================
  // Section Initials (checkboxes representing initials)
  bool _initialsEvaluation = false;
  bool _initialsReleaseInfo = false;
  bool _initialsTelehealth = false;
  bool _initialsFinancial = false;
  bool _initialsClientRights = false;
  bool _initialsRisksBenefits = false;
  
  // Final Consent
  bool _consentForServices = false;
  final _clientPrintedNameController = TextEditingController();
  DateTime? _clientSignatureDate;
  final List<Offset?> _clientSignaturePoints = [];
  bool _clientSignatureCaptured = false;
  
  // Provider Verification
  bool _providerVerification = false;
  final _providerNameController = TextEditingController();
  DateTime? _providerSignatureDate;
  final List<Offset?> _providerSignaturePoints = [];
  bool _providerSignatureCaptured = false;

  // Form type helpers
  static const Map<String, Map<String, dynamic>> _formTypeDetails = {
    'patient_rights_responsibilities': {
      'name': 'Patient Rights & Responsibilities',
      'icon': Icons.gavel,
      'color': Colors.indigo,
    },
    'consent_behavioral_health_aba': {
      'name': 'Consent for Behavioral Health & ABA',
      'icon': Icons.health_and_safety,
      'color': Colors.teal,
    },
    'consent_evaluation': {
      'name': 'Consent for Evaluation',
      'icon': Icons.assignment,
      'color': Colors.purple,
    },
    'hipaa_authorization': {
      'name': 'HIPAA Authorization',
      'icon': Icons.security,
      'color': Colors.blue,
    },
    'telehealth_consent': {
      'name': 'Telehealth Consent',
      'icon': Icons.videocam,
      'color': Colors.green,
    },
  };

  String get _formTypeName => 
    _formTypeDetails[widget.formTypeId]?['name'] ?? 'Consent Form';
  
  IconData get _formTypeIcon => 
    _formTypeDetails[widget.formTypeId]?['icon'] ?? Icons.description;
  
  Color get _formTypeColor => 
    _formTypeDetails[widget.formTypeId]?['color'] ?? Colors.blue;

  @override
  void initState() {
    super.initState();
    _loadCaregivers();
  }

  Future<void> _loadCaregivers() async {
    setState(() => _isLoadingCaregivers = true);
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      final caregivers = await fileMakerService.getCaregivers(patientId: widget.client.id);
      setState(() {
        _caregivers = caregivers;
        _isLoadingCaregivers = false;
        // Auto-select primary caregiver if available
        final primary = caregivers.where((c) => c['isPrimary'] == true).toList();
        if (primary.isNotEmpty) {
          _selectedCaregiver = primary.first;
        }
      });
    } catch (e) {
      print('Error loading caregivers: $e');
      setState(() => _isLoadingCaregivers = false);
    }
  }

  @override
  void dispose() {
    _clientPrintedNameController.dispose();
    _providerNameController.dispose();
    super.dispose();
  }

  // Validation for Patient Rights & Responsibilities form
  bool get _canSubmitPatientRights =>
    _selectedCaregiver != null &&
    _guardianSignatureCaptured;
    // For testing - simplified validation. Full validation:
    // _consentForDataCollection &&
    // _releaseOfInformation &&
    // _telehealthConsent &&
    // _financialResponsibility &&
    // _clientRightsResponsibilities &&
    // _benefitsOfTreatment &&
    // _guardianDate != null;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _formTypeColor.withAlpha(40),
                  child: Icon(_formTypeIcon, color: _formTypeColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formTypeName,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                      Text(
                        widget.client.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Form content - different for each form type
          Expanded(
            child: _buildFormByType(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Route to the correct form based on form type
  Widget _buildFormByType() {
    switch (widget.formTypeId) {
      case 'patient_rights_responsibilities':
        return _buildPatientRightsForm();
      case 'consent_behavioral_health_aba':
        return _buildConsentBehavioralHealthForm();
      case 'consent_evaluation':
        return _buildConsentEvaluationForm();
      case 'hipaa_authorization':
        return _buildHipaaAuthorizationForm();
      case 'telehealth_consent':
        return _buildTelehealthConsentForm();
      default:
        return _buildGenericConsentForm();
    }
  }

  // ==========================================
  // Patient Rights & Responsibilities Form
  // ==========================================
  Widget _buildPatientRightsForm() {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // Consent for Data Collection
        _buildConsentCheckbox(
          title: 'Consent for Data Collection',
          description: 'I consent to the collection and use of my personal and health data for treatment purposes.',
          value: _consentForDataCollection,
          onChanged: (v) => setState(() => _consentForDataCollection = v ?? false),
          fieldName: 'consent_for_data_collection',
        ),
        const SizedBox(height: 16),
        
        // Release of Information
        _buildConsentCheckbox(
          title: 'Release of Information',
          description: 'I authorize the release of my information to relevant healthcare providers and insurers as necessary.',
          value: _releaseOfInformation,
          onChanged: (v) => setState(() => _releaseOfInformation = v ?? false),
          fieldName: 'release_of_Information',
        ),
        const SizedBox(height: 16),
        
        // Telehealth Consent
        _buildConsentCheckbox(
          title: 'Telehealth Consent',
          description: 'I consent to receive services via telehealth/telemedicine when appropriate.',
          value: _telehealthConsent,
          onChanged: (v) => setState(() => _telehealthConsent = v ?? false),
          fieldName: 'telehealth_consent',
        ),
        const SizedBox(height: 16),
        
        // Financial Responsibility
        _buildConsentCheckbox(
          title: 'Financial Responsibility',
          description: 'I understand and accept responsibility for any charges not covered by insurance.',
          value: _financialResponsibility,
          onChanged: (v) => setState(() => _financialResponsibility = v ?? false),
          fieldName: 'financial_responsibilty',
        ),
        const SizedBox(height: 16),
        
        // Client Rights & Responsibilities
        _buildConsentCheckbox(
          title: 'Client Rights & Responsibilities',
          description: 'I have received and understand the Client Rights and Responsibilities document.',
          value: _clientRightsResponsibilities,
          onChanged: (v) => setState(() => _clientRightsResponsibilities = v ?? false),
          fieldName: 'client_rights_responsibilites',
        ),
        const SizedBox(height: 16),
        
        // Benefits of Treatment
        _buildConsentCheckbox(
          title: 'Benefits of Treatment',
          description: 'I have been informed of the potential benefits and risks of treatment.',
          value: _benefitsOfTreatment,
          onChanged: (v) => setState(() => _benefitsOfTreatment = v ?? false),
          fieldName: 'benefits_of_treatment',
        ),
        const SizedBox(height: 16),
        
        // Treatment Administration
        _buildConsentCheckbox(
          title: 'Treatment Administration',
          description: 'I consent to the administration of treatment as outlined in my treatment plan.',
          value: _treatmentAdministration,
          onChanged: (v) => setState(() => _treatmentAdministration = v ?? false),
          fieldName: 'treatment_administration',
        ),
        const SizedBox(height: 16),
        
        // Risks & Side Effects
        _buildConsentCheckbox(
          title: 'Risks & Side Effects',
          description: 'I have been informed of the potential risks and side effects of treatment.',
          value: _risksSideEffects,
          onChanged: (v) => setState(() => _risksSideEffects = v ?? false),
          fieldName: 'risks_side_effects',
        ),
        const SizedBox(height: 16),
        
        // Alternative Treatments
        _buildConsentCheckbox(
          title: 'Alternative Treatments',
          description: 'I have been informed of alternative treatment options available to me.',
          value: _alternativeTreatments,
          onChanged: (v) => setState(() => _alternativeTreatments = v ?? false),
          fieldName: 'alternative_treatments',
        ),
        const SizedBox(height: 16),
        
        // Consequences of Non-Treatment
        _buildConsentCheckbox(
          title: 'Consequences of Non-Treatment',
          description: 'I have been informed of the potential consequences of not receiving treatment.',
          value: _consequencesNonTreatment,
          onChanged: (v) => setState(() => _consequencesNonTreatment = v ?? false),
          fieldName: 'consequences_non_treatment',
        ),
        const SizedBox(height: 24),
        
        // Divider
        const Divider(thickness: 2),
        const SizedBox(height: 24),
        
        // Guardian Signature Section
        _buildSectionTitle('Guardian Signature'),
        const SizedBox(height: 16),
        
        // Guardian Dropdown
        _isLoadingCaregivers
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Loading guardians...'),
                  ],
                ),
              )
            : _caregivers.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange[700]),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('No guardians found. Please add a guardian in FileMaker first.'),
                        ),
                      ],
                    ),
                  )
                : DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedCaregiver,
                    decoration: InputDecoration(
                      labelText: 'Select Guardian *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: _caregivers.map((caregiver) {
                      final name = caregiver['name'] ?? '';
                      final relationship = caregiver['relationship'] ?? '';
                      final isPrimary = caregiver['isPrimary'] == true;
                      String displayText = name.isNotEmpty ? name : 'Guardian';
                      if (relationship.isNotEmpty) displayText += ' ($relationship)';
                      if (isPrimary) displayText += ' ✓';
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: caregiver,
                        child: Text(displayText, style: const TextStyle(fontSize: 15)),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedCaregiver = value),
                    validator: (value) => value == null ? 'Please select a guardian' : null,
                    isExpanded: true,
                  ),
        const SizedBox(height: 16),

        // Guardian Signature Pad (optimized)
        Text(
          'Guardian Signature *',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        SignaturePad(
          height: 150,
          points: _guardianSignaturePoints,
          onSignatureChanged: (hasSignature) {
            setState(() {
              _guardianSignatureCaptured = hasSignature;
              if (hasSignature) {
                _guardianDate ??= DateTime.now();
              }
            });
          },
        ),
        if (_guardianSignatureCaptured)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  'Signature captured',
                  style: TextStyle(color: Colors.green[600], fontSize: 12),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        
        // Guardian Date
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 1)),
            );
            if (date != null) {
              setState(() => _guardianDate = date);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  _guardianDate != null
                      ? '${_guardianDate!.month.toString().padLeft(2, '0')} / ${_guardianDate!.day.toString().padLeft(2, '0')} / ${_guardianDate!.year}'
                      : 'Date *',
                  style: TextStyle(
                    fontSize: 16,
                    color: _guardianDate != null ? Colors.black : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Interpreter Section
        const Divider(thickness: 1),
        const SizedBox(height: 16),
        
        // Was Interpreter Used?
        SwitchListTile(
          title: const Text(
            'Was an interpreter used?',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: const Text('If yes, please provide interpreter details below'),
          value: _interpreterUsed,
          onChanged: (value) {
            setState(() {
              _interpreterUsed = value;
              if (!value) {
                _selectedInterpreter = null;
                _interpreterSignaturePoints.clear();
                _interpreterSignatureCaptured = false;
                _interpreterDate = null;
              }
            });
          },
          activeColor: Colors.indigo,
        ),
        
        // Interpreter Details (shown only if interpreter was used)
        if (_interpreterUsed) ...[
          const SizedBox(height: 16),
          
          // Interpreter Dropdown (using caregivers/providers list)
          Text(
            'Select Interpreter *',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                isExpanded: true,
                hint: const Text('Select Interpreter'),
                value: _selectedInterpreter,
                items: _caregivers.map((caregiver) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: caregiver,
                    child: Text(caregiver['name'] ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedInterpreter = value;
                    _interpreterDate ??= DateTime.now();
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Interpreter Signature Pad
          Text(
            'Interpreter Signature *',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          SignaturePad(
            height: 150,
            points: _interpreterSignaturePoints,
            onSignatureChanged: (hasSignature) {
              setState(() {
                _interpreterSignatureCaptured = hasSignature;
                if (hasSignature) {
                  _interpreterDate ??= DateTime.now();
                }
              });
            },
          ),
          if (_interpreterSignatureCaptured)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Interpreter signature captured',
                    style: TextStyle(color: Colors.green[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          
          // Interpreter Date
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (date != null) {
                setState(() => _interpreterDate = date);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Text(
                    _interpreterDate != null
                        ? '${_interpreterDate!.month.toString().padLeft(2, '0')} / ${_interpreterDate!.day.toString().padLeft(2, '0')} / ${_interpreterDate!.year}'
                        : 'Interpreter Date *',
                    style: TextStyle(
                      fontSize: 16,
                      color: _interpreterDate != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 32),
        
        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _canSubmitPatientRights && !_isSubmitting ? _submitPatientRightsForm : null,
            icon: _isSubmitting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle, size: 24),
            label: Text(
              _isSubmitting ? 'Submitting...' : 'Submit Patient Rights Form',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Debug button to show payload
        Center(
          child: OutlinedButton.icon(
            onPressed: () async {
              final signatureBase64 = await _signatureToBase64(_guardianSignaturePoints);
              final payload = {
                'clientId': widget.client.id,
                'consent_for_data_collection': _consentForDataCollection ? 1 : 0,
                'release_of_Information': _releaseOfInformation ? 1 : 0,
                'telehealth_consent': _telehealthConsent ? 1 : 0,
                'financialResponsibility': _financialResponsibility ? 1 : 0,
                'client_rights_responsibilites': _clientRightsResponsibilities ? 1 : 0,
                'benefits_of_treatment': _benefitsOfTreatment ? 1 : 0,
                'guardian_name': _selectedCaregiver?['name'] ?? '',
                'guardian_date': _guardianDate != null 
                    ? '${_guardianDate!.month.toString().padLeft(2, '0')}/${_guardianDate!.day.toString().padLeft(2, '0')}/${_guardianDate!.year}'
                    : '',
                'guardian_signature': '${_selectedCaregiver?['name'] ?? ''}<br>$signatureBase64',
              };
              
              // Convert to formatted JSON
              const encoder = JsonEncoder.withIndent('  ');
              final jsonString = encoder.convert(payload);
              
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Debug Payload (JSON)'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: SingleChildScrollView(
                        child: SelectableText(
                          jsonString,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                        ),
                      ),
                    ),
                    actions: [
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: jsonString));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied to clipboard!'), duration: Duration(seconds: 2)),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              }
            },
            icon: const Icon(Icons.bug_report, size: 20),
            label: const Text('Debug: Show Payload'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildConsentCheckbox({
    required String title,
    String description = '',
    required bool value,
    required ValueChanged<bool?> onChanged,
    String fieldName = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: value ? Colors.green : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: value ? Colors.green[50] : Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.green[700],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: value ? Colors.green[800] : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (value)
            Icon(Icons.check_circle, color: Colors.green[600], size: 20),
        ],
      ),
    );
  }

  /// Convert signature points to base64 PNG image
  Future<String> _signatureToBase64(List<Offset?> points, {double width = 400, double height = 150}) async {
    if (points.isEmpty) return '';
    
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
    
    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );
    
    // Draw signature
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) return '';
    
    final Uint8List pngBytes = byteData.buffer.asUint8List();
    return base64Encode(pngBytes);
  }

  Future<void> _submitPatientRightsForm() async {
    if (!_canSubmitPatientRights) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      // Convert signatures to base64
      final guardianSignatureBase64 = await _signatureToBase64(_guardianSignaturePoints);
      final interpreterSignatureBase64 = _interpreterSignatureCaptured 
          ? await _signatureToBase64(_interpreterSignaturePoints) 
          : '';
      final qspSignatureBase64 = _qspSignatureCaptured 
          ? await _signatureToBase64(_qspSignaturePoints) 
          : '';
      
      // Format dates
      String formatDate(DateTime? date) {
        if (date == null) return '';
        return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
      }
      
      final payload = <String, dynamic>{
        'clientId': widget.client.id,
        
        // Section 1: ABA Treatment Informed Consent (Laravel snake_case)
        'benefits_of_treatment': _benefitsOfTreatment ? 1 : 0,
        'treatment_administration': _treatmentAdministration ? 1 : 0,
        'risks_side_effects': _risksSideEffects ? 1 : 0,
        'alternative_treatments': _alternativeTreatments ? 1 : 0,
        'consequences_non_treatment': _consequencesNonTreatment ? 1 : 0,
        
        // Section 2: Data & Privacy
        'consent_data_collection': _consentForDataCollection ? 1 : 0,
        'release_of_information': _releaseOfInformation ? 1 : 0,
        'telehealth_consent': _telehealthConsent ? 1 : 0,
        
        // Section 3: Financial & Administrative
        'financial_responsibility': _financialResponsibility ? 1 : 0,
        'client_rights_responsibilities': _clientRightsResponsibilities ? 1 : 0,
        
        // Guardian Signature
        'guardian_signature': '${_selectedCaregiver?['name'] ?? ''}<br>$guardianSignatureBase64',
        'guardian_name': _selectedCaregiver?['name'] ?? '',
        'guardian_date': formatDate(_guardianDate),
        
        // QSP Signature (required by API)
        'qsp_name': _qspNameController.text.isNotEmpty ? _qspNameController.text : 'Staff',
        'qsp_date': formatDate(_qspDate ?? DateTime.now()),
      };
      
      // Use direct FileMaker for now (MCP API has field mismatch)
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      
      // FileMaker payload with all working fields
      final fileMakerPayload = <String, dynamic>{
        'telehealth_consent': _telehealthConsent ? 1 : 0,
        'release_of_Information': _releaseOfInformation ? 1 : 0,
        'client_rights_responsibilites': _clientRightsResponsibilities ? 1 : 0,
        'financialResponsibility': _financialResponsibility ? 1 : 0,
        'benefits_of_treatment': _benefitsOfTreatment ? 1 : 0,
        'guardian_name': _selectedCaregiver?['name'] ?? '',
        'guardian_date': formatDate(_guardianDate),
        'guardian_signature': '${_selectedCaregiver?['name'] ?? ''}<br>$guardianSignatureBase64',
        'treatment_administration': _treatmentAdministration ? 1 : 0,
        'guardian_relationship': _guardianRelationship,
        'alternative_treatments': _alternativeTreatments ? 1 : 0,
        'consent_data_collection': _consentForDataCollection ? 1 : 0,
        'risks_side_effects': _risksSideEffects ? 1 : 0,
        'consequences_non_treatment': _consequencesNonTreatment ? 1 : 0,
        // Interpreter fields (if used)
        'interpreter_used': _interpreterUsed ? 1 : 0,
        if (_interpreterUsed && _selectedInterpreter != null) ...{
          'interpreter_name': _selectedInterpreter!['name'] ?? '',
          'interpreter_date': formatDate(_interpreterDate),
          'interpreter_signature': '${_selectedInterpreter!['name'] ?? ''}<br>$interpreterSignatureBase64',
        },
      };
      
      await fileMakerService.createPatientRightsRecord(
        clientId: widget.client.id,
        formData: fileMakerPayload,
      );
      
      if (mounted) {
        widget.onSubmit();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ==========================================
  // Generic Consent Form (for other form types)
  // ==========================================
  Widget _buildGenericConsentForm() {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // Guardian Info Section
        _buildSectionTitle('Guardian Information'),
        const SizedBox(height: 12),
        
        // Guardian Dropdown
        _isLoadingCaregivers
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Loading guardians...'),
                          ],
                        ),
                      )
                    : _caregivers.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              border: Border.all(color: Colors.orange[200]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.orange[700]),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'No guardians found for this patient. Please add a guardian in FileMaker first.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<Map<String, dynamic>>(
                                value: _selectedCaregiver,
                                decoration: InputDecoration(
                                  labelText: 'Select Guardian *',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.person),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                items: _caregivers.map((caregiver) {
                                  final name = caregiver['name'] ?? '';
                                  final relationship = caregiver['relationship'] ?? '';
                                  final isPrimary = caregiver['isPrimary'] == true;
                                  
                                  // Build display text: "Name (relationship)"
                                  String displayText = name.isNotEmpty ? name : 'Guardian';
                                  if (relationship.isNotEmpty) {
                                    displayText += ' ($relationship)';
                                  }
                                  if (isPrimary) {
                                    displayText += ' ✓';
                                  }
                                  
                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: caregiver,
                                    child: Text(
                                      displayText,
                                      style: const TextStyle(fontSize: 15),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedCaregiver = value);
                                },
                                validator: (value) => value == null ? 'Please select a guardian' : null,
                                isExpanded: true,
                              ),
                              
                              // Display selected guardian details
                              if (_selectedCaregiver != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Guardian Details',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue[800],
                                            ),
                                          ),
                                          const Spacer(),
                                          if (_selectedCaregiver!['isLegalGuardian'] == true)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green[100],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.verified, size: 14, color: Colors.green[700]),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Legal Guardian',
                                                    style: TextStyle(fontSize: 11, color: Colors.green[700], fontWeight: FontWeight.w500),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _buildDetailRow('Name', _selectedCaregiver!['name'] ?? ''),
                                      if (_selectedCaregiver!['relationship']?.toString().isNotEmpty ?? false)
                                        _buildDetailRow('Relationship', _selectedCaregiver!['relationship']),
                                      if (_selectedCaregiver!['custodyStatus']?.toString().isNotEmpty ?? false)
                                        _buildDetailRow('Custody', _selectedCaregiver!['custodyStatus']),
                                      if (_selectedCaregiver!['cellPhone']?.toString().isNotEmpty ?? false)
                                        _buildDetailRow('Cell Phone', _selectedCaregiver!['cellPhone']),
                                      if (_selectedCaregiver!['homePhone']?.toString().isNotEmpty ?? false)
                                        _buildDetailRow('Home Phone', _selectedCaregiver!['homePhone']),
                                      if (_selectedCaregiver!['email']?.toString().isNotEmpty ?? false)
                                        _buildDetailRow('Email', _selectedCaregiver!['email']),
                                      if (_selectedCaregiver!['address']?.toString().isNotEmpty ?? false)
                                        _buildDetailRow('Address', _selectedCaregiver!['address']),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                const SizedBox(height: 24),
                
                // Section 3: Consent for Evaluation & Data Collection
                _buildConsentSection(
                  sectionNumber: '3',
                  title: 'Consent for Evaluation & Data Collection',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I authorize LifeLink to conduct assessments necessary to determine treatment needs. These may include:',
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 12),
                      _buildBulletPoint('Behavioral assessments'),
                      _buildBulletPoint('Functional behavior assessments (FBA)'),
                      _buildBulletPoint('Observations, interviews, or standardized tools'),
                      _buildBulletPoint('Review of educational and medical records'),
                      const SizedBox(height: 12),
                      Text(
                        'Collected data will be used to plan, monitor, and adjust treatment.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                    ],
                  ),
                  initialed: _initialsEvaluation,
                  onInitialed: (v) => setState(() => _initialsEvaluation = v ?? false),
                ),
                
                // Section 4: Release of Information & Coordination of Care
                _buildConsentSection(
                  sectionNumber: '4',
                  title: 'Release of Information & Coordination of Care',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I authorize LifeLink to share relevant information with the following entities for treatment, payment, and operations:',
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 12),
                      _buildBulletPoint('Medical providers'),
                      _buildBulletPoint('Schools and educational teams'),
                      _buildBulletPoint('County programs (CLTS, CCS, CCOP)'),
                      _buildBulletPoint('Insurance companies or Medicaid (ForwardHealth)'),
                      _buildBulletPoint('Other agencies involved in care'),
                      const SizedBox(height: 12),
                      Text(
                        'Information will be shared only as necessary and in accordance with HIPAA and Wisconsin confidentiality laws (DHS 92, 51.30).',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700], fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  initialed: _initialsReleaseInfo,
                  onInitialed: (v) => setState(() => _initialsReleaseInfo = v ?? false),
                ),
                
                // Section 5: Telehealth Consent
                _buildConsentSection(
                  sectionNumber: '5',
                  title: 'Telehealth Consent',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I understand that telehealth may be used when appropriate and that:',
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 12),
                      _buildBulletPoint('Telehealth sessions will follow HIPAA standards.'),
                      _buildBulletPoint('I may refuse telehealth at any time without affecting access to in-person care.'),
                    ],
                  ),
                  initialed: _initialsTelehealth,
                  onInitialed: (v) => setState(() => _initialsTelehealth = v ?? false),
                ),
                
                // Section 6: Financial Responsibility & Billing Authorization
                _buildConsentSection(
                  sectionNumber: '6',
                  title: 'Financial Responsibility & Billing Authorization',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I understand that:',
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 12),
                      _buildBulletPoint('LifeLink will bill ForwardHealth, CLTS, CCS, CCOP, or commercial insurance when applicable.'),
                      _buildBulletPoint('I am responsible for providing accurate insurance information.'),
                      _buildBulletPoint('I may be responsible for charges not covered by funding sources (unless prohibited by program rules).'),
                    ],
                  ),
                  initialed: _initialsFinancial,
                  onInitialed: (v) => setState(() => _initialsFinancial = v ?? false),
                ),
                
                // Section 7: Client Rights & Responsibilities
                _buildConsentSection(
                  sectionNumber: '7',
                  title: 'Client Rights & Responsibilities',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I acknowledge receipt of LifeLink\'s Client Rights Statement, which includes:',
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 12),
                      _buildBulletPoint('The right to respectful, non-discriminatory services'),
                      _buildBulletPoint('The right to confidentiality'),
                      _buildBulletPoint('The right to file grievances or appeals'),
                      _buildBulletPoint('The right to participate in treatment planning'),
                    ],
                  ),
                  initialed: _initialsClientRights,
                  onInitialed: (v) => setState(() => _initialsClientRights = v ?? false),
                ),
                
                // Section 8: Risks & Benefits of Treatment
                _buildConsentSection(
                  sectionNumber: '8',
                  title: 'Risks & Benefits of Treatment',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I have been informed that services may include benefits such as improved skills and functioning, as well as risks such as temporary increases in behavior or discomfort during learning.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'I have had the opportunity to ask questions about the treatment process.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                    ],
                  ),
                  initialed: _initialsRisksBenefits,
                  onInitialed: (v) => setState(() => _initialsRisksBenefits = v ?? false),
                ),
                
                const SizedBox(height: 32),
                
                // Section 9: Consent for Services (Final Signature)
                _buildFinalConsentSection(),
                
                const SizedBox(height: 24),
                
                // Section 10: Provider Verification
                _buildProviderVerificationSection(),
                
                const SizedBox(height: 32),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _canSubmit ? _submit : null,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Submit Consent', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Debug button to show payload
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final clientSignatureBase64 = await _signatureToBase64(_clientSignaturePoints);
                      final providerSignatureBase64 = await _signatureToBase64(_providerSignaturePoints);
                      final payload = {
                        'formType': widget.formTypeId,
                        'clientId': widget.client.id,
                        'clientName': widget.client.name,
                        'guardian_name': _selectedCaregiver?['name'] ?? '',
                        'initialsEvaluation': _initialsEvaluation ? 1 : 0,
                        'initialsReleaseInfo': _initialsReleaseInfo ? 1 : 0,
                        'initialsTelehealth': _initialsTelehealth ? 1 : 0,
                        'initialsFinancial': _initialsFinancial ? 1 : 0,
                        'initialsClientRights': _initialsClientRights ? 1 : 0,
                        'initialsRisksBenefits': _initialsRisksBenefits ? 1 : 0,
                        'consentForServices': _consentForServices ? 1 : 0,
                        'client_printed_name': _clientPrintedNameController.text,
                        'client_signature_date': _clientSignatureDate?.toString() ?? '',
                        'client_signature': '${_clientPrintedNameController.text}<br>$clientSignatureBase64',
                        'provider_printed_name': _providerNameController.text,
                        'provider_signature_date': _providerSignatureDate?.toString() ?? '',
                        'provider_signature': '${_providerNameController.text}<br>$providerSignatureBase64',
                      };
                      
                      const encoder = JsonEncoder.withIndent('  ');
                      final jsonString = encoder.convert(payload);
                      
                      if (mounted) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Debug Payload (JSON)'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  jsonString,
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                                ),
                              ),
                            ),
                            actions: [
                              TextButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: jsonString));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Copied to clipboard!'), duration: Duration(seconds: 2)),
                                  );
                                },
                                icon: const Icon(Icons.copy, size: 18),
                                label: const Text('Copy'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.bug_report, size: 20),
                    label: const Text('Debug: Show Payload'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
  }

  bool get _canSubmit => 
    _selectedCaregiver != null &&
    _initialsEvaluation &&
    _initialsReleaseInfo &&
    _initialsTelehealth &&
    _initialsFinancial &&
    _initialsClientRights &&
    _initialsRisksBenefits &&
    _consentForServices &&
    _clientPrintedNameController.text.isNotEmpty &&
    _clientSignatureDate != null &&
    _clientSignatureCaptured &&
    _providerVerification &&
    _providerNameController.text.isNotEmpty &&
    _providerSignatureDate != null &&
    _providerSignatureCaptured;

  Widget _buildConsentSection({
    required String sectionNumber,
    required String title,
    required Widget content,
    required bool initialed,
    required Function(bool?) onInitialed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(color: initialed ? Colors.green[300]! : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: initialed ? Colors.green[50] : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: initialed ? Colors.green[100] : Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: initialed ? Colors.green : Colors.blue[700],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      sectionNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                if (initialed)
                  Icon(Icons.check_circle, color: Colors.green[700], size: 24),
              ],
            ),
          ),
          // Section Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
          // Initials Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: initialed,
                    onChanged: onInitialed,
                    activeColor: Colors.green[700],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Initials',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: initialed ? Colors.green[700] : Colors.grey[700],
                  ),
                ),
                if (initialed) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '✓ Initialed',
                      style: TextStyle(fontSize: 12, color: Colors.green[800]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalConsentSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _consentForServices ? Colors.green[400]! : Colors.blue[300]!, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: _consentForServices ? Colors.green[50] : Colors.blue[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _consentForServices ? Colors.green[100] : Colors.blue[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _consentForServices ? Colors.green : Colors.blue[700],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      '9',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Consent for Services',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'I understand the above information and voluntarily consent for services from LifeLink Behavioral Health, Inc.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
                const SizedBox(height: 20),
                
                // Printed Name
                TextFormField(
                  controller: _clientPrintedNameController,
                  decoration: const InputDecoration(
                    labelText: 'Printed Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                
                // Signature Pad
                Text(
                  'Client (18+) / Parent / Guardian Signature *',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _clientSignatureCaptured ? Colors.green : Colors.grey[400]!,
                      width: _clientSignatureCaptured ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onPanStart: (details) {
                          setState(() {
                            _clientSignaturePoints.add(details.localPosition);
                            _clientSignatureCaptured = true;
                            _consentForServices = true;
                            _clientSignatureDate ??= DateTime.now();
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            _clientSignaturePoints.add(details.localPosition);
                          });
                        },
                        onPanEnd: (details) {
                          setState(() {
                            _clientSignaturePoints.add(null); // Break the line
                          });
                        },
                        child: CustomPaint(
                          painter: SignaturePainter(_clientSignaturePoints),
                          size: Size.infinite,
                        ),
                      ),
                      if (!_clientSignatureCaptured)
                        Center(
                          child: Text(
                            'Sign here',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            setState(() {
                              _clientSignaturePoints.clear();
                              _clientSignatureCaptured = false;
                            });
                          },
                          tooltip: 'Clear signature',
                        ),
                      ),
                    ],
                  ),
                ),
                if (_clientSignatureCaptured)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Signature captured',
                          style: TextStyle(color: Colors.green[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Date
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (date != null) {
                      setState(() => _clientSignatureDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Text(
                          _clientSignatureDate != null
                              ? '${_clientSignatureDate!.month.toString().padLeft(2, '0')} / ${_clientSignatureDate!.day.toString().padLeft(2, '0')} / ${_clientSignatureDate!.year}'
                              : 'Date *',
                          style: TextStyle(
                            fontSize: 16,
                            color: _clientSignatureDate != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderVerificationSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _providerVerification ? Colors.green[400]! : Colors.purple[300]!, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: _providerVerification ? Colors.green[50] : Colors.purple[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _providerVerification ? Colors.green[100] : Colors.purple[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _providerVerification ? Colors.green : Colors.purple[700],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      '10',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Provider Verification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'I have explained the information in this document and answered all client questions.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
                const SizedBox(height: 20),
                
                // Printed Name & Title
                TextFormField(
                  controller: _providerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Printed Name & Title *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                
                // Provider Signature Pad
                Text(
                  'Provider Signature *',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _providerSignatureCaptured ? Colors.green : Colors.grey[400]!,
                      width: _providerSignatureCaptured ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onPanStart: (details) {
                          setState(() {
                            _providerSignaturePoints.add(details.localPosition);
                            _providerSignatureCaptured = true;
                            _providerVerification = true;
                            _providerSignatureDate ??= DateTime.now();
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            _providerSignaturePoints.add(details.localPosition);
                          });
                        },
                        onPanEnd: (details) {
                          setState(() {
                            _providerSignaturePoints.add(null); // Break the line
                          });
                        },
                        child: CustomPaint(
                          painter: SignaturePainter(_providerSignaturePoints),
                          size: Size.infinite,
                        ),
                      ),
                      if (!_providerSignatureCaptured)
                        Center(
                          child: Text(
                            'Sign here',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            setState(() {
                              _providerSignaturePoints.clear();
                              _providerSignatureCaptured = false;
                            });
                          },
                          tooltip: 'Clear signature',
                        ),
                      ),
                    ],
                  ),
                ),
                if (_providerSignatureCaptured)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Signature captured',
                          style: TextStyle(color: Colors.green[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Date
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (date != null) {
                      setState(() => _providerSignatureDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Text(
                          _providerSignatureDate != null
                              ? '${_providerSignatureDate!.month.toString().padLeft(2, '0')} / ${_providerSignatureDate!.day.toString().padLeft(2, '0')} / ${_providerSignatureDate!.year}'
                              : 'Date *',
                          style: TextStyle(
                            fontSize: 16,
                            color: _providerSignatureDate != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Footer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.red[400], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'LifeLink Behavioral Health, Inc. Thank you for partnering with us in care.',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit();
    }
  }

  // ==========================================
  // Consent for Behavioral Health & ABA Form
  // ==========================================
  Widget _buildConsentBehavioralHealthForm() {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // Form Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.health_and_safety, color: Colors.teal[700], size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Consent for Behavioral Health & ABA',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Client: ${widget.client.name}',
                style: TextStyle(fontSize: 14, color: Colors.teal[700]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Guardian Selection
        const Text('Guardian/Responsible Party *', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _isLoadingCaregivers
            ? const Center(child: CircularProgressIndicator())
            : _caregivers.isEmpty
                ? const Text('No guardians found for this client', style: TextStyle(color: Colors.red))
                : DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedCaregiver,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: const Text('Select Guardian'),
                    onChanged: (value) => setState(() => _selectedCaregiver = value),
                    items: _caregivers.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c['name'] ?? 'Unknown'),
                    )).toList(),
                  ),
        const SizedBox(height: 24),

        // Consent Checkboxes
        _buildConsentCheckbox(
          title: 'I consent to Applied Behavior Analysis (ABA) therapy services',
          value: _initialsEvaluation,
          onChanged: (v) => setState(() => _initialsEvaluation = v ?? false),
        ),
        _buildConsentCheckbox(
          title: 'I consent to behavioral health assessment and treatment',
          value: _initialsReleaseInfo,
          onChanged: (v) => setState(() => _initialsReleaseInfo = v ?? false),
        ),
        _buildConsentCheckbox(
          title: 'I understand the goals and methods of ABA therapy',
          value: _initialsTelehealth,
          onChanged: (v) => setState(() => _initialsTelehealth = v ?? false),
        ),
        _buildConsentCheckbox(
          title: 'I consent to data collection for treatment purposes',
          value: _initialsFinancial,
          onChanged: (v) => setState(() => _initialsFinancial = v ?? false),
        ),
        _buildConsentCheckbox(
          title: 'I understand my right to withdraw consent at any time',
          value: _initialsClientRights,
          onChanged: (v) => setState(() => _initialsClientRights = v ?? false),
        ),
        const SizedBox(height: 24),

        // Guardian Signature
        const Text('Guardian Signature *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        SignaturePad(
          height: 150,
          points: _guardianSignaturePoints,
          onSignatureChanged: (hasSignature) {
            setState(() {
              _guardianSignatureCaptured = hasSignature;
              if (hasSignature) _guardianDate ??= DateTime.now();
            });
          },
        ),
        if (_guardianDate != null)
          Text('Date: ${_guardianDate!.month}/${_guardianDate!.day}/${_guardianDate!.year}',
              style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 24),

        // Debug Button
        _buildDebugButton({
          'formType': 'consent_behavioral_health_aba',
          'clientId': widget.client.id,
          'clientName': widget.client.name,
          'guardian_name': _selectedCaregiver?['name'] ?? '',
          'aba_consent': _initialsEvaluation ? 1 : 0,
          'behavioral_health_consent': _initialsReleaseInfo ? 1 : 0,
          'aba_goals_understood': _initialsTelehealth ? 1 : 0,
          'data_collection_consent': _initialsFinancial ? 1 : 0,
          'withdrawal_rights_understood': _initialsClientRights ? 1 : 0,
          'guardian_signature': _guardianSignatureCaptured ? 'captured' : 'not_captured',
          'guardian_date': _guardianDate?.toString() ?? '',
        }),
      ],
    );
  }

  // ==========================================
  // Consent for Evaluation Form
  // ==========================================
  Widget _buildConsentEvaluationForm() {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // Form Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.assignment, color: Colors.purple[700], size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Consent for Evaluation',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Client: ${widget.client.name}',
                style: TextStyle(fontSize: 14, color: Colors.purple[700]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Guardian Selection
        const Text('Guardian/Responsible Party *', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _isLoadingCaregivers
            ? const Center(child: CircularProgressIndicator())
            : _caregivers.isEmpty
                ? const Text('No guardians found for this client', style: TextStyle(color: Colors.red))
                : DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedCaregiver,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: const Text('Select Guardian'),
                    onChanged: (value) => setState(() => _selectedCaregiver = value),
                    items: _caregivers.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c['name'] ?? 'Unknown'),
                    )).toList(),
                  ),
        const SizedBox(height: 24),

        // Evaluation Type Selection
        const Text('Evaluation Type *', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: const Text('Select Evaluation Type'),
          items: const [
            DropdownMenuItem(value: 'diagnostic', child: Text('Diagnostic Evaluation')),
            DropdownMenuItem(value: 'functional', child: Text('Functional Behavior Assessment')),
            DropdownMenuItem(value: 'developmental', child: Text('Developmental Assessment')),
            DropdownMenuItem(value: 'psychological', child: Text('Psychological Evaluation')),
          ],
          onChanged: (value) {},
        ),
        const SizedBox(height: 24),

        // Consent Checkboxes
        _buildConsentCheckbox(
          title: 'I consent to diagnostic evaluation of my child',
          value: _initialsEvaluation,
          onChanged: (v) => setState(() => _initialsEvaluation = v ?? false),
        ),
        _buildConsentCheckbox(
          title: 'I consent to psychological/developmental testing',
          value: _initialsReleaseInfo,
          onChanged: (v) => setState(() => _initialsReleaseInfo = v ?? false),
        ),
        _buildConsentCheckbox(
          title: 'I consent to interview and observation as part of evaluation',
          value: _initialsTelehealth,
          onChanged: (v) => setState(() => _initialsTelehealth = v ?? false),
        ),
        _buildConsentCheckbox(
          title: 'I understand the evaluation results will be shared with me',
          value: _initialsFinancial,
          onChanged: (v) => setState(() => _initialsFinancial = v ?? false),
        ),
        const SizedBox(height: 24),

        // Guardian Signature
        const Text('Guardian Signature *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        SignaturePad(
          height: 150,
          points: _guardianSignaturePoints,
          onSignatureChanged: (hasSignature) {
            setState(() {
              _guardianSignatureCaptured = hasSignature;
              if (hasSignature) _guardianDate ??= DateTime.now();
            });
          },
        ),
        if (_guardianDate != null)
          Text('Date: ${_guardianDate!.month}/${_guardianDate!.day}/${_guardianDate!.year}',
              style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 24),

        // Debug Button
        _buildDebugButton({
          'formType': 'consent_evaluation',
          'clientId': widget.client.id,
          'clientName': widget.client.name,
          'guardian_name': _selectedCaregiver?['name'] ?? '',
          'diagnostic_consent': _initialsEvaluation ? 1 : 0,
          'testing_consent': _initialsReleaseInfo ? 1 : 0,
          'interview_consent': _initialsTelehealth ? 1 : 0,
          'results_sharing_consent': _initialsFinancial ? 1 : 0,
          'guardian_signature': _guardianSignatureCaptured ? 'captured' : 'not_captured',
          'guardian_date': _guardianDate?.toString() ?? '',
        }),
      ],
    );
  }

  // ==========================================
  // HIPAA Authorization Form
  // ==========================================
  Widget _buildHipaaAuthorizationForm() {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // Form Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security, color: Colors.blue[700], size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'HIPAA Authorization',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Client: ${widget.client.name}',
                style: TextStyle(fontSize: 14, color: Colors.blue[700]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Guardian Selection
        const Text('Guardian/Responsible Party *', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _isLoadingCaregivers
            ? const Center(child: CircularProgressIndicator())
            : _caregivers.isEmpty
                ? const Text('No guardians found for this client', style: TextStyle(color: Colors.red))
                : DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedCaregiver,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: const Text('Select Guardian'),
                    onChanged: (value) => setState(() => _selectedCaregiver = value),
                    items: _caregivers.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c['name'] ?? 'Unknown'),
                    )).toList(),
                  ),
        const SizedBox(height: 24),

        // Release To/From
        const Text('Authorize Release To:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: 'Name of person/organization to receive information',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Purpose of Release:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: const Text('Select Purpose'),
          items: const [
            DropdownMenuItem(value: 'treatment', child: Text('Continuity of Care/Treatment')),
            DropdownMenuItem(value: 'insurance', child: Text('Insurance/Billing')),
            DropdownMenuItem(value: 'legal', child: Text('Legal Purposes')),
            DropdownMenuItem(value: 'school', child: Text('School Records')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (value) {},
        ),
        const SizedBox(height: 24),

        // Information Types
        const Text('Information to be Released:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _buildConsentCheckbox(
          title: 'Medical/Treatment Records',
          value: _initialsEvaluation,
          onChanged: (v) => setState(() => _initialsEvaluation = v ?? false),
        ),
        _buildConsentCheckbox(
          title: 'Psychological/Behavioral Assessments',
          value: _initialsReleaseInfo,
          onChanged: (v) => setState(() => _initialsReleaseInfo = v ?? false),
        ),
        _buildConsentCheckbox(
          title: 'Treatment Plans and Progress Notes',
          value: _initialsTelehealth,
          onChanged: (v) => setState(() => _initialsTelehealth = v ?? false),
        ),
        _buildConsentCheckbox(
          title: 'Billing/Financial Information',
          value: _initialsFinancial,
          onChanged: (v) => setState(() => _initialsFinancial = v ?? false),
        ),
        _buildConsentCheckbox(
          title: 'Educational/School Records',
          value: _initialsClientRights,
          onChanged: (v) => setState(() => _initialsClientRights = v ?? false),
        ),
        const SizedBox(height: 16),

        // Expiration
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700]),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'This authorization expires 1 year from the date of signature unless otherwise specified.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Guardian Signature
        const Text('Guardian Signature *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        SignaturePad(
          height: 150,
          points: _guardianSignaturePoints,
          onSignatureChanged: (hasSignature) {
            setState(() {
              _guardianSignatureCaptured = hasSignature;
              if (hasSignature) _guardianDate ??= DateTime.now();
            });
          },
        ),
        if (_guardianDate != null)
          Text('Date: ${_guardianDate!.month}/${_guardianDate!.day}/${_guardianDate!.year}',
              style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 24),

        // Debug Button
        _buildDebugButton({
          'formType': 'hipaa_authorization',
          'clientId': widget.client.id,
          'clientName': widget.client.name,
          'guardian_name': _selectedCaregiver?['name'] ?? '',
          'medical_records': _initialsEvaluation ? 1 : 0,
          'psychological_assessments': _initialsReleaseInfo ? 1 : 0,
          'treatment_plans': _initialsTelehealth ? 1 : 0,
          'billing_info': _initialsFinancial ? 1 : 0,
          'educational_records': _initialsClientRights ? 1 : 0,
          'guardian_signature': _guardianSignatureCaptured ? 'captured' : 'not_captured',
          'guardian_date': _guardianDate?.toString() ?? '',
        }),
      ],
    );
  }

  // ==========================================
  // Telehealth Consent Form
  // ==========================================
  Widget _buildTelehealthConsentForm() {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // Form Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.videocam, color: Colors.green[700], size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Telehealth Consent',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Client: ${widget.client.name}',
                style: TextStyle(fontSize: 14, color: Colors.green[700]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Guardian Selection
        const Text('Guardian/Responsible Party *', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _isLoadingCaregivers
            ? const Center(child: CircularProgressIndicator())
            : _caregivers.isEmpty
                ? const Text('No guardians found for this client', style: TextStyle(color: Colors.red))
                : DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedCaregiver,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: const Text('Select Guardian'),
                    onChanged: (value) => setState(() => _selectedCaregiver = value),
                    items: _caregivers.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c['name'] ?? 'Unknown'),
                    )).toList(),
                  ),
        const SizedBox(height: 24),

        // Telehealth Info Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text('About Telehealth Services', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Telehealth involves the use of electronic communications to provide healthcare services remotely. '
                'This includes video conferencing, phone calls, and secure messaging.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Consent Checkboxes
        _buildConsentCheckbox(
          title: 'I consent to receive healthcare services via telehealth',
          value: _initialsEvaluation,
          onChanged: (v) => setState(() => _initialsEvaluation = v ?? false),
        ),
        _buildConsentCheckbox(
          title: 'I understand the potential risks and benefits of telehealth',
          value: _initialsReleaseInfo,
          onChanged: (v) => setState(() => _initialsReleaseInfo = v ?? false),
        ),
        _buildConsentCheckbox(
          title: 'I understand telehealth may not be appropriate for all conditions',
          value: _initialsTelehealth,
          onChanged: (v) => setState(() => _initialsTelehealth = v ?? false),
        ),
        _buildConsentCheckbox(
          title: 'I have adequate technology and private space for telehealth sessions',
          value: _initialsFinancial,
          onChanged: (v) => setState(() => _initialsFinancial = v ?? false),
        ),
        _buildConsentCheckbox(
          title: 'I consent to recording of sessions if clinically necessary',
          value: _initialsClientRights,
          onChanged: (v) => setState(() => _initialsClientRights = v ?? false),
        ),
        _buildConsentCheckbox(
          title: 'I understand I can withdraw consent for telehealth at any time',
          value: _initialsRisksBenefits,
          onChanged: (v) => setState(() => _initialsRisksBenefits = v ?? false),
        ),
        const SizedBox(height: 24),

        // Emergency Contact
        const Text('Emergency Contact Information:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: 'Local emergency contact phone number',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: 'Physical address for emergency services',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.location_on),
          ),
        ),
        const SizedBox(height: 24),

        // Guardian Signature
        const Text('Guardian Signature *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        SignaturePad(
          height: 150,
          points: _guardianSignaturePoints,
          onSignatureChanged: (hasSignature) {
            setState(() {
              _guardianSignatureCaptured = hasSignature;
              if (hasSignature) _guardianDate ??= DateTime.now();
            });
          },
        ),
        if (_guardianDate != null)
          Text('Date: ${_guardianDate!.month}/${_guardianDate!.day}/${_guardianDate!.year}',
              style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 24),

        // Debug Button
        _buildDebugButton({
          'formType': 'telehealth_consent',
          'clientId': widget.client.id,
          'clientName': widget.client.name,
          'guardian_name': _selectedCaregiver?['name'] ?? '',
          'telehealth_consent': _initialsEvaluation ? 1 : 0,
          'risks_benefits_understood': _initialsReleaseInfo ? 1 : 0,
          'limitations_understood': _initialsTelehealth ? 1 : 0,
          'technology_confirmed': _initialsFinancial ? 1 : 0,
          'recording_consent': _initialsClientRights ? 1 : 0,
          'withdrawal_understood': _initialsRisksBenefits ? 1 : 0,
          'guardian_signature': _guardianSignatureCaptured ? 'captured' : 'not_captured',
          'guardian_date': _guardianDate?.toString() ?? '',
        }),
      ],
    );
  }

  // ==========================================
  // Debug Button Builder
  // ==========================================
  Widget _buildDebugButton(Map<String, dynamic> payload) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () {
          const encoder = JsonEncoder.withIndent('  ');
          final jsonString = encoder.convert(payload);
          
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Debug Payload (JSON)'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonString,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: jsonString));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard!'), duration: Duration(seconds: 2)),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.bug_report, size: 20),
        label: const Text('Debug: Show Payload'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey,
        ),
      ),
    );
  }
}

/// Consent for Evaluation Tab
class ConsentEvaluationTab extends StatelessWidget {
  const ConsentEvaluationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Header Card
          Card(
            color: Colors.purple[50],
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment, size: 32, color: Colors.purple[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Consent for Evaluation',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Manage consent forms for diagnostic evaluations and assessments.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.purple[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // New Evaluation Consent Button
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add_circle, color: Colors.green[700]),
              ),
              title: const Text('Create New Consent'),
              subtitle: const Text('Start a new evaluation consent form'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Evaluation consent form creation coming soon')),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          
          // View Pending Button
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.pending_actions, color: Colors.orange[700]),
              ),
              title: const Text('Pending Consents'),
              subtitle: const Text('View consents awaiting signature'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pending evaluation consents view coming soon')),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          
          // View Completed Button
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.check_circle, color: Colors.purple[700]),
              ),
              title: const Text('Completed Consents'),
              subtitle: const Text('View signed evaluation consents'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Completed evaluation consents view coming soon')),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // Evaluation Types Section
          const Text(
            'Evaluation Types',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildEvaluationTypeCard(
            'Diagnostic Evaluation',
            'Comprehensive assessment for initial diagnosis',
            Icons.medical_services,
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildEvaluationTypeCard(
            'Functional Behavior Assessment',
            'Identify function of challenging behaviors',
            Icons.psychology,
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildEvaluationTypeCard(
            'Skills Assessment',
            'Evaluate current skill levels and abilities',
            Icons.assessment,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildEvaluationTypeCard(
            'Progress Re-evaluation',
            'Periodic assessment of treatment progress',
            Icons.trending_up,
            Colors.purple,
          ),
        ],
      ),
    );
  }
  
  Widget _buildEvaluationTypeCard(String title, String description, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}

/// Optimized Signature Pad Widget
class SignaturePad extends StatefulWidget {
  final double height;
  final ValueChanged<bool> onSignatureChanged;
  final List<Offset?> points;
  
  const SignaturePad({
    super.key,
    this.height = 150,
    required this.onSignatureChanged,
    required this.points,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  bool _hasSignature = false;

  void _onPanStart(DragStartDetails details) {
    widget.points.add(details.localPosition);
    if (!_hasSignature) {
      _hasSignature = true;
      widget.onSignatureChanged(true);
    }
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    widget.points.add(details.localPosition);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    widget.points.add(null); // Break the line
    setState(() {});
  }

  void _clear() {
    widget.points.clear();
    _hasSignature = false;
    widget.onSignatureChanged(false);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(
          color: _hasSignature ? Colors.green : Colors.grey[400]!,
          width: _hasSignature ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          children: [
            // Signature drawing area
            Positioned.fill(
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                behavior: HitTestBehavior.opaque,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _SignaturePainterOptimized(widget.points),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            // Placeholder text
            if (!_hasSignature)
              Center(
                child: IgnorePointer(
                  child: Text(
                    'Sign here',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                ),
              ),
            // Clear button
            Positioned(
              right: 4,
              top: 4,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[500], size: 20),
                  onPressed: _clear,
                  tooltip: 'Clear signature',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Optimized painter for drawing signatures
class _SignaturePainterOptimized extends CustomPainter {
  final List<Offset?> points;
  
  _SignaturePainterOptimized(this.points);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5
      ..isAntiAlias = true;
    
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(_SignaturePainterOptimized oldDelegate) => true;
}

/// Legacy painter (for backwards compatibility)
class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  
  SignaturePainter(this.points);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;
    
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(SignaturePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.points.length != points.length;
  }
}
