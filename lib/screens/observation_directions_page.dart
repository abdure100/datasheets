import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../models/visit.dart';
import '../services/filemaker_service.dart';

class ObservationDirectionsPage extends StatefulWidget {
  final Visit? visit;
  final Client? client;

  const ObservationDirectionsPage({
    super.key,
    this.visit,
    this.client,
  });

  @override
  State<ObservationDirectionsPage> createState() => _ObservationDirectionsPageState();
}

class _ObservationDirectionsPageState extends State<ObservationDirectionsPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _observationsController = TextEditingController();
  final _directionsController = TextEditingController();
  final _protocolModificationsController = TextEditingController();
  final _treatmentProceduresController = TextEditingController();
  final _goalsModificationsController = TextEditingController();
  final _dataCollectionMethodsController = TextEditingController();
  final _scopeOfServiceController = TextEditingController();
  final _individualResponseController = TextEditingController();
  final _qspNameController = TextEditingController();
  final _qspTitleController = TextEditingController();
  bool _isLoading = false;
  DateTime? _sessionStartTime;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = widget.visit?.startTs ?? DateTime.now();
    _startTimer();
    
    // Pre-fill QSP title
    _qspTitleController.text = 'Qualified Supervising Professional (QSP)';
    
    // Pre-fill QSP name after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      if (mounted) {
        setState(() {
          _qspNameController.text = fileMakerService.currentStaffName ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _observationsController.dispose();
    _directionsController.dispose();
    _protocolModificationsController.dispose();
    _treatmentProceduresController.dispose();
    _goalsModificationsController.dispose();
    _dataCollectionMethodsController.dispose();
    _scopeOfServiceController.dispose();
    _individualResponseController.dispose();
    _qspNameController.dispose();
    _qspTitleController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_sessionStartTime != null) {
      _updateElapsed();
      // Update every second
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _startTimer();
        }
      });
    }
  }

  void _updateElapsed() {
    if (_sessionStartTime != null) {
      setState(() {
        _elapsed = DateTime.now().difference(_sessionStartTime!);
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  Future<void> _endSession() async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Session'),
          content: const Text('Are you sure you want to end this observation/directions session?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('End Session'),
            ),
          ],
        );
      },
    );

    if (shouldEnd != true) return;

    setState(() => _isLoading = true);

    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      
      if (widget.visit != null) {
        // Update visit end time
        await fileMakerService.updateVisitEndTs(widget.visit!.id, DateTime.now());
        
        // Close the visit
        await fileMakerService.closeVisit(widget.visit!.id, DateTime.now());
      }

      // Save to specific FileMaker fields for service code 97155
      try {
        await fileMakerService.updateObservationDirectionFields(
          widget.visit!.id,
          additionalNotes: _notesController.text.trim(),
          responseProgress: _individualResponseController.text.trim(),
          methods: _dataCollectionMethodsController.text.trim(),
          modifications: _goalsModificationsController.text.trim(),
          adjustments: _treatmentProceduresController.text.trim(),
          observations: _observationsController.text.trim(),
        );
        print('✅ Observation/direction fields saved to FileMaker');
      } catch (e) {
        print('⚠️ Could not save to FileMaker fields: $e');
        // Fallback: save as combined notes
        final combinedNotes = _buildDHSCompliantNotes();
        if (combinedNotes.isNotEmpty) {
          try {
            await fileMakerService.saveNoteToNotesLayout(
              widget.visit!.id,
              combinedNotes,
            );
          } catch (e2) {
            print('⚠️ Could not save notes as fallback: $e2');
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session ended successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to start visit page
        Navigator.pushReplacementNamed(context, '/start-visit');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ending session: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveNotes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      
      if (widget.visit != null) {
        // Save to specific FileMaker fields for service code 97155
        try {
          await fileMakerService.updateObservationDirectionFields(
            widget.visit!.id,
            additionalNotes: _notesController.text.trim(),
            responseProgress: _individualResponseController.text.trim(),
            methods: _dataCollectionMethodsController.text.trim(),
            modifications: _goalsModificationsController.text.trim(),
            adjustments: _treatmentProceduresController.text.trim(),
            observations: _observationsController.text.trim(),
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notes saved successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          print('⚠️ Error saving observation/direction fields: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving notes: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving notes: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.visit == null || widget.client == null) {
      return const Scaffold(
        body: Center(
          child: Text('No active session'),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('End Session?'),
              content: const Text('Are you sure you want to leave? The session will be ended.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('End Session'),
                ),
              ],
            );
          },
        );
        
        if (shouldPop == true) {
          await _endSession();
        }
        
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.client!.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('End Session?'),
                    content: const Text('Are you sure you want to leave? The session will be ended.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('End Session'),
                      ),
                    ],
                  );
                },
              );
              
              if (shouldPop == true) {
                await _endSession();
              }
            },
          ),
          actions: [
            // Save Notes Button
            IconButton(
              onPressed: _isLoading ? null : _saveNotes,
              icon: const Icon(Icons.save),
              tooltip: 'Save Notes',
            ),
            // Session Timer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  _formatDuration(_elapsed),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Session Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.visibility, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Observation/Directions Session',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('Client: ${widget.client!.name}'),
                              Text('Start Time: ${_formatDateTime(widget.visit!.startTs)}'),
                              Text('Duration: ${_formatDuration(_elapsed)}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Provider Information (DHS Required)
                      Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Provider Information (DHS Required)',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _qspNameController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter QSP name...',
                                  border: OutlineInputBorder(),
                                  labelText: 'QSP Name *',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'QSP name is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _qspTitleController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter QSP title...',
                                  border: OutlineInputBorder(),
                                  labelText: 'QSP Title *',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'QSP title is required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Scope of Service (DHS Required)
                      Card(
                        color: Colors.green[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.description, color: Colors.green),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Scope of Service (DHS Required)',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _scopeOfServiceController,
                                decoration: const InputDecoration(
                                  hintText: 'Describe the scope of service provided during this observation/direction session...',
                                  border: OutlineInputBorder(),
                                  labelText: 'Scope of Service *',
                                ),
                                maxLines: 5,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Scope of service is required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Observations Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.visibility, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Observations',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _observationsController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter your observations here...',
                                  border: OutlineInputBorder(),
                                  labelText: 'Observations',
                                ),
                                maxLines: 8,
                                textInputAction: TextInputAction.newline,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Directions Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.directions, color: Colors.green),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Directions',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _directionsController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter directions given here...',
                                  border: OutlineInputBorder(),
                                  labelText: 'Directions',
                                ),
                                maxLines: 8,
                                textInputAction: TextInputAction.newline,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Protocol Modifications (DHS Required)
                      Card(
                        color: Colors.orange[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.settings, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Protocol Modifications (DHS Required)',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Real-time protocol modifications must be documented per DHS MN EIDBI requirements.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _treatmentProceduresController,
                                decoration: const InputDecoration(
                                  hintText: 'Describe adjustments to treatment procedures...',
                                  border: OutlineInputBorder(),
                                  labelText: 'Treatment Procedures Adjustments',
                                ),
                                maxLines: 4,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _goalsModificationsController,
                                decoration: const InputDecoration(
                                  hintText: 'Describe goals modifications...',
                                  border: OutlineInputBorder(),
                                  labelText: 'Goals Modifications',
                                ),
                                maxLines: 4,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _dataCollectionMethodsController,
                                decoration: const InputDecoration(
                                  hintText: 'Describe data collection method changes...',
                                  border: OutlineInputBorder(),
                                  labelText: 'Data Collection Methods',
                                ),
                                maxLines: 4,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _protocolModificationsController,
                                decoration: const InputDecoration(
                                  hintText: 'Describe other protocol modifications...',
                                  border: OutlineInputBorder(),
                                  labelText: 'Other Protocol Modifications',
                                ),
                                maxLines: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Individual's Response/Progress (DHS Required)
                      Card(
                        color: Colors.purple[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.trending_up, color: Colors.purple),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Individual's Response/Progress (DHS Required)",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _individualResponseController,
                                decoration: const InputDecoration(
                                  hintText: 'Describe the individual\'s response and progress during this session...',
                                  border: OutlineInputBorder(),
                                  labelText: "Individual's Response/Progress *",
                                ),
                                maxLines: 6,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Individual's response/progress is required";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Additional Notes Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.note, color: Colors.purple),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Additional Notes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _notesController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter any additional notes here...',
                                  border: OutlineInputBorder(),
                                  labelText: 'Notes',
                                ),
                                maxLines: 6,
                                textInputAction: TextInputAction.newline,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // End Session Button
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _endSession,
                        icon: const Icon(Icons.stop),
                        label: const Text('End Session'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Build DHS MN EIDBI compliant notes format
  String _buildDHSCompliantNotes() {
    final List<String> sections = [];
    
    // Provider Information (Required by DHS)
    final qspName = _qspNameController.text.trim();
    final qspTitle = _qspTitleController.text.trim();
    if (qspName.isNotEmpty || qspTitle.isNotEmpty) {
      sections.add('PROVIDER INFORMATION:');
      if (qspName.isNotEmpty) sections.add('QSP Name: $qspName');
      if (qspTitle.isNotEmpty) sections.add('QSP Title: $qspTitle');
      sections.add('');
    }
    
    // Type of Service (Required by DHS)
    sections.add('TYPE OF SERVICE: Observation and Direction (O&D)');
    sections.add('');
    
    // Date and Session Times (Required by DHS)
    if (widget.visit != null) {
      final startTime = widget.visit!.startTs;
      final endTime = DateTime.now();
      sections.add('SESSION TIMES:');
      sections.add('Date: ${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}');
      sections.add('Start Time: ${_formatDateTime(startTime)}');
      sections.add('End Time: ${_formatDateTime(endTime)}');
      sections.add('Duration: ${_formatDuration(_elapsed)}');
      sections.add('');
    }
    
    // Scope of Service (Required by DHS)
    final scopeOfService = _scopeOfServiceController.text.trim();
    if (scopeOfService.isNotEmpty) {
      sections.add('SCOPE OF SERVICE:');
      sections.add(scopeOfService);
      sections.add('');
    }
    
    // Observations
    final observations = _observationsController.text.trim();
    if (observations.isNotEmpty) {
      sections.add('OBSERVATIONS:');
      sections.add(observations);
      sections.add('');
    }
    
    // Directions
    final directions = _directionsController.text.trim();
    if (directions.isNotEmpty) {
      sections.add('DIRECTIONS GIVEN:');
      sections.add(directions);
      sections.add('');
    }
    
    // Protocol Modifications (Required by DHS - Real-time protocol modification)
    final protocolMods = _protocolModificationsController.text.trim();
    final treatmentProcedures = _treatmentProceduresController.text.trim();
    final goalsMods = _goalsModificationsController.text.trim();
    final dataCollectionMethods = _dataCollectionMethodsController.text.trim();
    
    if (protocolMods.isNotEmpty || treatmentProcedures.isNotEmpty || 
        goalsMods.isNotEmpty || dataCollectionMethods.isNotEmpty) {
      sections.add('PROTOCOL MODIFICATIONS (DHS MN EIDBI Required):');
      
      if (treatmentProcedures.isNotEmpty) {
        sections.add('Treatment Procedures Adjustments:');
        sections.add(treatmentProcedures);
        sections.add('');
      }
      
      if (goalsMods.isNotEmpty) {
        sections.add('Goals Modifications:');
        sections.add(goalsMods);
        sections.add('');
      }
      
      if (dataCollectionMethods.isNotEmpty) {
        sections.add('Data Collection Methods:');
        sections.add(dataCollectionMethods);
        sections.add('');
      }
      
      if (protocolMods.isNotEmpty) {
        sections.add('Other Protocol Modifications:');
        sections.add(protocolMods);
        sections.add('');
      }
    }
    
    // Individual's Response/Progress (Required by DHS)
    final individualResponse = _individualResponseController.text.trim();
    if (individualResponse.isNotEmpty) {
      sections.add("INDIVIDUAL'S RESPONSE/PROGRESS:");
      sections.add(individualResponse);
      sections.add('');
    }
    
    // Additional Notes
    final notes = _notesController.text.trim();
    if (notes.isNotEmpty) {
      sections.add('ADDITIONAL NOTES:');
      sections.add(notes);
    }
    
    return sections.join('\n');
  }
}

