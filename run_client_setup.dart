import 'package:datasheets/services/filemaker_service.dart';
import 'setup_client_03626AAB.dart';

/// Simple runner to set up client 03626AAB-FEF9-4325-A70D-191463DBAF2A
/// with 8 programs and scheduled sessions from 09/16/2025 to 10/15/2025
void main() async {
  print('🚀 Starting client setup for 03626AAB-FEF9-4325-A70D-191463DBAF2A...');
  print('📅 Date range: 09/16/2025 to 10/15/2025');
  print('📋 Programs: 8 (covering all data collection types)');
  print('==============================================');
  
  try {
    // Initialize FileMaker service
    final fileMakerService = FileMakerService();
    
    // Create setup instance
    final setup = Client03626AABSetup(fileMakerService);
    
    // Run the complete setup
    print('🎯 Running complete client setup...');
    final results = await setup.setupClient();
    
    // Print results
    print('\n📊 Setup Results:');
    print('================');
    
    // Client results
    final clientResult = results['client'] as Map<String, dynamic>;
    print('👤 Client: ${clientResult['name']} (${clientResult['id']}) - ${clientResult['status']}');
    
    // Program results
    final programResults = results['programs'] as List<Map<String, dynamic>>;
    print('📋 Programs: ${programResults.length} created');
    for (final program in programResults) {
      print('   - ${program['name']} (${program['dataType']}) - ${program['status']}');
    }
    
    // Session results
    final sessionResults = results['sessions'] as List<Map<String, dynamic>>;
    print('📅 Sessions: ${sessionResults.length} scheduled');
    print('   - Date range: 09/16/2025 to 10/15/2025');
    print('   - Frequency: Monday-Friday');
    print('   - Time: 09:00 AM');
    
    // Behavior results
    final behaviorResults = results['behaviors'] as List<Map<String, dynamic>>;
    print('🎭 Behaviors: ${behaviorResults.length} defined');
    for (final behavior in behaviorResults) {
      print('   - ${behavior['name']} - ${behavior['status']}');
    }
    
    // Get and print summary
    final summary = setup.getSetupSummary();
    print('\n📋 Setup Summary:');
    print('================');
    print('Client: ${summary['client']['name']} (${summary['client']['id']})');
    print('Programs: ${summary['programs']['count']} covering ${summary['programs']['dataTypes'].length} data types');
    print('Sessions: ${summary['sessions']['dateRange']} (${summary['sessions']['frequency']})');
    print('Behaviors: ${summary['behaviors']['count']} definitions');
    
    print('\n✅ Client setup completed successfully!');
    print('🎉 You can now start sessions for this client.');
    
  } catch (e) {
    print('❌ Error during setup: $e');
    print('💡 Make sure your FileMaker service is properly configured.');
  }
}
