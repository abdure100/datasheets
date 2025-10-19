# 📝 Note Drafting Service Guide

## 📋 **Overview**

The Note Drafting Service integrates AI-powered clinical note generation with your ABA data collection app. It converts session data and trial records into professional clinical notes suitable for payer review.

## 🎯 **Key Features**

- **AI-Powered Note Generation** - Uses OpenAI-compatible API for clinical note drafting
- **Trial Data Integration** - Automatically converts session records to clinical notes
- **SOAP Format Support** - Generates notes in standard clinical format
- **Payer-Ready Documentation** - Meets insurance and regulatory requirements
- **Streaming Support** - Real-time note generation with streaming
- **Customizable Context** - RAG (Retrieval-Augmented Generation) support

## 🚀 **Quick Start**

### **1. Basic Usage**
```dart
import 'package:datasheets/services/note_drafting_service.dart';

// Create session data
final session = SessionData(
  providerName: 'Jane Doe, BCBA',
  npi: 'ATYPICAL',
  clientName: 'A.B.',
  dob: '2015-08-03',
  date: '2025-10-18',
  startTime: '09:00',
  endTime: '10:00',
  durationMinutes: 60,
  serviceName: 'Adaptive Behavior Treatment',
  cpt: '97153',
  modifiers: ['UC'],
  pos: '11',
  goalsList: ['task independence', 'manding'],
  behaviors: 'Calm, cooperative; brief off-task moments.',
  interventions: 'Least-to-most prompting; differential reinforcement.',
  dataSummary: 'Achieved ~90% independence on targeted tasks.',
  caregiver: 'Parent observed; reinforced strategies.',
  plan: 'Increase task complexity; fade prompts further.',
);

// Generate note draft
final noteDraft = await NoteDraftingService.generateNoteDraft(
  session: session,
  ragContext: 'Use SOAP tone; avoid speculation.',
);
```

### **2. With Trial Data Integration**
```dart
// Convert session records to SessionData
final sessionData = NoteDraftingService.convertSessionRecordsToSessionData(
  visit: visit,
  client: client,
  sessionRecords: sessionRecords,
  assignments: assignments,
  providerName: 'Jane Doe, BCBA',
  npi: 'ATYPICAL',
);

// Generate note draft
final noteDraft = await NoteDraftingService.generateNoteDraft(
  session: sessionData,
  ragContext: 'Use SOAP format with measurable outcomes.',
);
```

## 📊 **SessionData Structure**

### **Required Fields**
```dart
class SessionData {
  final String providerName;        // Provider name (e.g., "Jane Doe, BCBA")
  final String npi;                 // NPI number or "ATYPICAL"
  final String clientName;          // Client name (use initials for privacy)
  final String dob;                 // Date of birth (YYYY-MM-DD)
  final String date;                // Session date (YYYY-MM-DD)
  final String startTime;           // Start time (HH:MM)
  final String endTime;             // End time (HH:MM)
  final int durationMinutes;        // Session duration in minutes
  final String serviceName;         // Service name
  final String cpt;                 // CPT code (e.g., "97153")
  final List<String> modifiers;     // Modifiers (e.g., ["UC"])
  final String pos;                 // Place of Service (e.g., "11")
  final List<String> goalsList;     // Goals targeted
  final String behaviors;           // Behavioral observations
  final String interventions;       // Interventions used
  final String dataSummary;         // Data summary
  final String caregiver;           // Caregiver involvement
  final String plan;                // Plan/next steps
}
```

## 🔧 **API Methods**

### **1. Generate Note Draft (Non-Streaming)**
```dart
Future<String> generateNoteDraft({
  required SessionData session,
  String ragContext = '',
  String? apiKey,
})
```

### **2. Generate Note Draft (Streaming)**
```dart
Stream<String> generateNoteDraftStream({
  required SessionData session,
  String ragContext = '',
  String? apiKey,
})
```

### **3. Build Chat Messages**
```dart
List<Map<String, String>> buildNoteDraftMessages({
  required SessionData session,
  String ragContext = '',
})
```

### **4. Convert Session Records**
```dart
SessionData convertSessionRecordsToSessionData({
  required Visit visit,
  required Client client,
  required List<SessionRecord> sessionRecords,
  required List<ProgramAssignment> assignments,
  required String providerName,
  required String npi,
})
```

## 📝 **Usage Examples**

### **Example 1: Basic Note Generation**
```dart
final session = SessionData(
  providerName: 'Jane Doe, BCBA',
  npi: 'ATYPICAL',
  clientName: 'A.B.',
  dob: '2015-08-03',
  date: '2025-10-18',
  startTime: '09:00',
  endTime: '10:00',
  durationMinutes: 60,
  serviceName: 'Adaptive Behavior Treatment',
  cpt: '97153',
  modifiers: ['UC'],
  pos: '11',
  goalsList: ['task independence', 'manding'],
  behaviors: 'Calm, cooperative; brief off-task moments.',
  interventions: 'Least-to-most prompting; differential reinforcement.',
  dataSummary: 'Achieved ~90% independence on targeted tasks.',
  caregiver: 'Parent observed; reinforced strategies.',
  plan: 'Increase task complexity; fade prompts further.',
);

final noteDraft = await NoteDraftingService.generateNoteDraft(
  session: session,
  ragContext: 'Use SOAP tone; avoid speculation.',
);
```

### **Example 2: Streaming Note Generation**
```dart
await for (final chunk in NoteDraftingService.generateNoteDraftStream(
  session: session,
  ragContext: 'Use professional, objective tone.',
)) {
  print(chunk);
}
```

### **Example 3: With Trial Data Integration**
```dart
// Save trial data first
final record1 = await trialDataService.savePercentCorrectTrial(
  visitId: visitId,
  clientId: clientId,
  assignmentId: assignmentId,
  staffId: staffId,
  interventionPhase: 'intervention',
  hits: 8,
  totalTrials: 10,
  independent: 6,
  prompted: 2,
  incorrect: 2,
  noResponse: 0,
);

// Convert to SessionData
final sessionData = NoteDraftingService.convertSessionRecordsToSessionData(
  visit: visit,
  client: client,
  sessionRecords: [record1],
  assignments: assignments,
  providerName: 'Jane Doe, BCBA',
  npi: 'ATYPICAL',
);

// Generate note draft
final noteDraft = await NoteDraftingService.generateNoteDraft(
  session: sessionData,
  ragContext: 'Use SOAP format with measurable outcomes.',
);
```

### **Example 4: Custom RAG Context**
```dart
final ragContext = '''
- Use SOAP tone; avoid speculation.
- Payer requires explicit minutes and CPT/Modifiers alignment.
- Focus on measurable outcomes and data-driven observations.
- Include specific behavioral observations and interventions used.
- Maintain professional, objective tone suitable for payer review.
''';

final noteDraft = await NoteDraftingService.generateNoteDraft(
  session: session,
  ragContext: ragContext,
);
```

## 🎯 **Data Type Support**

The service automatically converts trial data to clinical notes:

### **Percent Correct/Independent**
- Converts hits, total trials, percentages to clinical language
- Example: "8/10 trials (80% accuracy)" → "Client achieved 80% accuracy on receptive identification tasks"

### **Frequency Counting**
- Converts counts and rates to behavioral observations
- Example: "5 occurrences (0.17/min)" → "Client demonstrated appropriate hand raising 5 times during session"

### **Duration Timing**
- Converts duration data to engagement observations
- Example: "4.0 minutes" → "Client engaged in independent play for 4 minutes"

### **Task Analysis**
- Converts step completion to skill development notes
- Example: "6/7 steps (86% completion)" → "Client completed 6 out of 7 hand washing steps independently"

### **Rate Calculation**
- Converts rate data to communication observations
- Example: "8 events (0.4/min)" → "Client made 8 appropriate requests at a rate of 0.4 per minute"

### **Time Sampling**
- Converts on-task data to attention observations
- Example: "12/15 intervals (80%)" → "Client was on-task for 80% of observed intervals"

### **Rating Scale**
- Converts ratings to quality assessments
- Example: "4.0/5.0 rating" → "Client demonstrated very good social interaction quality"

### **ABC Data Collection**
- Converts incidents to behavioral analysis
- Example: "2 incidents" → "Client had 2 instances of challenging behavior, both resolved appropriately"

## 🔧 **Configuration**

### **API Configuration**
```dart
// Set API key if needed
final noteDraft = await NoteDraftingService.generateNoteDraft(
  session: session,
  ragContext: ragContext,
  apiKey: 'your-api-key-here',
);
```

### **RAG Context Examples**
```dart
// Professional tone
final ragContext = 'Use professional, objective tone suitable for payer review.';

// SOAP format
final ragContext = 'Use SOAP format with measurable outcomes and data-driven observations.';

// Payer requirements
final ragContext = 'Payer requires explicit minutes and CPT/Modifiers alignment. Focus on measurable outcomes.';

// Custom requirements
final ragContext = '''
- Use SOAP tone; avoid speculation.
- Include specific behavioral observations and interventions used.
- Maintain professional, objective tone suitable for payer review.
- Focus on measurable outcomes and data-driven observations.
''';
```

## 🧪 **Testing**

### **Run Test Script**
```bash
dart test_note_drafting.dart
```

### **Run Example**
```bash
dart example_note_drafting.dart
```

### **Test Different Scenarios**
```dart
// High-performing session
final highPerformingSession = SessionData(
  // ... high performance data
);

// Challenging session
final challengingSession = SessionData(
  // ... challenging data
);

// Mixed performance session
final mixedSession = SessionData(
  // ... mixed data
);
```

## 📊 **Output Examples**

### **Generated Note Example**
```
Session conducted with A.B. (DOB: 2015-08-03) on 2025-10-18 from 09:00-10:00 (60 minutes). 
Provider: Jane Doe, BCBA (ATYPICAL). Service: Adaptive Behavior Treatment (CPT: 97153, Modifiers: UC, POS: 11). 
Goals targeted: task independence, manding. Client was calm and cooperative with brief off-task moments during transitions. 
Interventions used: least-to-most prompting and differential reinforcement. 
Data summary: Receptive ID achieved 8/10 trials (80% accuracy); Hand raising demonstrated 5 occurrences (0.17/min); 
Hand washing completed 6/7 steps (86% completion). Parent observed and participated in session, reinforcing strategies at home. 
Plan: Continue current programs; increase task complexity for receptive ID; fade prompts for hand washing.
```

## 🔍 **Troubleshooting**

### **Common Issues**

1. **API Key Errors**
   - Ensure you have a valid API key for the service
   - Check if the API endpoint is accessible

2. **Network Errors**
   - Verify internet connection
   - Check if the API endpoint is reachable

3. **Data Validation Errors**
   - Ensure all required fields are provided
   - Check data format (dates, times, etc.)

4. **Empty Output**
   - Verify session data is complete
   - Check if RAG context is appropriate

### **Debug Mode**
```dart
// Enable debug logging
print('🔍 Debug: Generating note for session: ${session.clientName}');
print('🔍 Debug: RAG context: $ragContext');

final noteDraft = await NoteDraftingService.generateNoteDraft(
  session: session,
  ragContext: ragContext,
);
```

## 📈 **Best Practices**

### **1. Data Quality**
- Ensure all session data is complete and accurate
- Use consistent formatting for dates and times
- Include specific, measurable outcomes

### **2. Privacy Protection**
- Use client initials instead of full names
- Avoid including unnecessary PHI
- Follow HIPAA guidelines

### **3. Clinical Accuracy**
- Review generated notes for accuracy
- Ensure notes reflect actual session events
- Maintain professional tone

### **4. Payer Requirements**
- Include required CPT codes and modifiers
- Specify session duration and place of service
- Focus on measurable outcomes

## 🎉 **Success Metrics**

- ✅ **AI-Powered Note Generation** with OpenAI-compatible API
- ✅ **Trial Data Integration** with automatic conversion
- ✅ **SOAP Format Support** for clinical documentation
- ✅ **Payer-Ready Documentation** meeting insurance requirements
- ✅ **Streaming Support** for real-time generation
- ✅ **Customizable Context** with RAG support
- ✅ **Comprehensive Testing** with multiple scenarios
- ✅ **Professional Output** suitable for clinical use

---

**📝 Your clinical note generation system is now ready for production use!**
