import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/session_record.dart';
import '../models/visit.dart';
import '../models/client.dart';
import '../models/program_assignment.dart';
import '../config/note_drafting_config.dart';
import 'mcp_service.dart';
import 'token_service.dart';

/// Service for generating clinical notes using AI
class NoteDraftingService {
  
  /// Build OpenAI-style chat messages for ABA/EMR note drafting
  static List<Map<String, String>> buildNoteDraftMessages({
    required SessionData session,
    String ragContext = '',
  }) {
    final system = NoteDraftingConfig.systemPrompt;

    final user = '''
Visit Info:
- Visit ID: ${session.visitId}${session.company != null ? '\n- Company: ${session.company}' : ''}

Provider Info:
- Provider Name: ${session.providerName}
- Staff ID: ${session.staffId}
- Staff Title: ${session.staffTitle}
- NPI: ${session.npi}${session.staffRole != null ? '\n- Role: ${session.staffRole}' : ''}

Client Info:
- Client Name: ${session.clientName}
- Client ID: ${session.clientId}
- Date of Birth: ${session.dob}

Session Timing:
- Date: ${session.date}
- Start Time: ${session.startTime}
- End Time: ${session.endTime}
- Duration: ${session.durationMinutes} minutes

Service Information:
- Service Code: ${session.serviceName}
- CPT: ${session.cpt}
- Modifiers: ${session.modifiers.join(', ')}
- POS: ${session.pos}

Goals Targeted: ${session.goalsList.join('; ')}
Behaviors Observed: ${session.behaviors}
Interventions Used: ${session.interventions}
Data Summary: ${session.dataSummary}
Caregiver Involvement: ${session.caregiver}
Plan/Next Steps: ${session.plan}

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

  /// Build a single prompt string for the new generate-note endpoint
  /// Combines system prompt and user content into one prompt
  /// NOTE: Prompt must be <= 2000 characters per API validation
  static String buildNotePrompt({
    required SessionData session,
    String ragContext = '',
  }) {
    // Shortened system prompt
    final system = 'Clinical documentation assistant for ABA EMR. Generate concise, factual notes from provided data. Professional, payer-appropriate tone.';

    // Build concise user content
    final user = '''Visit: ${session.visitId} | Provider: ${session.providerName} (${session.staffTitle}) | Client: ${session.clientName} | Date: ${session.date} | Duration: ${session.durationMinutes} min | CPT: ${session.cpt}${session.modifiers.isNotEmpty ? ' | Modifiers: ${session.modifiers.join(', ')}' : ''}${session.pos.isNotEmpty ? ' | POS: ${session.pos}' : ''}

Goals: ${session.goalsList.isNotEmpty ? session.goalsList.join('; ') : 'None'}
Behaviors: ${session.behaviors.isNotEmpty ? session.behaviors : 'None'}
Interventions: ${session.interventions.isNotEmpty ? session.interventions : 'None'}
Data: ${session.dataSummary.isNotEmpty ? session.dataSummary : 'None'}
Caregiver: ${session.caregiver.isNotEmpty ? session.caregiver : 'None'}
Plan: ${session.plan.isNotEmpty ? session.plan : 'None'}

${ragContext.isNotEmpty ? 'Context: $ragContext\n' : ''}Generate structured note: Session Summary, Goals Targeted, Interventions, Data Collected, Caregiver Involvement, Plan.''';

    final prompt = '$system\n\n$user';
    
    // Log prompt length for debugging
    if (prompt.length > 2000) {
      print('⚠️ Prompt length: ${prompt.length} characters (exceeds 2000 limit)');
    }
    
    return prompt;
  }

  /// Analyze assignment data for a specific program
  /// Uses the new simplified /api/arawello/analyze endpoint
  static Future<String> analyzeAssignment({
    required String assignmentId,
    String? visitId,
    String ragContext = '',
    bool useMCP = true,
  }) async {
    try {
      if (useMCP) {
        final sanctumToken = await TokenService.getSanctumToken();
        if (sanctumToken != null && sanctumToken.isNotEmpty) {
          try {
            print('🔄 Using new analyze endpoint for program analysis...');
            final mcpService = MCPService(token: sanctumToken);
            
            // Use the new simplified analyze endpoint
            final response = await mcpService.analyzeProgram(
              programId: assignmentId,
            );
            
            if (response['success'] == true && response['analysis'] != null) {
              final analysis = response['analysis'] as Map<String, dynamic>;
              
              // Build a formatted response from the analysis data
              final StringBuffer formattedAnalysis = StringBuffer();
              
              // Add program name if available
              if (response['program_name'] != null) {
                formattedAnalysis.writeln('**${response['program_name']}**\n');
              }
              
              // Add performance analysis
              if (analysis['performance_analysis'] != null) {
                formattedAnalysis.writeln('## Performance Analysis');
                formattedAnalysis.writeln(analysis['performance_analysis']);
                formattedAnalysis.writeln();
              }
              
              // Add detailed analysis
              if (analysis['detailed_analysis'] != null) {
                formattedAnalysis.writeln('## Detailed Analysis');
                formattedAnalysis.writeln(analysis['detailed_analysis']);
                formattedAnalysis.writeln();
              } else if (analysis['analysis'] != null) {
                formattedAnalysis.writeln('## Analysis');
                formattedAnalysis.writeln(analysis['analysis']);
                formattedAnalysis.writeln();
              }
              
              // Add recommendations
              if (analysis['recommendations'] != null) {
                formattedAnalysis.writeln('## Recommendations');
                formattedAnalysis.writeln(analysis['recommendations']);
                formattedAnalysis.writeln();
              }
              
              // Add conclusion
              if (analysis['conclusion'] != null) {
                formattedAnalysis.writeln('## Conclusion');
                formattedAnalysis.writeln(analysis['conclusion']);
                formattedAnalysis.writeln();
              }
              
              // Add mastery status if available
              if (response['mastery_status'] != null) {
                final masteryStatus = response['mastery_status'] as Map<String, dynamic>;
                formattedAnalysis.writeln('## Mastery Status');
                if (masteryStatus['is_mastered'] == true) {
                  formattedAnalysis.writeln('✅ Program has achieved mastery criteria.');
                } else {
                  formattedAnalysis.writeln('⏳ Program is progressing toward mastery.');
                }
                if (masteryStatus['current_performance'] != null) {
                  formattedAnalysis.writeln('Current Performance: ${masteryStatus['current_performance']}%');
                }
                formattedAnalysis.writeln();
              }
              
              print('✅ Program analysis generated successfully via new analyze endpoint');
              return formattedAnalysis.toString().trim();
            }
            print('⚠️ Analyze endpoint response format unexpected');
            throw Exception('Unexpected response format from analyze endpoint');
          } catch (e) {
            print('❌ Analyze endpoint failed: $e');
            rethrow;
          }
        } else {
          throw Exception('No Sanctum token available for MCP API');
        }
      }
      throw Exception('MCP API not available');
    } catch (e) {
      print('❌ Error analyzing assignment: $e');
      rethrow;
    }
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
        print('🔵 Checking for Sanctum token...');
        final sanctumToken = await TokenService.getSanctumToken();
        print('🔵 Sanctum token check result: ${sanctumToken != null ? "found (${sanctumToken.length} chars)" : "null"}');
        
        if (sanctumToken != null && sanctumToken.isNotEmpty) {
          try {
            print('🔄 Using MCP API for note generation...');
            print('🔵 Creating MCPService instance...');
            final mcpService = MCPService(token: sanctumToken);
            print('✅ MCPService created');
            
            // Build prompt for new generate-note endpoint
            print('🔵 Building note prompt...');
            final prompt = buildNotePrompt(session: session, ragContext: ragContext);
            print('✅ Prompt built, length: ${prompt.length} characters');
            
            // Use new generate-note endpoint
            // visitId is required, clientId is optional
            if (visitId == null || visitId.isEmpty) {
              throw Exception('visitId is required for generate-note endpoint');
            }
            
            print('🔵 Calling mcpService.generateNote...');
            print('   - visitId: $visitId');
            print('   - clientId: ${session.clientId}');
            print('   - model: Qwen/Qwen2.5-7B-Instruct');
            
            final response = await mcpService.generateNote(
              prompt: prompt,
              visitId: visitId,
              clientId: session.clientId,
              model: 'Qwen/Qwen2.5-7B-Instruct',
              temperature: NoteDraftingConfig.temperature,
              maxTokens: NoteDraftingConfig.maxTokens,
            );
            
            print('✅ mcpService.generateNote returned');
            print('🔵 Response keys: ${response.keys.toList()}');
            print('🔵 Response success: ${response['success']}');
            print('🔵 Response has note: ${response.containsKey('note')}');
            
            if (response['success'] == true && response['note'] != null) {
              var note = response['note'] as String;
              
              // Replace model name attribution with just "Arawello AI"
              // Remove model names like (Meta-Llama-3.1-8B-Instruct) or (Qwen/Qwen2.5-7B-Instruct)
              note = note.replaceAll(RegExp(r'\(Meta-Llama[^)]+\)', caseSensitive: false), '');
              note = note.replaceAll(RegExp(r'\(Qwen[^)]+\)', caseSensitive: false), '');
              
              // Replace "Generated by Arawello AI" patterns with just "Arawello AI"
              note = note.replaceAll(RegExp(r'\*\*Generated by Arawello AI[^*]*\*\*', caseSensitive: false), '**Arawello AI**');
              note = note.replaceAll(RegExp(r'Generated by Arawello AI[^\n]*', caseSensitive: false), 'Arawello AI');
              
              // Clean up any double newlines or extra spaces left behind
              note = note.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
              
              print('✅ Note generated successfully via MCP generate-note endpoint');
              print('✅ Note length: ${note.length} characters (after cleanup)');
              return note;
            }
            print('⚠️ MCP API response format unexpected, falling back to direct API');
          } catch (e, stackTrace) {
            print('❌ MCP API failed with exception: $e');
            print('❌ Exception type: ${e.runtimeType}');
            print('❌ Stack trace: $stackTrace');
            print('⚠️ MCP API failed, falling back to direct API');
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
        var note = data['choices'][0]['message']['content'] ?? 'Note generation failed';
        
        // Replace model name attribution with just "Arawello AI"
        // Remove model names like (Meta-Llama-3.1-8B-Instruct) or (Qwen/Qwen2.5-7B-Instruct)
        note = note.replaceAll(RegExp(r'\(Meta-Llama[^)]+\)', caseSensitive: false), '');
        note = note.replaceAll(RegExp(r'\(Qwen[^)]+\)', caseSensitive: false), '');
        
        // Replace "Generated by Arawello AI" patterns with just "Arawello AI"
        note = note.replaceAll(RegExp(r'\*\*Generated by Arawello AI[^*]*\*\*', caseSensitive: false), '**Arawello AI**');
        note = note.replaceAll(RegExp(r'Generated by Arawello AI[^\n]*', caseSensitive: false), 'Arawello AI');
        note = note.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
        
        return note;
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
    String? providerName,
    String? npi,
    String? company,
    String? staffNpi,
    String? procedure,
    String? timeOut,
    String? modifier1,
    String? pos,
    String? staffRole,
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
    
    // Visit Info
    final visitId = visit.id;
    final visitCompany = company;
    
    // Provider Info - use visit fields first, fallback to provided values
    final providerNameFromVisit = visit.staffName?.isNotEmpty == true 
        ? visit.staffName! 
        : (providerName ?? 'Provider');
    final staffId = visit.staffId;
    final staffTitleFromVisit = visit.staffTitle?.isNotEmpty == true 
        ? visit.staffTitle! 
        : 'Therapist';
    final finalProviderName = staffTitleFromVisit.isNotEmpty
        ? '$providerNameFromVisit, $staffTitleFromVisit'
        : providerNameFromVisit;
    final finalNpi = staffNpi ?? npi ?? 'ATYPICAL';
    final finalStaffRole = staffRole;
    
    // Client Info
    final clientNameFromVisit = visit.clientName?.isNotEmpty == true 
        ? visit.clientName! 
        : client.name;
    final clientId = visit.clientId;
    
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
    
    // Session Timing
    // Date (MM/DD/YYYY from visit.Appointment_date or visit.startTs)
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
    
    // Start time (from visit.time_in or formatted from visit.startTs)
    final startTime = visit.timeIn?.isNotEmpty == true 
        ? visit.timeIn! 
        : _formatTime(visit.startTs);
    
    // End time (from visit.time_out or formatted from visit.endTs)
    String endTime;
    if (timeOut != null && timeOut.isNotEmpty) {
      endTime = timeOut;
    } else if (visit.endTs != null) {
      endTime = _formatTime(visit.endTs!);
      } else {
      endTime = 'Not provided';
    }
    
    final durationMinutes = _calculateDurationMinutes(visit);
    
    // Service Information
    // Service code (from visit.Procedure_input)
    final serviceNameFromVisit = visit.serviceCode;
    
    // CPT: "97153" (from visit.Procedure, fallback to default)
    final cptCode = procedure ?? '97153';
    
    // Modifiers: from visit.Modifier1, fallback to "UC"
    final modifiersList = modifier1 != null && modifier1.isNotEmpty 
        ? [modifier1] 
        : ['UC'];
    
    // POS: from visit.POS, fallback to "11"
    final posCode = pos ?? '11';
    
    return SessionData(
      visitId: visitId,
      company: visitCompany,
      providerName: finalProviderName,
      staffId: staffId,
      staffTitle: staffTitleFromVisit,
      npi: finalNpi,
      staffRole: finalStaffRole,
      clientName: clientNameFromVisit,
      clientId: clientId,
      dob: formattedDob,
      date: formattedDate,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      serviceName: serviceNameFromVisit,
      cpt: cptCode,
      modifiers: modifiersList,
      pos: posCode,
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
  // Visit Info
  final String visitId;
  final String? company;
  
  // Provider Info
  final String providerName;
  final String staffId;
  final String staffTitle;
  final String npi;                 // "ATYPICAL" or NPI number
  final String? staffRole;          // Staff role from visit.Staff_Role
  
  // Client Info
  final String clientName;          // Use initials if needed for PHI policy
  final String clientId;
  final String dob;                 // e.g., 2015-04-12
  
  // Session Timing
  final String date;                // e.g., 2025-10-18
  final String startTime;           // e.g., 14:00
  final String endTime;             // e.g., 15:00
  final int durationMinutes;        // e.g., 60
  
  // Service Information
  final String serviceName;         // e.g., "Adaptive Behavior Treatment"
  final String cpt;                 // e.g., "97153"
  final List<String> modifiers;     // e.g., ["UC"]
  final String pos;                 // Place of Service, e.g., "11"
  
  // Session Data
  final List<String> goalsList;     // e.g., ["manding", "task compliance"]
  final String behaviors;           // narrative
  final String interventions;       // narrative
  final String dataSummary;         // e.g., "90% independence; 2 prompts"
  final String caregiver;           // e.g., "Parent observed and participated"
  final String plan;                // e.g., "Increase task complexity next session"

  SessionData({
    required this.visitId,
    this.company,
    required this.providerName,
    required this.staffId,
    required this.staffTitle,
    required this.npi,
    this.staffRole,
    required this.clientName,
    required this.clientId,
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
