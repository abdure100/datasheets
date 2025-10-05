import 'package:flutter/material.dart';

class FrequencyWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final Function(Map<String, dynamic>) onDataChanged;

  const FrequencyWidget({
    super.key,
    required this.config,
    required this.onDataChanged,
  });

  @override
  State<FrequencyWidget> createState() => _FrequencyWidgetState();
}

class _FrequencyWidgetState extends State<FrequencyWidget> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _count = widget.config['count'] ?? 0;
  }

  void _updateData() {
    widget.onDataChanged({
      ...widget.config,
      'count': _count,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequency Data Collection',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Current Count Display
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Center(
            child: Text(
              '$_count',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
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
                    _count++;
                  });
                  _updateData();
                },
                icon: const Icon(Icons.add),
                label: const Text('+1'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_count > 0) {
                    setState(() {
                      _count--;
                    });
                    _updateData();
                  }
                },
                icon: const Icon(Icons.remove),
                label: const Text('-1'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
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
                _count = 0;
              });
              _updateData();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Count'),
          ),
        ),
      ],
    );
  }
}
