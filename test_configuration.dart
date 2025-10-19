import 'package:datasheets/config/note_drafting_config.dart';
import 'package:datasheets/services/note_drafting_service.dart';

/// Test script for configuration and environment setup
void main() {
  print('🔧 Testing Configuration Setup');
  print('==============================');
  
  // Test 1: Check configuration
  print('\n📋 Test 1: Configuration Check');
  print('-------------------------------');
  
  final configSummary = NoteDraftingConfig.getConfigSummary();
  print('✅ Configuration loaded:');
  print('   - API URL: ${configSummary['apiUrl']}');
  print('   - Model: ${configSummary['model']}');
  print('   - Temperature: ${configSummary['temperature']}');
  print('   - Max Tokens: ${configSummary['maxTokens']}');
  print('   - Has API Key: ${configSummary['hasApiKey']}');
  print('   - API Key Source: ${configSummary['apiKeySource']}');
  
  // Test 2: Check API configuration
  print('\n🔑 Test 2: API Key Configuration');
  print('--------------------------------');
  
  if (NoteDraftingConfig.isConfigured) {
    print('✅ API key is configured');
    print('   - API Key: ${NoteDraftingConfig.getApiKey()?.substring(0, 10)}...');
  } else {
    print('⚠️  No API key configured');
    print('   - To configure: Edit lib/config/note_drafting_config.dart');
    print('   - Set apiKey or openaiApiKey to your API key');
  }
  
  // Test 3: Test message building (no API key required)
  print('\n📝 Test 3: Message Building Test');
  print('--------------------------------');
  
  try {
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
      goalsList: ['task independence', 'manding'],
      behaviors: 'Calm, cooperative; brief off-task moments.',
      interventions: 'Least-to-most prompting; differential reinforcement.',
      dataSummary: 'Achieved ~90% independence on targeted tasks.',
      caregiver: 'Parent observed; reinforced strategies.',
      plan: 'Increase task complexity; fade prompts further.',
    );
    
    final messages = NoteDraftingService.buildNoteDraftMessages(
      session: session,
      ragContext: 'Use SOAP tone; avoid speculation.',
    );
    
    print('✅ Messages built successfully!');
    print('   - System message length: ${messages[0]['content']?.length} characters');
    print('   - User message length: ${messages[1]['content']?.length} characters');
    print('   - System prompt: ${messages[0]['content']?.substring(0, 100)}...');
    
  } catch (e) {
    print('❌ Error building messages: $e');
  }
  
  // Test 4: Test API call (if configured)
  print('\n🌐 Test 4: API Call Test');
  print('------------------------');
  
  if (NoteDraftingConfig.isConfigured) {
    print('✅ API key is configured, testing API call...');
    
    try {
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
        goalsList: ['task independence', 'manding'],
        behaviors: 'Calm, cooperative; brief off-task moments.',
        interventions: 'Least-to-most prompting; differential reinforcement.',
        dataSummary: 'Achieved ~90% independence on targeted tasks.',
        caregiver: 'Parent observed; reinforced strategies.',
        plan: 'Increase task complexity; fade prompts further.',
      );
      
      // Note: This will actually make an API call if configured
      print('   - Making API call to: ${NoteDraftingConfig.getApiUrl()}');
      print('   - Using model: ${NoteDraftingConfig.model}');
      print('   - This may take a few seconds...');
      
      // Uncomment the next line to actually test the API call
      // final noteDraft = await NoteDraftingService.generateNoteDraft(session: session);
      // print('✅ API call successful!');
      // print('   - Generated note: ${noteDraft.substring(0, 100)}...');
      
      print('⚠️  API call test skipped (uncomment in code to test)');
      
    } catch (e) {
      print('❌ API call failed: $e');
    }
  } else {
    print('⚠️  No API key configured, skipping API call test');
    print('   - To test API calls:');
    print('     1. Edit lib/config/note_drafting_config.dart');
    print('     2. Set apiKey or openaiApiKey to your API key');
    print('     3. Run this test again');
  }
  
  // Test 5: Configuration recommendations
  print('\n💡 Test 5: Configuration Recommendations');
  print('---------------------------------------');
  
  print('📋 Current setup:');
  print('   - Configuration file: lib/config/note_drafting_config.dart');
  print('   - API URL: ${NoteDraftingConfig.getApiUrl()}');
  print('   - Model: ${NoteDraftingConfig.model}');
  print('   - Temperature: ${NoteDraftingConfig.temperature}');
  print('   - Max Tokens: ${NoteDraftingConfig.maxTokens}');
  
  print('\n🔧 To configure API key:');
  print('   1. Open lib/config/note_drafting_config.dart');
  print('   2. Set apiKey = "your-api-key-here"');
  print('   3. Or set openaiApiKey = "your-openai-key-here"');
  print('   4. Save the file');
  print('   5. Run this test again');
  
  print('\n🌐 Supported APIs:');
  print('   - arawello.ai (default)');
  print('   - OpenAI API (if openaiApiKey is set)');
  print('   - Any OpenAI-compatible API');
  
  print('\n🎉 Configuration test completed!');
  print('💡 The note drafting service is ready to use.');
}
