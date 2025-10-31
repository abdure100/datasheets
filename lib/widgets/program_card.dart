import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/program_assignment.dart';
import '../models/behavior_log.dart';
import '../providers/session_provider.dart';
import 'data_collection_widgets/trials_widget.dart';
import 'data_collection_widgets/frequency_widget.dart';
import 'data_collection_widgets/duration_widget.dart';
import 'data_collection_widgets/rate_widget.dart';
import 'data_collection_widgets/task_analysis_widget.dart';
import 'data_collection_widgets/time_sampling_widget.dart';
import 'data_collection_widgets/rating_scale_widget.dart';
import 'data_collection_widgets/abc_widget.dart';
import 'behavior_modal.dart';

class ProgramCard extends StatefulWidget {
  final ProgramAssignment assignment;
  final Function(Map<String, dynamic>) onSave;
  final String? visitId;
  final String? clientId;
  final Function(BehaviorLog)? onBehaviorLogged;

  const ProgramCard({
    super.key,
    required this.assignment,
    required this.onSave,
    this.visitId,
    this.clientId,
    this.onBehaviorLogged,
  });

  @override
  State<ProgramCard> createState() => _ProgramCardState();
}

class _ProgramCardState extends State<ProgramCard> {
  Map<String, dynamic> _currentData = {};
  bool _isSaving = false;
  Map<String, dynamic> _originalData = {};

  @override
  void initState() {
    super.initState();
    _currentData = Map<String, dynamic>.from(widget.assignment.config);
    _originalData = Map<String, dynamic>.from(widget.assignment.config);
  }

  Widget _buildDataCollectionWidget() {
    switch (widget.assignment.dataType) {
      case 'discrete_trial':
        return TrialsWidget(
          config: _currentData,
          onDataChanged: (data) {
            setState(() => _currentData = data);
            _autoSaveData(); // Automatically save when data changes
          },
        );
      
      // FileMaker: frequency
      case 'frequency':
        return FrequencyWidget(
          config: _currentData,
          onDataChanged: (data) {
            setState(() => _currentData = data);
            _autoSaveData(); // Automatically save when data changes
          },
        );
      
      // FileMaker: duration
      case 'duration':
        return DurationWidget(
          config: _currentData,
          onDataChanged: (data) {
            setState(() => _currentData = data);
            _autoSaveData(); // Automatically save when data changes
          },
        );
      
      // FileMaker: rate
      case 'rate':
        return RateWidget(
          config: _currentData,
          onDataChanged: (data) {
            setState(() => _currentData = data);
            _autoSaveData(); // Automatically save when data changes
          },
        );
      
      // FileMaker: task_analysis
      case 'taskAnalysis':
      case 'task_analysis':
        return TaskAnalysisWidget(
          config: _currentData,
          onDataChanged: (data) {
            setState(() => _currentData = data);
            _autoSaveData(); // Automatically save when data changes
          },
        );
      
      // FileMaker: time_sampling
      case 'timeSampling':
      case 'time_sampling':
        return TimeSamplingWidget(
          config: _currentData,
          onDataChanged: (data) {
            setState(() => _currentData = data);
            _autoSaveData(); // Automatically save when data changes
          },
        );
      
      // FileMaker: rating_scale
      case 'ratingScale':
      case 'rating_scale':
        return RatingScaleWidget(
          config: _currentData,
          onDataChanged: (data) {
            setState(() => _currentData = data);
            _autoSaveData(); // Automatically save when data changes
          },
        );
      
      // FileMaker: abc_data
      case 'abcData':
      case 'abc_data':
        return ABCWidget(
          config: _currentData,
          onDataChanged: (data) {
            setState(() => _currentData = data);
            _autoSaveData(); // Automatically save when data changes
          },
        );
      
      default:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Unknown data type: ${widget.assignment.dataType}'),
                const SizedBox(height: 8),
                const Text(
                  'Available types: percent_correct, percent_independent, frequency, duration, rate, task_analysis, time_sampling, rating_scale, abc_data',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
    }
  }

  Map<String, dynamic> _getPayload() {
    switch (widget.assignment.dataType) {
      case 'discrete_trial':
        final total = _currentData['total'] ?? 0;
        final hits = _currentData['hits'] ?? 0;
        final misses = _currentData['misses'] ?? 0;
        final noResponse = _currentData['noResponse'] ?? 0;
        final promptCounts = _currentData['promptCounts'] ?? {};
        final mostIntrusivePrompt = _currentData['mostIntrusivePrompt'];
        final totalPrompted = _currentData['totalPrompted'] ?? 0;
        final percentCorrect = _currentData['percentCorrect'] ?? 0;
        final percentIncorrect = _currentData['percentIncorrect'] ?? 0;
        final percentNoResponse = _currentData['percentNoResponse'] ?? 0;
        final percentPrompted = _currentData['percentPrompted'] ?? 0;
        
        print('🔍 ProgramCard _getPayload discrete_trial:');
        print('  _currentData: $_currentData');
        print('  totalPrompted: $totalPrompted');
        print('  percentCorrect: $percentCorrect');
        print('  percentIncorrect: $percentIncorrect');
        print('  percentNoResponse: $percentNoResponse');
        print('  percentPrompted: $percentPrompted');
        
        return {
          'total': total,
          'hits': hits,
          'misses': misses,
          'percent': total > 0 ? (hits / total * 100).round() : 0,
          'noResponse': noResponse,
          'promptCounts': promptCounts,
          'mostIntrusivePrompt': mostIntrusivePrompt,
          'totalPrompted': totalPrompted,
          'percentCorrect': percentCorrect,
          'percentIncorrect': percentIncorrect,
          'percentNoResponse': percentNoResponse,
          'percentPrompted': percentPrompted,
          'programStartTime': _currentData['programStartTime'],
          'programEndTime': _currentData['programEndTime'],
        };
      
      // FileMaker: frequency
      case 'frequency':
        return {'count': _currentData['count'] ?? 0};
      
      // FileMaker: duration
      case 'duration':
        return {
          'seconds': _currentData['seconds'] ?? 0,
          'minutes': _currentData['minutes'] ?? 0.0,
          'phase': _currentData['phase'] ?? 'baseline',
          'notes': _currentData['notes'] ?? '',
          'data_type': 'duration',
        };
      
      // FileMaker: rate
      case 'rate':
        final count = _currentData['count'] ?? 0;
        final seconds = _currentData['seconds'] ?? 0;
        return {
          'count': count,
          'seconds': seconds,
          'ratePerMin': seconds > 0 ? (count / (seconds / 60)).round() : 0,
        };
      
      // FileMaker: task_analysis
      case 'taskAnalysis':
      case 'task_analysis':
        final steps = _currentData['steps'] as List? ?? [];
        final completed = steps.where((s) => s == true).length;
        return {
          'steps': steps,
          'percentComplete': steps.isNotEmpty ? (completed / steps.length * 100).round() : 0,
        };
      
      // FileMaker: time_sampling
      case 'timeSampling':
      case 'time_sampling':
        final samples = _currentData['samples'] as List? ?? [];
        final onTask = samples.where((s) => s == true).length;
        return {
          'samples': samples,
          'percentOnTask': samples.isNotEmpty ? (onTask / samples.length * 100).round() : 0,
        };
      
      // FileMaker: rating_scale
      case 'ratingScale':
      case 'rating_scale':
        return {'rating': _currentData['rating'] ?? 0};
      
      // FileMaker: abc_data
      case 'abcData':
      case 'abc_data':
        return {
          'antecedent': _currentData['antecedent'] ?? '',
          'behavior': _currentData['behavior'] ?? '',
          'consequence': _currentData['consequence'] ?? '',
          'notes': _currentData['notes'] ?? '',
        };
      
      default:
        return _currentData;
    }
  }


  Future<void> _saveData() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    
    try {
      final payload = _getPayload();
      await widget.onSave(payload);
      
      // Preserve program times when resetting data after successful save
      final preservedProgramStartTime = _currentData['programStartTime'];
      final preservedProgramEndTime = _currentData['programEndTime'];
      
      // Reset data after successful save
      setState(() {
        _currentData = Map<String, dynamic>.from(widget.assignment.config);
        _originalData = Map<String, dynamic>.from(widget.assignment.config);
        
        // Preserve program times
        if (preservedProgramStartTime != null) {
          _currentData['programStartTime'] = preservedProgramStartTime;
        }
        if (preservedProgramEndTime != null) {
          _currentData['programEndTime'] = preservedProgramEndTime;
        }
      });
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Automatically save data when it changes (without resetting the form)
  Future<void> _autoSaveData() async {
    if (_isSaving) return; // Prevent multiple simultaneous saves
    
    try {
      final payload = _getPayload();
      await widget.onSave(payload);
      
      // Update original data to reflect the saved state
      _originalData = Map<String, dynamic>.from(_currentData);
      
      print('✅ Auto-saved data for ${widget.assignment.name}: $payload');
    } catch (e) {
      print('❌ Auto-save failed for ${widget.assignment.name}: $e');
      // Don't show error to user for auto-save failures to avoid interrupting workflow
    }
  }

  Future<void> _logBehavior() async {
    if (widget.visitId == null || widget.clientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot log behavior: Missing visit or client information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<BehaviorLog>(
      context: context,
      isScrollControlled: true,
      builder: (context) => BehaviorModal(
        visitId: widget.visitId!,
        clientId: widget.clientId!,
        assignmentId: widget.assignment.id, // Pass this program's assignment ID
      ),
    );
    
    if (result != null && widget.onBehaviorLogged != null) {
      widget.onBehaviorLogged!(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        final sessionTotals = sessionProvider.getSessionTotalsForAssignment(widget.assignment.id ?? '');
        
        return Card(
          elevation: 3,
          color: Colors.blue[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.blue[300]!,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Program Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Program Name - First Row
                          Text(
                            widget.assignment.name ?? 'Unnamed Program',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.assignment.dataType ?? 'Unknown',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          if (widget.assignment.phase?.isNotEmpty == true)
                            Chip(
                              label: Text(widget.assignment.phase!),
                              backgroundColor: _getPhaseColor(widget.assignment.phase!),
                            ),
                        ],
                      ),
                    ),
                    if (sessionTotals.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Session Total',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              _formatSessionTotal(sessionTotals),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Data Collection Widget
                _buildDataCollectionWidget(),
                
                const SizedBox(height: 16),
                
                
                // Behavior Logging Button (only show if visit/client info available)
                if (widget.visitId != null && widget.clientId != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logBehavior,
                      icon: const Icon(Icons.psychology),
                      label: const Text('Log Behavior for This Program'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getPhaseColor(String phase) {
    switch (phase.toLowerCase()) {
      case 'baseline':
        return Colors.grey[300]!;
      case 'intervention':
        return Colors.blue[300]!;
      case 'maintenance':
        return Colors.green[300]!;
      case 'generalization':
        return Colors.purple[300]!;
      default:
        return Colors.grey[300]!;
    }
  }

  String _formatSessionTotal(Map<String, dynamic> totals) {
    switch (widget.assignment.dataType) {
      case 'discrete_trial':
        return '${totals['totalHits']}/${totals['totalTrials']} (${totals['overallPercent']}%)';
      
      case 'frequency':
        return '${totals['totalCount']} events';
      
      case 'duration':
        final phase = totals['phase'] ?? 'baseline';
        final minutes = totals['totalMinutes'] ?? 0;
        return '${minutes} min ($phase)';
      
      case 'rate':
        return '${totals['totalCount']} in ${(totals['totalSeconds'] / 60).round()} min (${totals['overallRate']}/min)';
      
      case 'taskAnalysis':
        return '${totals['completedSteps']}/${totals['totalSteps']} (${totals['overallPercent']}%)';
      
      case 'timeSampling':
        return '${totals['onTaskSamples']}/${totals['totalSamples']} (${totals['overallPercent']}%)';
      
      case 'ratingScale':
        return 'Avg: ${totals['averageRating']}';
      
      default:
        return 'Data collected';
    }
  }

}
