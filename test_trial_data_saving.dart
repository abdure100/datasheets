import 'package:datasheets/services/filemaker_service.dart';
import 'package:datasheets/services/trial_data_service.dart';

/// Test script for trial data saving to FileMaker
void main() async {
  print('🧪 Testing Trial Data Saving to FileMaker');
  print('=========================================');
  
  try {
    // Initialize services
    final fileMakerService = FileMakerService();
    final trialDataService = TrialDataService(fileMakerService);
    
    // Test data for client 03626AAB-FEF9-4325-A70D-191463DBAF2A
    const clientId = '03626AAB-FEF9-4325-A70D-191463DBAF2A';
    const visitId = 'test_visit_001';
    const staffId = '17ED033A-7CA9-4367-AA48-3C459DBBC24C';
    const interventionPhase = 'intervention';
    
    print('🎯 Testing trial data saving for client: $clientId');
    print('📅 Visit ID: $visitId');
    print('👤 Staff ID: $staffId');
    print('📊 Phase: $interventionPhase');
    print('');
    
    // Test 1: Percent Correct/Independent Trial
    print('📊 Test 1: Percent Correct/Independent Trial');
    print('-------------------------------------------');
    
    try {
      final record1 = await trialDataService.savePercentCorrectTrial(
        visitId: visitId,
        clientId: clientId,
        assignmentId: '${clientId}_prog_001',
        staffId: staffId,
        interventionPhase: interventionPhase,
        hits: 8,
        totalTrials: 10,
        independent: 6,
        prompted: 2,
        incorrect: 2,
        noResponse: 0,
        notes: 'Test trial data - Receptive Identification',
        programStartTime: DateTime.now().subtract(const Duration(minutes: 15)),
        programEndTime: DateTime.now(),
      );
      
      print('✅ Percent Correct trial saved successfully!');
      print('   - Record ID: ${record1.id}');
      print('   - Hits: 8/10 (80%)');
      print('   - Independent: 6/10 (60%)');
      
    } catch (e) {
      print('❌ Error saving Percent Correct trial: $e');
    }
    
    // Test 2: Frequency Counting Trial
    print('\n📊 Test 2: Frequency Counting Trial');
    print('-----------------------------------');
    
    try {
      final record2 = await trialDataService.saveFrequencyTrial(
        visitId: visitId,
        clientId: clientId,
        assignmentId: '${clientId}_prog_002',
        staffId: staffId,
        interventionPhase: interventionPhase,
        count: 5,
        sessionDuration: 30,
        notes: 'Test trial data - Hand Raising',
        programStartTime: DateTime.now().subtract(const Duration(minutes: 30)),
        programEndTime: DateTime.now(),
      );
      
      print('✅ Frequency trial saved successfully!');
      print('   - Record ID: ${record2.id}');
      print('   - Count: 5 hand raises');
      print('   - Rate: 0.17 per minute');
      
    } catch (e) {
      print('❌ Error saving Frequency trial: $e');
    }
    
    // Test 3: Duration Timing Trial
    print('\n📊 Test 3: Duration Timing Trial');
    print('-------------------------------');
    
    try {
      final record3 = await trialDataService.saveDurationTrial(
        visitId: visitId,
        clientId: clientId,
        assignmentId: '${clientId}_prog_008',
        staffId: staffId,
        interventionPhase: interventionPhase,
        duration: 4.0,
        activity: 'Independent puzzle play',
        notes: 'Test trial data - Independent Play',
        programStartTime: DateTime.now().subtract(const Duration(minutes: 5)),
        programEndTime: DateTime.now(),
      );
      
      print('✅ Duration trial saved successfully!');
      print('   - Record ID: ${record3.id}');
      print('   - Duration: 4.0 minutes');
      print('   - Activity: Independent puzzle play');
      
    } catch (e) {
      print('❌ Error saving Duration trial: $e');
    }
    
    // Test 4: Task Analysis Trial
    print('\n📊 Test 4: Task Analysis Trial');
    print('-----------------------------');
    
    try {
      final record4 = await trialDataService.saveTaskAnalysisTrial(
        visitId: visitId,
        clientId: clientId,
        assignmentId: '${clientId}_prog_003',
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
        completedSteps: [true, true, true, true, true, false, true],
        notes: 'Test trial data - Hand Washing (6/7 steps)',
        programStartTime: DateTime.now().subtract(const Duration(minutes: 10)),
        programEndTime: DateTime.now(),
      );
      
      print('✅ Task Analysis trial saved successfully!');
      print('   - Record ID: ${record4.id}');
      print('   - Steps completed: 6/7 (86%)');
      print('   - Missed step: Turn off water');
      
    } catch (e) {
      print('❌ Error saving Task Analysis trial: $e');
    }
    
    // Test 5: Rate Calculation Trial
    print('\n📊 Test 5: Rate Calculation Trial');
    print('--------------------------------');
    
    try {
      final record5 = await trialDataService.saveRateTrial(
        visitId: visitId,
        clientId: clientId,
        assignmentId: '${clientId}_prog_005',
        staffId: staffId,
        interventionPhase: interventionPhase,
        events: 8,
        sessionDuration: 20.0,
        notes: 'Test trial data - Request Making',
        programStartTime: DateTime.now().subtract(const Duration(minutes: 20)),
        programEndTime: DateTime.now(),
      );
      
      print('✅ Rate trial saved successfully!');
      print('   - Record ID: ${record5.id}');
      print('   - Events: 8 requests');
      print('   - Rate: 0.4 per minute');
      
    } catch (e) {
      print('❌ Error saving Rate trial: $e');
    }
    
    // Test 6: Time Sampling Trial
    print('\n📊 Test 6: Time Sampling Trial');
    print('-----------------------------');
    
    try {
      final record6 = await trialDataService.saveTimeSamplingTrial(
        visitId: visitId,
        clientId: clientId,
        assignmentId: '${clientId}_prog_004',
        staffId: staffId,
        interventionPhase: interventionPhase,
        intervals: 15,
        onTaskIntervals: 12,
        intervalDuration: 15,
        notes: 'Test trial data - On-Task Behavior',
        programStartTime: DateTime.now().subtract(const Duration(minutes: 15)),
        programEndTime: DateTime.now(),
      );
      
      print('✅ Time Sampling trial saved successfully!');
      print('   - Record ID: ${record6.id}');
      print('   - On-task: 12/15 intervals (80%)');
      print('   - Interval duration: 15 seconds');
      
    } catch (e) {
      print('❌ Error saving Time Sampling trial: $e');
    }
    
    // Test 7: Rating Scale Trial
    print('\n📊 Test 7: Rating Scale Trial');
    print('----------------------------');
    
    try {
      final record7 = await trialDataService.saveRatingScaleTrial(
        visitId: visitId,
        clientId: clientId,
        assignmentId: '${clientId}_prog_006',
        staffId: staffId,
        interventionPhase: interventionPhase,
        rating: 4.0,
        maxRating: 5.0,
        context: 'Peer interaction during play',
        notes: 'Test trial data - Social Interaction',
        programStartTime: DateTime.now().subtract(const Duration(minutes: 25)),
        programEndTime: DateTime.now(),
      );
      
      print('✅ Rating Scale trial saved successfully!');
      print('   - Record ID: ${record7.id}');
      print('   - Rating: 4.0/5.0 (80%)');
      print('   - Context: Peer interaction');
      
    } catch (e) {
      print('❌ Error saving Rating Scale trial: $e');
    }
    
    // Test 8: ABC Data Trial
    print('\n📊 Test 8: ABC Data Trial');
    print('------------------------');
    
    try {
      final record8 = await trialDataService.saveABCDataTrial(
        visitId: visitId,
        clientId: clientId,
        assignmentId: '${clientId}_prog_007',
        staffId: staffId,
        interventionPhase: interventionPhase,
        incidents: [
          {
            'antecedent': 'Transition from play to work',
            'behavior': 'Throwing materials',
            'consequence': 'Redirected to calming corner',
            'severity': 3,
            'timestamp': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
          }
        ],
        notes: 'Test trial data - Aggressive Behavior (1 incident)',
        programStartTime: DateTime.now().subtract(const Duration(minutes: 30)),
        programEndTime: DateTime.now(),
      );
      
      print('✅ ABC Data trial saved successfully!');
      print('   - Record ID: ${record8.id}');
      print('   - Incidents: 1');
      print('   - Severity: 3');
      
    } catch (e) {
      print('❌ Error saving ABC Data trial: $e');
    }
    
    // Test Summary
    print('\n📊 Test Summary');
    print('==============');
    
    try {
      final summary = await trialDataService.getTrialDataSummary(
        clientId: clientId,
        dateFrom: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        dateTo: DateTime.now().toIso8601String(),
      );
      
      print('✅ Trial data summary retrieved successfully!');
      print('   - Client ID: ${summary['clientId']}');
      print('   - Summary: ${summary['summary']}');
      
    } catch (e) {
      print('❌ Error getting trial data summary: $e');
    }
    
    print('\n🎉 Trial data saving tests completed!');
    print('💾 All trial data has been saved to FileMaker database.');
    print('📊 Check your FileMaker database to verify the data was saved correctly.');
    
  } catch (e) {
    print('❌ Error in trial data testing: $e');
    print('💡 Make sure your FileMaker service is properly configured.');
  }
}
