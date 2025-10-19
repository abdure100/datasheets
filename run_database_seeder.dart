import 'package:datasheets/services/filemaker_service.dart';
import 'test/mock_data/database_seeder.dart';

/// Script to run the database seeder
void main() async {
  print('🌱 Starting Database Seeder');
  print('=' * 50);
  
  try {
    // Create the FileMaker service
    final fileMakerService = FileMakerService();
    
    // Create the seeder
    final seeder = DatabaseSeeder(fileMakerService);
    
    // Seed all data for a user
    final results = await seeder.seedAllData(
      username: 'nafisa@test.com',
      clientId: '03626AAB-FEF9-4325-A70D-191463DBAF2A',
      staffId: '17ED033A-7CA9-4367-AA48-3C459DBBC24C',
    );
    
    print('\n✅ Database seeding completed successfully!');
    print('📊 Results:');
    print('  - Client: ${results['client'] != null ? 'Created' : 'Failed'}');
    print('  - Visit: ${results['visit'] != null ? 'Created' : 'Failed'}');
    print('  - Behavior Definitions: ${results['behaviorDefinitions']?.length ?? 0}');
    print('  - Program Assignments: ${results['programAssignments']?.length ?? 0}');
    print('  - Baseline Records: ${results['baselineRecords']?.length ?? 0}');
    print('  - Intervention Records: ${results['interventionRecords']?.length ?? 0}');
    print('  - Generalization Records: ${results['generalizationRecords']?.length ?? 0}');
    print('  - Behavior Logs: ${results['behaviorLogs']?.length ?? 0}');
    
  } catch (e) {
    print('❌ Error during database seeding: $e');
  }
}
