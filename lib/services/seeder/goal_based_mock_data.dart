
/// Mock data for 8 specific goals with corresponding programs and phase-specific data logging
class GoalBasedMockData {
  
  // ============================================================================
  // 8 SPECIFIC GOALS
  // ============================================================================
  
  static List<Map<String, dynamic>> getEightGoals() {
    return [
      {
        'id': 'goal-001',
        'name': 'Receptive Identification of Common Objects',
        'description': 'Client will identify 10 common objects when named by therapist',
        'targetBehavior': 'Point to or touch the correct object when named',
        'dataType': 'percentCorrect',
        'masteryCriteria': {
          'targetPercentage': 80.0,
          'consecutiveSessions': 3,
          'totalSessions': 5,
        },
        'objects': ['ball', 'cup', 'book', 'car', 'dog', 'cat', 'apple', 'shoe', 'hat', 'phone'],
        'clientId': 'client-001',
        'staffId': 'staff-001',
        'priority': 'High',
        'category': 'Communication',
      },
      {
        'id': 'goal-002',
        'name': 'Hand Raising for Attention',
        'description': 'Client will raise hand to get attention instead of calling out',
        'targetBehavior': 'Raise hand when wanting to speak or get attention',
        'dataType': 'frequency',
        'masteryCriteria': {
          'targetCount': 5,
          'consecutiveSessions': 3,
          'totalSessions': 5,
        },
        'replacementBehavior': 'Hand raising',
        'clientId': 'client-001',
        'staffId': 'staff-001',
        'priority': 'High',
        'category': 'Social Skills',
      },
      {
        'id': 'goal-003',
        'name': 'Independent Hand Washing',
        'description': 'Client will complete hand washing routine independently',
        'targetBehavior': 'Complete all steps of hand washing without prompts',
        'dataType': 'taskAnalysis',
        'masteryCriteria': {
          'targetPercentage': 90.0,
          'consecutiveSessions': 3,
          'totalSessions': 5,
        },
        'steps': [
          'Turn on water',
          'Wet hands',
          'Apply soap',
          'Scrub hands',
          'Rinse hands',
          'Turn off water',
          'Dry hands',
        ],
        'clientId': 'client-001',
        'staffId': 'staff-001',
        'priority': 'Medium',
        'category': 'Self-Care',
      },
      {
        'id': 'goal-004',
        'name': 'On-Task Behavior During Academic Work',
        'description': 'Client will stay on-task during 15-minute academic work periods',
        'targetBehavior': 'Stay focused on assigned academic work',
        'dataType': 'timeSampling',
        'masteryCriteria': {
          'targetPercentage': 80.0,
          'consecutiveSessions': 3,
          'totalSessions': 5,
        },
        'workPeriods': ['Math worksheet', 'Reading comprehension', 'Writing practice'],
        'clientId': 'client-001',
        'staffId': 'staff-001',
        'priority': 'High',
        'category': 'Academic',
      },
      {
        'id': 'goal-005',
        'name': 'Appropriate Request Making',
        'description': 'Client will make appropriate requests using "I want" statements',
        'targetBehavior': 'Use "I want [item]" to request preferred items',
        'dataType': 'rate',
        'masteryCriteria': {
          'targetRate': 2.0, // per minute
          'consecutiveSessions': 3,
          'totalSessions': 5,
        },
        'requestItems': ['snack', 'toy', 'break', 'help', 'bathroom'],
        'clientId': 'client-001',
        'staffId': 'staff-001',
        'priority': 'High',
        'category': 'Communication',
      },
      {
        'id': 'goal-006',
        'name': 'Social Interaction Quality',
        'description': 'Client will engage in appropriate social interactions with peers',
        'targetBehavior': 'Initiate and maintain appropriate social interactions',
        'dataType': 'ratingScale',
        'masteryCriteria': {
          'targetRating': 4.0,
          'consecutiveSessions': 3,
          'totalSessions': 5,
        },
        'scaleLabels': {
          '1': 'Poor - No interaction',
          '2': 'Fair - Brief interaction',
          '3': 'Good - Some interaction',
          '4': 'Very Good - Appropriate interaction',
          '5': 'Excellent - Natural interaction'
        },
        'clientId': 'client-001',
        'staffId': 'staff-001',
        'priority': 'Medium',
        'category': 'Social Skills',
      },
      {
        'id': 'goal-007',
        'name': 'Reduction of Aggressive Behavior',
        'description': 'Client will reduce aggressive behaviors when frustrated',
        'targetBehavior': 'Use appropriate coping strategies instead of aggression',
        'dataType': 'abcData',
        'masteryCriteria': {
          'targetFrequency': 2, // per session
          'consecutiveSessions': 3,
          'totalSessions': 5,
        },
        'replacementBehaviors': ['Ask for help', 'Take a break', 'Use calming strategies'],
        'clientId': 'client-001',
        'staffId': 'staff-001',
        'priority': 'High',
        'category': 'Behavior Management',
      },
      {
        'id': 'goal-008',
        'name': 'Independent Play Duration',
        'description': 'Client will engage in independent play for extended periods',
        'targetBehavior': 'Play independently without adult supervision',
        'dataType': 'duration',
        'masteryCriteria': {
          'targetDuration': 300, // 5 minutes
          'consecutiveSessions': 3,
          'totalSessions': 5,
        },
        'playActivities': ['Puzzles', 'Blocks', 'Books', 'Art supplies', 'Toys'],
        'clientId': 'client-001',
        'staffId': 'staff-001',
        'priority': 'Medium',
        'category': 'Play Skills',
      },
    ];
  }

  // ============================================================================
  // CORRESPONDING PROGRAMS FOR EACH GOAL
  // ============================================================================
  
  static List<Map<String, dynamic>> getProgramsForGoals() {
    return [
      // Goal 1: Receptive Identification
      {
        'id': 'program-001',
        'goalId': 'goal-001',
        'name': 'Receptive ID - Common Objects',
        'description': 'Teaching client to identify common objects when named',
        'dataType': 'percentCorrect',
        'phase': 'intervention',
        'status': 'active',
        'masteryCriteria': {
          'targetPercentage': 80.0,
          'consecutiveSessions': 3,
          'totalSessions': 5,
        },
        'config': {
          'trialCount': 10,
          'promptLevels': ['Independent', 'Verbal', 'Physical'],
          'reinforcementSchedule': 'FR1',
          'objects': ['ball', 'cup', 'book', 'car', 'dog', 'cat', 'apple', 'shoe', 'hat', 'phone'],
        },
        'clientId': 'client-001',
        'staffId': 'staff-001',
        'startDate': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
        'endDate': null,
      },
      // Goal 2: Hand Raising
      {
        'id': 'program-002',
        'goalId': 'goal-002',
        'name': 'Hand Raising for Attention',
        'description': 'Teaching client to raise hand for attention',
        'dataType': 'frequency',
        'phase': 'intervention',
        'status': 'active',
        'masteryCriteria': {
          'targetCount': 5,
          'consecutiveSessions': 3,
          'totalSessions': 5,
        },
        'config': {
          'sessionDuration': 30,
          'targetRate': 0.17, // per minute
          'reinforcementSchedule': 'FR1',
        },
        'clientId': 'client-001',
        'staffId': 'staff-001',
        'startDate': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
        'endDate': null,
      },
      // Goal 3: Hand Washing
      {
        'id': 'program-003',
        'goalId': 'goal-003',
        'name': 'Independent Hand Washing',
        'description': 'Teaching client to wash hands independently',
        'dataType': 'taskAnalysis',
        'phase': 'intervention',
        'status': 'active',
        'masteryCriteria': {
          'targetPercentage': 90.0,
          'consecutiveSessions': 3,
          'totalSessions': 5,
        },
        'config': {
          'steps': [
            'Turn on water',
            'Wet hands',
            'Apply soap',
            'Scrub hands',
            'Rinse hands',
            'Turn off water',
            'Dry hands',
          ],
          'promptLevels': ['Independent', 'Verbal', 'Physical'],
        },
        'clientId': 'client-001',
        'staffId': 'staff-001',
        'startDate': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
        'endDate': null,
      },
      // Goal 4: On-Task Behavior
      {
        'id': 'program-004',
        'goalId': 'goal-004',
        'name': 'On-Task During Academic Work',
        'description': 'Teaching client to stay on-task during academic work',
        'dataType': 'timeSampling',
        'phase': 'intervention',
        'status': 'active',
        'masteryCriteria': {
          'targetPercentage': 80.0,
          'consecutiveSessions': 3,
          'totalSessions': 5,
        },
        'config': {
          'intervalDuration': 30, // seconds
          'sessionDuration': 15, // minutes
          'workTypes': ['Math worksheet', 'Reading comprehension', 'Writing practice'],
        },
        'clientId': 'client-001',
        'staffId': 'staff-001',
        'startDate': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
        'endDate': null,
      },
      // Goal 5: Request Making
      {
        'id': 'program-005',
        'goalId': 'goal-005',
        'name': 'Appropriate Request Making',
        'description': 'Teaching client to make appropriate requests',
        'dataType': 'rate',
        'phase': 'intervention',
        'status': 'active',
        'masteryCriteria': {
          'targetRate': 2.0,
          'consecutiveSessions': 3,
          'totalSessions': 5,
        },
        'config': {
          'sessionDuration': 20, // minutes
          'requestItems': ['snack', 'toy', 'break', 'help', 'bathroom'],
          'reinforcementSchedule': 'FR1',
        },
        'clientId': 'client-001',
        'staffId': 'staff-001',
        'startDate': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
        'endDate': null,
      },
      // Goal 6: Social Interaction
      {
        'id': 'program-006',
        'goalId': 'goal-006',
        'name': 'Social Interaction Quality',
        'description': 'Teaching client to engage in appropriate social interactions',
        'dataType': 'ratingScale',
        'phase': 'intervention',
        'status': 'active',
        'masteryCriteria': {
          'targetRating': 4.0,
          'consecutiveSessions': 3,
          'totalSessions': 5,
        },
        'config': {
          'scaleMin': 1,
          'scaleMax': 5,
          'scaleLabels': {
            '1': 'Poor - No interaction',
            '2': 'Fair - Brief interaction',
            '3': 'Good - Some interaction',
            '4': 'Very Good - Appropriate interaction',
            '5': 'Excellent - Natural interaction'
          },
        },
        'clientId': 'client-001',
        'staffId': 'staff-001',
        'startDate': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
        'endDate': null,
      },
      // Goal 7: Aggressive Behavior Reduction
      {
        'id': 'program-007',
        'goalId': 'goal-007',
        'name': 'Aggressive Behavior Reduction',
        'description': 'Teaching client to use appropriate coping strategies',
        'dataType': 'abcData',
        'phase': 'intervention',
        'status': 'active',
        'masteryCriteria': {
          'targetFrequency': 2,
          'consecutiveSessions': 3,
          'totalSessions': 5,
        },
        'config': {
          'replacementBehaviors': ['Ask for help', 'Take a break', 'Use calming strategies'],
          'antecedentStrategies': ['Environmental modifications', 'Preventive strategies'],
          'consequenceStrategies': ['Reinforcement of appropriate behavior', 'Extinction of inappropriate behavior'],
        },
        'clientId': 'client-001',
        'staffId': 'staff-001',
        'startDate': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
        'endDate': null,
      },
      // Goal 8: Independent Play
      {
        'id': 'program-008',
        'goalId': 'goal-008',
        'name': 'Independent Play Duration',
        'description': 'Teaching client to engage in independent play',
        'dataType': 'duration',
        'phase': 'intervention',
        'status': 'active',
        'masteryCriteria': {
          'targetDuration': 300,
          'consecutiveSessions': 3,
          'totalSessions': 5,
        },
        'config': {
          'playActivities': ['Puzzles', 'Blocks', 'Books', 'Art supplies', 'Toys'],
          'reinforcementSchedule': 'VR3',
          'promptLevels': ['Independent', 'Verbal', 'Physical'],
        },
        'clientId': 'client-001',
        'staffId': 'staff-001',
        'startDate': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
        'endDate': null,
      },
    ];
  }

  // ============================================================================
  // BASELINE DATA FOR ALL 8 GOALS
  // ============================================================================
  
  static List<Map<String, dynamic>> getBaselineDataForAllGoals() {
    return [
      // Goal 1: Receptive Identification - Baseline
      {
        'id': 'baseline-001',
        'goalId': 'goal-001',
        'programId': 'program-001',
        'clientId': 'client-001',
        'visitId': 'visit-001',
        'dataType': 'percentCorrect',
        'phase': 'baseline',
        'sessionData': {
          'hits': 2,
          'totalTrials': 10,
          'percentage': 20.0,
          'independent': 0,
          'prompted': 2,
          'incorrect': 8,
          'noResponse': 0,
        },
        'notes': 'Baseline: Client identified 2 out of 10 objects correctly',
        'timestamp': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
      },
      // Goal 2: Hand Raising - Baseline
      {
        'id': 'baseline-002',
        'goalId': 'goal-002',
        'programId': 'program-002',
        'clientId': 'client-001',
        'visitId': 'visit-001',
        'dataType': 'frequency',
        'phase': 'baseline',
        'sessionData': {
          'count': 0,
          'sessionDuration': 30,
          'ratePerMinute': 0.0,
        },
        'notes': 'Baseline: Client did not raise hand during 30-minute session',
        'timestamp': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
      },
      // Goal 3: Hand Washing - Baseline
      {
        'id': 'baseline-003',
        'goalId': 'goal-003',
        'programId': 'program-003',
        'clientId': 'client-001',
        'visitId': 'visit-001',
        'dataType': 'taskAnalysis',
        'phase': 'baseline',
        'sessionData': {
          'totalSteps': 7,
          'completedSteps': 2,
          'percentage': 28.6,
          'steps': [
            {'step': 1, 'description': 'Turn on water', 'completed': true, 'prompted': true},
            {'step': 2, 'description': 'Wet hands', 'completed': true, 'prompted': true},
            {'step': 3, 'description': 'Apply soap', 'completed': false, 'prompted': false},
            {'step': 4, 'description': 'Scrub hands', 'completed': false, 'prompted': false},
            {'step': 5, 'description': 'Rinse hands', 'completed': false, 'prompted': false},
            {'step': 6, 'description': 'Turn off water', 'completed': false, 'prompted': false},
            {'step': 7, 'description': 'Dry hands', 'completed': false, 'prompted': false},
          ],
        },
        'notes': 'Baseline: Client completed 2 out of 7 steps with heavy prompting',
        'timestamp': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
      },
      // Goal 4: On-Task Behavior - Baseline
      {
        'id': 'baseline-004',
        'goalId': 'goal-004',
        'programId': 'program-004',
        'clientId': 'client-001',
        'visitId': 'visit-001',
        'dataType': 'timeSampling',
        'phase': 'baseline',
        'sessionData': {
          'totalIntervals': 30,
          'onTaskIntervals': 12,
          'percentage': 40.0,
          'intervalDuration': 30,
          'sessionDuration': 15,
        },
        'notes': 'Baseline: Client was on-task for 12 out of 30 intervals (40%)',
        'timestamp': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
      },
      // Goal 5: Request Making - Baseline
      {
        'id': 'baseline-005',
        'goalId': 'goal-005',
        'programId': 'program-005',
        'clientId': 'client-001',
        'visitId': 'visit-001',
        'dataType': 'rate',
        'phase': 'baseline',
        'sessionData': {
          'count': 3,
          'sessionDuration': 20,
          'ratePerMinute': 0.15,
        },
        'notes': 'Baseline: Client made 3 requests in 20 minutes (0.15 per minute)',
        'timestamp': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
      },
      // Goal 6: Social Interaction - Baseline
      {
        'id': 'baseline-006',
        'goalId': 'goal-006',
        'programId': 'program-006',
        'clientId': 'client-001',
        'visitId': 'visit-001',
        'dataType': 'ratingScale',
        'phase': 'baseline',
        'sessionData': {
          'rating': 2,
          'scaleMin': 1,
          'scaleMax': 5,
          'scaleLabels': {
            '1': 'Poor - No interaction',
            '2': 'Fair - Brief interaction',
            '3': 'Good - Some interaction',
            '4': 'Very Good - Appropriate interaction',
            '5': 'Excellent - Natural interaction'
          },
        },
        'notes': 'Baseline: Client showed fair social interaction skills',
        'timestamp': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
      },
      // Goal 7: Aggressive Behavior - Baseline
      {
        'id': 'baseline-007',
        'goalId': 'goal-007',
        'programId': 'program-007',
        'clientId': 'client-001',
        'visitId': 'visit-001',
        'dataType': 'abcData',
        'phase': 'baseline',
        'sessionData': {
          'antecedent': 'Client was asked to complete difficult task',
          'behavior': 'Client hit therapist and threw materials',
          'consequence': 'Therapist removed client from area',
          'setting': 'Classroom',
          'perceivedFunction': 'Escape from demand',
          'severity': 4,
          'injury': false,
          'restraintUsed': false,
          'duration': 180,
          'frequency': 1,
        },
        'notes': 'Baseline: Client engaged in aggressive behavior when frustrated',
        'timestamp': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
      },
      // Goal 8: Independent Play - Baseline
      {
        'id': 'baseline-008',
        'goalId': 'goal-008',
        'programId': 'program-008',
        'clientId': 'client-001',
        'visitId': 'visit-001',
        'dataType': 'duration',
        'phase': 'baseline',
        'sessionData': {
          'totalDuration': 60,
          'sessionDuration': 15,
          'percentageOfSession': 6.7,
          'episodes': [
            {'startTime': '09:00:00', 'endTime': '09:01:00', 'duration': 60},
          ],
        },
        'notes': 'Baseline: Client played independently for 1 minute out of 15-minute session',
        'timestamp': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
      },
    ];
  }

  // ============================================================================
  // INTERVENTION DATA FOR ALL 8 GOALS
  // ============================================================================
  
  static List<Map<String, dynamic>> getInterventionDataForAllGoals() {
    return [
      // Goal 1: Receptive Identification - Intervention
      {
        'id': 'intervention-001',
        'goalId': 'goal-001',
        'programId': 'program-001',
        'clientId': 'client-001',
        'visitId': 'visit-002',
        'dataType': 'percentCorrect',
        'phase': 'intervention',
        'sessionData': {
          'hits': 6,
          'totalTrials': 10,
          'percentage': 60.0,
          'independent': 3,
          'prompted': 3,
          'incorrect': 4,
          'noResponse': 0,
        },
        'notes': 'Intervention: Client identified 6 out of 10 objects with teaching support',
        'timestamp': DateTime.now().subtract(Duration(days: 4)).toIso8601String(),
      },
      // Goal 2: Hand Raising - Intervention
      {
        'id': 'intervention-002',
        'goalId': 'goal-002',
        'programId': 'program-002',
        'clientId': 'client-001',
        'visitId': 'visit-002',
        'dataType': 'frequency',
        'phase': 'intervention',
        'sessionData': {
          'count': 2,
          'sessionDuration': 30,
          'ratePerMinute': 0.07,
        },
        'notes': 'Intervention: Client raised hand 2 times during 30-minute session',
        'timestamp': DateTime.now().subtract(Duration(days: 4)).toIso8601String(),
      },
      // Goal 3: Hand Washing - Intervention
      {
        'id': 'intervention-003',
        'goalId': 'goal-003',
        'programId': 'program-003',
        'clientId': 'client-001',
        'visitId': 'visit-002',
        'dataType': 'taskAnalysis',
        'phase': 'intervention',
        'sessionData': {
          'totalSteps': 7,
          'completedSteps': 5,
          'percentage': 71.4,
          'steps': [
            {'step': 1, 'description': 'Turn on water', 'completed': true, 'prompted': false},
            {'step': 2, 'description': 'Wet hands', 'completed': true, 'prompted': false},
            {'step': 3, 'description': 'Apply soap', 'completed': true, 'prompted': true},
            {'step': 4, 'description': 'Scrub hands', 'completed': true, 'prompted': true},
            {'step': 5, 'description': 'Rinse hands', 'completed': true, 'prompted': false},
            {'step': 6, 'description': 'Turn off water', 'completed': false, 'prompted': false},
            {'step': 7, 'description': 'Dry hands', 'completed': false, 'prompted': false},
          ],
        },
        'notes': 'Intervention: Client completed 5 out of 7 steps with reduced prompting',
        'timestamp': DateTime.now().subtract(Duration(days: 4)).toIso8601String(),
      },
      // Goal 4: On-Task Behavior - Intervention
      {
        'id': 'intervention-004',
        'goalId': 'goal-004',
        'programId': 'program-004',
        'clientId': 'client-001',
        'visitId': 'visit-002',
        'dataType': 'timeSampling',
        'phase': 'intervention',
        'sessionData': {
          'totalIntervals': 30,
          'onTaskIntervals': 21,
          'percentage': 70.0,
          'intervalDuration': 30,
          'sessionDuration': 15,
        },
        'notes': 'Intervention: Client was on-task for 21 out of 30 intervals (70%)',
        'timestamp': DateTime.now().subtract(Duration(days: 4)).toIso8601String(),
      },
      // Goal 5: Request Making - Intervention
      {
        'id': 'intervention-005',
        'goalId': 'goal-005',
        'programId': 'program-005',
        'clientId': 'client-001',
        'visitId': 'visit-002',
        'dataType': 'rate',
        'phase': 'intervention',
        'sessionData': {
          'count': 8,
          'sessionDuration': 20,
          'ratePerMinute': 0.4,
        },
        'notes': 'Intervention: Client made 8 requests in 20 minutes (0.4 per minute)',
        'timestamp': DateTime.now().subtract(Duration(days: 4)).toIso8601String(),
      },
      // Goal 6: Social Interaction - Intervention
      {
        'id': 'intervention-006',
        'goalId': 'goal-006',
        'programId': 'program-006',
        'clientId': 'client-001',
        'visitId': 'visit-002',
        'dataType': 'ratingScale',
        'phase': 'intervention',
        'sessionData': {
          'rating': 3,
          'scaleMin': 1,
          'scaleMax': 5,
          'scaleLabels': {
            '1': 'Poor - No interaction',
            '2': 'Fair - Brief interaction',
            '3': 'Good - Some interaction',
            '4': 'Very Good - Appropriate interaction',
            '5': 'Excellent - Natural interaction'
          },
        },
        'notes': 'Intervention: Client showed good social interaction skills',
        'timestamp': DateTime.now().subtract(Duration(days: 4)).toIso8601String(),
      },
      // Goal 7: Aggressive Behavior - Intervention
      {
        'id': 'intervention-007',
        'goalId': 'goal-007',
        'programId': 'program-007',
        'clientId': 'client-001',
        'visitId': 'visit-002',
        'dataType': 'abcData',
        'phase': 'intervention',
        'sessionData': {
          'antecedent': 'Client was asked to complete difficult task',
          'behavior': 'Client asked for help instead of becoming aggressive',
          'consequence': 'Therapist provided help and praised appropriate request',
          'setting': 'Classroom',
          'perceivedFunction': 'Access to help',
          'severity': 1,
          'injury': false,
          'restraintUsed': false,
          'duration': 30,
          'frequency': 1,
        },
        'notes': 'Intervention: Client used appropriate coping strategy instead of aggression',
        'timestamp': DateTime.now().subtract(Duration(days: 4)).toIso8601String(),
      },
      // Goal 8: Independent Play - Intervention
      {
        'id': 'intervention-008',
        'goalId': 'goal-008',
        'programId': 'program-008',
        'clientId': 'client-001',
        'visitId': 'visit-002',
        'dataType': 'duration',
        'phase': 'intervention',
        'sessionData': {
          'totalDuration': 180,
          'sessionDuration': 15,
          'percentageOfSession': 20.0,
          'episodes': [
            {'startTime': '09:00:00', 'endTime': '09:02:00', 'duration': 120},
            {'startTime': '09:05:00', 'endTime': '09:06:00', 'duration': 60},
          ],
        },
        'notes': 'Intervention: Client played independently for 3 minutes out of 15-minute session',
        'timestamp': DateTime.now().subtract(Duration(days: 4)).toIso8601String(),
      },
    ];
  }

  // ============================================================================
  // GENERALIZATION DATA FOR ALL 8 GOALS
  // ============================================================================
  
  static List<Map<String, dynamic>> getGeneralizationDataForAllGoals() {
    return [
      // Goal 1: Receptive Identification - Generalization
      {
        'id': 'generalization-001',
        'goalId': 'goal-001',
        'programId': 'program-001',
        'clientId': 'client-001',
        'visitId': 'visit-003',
        'dataType': 'percentCorrect',
        'phase': 'generalization',
        'sessionData': {
          'hits': 8,
          'totalTrials': 10,
          'percentage': 80.0,
          'independent': 7,
          'prompted': 1,
          'incorrect': 2,
          'noResponse': 0,
        },
        'notes': 'Generalization: Client identified 8 out of 10 objects in classroom setting',
        'timestamp': DateTime.now().toIso8601String(),
        'setting': 'Classroom',
        'generalizationTarget': 'Different environment',
      },
      // Goal 2: Hand Raising - Generalization
      {
        'id': 'generalization-002',
        'goalId': 'goal-002',
        'programId': 'program-002',
        'clientId': 'client-001',
        'visitId': 'visit-003',
        'dataType': 'frequency',
        'phase': 'generalization',
        'sessionData': {
          'count': 4,
          'sessionDuration': 30,
          'ratePerMinute': 0.13,
        },
        'notes': 'Generalization: Client raised hand 4 times during 30-minute session in classroom',
        'timestamp': DateTime.now().toIso8601String(),
        'setting': 'Classroom',
        'generalizationTarget': 'Different environment',
      },
      // Goal 3: Hand Washing - Generalization
      {
        'id': 'generalization-003',
        'goalId': 'goal-003',
        'programId': 'program-003',
        'clientId': 'client-001',
        'visitId': 'visit-003',
        'dataType': 'taskAnalysis',
        'phase': 'generalization',
        'sessionData': {
          'totalSteps': 7,
          'completedSteps': 6,
          'percentage': 85.7,
          'steps': [
            {'step': 1, 'description': 'Turn on water', 'completed': true, 'prompted': false},
            {'step': 2, 'description': 'Wet hands', 'completed': true, 'prompted': false},
            {'step': 3, 'description': 'Apply soap', 'completed': true, 'prompted': false},
            {'step': 4, 'description': 'Scrub hands', 'completed': true, 'prompted': false},
            {'step': 5, 'description': 'Rinse hands', 'completed': true, 'prompted': false},
            {'step': 6, 'description': 'Turn off water', 'completed': true, 'prompted': false},
            {'step': 7, 'description': 'Dry hands', 'completed': false, 'prompted': false},
          ],
        },
        'notes': 'Generalization: Client completed 6 out of 7 steps in school bathroom',
        'timestamp': DateTime.now().toIso8601String(),
        'setting': 'School Bathroom',
        'generalizationTarget': 'Different environment',
      },
      // Goal 4: On-Task Behavior - Generalization
      {
        'id': 'generalization-004',
        'goalId': 'goal-004',
        'programId': 'program-004',
        'clientId': 'client-001',
        'visitId': 'visit-003',
        'dataType': 'timeSampling',
        'phase': 'generalization',
        'sessionData': {
          'totalIntervals': 30,
          'onTaskIntervals': 24,
          'percentage': 80.0,
          'intervalDuration': 30,
          'sessionDuration': 15,
        },
        'notes': 'Generalization: Client was on-task for 24 out of 30 intervals (80%) in classroom',
        'timestamp': DateTime.now().toIso8601String(),
        'setting': 'Classroom',
        'generalizationTarget': 'Different environment',
      },
      // Goal 5: Request Making - Generalization
      {
        'id': 'generalization-005',
        'goalId': 'goal-005',
        'programId': 'program-005',
        'clientId': 'client-001',
        'visitId': 'visit-003',
        'dataType': 'rate',
        'phase': 'generalization',
        'sessionData': {
          'count': 12,
          'sessionDuration': 20,
          'ratePerMinute': 0.6,
        },
        'notes': 'Generalization: Client made 12 requests in 20 minutes (0.6 per minute) in classroom',
        'timestamp': DateTime.now().toIso8601String(),
        'setting': 'Classroom',
        'generalizationTarget': 'Different environment',
      },
      // Goal 6: Social Interaction - Generalization
      {
        'id': 'generalization-006',
        'goalId': 'goal-006',
        'programId': 'program-006',
        'clientId': 'client-001',
        'visitId': 'visit-003',
        'dataType': 'ratingScale',
        'phase': 'generalization',
        'sessionData': {
          'rating': 4,
          'scaleMin': 1,
          'scaleMax': 5,
          'scaleLabels': {
            '1': 'Poor - No interaction',
            '2': 'Fair - Brief interaction',
            '3': 'Good - Some interaction',
            '4': 'Very Good - Appropriate interaction',
            '5': 'Excellent - Natural interaction'
          },
        },
        'notes': 'Generalization: Client showed very good social interaction skills with peers',
        'timestamp': DateTime.now().toIso8601String(),
        'setting': 'Playground',
        'generalizationTarget': 'Different environment and peers',
      },
      // Goal 7: Aggressive Behavior - Generalization
      {
        'id': 'generalization-007',
        'goalId': 'goal-007',
        'programId': 'program-007',
        'clientId': 'client-001',
        'visitId': 'visit-003',
        'dataType': 'abcData',
        'phase': 'generalization',
        'sessionData': {
          'antecedent': 'Client was frustrated with peer interaction',
          'behavior': 'Client asked for help and used calming strategy',
          'consequence': 'Peer provided support and praised appropriate response',
          'setting': 'Playground',
          'perceivedFunction': 'Access to help',
          'severity': 1,
          'injury': false,
          'restraintUsed': false,
          'duration': 15,
          'frequency': 1,
        },
        'notes': 'Generalization: Client used appropriate coping strategy with peers',
        'timestamp': DateTime.now().toIso8601String(),
        'setting': 'Playground',
        'generalizationTarget': 'Different environment and peers',
      },
      // Goal 8: Independent Play - Generalization
      {
        'id': 'generalization-008',
        'goalId': 'goal-008',
        'programId': 'program-008',
        'clientId': 'client-001',
        'visitId': 'visit-003',
        'dataType': 'duration',
        'phase': 'generalization',
        'sessionData': {
          'totalDuration': 240,
          'sessionDuration': 15,
          'percentageOfSession': 26.7,
          'episodes': [
            {'startTime': '09:00:00', 'endTime': '09:03:00', 'duration': 180},
            {'startTime': '09:05:00', 'endTime': '09:06:00', 'duration': 60},
          ],
        },
        'notes': 'Generalization: Client played independently for 4 minutes out of 15-minute session in classroom',
        'timestamp': DateTime.now().toIso8601String(),
        'setting': 'Classroom',
        'generalizationTarget': 'Different environment',
      },
    ];
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================
  
  /// Get all data for a specific goal across all phases
  static List<Map<String, dynamic>> getDataForGoal(String goalId) {
    final allData = [
      ...getBaselineDataForAllGoals(),
      ...getInterventionDataForAllGoals(),
      ...getGeneralizationDataForAllGoals(),
    ];
    
    return allData.where((data) => data['goalId'] == goalId).toList();
  }
  
  /// Get all data for a specific phase across all goals
  static List<Map<String, dynamic>> getDataForPhase(String phase) {
    switch (phase.toLowerCase()) {
      case 'baseline':
        return getBaselineDataForAllGoals();
      case 'intervention':
        return getInterventionDataForAllGoals();
      case 'generalization':
        return getGeneralizationDataForAllGoals();
      default:
        return [];
    }
  }
  
  /// Get all data for all goals and phases
  static Map<String, List<Map<String, dynamic>>> getAllGoalBasedData() {
    return {
      'goals': getEightGoals(),
      'programs': getProgramsForGoals(),
      'baseline': getBaselineDataForAllGoals(),
      'intervention': getInterventionDataForAllGoals(),
      'generalization': getGeneralizationDataForAllGoals(),
    };
  }
  
  /// Get summary statistics for all goals
  static Map<String, dynamic> getGoalBasedDataSummary() {
    final allData = getAllGoalBasedData();
    return {
      'totalGoals': 8,
      'totalPrograms': 8,
      'totalRecords': allData.values.fold(0, (sum, list) => sum + list.length),
      'phases': ['baseline', 'intervention', 'generalization'],
      'dataTypes': ['percentCorrect', 'frequency', 'taskAnalysis', 'timeSampling', 'rate', 'ratingScale', 'abcData', 'duration'],
      'summary': {
        'goals': {'count': allData['goals']!.length, 'description': '8 specific ABA goals'},
        'programs': {'count': allData['programs']!.length, 'description': 'Corresponding programs for each goal'},
        'baseline': {'count': allData['baseline']!.length, 'description': 'Baseline data for all goals'},
        'intervention': {'count': allData['intervention']!.length, 'description': 'Intervention data for all goals'},
        'generalization': {'count': allData['generalization']!.length, 'description': 'Generalization data for all goals'},
      },
    };
  }
}
