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
  int _misses = 0;
  int _noResponse = 0;
  Map<String, int> _promptCounts = {};
  String? _mostIntrusivePrompt; // Track the highest level prompt that led to success
  String? _selectedPrompt; // Currently selected prompt for the next hit

  @override
  void initState() {
    super.initState();
    _total = widget.config['total'] ?? 0;
    _hits = widget.config['hits'] ?? 0;
    _misses = widget.config['misses'] ?? 0;
    _noResponse = widget.config['noResponse'] ?? 0;
    _promptCounts = Map<String, int>.from(widget.config['promptCounts'] ?? {});
    _mostIntrusivePrompt = widget.config['mostIntrusivePrompt'];
  }

  void _updateData() {
    final percentCorrect = _total > 0 ? (_hits / _total * 100).round() : 0;
    final percentIncorrect = _total > 0 ? (_misses / _total * 100).round() : 0;
    final percentNoResponse = _total > 0 ? (_noResponse / _total * 100).round() : 0;
    
    // Calculate prompted trials (only count successful hits that used prompts, exclude "Ind")
    final promptedHits = _hits - (_promptCounts['Ind'] ?? 0);
    final percentPrompted = _total > 0 ? (promptedHits / _total * 100).round() : 0;
    
    final updatedData = {
      ...widget.config,
      'total': _total,
      'hits': _hits,
      'misses': _misses,
      'noResponse': _noResponse,
      'promptCounts': _promptCounts,
      'mostIntrusivePrompt': _mostIntrusivePrompt,
      'totalPrompted': promptedHits,
      'percentCorrect': percentCorrect,
      'percentIncorrect': percentIncorrect,
      'percentNoResponse': percentNoResponse,
      'percentPrompted': percentPrompted,
    };
    
    print('🔍 TrialsWidget _updateData: $updatedData');
    widget.onDataChanged(updatedData);
  }

  // Determine prompt hierarchy (most intrusive to least intrusive)
  int _getPromptLevel(String promptType) {
    switch (promptType.toLowerCase()) {
      case 'fp':
        return 7; // Most intrusive
      case 'pp':
        return 6;
      case 'm':
        return 5;
      case 'vb':
        return 4;
      case 'vs':
        return 3;
      case 'g':
        return 2;
      case 'ind':
        return 1; // Least intrusive (ultimate goal)
      default:
        return 0;
    }
  }

  // Update most intrusive prompt when a hit occurs
  void _updateMostIntrusivePrompt() {
    String? currentMostIntrusive = _mostIntrusivePrompt;
    int currentLevel = currentMostIntrusive != null ? _getPromptLevel(currentMostIntrusive) : 0;
    
    // Find the most intrusive prompt used in this session
    for (String promptType in _promptCounts.keys) {
      if (_promptCounts[promptType]! > 0) {
        int promptLevel = _getPromptLevel(promptType);
        if (promptLevel > currentLevel) {
          currentMostIntrusive = promptType;
          currentLevel = promptLevel;
        }
      }
    }
    
    _mostIntrusivePrompt = currentMostIntrusive;
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
        
        // Most Intrusive Prompt Display
        if (_mostIntrusivePrompt != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flag,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Most Intrusive Prompt: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _mostIntrusivePrompt!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Prompt Selection for Next Hit
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Prompt for Next Hit:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildPromptSelectionButtons(),
                ),
              ),
              if (_selectedPrompt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Selected: $_selectedPrompt',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Control Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _selectedPrompt != null ? () {
                  setState(() {
                    _total++;
                    _hits++;
                    // Record the prompt that led to this hit
                    _promptCounts[_selectedPrompt!] = (_promptCounts[_selectedPrompt!] ?? 0) + 1;
                    _updateMostIntrusivePrompt(); // Update MIP when hit occurs
                    _selectedPrompt = null; // Reset selection
                  });
                  _updateData();
                } : null,
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
                    _misses++;
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
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _total++;
                    _noResponse++;
                    // NR counts as a trial but not as a hit
                  });
                  _updateData();
                },
                icon: const Icon(Icons.block),
                label: const Text('NR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Reset Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _total = 0;
                _hits = 0;
                _misses = 0;
                _noResponse = 0;
                _promptCounts.clear();
                _mostIntrusivePrompt = null; // Reset MIP
                _selectedPrompt = null; // Reset selection
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

  List<Widget> _buildPromptSelectionButtons() {
    // Get prompt types from the program configuration
    final promptTypes = (widget.config['promptTypes'] as List<dynamic>?)?.cast<String>() ?? [
      'Ind',
      'G',
      'VS',
      'VB',
      'M',
      'PP',
      'FP',
    ];

    return promptTypes.map((promptType) {
      final isSelected = _selectedPrompt == promptType;
      
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedPrompt = isSelected ? null : promptType;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[200] : Colors.blue[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.blue[400]! : Colors.blue[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            promptType,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.blue[800] : Colors.blue[700],
            ),
          ),
        ),
      );
    }).toList();
  }


}
