import 'package:datasheets/services/note_drafting_service.dart';
import 'package:datasheets/services/trial_data_service.dart';
import 'package:datasheets/services/filemaker_service.dart';
import 'package:datasheets/models/visit.dart';
import 'package:datasheets/models/client.dart';
import 'package:datasheets/models/program_assignment.dart';
import 'package:datasheets/models/session_record.dart';

/// Example of using the note drafting service with trial data
void main() async {
  print('📝 Note Drafting Service Example');
  print('================================');
  
  try {
    // Initialize services
    final fileMakerService = FileMakerService();
    final trialDataService = TrialDataService(fileMakerService);
    
    // Example session data
    const clientId = '03626AAB-FEF9-4325-A70D-191463DBAF2A';
    const visitId = 'visit_001';
    const staffId = '17ED033A-7CA9-4367-AA48-3C459DBBC24C';
    
    // Create example visit
    final visit = Visit(
      id: visitId,
      clientId: clientId,
      staffId: staffId,
      serviceCode: 'Intervention (97153)',
      startTs: DateTime.now().subtract(const Duration(hours: 1)),
      endTs: DateTime.now(),
      status: 'Submitted',
      notes: 'Session completed successfully',
      clientName: 'Alex Johnson',
      staffName: 'Jane Doe, BCBA',
      appointmentDate: DateTime.now().toIso8601String().split('T')[0],
      timeIn: '09:00',
    );
    
    // Create example client
    final client = Client(
      id: clientId,
      name: 'Alex Johnson',
      dateOfBirth: '2015-03-15',
    );
    
    // Create example program assignments
    final assignments = [
      ProgramAssignment(
        id: '${clientId}_prog_001',
        clientId: clientId,
        name: 'Receptive Identification of Common Objects',
        dataType: 'percentCorrect',
        status: 'active',
        phase: 'intervention',
      ),
      ProgramAssignment(
        id: '${clientId}_prog_002',
        clientId: clientId,
        name: 'Hand Raising for Attention',
        dataType: 'frequency',
        status: 'active',
        phase: 'intervention',
      ),
      ProgramAssignment(
        id: '${clientId}_prog_003',
        clientId: clientId,
        name: 'Independent Hand Washing',
        dataType: 'taskAnalysis',
        status: 'active',
        phase: 'intervention',
      ),
    ];
    
    // Create example session records
    final sessionRecords = <SessionRecord>[];
    
    // Add percent correct trial data
    sessionRecords.add(SessionRecord(
      id: 'record_001',
      visitId: visitId,
      clientId: clientId,
      assignmentId: '${clientId}_prog_001',
      startedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      payload: {
        'dataType': 'percentCorrect',
        'hits': 8,
        'totalTrials': 10,
        'independent': 6,
        'prompted': 2,
        'incorrect': 2,
        'noResponse': 0,
        'percentage': 80.0,
        'independentPercentage': 60.0,
        'timestamp': DateTime.now().toIso8601String(),
        'sessionEnded': true,
      },
      staffId: staffId,
      interventionPhase: 'intervention',
      programStartTime: DateTime.now().subtract(const Duration(minutes: 45)),
      programEndTime: DateTime.now().subtract(const Duration(minutes: 30)),
    ));
    
    // Add frequency trial data
    sessionRecords.add(SessionRecord(
      id: 'record_002',
      visitId: visitId,
      clientId: clientId,
      assignmentId: '${clientId}_prog_002',
      startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      payload: {
        'dataType': 'frequency',
        'count': 5,
        'sessionDuration': 30,
        'rate': 0.17,
        'timestamp': DateTime.now().toIso8601String(),
        'sessionEnded': true,
      },
      staffId: staffId,
      interventionPhase: 'intervention',
      programStartTime: DateTime.now().subtract(const Duration(minutes: 30)),
      programEndTime: DateTime.now().subtract(const Duration(minutes: 15)),
    ));
    
    // Add task analysis trial data
    sessionRecords.add(SessionRecord(
      id: 'record_003',
      visitId: visitId,
      clientId: clientId,
      assignmentId: '${clientId}_prog_003',
      startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      updatedAt: DateTime.now(),
      payload: {
        'dataType': 'taskAnalysis',
        'steps': [
          'Turn on water',
          'Wet hands',
          'Apply soap',
          'Scrub hands',
          'Rinse hands',
          'Turn off water',
          'Dry hands'
        ],
        'completedSteps': [true, true, true, true, true, false, true],
        'completedCount': 6,
        'totalSteps': 7,
        'percentage': 85.7,
        'timestamp': DateTime.now().toIso8601String(),
        'sessionEnded': true,
      },
      staffId: staffId,
      interventionPhase: 'intervention',
      programStartTime: DateTime.now().subtract(const Duration(minutes: 15)),
      programEndTime: DateTime.now(),
    ));
    
    // Convert session records to SessionData
    print('🔄 Converting session records to SessionData...');
    final sessionData = NoteDraftingService.convertSessionRecordsToSessionData(
      visit: visit,
      client: client,
      sessionRecords: sessionRecords,
      assignments: assignments,
      providerName: 'Jane Doe, BCBA',
      npi: 'ATYPICAL',
    );
    
    print('✅ SessionData created:');
    print('   - Provider: ${sessionData.providerName}');
    print('   - Client: ${sessionData.clientName}');
    print('   - Date: ${sessionData.date}');
    print('   - Duration: ${sessionData.durationMinutes} minutes');
    print('   - Goals: ${sessionData.goalsList.join(', ')}');
    print('   - Data Summary: ${sessionData.dataSummary}');
    print('   - Behaviors: ${sessionData.behaviors}');
    print('   - Interventions: ${sessionData.interventions}');
    print('   - Plan: ${sessionData.plan}');
    
    // Generate note draft
    print('\n📝 Generating note draft...');
    try {
      final noteDraft = await NoteDraftingService.generateNoteDraft(
        session: sessionData,
        ragContext: '''
- Use SOAP tone; avoid speculation.
- Payer requires explicit minutes and CPT/Modifiers alignment.
- Focus on measurable outcomes and data-driven observations.
- Include specific behavioral observations and interventions used.
        ''',
        // apiKey: 'your-api-key-here', // Add your API key if needed
      );
      
      print('✅ Note draft generated:');
      print('========================');
      print(noteDraft);
      print('========================');
      
    } catch (e) {
      print('❌ Error generating note draft: $e');
      print('💡 This might be due to API key or network issues.');
      print('   You can still use the SessionData for manual note creation.');
    }
    
    // Example of using streaming
    print('\n📝 Generating note draft with streaming...');
    try {
      await for (final chunk in NoteDraftingService.generateNoteDraftStream(
        session: sessionData,
        ragContext: 'Use professional, objective tone suitable for payer review.',
        // apiKey: 'your-api-key-here', // Add your API key if needed
      )) {
        print(chunk);
      }
    } catch (e) {
      print('❌ Error generating streaming note draft: $e');
    }
    
    // Example of building messages manually
    print('\n📝 Building chat messages manually...');
    final messages = NoteDraftingService.buildNoteDraftMessages(
      session: sessionData,
      ragContext: 'Use SOAP format with measurable outcomes.',
    );
    
    print('✅ Chat messages built:');
    for (final message in messages) {
      print('   Role: ${message['role']}');
      print('   Content: ${message['content']?.substring(0, 100)}...');
    }
    
    print('\n🎉 Note drafting example completed!');
    print('💡 You can now integrate this into your app for automatic note generation.');
    
  } catch (e) {
    print('❌ Error in note drafting example: $e');
  }
}

/// Example of using the service with real trial data
Future<void> exampleWithRealTrialData() async {
  print('\n🎯 Example with Real Trial Data');
  print('===============================');
  
  try {
    // Initialize services
    final fileMakerService = FileMakerService();
    final trialDataService = TrialDataService(fileMakerService);
    
    // Create a complete session with trial data
    const clientId = '03626AAB-FEF9-4325-A70D-191463DBAF2A';
    const visitId = 'real_session_001';
    const staffId = '17ED033A-7CA9-4367-AA48-3C459DBBC24C';
    
    // Create visit
    final visit = Visit(
      id: visitId,
      clientId: clientId,
      staffId: staffId,
      serviceCode: 'Intervention (97153)',
      startTs: DateTime.now().subtract(const Duration(hours: 1)),
      endTs: DateTime.now(),
      status: 'Submitted',
      notes: 'Real session with comprehensive data collection',
      clientName: 'Alex Johnson',
      staffName: 'Jane Doe, BCBA',
      appointmentDate: DateTime.now().toIso8601String().split('T')[0],
      timeIn: '09:00',
    );
    
    // Create client
    final client = Client(
      id: clientId,
      name: 'Alex Johnson',
      dateOfBirth: '2015-03-15',
    );
    
    // Create assignments
    final assignments = [
      ProgramAssignment(
        id: '${clientId}_prog_001',
        clientId: clientId,
        name: 'Receptive Identification of Common Objects',
        dataType: 'percentCorrect',
        status: 'active',
        phase: 'intervention',
      ),
      ProgramAssignment(
        id: '${clientId}_prog_002',
        clientId: clientId,
        name: 'Hand Raising for Attention',
        dataType: 'frequency',
        status: 'active',
        phase: 'intervention',
      ),
    ];
    
    // Save trial data
    print('💾 Saving trial data...');
    
    final record1 = await trialDataService.savePercentCorrectTrial(
      visitId: visitId,
      clientId: clientId,
      assignmentId: '${clientId}_prog_001',
      staffId: staffId,
      interventionPhase: 'intervention',
      hits: 8,
      totalTrials: 10,
      independent: 6,
      prompted: 2,
      incorrect: 2,
      noResponse: 0,
      notes: 'Client showed good progress on receptive identification',
      programStartTime: DateTime.now().subtract(const Duration(minutes: 45)),
      programEndTime: DateTime.now().subtract(const Duration(minutes: 30)),
    );
    
    final record2 = await trialDataService.saveFrequencyTrial(
      visitId: visitId,
      clientId: clientId,
      assignmentId: '${clientId}_prog_002',
      staffId: staffId,
      interventionPhase: 'intervention',
      count: 5,
      sessionDuration: 30,
      notes: 'Client raised hand 5 times during session',
      programStartTime: DateTime.now().subtract(const Duration(minutes: 30)),
      programEndTime: DateTime.now(),
    );
    
    // Convert to SessionData
    final sessionData = NoteDraftingService.convertSessionRecordsToSessionData(
      visit: visit,
      client: client,
      sessionRecords: [record1, record2],
      assignments: assignments,
      providerName: 'Jane Doe, BCBA',
      npi: 'ATYPICAL',
    );
    
    print('✅ SessionData created from real trial data:');
    print('   - Data Summary: ${sessionData.dataSummary}');
    print('   - Behaviors: ${sessionData.behaviors}');
    print('   - Interventions: ${sessionData.interventions}');
    print('   - Plan: ${sessionData.plan}');
    
    // Generate note draft
    try {
      final noteDraft = await NoteDraftingService.generateNoteDraft(
        session: sessionData,
        ragContext: 'Use SOAP format with measurable outcomes and data-driven observations.',
      );
      
      print('\n📝 Generated Note Draft:');
      print('========================');
      print(noteDraft);
      print('========================');
      
    } catch (e) {
      print('❌ Error generating note draft: $e');
    }
    
  } catch (e) {
    print('❌ Error in real trial data example: $e');
  }
}
