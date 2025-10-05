import 'package:flutter/material.dart';
import 'dart:async';

class RateWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final Function(Map<String, dynamic>) onDataChanged;

  const RateWidget({
    super.key,
    required this.config,
    required this.onDataChanged,
  });

  @override
  State<RateWidget> createState() => _RateWidgetState();
}

class _RateWidgetState extends State<RateWidget> {
  int _count = 0;
  int _seconds = 0;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _count = widget.config['count'] ?? 0;
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
      _count = 0;
      _seconds = 0;
      _isRunning = false;
    });
    _updateData();
  }

  void _incrementCount() {
    setState(() {
      _count++;
    });
    _updateData();
  }

  void _updateData() {
    widget.onDataChanged({
      ...widget.config,
      'count': _count,
      'seconds': _seconds,
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
           '${secs.toString().padLeft(2, '0')}';
  }

  double get _ratePerMinute {
    if (_seconds == 0) return 0.0;
    return _count / (_seconds / 60);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rate Data Collection',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Stats Display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isRunning ? Colors.green[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isRunning ? Colors.green[200]! : Colors.blue[200]!,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '$_count',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Text('Events'),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        _formatDuration(_seconds),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _isRunning ? Colors.green[700] : Colors.blue[700],
                        ),
                      ),
                      const Text('Time'),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        _ratePerMinute.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Text('Per Min'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Control Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _incrementCount,
                icon: const Icon(Icons.add),
                label: const Text('+1 Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isRunning ? _stopTimer : _startTimer,
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(_isRunning ? 'Stop Timer' : 'Start Timer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Reset Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isRunning ? null : _resetTimer,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset All'),
          ),
        ),
      ],
    );
  }
}
