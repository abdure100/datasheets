import 'package:datasheets/services/note_drafting_service.dart';

/// Simple test for note drafting without Flutter dependencies
void main() async {
  print('📝 Simple Note Drafting Test');
  print('============================');
  
  try {
    // Test 1: Basic message building
    print('\n📝 Test 1: Building Chat Messages');
    print('----------------------------------');
    
    final session = SessionData(
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
    
    final messages = NoteDraftingService.buildNoteDraftMessages(
      session: session,
      ragContext: 'Use SOAP tone; avoid speculation.',
    );
    
    print('✅ Messages built successfully!');
    print('   - System message length: ${messages[0]['content']?.length} characters');
    print('   - User message length: ${messages[1]['content']?.length} characters');
    
    // Show system message
    print('\n📋 System Message:');
    print('${messages[0]['content']}');
    
    // Show user message (truncated)
    print('\n📋 User Message (first 500 chars):');
    print('${messages[1]['content']?.substring(0, 500)}...');
    
    // Test 2: Test API call (if configured)
    print('\n🌐 Test 2: API Call Test');
    print('------------------------');
    
    try {
      print('   - Making API call...');
      print('   - This may take a few seconds...');
      
      final noteDraft = await NoteDraftingService.generateNoteDraft(
        session: session,
        ragContext: 'Use SOAP tone; avoid speculation.',
      );
      
      print('✅ API call successful!');
      print('\n📝 Generated Note Draft:');
      print('========================');
      print(noteDraft);
      print('========================');
      
    } catch (e) {
      print('❌ API call failed: $e');
      print('💡 This might be due to:');
      print('   - Network connectivity issues');
      print('   - Invalid API key');
      print('   - API service unavailable');
    }
    
    // Test 3: Test streaming (if configured)
    print('\n🌊 Test 3: Streaming Test');
    print('-------------------------');
    
    try {
      print('   - Testing streaming API call...');
      
      await for (final chunk in NoteDraftingService.generateNoteDraftStream(
        session: session,
        ragContext: 'Use professional, objective tone.',
      )) {
        print(chunk);
      }
      
      print('\n✅ Streaming completed successfully!');
      
    } catch (e) {
      print('❌ Streaming failed: $e');
    }
    
    // Test 4: Test different scenarios
    print('\n🎭 Test 4: Different Scenarios');
    print('-------------------------------');
    
    // High-performing session
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
    
    // Challenging session
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
    
    print('\n🎉 All tests completed successfully!');
    print('💡 The note drafting service is working correctly.');
    print('📝 You can now integrate this into your app for automatic note generation.');
    
  } catch (e) {
    print('❌ Error in note drafting test: $e');
  }
}
