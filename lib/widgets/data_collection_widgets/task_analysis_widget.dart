import 'package:flutter/material.dart';

class TaskAnalysisWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final Function(Map<String, dynamic>) onDataChanged;

  const TaskAnalysisWidget({
    super.key,
    required this.config,
    required this.onDataChanged,
  });

  @override
  State<TaskAnalysisWidget> createState() => _TaskAnalysisWidgetState();
}

class _TaskAnalysisWidgetState extends State<TaskAnalysisWidget> {
  List<bool> _steps = [];

  @override
  void initState() {
    super.initState();
    _steps = List<bool>.from(widget.config['steps'] ?? []);
    if (_steps.isEmpty) {
      _steps = List.filled(5, false); // Default to 5 steps
    }
  }

  void _updateData() {
    widget.onDataChanged({
      ...widget.config,
      'steps': _steps,
    });
  }

  void _toggleStep(int index) {
    setState(() {
      _steps[index] = !_steps[index];
    });
    _updateData();
  }

  // Step management methods removed - using fixed step configuration

  int get _completedSteps => _steps.where((step) => step).length;
  double get _percentComplete => _steps.isEmpty ? 0.0 : (_completedSteps / _steps.length * 100);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Task Analysis Data Collection',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '$_completedSteps/${_steps.length} (${_percentComplete.round()}%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _percentComplete == 100 ? Colors.green : Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Progress Bar
        LinearProgressIndicator(
          value: _percentComplete / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            _percentComplete == 100 ? Colors.green : Colors.blue,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Steps List
        ..._steps.asMap().entries.map((entry) {
          final index = entry.key;
          final isCompleted = entry.value;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Checkbox(
                value: isCompleted,
                onChanged: (_) => _toggleStep(index),
              ),
              title: Text('Step ${index + 1}'),
              tileColor: isCompleted ? Colors.green[50] : null,
            ),
          );
        }),
        
        const SizedBox(height: 16),
        
        // Control buttons removed - using fixed step configuration
      ],
    );
  }
}
