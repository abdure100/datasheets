import 'dart:convert';
import 'package:datasheets/models/client.dart';
import 'package:datasheets/models/visit.dart';
import 'package:datasheets/models/program_assignment.dart';
import 'package:datasheets/services/filemaker_service.dart';

/// Setup script for client 03626AAB-FEF9-4325-A70D-191463DBAF2A
/// with 8 programs and scheduled sessions from 09/16/2025 to 10/15/2025
class Client03626AABSetup {
  final FileMakerService _fileMakerService;
  
  // Client information
  static const String clientId = '03626AAB-FEF9-4325-A70D-191463DBAF2A';
  static const String clientName = 'Alex Johnson';
  static const String clientDob = '2015-03-15';
  
  // Staff information (you'll need to update these)
  static const String staffId = '17ED033A-7CA9-4367-AA48-3C459DBBC24C';
  static const String staffName = 'Current Staff';
  
  // Service code
  static const String serviceCode = 'Intervention (97153)';
  
  Client03626AABSetup(this._fileMakerService);
  
  /// Main setup method
  Future<Map<String, dynamic>> setupClient() async {
    print('🎯 Setting up client $clientId with 8 programs and scheduled sessions...');
    
    final results = <String, dynamic>{};
    
    try {
      // 1. Create/Update client
      results['client'] = await _createClient();
      
      // 2. Create 8 program assignments
      results['programs'] = await _createEightPrograms();
      
      // 3. Create scheduled sessions
      results['sessions'] = await _createScheduledSessions();
      
      // 4. Create behavior definitions
      results['behaviors'] = await _createBehaviorDefinitions();
      
      print('✅ Client setup completed successfully!');
      return results;
      
    } catch (e) {
      print('❌ Error setting up client: $e');
      rethrow;
    }
  }
  
  /// Create the client record
  Future<Map<String, dynamic>> _createClient() async {
    print('👤 Creating client record...');
    
    final client = Client(
      id: clientId,
      name: clientName,
      dateOfBirth: clientDob,
      address: '123 Main St, Anytown, ST 12345',
      phone: '(555) 123-4567',
      email: 'alex.johnson@example.com',
      agencyId: 'AGENCY-001',
    );
    
    try {
      final createdClient = await _fileMakerService.createClient(client);
      print('✅ Client created: ${createdClient.name} (${createdClient.id})');
      return {
        'id': createdClient.id,
        'name': createdClient.name,
        'status': 'created'
      };
    } catch (e) {
      print('⚠️ Client may already exist: $e');
      return {
        'id': clientId,
        'name': clientName,
        'status': 'existing'
      };
    }
  }
  
  /// Create 8 program assignments covering all data collection types
  Future<List<Map<String, dynamic>>> _createEightPrograms() async {
    print('📋 Creating 8 program assignments...');
    
    final programs = [
      {
        'id': '${clientId}_prog_001',
        'name': 'Receptive Identification of Common Objects',
        'dataType': 'percentCorrect',
        'status': 'active',
        'phase': 'intervention',
        'criteriaJson': jsonEncode({
          'target': 80,
          'sessions': 5,
          'consecutive': 3,
          'mastery': '80% accuracy for 3 consecutive sessions'
        }),
        'configJson': jsonEncode({
          'method': 'DTT',
          'prompts': 'full',
          'objects': ['ball', 'cup', 'book', 'car', 'dog', 'cat', 'apple', 'shoe', 'hat', 'phone'],
          'trials': 10
        }),
      },
      {
        'id': '${clientId}_prog_002',
        'name': 'Hand Raising for Attention',
        'dataType': 'frequency',
        'status': 'active',
        'phase': 'intervention',
        'criteriaJson': jsonEncode({
          'target': 5,
          'sessions': 5,
          'consecutive': 3,
          'mastery': '5 hand raises per session for 3 consecutive sessions'
        }),
        'configJson': jsonEncode({
          'method': 'Natural Environment',
          'prompts': 'partial',
          'replacement_behavior': 'Hand raising',
          'context': 'Classroom activities'
        }),
      },
      {
        'id': '${clientId}_prog_003',
        'name': 'Independent Hand Washing',
        'dataType': 'taskAnalysis',
        'status': 'active',
        'phase': 'intervention',
        'criteriaJson': jsonEncode({
          'target': 90,
          'sessions': 5,
          'consecutive': 3,
          'mastery': '90% completion for 3 consecutive sessions'
        }),
        'configJson': jsonEncode({
          'method': 'Task Analysis',
          'prompts': 'graduated',
          'steps': [
            'Turn on water',
            'Wet hands',
            'Apply soap',
            'Scrub hands',
            'Rinse hands',
            'Turn off water',
            'Dry hands'
          ]
        }),
      },
      {
        'id': '${clientId}_prog_004',
        'name': 'On-Task Behavior During Academic Work',
        'dataType': 'timeSampling',
        'status': 'active',
        'phase': 'intervention',
        'criteriaJson': jsonEncode({
          'target': 80,
          'sessions': 5,
          'consecutive': 3,
          'mastery': '80% on-task for 3 consecutive sessions'
        }),
        'configJson': jsonEncode({
          'method': 'Time Sampling',
          'interval': 15,
          'work_periods': ['Math worksheet', 'Reading comprehension', 'Writing practice'],
          'duration': 15
        }),
      },
      {
        'id': '${clientId}_prog_005',
        'name': 'Appropriate Request Making',
        'dataType': 'rate',
        'status': 'active',
        'phase': 'intervention',
        'criteriaJson': jsonEncode({
          'target': 2.0,
          'sessions': 5,
          'consecutive': 3,
          'mastery': '2.0 requests per minute for 3 consecutive sessions'
        }),
        'configJson': jsonEncode({
          'method': 'Natural Environment',
          'prompts': 'minimal',
          'request_items': ['snack', 'toy', 'break', 'help', 'bathroom'],
          'format': 'I want...'
        }),
      },
      {
        'id': '${clientId}_prog_006',
        'name': 'Social Interaction Quality',
        'dataType': 'ratingScale',
        'status': 'active',
        'phase': 'intervention',
        'criteriaJson': jsonEncode({
          'target': 4.0,
          'sessions': 5,
          'consecutive': 3,
          'mastery': '4.0 rating for 3 consecutive sessions'
        }),
        'configJson': jsonEncode({
          'method': 'Rating Scale',
          'scale': '1-5',
          'criteria': {
            '1': 'Poor - No interaction',
            '2': 'Fair - Minimal interaction',
            '3': 'Good - Some interaction',
            '4': 'Very Good - Good interaction',
            '5': 'Excellent - Outstanding interaction'
          }
        }),
      },
      {
        'id': '${clientId}_prog_007',
        'name': 'Reduction of Aggressive Behavior',
        'dataType': 'abcData',
        'status': 'active',
        'phase': 'intervention',
        'criteriaJson': jsonEncode({
          'target': 0,
          'sessions': 5,
          'consecutive': 3,
          'mastery': '0 incidents for 3 consecutive sessions'
        }),
        'configJson': jsonEncode({
          'method': 'ABC Data Collection',
          'replacement_behaviors': ['Ask for help', 'Take a break', 'Use calming strategies'],
          'severity_scale': '1-5',
          'triggers': ['Transitions', 'Demands', 'Attention seeking']
        }),
      },
      {
        'id': '${clientId}_prog_008',
        'name': 'Independent Play Duration',
        'dataType': 'duration',
        'status': 'active',
        'phase': 'intervention',
        'criteriaJson': jsonEncode({
          'target': 4.0,
          'sessions': 5,
          'consecutive': 3,
          'mastery': '4 minutes independent play for 3 consecutive sessions'
        }),
        'configJson': jsonEncode({
          'method': 'Duration Timing',
          'play_activities': ['Puzzles', 'Blocks', 'Books', 'Art supplies', 'Toys'],
          'independence_level': 'No adult interaction',
          'target_duration': 4
        }),
      },
    ];
    
    final createdPrograms = <Map<String, dynamic>>[];
    
    for (final program in programs) {
      try {
        final assignment = ProgramAssignment(
          id: program['id'] as String,
          clientId: clientId,
          name: program['name'] as String,
          dataType: program['dataType'] as String,
          status: program['status'] as String,
          phase: program['phase'] as String,
          criteriaJson: program['criteriaJson'] as String,
          configJson: program['configJson'] as String,
        );
        
        final createdAssignment = await _fileMakerService.createProgramAssignment(assignment);
        createdPrograms.add({
          'id': createdAssignment.id,
          'name': createdAssignment.name,
          'dataType': createdAssignment.dataType,
          'status': 'created'
        });
        print('✅ Created program: ${createdAssignment.name}');
      } catch (e) {
        print('❌ Failed to create program ${program['name']}: $e');
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
  
  /// Create scheduled sessions from 09/16/2025 to 10/15/2025
  Future<List<Map<String, dynamic>>> _createScheduledSessions() async {
    print('📅 Creating scheduled sessions from 09/16/2025 to 10/15/2025...');
    
    final sessions = <Map<String, dynamic>>[];
    final startDate = DateTime(2025, 9, 16);
    final endDate = DateTime(2025, 10, 15);
    
    // Create sessions for each weekday (Monday-Friday)
    for (var date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      // Skip weekends
      if (date.weekday >= 1 && date.weekday <= 5) {
        final sessionDate = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
        final sessionTime = '09:00'; // 9:00 AM
        
        final visit = Visit(
          id: '${clientId}_visit_${date.millisecondsSinceEpoch}',
          clientId: clientId,
          staffId: staffId,
          serviceCode: serviceCode,
          startTs: DateTime(date.year, date.month, date.day, 9, 0),
          endTs: null,
          status: 'Planned',
          notes: 'Scheduled session for $clientName',
          clientName: clientName,
          staffName: staffName,
          appointmentDate: sessionDate,
          timeIn: sessionTime,
        );
        
        try {
          final createdVisit = await _fileMakerService.createVisit(visit);
          sessions.add({
            'id': createdVisit.id,
            'date': sessionDate,
            'time': sessionTime,
            'status': 'created'
          });
          print('✅ Created session: $sessionDate at $sessionTime');
        } catch (e) {
          print('❌ Failed to create session for $sessionDate: $e');
          sessions.add({
            'id': '${clientId}_visit_${date.millisecondsSinceEpoch}',
            'date': sessionDate,
            'time': sessionTime,
            'status': 'failed'
          });
        }
      }
    }
    
    print('✅ Created ${sessions.length} scheduled sessions');
    return sessions;
  }
  
  /// Create behavior definitions for the client
  Future<List<Map<String, dynamic>>> _createBehaviorDefinitions() async {
    print('🎭 Creating behavior definitions...');
    
    final behaviors = [
      {
        'id': '${clientId}_behav_001',
        'name': 'Aggressive Behavior',
        'description': 'Physical aggression toward others or property',
        'category': 'Challenging',
        'severity': 'High',
        'replacement_behavior': 'Ask for help or take a break'
      },
      {
        'id': '${clientId}_behav_002',
        'name': 'Self-Injurious Behavior',
        'description': 'Any behavior that causes harm to self',
        'category': 'Challenging',
        'severity': 'High',
        'replacement_behavior': 'Use calming strategies'
      },
      {
        'id': '${clientId}_behav_003',
        'name': 'Appropriate Request Making',
        'description': 'Using words or gestures to request items or activities',
        'category': 'Communication',
        'severity': 'Low',
        'replacement_behavior': 'Continue appropriate requests'
      },
    ];
    
    final createdBehaviors = <Map<String, dynamic>>[];
    
    for (final behavior in behaviors) {
      try {
        final behaviorDef = BehaviorDefinition(
          id: behavior['id'] as String,
          clientId: clientId,
          name: behavior['name'] as String,
          description: behavior['description'] as String,
          category: behavior['category'] as String,
          severity: behavior['severity'] as String,
          replacementBehavior: behavior['replacement_behavior'] as String,
        );
        
        final createdDef = await _fileMakerService.createBehaviorDefinition(behaviorDef);
        createdBehaviors.add({
          'id': createdDef.id,
          'name': createdDef.name,
          'status': 'created'
        });
        print('✅ Created behavior definition: ${createdDef.name}');
      } catch (e) {
        print('❌ Failed to create behavior definition ${behavior['name']}: $e');
        createdBehaviors.add({
          'id': behavior['id'],
          'name': behavior['name'],
          'status': 'failed'
        });
      }
    }
    
    print('✅ Created ${createdBehaviors.length} behavior definitions');
    return createdBehaviors;
  }
  
  /// Get summary of the setup
  Map<String, dynamic> getSetupSummary() {
    return {
      'client': {
        'id': clientId,
        'name': clientName,
        'dateOfBirth': clientDob,
      },
      'programs': {
        'count': 8,
        'dataTypes': [
          'percentCorrect',
          'frequency',
          'taskAnalysis',
          'timeSampling',
          'rate',
          'ratingScale',
          'abcData',
          'duration'
        ],
        'phases': ['intervention'],
        'status': 'active'
      },
      'sessions': {
        'dateRange': '09/16/2025 to 10/15/2025',
        'frequency': 'Monday-Friday',
        'time': '09:00 AM',
        'serviceCode': serviceCode
      },
      'behaviors': {
        'count': 3,
        'categories': ['Challenging', 'Communication']
      }
    };
  }
}

/// Usage example:
/// 
/// ```dart
/// final fileMakerService = FileMakerService();
/// final setup = Client03626AABSetup(fileMakerService);
/// 
/// // Run the complete setup
/// final results = await setup.setupClient();
/// 
/// // Get summary
/// final summary = setup.getSetupSummary();
/// print('Setup completed: ${summary}');
/// ```
