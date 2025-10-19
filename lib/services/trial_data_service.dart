import 'package:datasheets/services/filemaker_service.dart';
import 'package:datasheets/models/session_record.dart';

/// Service for handling trial data operations with FileMaker
class TrialDataService {
  final FileMakerService _fileMakerService;
  
  TrialDataService(this._fileMakerService);
  
  /// Save trial data for a specific program assignment
  Future<SessionRecord> saveTrialData({
    required String visitId,
    required String clientId,
    required String assignmentId,
    required String staffId,
    required String interventionPhase,
    required Map<String, dynamic> trialData,
    String? notes,
    DateTime? programStartTime,
    DateTime? programEndTime,
  }) async {
    print('💾 Saving trial data for assignment: $assignmentId');
    
    try {
      // Create the session record with trial data
      final sessionRecord = SessionRecord(
        id: '', // Will be set by FileMaker
        visitId: visitId,
        clientId: clientId,
        assignmentId: assignmentId,
        startedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        payload: trialData,
        notes: notes,
        staffId: staffId,
        interventionPhase: interventionPhase,
        programStartTime: programStartTime,
        programEndTime: programEndTime,
      );
      
      // Save to FileMaker using upsert (create or update)
      final savedRecord = await _fileMakerService.upsertSessionRecord(sessionRecord);
      
      print('✅ Trial data saved successfully: ${savedRecord.id}');
      return savedRecord;
      
    } catch (e) {
      print('❌ Error saving trial data: $e');
      rethrow;
    }
  }
  
  /// Save percent correct/independent trial data
  Future<SessionRecord> savePercentCorrectTrial({
    required String visitId,
    required String clientId,
    required String assignmentId,
    required String staffId,
    required String interventionPhase,
    required int hits,
    required int totalTrials,
    required int independent,
    required int prompted,
    required int incorrect,
    required int noResponse,
    String? notes,
    DateTime? programStartTime,
    DateTime? programEndTime,
  }) async {
    final trialData = {
      'dataType': 'percentCorrect',
      'hits': hits,
      'totalTrials': totalTrials,
      'independent': independent,
      'prompted': prompted,
      'incorrect': incorrect,
      'noResponse': noResponse,
      'percentage': totalTrials > 0 ? (hits / totalTrials * 100).roundToDouble() : 0.0,
      'independentPercentage': totalTrials > 0 ? (independent / totalTrials * 100).roundToDouble() : 0.0,
      'timestamp': DateTime.now().toIso8601String(),
      'sessionEnded': true,
    };
    
    return await saveTrialData(
      visitId: visitId,
      clientId: clientId,
      assignmentId: assignmentId,
      staffId: staffId,
      interventionPhase: interventionPhase,
      trialData: trialData,
      notes: notes,
      programStartTime: programStartTime,
      programEndTime: programEndTime,
    );
  }
  
  /// Save frequency counting trial data
  Future<SessionRecord> saveFrequencyTrial({
    required String visitId,
    required String clientId,
    required String assignmentId,
    required String staffId,
    required String interventionPhase,
    required int count,
    required int sessionDuration, // in minutes
    String? notes,
    DateTime? programStartTime,
    DateTime? programEndTime,
  }) async {
    final trialData = {
      'dataType': 'frequency',
      'count': count,
      'sessionDuration': sessionDuration,
      'rate': sessionDuration > 0 ? (count / sessionDuration).roundToDouble() : 0.0,
      'timestamp': DateTime.now().toIso8601String(),
      'sessionEnded': true,
    };
    
    return await saveTrialData(
      visitId: visitId,
      clientId: clientId,
      assignmentId: assignmentId,
      staffId: staffId,
      interventionPhase: interventionPhase,
      trialData: trialData,
      notes: notes,
      programStartTime: programStartTime,
      programEndTime: programEndTime,
    );
  }
  
  /// Save duration timing trial data
  Future<SessionRecord> saveDurationTrial({
    required String visitId,
    required String clientId,
    required String assignmentId,
    required String staffId,
    required String interventionPhase,
    required double duration, // in minutes
    required String activity,
    String? notes,
    DateTime? programStartTime,
    DateTime? programEndTime,
  }) async {
    final trialData = {
      'dataType': 'duration',
      'duration': duration,
      'activity': activity,
      'timestamp': DateTime.now().toIso8601String(),
      'sessionEnded': true,
    };
    
    return await saveTrialData(
      visitId: visitId,
      clientId: clientId,
      assignmentId: assignmentId,
      staffId: staffId,
      interventionPhase: interventionPhase,
      trialData: trialData,
      notes: notes,
      programStartTime: programStartTime,
      programEndTime: programEndTime,
    );
  }
  
  /// Save rate calculation trial data
  Future<SessionRecord> saveRateTrial({
    required String visitId,
    required String clientId,
    required String assignmentId,
    required String staffId,
    required String interventionPhase,
    required int events,
    required double sessionDuration, // in minutes
    String? notes,
    DateTime? programStartTime,
    DateTime? programEndTime,
  }) async {
    final rate = sessionDuration > 0 ? (events / sessionDuration).roundToDouble() : 0.0;
    
    final trialData = {
      'dataType': 'rate',
      'events': events,
      'sessionDuration': sessionDuration,
      'rate': rate,
      'timestamp': DateTime.now().toIso8601String(),
      'sessionEnded': true,
    };
    
    return await saveTrialData(
      visitId: visitId,
      clientId: clientId,
      assignmentId: assignmentId,
      staffId: staffId,
      interventionPhase: interventionPhase,
      trialData: trialData,
      notes: notes,
      programStartTime: programStartTime,
      programEndTime: programEndTime,
    );
  }
  
  /// Save task analysis trial data
  Future<SessionRecord> saveTaskAnalysisTrial({
    required String visitId,
    required String clientId,
    required String assignmentId,
    required String staffId,
    required String interventionPhase,
    required List<String> steps,
    required List<bool> completedSteps,
    String? notes,
    DateTime? programStartTime,
    DateTime? programEndTime,
  }) async {
    final completedCount = completedSteps.where((step) => step).length;
    final totalSteps = steps.length;
    final percentage = totalSteps > 0 ? (completedCount / totalSteps * 100).roundToDouble() : 0.0;
    
    final trialData = {
      'dataType': 'taskAnalysis',
      'steps': steps,
      'completedSteps': completedSteps,
      'completedCount': completedCount,
      'totalSteps': totalSteps,
      'percentage': percentage,
      'timestamp': DateTime.now().toIso8601String(),
      'sessionEnded': true,
    };
    
    return await saveTrialData(
      visitId: visitId,
      clientId: clientId,
      assignmentId: assignmentId,
      staffId: staffId,
      interventionPhase: interventionPhase,
      trialData: trialData,
      notes: notes,
      programStartTime: programStartTime,
      programEndTime: programEndTime,
    );
  }
  
  /// Save time sampling trial data
  Future<SessionRecord> saveTimeSamplingTrial({
    required String visitId,
    required String clientId,
    required String assignmentId,
    required String staffId,
    required String interventionPhase,
    required int intervals,
    required int onTaskIntervals,
    required int intervalDuration, // in seconds
    String? notes,
    DateTime? programStartTime,
    DateTime? programEndTime,
  }) async {
    final percentage = intervals > 0 ? (onTaskIntervals / intervals * 100).roundToDouble() : 0.0;
    
    final trialData = {
      'dataType': 'timeSampling',
      'intervals': intervals,
      'onTaskIntervals': onTaskIntervals,
      'intervalDuration': intervalDuration,
      'percentage': percentage,
      'timestamp': DateTime.now().toIso8601String(),
      'sessionEnded': true,
    };
    
    return await saveTrialData(
      visitId: visitId,
      clientId: clientId,
      assignmentId: assignmentId,
      staffId: staffId,
      interventionPhase: interventionPhase,
      trialData: trialData,
      notes: notes,
      programStartTime: programStartTime,
      programEndTime: programEndTime,
    );
  }
  
  /// Save rating scale trial data
  Future<SessionRecord> saveRatingScaleTrial({
    required String visitId,
    required String clientId,
    required String assignmentId,
    required String staffId,
    required String interventionPhase,
    required double rating,
    required double maxRating,
    required String context,
    String? notes,
    DateTime? programStartTime,
    DateTime? programEndTime,
  }) async {
    final percentage = maxRating > 0 ? (rating / maxRating * 100).roundToDouble() : 0.0;
    
    final trialData = {
      'dataType': 'ratingScale',
      'rating': rating,
      'maxRating': maxRating,
      'percentage': percentage,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
      'sessionEnded': true,
    };
    
    return await saveTrialData(
      visitId: visitId,
      clientId: clientId,
      assignmentId: assignmentId,
      staffId: staffId,
      interventionPhase: interventionPhase,
      trialData: trialData,
      notes: notes,
      programStartTime: programStartTime,
      programEndTime: programEndTime,
    );
  }
  
  /// Save ABC data trial data
  Future<SessionRecord> saveABCDataTrial({
    required String visitId,
    required String clientId,
    required String assignmentId,
    required String staffId,
    required String interventionPhase,
    required List<Map<String, dynamic>> incidents,
    String? notes,
    DateTime? programStartTime,
    DateTime? programEndTime,
  }) async {
    final trialData = {
      'dataType': 'abcData',
      'incidents': incidents,
      'incidentCount': incidents.length,
      'timestamp': DateTime.now().toIso8601String(),
      'sessionEnded': true,
    };
    
    return await saveTrialData(
      visitId: visitId,
      clientId: clientId,
      assignmentId: assignmentId,
      staffId: staffId,
      interventionPhase: interventionPhase,
      trialData: trialData,
      notes: notes,
      programStartTime: programStartTime,
      programEndTime: programEndTime,
    );
  }
  
  /// Get trial data for a specific assignment
  Future<List<SessionRecord>> getTrialDataForAssignment({
    required String assignmentId,
    String? clientId,
    String? visitId,
  }) async {
    try {
      print('🔍 Getting trial data for assignment: $assignmentId');
      
      // This would need to be implemented in FileMakerService
      // For now, return empty list
      return [];
      
    } catch (e) {
      print('❌ Error getting trial data: $e');
      return [];
    }
  }
  
  /// Get trial data summary for a client
  Future<Map<String, dynamic>> getTrialDataSummary({
    required String clientId,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      print('📊 Getting trial data summary for client: $clientId');
      
      // This would need to be implemented in FileMakerService
      // For now, return empty summary
      return {
        'clientId': clientId,
        'totalSessions': 0,
        'dataTypes': [],
        'summary': 'No data available'
      };
      
    } catch (e) {
      print('❌ Error getting trial data summary: $e');
      return {
        'clientId': clientId,
        'error': e.toString()
      };
    }
  }
}
