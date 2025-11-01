import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:datasheets/models/session_record.dart';
import 'package:datasheets/models/visit.dart';
import 'package:datasheets/models/client.dart';
import 'package:datasheets/models/program_assignment.dart';
import 'package:datasheets/config/note_drafting_config.dart';
import 'package:datasheets/services/mcp_service.dart';
import 'package:datasheets/services/token_service.dart';

/// Service for generating clinical notes using AI
class NoteDraftingService {
  
  /// Build OpenAI-style chat messages for ABA/EMR note drafting
  static List<Map<String, String>> buildNoteDraftMessages({
    required SessionData session,
    String ragContext = '',
  }) {
    final system = NoteDraftingConfig.systemPrompt;

    final user = '''
Session Metadata:
- Provider: ${session.providerName}, NPI/ATYPICAL: ${session.npi}
- Client: ${session.clientName}, DOB: ${session.dob}
- Date: ${session.date}, Time: ${session.startTime}–${session.endTime} (${session.durationMinutes} min)
- Service: ${session.serviceName}, CPT: ${session.cpt}, Modifiers: ${session.modifiers.join(', ')}, POS: ${session.pos}
- Goals Targeted: ${session.goalsList.join('; ')}
- Behaviors Observed: ${session.behaviors}
- Interventions Used: ${session.interventions}
- Data Summary: ${session.dataSummary}
- Caregiver Involvement: ${session.caregiver}
- Plan/Next Steps: ${session.plan}

Context (templates/payer rules/exemplars):
${ragContext.isEmpty ? NoteDraftingConfig.defaultRagContext : ragContext}

Instruction:
Generate a structured clinical session note following this format:
- Session Summary: One paragraph describing who conducted the session, duration, service type, and overall engagement
- Goals Targeted: List the specific goals/programs addressed
- Interventions: Describe the interventions and teaching strategies used
- Data Collected: Summarize the data collected during the session
- Caregiver Involvement: Note parent/caregiver participation and observations
- Plan: Outline next steps and program modifications

Keep it factual, professional, and payer-appropriate. Do not include PHI beyond what is provided.
'''.trim();

    return [
      {'role': 'system', 'content': system},
      {'role': 'user', 'content': user},
    ];
  }

  /// Generate note draft from session data
  /// Uses MCP API if available, falls back to direct API call
  static Future<String> generateNoteDraft({
    required SessionData session,
    String ragContext = '',
    String? apiKey,
    String? visitId,
    String? assignmentId,
    bool useMCP = true, // Use MCP by default if token is available
  }) async {
    try {
      // Try MCP API first if enabled and token is available
      if (useMCP) {
        final sanctumToken = await TokenService.getSanctumToken();
        if (sanctumToken != null && sanctumToken.isNotEmpty) {
          try {
            print('🔄 Using MCP API for note generation...');
            final mcpService = MCPService(token: sanctumToken);
            
            // Build messages in OpenAI format
            final messages = buildNoteDraftMessages(session: session, ragContext: ragContext);
            
            // Use MCP completions endpoint with context
            final response = await mcpService.completions(
              messages: messages,
              visitId: visitId,
              assignmentId: assignmentId,
              model: NoteDraftingConfig.model,
              temperature: NoteDraftingConfig.temperature,
              maxTokens: NoteDraftingConfig.maxTokens,
              stream: false,
            );
            
            if (response['success'] == true && response['response'] != null) {
              final completionData = response['response'];
              if (completionData['choices'] != null && completionData['choices'].isNotEmpty) {
                final content = completionData['choices'][0]['message']['content'];
                if (content != null) {
                  print('✅ Note generated successfully via MCP API');
                  return content;
                }
              }
            }
            print('⚠️ MCP API response format unexpected, falling back to direct API');
          } catch (e) {
            print('⚠️ MCP API failed, falling back to direct API: $e');
            // Fall through to direct API call
          }
        } else {
          print('⚠️ No Sanctum token available, using direct API');
        }
      }
      
      // Fallback to direct API call
      print('🔄 Using direct API for note generation...');
      final messages = buildNoteDraftMessages(session: session, ragContext: ragContext);
      final configApiKey = apiKey ?? NoteDraftingConfig.getApiKey();
      
      if (configApiKey == null) {
        throw Exception('API key not configured. Please set NoteDraftingConfig.apiKey or pass apiKey parameter.');
      }
      
      final response = await http.post(
        Uri.parse(NoteDraftingConfig.getApiUrl()),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $configApiKey',
        },
        body: jsonEncode({
          'model': NoteDraftingConfig.model,
          'messages': messages,
          'stream': false,
          'temperature': NoteDraftingConfig.temperature,
          'max_tokens': NoteDraftingConfig.maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'Note generation failed';
      } else {
        throw Exception('API request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating note draft: $e');
    }
  }

  /// Generate note draft with streaming
  static Stream<String> generateNoteDraftStream({
    required SessionData session,
    String ragContext = '',
    String? apiKey,
  }) async* {
    try {
      final messages = buildNoteDraftMessages(session: session, ragContext: ragContext);
      final configApiKey = apiKey ?? NoteDraftingConfig.getApiKey();
      
      if (configApiKey == null) {
        throw Exception('API key not configured. Please set NoteDraftingConfig.apiKey or pass apiKey parameter.');
      }
      
      final request = http.Request('POST', Uri.parse(NoteDraftingConfig.getApiUrl()));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $configApiKey',
      });
      request.body = jsonEncode({
        'model': NoteDraftingConfig.model,
        'messages': messages,
        'stream': true,
        'temperature': NoteDraftingConfig.temperature,
        'max_tokens': NoteDraftingConfig.maxTokens,
      });

      final streamedResponse = await request.send();
      
      if (streamedResponse.statusCode == 200) {
        await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (data == '[DONE]') break;
              
              try {
                final json = jsonDecode(data);
                final content = json['choices']?[0]?['delta']?['content'];
                if (content != null) {
                  yield content;
                }
              } catch (e) {
                // Skip invalid JSON lines
                continue;
              }
            }
          }
        }
      } else {
        throw Exception('Streaming request failed: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating streaming note draft: $e');
    }
  }

  /// Convert session records to SessionData for note generation
  static SessionData convertSessionRecordsToSessionData({
    required Visit visit,
    required Client client,
    required List<SessionRecord> sessionRecords,
    required List<ProgramAssignment> assignments,
    required String providerName,
    required String npi,
    String? apiKey,
  }) {
    // Extract unique goals from assignments that have session records
    // Only include goals/programs that have actual session data
    final assignmentIdsWithData = sessionRecords
        .map((r) => r.assignmentId)
        .where((id) => id.isNotEmpty)
        .toSet();
    
    final goalsSet = <String>{};
    for (final assignment in assignments) {
      // Only include if it has session data OR if no session records exist (show all active assignments)
      if (sessionRecords.isEmpty || 
          (assignment.id != null && assignmentIdsWithData.contains(assignment.id))) {
        goalsSet.add(assignment.displayName);
      }
    }
    final goalsList = goalsSet.toList()..sort();
    
    // Create map of assignmentId to assignment name for data summary
    final assignmentMap = <String, String>{};
    for (final assignment in assignments) {
      if (assignment.id != null) {
        assignmentMap[assignment.id!] = assignment.displayName;
      }
    }
    
    // Generate data summary from session records with assignment names
    final dataSummary = _generateDataSummary(sessionRecords, assignmentMap);
    
    // Generate behaviors summary
    final behaviors = _generateBehaviorsSummary(sessionRecords);
    
    // Generate interventions summary from session records and assignments
    final interventions = _generateInterventionsSummary(sessionRecords, assignments);
    
    // Generate caregiver involvement (placeholder)
    final caregiver = 'Parent observed and participated in session';
    
    // Generate plan/next steps
    final plan = _generatePlanFromRecords(sessionRecords, assignments);
    
    // Format date as MM/DD/YYYY
    String formattedDate;
    if (visit.appointmentDate != null && visit.appointmentDate!.isNotEmpty) {
      // If appointmentDate is already in MM/DD/YYYY format, use it
      if (visit.appointmentDate!.contains('/')) {
        formattedDate = visit.appointmentDate!;
      } else {
        // Convert from YYYY-MM-DD to MM/DD/YYYY
        try {
          final dateTime = DateTime.parse(visit.appointmentDate!);
          formattedDate = _formatDate(dateTime);
        } catch (e) {
          formattedDate = visit.appointmentDate!;
        }
      }
    } else {
      formattedDate = _formatDate(visit.startTs);
    }
    
    // Format DOB as MM/DD/YYYY if provided
    String formattedDob = 'Not provided';
    if (client.dateOfBirth != null && client.dateOfBirth!.isNotEmpty) {
      if (client.dateOfBirth!.contains('/')) {
        formattedDob = client.dateOfBirth!;
      } else {
        try {
          final dateTime = DateTime.parse(client.dateOfBirth!);
          formattedDob = _formatDate(dateTime);
        } catch (e) {
          formattedDob = client.dateOfBirth!;
        }
      }
    }
    
    return SessionData(
      providerName: providerName,
      npi: npi,
      clientName: client.name,
      dob: formattedDob,
      date: formattedDate,
      startTime: visit.timeIn?.isNotEmpty == true ? visit.timeIn! : _formatTime(visit.startTs),
      endTime: visit.endTs != null ? _formatTime(visit.endTs!) : 'Not provided',
      durationMinutes: _calculateDurationMinutes(visit),
      serviceName: visit.serviceCode,
      cpt: '97153', // Default CPT code
      modifiers: ['UC'], // Default modifier
      pos: '11', // Office/Outpatient
      goalsList: goalsList,
      behaviors: behaviors,
      interventions: interventions,
      dataSummary: dataSummary,
      caregiver: caregiver,
      plan: plan,
    );
  }

  /// Generate data summary from session records with assignment names
  static String _generateDataSummary(List<SessionRecord> records, Map<String, String> assignmentMap) {
    if (records.isEmpty) return 'No data collected';
    
    final summaries = <String>[];
    
    for (final record in records) {
      final payload = record.payload;
      final dataType = payload['dataType'] as String? ?? payload['data_type'] as String?;
      
      // Get assignment name from map, fallback to ID if not found
      final assignmentName = assignmentMap[record.assignmentId] ?? record.assignmentId;
      
      switch (dataType) {
        case 'percentCorrect':
          final hits = payload['hits'] as int? ?? 0;
          final totalTrials = payload['totalTrials'] as int? ?? 0;
          final percentage = payload['percentage'] as double? ?? 0.0;
          if (totalTrials > 0) {
            summaries.add('$assignmentName: $hits/$totalTrials trials (${percentage.toStringAsFixed(1)}% accuracy)');
          } else {
            summaries.add('$assignmentName: Percent correct data collected');
          }
          break;
        case 'frequency':
          final count = payload['count'] as int? ?? 0;
          final rate = payload['rate'] as double? ?? 0.0;
          summaries.add('$assignmentName: $count occurrences (rate: ${rate.toStringAsFixed(2)}/min)');
          break;
        case 'duration':
          final duration = payload['duration'] as double? ?? payload['minutes'] as double? ?? 0.0;
          if (duration > 0) {
            summaries.add('$assignmentName: ${duration.toStringAsFixed(1)} minutes duration');
          } else {
            summaries.add('$assignmentName: Duration data collected');
          }
          break;
        case 'rate':
          final events = payload['events'] as int? ?? 0;
          final rate = payload['rate'] as double? ?? 0.0;
          summaries.add('$assignmentName: $events events (rate: ${rate.toStringAsFixed(2)}/min)');
          break;
        case 'taskAnalysis':
          final completedCount = payload['completedCount'] as int? ?? 0;
          final totalSteps = payload['totalSteps'] as int? ?? 0;
          final percentage = payload['percentage'] as double? ?? 0.0;
          if (totalSteps > 0) {
            summaries.add('$assignmentName: $completedCount/$totalSteps steps (${percentage.toStringAsFixed(1)}% completion)');
          } else {
            summaries.add('$assignmentName: Task analysis data collected');
          }
          break;
        case 'timeSampling':
          final onTaskIntervals = payload['onTaskIntervals'] as int? ?? 0;
          final intervals = payload['intervals'] as int? ?? 0;
          final percentage = payload['percentage'] as double? ?? 0.0;
          if (intervals > 0) {
            summaries.add('$assignmentName: $onTaskIntervals/$intervals intervals on-task (${percentage.toStringAsFixed(1)}%)');
          } else {
            summaries.add('$assignmentName: Time sampling data collected');
          }
          break;
        case 'ratingScale':
          final rating = payload['rating'] as double? ?? 0.0;
          final maxRating = payload['maxRating'] as double? ?? 0.0;
          if (maxRating > 0) {
            summaries.add('$assignmentName: $rating/$maxRating rating');
          } else {
            summaries.add('$assignmentName: Rating scale data collected');
          }
          break;
        case 'abcData':
          final incidentCount = payload['incidentCount'] as int? ?? payload['incidents']?.length ?? 0;
          summaries.add('$assignmentName: $incidentCount behavior incident(s) recorded');
          break;
        default:
          summaries.add('$assignmentName: Data collected');
      }
    }
    
    return summaries.isEmpty ? 'Data was collected during the session' : summaries.join('; ');
  }

  /// Generate behaviors summary from session records
  static String _generateBehaviorsSummary(List<SessionRecord> records) {
    final behaviors = <String>[];
    
    for (final record in records) {
      final payload = record.payload;
      
      if (payload['dataType'] == 'abcData') {
        final incidents = payload['incidents'] as List<dynamic>? ?? [];
        for (final incident in incidents) {
          final behavior = incident['behavior'] as String?;
          if (behavior != null) {
            behaviors.add(behavior);
          }
        }
      }
    }
    
    if (behaviors.isEmpty) {
      return 'Client was cooperative and engaged throughout session';
    }
    
    return 'Observed behaviors: ${behaviors.join(', ')}';
  }

  /// Generate interventions summary from session records and assignments
  static String _generateInterventionsSummary(List<SessionRecord> records, List<ProgramAssignment> assignments) {
    final interventions = <String>[];
    final usedInterventions = <String>{};
    
    // Create map of assignmentId to assignment for reference
    final assignmentMap = <String, ProgramAssignment>{};
    for (final assignment in assignments) {
      if (assignment.id != null) {
        assignmentMap[assignment.id!] = assignment;
      }
    }
    
    // Add specific interventions based on data types and assignments
    for (final record in records) {
      final payload = record.payload;
      final dataType = payload['dataType'] as String? ?? payload['data_type'] as String?;
      final assignment = assignmentMap[record.assignmentId];
      final assignmentName = assignment?.displayName ?? record.assignmentId;
      
      String? intervention;
      switch (dataType) {
        case 'percentCorrect':
          intervention = 'Discrete trial training (DTT) with systematic prompting for $assignmentName';
          break;
        case 'frequency':
          intervention = 'Differential reinforcement procedures for $assignmentName';
          break;
        case 'duration':
          intervention = 'Independent activity engagement training for $assignmentName';
          break;
        case 'rate':
          intervention = 'Communication training and functional communication training (FCT)';
          break;
        case 'taskAnalysis':
          intervention = 'Task analysis with chaining procedures for $assignmentName';
          break;
        case 'timeSampling':
          intervention = 'On-task behavior reinforcement and attention training';
          break;
        case 'ratingScale':
          intervention = 'Social skills training and social interaction protocols';
          break;
        case 'abcData':
          intervention = 'Behavior management strategies and antecedent-based interventions';
          break;
      }
      
      if (intervention != null && !usedInterventions.contains(intervention)) {
        interventions.add(intervention);
        usedInterventions.add(intervention);
      }
    }
    
    if (interventions.isEmpty) {
      return 'Standard ABA interventions were implemented, including discrete trial training, natural environment teaching, and behavior management strategies as appropriate for each program goal';
    }
    
    return interventions.join('; ');
  }

  /// Generate plan from session records and assignments
  static String _generatePlanFromRecords(List<SessionRecord> records, List<ProgramAssignment> assignments) {
    final plans = <String>[];
    
    for (final record in records) {
      final payload = record.payload;
      final percentage = payload['percentage'] as double? ?? 0.0;
      
      if (percentage >= 80) {
        plans.add('Continue current program with maintenance phase');
      } else if (percentage >= 60) {
        plans.add('Continue current program with increased complexity');
      } else {
        plans.add('Review and adjust current program strategies');
      }
    }
    
    if (plans.isEmpty) {
      return 'Continue current programming based on data analysis';
    }
    
    return plans.join('; ');
  }

  /// Calculate session duration in minutes
  static int _calculateDurationMinutes(Visit visit) {
    if (visit.endTs != null) {
      return visit.endTs!.difference(visit.startTs).inMinutes;
    }
    return 60; // Default 60 minutes
  }
  
  /// Format DateTime to time string (HH:MM)
  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  /// Format DateTime to date string (MM/DD/YYYY)
  static String _formatDate(DateTime dateTime) {
    return '${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}/${dateTime.year}';
  }
}

/// Minimal container for session fields
class SessionData {
  final String providerName;
  final String npi;                 // "ATYPICAL" or NPI number
  final String clientName;          // Use initials if needed for PHI policy
  final String dob;                 // e.g., 2015-04-12
  final String date;                // e.g., 2025-10-18
  final String startTime;           // e.g., 14:00
  final String endTime;             // e.g., 15:00
  final int durationMinutes;        // e.g., 60
  final String serviceName;         // e.g., "Adaptive Behavior Treatment"
  final String cpt;                 // e.g., "97153"
  final List<String> modifiers;     // e.g., ["UC"]
  final String pos;                 // Place of Service, e.g., "11"
  final List<String> goalsList;     // e.g., ["manding", "task compliance"]
  final String behaviors;           // narrative
  final String interventions;       // narrative
  final String dataSummary;         // e.g., "90% independence; 2 prompts"
  final String caregiver;           // e.g., "Parent observed and participated"
  final String plan;                // e.g., "Increase task complexity next session"

  SessionData({
    required this.providerName,
    required this.npi,
    required this.clientName,
    required this.dob,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.serviceName,
    required this.cpt,
    required this.modifiers,
    required this.pos,
    required this.goalsList,
    required this.behaviors,
    required this.interventions,
    required this.dataSummary,
    required this.caregiver,
    required this.plan,
  });
}
