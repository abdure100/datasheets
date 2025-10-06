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

  @override
  void initState() {
    super.initState();
    _currentData = widget.assignment.config;
  }

  Widget _buildDataCollectionWidget() {
    switch (widget.assignment.dataType) {
      case 'percentCorrect':
      case 'percentIndependent':
        return TrialsWidget(
          config: _currentData,
          onDataChanged: (data) => setState(() => _currentData = data),
        );
      
      case 'frequency':
        return FrequencyWidget(
          config: _currentData,
          onDataChanged: (data) => setState(() => _currentData = data),
        );
      
      case 'duration':
        return DurationWidget(
          config: _currentData,
          onDataChanged: (data) => setState(() => _currentData = data),
        );
      
      case 'rate':
        return RateWidget(
          config: _currentData,
          onDataChanged: (data) => setState(() => _currentData = data),
        );
      
      case 'taskAnalysis':
        return TaskAnalysisWidget(
          config: _currentData,
          onDataChanged: (data) => setState(() => _currentData = data),
        );
      
      case 'timeSampling':
        return TimeSamplingWidget(
          config: _currentData,
          onDataChanged: (data) => setState(() => _currentData = data),
        );
      
      case 'ratingScale':
        return RatingScaleWidget(
          config: _currentData,
          onDataChanged: (data) => setState(() => _currentData = data),
        );
      
      case 'abcData':
        return ABCWidget(
          config: _currentData,
          onDataChanged: (data) => setState(() => _currentData = data),
        );
      
      default:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Unknown data type: ${widget.assignment.dataType}'),
          ),
        );
    }
  }

  Map<String, dynamic> _getPayload() {
    switch (widget.assignment.dataType) {
      case 'percentCorrect':
      case 'percentIndependent':
        final total = _currentData['total'] ?? 0;
        final hits = _currentData['hits'] ?? 0;
        return {
          'total': total,
          'hits': hits,
          'percent': total > 0 ? (hits / total * 100).round() : 0,
        };
      
      case 'frequency':
        return {'count': _currentData['count'] ?? 0};
      
      case 'duration':
        return {'seconds': _currentData['seconds'] ?? 0};
      
      case 'rate':
        final count = _currentData['count'] ?? 0;
        final seconds = _currentData['seconds'] ?? 0;
        return {
          'count': count,
          'seconds': seconds,
          'ratePerMin': seconds > 0 ? (count / (seconds / 60)).round() : 0,
        };
      
      case 'taskAnalysis':
        final steps = _currentData['steps'] as List? ?? [];
        final completed = steps.where((s) => s == true).length;
        return {
          'steps': steps,
          'percentComplete': steps.isNotEmpty ? (completed / steps.length * 100).round() : 0,
        };
      
      case 'timeSampling':
        final samples = _currentData['samples'] as List? ?? [];
        final onTask = samples.where((s) => s == true).length;
        return {
          'samples': samples,
          'percentOnTask': samples.isNotEmpty ? (onTask / samples.length * 100).round() : 0,
        };
      
      case 'ratingScale':
        return {'rating': _currentData['rating'] ?? 0};
      
      case 'abcData':
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
      
      // Reset data after successful save
      setState(() {
        _currentData = widget.assignment.config;
      });
    } finally {
      setState(() => _isSaving = false);
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
                          Text(
                            widget.assignment.name ?? 'Unnamed Program',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveData,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save Data'),
                  ),
                ),
                
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
      case 'percentCorrect':
      case 'percentIndependent':
        return '${totals['totalHits']}/${totals['totalTrials']} (${totals['overallPercent']}%)';
      
      case 'frequency':
        return '${totals['totalCount']} events';
      
      case 'duration':
        return '${totals['totalMinutes']} min';
      
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
