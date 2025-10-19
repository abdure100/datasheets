import 'package:flutter/material.dart';
import 'package:datasheets/services/note_drafting_service.dart';

/// Widget for AI-powered clinical note generation and editing
class NoteDraftingWidget extends StatefulWidget {
  final SessionData session;
  final String? initialNote;
  final Function(String)? onNoteChanged;
  final Function(String)? onNoteSaved;
  final bool readOnly;
  final String? ragContext;

  const NoteDraftingWidget({
    super.key,
    required this.session,
    this.initialNote,
    this.onNoteChanged,
    this.onNoteSaved,
    this.readOnly = false,
    this.ragContext,
  });

  @override
  State<NoteDraftingWidget> createState() => _NoteDraftingWidgetState();
}

class _NoteDraftingWidgetState extends State<NoteDraftingWidget> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _ragController = TextEditingController();
  bool _isGenerating = false;
  bool _isStreaming = false;
  String _streamingText = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.initialNote ?? '';
    _ragController.text = widget.ragContext ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    _ragController.dispose();
    super.dispose();
  }

  /// Generate note using AI
  Future<void> _generateNote() async {
    if (_isGenerating || _isStreaming) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final noteDraft = await NoteDraftingService.generateNoteDraft(
        session: widget.session,
        ragContext: _ragController.text.trim(),
      );

      setState(() {
        _noteController.text = noteDraft;
        _isGenerating = false;
      });

      widget.onNoteChanged?.call(noteDraft);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating note: $e';
        _isGenerating = false;
      });
    }
  }

  /// Generate note with streaming
  Future<void> _generateNoteStreaming() async {
    if (_isGenerating || _isStreaming) return;

    setState(() {
      _isStreaming = true;
      _streamingText = '';
      _errorMessage = null;
    });

    try {
      await for (final chunk in NoteDraftingService.generateNoteDraftStream(
        session: widget.session,
        ragContext: _ragController.text.trim(),
      )) {
        setState(() {
          _streamingText += chunk;
          _noteController.text = _streamingText;
        });
        widget.onNoteChanged?.call(_streamingText);
      }

      setState(() {
        _isStreaming = false;
        _streamingText = '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating streaming note: $e';
        _isStreaming = false;
        _streamingText = '';
      });
    }
  }

  /// Save the current note
  void _saveNote() {
    widget.onNoteSaved?.call(_noteController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Clear the current note
  void _clearNote() {
    setState(() {
      _noteController.clear();
      _streamingText = '';
    });
    widget.onNoteChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.notes, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Clinical Note Generation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!widget.readOnly) ...[
                  IconButton(
                    onPressed: _isGenerating || _isStreaming ? null : _generateNote,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    tooltip: 'Generate Note with AI',
                  ),
                  IconButton(
                    onPressed: _isGenerating || _isStreaming ? null : _generateNoteStreaming,
                    icon: _isStreaming
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.stream),
                    tooltip: 'Generate Note with Streaming',
                  ),
                  IconButton(
                    onPressed: _clearNote,
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear Note',
                  ),
                  IconButton(
                    onPressed: _saveNote,
                    icon: const Icon(Icons.save),
                    tooltip: 'Save Note',
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Session Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session: ${widget.session.clientName} - ${widget.session.date}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Provider: ${widget.session.providerName}'),
                  Text('Duration: ${widget.session.durationMinutes} minutes'),
                  Text('Goals: ${widget.session.goalsList.join(', ')}'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // RAG Context (if not read-only)
            if (!widget.readOnly) ...[
              TextField(
                controller: _ragController,
                decoration: const InputDecoration(
                  labelText: 'RAG Context (Optional)',
                  hintText: 'Add specific instructions for note generation...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.settings),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
            ],
            
            // Error Message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[600]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Note Editor
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Clinical Note',
                hintText: 'Generated note will appear here...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.description),
                suffixIcon: _isStreaming
                    ? const Icon(Icons.stream, color: Colors.blue)
                    : null,
              ),
              maxLines: 10,
              readOnly: widget.readOnly,
              onChanged: widget.onNoteChanged,
            ),
            
            // Status indicators
            if (_isGenerating || _isStreaming) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isStreaming ? Colors.blue : Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isStreaming ? 'Generating note with streaming...' : 'Generating note...',
                    style: TextStyle(
                      color: _isStreaming ? Colors.blue : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact version of the note drafting widget
class CompactNoteDraftingWidget extends StatefulWidget {
  final SessionData session;
  final String? initialNote;
  final Function(String)? onNoteChanged;
  final bool readOnly;

  const CompactNoteDraftingWidget({
    super.key,
    required this.session,
    this.initialNote,
    this.onNoteChanged,
    this.readOnly = false,
  });

  @override
  State<CompactNoteDraftingWidget> createState() => _CompactNoteDraftingWidgetState();
}

class _CompactNoteDraftingWidgetState extends State<CompactNoteDraftingWidget> {
  final TextEditingController _noteController = TextEditingController();
  bool _isGenerating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.initialNote ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _generateNote() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final noteDraft = await NoteDraftingService.generateNoteDraft(
        session: widget.session,
        ragContext: 'Use SOAP tone; be concise.',
      );

      setState(() {
        _noteController.text = noteDraft;
        _isGenerating = false;
      });

      widget.onNoteChanged?.call(noteDraft);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Clinical Note',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (!widget.readOnly)
                  IconButton(
                    onPressed: _isGenerating ? null : _generateNote,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome, size: 20),
                    tooltip: 'Generate Note',
                  ),
              ],
            ),
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Click generate to create a clinical note...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              readOnly: widget.readOnly,
              onChanged: widget.onNoteChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Note preview widget for displaying generated notes
class NotePreviewWidget extends StatelessWidget {
  final String note;
  final SessionData session;
  final VoidCallback? onEdit;
  final VoidCallback? onRegenerate;

  const NotePreviewWidget({
    super.key,
    required this.note,
    required this.session,
    this.onEdit,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Generated Clinical Note',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit Note',
                  ),
                if (onRegenerate != null)
                  IconButton(
                    onPressed: onRegenerate,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Regenerate Note',
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Session summary
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${session.clientName} • ${session.date} • ${session.durationMinutes}min',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Note content
            SelectableText(
              note,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
