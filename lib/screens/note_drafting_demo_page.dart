import 'package:flutter/material.dart';
import 'package:datasheets/services/note_drafting_service.dart';
import 'package:datasheets/widgets/note_drafting_widget.dart';

/// Demo page showing how to use the note drafting widgets
class NoteDraftingDemoPage extends StatefulWidget {
  const NoteDraftingDemoPage({super.key});

  @override
  State<NoteDraftingDemoPage> createState() => _NoteDraftingDemoPageState();
}

class _NoteDraftingDemoPageState extends State<NoteDraftingDemoPage> {
  String _currentNote = '';
  String _savedNote = '';

  // Example session data
  final SessionData _exampleSession = SessionData(
    providerName: 'Jane Doe, BCBA',
    npi: 'ATYPICAL',
    clientName: 'A.B.',
    dob: '2015-08-03',
    date: '2025-10-18',
    startTime: '09:00',
    endTime: '10:00',
    durationMinutes: 60,
    serviceName: 'Adaptive Behavior Treatment',
    cpt: '97153',
    modifiers: ['UC'],
    pos: '11',
    goalsList: ['task independence', 'manding', 'hand washing'],
    behaviors: 'Calm, cooperative; brief off-task moments during transitions.',
    interventions: 'Least-to-most prompting; differential reinforcement; task analysis.',
    dataSummary: 'Receptive ID: 8/10 trials (80% accuracy); Hand raising: 5 occurrences (0.17/min); Hand washing: 6/7 steps (86% completion)',
    caregiver: 'Parent observed and participated in session; reinforced strategies at home.',
    plan: 'Continue current programs; increase task complexity for receptive ID; fade prompts for hand washing.',
  );

  void _onNoteChanged(String note) {
    setState(() {
      _currentNote = note;
    });
  }

  void _onNoteSaved(String note) {
    setState(() {
      _savedNote = note;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Drafting Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'AI-Powered Clinical Note Generation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate professional clinical notes from session data using AI',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Full Note Drafting Widget
            const Text(
              'Full Note Drafting Widget',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            NoteDraftingWidget(
              session: _exampleSession,
              initialNote: _currentNote,
              onNoteChanged: _onNoteChanged,
              onNoteSaved: _onNoteSaved,
              ragContext: 'Use SOAP tone; focus on measurable outcomes.',
            ),
            
            const SizedBox(height: 24),
            
            // Compact Widget
            const Text(
              'Compact Note Drafting Widget',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            CompactNoteDraftingWidget(
              session: _exampleSession,
              initialNote: _currentNote,
              onNoteChanged: _onNoteChanged,
            ),
            
            const SizedBox(height: 24),
            
            // Note Preview
            if (_currentNote.isNotEmpty) ...[
              const Text(
                'Note Preview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              NotePreviewWidget(
                note: _currentNote,
                session: _exampleSession,
                onEdit: () {
                  // Navigate to edit mode
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit functionality would open here')),
                  );
                },
                onRegenerate: () {
                  // Regenerate note
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Regenerate functionality would trigger here')),
                  );
                },
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Current Note Status
            Card(
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Note Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Current Note Length: ${_currentNote.length} characters'),
                    Text('Saved Note Length: ${_savedNote.length} characters'),
                    if (_currentNote.isNotEmpty)
                      Text('Last Updated: ${DateTime.now().toString().substring(0, 19)}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Usage Instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How to Use',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Click the AI icon to generate a note'),
                    const Text('2. Click the stream icon for real-time generation'),
                    const Text('3. Add custom RAG context for specific instructions'),
                    const Text('4. Edit the generated note as needed'),
                    const Text('5. Save the note when complete'),
                    const SizedBox(height: 8),
                    const Text(
                      'The AI will generate professional clinical notes suitable for payer review.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
