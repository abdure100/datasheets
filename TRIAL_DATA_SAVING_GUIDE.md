# 💾 Trial Data Saving to FileMaker Guide

## 📋 **Overview**

This guide explains how to save trial data to FileMaker using the `TrialDataService`. The system supports all 8 data collection types with comprehensive trial data management.

## 🎯 **Supported Data Types**

### **1. Percent Correct/Independent (Trials)**
- **Use Case**: Receptive identification, academic skills
- **Data Saved**: Hits, total trials, independent responses, prompted responses, incorrect responses, no responses
- **Calculations**: Percentage accuracy, independent percentage

### **2. Frequency Counting**
- **Use Case**: Hand raising, behavior counting
- **Data Saved**: Count, session duration, rate calculation
- **Calculations**: Events per minute

### **3. Duration Timing**
- **Use Case**: Independent play, task completion time
- **Data Saved**: Duration, activity description
- **Calculations**: Time-based measurements

### **4. Rate Calculation**
- **Use Case**: Request making, communication skills
- **Data Saved**: Events, session duration, rate
- **Calculations**: Events per minute

### **5. Task Analysis**
- **Use Case**: Multi-step tasks (hand washing, routines)
- **Data Saved**: Steps, completion status, percentage
- **Calculations**: Completion percentage

### **6. Time Sampling**
- **Use Case**: On-task behavior, attention monitoring
- **Data Saved**: Intervals, on-task intervals, percentage
- **Calculations**: On-task percentage

### **7. Rating Scale**
- **Use Case**: Social interaction quality, behavior ratings
- **Data Saved**: Rating, max rating, context, percentage
- **Calculations**: Rating percentage

### **8. ABC Data Collection**
- **Use Case**: Challenging behavior analysis
- **Data Saved**: Incidents with antecedents, behaviors, consequences
- **Calculations**: Incident count, severity analysis

## 🚀 **Quick Start**

### **1. Initialize the Service**
```dart
import 'package:datasheets/services/filemaker_service.dart';
import 'package:datasheets/services/trial_data_service.dart';

final fileMakerService = FileMakerService();
final trialDataService = TrialDataService(fileMakerService);
```

### **2. Save Trial Data**
```dart
// Example: Save percent correct trial data
final record = await trialDataService.savePercentCorrectTrial(
  visitId: 'visit_001',
  clientId: '03626AAB-FEF9-4325-A70D-191463DBAF2A',
  assignmentId: 'assignment_001',
  staffId: 'staff_001',
  interventionPhase: 'intervention',
  hits: 8,
  totalTrials: 10,
  independent: 6,
  prompted: 2,
  incorrect: 2,
  noResponse: 0,
  notes: 'Client showed good progress',
);
```

## 📊 **Detailed Examples**

### **Percent Correct/Independent Trial**
```dart
final record = await trialDataService.savePercentCorrectTrial(
  visitId: 'visit_001',
  clientId: 'client_001',
  assignmentId: 'assignment_001',
  staffId: 'staff_001',
  interventionPhase: 'intervention',
  hits: 8,                    // Correct responses
  totalTrials: 10,            // Total trials
  independent: 6,             // Independent responses
  prompted: 2,                // Prompted responses
  incorrect: 2,              // Incorrect responses
  noResponse: 0,              // No responses
  notes: 'Good progress shown',
  programStartTime: DateTime.now().subtract(Duration(minutes: 15)),
  programEndTime: DateTime.now(),
);
```

### **Frequency Counting Trial**
```dart
final record = await trialDataService.saveFrequencyTrial(
  visitId: 'visit_001',
  clientId: 'client_001',
  assignmentId: 'assignment_001',
  staffId: 'staff_001',
  interventionPhase: 'intervention',
  count: 5,                   // Number of occurrences
  sessionDuration: 30,        // Session duration in minutes
  notes: 'Client raised hand 5 times',
  programStartTime: DateTime.now().subtract(Duration(minutes: 30)),
  programEndTime: DateTime.now(),
);
```

### **Duration Timing Trial**
```dart
final record = await trialDataService.saveDurationTrial(
  visitId: 'visit_001',
  clientId: 'client_001',
  assignmentId: 'assignment_001',
  staffId: 'staff_001',
  interventionPhase: 'intervention',
  duration: 4.0,              // Duration in minutes
  activity: 'Independent puzzle play',
  notes: 'Client engaged in independent play',
  programStartTime: DateTime.now().subtract(Duration(minutes: 5)),
  programEndTime: DateTime.now(),
);
```

### **Task Analysis Trial**
```dart
final record = await trialDataService.saveTaskAnalysisTrial(
  visitId: 'visit_001',
  clientId: 'client_001',
  assignmentId: 'assignment_001',
  staffId: 'staff_001',
  interventionPhase: 'intervention',
  steps: [
    'Turn on water',
    'Wet hands',
    'Apply soap',
    'Scrub hands',
    'Rinse hands',
    'Turn off water',
    'Dry hands'
  ],
  completedSteps: [true, true, true, true, true, false, true],
  notes: 'Client completed 6 out of 7 steps',
  programStartTime: DateTime.now().subtract(Duration(minutes: 10)),
  programEndTime: DateTime.now(),
);
```

### **Rate Calculation Trial**
```dart
final record = await trialDataService.saveRateTrial(
  visitId: 'visit_001',
  clientId: 'client_001',
  assignmentId: 'assignment_001',
  staffId: 'staff_001',
  interventionPhase: 'intervention',
  events: 12,                 // Number of events
  sessionDuration: 20.0,      // Session duration in minutes
  notes: 'Client made 12 requests',
  programStartTime: DateTime.now().subtract(Duration(minutes: 20)),
  programEndTime: DateTime.now(),
);
```

### **Time Sampling Trial**
```dart
final record = await trialDataService.saveTimeSamplingTrial(
  visitId: 'visit_001',
  clientId: 'client_001',
  assignmentId: 'assignment_001',
  staffId: 'staff_001',
  interventionPhase: 'intervention',
  intervals: 15,               // Total intervals
  onTaskIntervals: 12,         // On-task intervals
  intervalDuration: 15,        // Interval duration in seconds
  notes: 'Client was on-task for 12 out of 15 intervals',
  programStartTime: DateTime.now().subtract(Duration(minutes: 15)),
  programEndTime: DateTime.now(),
);
```

### **Rating Scale Trial**
```dart
final record = await trialDataService.saveRatingScaleTrial(
  visitId: 'visit_001',
  clientId: 'client_001',
  assignmentId: 'assignment_001',
  staffId: 'staff_001',
  interventionPhase: 'intervention',
  rating: 4.0,                // Current rating
  maxRating: 5.0,             // Maximum possible rating
  context: 'Peer interaction during play',
  notes: 'Client showed very good social interaction',
  programStartTime: DateTime.now().subtract(Duration(minutes: 25)),
  programEndTime: DateTime.now(),
);
```

### **ABC Data Trial**
```dart
final record = await trialDataService.saveABCDataTrial(
  visitId: 'visit_001',
  clientId: 'client_001',
  assignmentId: 'assignment_001',
  staffId: 'staff_001',
  interventionPhase: 'intervention',
  incidents: [
    {
      'antecedent': 'Transition from play to work',
      'behavior': 'Throwing materials',
      'consequence': 'Redirected to calming corner',
      'severity': 3,
      'timestamp': DateTime.now().subtract(Duration(minutes: 30)).toIso8601String(),
    }
  ],
  notes: 'Client had 1 incident of challenging behavior',
  programStartTime: DateTime.now().subtract(Duration(minutes: 30)),
  programEndTime: DateTime.now(),
);
```

## 🔧 **Advanced Usage**

### **Custom Trial Data**
```dart
// Save custom trial data
final record = await trialDataService.saveTrialData(
  visitId: 'visit_001',
  clientId: 'client_001',
  assignmentId: 'assignment_001',
  staffId: 'staff_001',
  interventionPhase: 'intervention',
  trialData: {
    'dataType': 'custom',
    'customField1': 'value1',
    'customField2': 'value2',
    'timestamp': DateTime.now().toIso8601String(),
    'sessionEnded': true,
  },
  notes: 'Custom trial data',
);
```

### **Get Trial Data Summary**
```dart
final summary = await trialDataService.getTrialDataSummary(
  clientId: 'client_001',
  dateFrom: DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
  dateTo: DateTime.now().toIso8601String(),
);

print('Client ID: ${summary['clientId']}');
print('Total Sessions: ${summary['totalSessions']}');
print('Data Types: ${summary['dataTypes']}');
```

### **Get Trial Data for Assignment**
```dart
final records = await trialDataService.getTrialDataForAssignment(
  assignmentId: 'assignment_001',
  clientId: 'client_001',
  visitId: 'visit_001',
);

for (final record in records) {
  print('Record ID: ${record.id}');
  print('Data Type: ${record.payload['dataType']}');
  print('Timestamp: ${record.payload['timestamp']}');
}
```

## 📊 **Data Structure**

### **SessionRecord Model**
```dart
class SessionRecord {
  final String id;                    // FileMaker record ID
  final String visitId;              // Visit ID
  final String clientId;             // Client ID
  final String assignmentId;         // Program assignment ID
  final DateTime? startedAt;         // Session start time
  final DateTime? updatedAt;        // Last update time
  final Map<String, dynamic> payload; // Trial data payload
  final String? notes;               // Additional notes
  final String? staffId;             // Staff member ID
  final String? interventionPhase;   // Intervention phase
  final DateTime? programStartTime;   // Program start time
  final DateTime? programEndTime;    // Program end time
}
```

### **Trial Data Payload Structure**
```dart
{
  'dataType': 'percentCorrect',      // Data collection type
  'hits': 8,                        // Correct responses
  'totalTrials': 10,                // Total trials
  'independent': 6,                  // Independent responses
  'prompted': 2,                    // Prompted responses
  'incorrect': 2,                   // Incorrect responses
  'noResponse': 0,                  // No responses
  'percentage': 80.0,               // Calculated percentage
  'independentPercentage': 60.0,   // Independent percentage
  'timestamp': '2024-01-01T10:00:00Z', // Trial timestamp
  'sessionEnded': true,             // Session completion flag
}
```

## 🎯 **Best Practices**

### **1. Always Include Timestamps**
```dart
final record = await trialDataService.savePercentCorrectTrial(
  // ... other parameters
  programStartTime: DateTime.now().subtract(Duration(minutes: 15)),
  programEndTime: DateTime.now(),
);
```

### **2. Add Descriptive Notes**
```dart
final record = await trialDataService.saveFrequencyTrial(
  // ... other parameters
  notes: 'Client raised hand 5 times during 30-minute session. Good progress from baseline of 2 times.',
);
```

### **3. Use Appropriate Intervention Phases**
```dart
// Baseline phase
interventionPhase: 'baseline'

// Intervention phase
interventionPhase: 'intervention'

// Maintenance phase
interventionPhase: 'maintenance'

// Generalization phase
interventionPhase: 'generalization'
```

### **4. Handle Errors Gracefully**
```dart
try {
  final record = await trialDataService.savePercentCorrectTrial(
    // ... parameters
  );
  print('✅ Trial data saved: ${record.id}');
} catch (e) {
  print('❌ Error saving trial data: $e');
  // Handle error appropriately
}
```

## 🧪 **Testing**

### **Run Test Script**
```bash
dart test_trial_data_saving.dart
```

### **Run Example Usage**
```bash
dart example_trial_data_usage.dart
```

## 📈 **Data Analysis**

### **Calculate Progress**
```dart
// Get trial data for analysis
final records = await trialDataService.getTrialDataForAssignment(
  assignmentId: 'assignment_001',
);

// Calculate average performance
double totalPercentage = 0;
for (final record in records) {
  if (record.payload['percentage'] != null) {
    totalPercentage += record.payload['percentage'];
  }
}
double averagePercentage = totalPercentage / records.length;
```

### **Track Phase Progression**
```dart
// Get records by phase
final baselineRecords = records.where((r) => r.interventionPhase == 'baseline').toList();
final interventionRecords = records.where((r) => r.interventionPhase == 'intervention').toList();
final maintenanceRecords = records.where((r) => r.interventionPhase == 'maintenance').toList();

// Calculate phase averages
double baselineAvg = calculateAverage(baselineRecords);
double interventionAvg = calculateAverage(interventionRecords);
double maintenanceAvg = calculateAverage(maintenanceRecords);
```

## 🔍 **Troubleshooting**

### **Common Issues**

1. **Authentication Errors**
   - Ensure FileMaker service is properly configured
   - Check credentials in `app_config.dart`

2. **Data Not Saving**
   - Verify visit ID and assignment ID exist
   - Check FileMaker layout permissions

3. **Invalid Data Types**
   - Ensure data type matches assignment configuration
   - Validate required fields are provided

### **Debug Mode**
```dart
// Enable debug logging
print('🔍 Debug: Saving trial data for assignment: $assignmentId');
print('🔍 Debug: Payload: ${jsonEncode(trialData)}');
```

## 📞 **Support**

If you need help with trial data saving:

1. **Check the test file**: `test_trial_data_saving.dart`
2. **Review the example**: `example_trial_data_usage.dart`
3. **Verify FileMaker connection**: Ensure your FileMaker service is configured
4. **Check data structure**: Ensure all required fields are provided

## 🎉 **Success Metrics**

- ✅ **8 Data Types** supported with specialized methods
- ✅ **Comprehensive Data Structure** for all trial types
- ✅ **Automatic Calculations** for percentages and rates
- ✅ **Phase Tracking** for intervention progression
- ✅ **Error Handling** with detailed logging
- ✅ **Flexible API** for custom trial data
- ✅ **FileMaker Integration** with upsert functionality

---

**💾 Your trial data is now being saved to FileMaker with comprehensive tracking and analysis capabilities!**
