import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:datasheets/models/session_record.dart';
import 'package:datasheets/models/visit.dart';
import 'package:datasheets/models/client.dart';
import 'package:datasheets/models/program_assignment.dart';
import 'package:datasheets/config/note_drafting_config.dart';

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
Stream a clear, one-paragraph summary suitable for the session note preview.
Keep it factual and concise (2–4 sentences). Do not include PHI beyond what is provided.
'''.trim();

    return [
      {'role': 'system', 'content': system},
      {'role': 'user', 'content': user},
    ];
  }

  /// Generate note draft from session data
  static Future<String> generateNoteDraft({
    required SessionData session,
    String ragContext = '',
    String? apiKey,
  }) async {
    try {
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
    // Extract goals from assignments
    final goalsList = assignments.map((a) => a.displayName).toList();
    
    // Generate data summary from session records
    final dataSummary = _generateDataSummary(sessionRecords);
    
    // Generate behaviors summary
    final behaviors = _generateBehaviorsSummary(sessionRecords);
    
    // Generate interventions summary
    final interventions = _generateInterventionsSummary(sessionRecords);
    
    // Generate caregiver involvement (placeholder)
    final caregiver = 'Parent observed and participated in session';
    
    // Generate plan/next steps
    final plan = _generatePlanFromRecords(sessionRecords, assignments);
    
    return SessionData(
      providerName: providerName,
      npi: npi,
      clientName: client.name,
      dob: client.dateOfBirth ?? 'Not provided',
      date: visit.appointmentDate ?? DateTime.now().toIso8601String().split('T')[0],
      startTime: visit.timeIn ?? 'Not provided',
      endTime: visit.endTs?.toIso8601String().split('T')[1].substring(0, 5) ?? 'Not provided',
      durationMinutes: _calculateDurationMinutes(visit),
      serviceName: visit.serviceCode ?? 'Adaptive Behavior Treatment',
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

  /// Generate data summary from session records
  static String _generateDataSummary(List<SessionRecord> records) {
    if (records.isEmpty) return 'No data collected';
    
    final summaries = <String>[];
    
    for (final record in records) {
      final payload = record.payload;
      final dataType = payload['dataType'] as String?;
      
      switch (dataType) {
        case 'percentCorrect':
          final hits = payload['hits'] as int? ?? 0;
          final totalTrials = payload['totalTrials'] as int? ?? 0;
          final percentage = payload['percentage'] as double? ?? 0.0;
          summaries.add('${record.assignmentId}: $hits/$totalTrials trials ($percentage% accuracy)');
          break;
        case 'frequency':
          final count = payload['count'] as int? ?? 0;
          final rate = payload['rate'] as double? ?? 0.0;
          summaries.add('${record.assignmentId}: $count occurrences (rate: $rate/min)');
          break;
        case 'duration':
          final duration = payload['duration'] as double? ?? 0.0;
          summaries.add('${record.assignmentId}: ${duration}min duration');
          break;
        case 'rate':
          final events = payload['events'] as int? ?? 0;
          final rate = payload['rate'] as double? ?? 0.0;
          summaries.add('${record.assignmentId}: $events events (rate: $rate/min)');
          break;
        case 'taskAnalysis':
          final completedCount = payload['completedCount'] as int? ?? 0;
          final totalSteps = payload['totalSteps'] as int? ?? 0;
          final percentage = payload['percentage'] as double? ?? 0.0;
          summaries.add('${record.assignmentId}: $completedCount/$totalSteps steps ($percentage% completion)');
          break;
        case 'timeSampling':
          final onTaskIntervals = payload['onTaskIntervals'] as int? ?? 0;
          final intervals = payload['intervals'] as int? ?? 0;
          final percentage = payload['percentage'] as double? ?? 0.0;
          summaries.add('${record.assignmentId}: $onTaskIntervals/$intervals intervals on-task ($percentage%)');
          break;
        case 'ratingScale':
          final rating = payload['rating'] as double? ?? 0.0;
          final maxRating = payload['maxRating'] as double? ?? 0.0;
          summaries.add('${record.assignmentId}: $rating/$maxRating rating');
          break;
        case 'abcData':
          final incidentCount = payload['incidentCount'] as int? ?? 0;
          summaries.add('${record.assignmentId}: $incidentCount incidents recorded');
          break;
        default:
          summaries.add('${record.assignmentId}: Data collected');
      }
    }
    
    return summaries.join('; ');
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

  /// Generate interventions summary from session records
  static String _generateInterventionsSummary(List<SessionRecord> records) {
    final interventions = <String>[];
    
    // Add common interventions based on data types
    for (final record in records) {
      final payload = record.payload;
      final dataType = payload['dataType'] as String?;
      
      switch (dataType) {
        case 'percentCorrect':
          interventions.add('Discrete trial training with prompting');
          break;
        case 'frequency':
          interventions.add('Differential reinforcement');
          break;
        case 'duration':
          interventions.add('Independent activity engagement');
          break;
        case 'rate':
          interventions.add('Communication training');
          break;
        case 'taskAnalysis':
          interventions.add('Task analysis with step-by-step instruction');
          break;
        case 'timeSampling':
          interventions.add('On-task behavior reinforcement');
          break;
        case 'ratingScale':
          interventions.add('Social skills training');
          break;
        case 'abcData':
          interventions.add('Behavior management strategies');
          break;
      }
    }
    
    if (interventions.isEmpty) {
      return 'Standard ABA interventions implemented';
    }
    
    return 'Interventions used: ${interventions.join(', ')}';
  }

  /// Generate plan from session records and assignments
  static String _generatePlanFromRecords(List<SessionRecord> records, List<ProgramAssignment> assignments) {
    final plans = <String>[];
    
    for (final record in records) {
      final payload = record.payload;
      final dataType = payload['dataType'] as String?;
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
