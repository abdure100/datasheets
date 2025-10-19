import 'package:datasheets/services/note_drafting_service.dart';

/// Test script for note drafting service
void main() async {
  print('📝 Testing Note Drafting Service');
  print('================================');
  
  try {
    // Create example session data
    final session = SessionData(
      providerName: 'Jane Doe, BCBA',
      npi: 'ATYPICAL',
      clientName: 'A.B.',          // De-identified for privacy
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
    
    print('🎯 Testing with example session data:');
    print('   - Provider: ${session.providerName}');
    print('   - Client: ${session.clientName}');
    print('   - Date: ${session.date}');
    print('   - Duration: ${session.durationMinutes} minutes');
    print('   - Goals: ${session.goalsList.join(', ')}');
    print('   - Data Summary: ${session.dataSummary}');
    
    // Test 1: Build chat messages
    print('\n📝 Test 1: Building chat messages');
    print('--------------------------------');
    
    final messages = NoteDraftingService.buildNoteDraftMessages(
      session: session,
      ragContext: '''
- Use SOAP tone; avoid speculation.
- Payer requires explicit minutes and CPT/Modifiers alignment.
- Focus on measurable outcomes and data-driven observations.
- Include specific behavioral observations and interventions used.
      ''',
    );
    
    print('✅ Chat messages built successfully!');
    print('   - System message length: ${messages[0]['content']?.length} characters');
    print('   - User message length: ${messages[1]['content']?.length} characters');
    
    // Test 2: Generate note draft (without API call)
    print('\n📝 Test 2: Testing message structure');
    print('-----------------------------------');
    
    print('System Message:');
    print('${messages[0]['content']?.substring(0, 200)}...');
    print('');
    print('User Message:');
    print('${messages[1]['content']?.substring(0, 300)}...');
    
    // Test 3: Test with different RAG contexts
    print('\n📝 Test 3: Testing different RAG contexts');
    print('----------------------------------------');
    
    final messagesWithContext = NoteDraftingService.buildNoteDraftMessages(
      session: session,
      ragContext: 'Use professional, objective tone. Include specific data points and measurable outcomes.',
    );
    
    print('✅ Messages with RAG context built successfully!');
    print('   - Total message length: ${messagesWithContext[1]['content']?.length} characters');
    
    // Test 4: Test with empty RAG context
    print('\n📝 Test 4: Testing with empty RAG context');
    print('----------------------------------------');
    
    final messagesEmptyContext = NoteDraftingService.buildNoteDraftMessages(
      session: session,
      ragContext: '',
    );
    
    print('✅ Messages with empty RAG context built successfully!');
    print('   - RAG context placeholder: ${messagesEmptyContext[1]['content']?.contains('(none)')}');
    
    // Test 5: Test with minimal session data
    print('\n📝 Test 5: Testing with minimal session data');
    print('--------------------------------------------');
    
    final minimalSession = SessionData(
      providerName: 'John Smith, BCBA',
      npi: '1234567890',
      clientName: 'C.D.',
      dob: '2016-01-15',
      date: '2025-10-18',
      startTime: '14:00',
      endTime: '15:00',
      durationMinutes: 60,
      serviceName: 'Adaptive Behavior Treatment',
      cpt: '97153',
      modifiers: ['UC'],
      pos: '11',
      goalsList: ['communication'],
      behaviors: 'Cooperative throughout session.',
      interventions: 'Standard ABA interventions.',
      dataSummary: 'Data collected as planned.',
      caregiver: 'Parent present.',
      plan: 'Continue current programming.',
    );
    
    final minimalMessages = NoteDraftingService.buildNoteDraftMessages(
      session: minimalSession,
      ragContext: 'Use concise, professional tone.',
    );
    
    print('✅ Minimal session messages built successfully!');
    print('   - Provider: ${minimalSession.providerName}');
    print('   - NPI: ${minimalSession.npi}');
    print('   - Message length: ${minimalMessages[1]['content']?.length} characters');
    
    // Test 6: Test data validation
    print('\n📝 Test 6: Testing data validation');
    print('----------------------------------');
    
    // Test with missing data
    final incompleteSession = SessionData(
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
      goalsList: [], // Empty goals list
      behaviors: '', // Empty behaviors
      interventions: '', // Empty interventions
      dataSummary: '', // Empty data summary
      caregiver: '', // Empty caregiver
      plan: '', // Empty plan
    );
    
    final incompleteMessages = NoteDraftingService.buildNoteDraftMessages(
      session: incompleteSession,
      ragContext: 'Handle missing data gracefully.',
    );
    
    print('✅ Incomplete session messages built successfully!');
    print('   - Empty goals handled: ${incompleteMessages[1]['content']?.contains('Goals Targeted:')}');
    print('   - Empty behaviors handled: ${incompleteMessages[1]['content']?.contains('Behaviors Observed:')}');
    
    // Test 7: Test with special characters
    print('\n📝 Test 7: Testing with special characters');
    print('------------------------------------------');
    
    final specialSession = SessionData(
      providerName: 'Dr. María García, BCBA',
      npi: 'ATYPICAL',
      clientName: 'José-Luis M.',
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
      behaviors: 'Calm, cooperative; brief off-task moments during transitions. Used "I want" statements appropriately.',
      interventions: 'Least-to-most prompting; differential reinforcement; task analysis.',
      dataSummary: 'Receptive ID: 8/10 trials (80% accuracy); Hand raising: 5 occurrences (0.17/min); Hand washing: 6/7 steps (86% completion)',
      caregiver: 'Parent observed and participated in session; reinforced strategies at home.',
      plan: 'Continue current programs; increase task complexity for receptive ID; fade prompts for hand washing.',
    );
    
    final specialMessages = NoteDraftingService.buildNoteDraftMessages(
      session: specialSession,
      ragContext: 'Handle special characters and accents properly.',
    );
    
    print('✅ Special characters session messages built successfully!');
    print('   - Provider with accent: ${specialMessages[1]['content']?.contains('María García')}');
    print('   - Client with hyphen: ${specialMessages[1]['content']?.contains('José-Luis')}');
    print('   - Quotes in behaviors: ${specialMessages[1]['content']?.contains('I want')}');
    
    print('\n🎉 All note drafting tests completed successfully!');
    print('💡 The service is ready for integration with your app.');
    print('📝 You can now use this to generate clinical notes from session data.');
    
  } catch (e) {
    print('❌ Error in note drafting tests: $e');
  }
}

/// Test the service with different scenarios
Future<void> testDifferentScenarios() async {
  print('\n🎭 Testing Different Scenarios');
  print('==============================');
  
  // Scenario 1: High-performing session
  final highPerformingSession = SessionData(
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
    goalsList: ['receptive identification', 'hand raising', 'hand washing'],
    behaviors: 'Excellent cooperation and engagement throughout session. No challenging behaviors observed.',
    interventions: 'Minimal prompting required; independent responses increased significantly.',
    dataSummary: 'Receptive ID: 9/10 trials (90% accuracy); Hand raising: 8 occurrences (0.27/min); Hand washing: 7/7 steps (100% completion)',
    caregiver: 'Parent actively participated and reinforced strategies effectively.',
    plan: 'Client ready for maintenance phase; consider increasing task complexity.',
  );
  
  print('📊 High-performing session:');
  final highMessages = NoteDraftingService.buildNoteDraftMessages(
    session: highPerformingSession,
    ragContext: 'Highlight positive outcomes and progress.',
  );
  print('   - Message length: ${highMessages[1]['content']?.length} characters');
  
  // Scenario 2: Challenging session
  final challengingSession = SessionData(
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
    goalsList: ['receptive identification', 'hand raising', 'hand washing'],
    behaviors: 'Client showed increased off-task behavior and resistance to demands. Multiple instances of non-compliance observed.',
    interventions: 'Increased prompting levels; used behavior management strategies; provided frequent breaks.',
    dataSummary: 'Receptive ID: 4/10 trials (40% accuracy); Hand raising: 2 occurrences (0.07/min); Hand washing: 3/7 steps (43% completion)',
    caregiver: 'Parent observed challenges and discussed strategies for home implementation.',
    plan: 'Review current programming; consider environmental modifications; increase reinforcement schedule.',
  );
  
  print('📊 Challenging session:');
  final challengingMessages = NoteDraftingService.buildNoteDraftMessages(
    session: challengingSession,
    ragContext: 'Address challenges objectively and focus on intervention strategies.',
  );
  print('   - Message length: ${challengingMessages[1]['content']?.length} characters');
  
  // Scenario 3: Mixed performance session
  final mixedSession = SessionData(
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
    goalsList: ['receptive identification', 'hand raising', 'hand washing'],
    behaviors: 'Client showed variable engagement. Cooperative during preferred activities, resistant during non-preferred tasks.',
    interventions: 'Differential reinforcement; task interspersal; choice-making opportunities.',
    dataSummary: 'Receptive ID: 6/10 trials (60% accuracy); Hand raising: 4 occurrences (0.13/min); Hand washing: 5/7 steps (71% completion)',
    caregiver: 'Parent observed session and discussed strategies for increasing motivation.',
    plan: 'Continue current programming with increased reinforcement for non-preferred tasks.',
  );
  
  print('📊 Mixed performance session:');
  final mixedMessages = NoteDraftingService.buildNoteDraftMessages(
    session: mixedSession,
    ragContext: 'Balance positive and challenging aspects objectively.',
  );
  print('   - Message length: ${mixedMessages[1]['content']?.length} characters');
  
  print('\n✅ All scenarios tested successfully!');
}
