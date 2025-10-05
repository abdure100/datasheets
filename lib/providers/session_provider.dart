import 'package:flutter/foundation.dart';
import '../models/visit.dart';
import '../models/client.dart';
import '../models/program_assignment.dart';
import '../models/session_record.dart';
import '../models/behavior_log.dart';
import '../models/behavior_definition.dart';

class SessionProvider extends ChangeNotifier {
  Visit? _currentVisit;
  Client? _currentClient;
  List<ProgramAssignment> _activeAssignments = [];
  final List<SessionRecord> _sessionRecords = [];
  final List<BehaviorLog> _behaviorLogs = [];
  List<BehaviorDefinition> _behaviorDefinitions = [];
  final Map<String, Map<String, dynamic>> _programData = {};

  Visit? get currentVisit => _currentVisit;
  Client? get currentClient => _currentClient;
  List<ProgramAssignment> get activeAssignments => _activeAssignments;
  List<SessionRecord> get sessionRecords => _sessionRecords;
  List<BehaviorLog> get behaviorLogs => _behaviorLogs;
  List<BehaviorDefinition> get behaviorDefinitions => _behaviorDefinitions;

  Map<String, dynamic> getProgramData(String assignmentId) {
    return _programData[assignmentId] ?? {};
  }

  void setProgramData(String assignmentId, Map<String, dynamic> data) {
    _programData[assignmentId] = data;
    notifyListeners();
  }

  void startVisit(Visit visit, Client client) {
    _currentVisit = visit;
    _currentClient = client;
    _sessionRecords.clear();
    _behaviorLogs.clear();
    _programData.clear();
    notifyListeners();
  }

  void endVisit() {
    _currentVisit = null;
    _currentClient = null;
    _activeAssignments.clear();
    _sessionRecords.clear();
    _behaviorLogs.clear();
    _programData.clear();
    notifyListeners();
  }

  void setActiveAssignments(List<ProgramAssignment> assignments) {
    _activeAssignments = assignments.where((a) => a.isActive).toList();
    notifyListeners();
  }

  void addSessionRecord(SessionRecord record) {
    _sessionRecords.add(record);
    notifyListeners();
  }

  void updateSessionRecord(SessionRecord record) {
    final index = _sessionRecords.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _sessionRecords[index] = record;
      notifyListeners();
    }
  }

  void addBehaviorLog(BehaviorLog log) {
    _behaviorLogs.add(log);
    notifyListeners();
  }

  void updateBehaviorLog(BehaviorLog log) {
    final index = _behaviorLogs.indexWhere((l) => l.id == log.id);
    if (index != -1) {
      _behaviorLogs[index] = log;
      notifyListeners();
    }
  }

  void setBehaviorDefinitions(List<BehaviorDefinition> definitions) {
    _behaviorDefinitions = definitions;
    notifyListeners();
  }

  List<SessionRecord> getSessionRecordsForAssignment(String assignmentId) {
    return _sessionRecords.where((r) => r.assignmentId == assignmentId).toList();
  }

  Map<String, dynamic> getSessionTotalsForAssignment(String assignmentId) {
    final records = getSessionRecordsForAssignment(assignmentId);
    if (records.isEmpty) return {};

    final dataType = _activeAssignments
        .firstWhere((a) => a.id == assignmentId, orElse: () => throw Exception('Assignment not found'))
        .dataType;

    switch (dataType) {
      case 'percentCorrect':
      case 'percentIndependent':
        final totalTrials = records.fold<int>(0, (sum, r) => sum + ((r.payload['total'] ?? 0) as int));
        final totalHits = records.fold<int>(0, (sum, r) => sum + ((r.payload['hits'] ?? 0) as int));
        return {
          'totalTrials': totalTrials,
          'totalHits': totalHits,
          'overallPercent': totalTrials > 0 ? (totalHits / totalTrials * 100).round() : 0,
        };
      
      case 'frequency':
        final totalCount = records.fold<int>(0, (sum, r) => sum + ((r.payload['count'] ?? 0) as int));
        return {'totalCount': totalCount};
      
      case 'duration':
        final totalSeconds = records.fold<int>(0, (sum, r) => sum + ((r.payload['seconds'] ?? 0) as int));
        return {
          'totalSeconds': totalSeconds,
          'totalMinutes': (totalSeconds / 60).round(),
        };
      
      case 'rate':
        final totalCount = records.fold<int>(0, (sum, r) => sum + ((r.payload['count'] ?? 0) as int));
        final totalSeconds = records.fold<int>(0, (sum, r) => sum + ((r.payload['seconds'] ?? 0) as int));
        return {
          'totalCount': totalCount,
          'totalSeconds': totalSeconds,
          'overallRate': totalSeconds > 0 ? (totalCount / (totalSeconds / 60)).round() : 0,
        };
      
      case 'taskAnalysis':
        final totalSteps = records.fold<int>(0, (sum, r) => sum + ((r.payload['steps']?.length ?? 0) as int));
        final completedSteps = records.fold<int>(0, (sum, r) {
          final steps = r.payload['steps'] as List? ?? [];
          return sum + steps.where((s) => s == true).length;
        });
        return {
          'totalSteps': totalSteps,
          'completedSteps': completedSteps,
          'overallPercent': totalSteps > 0 ? (completedSteps / totalSteps * 100).round() : 0,
        };
      
      case 'timeSampling':
        final totalSamples = records.fold<int>(0, (sum, r) => sum + ((r.payload['samples']?.length ?? 0) as int));
        final onTaskSamples = records.fold<int>(0, (sum, r) {
          final samples = r.payload['samples'] as List? ?? [];
          return sum + samples.where((s) => s == true).length;
        });
        return {
          'totalSamples': totalSamples,
          'onTaskSamples': onTaskSamples,
          'overallPercent': totalSamples > 0 ? (onTaskSamples / totalSamples * 100).round() : 0,
        };
      
      case 'ratingScale':
        final ratings = records.map((r) => (r.payload['rating'] as int? ?? 0)).toList();
        final avgRating = ratings.isNotEmpty ? ratings.reduce((a, b) => a + b) / ratings.length : 0;
        return {
          'ratings': ratings,
          'averageRating': avgRating.round(),
        };
      
      default:
        return {};
    }
  }
}
