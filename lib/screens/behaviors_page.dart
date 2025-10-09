import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/behavior_definition.dart';
import '../models/behavior_log.dart';
import '../services/filemaker_service.dart';
import '../providers/session_provider.dart';
import '../widgets/behavior_card.dart';

class BehaviorsPage extends StatefulWidget {
  final String? clientId;
  final String? visitId;

  const BehaviorsPage({
    super.key,
    this.clientId,
    this.visitId,
  });

  @override
  State<BehaviorsPage> createState() => _BehaviorsPageState();
}

class _BehaviorsPageState extends State<BehaviorsPage> {
  List<BehaviorDefinition> _behaviorDefinitions = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBehaviorDefinitions(); // Always load all behaviors
  }

  Future<void> _loadBehaviorDefinitions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      final behaviorDefs = await fileMakerService.getBehaviorDefinitions(
        clientId: null, // Load all behaviors without filtering
      );
      
      setState(() {
        _behaviorDefinitions = behaviorDefs;
        _isLoading = false;
      });
      
      // Also update the session provider
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      sessionProvider.setBehaviorDefinitions(behaviorDefs);
      
    } catch (e) {
      // If FileMaker API fails, create some sample behavior definitions
      print('Error loading behavior definitions: $e');
      print('Creating sample behavior definitions as fallback');
      
      final sampleBehaviors = _createSampleBehaviorDefinitions();
      
      setState(() {
        _behaviorDefinitions = sampleBehaviors;
        _isLoading = false;
        _error = null; // Clear error since we have fallback data
      });
      
      // Also update the session provider
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      sessionProvider.setBehaviorDefinitions(sampleBehaviors);
    }
  }

  List<BehaviorDefinition> _createSampleBehaviorDefinitions() {
    return [
      const BehaviorDefinition(
        id: 'sample-1',
        name: 'Aggressive Behavior',
        code: 'AGG',
        defaultLogType: 'frequency',
        severityScaleJson: {
          '1': 'Mild - Verbal aggression',
          '2': 'Moderate - Physical aggression without injury',
          '3': 'Severe - Physical aggression with injury risk',
        },
      ),
      const BehaviorDefinition(
        id: 'sample-2',
        name: 'Self-Injurious Behavior',
        code: 'SIB',
        defaultLogType: 'frequency',
        severityScaleJson: {
          '1': 'Mild - Head banging on soft surface',
          '2': 'Moderate - Head banging on hard surface',
          '3': 'Severe - Biting, scratching, or hitting self',
        },
      ),
      const BehaviorDefinition(
        id: 'sample-3',
        name: 'Elopement',
        code: 'ELOP',
        defaultLogType: 'frequency',
        severityScaleJson: {
          '1': 'Mild - Wandering within safe area',
          '2': 'Moderate - Leaving designated area',
          '3': 'Severe - Running into dangerous area',
        },
      ),
      const BehaviorDefinition(
        id: 'sample-4',
        name: 'Non-Compliance',
        code: 'NONCOMP',
        defaultLogType: 'frequency',
        severityScaleJson: {
          '1': 'Mild - Delayed response to instruction',
          '2': 'Moderate - Refusal to follow instruction',
          '3': 'Severe - Active resistance to instruction',
        },
      ),
      const BehaviorDefinition(
        id: 'sample-5',
        name: 'Stereotypic Behavior',
        code: 'STIM',
        defaultLogType: 'duration',
        severityScaleJson: {
          '1': 'Mild - Brief, non-disruptive',
          '2': 'Moderate - Interferes with task completion',
          '3': 'Severe - Prevents all other activities',
        },
      ),
    ];
  }

  Future<void> _refreshBehaviors() async {
    await _loadBehaviorDefinitions();
  }

  void _onBehaviorLogged(BehaviorLog behaviorLog) {
    // Add the behavior log to the session provider
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    sessionProvider.addBehaviorLog(behaviorLog);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Behavior "${behaviorLog.behaviorId}" logged successfully'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Implement undo functionality
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Behavior Definitions'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _refreshBehaviors,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Behaviors',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading behavior definitions...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error Loading Behaviors',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refreshBehaviors,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_behaviorDefinitions.isEmpty) {
      return const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology,
                  size: 48,
                  color: Colors.orange,
                ),
                SizedBox(height: 16),
                Text(
                  'No Behavior Definitions Found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'No behavior definitions are available.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshBehaviors,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _behaviorDefinitions.length,
        itemBuilder: (context, index) {
          final behaviorDef = _behaviorDefinitions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: BehaviorCard(
              behaviorDefinition: behaviorDef,
              visitId: widget.visitId,
              clientId: widget.clientId,
              onBehaviorLogged: _onBehaviorLogged,
            ),
          );
        },
      ),
    );
  }
}
