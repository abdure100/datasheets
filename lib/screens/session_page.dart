import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/visit.dart';
import '../models/client.dart';
import '../models/session_record.dart';
import '../models/program_assignment.dart';
import '../services/filemaker_service.dart';
import '../services/note_drafting_service.dart';
import '../providers/session_provider.dart';
import '../widgets/program_card.dart';
import '../widgets/behavior_board.dart';

class SessionPage extends StatefulWidget {
  final Visit? visit;
  final Client? client;

  const SessionPage({
    super.key,
    this.visit,
    this.client,
  });

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isEnding = false;
  bool _isGeneratingNotes = false;
  bool _showNotes = false;
  final TextEditingController _noteController = TextEditingController();
  final Set<String> _savedAssignments = {}; // Track which assignments have been saved

  @override
  void initState() {
    super.initState();
    if (widget.visit != null) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (widget.visit == null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = DateTime.now().difference(widget.visit!.startTs);
      });
    });
  }

  /// Generate clinical notes from session data
  Future<void> _generateNotes() async {
    if (widget.visit == null || widget.client == null || _isGeneratingNotes) return;

    setState(() {
      _isGeneratingNotes = true;
    });

    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      
      // Fetch fresh session data from FileMaker
      print('🔄 Fetching fresh session data from FileMaker...');
      final sessionRecords = await fileMakerService.getSessionRecordsForVisit(widget.visit!.id);
      print('✅ Fetched ${sessionRecords.length} session records from FileMaker');
      
      // Get program assignments
      final assignments = await fileMakerService.getProgramAssignments(widget.client!.id);

      // Convert to SessionData
      final sessionData = NoteDraftingService.convertSessionRecordsToSessionData(
        visit: widget.visit!,
        client: widget.client!,
        sessionRecords: sessionRecords,
        assignments: assignments,
        providerName: 'Jane Doe, BCBA', // You can get this from staff data
        npi: 'ATYPICAL', // You can get this from staff data
      );

      print('🔄 Sending session data to LLM for note generation...');
      print('📊 Session data summary:');
      print('  - Visit ID: ${widget.visit!.id}');
      print('  - Client: ${widget.client!.name}');
      print('  - Session Records: ${sessionRecords.length}');
      print('  - Assignments: ${assignments.length}');

      // Generate note
      final noteDraft = await NoteDraftingService.generateNoteDraft(
        session: sessionData,
        ragContext: 'Use SOAP tone; focus on measurable outcomes and data-driven observations.',
      );

      // Save note to FileMaker
      await _saveNoteToFileMaker(noteDraft);

      setState(() {
        _noteController.text = noteDraft;
        _showNotes = true;
        _isGeneratingNotes = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clinical note generated! Please review and submit.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Show review dialog instead of automatically ending
        await _showNoteReviewDialog(noteDraft);
      }

    } catch (e) {
      setState(() {
        _isGeneratingNotes = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Save note to FileMaker in the notes field
  Future<void> _saveNoteToFileMaker(String note) async {
    if (widget.visit == null) return;

    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      
      // Try to save to visit first, if that fails, save to session record
      try {
        await fileMakerService.updateVisitNotes(widget.visit!.id, note);
        print('✅ Note saved to visit record for visit: ${widget.visit!.id}');
      } catch (e) {
        print('⚠️ Failed to save to visit, trying session record: $e');
        
        // Fallback: Save to the most recent session record
        final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
        final sessionRecords = sessionProvider.sessionRecords;
        
        if (sessionRecords.isNotEmpty) {
          // Get the most recent session record
          final latestRecord = sessionRecords.last;
          
          // Update the session record with the note
          final updatedRecord = latestRecord.copyWith(notes: note);
          await fileMakerService.updateSessionRecord(updatedRecord);
          
          print('✅ Note saved to session record: ${latestRecord.id}');
        } else {
          throw Exception('No session records found to save note to');
        }
      }
    } catch (e) {
      print('❌ Error saving note to FileMaker: $e');
      // Don't throw error here, just log it
    }
  }

  /// Save the edited note
  Future<void> _saveEditedNote() async {
    final editedNote = _noteController.text.trim();
    if (editedNote.isEmpty) return;

    print('💾 Attempting to save note: ${editedNote.substring(0, 50)}...');

    try {
      await _saveNoteToFileMaker(editedNote);
      
      setState(() {
        // Note updated successfully
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error in _saveEditedNote: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  /// Generate sessions for a specific program
  Future<void> _generateProgramSessions(
    FileMakerService fileMakerService,
    String clientId,
    ProgramAssignment program,
    int programNumber,
    int sessionCount,
  ) async {
    print('📊 Generating $sessionCount sessions for PROGRAM $programNumber');
    print('🎯 PROGRAM $programNumber:');
    print('   - ID: ${program.id}');
    print('   - Name: ${program.displayName}');
    print('   - Phase: ${program.phase}');
    print('   - Data Type: ${program.dataType}');
    
    for (int session = 1; session <= sessionCount; session++) {
      try {
        print('\n📝 Processing session $session for PROGRAM $programNumber');
        print('   - Program: ${program.displayName}');
        print('   - Assignment ID: ${program.id}');
        
        // Create realistic trial data with progression over 15 sessions
        final trialData = _createMockTrialDataForProgram(session, sessionCount, program.dataType ?? 'percentCorrect');
        
        // Create realistic program start/end times
        final programStartTime = DateTime.now().subtract(Duration(days: sessionCount - session));
        final programEndTime = programStartTime.add(Duration(minutes: 10 + (session * 2)));
        
        // Add program times to the payload
        final payloadWithTimes = Map<String, dynamic>.from(trialData);
        payloadWithTimes['programStartTime'] = programStartTime.toIso8601String();
        payloadWithTimes['programEndTime'] = programEndTime.toIso8601String();
        payloadWithTimes['program_start_time'] = programStartTime.toIso8601String();
        payloadWithTimes['program_end_time'] = programEndTime.toIso8601String();
        
        // Get the actual logged-in staff ID
        final currentStaffId = fileMakerService.currentStaffId ?? 'unknown-staff';
        
        // Determine the realistic phase based on session number
        String realisticPhase;
        if (session <= 3) {
          realisticPhase = 'baseline';
        } else if (session <= 8) {
          realisticPhase = 'intervention';
        } else {
          realisticPhase = 'maintenance';
        }
        
        // Create session record
        final sessionRecord = SessionRecord(
          id: 'session-program$programNumber-$session-${DateTime.now().millisecondsSinceEpoch}',
          visitId: 'mock-visit-program$programNumber-$session-${program.id}',
          clientId: clientId,
          assignmentId: program.id ?? '',
          startedAt: programStartTime,
          updatedAt: DateTime.now(),
          payload: payloadWithTimes,
          staffId: currentStaffId,
          interventionPhase: realisticPhase, // Use calculated phase, not program phase
          notes: 'Generated $realisticPhase session $session for program $programNumber',
          programStartTime: programStartTime,
          programEndTime: programEndTime,
        );
        
        print('🔍 Creating session record:');
        print('   - Assignment ID: ${program.id}');
        print('   - Program name: ${program.displayName}');
        print('   - Staff ID: $currentStaffId');
        print('   - Phase: $realisticPhase (session $session)');
        print('   - Accuracy: ${trialData['percent']}%');
        print('   - Hits: ${trialData['hits']}/${trialData['total']}');
        
        // Save to FileMaker
        await fileMakerService.upsertSessionRecord(sessionRecord);
        print('✅ Saved session $session for PROGRAM $programNumber: ${program.displayName}');
        
      } catch (e) {
        print('❌ Error saving session $session for PROGRAM $programNumber: $e');
        // Continue with other sessions even if one fails
      }
    }
  }

  /// Generate trial data for a specific phase
  Future<void> _generatePhaseData(
    FileMakerService fileMakerService,
    String clientId,
    List<ProgramAssignment> assignments,
    String phase,
    int sessionCount,
  ) async {
    print('📊 Generating $phase data: $sessionCount sessions');
    print('📋 Available programs: ${assignments.length}');
    
    // Log details for first and second programs
    if (assignments.isNotEmpty) {
      print('🎯 FIRST PROGRAM:');
      print('   - ID: ${assignments.first.id}');
      print('   - Name: ${assignments.first.displayName}');
      print('   - Phase: ${assignments.first.phase}');
      print('   - Data Type: ${assignments.first.dataType}');
    }
    
    if (assignments.length > 1) {
      print('🎯 SECOND PROGRAM:');
      print('   - ID: ${assignments[1].id}');
      print('   - Name: ${assignments[1].displayName}');
      print('   - Phase: ${assignments[1].phase}');
      print('   - Data Type: ${assignments[1].dataType}');
    }
    
    for (int session = 1; session <= sessionCount; session++) {
      for (int programIndex = 0; programIndex < assignments.length; programIndex++) {
        final assignment = assignments[programIndex];
        final isFirstProgram = programIndex == 0;
        final isSecondProgram = programIndex == 1;
        
        try {
          print('\n📝 Processing $phase session $session for ${isFirstProgram ? 'FIRST' : isSecondProgram ? 'SECOND' : 'PROGRAM ${programIndex + 1}'} program');
          print('   - Program: ${assignment.displayName}');
          print('   - Assignment ID: ${assignment.id}');
          
          // Create mock trial data based on phase - using same structure as Load Demo Data
          final trialData = _createMockTrialData(phase, session, sessionCount);
          
          // Create realistic program start/end times
          final programStartTime = DateTime.now().subtract(Duration(days: sessionCount - session));
          final programEndTime = programStartTime.add(Duration(minutes: 10 + (session * 2)));
          
          // Add program times to the payload as shown in your example
          final payloadWithTimes = Map<String, dynamic>.from(trialData);
          payloadWithTimes['programStartTime'] = programStartTime.toIso8601String();
          payloadWithTimes['programEndTime'] = programEndTime.toIso8601String();
          payloadWithTimes['program_start_time'] = programStartTime.toIso8601String();
          payloadWithTimes['program_end_time'] = programEndTime.toIso8601String();
          
          // Get the actual logged-in staff ID
          final currentStaffId = fileMakerService.currentStaffId ?? 'unknown-staff';
          
          // Create session record using the same pattern as Load Demo Data
          final sessionRecord = SessionRecord(
            id: 'session-$phase-$session-${DateTime.now().millisecondsSinceEpoch}',
            visitId: 'mock-visit-$phase-$session-${assignment.id}',
            clientId: clientId,
            assignmentId: assignment.id ?? '', // Use the PrimaryKey from program assignment
            startedAt: programStartTime,
            updatedAt: DateTime.now(),
            payload: payloadWithTimes,
            staffId: currentStaffId, // Use actual logged-in staff ID
            interventionPhase: phase,
            notes: 'Generated $phase data for session $session',
            programStartTime: programStartTime,
            programEndTime: programEndTime,
          );
          
          print('🔍 Creating session record:');
          print('   - Assignment ID: ${assignment.id}');
          print('   - Program name: ${assignment.displayName}');
          print('   - Staff ID: $currentStaffId');
          print('   - Accuracy: ${trialData['percent']}%');
          print('   - Hits: ${trialData['hits']}/${trialData['total']}');
          
          // Save to FileMaker using the same method as Load Demo Data
          await fileMakerService.upsertSessionRecord(sessionRecord);
          print('✅ Saved $phase session $session for program: ${assignment.displayName}');
          
        } catch (e) {
          print('❌ Error saving $phase session $session for ${assignment.displayName}: $e');
          // Continue with other sessions even if one fails
        }
      }
    }
  }

  /// Create mock trial data for a program with realistic progression over 15 sessions
  Map<String, dynamic> _createMockTrialDataForProgram(int session, int totalSessions, String dataType) {
    print('🔍 Creating mock data for dataType: $dataType');
    // Determine data type based on program or default to percentCorrect
    switch (dataType.toLowerCase()) {
      case 'frequency':
        return _createFrequencyData(session, totalSessions);
      case 'duration':
        print('✅ Processing DURATION data type - creating duration data');
        return _createDurationData(session, totalSessions);
      case 'rate':
        return _createRateData(session, totalSessions);
      case 'taskanalysis':
        return _createTaskAnalysisData(session, totalSessions);
      case 'timesampling':
        return _createTimeSamplingData(session, totalSessions);
      case 'ratingscales':
        return _createRatingScalesData(session, totalSessions);
      case 'abcdata':
        return _createABCData(session, totalSessions);
      default:
        return _createPercentCorrectData(session, totalSessions);
    }
  }

  /// Create percent correct data (existing logic)
  Map<String, dynamic> _createPercentCorrectData(int session, int totalSessions) {
    // Create realistic progression: start low, improve over time, maintain high performance
    int finalAccuracy;
    
    if (session <= 3) {
      // First 3 sessions: baseline phase (20-40%)
      finalAccuracy = 20 + (session * 5) + (session % 2 == 0 ? 5 : 0);
      finalAccuracy = finalAccuracy.clamp(20, 40);
    } else if (session <= 8) {
      // Sessions 4-8: intervention phase (50-85%)
      finalAccuracy = 50 + ((session - 3) * 7);
      finalAccuracy = finalAccuracy.clamp(50, 85);
    } else {
      // Sessions 9-15: maintenance phase (80-95%)
      finalAccuracy = 80 + ((session - 8) * 2) + (session % 3 == 0 ? 5 : 0);
      finalAccuracy = finalAccuracy.clamp(80, 95);
    }
    
    // Calculate hits and misses based on accuracy
    final total = 10;
    final hits = ((finalAccuracy / 100) * total).round();
    final misses = total - hits;
    final noResponse = session % 5 == 0 ? 1 : 0; // Occasional no response
    
    // Generate realistic prompt counts based on performance
    final promptCounts = <String, int>{};
    
    if (finalAccuracy >= 80) {
      // High performance: mostly independent
      promptCounts['Ind'] = hits;
      promptCounts['G'] = 0;
      promptCounts['VS'] = 0;
    } else if (finalAccuracy >= 60) {
      // Medium performance: some guidance needed
      promptCounts['Ind'] = (hits * 0.7).round();
      promptCounts['G'] = hits - promptCounts['Ind']!;
      promptCounts['VS'] = 0;
    } else {
      // Low performance: more prompting needed
      promptCounts['Ind'] = (hits * 0.4).round();
      promptCounts['G'] = (hits * 0.4).round();
      promptCounts['VS'] = hits - promptCounts['Ind']! - promptCounts['G']!;
    }
    
    // Ensure we don't exceed hits
    final totalPrompts = promptCounts['Ind']! + promptCounts['G']! + promptCounts['VS']!;
    if (totalPrompts > hits) {
      final excess = totalPrompts - hits;
      if (promptCounts['VS']! >= excess) {
        promptCounts['VS'] = promptCounts['VS']! - excess;
      } else if (promptCounts['G']! >= excess) {
        promptCounts['G'] = promptCounts['G']! - excess;
      }
    }
    
    // Determine most intrusive prompt used
    String mostIntrusivePrompt = 'Ind';
    if (promptCounts['VS']! > 0) {
      mostIntrusivePrompt = 'VS';
    } else if (promptCounts['G']! > 0) {
      mostIntrusivePrompt = 'G';
    }
    
    final totalPrompted = promptCounts['G']! + promptCounts['VS']!;
    
    return {
      'total': total,
      'hits': hits,
      'misses': misses,
      'percent': finalAccuracy,
      'noResponse': noResponse,
      'promptCounts': promptCounts,
      'mostIntrusivePrompt': mostIntrusivePrompt,
      'totalPrompted': totalPrompted,
      'percentCorrect': finalAccuracy,
      'percentIncorrect': 100 - finalAccuracy,
      'percentNoResponse': (noResponse / total * 100).round(),
      'percentPrompted': (totalPrompted / total * 100).round(),
      'dataType': 'percentCorrect',
      'session': session,
      'totalSessions': totalSessions,
    };
  }

  /// Create frequency data with simple structure: phase, count, notes
  Map<String, dynamic> _createFrequencyData(int session, int totalSessions) {
    // Determine phase
    String phase;
    if (session <= 3) {
      phase = 'baseline';
    } else if (session <= 8) {
      phase = 'intervention';
    } else {
      phase = 'maintenance';
    }
    
    // Generate realistic count based on phase
    int count;
    String notes;
    
    if (phase == 'baseline') {
      // Baseline: higher frequency of behavior (more occurrences)
      count = 8 + (session * 2); // 10-14 occurrences
      notes = 'Baseline data collection - high frequency observed';
    } else if (phase == 'intervention') {
      // Intervention: decreasing frequency as behavior improves
      count = (12 - (session - 3) * 2).clamp(2, 10); // 10, 8, 6, 4, 2
      notes = 'Intervention phase - frequency decreasing';
    } else {
      // Maintenance: low frequency, behavior under control
      count = 1 + (session % 3); // 1-3 occurrences
      notes = 'Maintenance phase - behavior well controlled';
    }
    
    return {
      'phase': phase,
      'count': count,
      'notes': notes,
      'data_type': 'frequency',
      'session': session,
      'totalSessions': totalSessions,
    };
  }

  /// Create duration data with simple structure: phase, duration, notes
  Map<String, dynamic> _createDurationData(int session, int totalSessions) {
    print('🎯 _createDurationData called for session $session');
    // Determine phase
    String phase;
    if (session <= 3) {
      phase = 'baseline';
    } else if (session <= 8) {
      phase = 'intervention';
    } else {
      phase = 'maintenance';
    }
    
    // Generate realistic duration based on phase (in seconds)
    int durationSeconds;
    String notes;
    
    if (phase == 'baseline') {
      // Baseline: shorter duration (behavior not well established)
      durationSeconds = 30 + (session * 10); // 40-60 seconds
      notes = 'Baseline data collection - short duration observed';
    } else if (phase == 'intervention') {
      // Intervention: increasing duration as behavior improves
      durationSeconds = 60 + ((session - 3) * 15); // 60, 75, 90, 105, 120 seconds
      notes = 'Intervention phase - duration increasing';
    } else {
      // Maintenance: longer duration, behavior well established
      durationSeconds = 120 + ((session - 8) * 10); // 120-190 seconds
      notes = 'Maintenance phase - behavior well established';
    }
    
    final durationData = {
      'phase': phase,
      'seconds': durationSeconds,
      'minutes': (durationSeconds / 60).roundToDouble(),
      'notes': notes,
      'data_type': 'duration',
      'session': session,
      'totalSessions': totalSessions,
    };
    
    print('📊 Created duration data: $durationData');
    return durationData;
  }

  /// Create rate data
  Map<String, dynamic> _createRateData(int session, int totalSessions) {
    // Placeholder - implement rate data logic
    return _createPercentCorrectData(session, totalSessions);
  }

  /// Create task analysis data
  Map<String, dynamic> _createTaskAnalysisData(int session, int totalSessions) {
    // Placeholder - implement task analysis data logic
    return _createPercentCorrectData(session, totalSessions);
  }

  /// Create time sampling data
  Map<String, dynamic> _createTimeSamplingData(int session, int totalSessions) {
    // Placeholder - implement time sampling data logic
    return _createPercentCorrectData(session, totalSessions);
  }

  /// Create rating scales data
  Map<String, dynamic> _createRatingScalesData(int session, int totalSessions) {
    // Placeholder - implement rating scales data logic
    return _createPercentCorrectData(session, totalSessions);
  }

  /// Create ABC data
  Map<String, dynamic> _createABCData(int session, int totalSessions) {
    // Placeholder - implement ABC data logic
    return _createPercentCorrectData(session, totalSessions);
  }

  /// Create mock trial data based on phase
  Map<String, dynamic> _createMockTrialData(String phase, int session, int totalSessions) {
    // Create realistic trial data with proper phase progression
    int finalAccuracy;
    
    switch (phase) {
      case 'baseline':
        // Baseline: 20-40% range, showing initial performance
        finalAccuracy = 20 + (session * 5) + (session % 2 == 0 ? 5 : 0);
        finalAccuracy = finalAccuracy.clamp(20, 40);
        break;
        
      case 'intervention':
        // Intervention: Start at 50%, ensure at least 3 sessions over 80%
        if (session <= 2) {
          finalAccuracy = 50 + (session * 10); // Sessions 1-2: 60-70%
        } else if (session <= 4) {
          finalAccuracy = 75 + (session * 5); // Sessions 3-4: 80-95%
        } else {
          finalAccuracy = 85 + (session * 3); // Session 5: 88%
        }
        finalAccuracy = finalAccuracy.clamp(50, 95);
        break;
        
      case 'maintenance':
        // Maintenance: All sessions over 80%, showing mastery
        finalAccuracy = 80 + (session * 3) + (session % 2 == 0 ? 5 : 0);
        finalAccuracy = finalAccuracy.clamp(80, 100);
        break;
        
      default:
        finalAccuracy = 50;
    }
    
    // Calculate hits and misses based on accuracy
    final total = 10;
    final hits = ((finalAccuracy / 100) * total).round();
    final misses = total - hits;
    final noResponse = session % 4 == 0 ? 1 : 0; // Occasional no response
    
    // Generate realistic prompt counts based on performance
    final promptCounts = <String, int>{};
    
    if (finalAccuracy >= 80) {
      // High performance: mostly independent
      promptCounts['Ind'] = hits;
      promptCounts['G'] = 0;
      promptCounts['VS'] = 0;
    } else if (finalAccuracy >= 60) {
      // Medium performance: some guidance needed
      promptCounts['Ind'] = (hits * 0.7).round();
      promptCounts['G'] = hits - promptCounts['Ind']!;
      promptCounts['VS'] = 0;
    } else {
      // Low performance: more prompting needed
      promptCounts['Ind'] = (hits * 0.4).round();
      promptCounts['G'] = (hits * 0.4).round();
      promptCounts['VS'] = hits - promptCounts['Ind']! - promptCounts['G']!;
    }
    
    // Ensure we don't exceed hits
    final totalPrompts = promptCounts['Ind']! + promptCounts['G']! + promptCounts['VS']!;
    if (totalPrompts > hits) {
      final excess = totalPrompts - hits;
      if (promptCounts['VS']! >= excess) {
        promptCounts['VS'] = promptCounts['VS']! - excess;
      } else if (promptCounts['G']! >= excess) {
        promptCounts['G'] = promptCounts['G']! - excess;
      }
    }
    
    // Determine most intrusive prompt used
    String mostIntrusivePrompt = 'Ind';
    if (promptCounts['VS']! > 0) {
      mostIntrusivePrompt = 'VS';
    } else if (promptCounts['G']! > 0) {
      mostIntrusivePrompt = 'G';
    }
    
    final totalPrompted = promptCounts['G']! + promptCounts['VS']!;
    
    return {
      'total': total,
      'hits': hits,
      'misses': misses,
      'percent': finalAccuracy,
      'noResponse': noResponse,
      'promptCounts': promptCounts,
      'mostIntrusivePrompt': mostIntrusivePrompt,
      'totalPrompted': totalPrompted,
      'percentCorrect': finalAccuracy,
      'percentIncorrect': 100 - finalAccuracy,
      'percentNoResponse': (noResponse / total * 100).round(),
      'percentPrompted': (totalPrompted / total * 100).round(),
      'dataType': 'percentCorrect',
      'phase': phase,
      'session': session,
    };
  }


  Future<void> _endVisit({bool skipUnsavedDataCheck = false}) async {
    if (_isEnding || widget.visit == null) return;
    
    setState(() => _isEnding = true);
    
    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      
      if (!skipUnsavedDataCheck) {
        // Check if all assignments are saved
        final activeAssignments = await fileMakerService.getProgramAssignments(widget.client!.id);
        final totalAssignments = activeAssignments.length;
        final savedAssignments = _savedAssignments.length;
        
        if (savedAssignments < totalAssignments) {
          // Not all assignments are saved, show dialog
          await _showSaveUnsavedDataDialog();
        } else {
          // All assignments are saved, proceed to end session
          print('✅ All assignments saved, ending session directly');
        }
      } else {
        // Skip unsaved data check (called from note submission)
        print('✅ Skipping unsaved data check - proceeding to end session');
      }
      
      print('🛑 Ending session for visit: ${widget.visit!.id}');
      final result = await fileMakerService.closeVisit(widget.visit!.id, DateTime.now());
      print('🛑 Session ended, result: $result');
      
      sessionProvider.endVisit();
      
      if (mounted) {
        setState(() => _isEnding = false);
        // Navigate back to client selection page
        Navigator.pushReplacementNamed(context, '/start-visit');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Visit ended successfully. '
              'Billable minutes: ${result['billableMinutes'] ?? 0}, '
              'Units: ${result['billableUnits'] ?? 0}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isEnding = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending visit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _showNoteReviewDialog(String noteDraft) async {
    final TextEditingController editController = TextEditingController(text: noteDraft);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Review & Edit Clinical Notes'),
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: Column(
                  children: [
                    const Text(
                      'You can edit the generated notes below:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TextField(
                        controller: editController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Edit your clinical notes here...',
                          contentPadding: EdgeInsets.all(12),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Submit & End Session'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      // User confirmed, save edited note and end session
      final editedNote = editController.text.trim();
      await _saveNoteToFileMaker(editedNote);
      await _endVisit(skipUnsavedDataCheck: true);
    }
  }

  Future<void> _showEndSessionDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Generate & Edit Notes'),
          content: const Text(
            'Generate clinical notes for this session? '
            'You will be able to review and edit the notes before submitting and ending the session.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Generate Notes'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // User confirmed, generate notes (which will handle the end session flow)
      await _generateNotes();
    }
  }

  Future<void> _showSaveUnsavedDataDialog() async {
    // Get all active assignments
    final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
    final activeAssignments = await fileMakerService.getProgramAssignments(widget.client!.id);
    final totalAssignments = activeAssignments.length;
    final savedAssignments = _savedAssignments.length;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Unsaved Data'),
          content: Text(
            'You have $savedAssignments of $totalAssignments programs saved.\n\nDo you have any unsaved program data that you would like to save before ending the session?\n\nIf you choose "Yes, Save Data", please use the "Save Data" button on each program card to save your data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No, End Session'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes, Save Data'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // User wants to save data, show instructions and don't end session yet
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please save your program data using the "Save Data" button on each program card, then try ending the session again.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
      
      // Don't end the session yet, let user save data manually
      setState(() => _isEnding = false);
      return;
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
        await _showEndSessionDialog();
        return false; // Prevent default back navigation
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.client!.name),
        leading: IconButton(
          icon: const Icon(Icons.notes),
          onPressed: () => _showEndSessionDialog(),
        ),
        actions: [
          Text(
            _formatDuration(_elapsed),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          // Logout Dropdown
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.account_circle),
            ),
          ),
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, sessionProvider, child) {
          final activeAssignments = sessionProvider.activeAssignments;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Generated Notes Display
                if (_showNotes) ...[
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.edit_note, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'Editable Clinical Note',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              // Save button
                              IconButton(
                                onPressed: _saveEditedNote,
                                icon: const Icon(Icons.save, color: Colors.green),
                                tooltip: 'Save Changes',
                              ),
                              // Close button
                              IconButton(
                                onPressed: () => setState(() => _showNotes = false),
                                icon: const Icon(Icons.close),
                                tooltip: 'Hide Note',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: TextField(
                              controller: _noteController,
                              maxLines: null, // Allow multiple lines
                              style: const TextStyle(fontSize: 14, height: 1.5),
                              decoration: const InputDecoration(
                                hintText: 'Edit your clinical note here...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '💡 Tip: You can edit the note above and click save to update it.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Session Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Session Time - First Row
                        Row(
                          children: [
                            const Text(
                              'Session Time:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDuration(_elapsed),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Generate Notes Button - Second Row
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isGeneratingNotes ? null : _generateNotes,
                            icon: _isGeneratingNotes 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: Text(_isGeneratingNotes ? 'Generating Notes...' : 'Generate & Edit Notes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Service: ${widget.visit!.serviceCode}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Program Assignments Section
                const Text(
                  'Program Data Collection',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                if (activeAssignments.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No active program assignments found for this client.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...activeAssignments.map((assignment) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ProgramCard(
                      assignment: assignment,
                      visitId: widget.visit!.id,
                      clientId: widget.client!.id,
                      onSave: (payload) async {
                        try {
                          final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
                          
                          // Parse program times from payload if available
                          DateTime? programStartTime;
                          DateTime? programEndTime;
                          if (payload['programStartTime'] != null) {
                            programStartTime = DateTime.parse(payload['programStartTime']);
                          }
                          if (payload['programEndTime'] != null) {
                            programEndTime = DateTime.parse(payload['programEndTime']);
                          }

                          final sessionRecord = SessionRecord(
                            id: '', // Will be set by FileMaker
                            visitId: widget.visit!.id,
                            clientId: widget.client!.id,
                            assignmentId: assignment.id ?? '',
                            startedAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                            payload: payload,
                            staffId: widget.visit!.staffId,
                            interventionPhase: assignment.phase ?? 'baseline',
                            programStartTime: programStartTime,
                            programEndTime: programEndTime,
                          );
                          
                          final savedRecord = await fileMakerService.upsertSessionRecord(sessionRecord);
                          sessionProvider.addSessionRecord(savedRecord);
                          
                          // Mark this assignment as saved
                          setState(() {
                            _savedAssignments.add(assignment.id ?? '');
                          });
                          
                          // Check for mastery if this is a reduction program
                          if (assignment.dataType?.contains('reduction') == true || 
                              assignment.dataType?.contains('decrease') == true) {
                            try {
                              if (assignment.id != null) {
                                await fileMakerService.evaluateAssignmentMastery(assignment.id!);
                              }
                            } catch (e) {
                            }
                          }
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Data saved successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error saving data: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      onBehaviorLogged: (log) {
                        sessionProvider.addBehaviorLog(log);
                      },
                    ),
                  )),
                
                const SizedBox(height: 30),
                
                // Behavior Logging Section
                const Text(
                  'Behavior Logging',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                BehaviorBoard(
                  visitId: widget.visit!.id,
                  clientId: widget.client!.id,
                  onBehaviorLogged: (log) {
                    sessionProvider.addBehaviorLog(log);
                  },
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  void _logout() {
    // Clear any stored session data
    // Navigate back to login page
    Navigator.pushReplacementNamed(context, '/');
  }
}
