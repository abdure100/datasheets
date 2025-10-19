import 'package:datasheets/services/filemaker_service.dart';
import 'package:datasheets/services/trial_data_service.dart';

/// Example usage of TrialDataService for saving trial data to FileMaker
void main() async {
  print('🎯 Trial Data Service Example');
  print('============================');
  
  // Initialize services
  final fileMakerService = FileMakerService();
  final trialDataService = TrialDataService(fileMakerService);
  
  // Example data for client 03626AAB-FEF9-4325-A70D-191463DBAF2A
  const clientId = '03626AAB-FEF9-4325-A70D-191463DBAF2A';
  const visitId = 'visit_001';
  const staffId = '17ED033A-7CA9-4367-AA48-3C459DBBC24C';
  const interventionPhase = 'intervention';
  
  try {
    // Example 1: Save Percent Correct/Independent Trial Data
    print('\n📊 Example 1: Percent Correct/Independent Trial');
    print('-----------------------------------------------');
    
    final percentCorrectRecord = await trialDataService.savePercentCorrectTrial(
      visitId: visitId,
      clientId: clientId,
      assignmentId: '${clientId}_prog_001', // Receptive Identification
      staffId: staffId,
      interventionPhase: interventionPhase,
      hits: 8,
      totalTrials: 10,
      independent: 6,
      prompted: 2,
      incorrect: 2,
      noResponse: 0,
      notes: 'Client showed good progress on receptive identification',
      programStartTime: DateTime.now().subtract(const Duration(minutes: 15)),
      programEndTime: DateTime.now(),
    );
    
    print('✅ Percent Correct trial saved: ${percentCorrectRecord.id}');
    print('   - Hits: 8/10 (80%)');
    print('   - Independent: 6/10 (60%)');
    
    // Example 2: Save Frequency Counting Trial Data
    print('\n📊 Example 2: Frequency Counting Trial');
    print('--------------------------------------');
    
    final frequencyRecord = await trialDataService.saveFrequencyTrial(
      visitId: visitId,
      clientId: clientId,
      assignmentId: '${clientId}_prog_002', // Hand Raising
      staffId: staffId,
      interventionPhase: interventionPhase,
      count: 4,
      sessionDuration: 30, // 30 minutes
      notes: 'Client raised hand 4 times during 30-minute session',
      programStartTime: DateTime.now().subtract(const Duration(minutes: 30)),
      programEndTime: DateTime.now(),
    );
    
    print('✅ Frequency trial saved: ${frequencyRecord.id}');
    print('   - Count: 4 hand raises');
    print('   - Rate: 0.13 per minute');
    
    // Example 3: Save Duration Timing Trial Data
    print('\n📊 Example 3: Duration Timing Trial');
    print('------------------------------------');
    
    final durationRecord = await trialDataService.saveDurationTrial(
      visitId: visitId,
      clientId: clientId,
      assignmentId: '${clientId}_prog_008', // Independent Play
      staffId: staffId,
      interventionPhase: interventionPhase,
      duration: 3.5, // 3.5 minutes
      activity: 'Puzzle play',
      notes: 'Client engaged in independent puzzle play for 3.5 minutes',
      programStartTime: DateTime.now().subtract(const Duration(minutes: 5)),
      programEndTime: DateTime.now(),
    );
    
    print('✅ Duration trial saved: ${durationRecord.id}');
    print('   - Duration: 3.5 minutes');
    print('   - Activity: Puzzle play');
    
    // Example 4: Save Rate Calculation Trial Data
    print('\n📊 Example 4: Rate Calculation Trial');
    print('-------------------------------------');
    
    final rateRecord = await trialDataService.saveRateTrial(
      visitId: visitId,
      clientId: clientId,
      assignmentId: '${clientId}_prog_005', // Appropriate Request Making
      staffId: staffId,
      interventionPhase: interventionPhase,
      events: 12,
      sessionDuration: 20.0, // 20 minutes
      notes: 'Client made 12 appropriate requests during 20-minute session',
      programStartTime: DateTime.now().subtract(const Duration(minutes: 20)),
      programEndTime: DateTime.now(),
    );
    
    print('✅ Rate trial saved: ${rateRecord.id}');
    print('   - Events: 12 requests');
    print('   - Rate: 0.6 per minute');
    
    // Example 5: Save Task Analysis Trial Data
    print('\n📊 Example 5: Task Analysis Trial');
    print('--------------------------------');
    
    final taskAnalysisRecord = await trialDataService.saveTaskAnalysisTrial(
      visitId: visitId,
      clientId: clientId,
      assignmentId: '${clientId}_prog_003', // Hand Washing
      staffId: staffId,
      interventionPhase: interventionPhase,
      steps: [
        'Turn on water',
        'Wet hands',
        'Apply soap',
        'Scrub hands',
        'Rinse hands',
        'Turn off water',
        'Dry hands'
      ],
      completedSteps: [true, true, true, true, true, false, true], // 6/7 steps
      notes: 'Client completed 6 out of 7 hand washing steps independently',
      programStartTime: DateTime.now().subtract(const Duration(minutes: 10)),
      programEndTime: DateTime.now(),
    );
    
    print('✅ Task Analysis trial saved: ${taskAnalysisRecord.id}');
    print('   - Steps completed: 6/7 (86%)');
    print('   - Missed step: Turn off water');
    
    // Example 6: Save Time Sampling Trial Data
    print('\n📊 Example 6: Time Sampling Trial');
    print('--------------------------------');
    
    final timeSamplingRecord = await trialDataService.saveTimeSamplingTrial(
      visitId: visitId,
      clientId: clientId,
      assignmentId: '${clientId}_prog_004', // On-Task Behavior
      staffId: staffId,
      interventionPhase: interventionPhase,
      intervals: 20,
      onTaskIntervals: 16,
      intervalDuration: 15, // 15 seconds
      notes: 'Client was on-task for 16 out of 20 intervals during academic work',
      programStartTime: DateTime.now().subtract(const Duration(minutes: 15)),
      programEndTime: DateTime.now(),
    );
    
    print('✅ Time Sampling trial saved: ${timeSamplingRecord.id}');
    print('   - On-task: 16/20 intervals (80%)');
    print('   - Interval duration: 15 seconds');
    
    // Example 7: Save Rating Scale Trial Data
    print('\n📊 Example 7: Rating Scale Trial');
    print('-------------------------------');
    
    final ratingScaleRecord = await trialDataService.saveRatingScaleTrial(
      visitId: visitId,
      clientId: clientId,
      assignmentId: '${clientId}_prog_006', // Social Interaction Quality
      staffId: staffId,
      interventionPhase: interventionPhase,
      rating: 4.0,
      maxRating: 5.0,
      context: 'Peer interaction during play time',
      notes: 'Client showed very good social interaction with peers',
      programStartTime: DateTime.now().subtract(const Duration(minutes: 25)),
      programEndTime: DateTime.now(),
    );
    
    print('✅ Rating Scale trial saved: ${ratingScaleRecord.id}');
    print('   - Rating: 4.0/5.0 (80%)');
    print('   - Context: Peer interaction');
    
    // Example 8: Save ABC Data Trial Data
    print('\n📊 Example 8: ABC Data Trial');
    print('----------------------------');
    
    final abcDataRecord = await trialDataService.saveABCDataTrial(
      visitId: visitId,
      clientId: clientId,
      assignmentId: '${clientId}_prog_007', // Reduction of Aggressive Behavior
      staffId: staffId,
      interventionPhase: interventionPhase,
      incidents: [
        {
          'antecedent': 'Transition from play to work',
          'behavior': 'Throwing materials',
          'consequence': 'Redirected to calming corner',
          'severity': 3,
          'timestamp': DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
        },
        {
          'antecedent': 'Demand to complete worksheet',
          'behavior': 'Screaming',
          'consequence': 'Offered break, accepted',
          'severity': 2,
          'timestamp': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
        },
      ],
      notes: 'Client had 2 incidents of challenging behavior, both resolved appropriately',
      programStartTime: DateTime.now().subtract(const Duration(minutes: 60)),
      programEndTime: DateTime.now(),
    );
    
    print('✅ ABC Data trial saved: ${abcDataRecord.id}');
    print('   - Incidents: 2');
    print('   - Average severity: 2.5');
    
    // Get trial data summary
    print('\n📊 Trial Data Summary');
    print('====================');
    
    final summary = await trialDataService.getTrialDataSummary(
      clientId: clientId,
      dateFrom: DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
      dateTo: DateTime.now().toIso8601String(),
    );
    
    print('Client ID: ${summary['clientId']}');
    print('Summary: ${summary['summary']}');
    
    print('\n🎉 All trial data examples completed successfully!');
    print('💾 Data has been saved to FileMaker database.');
    
  } catch (e) {
    print('❌ Error in trial data examples: $e');
  }
}

/// Helper function to demonstrate different trial data scenarios
Future<void> demonstrateTrialDataScenarios() async {
  print('\n🎭 Trial Data Scenarios');
  print('=======================');
  
  // Initialize services
  final fileMakerService = FileMakerService();
  final trialDataService = TrialDataService(fileMakerService);
  
  const clientId = '03626AAB-FEF9-4325-A70D-191463DBAF2A';
  const visitId = 'visit_002';
  const staffId = '17ED033A-7CA9-4367-AA48-3C459DBBC24C';
  
  // Scenario 1: Baseline Phase Data
  print('\n📊 Scenario 1: Baseline Phase Data');
  print('----------------------------------');
  
  await trialDataService.savePercentCorrectTrial(
    visitId: visitId,
    clientId: clientId,
    assignmentId: '${clientId}_prog_001',
    staffId: staffId,
    interventionPhase: 'baseline',
    hits: 2,
    totalTrials: 10,
    independent: 0,
    prompted: 2,
    incorrect: 8,
    noResponse: 0,
    notes: 'Baseline: Client showed 20% accuracy with heavy prompting',
  );
  
  print('✅ Baseline data saved (20% accuracy)');
  
  // Scenario 2: Intervention Phase Data
  print('\n📊 Scenario 2: Intervention Phase Data');
  print('-------------------------------------');
  
  await trialDataService.savePercentCorrectTrial(
    visitId: visitId,
    clientId: clientId,
    assignmentId: '${clientId}_prog_001',
    staffId: staffId,
    interventionPhase: 'intervention',
    hits: 7,
    totalTrials: 10,
    independent: 4,
    prompted: 3,
    incorrect: 3,
    noResponse: 0,
    notes: 'Intervention: Client showed 70% accuracy with teaching support',
  );
  
  print('✅ Intervention data saved (70% accuracy)');
  
  // Scenario 3: Maintenance Phase Data
  print('\n📊 Scenario 3: Maintenance Phase Data');
  print('-----------------------------------');
  
  await trialDataService.savePercentCorrectTrial(
    visitId: visitId,
    clientId: clientId,
    assignmentId: '${clientId}_prog_001',
    staffId: staffId,
    interventionPhase: 'maintenance',
    hits: 9,
    totalTrials: 10,
    independent: 8,
    prompted: 1,
    incorrect: 1,
    noResponse: 0,
    notes: 'Maintenance: Client showed 90% accuracy with minimal support',
  );
  
  print('✅ Maintenance data saved (90% accuracy)');
  
  print('\n🎉 Trial data scenarios completed!');
}
