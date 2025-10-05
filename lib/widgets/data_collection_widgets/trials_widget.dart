import 'package:flutter/material.dart';

class TrialsWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final Function(Map<String, dynamic>) onDataChanged;

  const TrialsWidget({
    super.key,
    required this.config,
    required this.onDataChanged,
  });

  @override
  State<TrialsWidget> createState() => _TrialsWidgetState();
}

class _TrialsWidgetState extends State<TrialsWidget> {
  int _total = 0;
  int _hits = 0;

  @override
  void initState() {
    super.initState();
    _total = widget.config['total'] ?? 0;
    _hits = widget.config['hits'] ?? 0;
  }

  void _updateData() {
    widget.onDataChanged({
      ...widget.config,
      'total': _total,
      'hits': _hits,
    });
  }

  @override
  Widget build(BuildContext context) {
    final percent = _total > 0 ? (_hits / _total * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trials Data Collection',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Current Block Stats
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '$_total',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text('Total Trials'),
                ],
              ),
              Column(
                children: [
                  Text(
                    '$_hits',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text('Correct'),
                ],
              ),
              Column(
                children: [
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: percent >= 80 ? Colors.green : Colors.orange,
                    ),
                  ),
                  const Text('Accuracy'),
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
                onPressed: () {
                  setState(() {
                    _total++;
                    _hits++;
                  });
                  _updateData();
                },
                icon: const Icon(Icons.add),
                label: const Text('Hit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _total++;
                  });
                  _updateData();
                },
                icon: const Icon(Icons.remove),
                label: const Text('Miss'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
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
            onPressed: () {
              setState(() {
                _total = 0;
                _hits = 0;
              });
              _updateData();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Block'),
          ),
        ),
      ],
    );
  }
}
