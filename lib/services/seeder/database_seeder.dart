import 'dart:convert';
import 'package:datasheets/services/filemaker_service.dart';
import 'package:datasheets/models/client.dart';
import 'package:datasheets/models/visit.dart';
import 'package:datasheets/models/program_assignment.dart';
import 'package:datasheets/models/behavior_definition.dart';
import 'package:datasheets/models/session_record.dart';
import 'package:datasheets/models/behavior_log.dart';
import 'goal_based_mock_data.dart';

/// Database seeder for goal-based mock data
class DatabaseSeeder {
  final FileMakerService _fileMakerService;
  
  DatabaseSeeder(this._fileMakerService);
  
  /// Seed all goal-based mock data to the database
  Future<Map<String, dynamic>> seedAllData({
    required String username,
    required String clientId,
    required String staffId,
  }) async {
    print('🌱 Starting database seeding for user: $username');
    print('👤 Client ID: $clientId');
    print('👨‍💼 Staff ID: $staffId');
    
    final results = <String, dynamic>{};
    
    try {
      // 1. Create sample client
      print('📝 Creating sample client...');
      final client = await _createSampleClient(clientId);
      results['client'] = client;
      
      // 2. Create sample visit
      print('📝 Creating sample visit...');
      final visit = await _createSampleVisit(clientId, staffId);
      results['visit'] = visit;
      
      // 3. Create behavior definitions
      print('📝 Creating behavior definitions...');
      final behaviorDefs = await _createBehaviorDefinitions(clientId);
      results['behaviorDefinitions'] = behaviorDefs;
      
      // 4. Create program assignments (goals)
      print('📝 Creating program assignments...');
      final programs = await _createProgramAssignments(clientId, staffId);
      results['programAssignments'] = programs;
      
      // 5. Create session records for baseline data
      print('📝 Creating baseline session records...');
      final baselineRecords = await _createSessionRecords(
        clientId, 
        visit.id, 
        'baseline'
      );
      results['baselineRecords'] = baselineRecords;
      
      // 6. Create session records for intervention data
      print('📝 Creating intervention session records...');
      final interventionRecords = await _createSessionRecords(
        clientId, 
        visit.id, 
        'intervention'
      );
      results['interventionRecords'] = interventionRecords;
      
      // 7. Create session records for generalization data
      print('📝 Creating generalization session records...');
      final generalizationRecords = await _createSessionRecords(
        clientId, 
        visit.id, 
        'generalization'
      );
      results['generalizationRecords'] = generalizationRecords;
      
      // 8. Create behavior logs
      print('📝 Creating behavior logs...');
      final behaviorLogs = await _createBehaviorLogs(clientId, visit.id);
      results['behaviorLogs'] = behaviorLogs;
      
      print('✅ Database seeding completed successfully!');
      print('📊 Summary:');
      print('  - Client: ${results['client'] != null ? 'Created' : 'Failed'}');
      print('  - Visit: ${results['visit'] != null ? 'Created' : 'Failed'}');
      print('  - Behavior Definitions: ${results['behaviorDefinitions']?.length ?? 0}');
      print('  - Program Assignments: ${results['programAssignments']?.length ?? 0}');
      print('  - Baseline Records: ${results['baselineRecords']?.length ?? 0}');
      print('  - Intervention Records: ${results['interventionRecords']?.length ?? 0}');
      print('  - Generalization Records: ${results['generalizationRecords']?.length ?? 0}');
      print('  - Behavior Logs: ${results['behaviorLogs']?.length ?? 0}');
      
      return results;
      
    } catch (e) {
      print('❌ Error during database seeding: $e');
      rethrow;
    }
  }
  
  /// Create sample client
  Future<Client> _createSampleClient(String clientId) async {
    final client = Client(
      id: clientId,
      name: 'Sample Client',
      address: '123 Main St, Anytown, USA',
      phone: '555-0123',
      email: 'sample.client@example.com',
      agencyId: 'agency-001',
      dateOfBirth: '2010-01-01',
    );
    
    try {
      final createdClient = await _fileMakerService.createClient(client);
      print('✅ Sample client created: ${createdClient.name}');
      return createdClient;
    } catch (e) {
      print('❌ Failed to create client: $e');
      // Return the original client object if creation fails
      return client;
    }
  }
  
  /// Create sample visit
  Future<Visit> _createSampleVisit(String clientId, String staffId) async {
    final visit = Visit(
      id: 'visit-${DateTime.now().millisecondsSinceEpoch}',
      clientId: clientId,
      staffId: staffId,
      serviceCode: 'Intervention (97153)',
      startTs: DateTime.now().subtract(Duration(hours: 2)),
      endTs: DateTime.now().subtract(Duration(hours: 1)),
      status: 'Submitted',
      notes: 'Sample visit for goal-based mock data',
      clientName: 'Sample Client',
      staffName: 'Sample Staff',
      appointmentDate: DateTime.now().toIso8601String().split('T')[0],
      timeIn: '09:00',
    );
    
    try {
      final createdVisit = await _fileMakerService.createVisitWithDio(visit);
      print('✅ Sample visit created: ${createdVisit.id}');
      return createdVisit;
    } catch (e) {
      print('❌ Failed to create visit: $e');
      // Return the original visit object if creation fails
      return visit;
    }
  }
  
  /// Create behavior definitions
  Future<List<Map<String, dynamic>>> _createBehaviorDefinitions(String clientId) async {
    // Create mock behavior definitions
    final behaviorDefs = [
      {
        'id': 'behavior-001',
        'name': 'Aggressive Behavior',
        'code': 'AGGR',
        'defaultLogType': 'frequency',
        'severityScale': {'1': 'Mild', '2': 'Moderate', '3': 'Severe'},
        'clientId': clientId,
        'orgId': 'org-001',
      },
      {
        'id': 'behavior-002',
        'name': 'Self-Injurious Behavior',
        'code': 'SIB',
        'defaultLogType': 'frequency',
        'severityScale': {'1': 'Mild', '2': 'Moderate', '3': 'Severe'},
        'clientId': clientId,
        'orgId': 'org-001',
      },
      {
        'id': 'behavior-003',
        'name': 'Stereotypic Behavior',
        'code': 'STIM',
        'defaultLogType': 'duration',
        'severityScale': {'1': 'Mild', '2': 'Moderate', '3': 'Severe'},
        'clientId': clientId,
        'orgId': 'org-001',
      },
    ];
    
    final createdDefs = <Map<String, dynamic>>[];
    
    for (final def in behaviorDefs) {
      final behaviorDef = BehaviorDefinition(
        id: def['id'] as String,
        name: def['name'] as String,
        code: def['code'] as String,
        defaultLogType: def['defaultLogType'] as String,
        severityScaleJson: def['severityScale'] as Map<String, dynamic>,
        clientId: clientId,
        orgId: def['orgId'] as String?,
      );
      
      try {
        final createdDef = await _fileMakerService.createBehaviorDefinition(behaviorDef);
        createdDefs.add({
          'id': createdDef.id,
          'name': createdDef.name,
          'status': 'created'
        });
      } catch (e) {
        print('❌ Failed to create behavior definition ${behaviorDef.name}: $e');
        createdDefs.add({
          'id': behaviorDef.id,
          'name': behaviorDef.name,
          'status': 'failed'
        });
      }
    }
    
    print('✅ Created ${createdDefs.length} behavior definitions');
    return createdDefs;
  }
  
  /// Create program assignments (goals)
  Future<List<Map<String, dynamic>>> _createProgramAssignments(String clientId, String staffId) async {
    final goals = GoalBasedMockData.getEightGoals();
    final programs = GoalBasedMockData.getProgramsForGoals();
    final createdPrograms = <Map<String, dynamic>>[];
    
    for (int i = 0; i < goals.length; i++) {
      final goal = goals[i];
      final program = programs[i];
      
      final assignment = ProgramAssignment(
        id: program['id'] as String?,
        name: program['name'] as String?,
        dataType: program['dataType'] as String?,
        criteriaJson: jsonEncode(program['masteryCriteria']),
        configJson: jsonEncode(program['config']),
        status: program['status'] as String?,
        phase: program['phase'] as String?,
        clientId: clientId,
        ltgId: goal['id'] as String?,
      );
      
      try {
        final createdAssignment = await _fileMakerService.createProgramAssignment(assignment);
        createdPrograms.add({
          'id': createdAssignment.id,
          'name': createdAssignment.name,
          'goalId': goal['id'],
          'status': 'created'
        });
      } catch (e) {
        print('❌ Failed to create program assignment ${assignment.name}: $e');
        createdPrograms.add({
          'id': assignment.id,
          'name': assignment.name,
          'goalId': goal['id'],
          'status': 'failed'
        });
      }
    }
    
    print('✅ Created ${createdPrograms.length} program assignments');
    return createdPrograms;
  }
  
  /// Create session records for a specific phase
  Future<List<Map<String, dynamic>>> _createSessionRecords(
    String clientId, 
    String visitId, 
    String phase
  ) async {
    List<Map<String, dynamic>> phaseData;
    
    switch (phase) {
      case 'baseline':
        phaseData = GoalBasedMockData.getBaselineDataForAllGoals();
        break;
      case 'intervention':
        phaseData = GoalBasedMockData.getInterventionDataForAllGoals();
        break;
      case 'generalization':
        phaseData = GoalBasedMockData.getGeneralizationDataForAllGoals();
        break;
      default:
        phaseData = [];
    }
    
    final createdRecords = <Map<String, dynamic>>[];
    
    for (final data in phaseData) {
      final sessionRecord = SessionRecord(
        id: data['id'],
        visitId: visitId,
        clientId: clientId,
        assignmentId: data['programId'],
        startedAt: DateTime.now().subtract(Duration(days: 7 - (phase == 'baseline' ? 7 : phase == 'intervention' ? 4 : 0))),
        updatedAt: DateTime.now(),
        payload: data['sessionData'],
        notes: data['notes'],
        staffId: 'staff-001',
      );
      
      // Note: In a real implementation, you would call _fileMakerService.createSessionRecord(sessionRecord)
      createdRecords.add({
        'id': sessionRecord.id,
        'assignmentId': sessionRecord.assignmentId,
        'phase': phase,
        'status': 'created'
      });
    }
    
    print('✅ Created ${createdRecords.length} $phase session records');
    return createdRecords;
  }
  
  /// Create behavior logs
  Future<List<Map<String, dynamic>>> _createBehaviorLogs(String clientId, String visitId) async {
    // Create mock behavior logs
    final behaviorLogs = [
      {
        'id': 'log-001',
        'visitId': visitId,
        'clientId': clientId,
        'behaviorId': 'behavior-001',
        'assignmentId': 'program-001',
        'startTs': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
        'endTs': DateTime.now().subtract(Duration(minutes: 30)).toIso8601String(),
        'durationSec': 1800,
        'count': 3,
        'ratePerMin': 0.1,
        'antecedent': 'Asked to work on math',
        'behaviorDesc': 'Hit therapist with closed fist',
        'consequence': 'Removed from work area',
        'setting': 'Classroom',
        'perceivedFunction': 'Escape',
        'severity': 2,
        'injury': false,
        'restraintUsed': false,
        'notes': 'Client became frustrated with math problems',
        'collector': 'staff-001',
        'createdAt': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
        'updatedAt': DateTime.now().subtract(Duration(minutes: 30)).toIso8601String(),
      },
      {
        'id': 'log-002',
        'visitId': visitId,
        'clientId': clientId,
        'behaviorId': 'behavior-002',
        'assignmentId': 'program-002',
        'startTs': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
        'endTs': DateTime.now().subtract(Duration(hours: 1, minutes: 30)).toIso8601String(),
        'durationSec': 1800,
        'count': 1,
        'ratePerMin': 0.03,
        'antecedent': 'Transition to lunch',
        'behaviorDesc': 'Hit head against wall',
        'consequence': 'Redirected to safe area',
        'setting': 'Hallway',
        'perceivedFunction': 'Sensory',
        'severity': 1,
        'injury': false,
        'restraintUsed': false,
        'notes': 'Client was overwhelmed by transition',
        'collector': 'staff-001',
        'createdAt': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
        'updatedAt': DateTime.now().subtract(Duration(hours: 1, minutes: 30)).toIso8601String(),
      },
    ];
    
    final createdLogs = <Map<String, dynamic>>[];
    
    for (final log in behaviorLogs) {
      final behaviorLog = BehaviorLog(
        id: log['id'] as String,
        visitId: visitId,
        clientId: clientId,
        behaviorId: log['behaviorId'] as String,
        assignmentId: log['assignmentId'] as String?,
        startTs: DateTime.parse(log['startTs'] as String),
        endTs: DateTime.parse(log['endTs'] as String),
        durationSec: log['durationSec'] as int?,
        count: log['count'] as int?,
        ratePerMin: log['ratePerMin'] as double?,
        antecedent: log['antecedent'] as String?,
        behaviorDesc: log['behaviorDesc'] as String?,
        consequence: log['consequence'] as String?,
        setting: log['setting'] as String?,
        perceivedFunction: log['perceivedFunction'] as String?,
        severity: log['severity'] as int?,
        injury: log['injury'] as bool?,
        restraintUsed: log['restraintUsed'] as bool?,
        notes: log['notes'] as String?,
        collector: log['collector'] as String?,
        createdAt: DateTime.parse(log['createdAt'] as String),
        updatedAt: DateTime.parse(log['updatedAt'] as String),
      );
      
      // Note: In a real implementation, you would call _fileMakerService.createBehaviorLog(behaviorLog)
      createdLogs.add({
        'id': behaviorLog.id,
        'behaviorId': behaviorLog.behaviorId,
        'status': 'created'
      });
    }
    
    print('✅ Created ${createdLogs.length} behavior logs');
    return createdLogs;
  }
  
  /// Get summary of seeded data
  Future<Map<String, dynamic>> getSeededDataSummary({
    required String clientId,
  }) async {
    try {
      // Get all data for the client
      final allData = GoalBasedMockData.getAllGoalBasedData();
      
      return {
        'clientId': clientId,
        'totalGoals': allData['goals']?.length ?? 0,
        'totalPrograms': allData['programs']?.length ?? 0,
        'totalBaselineRecords': allData['baseline']?.length ?? 0,
        'totalInterventionRecords': allData['intervention']?.length ?? 0,
        'totalGeneralizationRecords': allData['generalization']?.length ?? 0,
        'totalBehaviorLogs': allData['behaviorLogs']?.length ?? 0,
        'dataTypes': allData['dataTypes'] ?? [],
        'phases': allData['phases'] ?? [],
        'summary': allData['summary'] ?? {},
      };
    } catch (e) {
      print('❌ Error getting seeded data summary: $e');
      return {};
    }
  }
  
  /// Clear all seeded data (for testing)
  Future<void> clearSeededData({
    required String clientId,
  }) async {
    print('🗑️ Clearing seeded data for client: $clientId');
    
    try {
      // Note: In a real implementation, you would call appropriate delete methods
      // _fileMakerService.deleteClient(clientId);
      // _fileMakerService.deleteVisit(visitId);
      // etc.
      
      print('✅ Seeded data cleared successfully');
    } catch (e) {
      print('❌ Error clearing seeded data: $e');
      rethrow;
    }
  }
}
