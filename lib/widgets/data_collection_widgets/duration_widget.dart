import 'package:flutter/material.dart';
import 'dart:async';

class DurationWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final Function(Map<String, dynamic>) onDataChanged;

  const DurationWidget({
    super.key,
    required this.config,
    required this.onDataChanged,
  });

  @override
  State<DurationWidget> createState() => _DurationWidgetState();
}

class _DurationWidgetState extends State<DurationWidget> {
  int _seconds = 0;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _seconds = widget.config['seconds'] ?? 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
      _updateData();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    _updateData();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = 0;
      _isRunning = false;
    });
    _updateData();
  }

  void _updateData() {
    widget.onDataChanged({
      ...widget.config,
      'seconds': _seconds,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duration Data Collection',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Duration Display
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isRunning ? Colors.green[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isRunning ? Colors.green[200]! : Colors.blue[200]!,
            ),
          ),
          child: Center(
            child: Text(
              _formatDuration(_seconds),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: _isRunning ? Colors.green[700] : Colors.blue[700],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Control Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isRunning ? _stopTimer : _startTimer,
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(_isRunning ? 'Stop' : 'Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isRunning ? null : _resetTimer,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
