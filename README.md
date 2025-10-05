# ABA Data Collection App

A Flutter application for collecting Applied Behavior Analysis (ABA) data with FileMaker integration. This app supports session management, program data collection, and behavior logging.

## Features

- **Visit Management**: Start, monitor, and end therapy sessions
- **Program Data Collection**: Support for multiple data collection types:
  - Percent Correct/Independent (Trials)
  - Frequency counting
  - Duration timing
  - Rate calculation (events per minute)
  - Task analysis (step-by-step completion)
  - Time sampling (on-task behavior)
  - Rating scales
  - ABC data collection
- **Behavior Logging**: Quick logging of behavioral incidents
- **FileMaker Integration**: Real-time data synchronization with FileMaker database
- **Mastery Evaluation**: Automatic evaluation of program mastery criteria

## Setup Instructions

### 1. Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK
- FileMaker Server with Data API enabled
- FileMaker database with required layouts (see FileMaker_Scripts.md)

### 2. Installation

1. Clone or download this project
2. Navigate to the project directory:
   ```bash
   cd datasheets
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Generate JSON serialization code:
   ```bash
   flutter packages pub run build_runner build
   ```

### 3. FileMaker Configuration

1. Update the FileMaker service configuration in `lib/services/filemaker_service.dart`:
   ```dart
   static const String baseUrl = 'https://your-filemaker-server.com/fmi/data/vLatest';
   static const String database = 'your_database_name';
   static const String username = 'your_username';
   static const String password = 'your_password';
   ```

2. Create the required FileMaker layouts as described in `FileMaker_Scripts.md`

3. Implement the required FileMaker scripts:
   - `EvaluateAssignmentMastery`
   - `CloseVisitFinalize`
   - `UpdateVisitBehaviorRollups` (optional)

### 4. Running the App

1. For development:
   ```bash
   flutter run
   ```

2. For web deployment:
   ```bash
   flutter build web
   ```

3. For mobile deployment:
   ```bash
   flutter build apk  # Android
   flutter build ios  # iOS
   ```

## App Structure

### Screens
- `StartVisitPage`: Client and staff selection, service code
- `SessionPage`: Main data collection interface

### Data Models
- `Client`: Client information
- `Visit`: Session/appointment data
- `ProgramAssignment`: Short-term goals assigned to clients
- `SessionRecord`: Data collected during sessions
- `BehaviorDefinition`: Catalog of behaviors to log
- `BehaviorLog`: Individual behavior incidents

### Services
- `FileMakerService`: Handles all FileMaker Data API interactions
- `SessionProvider`: State management for current session

### Widgets
- `ProgramCard`: Displays program assignments with data collection widgets
- `BehaviorBoard`: Behavior logging interface
- `BehaviorModal`: Detailed behavior logging form
- Data collection widgets for each supported data type

## Data Collection Types

### 1. Percent Correct/Independent
- Records hits and total trials
- Calculates percentage automatically
- Shows session totals

### 2. Frequency
- Simple counter for events
- Quick increment/decrement buttons

### 3. Duration
- Stopwatch functionality
- Start/stop/reset controls
- Displays elapsed time

### 4. Rate
- Combines counting and timing
- Calculates events per minute
- Shows real-time rate

### 5. Task Analysis
- Step-by-step task completion
- Visual progress tracking
- Configurable number of steps

### 6. Time Sampling
- Interval-based on-task monitoring
- Configurable sampling intervals
- Visual progress display

### 7. Rating Scale
- Slider-based rating system
- Configurable min/max values
- Quick rating buttons

### 8. ABC Data
- Antecedent-Behavior-Consequence recording
- Template quick-fills
- Additional context fields

## Usage Workflow

1. **Start Visit**: Select client, staff, and service code
2. **Collect Data**: Use program cards to collect data for each assignment
3. **Log Behaviors**: Use behavior board for quick incident logging
4. **End Visit**: Automatically calculates billable time and units

## FileMaker Integration

The app communicates with FileMaker through the Data API using these layouts:
- `api_patients`: Client information
- `api_appointments`: Visit/session data
- `api_program_assignments`: Program assignments
- `api_sessiondata`: Collected session data
- `api_behavior_defs`: Behavior definitions
- `api_behavior_logs`: Behavior incident logs

## Configuration

### Program Assignment Configuration

Each program assignment includes a `config_json` field that customizes the data collection widget:

```json
{
  "minValue": 1,
  "maxValue": 5,
  "label": "Rate the behavior",
  "intervalSeconds": 30,
  "steps": ["Step 1", "Step 2", "Step 3"]
}
```

### Mastery Criteria

Program assignments include mastery criteria in the `Mastery_Criteria` field:

```json
{
  "metric": "percent",
  "direction": "at_least",
  "threshold": 80,
  "consecutiveSessions": 2,
  "minTrialsPerSession": 10,
  "minDistinctDays": 2
}
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**: Check FileMaker credentials and server URL
2. **Data Not Saving**: Verify FileMaker layouts and field names match exactly
3. **Script Errors**: Ensure FileMaker scripts are properly implemented
4. **Build Errors**: Run `flutter clean` and `flutter pub get`

### Debug Mode

Enable debug logging by setting the log level in the FileMaker service:
```dart
// Add this to see detailed API calls
print('API Request: $request');
print('API Response: $response');
```

## Contributing

1. Follow Flutter/Dart coding standards
2. Add tests for new features
3. Update documentation for API changes
4. Test with actual FileMaker database

## License

This project is proprietary software. All rights reserved.

## Support

For technical support or questions about implementation, contact the development team.
