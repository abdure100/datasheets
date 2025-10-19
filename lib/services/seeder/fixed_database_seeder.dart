import 'dart:convert';
import 'package:datasheets/services/filemaker_service.dart';
import 'package:datasheets/models/visit.dart';
import 'package:datasheets/models/program_assignment.dart';
import 'package:datasheets/models/behavior_definition.dart';
import 'package:datasheets/models/session_record.dart';
import 'package:datasheets/models/behavior_log.dart';

/// Fixed database seeder that matches FileMaker schema requirements
class FixedDatabaseSeeder {
  final FileMakerService _fileMakerService;
  
  FixedDatabaseSeeder(this._fileMakerService);
  
  /// Seed simplified mock data that matches FileMaker schema
  Future<Map<String, dynamic>> seedSimplifiedData({
    required String username,
    required String clientId,
    required String staffId,
  }) async {
    print('🌱 Starting simplified database seeding for user: $username');
    print('👤 Client ID: $clientId');
    print('👨‍💼 Staff ID: $staffId');
    
    try {
      // Skip client creation since it already exists
      print('📝 Skipping client creation (already exists)');
      
      // Create a simple visit
      final visit = await _createSimpleVisit(clientId, staffId);
      
      // Create simplified behavior definitions
      final behaviorDefs = await _createSimpleBehaviorDefinitions(clientId);
      
      // Create simplified program assignments
      final programAssignments = await _createSimpleProgramAssignments(clientId);
      
      // Create session records
      final sessionRecords = await _createSimpleSessionRecords(clientId, visit.id);
      
      // Create behavior logs
      final behaviorLogs = await _createSimpleBehaviorLogs(clientId, visit.id);
      
      print('✅ Simplified database seeding completed successfully!');
      
      return {
        'client': null, // Skipped
        'visit': visit,
        'behaviorDefinitions': behaviorDefs,
        'programAssignments': programAssignments,
        'sessionRecords': sessionRecords,
        'behaviorLogs': behaviorLogs,
      };
      
    } catch (e) {
      print('❌ Error during simplified database seeding: $e');
      rethrow;
    }
  }
  
  /// Create a simple visit
  Future<Visit> _createSimpleVisit(String clientId, String staffId) async {
    final visit = Visit(
      id: 'visit-${DateTime.now().millisecondsSinceEpoch}',
      clientId: clientId,
      staffId: staffId,
      serviceCode: 'Intervention (97153)',
      startTs: DateTime.now().subtract(Duration(hours: 2)),
      endTs: DateTime.now().subtract(Duration(hours: 1)),
      status: 'Submitted',
      notes: 'Demo visit for testing',
      clientName: 'Demo Client',
      staffName: 'Demo Staff',
      appointmentDate: DateTime.now().toIso8601String().split('T')[0],
      timeIn: '09:00',
    );
    
    try {
      final createdVisit = await _fileMakerService.createVisitWithDio(visit);
      print('✅ Simple visit created: ${createdVisit.id}');
      return createdVisit;
    } catch (e) {
      print('❌ Failed to create visit: $e');
      return visit;
    }
  }
  
  /// Create simplified behavior definitions with minimal required fields
  Future<List<Map<String, dynamic>>> _createSimpleBehaviorDefinitions(String clientId) async {
    final behaviorDefs = [
      {
        'id': 'behavior-001',
        'behavior_name': 'Aggressive Behavior',
        'behavior_code': 'AGGR',
        'data_collection_method': 'frequency',
        'severityScale_json': jsonEncode({'1': 'Mild', '2': 'Moderate', '3': 'Severe'}),
        'clientId': clientId,
      },
      {
        'id': 'behavior-002',
        'behavior_name': 'Self-Injurious Behavior',
        'behavior_code': 'SIB',
        'data_collection_method': 'frequency',
        'severityScale_json': jsonEncode({'1': 'Mild', '2': 'Moderate', '3': 'Severe'}),
        'clientId': clientId,
      },
    ];
    
    final createdDefs = <Map<String, dynamic>>[];
    
    for (final def in behaviorDefs) {
      try {
        // Create behavior definition with minimal fields
        final behaviorDef = BehaviorDefinition(
          id: def['id'] as String,
          name: def['behavior_name'] as String,
          code: def['behavior_code'] as String,
          defaultLogType: def['data_collection_method'] as String,
          severityScaleJson: {'1': 'Mild', '2': 'Moderate', '3': 'Severe'},
          clientId: clientId,
        );
        
        final createdDef = await _fileMakerService.createBehaviorDefinition(behaviorDef);
        createdDefs.add({
          'id': createdDef.id,
          'name': createdDef.name,
          'status': 'created'
        });
        print('✅ Created behavior definition: ${createdDef.name}');
      } catch (e) {
        print('❌ Failed to create behavior definition ${def['behavior_name']}: $e');
        createdDefs.add({
          'id': def['id'],
          'name': def['behavior_name'],
          'status': 'failed'
        });
      }
    }
    
    print('✅ Created ${createdDefs.length} behavior definitions');
    return createdDefs;
  }
  
  /// Create simplified program assignments
  Future<List<Map<String, dynamic>>> _createSimpleProgramAssignments(String clientId) async {
    final programs = [
      {
        'id': 'program-001',
        'name': 'Communication Skills',
        'dataType': 'frequency',
        'status': 'active',
        'phase': 'intervention',
        'criteriaJson': jsonEncode({'target': 80, 'sessions': 5}),
        'configJson': jsonEncode({'method': 'DTT', 'prompts': 'full'}),
        'clientId': clientId,
      },
      {
        'id': 'program-002',
        'name': 'Social Skills',
        'dataType': 'duration',
        'status': 'active',
        'phase': 'intervention',
        'criteriaJson': jsonEncode({'target': 90, 'sessions': 5}),
        'configJson': jsonEncode({'method': 'Natural Environment', 'prompts': 'partial'}),
        'clientId': clientId,
      },
    ];
    
    final createdPrograms = <Map<String, dynamic>>[];
    
    for (final program in programs) {
      try {
        final assignment = ProgramAssignment(
          id: program['id'] as String,
          name: program['name'] as String,
          dataType: program['dataType'] as String,
          criteriaJson: program['criteriaJson'] as String,
          configJson: program['configJson'] as String,
          status: program['status'] as String,
          phase: program['phase'] as String,
          clientId: clientId,
        );
        
        final createdAssignment = await _fileMakerService.createProgramAssignment(assignment);
        createdPrograms.add({
          'id': createdAssignment.id,
          'name': createdAssignment.name,
          'status': 'created'
        });
        print('✅ Created program assignment: ${createdAssignment.name}');
      } catch (e) {
        print('❌ Failed to create program assignment ${program['name']}: $e');
        createdPrograms.add({
          'id': program['id'],
          'name': program['name'],
          'status': 'failed'
        });
      }
    }
    
    print('✅ Created ${createdPrograms.length} program assignments');
    return createdPrograms;
  }
  
  /// Create simplified session records
  Future<List<Map<String, dynamic>>> _createSimpleSessionRecords(String clientId, String visitId) async {
    final sessionRecords = [
      {
        'id': 'session-001',
        'visitId': visitId,
        'clientId': clientId,
        'assignmentId': 'program-001',
        'startedAt': DateTime.now().subtract(Duration(hours: 1)),
        'updatedAt': DateTime.now(),
        'payload': {'accuracy': 75, 'prompts': 3},
        'staffId': 'staff-001',
        'notes': 'Demo session record',
        'interventionPhase': 'intervention',
        'programStartTime': DateTime.now().subtract(Duration(hours: 1)),
        'programEndTime': DateTime.now().subtract(Duration(minutes: 30)),
      },
    ];
    
    final createdRecords = <Map<String, dynamic>>[];
    
    for (final record in sessionRecords) {
      try {
        final sessionRecord = SessionRecord(
          id: record['id'] as String,
          visitId: record['visitId'] as String,
          clientId: record['clientId'] as String,
          assignmentId: record['assignmentId'] as String,
          startedAt: record['startedAt'] as DateTime,
          updatedAt: record['updatedAt'] as DateTime,
          payload: record['payload'] as Map<String, dynamic>,
          staffId: record['staffId'] as String,
          notes: record['notes'] as String,
          interventionPhase: record['interventionPhase'] as String,
          programStartTime: record['programStartTime'] as DateTime,
          programEndTime: record['programEndTime'] as DateTime,
        );
        
        final createdRecord = await _fileMakerService.upsertSessionRecord(sessionRecord);
        createdRecords.add({
          'id': createdRecord.id,
          'visitId': createdRecord.visitId,
          'status': 'created'
        });
        print('✅ Created session record: ${createdRecord.id}');
      } catch (e) {
        print('❌ Failed to create session record: $e');
        createdRecords.add({
          'id': record['id'],
          'status': 'failed'
        });
      }
    }
    
    print('✅ Created ${createdRecords.length} session records');
    return createdRecords;
  }
  
  /// Create simplified behavior logs
  Future<List<Map<String, dynamic>>> _createSimpleBehaviorLogs(String clientId, String visitId) async {
    final behaviorLogs = [
      {
        'id': 'log-001',
        'visitId': visitId,
        'clientId': clientId,
        'behaviorId': 'behavior-001',
        'assignmentId': 'program-001',
        'startTs': DateTime.now().subtract(Duration(hours: 1)),
        'endTs': DateTime.now().subtract(Duration(minutes: 30)),
        'durationSec': 1800,
        'count': 3,
        'ratePerMin': 0.1,
        'antecedent': 'Task demand',
        'behaviorDesc': 'Aggressive behavior observed',
        'consequence': 'Task removed',
        'setting': 'Therapy room',
        'perceivedFunction': 'Escape',
        'severity': 2,
        'injury': false,
        'restraintUsed': false,
        'notes': 'Demo behavior log',
        'collector': 'Demo Staff',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      },
    ];
    
    final createdLogs = <Map<String, dynamic>>[];
    
    for (final log in behaviorLogs) {
      try {
        final behaviorLog = BehaviorLog(
          id: log['id'] as String,
          visitId: log['visitId'] as String,
          clientId: log['clientId'] as String,
          behaviorId: log['behaviorId'] as String,
          assignmentId: log['assignmentId'] as String?,
          startTs: log['startTs'] as DateTime,
          endTs: log['endTs'] as DateTime,
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
          createdAt: log['createdAt'] as DateTime,
          updatedAt: log['updatedAt'] as DateTime,
        );
        
        final createdLog = await _fileMakerService.createBehaviorLog(behaviorLog);
        createdLogs.add({
          'id': createdLog.id,
          'visitId': createdLog.visitId,
          'status': 'created'
        });
        print('✅ Created behavior log: ${createdLog.id}');
      } catch (e) {
        print('❌ Failed to create behavior log: $e');
        createdLogs.add({
          'id': log['id'],
          'status': 'failed'
        });
      }
    }
    
    print('✅ Created ${createdLogs.length} behavior logs');
    return createdLogs;
  }
}
