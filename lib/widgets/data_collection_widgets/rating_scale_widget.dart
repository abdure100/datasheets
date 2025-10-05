import 'package:flutter/material.dart';

class RatingScaleWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final Function(Map<String, dynamic>) onDataChanged;

  const RatingScaleWidget({
    super.key,
    required this.config,
    required this.onDataChanged,
  });

  @override
  State<RatingScaleWidget> createState() => _RatingScaleWidgetState();
}

class _RatingScaleWidgetState extends State<RatingScaleWidget> {
  double _rating = 0.0;
  int _minValue = 1;
  int _maxValue = 5;
  String _label = '';

  @override
  void initState() {
    super.initState();
    _rating = (widget.config['rating'] ?? 0).toDouble();
    _minValue = widget.config['minValue'] ?? 1;
    _maxValue = widget.config['maxValue'] ?? 5;
    _label = widget.config['label'] ?? 'Rate the behavior';
  }

  void _updateData() {
    widget.onDataChanged({
      ...widget.config,
      'rating': _rating.round(),
      'minValue': _minValue,
      'maxValue': _maxValue,
      'label': _label,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rating Scale Data Collection',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Rating Display
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            children: [
              Text(
                _label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '${_rating.round()}',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              Text(
                'out of $_maxValue',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Slider
        Slider(
          value: _rating,
          min: _minValue.toDouble(),
          max: _maxValue.toDouble(),
          divisions: _maxValue - _minValue,
          label: '${_rating.round()}',
          onChanged: (value) {
            setState(() {
              _rating = value;
            });
            _updateData();
          },
        ),
        
        // Quick Rating Buttons
        const SizedBox(height: 16),
        const Text(
          'Quick Rating:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(
            _maxValue - _minValue + 1,
            (index) {
              final value = _minValue + index;
              final isSelected = _rating.round() == value;
              return ChoiceChip(
                label: Text('$value'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _rating = value.toDouble();
                  });
                  _updateData();
                },
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Scale Configuration
        ExpansionTile(
          title: const Text('Scale Settings'),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _minValue.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Min Value',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final newMin = int.tryParse(value) ?? _minValue;
                            if (newMin < _maxValue) {
                              setState(() {
                                _minValue = newMin;
                                if (_rating < newMin) _rating = newMin.toDouble();
                              });
                              _updateData();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: _maxValue.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Max Value',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final newMax = int.tryParse(value) ?? _maxValue;
                            if (newMax > _minValue) {
                              setState(() {
                                _maxValue = newMax;
                                if (_rating > newMax) _rating = newMax.toDouble();
                              });
                              _updateData();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _label,
                    decoration: const InputDecoration(
                      labelText: 'Rating Label',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _label = value;
                      });
                      _updateData();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
