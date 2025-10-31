import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../models/program_assignment.dart';
import '../services/filemaker_service.dart';

/// Dialog for generating trial data with client and program selection
class TrialDataGenerationDialog extends StatefulWidget {
  final Function({required String clientId, required List<String> programIds}) onGenerate;

  const TrialDataGenerationDialog({
    super.key,
    required this.onGenerate,
  });

  @override
  State<TrialDataGenerationDialog> createState() => _TrialDataGenerationDialogState();
}

class _TrialDataGenerationDialogState extends State<TrialDataGenerationDialog> {
  List<Client> _clients = [];
  List<ProgramAssignment> _programs = [];
  String? _selectedClientId;
  List<String> _selectedProgramIds = [];
  bool _isLoading = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      final clients = await fileMakerService.getClients();
      
      setState(() {
        _clients = clients;
        _isLoading = false;
      });
      
      print('📋 Loaded ${clients.length} existing clients');
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error loading clients: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading clients: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadPrograms(String clientId) async {
    setState(() => _isLoading = true);
    
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      final programs = await fileMakerService.getProgramAssignments(clientId);
      
      setState(() {
        _programs = programs;
        _selectedProgramIds = programs.map((p) => p.id ?? '').toList(); // Select all by default
        _isLoading = false;
      });
      
      print('📋 Loaded ${programs.length} programs for client: $clientId');
      if (programs.isNotEmpty) {
        print('🎯 First program: ${programs.first.displayName}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error loading programs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading programs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onClientChanged(String? clientId) {
    setState(() {
      _selectedClientId = clientId;
      _programs = [];
      _selectedProgramIds = [];
    });
    
    if (clientId != null) {
      _loadPrograms(clientId);
    }
  }

  void _onProgramToggled(String programId, bool selected) {
    setState(() {
      if (selected) {
        _selectedProgramIds.add(programId);
      } else {
        _selectedProgramIds.remove(programId);
      }
    });
  }

  void _onGenerate() {
    if (_selectedClientId == null || _selectedProgramIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a client and at least one program'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);
    
    widget.onGenerate(
      clientId: _selectedClientId!,
      programIds: _selectedProgramIds,
    );
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.analytics, color: Colors.blue),
          SizedBox(width: 8),
          Text('Generate Trial Data (Existing Clients)'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Selection
            const Text(
              'Select Existing Client:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose from ${_clients.length} existing clients',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedClientId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose a client...',
                prefixIcon: Icon(Icons.person),
              ),
              items: _clients.map((client) {
                return DropdownMenuItem<String>(
                  value: client.id,
                  child: Text(client.name),
                );
              }).toList(),
              onChanged: _isLoading ? null : _onClientChanged,
            ),
            
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            
            // Program Selection
            if (_programs.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Available Programs:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                '${_programs.length} programs found (First program will be used)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: _programs.length,
                  itemBuilder: (context, index) {
                    final program = _programs[index];
                    final isFirst = index == 0;
                    final isSelected = _selectedProgramIds.contains(program.id);
                    
                    return Container(
                      color: isFirst ? Colors.orange[50] : null,
                      child: CheckboxListTile(
                        title: Row(
                          children: [
                            Text(program.displayName),
                            if (isFirst) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange[600],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'FIRST',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text('Phase: ${program.phase ?? 'Unknown'}'),
                        value: isSelected,
                        onChanged: (selected) => _onProgramToggled(program.id ?? '', selected ?? false),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            // Phase Information
            if (_selectedClientId != null && _programs.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trial Data Generation Plan:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('👤 Client: ${_clients.firstWhere((c) => c.id == _selectedClientId).name}'),
                    Text('📋 Program: ${_programs.first.displayName}'),
                    const SizedBox(height: 8),
                    const Text('📊 Baseline: 3 sessions'),
                    const Text('🎯 Intervention: 5 sessions'),
                    const Text('✅ Maintenance: 4 sessions'),
                    const SizedBox(height: 4),
                    Text(
                      'Total: 12 sessions will be created',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isGenerating || _selectedClientId == null || _selectedProgramIds.isEmpty
              ? null
              : _onGenerate,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Generate Data'),
        ),
      ],
    );
  }
}
