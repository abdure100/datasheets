import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/behavior_definition.dart';
import '../models/behavior_log.dart';
import '../services/filemaker_service.dart';
import '../providers/session_provider.dart';

class BehaviorModal extends StatefulWidget {
  final String visitId;
  final String clientId;
  final String? assignmentId; // Optional assignment ID for context
  final BehaviorLog? existingLog;
  final List<BehaviorDefinition>? behaviorDefinitions; // Optional - if provided, use these instead of SessionProvider

  const BehaviorModal({
    super.key,
    required this.visitId,
    required this.clientId,
    this.assignmentId, // Optional - if null, allows general behavior logging
    this.existingLog,
    this.behaviorDefinitions, // Optional - if null, will use SessionProvider
  });

  @override
  State<BehaviorModal> createState() => _BehaviorModalState();
}

class _BehaviorModalState extends State<BehaviorModal> {
  final _formKey = GlobalKey<FormState>();
  BehaviorDefinition? _selectedBehavior;
  String _logType = 'count';
  int _count = 0;
  int _durationSeconds = 0;
  Timer? _timer;
  bool _isTiming = false; // Timer disabled for manual behavior logging
  String _antecedent = '';
  String _behavior = '';
  String _consequence = '';
  String _setting = '';
  String _perceivedFunction = '';
  int _severity = 1;
  bool _injury = false;
  bool _restraintUsed = false;
  String _notes = '';
  bool _isSaving = false;
  final FocusNode _notesFocusNode = FocusNode();
  final FocusNode _durationManualFocusNode = FocusNode();
  final FocusNode _antecedentFocusNode = FocusNode();
  final FocusNode _behaviorFocusNode = FocusNode();
  final FocusNode _consequenceFocusNode = FocusNode();
  final FocusNode _settingFocusNode = FocusNode();
  final FocusNode _functionFocusNode = FocusNode();
  final FocusNode _severityFocusNode = FocusNode();
  bool _isNotesFocused = false;
  bool _isDurationManualFocused = false;
  bool _isABCFocused = false;

  void _updateABCFocusState() {
    setState(() {
      _isABCFocused = _antecedentFocusNode.hasFocus ||
          _behaviorFocusNode.hasFocus ||
          _consequenceFocusNode.hasFocus ||
          _settingFocusNode.hasFocus ||
          _functionFocusNode.hasFocus ||
          _severityFocusNode.hasFocus;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingLog != null) {
      _loadExistingLog();
    }
    _notesFocusNode.addListener(() {
      setState(() {
        _isNotesFocused = _notesFocusNode.hasFocus;
      });
    });
    _durationManualFocusNode.addListener(() {
      setState(() {
        _isDurationManualFocused = _durationManualFocusNode.hasFocus;
      });
    });
    _antecedentFocusNode.addListener(_updateABCFocusState);
    _behaviorFocusNode.addListener(_updateABCFocusState);
    _consequenceFocusNode.addListener(_updateABCFocusState);
    _settingFocusNode.addListener(_updateABCFocusState);
    _functionFocusNode.addListener(_updateABCFocusState);
    _severityFocusNode.addListener(_updateABCFocusState);
  }

  @override
  void dispose() {
    _timer?.cancel(); // Clean up any existing timer
    _notesFocusNode.dispose();
    _durationManualFocusNode.dispose();
    _antecedentFocusNode.dispose();
    _behaviorFocusNode.dispose();
    _consequenceFocusNode.dispose();
    _settingFocusNode.dispose();
    _functionFocusNode.dispose();
    _severityFocusNode.dispose();
    super.dispose();
  }

  void _loadExistingLog() {
    final log = widget.existingLog!;
    _count = log.count ?? 0;
    _durationSeconds = log.durationSec ?? 0;
    _antecedent = log.antecedent ?? '';
    _behavior = log.behaviorDesc ?? '';
    _consequence = log.consequence ?? '';
    _setting = log.setting ?? '';
    _perceivedFunction = log.perceivedFunction ?? '';
    _severity = log.severity ?? 1;
    _injury = log.injury ?? false;
    _restraintUsed = log.restraintUsed ?? false;
    _notes = log.notes ?? '';
    
    // Determine log type
    if (log.isTiming) {
      _logType = 'duration';
    } else if (log.isABC) {
      _logType = 'abc';
    } else {
      _logType = 'count';
    }
  }

  void _startTimer() {
    if (_isTiming) return;
    
    setState(() => _isTiming = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _durationSeconds++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isTiming = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _durationSeconds = 0;
      _isTiming = false;
    });
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
             '${secs.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _saveBehaviorLog() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBehavior == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a behavior')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      
      final log = BehaviorLog(
        id: widget.existingLog?.id ?? '',
        visitId: widget.visitId,
        clientId: widget.clientId,
        behaviorId: _selectedBehavior!.id,
        assignmentId: widget.assignmentId, // Use context assignment ID
        count: _logType == 'count' ? _count : null,
        startTs: _logType == 'duration' ? DateTime.now() : null, // For manual entry, use current time as start
        endTs: _logType == 'duration' ? DateTime.now() : null, // For manual entry, use current time as end
        durationSec: _logType == 'duration' ? _durationSeconds : null,
        antecedent: _logType == 'abc' ? _antecedent : null,
        behaviorDesc: _logType == 'abc' ? _behavior : null,
        consequence: _logType == 'abc' ? _consequence : null,
        setting: _logType == 'abc' ? _setting : null,
        perceivedFunction: _logType == 'abc' ? _perceivedFunction : null,
        severity: _logType == 'abc' ? _severity : null,
        injury: _logType == 'abc' ? _injury : null,
        restraintUsed: _logType == 'abc' ? _restraintUsed : null,
        notes: _notes,
        collector: 'Current User', // TODO: Get from auth
        createdAt: widget.existingLog?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      BehaviorLog savedLog;
      if (widget.existingLog != null) {
        savedLog = await fileMakerService.updateBehaviorLog(log);
      } else {
        savedLog = await fileMakerService.createBehaviorLog(log);
      }
      
      if (mounted) {
        Navigator.pop(context, savedLog);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving behavior log: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use provided behavior definitions if available, otherwise use SessionProvider
    if (widget.behaviorDefinitions != null) {
      return _buildModalContent(widget.behaviorDefinitions!);
    }
    
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        final behaviorDefs = sessionProvider.behaviorDefinitions;
        return _buildModalContent(behaviorDefs);
      },
    );
  }

  Widget _buildModalContent(List<BehaviorDefinition> behaviorDefs) {
    return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.existingLog != null ? 'Edit Behavior Log' : 'Log Behavior',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                
                const Divider(),
                
                // Program Context Indicator
                if (widget.assignmentId != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.assignment, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Logging to current program',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Save Button at the top
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveBehaviorLog,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Only hide keyboard when tapping on empty space in scrollable area
                      // This won't interfere with TextFormField taps
                      final currentFocus = FocusScope.of(context).focusedChild;
                      if (currentFocus == null) {
                        FocusScope.of(context).unfocus();
                      }
                    },
                    behavior: HitTestBehavior.translucent,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Collapsible sections - hide when notes, duration manual input, or ABC fields are focused
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: (_isNotesFocused || _isDurationManualFocused || _isABCFocused)
                                ? const SizedBox.shrink()
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                    // Behavior Selection
                                    DropdownButtonFormField<BehaviorDefinition>(
                                      initialValue: _selectedBehavior,
                                      decoration: const InputDecoration(
                                        labelText: 'Behavior',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: behaviorDefs.map((def) {
                                        return DropdownMenuItem(
                                          value: def,
                                          child: Text(def.name),
                                        );
                                      }).toList(),
                                      onChanged: (def) {
                                        setState(() => _selectedBehavior = def);
                                      },
                                      validator: (value) {
                                        if (value == null) return 'Please select a behavior';
                                        return null;
                                      },
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Log Type Selection - Labels on top, radio buttons below
                                    Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              setState(() => _logType = 'count');
                                            },
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'Count',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Radio<String>(
                                                  value: 'count',
                                                  groupValue: _logType,
                                                  onChanged: (value) {
                                                    setState(() => _logType = value!);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              setState(() => _logType = 'duration');
                                            },
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'Duration',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Radio<String>(
                                                  value: 'duration',
                                                  groupValue: _logType,
                                                  onChanged: (value) {
                                                    setState(() => _logType = value!);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              setState(() => _logType = 'abc');
                                            },
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'ABC',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Radio<String>(
                                                  value: 'abc',
                                                  groupValue: _logType,
                                                  onChanged: (value) {
                                                    setState(() => _logType = value!);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Count Input with +/- buttons
                                    if (_logType == 'count') ...[
                                      const Text(
                                        'Count',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Minus button on the left
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                if (_count > 0) _count--;
                                              });
                                            },
                                            icon: const Icon(Icons.remove),
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.red[100],
                                              foregroundColor: Colors.red[700],
                                              padding: const EdgeInsets.all(16),
                                              minimumSize: const Size(60, 60),
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          // Count display in the middle
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey[300]!),
                                            ),
                                            child: Text(
                                              '$_count',
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          // Plus button on the right
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _count++;
                                              });
                                            },
                                            icon: const Icon(Icons.add),
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.green[100],
                                              foregroundColor: Colors.green[700],
                                              padding: const EdgeInsets.all(16),
                                              minimumSize: const Size(60, 60),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    
                                    // Duration Input with Timer Option
                                    if (_logType == 'duration') ...[
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.blue[200]!,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.timer, color: Colors.blue[700], size: 20),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Duration Measurement',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            
                                            // Duration Display
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: _isTiming ? Colors.green[50] : Colors.grey[50],
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: _isTiming ? Colors.green[200]! : Colors.grey[300]!,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  _formatDuration(_durationSeconds),
                                                  style: TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                    color: _isTiming ? Colors.green[700] : Colors.grey[700],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            
                                            const SizedBox(height: 12),
                                            
                                            // Timer Controls
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: _isTiming ? _stopTimer : _startTimer,
                                                    icon: Icon(_isTiming ? Icons.pause : Icons.play_arrow),
                                                    label: Text(_isTiming ? 'Stop Timer' : 'Start Timer'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: _isTiming ? Colors.red : Colors.green,
                                                      foregroundColor: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: _isTiming ? null : _resetTimer,
                                                    icon: const Icon(Icons.refresh),
                                                    label: const Text('Reset'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            
                                            const SizedBox(height: 12),
                                            
                                // Manual Entry Option
                                const Divider(),
                                const Text(
                                  'Or enter duration manually:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  focusNode: _durationManualFocusNode,
                                  initialValue: _durationSeconds.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter duration in seconds',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.edit),
                                    helperText: 'Enter duration manually if not using timer',
                                  ),
                                  onChanged: (value) {
                                    _durationSeconds = int.tryParse(value) ?? 0;
                                  },
                                ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    
                                    // ABC Input
                                    if (_logType == 'abc') ...[
                                      TextFormField(
                                        focusNode: _antecedentFocusNode,
                                        initialValue: _antecedent,
                                        decoration: const InputDecoration(
                                          labelText: 'Antecedent',
                                          border: OutlineInputBorder(),
                                        ),
                                        maxLines: 2,
                                        onChanged: (value) => _antecedent = value,
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        focusNode: _behaviorFocusNode,
                                        initialValue: _behavior,
                                        decoration: const InputDecoration(
                                          labelText: 'Behavior',
                                          border: OutlineInputBorder(),
                                        ),
                                        maxLines: 2,
                                        onChanged: (value) => _behavior = value,
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        focusNode: _consequenceFocusNode,
                                        initialValue: _consequence,
                                        decoration: const InputDecoration(
                                          labelText: 'Consequence',
                                          border: OutlineInputBorder(),
                                        ),
                                        maxLines: 2,
                                        onChanged: (value) => _consequence = value,
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              focusNode: _settingFocusNode,
                                              initialValue: _setting,
                                              decoration: const InputDecoration(
                                                labelText: 'Setting',
                                                border: OutlineInputBorder(),
                                              ),
                                              onChanged: (value) => _setting = value,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: TextFormField(
                                              focusNode: _functionFocusNode,
                                              initialValue: _perceivedFunction,
                                              decoration: const InputDecoration(
                                                labelText: 'Function',
                                                border: OutlineInputBorder(),
                                              ),
                                              onChanged: (value) => _perceivedFunction = value,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              focusNode: _severityFocusNode,
                                              initialValue: _severity.toString(),
                                              decoration: const InputDecoration(
                                                labelText: 'Severity (1-5)',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.number,
                                              onChanged: (value) {
                                                _severity = int.tryParse(value) ?? 1;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              children: [
                                                CheckboxListTile(
                                                  title: const Text('Injury'),
                                                  value: _injury,
                                                  onChanged: (value) {
                                                    setState(() => _injury = value ?? false);
                                                  },
                                                ),
                                                CheckboxListTile(
                                                  title: const Text('Restraint Used'),
                                                  value: _restraintUsed,
                                                  onChanged: (value) {
                                                    setState(() => _restraintUsed = value ?? false);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Notes
                        TextFormField(
                          focusNode: _notesFocusNode,
                          initialValue: _notes,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          onChanged: (value) => _notes = value,
                        ),
                      ],
                    ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
  }
}
