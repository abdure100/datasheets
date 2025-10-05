import 'package:flutter/material.dart';

class ABCWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final Function(Map<String, dynamic>) onDataChanged;

  const ABCWidget({
    super.key,
    required this.config,
    required this.onDataChanged,
  });

  @override
  State<ABCWidget> createState() => _ABCWidgetState();
}

class _ABCWidgetState extends State<ABCWidget> {
  final _antecedentController = TextEditingController();
  final _behaviorController = TextEditingController();
  final _consequenceController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _antecedentController.text = widget.config['antecedent'] ?? '';
    _behaviorController.text = widget.config['behavior'] ?? '';
    _consequenceController.text = widget.config['consequence'] ?? '';
    _notesController.text = widget.config['notes'] ?? '';
  }

  @override
  void dispose() {
    _antecedentController.dispose();
    _behaviorController.dispose();
    _consequenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateData() {
    widget.onDataChanged({
      ...widget.config,
      'antecedent': _antecedentController.text,
      'behavior': _behaviorController.text,
      'consequence': _consequenceController.text,
      'notes': _notesController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ABC Data Collection',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Antecedent
        TextFormField(
          controller: _antecedentController,
          decoration: const InputDecoration(
            labelText: 'Antecedent (What happened before?)',
            hintText: 'Describe what was happening before the behavior',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.arrow_back, color: Colors.blue),
          ),
          maxLines: 2,
          onChanged: (_) => _updateData(),
        ),
        
        const SizedBox(height: 16),
        
        // Behavior
        TextFormField(
          controller: _behaviorController,
          decoration: const InputDecoration(
            labelText: 'Behavior (What did the client do?)',
            hintText: 'Describe the specific behavior observed',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.center_focus_strong, color: Colors.orange),
          ),
          maxLines: 2,
          onChanged: (_) => _updateData(),
        ),
        
        const SizedBox(height: 16),
        
        // Consequence
        TextFormField(
          controller: _consequenceController,
          decoration: const InputDecoration(
            labelText: 'Consequence (What happened after?)',
            hintText: 'Describe what happened immediately after the behavior',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.arrow_forward, color: Colors.green),
          ),
          maxLines: 2,
          onChanged: (_) => _updateData(),
        ),
        
        const SizedBox(height: 16),
        
        // Notes
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Additional Notes',
            hintText: 'Any additional observations or context',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note, color: Colors.grey),
          ),
          maxLines: 3,
          onChanged: (_) => _updateData(),
        ),
        
        const SizedBox(height: 16),
        
        // Quick Templates
        const Text(
          'Quick Templates:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildTemplateChip('Request denied', 'Tantrum', 'Attention given'),
            _buildTemplateChip('Transition time', 'Refusal', 'Task removed'),
            _buildTemplateChip('Difficult task', 'Escape behavior', 'Break given'),
            _buildTemplateChip('Peer interaction', 'Aggression', 'Removed from area'),
          ],
        ),
      ],
    );
  }

  Widget _buildTemplateChip(String antecedent, String behavior, String consequence) {
    return ActionChip(
      label: Text('$antecedent → $behavior → $consequence'),
      onPressed: () {
        setState(() {
          _antecedentController.text = antecedent;
          _behaviorController.text = behavior;
          _consequenceController.text = consequence;
        });
        _updateData();
      },
    );
  }
}
