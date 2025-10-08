import 'package:flutter/material.dart';
import 'dart:async';

class TimeSamplingWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final Function(Map<String, dynamic>) onDataChanged;

  const TimeSamplingWidget({
    super.key,
    required this.config,
    required this.onDataChanged,
  });

  @override
  State<TimeSamplingWidget> createState() => _TimeSamplingWidgetState();
}

class _TimeSamplingWidgetState extends State<TimeSamplingWidget> {
  List<bool> _samples = [];
  Timer? _timer;
  Timer? _countdownTimer;
  bool _isRunning = false;
  int _currentInterval = 0;
  int _intervalSeconds = 30; // Default 30 seconds
  int _countdownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _samples = List<bool>.from(widget.config['samples'] ?? []);
    _intervalSeconds = widget.config['intervalSeconds'] ?? 30;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startSampling() {
    if (_isRunning) return;
    
    setState(() {
      _isRunning = true;
      _countdownSeconds = _intervalSeconds;
    });
    
    // Start countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownSeconds--;
      });
    });
    
    // Start sampling timer
    _timer = Timer.periodic(Duration(seconds: _intervalSeconds), (timer) {
      _promptSample();
    });
  }

  void _stopSampling() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _isRunning = false;
      _countdownSeconds = 0;
    });
    _updateData();
  }

  void _promptSample() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Time Sample'),
        content: const Text('Is the client on-task right now?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _recordSample(false);
            },
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _recordSample(true);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _recordSample(bool onTask) {
    setState(() {
      _samples.add(onTask);
      _currentInterval++;
      _countdownSeconds = _intervalSeconds; // Reset countdown for next interval
    });
    _updateData();
  }

  void _resetSamples() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _samples.clear();
      _currentInterval = 0;
      _isRunning = false;
      _countdownSeconds = 0;
    });
    _updateData();
  }

  void _updateData() {
    widget.onDataChanged({
      ...widget.config,
      'samples': _samples,
      'intervalSeconds': _intervalSeconds,
    });
  }

  int get _onTaskSamples => _samples.where((sample) => sample).length;
  double get _percentOnTask => _samples.isEmpty ? 0.0 : (_onTaskSamples / _samples.length * 100);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Time Sampling Data Collection',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '$_onTaskSamples/${_samples.length} (${_percentOnTask.round()}%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _percentOnTask >= 80 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Interval Setting
        Row(
          children: [
            const Text('Interval: '),
            DropdownButton<int>(
              value: _intervalSeconds,
              items: [15, 30, 60, 120].map((seconds) {
                return DropdownMenuItem(
                  value: seconds,
                  child: Text('${seconds}s'),
                );
              }).toList(),
              onChanged: _isRunning ? null : (value) {
                setState(() {
                  _intervalSeconds = value!;
                });
                _updateData();
              },
            ),
            const SizedBox(width: 16),
            Text(_isRunning ? 'Next sample in: ${_countdownSeconds}s' : 'Not running'),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Countdown Display
        if (_isRunning) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Next sample in: ${_countdownSeconds}s',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Progress Bar
        LinearProgressIndicator(
          value: _samples.isEmpty ? 0.0 : _percentOnTask / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            _percentOnTask >= 80 ? Colors.green : Colors.orange,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Control Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isRunning ? _stopSampling : _startSampling,
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(_isRunning ? 'Stop Sampling' : 'Start Sampling'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isRunning ? null : _resetSamples,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
            ),
          ],
        ),
        
        if (_samples.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Sample History:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _samples.asMap().entries.map((entry) {
              final index = entry.key;
              final onTask = entry.value;
              return Chip(
                label: Text('${index + 1}'),
                backgroundColor: onTask ? Colors.green[100] : Colors.red[100],
                labelStyle: TextStyle(
                  color: onTask ? Colors.green[800] : Colors.red[800],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
